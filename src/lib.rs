use crate::client::*;
use crate::config::Config;
use logger::LuaWriter;
use mlua::prelude::*;
use reqwest::header::{self, HeaderMap};
use structured_logger::Builder;

mod api;
mod client;
mod config;
mod error;
mod logger;
mod lua;

fn setup(lua: &'static Lua, config: Config) -> Result<Config, error::Error> {
    lua.set_app_data(config.clone());

    let _ = Builder::with_level("trace")
        .with_target_writer("*", LuaWriter::new(lua)?.get())
        .try_init()
        .map_err(|err| log::error!("{}", err))
        .and_then(|_| {
            log::debug!("Setup the logger for the library.");

            Ok(())
        });

    let mut headers = HeaderMap::new();

    headers.insert(
        header::AUTHORIZATION,
        header::HeaderValue::from_str(format!("Bearer {}", config.token).as_str()).map_err(
            |err| {
                log::error!("Failed to create the authorization header: {}", err);
                error::Error::NoSetup
            },
        )?,
    );

    let client = api::Client::new_with_client(
        config.clone().url.as_str(),
        reqwest::Client::builder()
            .user_agent("youtrack-nvim")
            .default_headers(headers)
            .build()?,
    );
    lua.set_app_data(client);
    log::debug!("Setup the client with url: {}", config.url);

    Ok(config)
}

macro_rules! export_fn {
    ($lua:expr, $exports:expr, $fn:expr) => {
        $exports.set(
            stringify!($fn),
            $lua.create_function(move |lua: &'static Lua, args| {
                $fn(lua, args).map_err(|err| err.into_lua_err())
            })?,
        )
    };
}

macro_rules! export_async_fn {
    ($lua:expr, $rt:expr, $exports:expr, $fn:expr) => {
        $exports.set(
            stringify!($fn),
            $lua.create_function(move |lua: &'static Lua, args| {
                $rt.block_on(async { $fn(lua, args).await.map_err(|err| err.into_lua_err()) })
            })?,
        )
    };
}

#[mlua::lua_module(skip_memory_check)]
pub fn youtrack_lib(lua: &'static Lua) -> mlua::Result<LuaTable> {
    let exports = lua.create_table()?;

    let rt = tokio::runtime::Builder::new_multi_thread()
        .enable_all()
        .build()
        .unwrap();

    export_fn!(lua, exports, setup)?;
    export_async_fn!(lua, rt, exports, get_issues)?;

    Ok(exports)
}
