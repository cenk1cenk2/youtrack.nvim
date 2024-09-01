use crate::config::Config;
use client::*;
use error::Error;
use lua::NoData;
use macros::export_async_blocking_fn;
use mlua::prelude::*;
use reqwest::header::{self, HeaderMap};
use structured_logger::Builder;
use writer::LuaWriter;

mod api;
mod client;
mod config;
mod error;
mod lua;
mod macros;
mod writer;

struct Module {
    pub runtime: tokio::runtime::Runtime,
    pub config: Config,
    pub client: api::Client,
}

impl Module {
    fn setup(lua: &'static Lua, config: Config) -> Result<NoData, Error> {
        let runtime = tokio::runtime::Builder::new_multi_thread()
            .enable_all()
            .build()
            .unwrap();

        let _ = Builder::with_level(log::Level::Trace.as_str())
            .with_target_writer("*", LuaWriter::new(lua, "youtrack.log")?.get())
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
        log::debug!("Setup the client with url: {}", config.url);

        lua.set_app_data(Self {
            runtime,
            config,
            client,
        });

        Ok(NoData {})
    }
}

#[mlua::lua_module(skip_memory_check)]
pub fn youtrack_lib(lua: &'static Lua) -> mlua::Result<LuaTable> {
    let exports = lua.create_table()?;

    exports.set(
        "setup",
        lua.create_function(move |lua: &'static Lua, args| {
            Module::setup(lua, args).map_err(|err| err.into_lua_err())
        })?,
    )?;

    export_async_blocking_fn!(lua, exports, None, get_issues)?;

    Ok(exports)
}
