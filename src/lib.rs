#![feature(async_closure)]

use crate::config::Config;
use client::*;
use error::Error;
use lua::NoData;
use macros::export_async_fn;
use mlua::prelude::*;
use reqwest::header::{self, HeaderMap};
use structured_logger::Builder;
use tokio::runtime::Runtime;
use writer::LuaWriter;

mod api;
mod client;
mod config;
mod error;
mod lua;
mod macros;
mod writer;

struct Module {
    pub config: Config,
    pub client: api::Client,
}

impl Module {
    fn setup(lua: &'static Lua, config: Config) -> Result<NoData, Error> {
        let _ = Builder::with_level(log::Level::Trace.as_str())
            .with_target_writer("*", LuaWriter::new(lua, "youtrack.log")?.get())
            .try_init()
            .map_err(|err| log::error!("{}", err))
            .map(|_| {
                log::debug!("Setup the logger for the library.");
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

        lua.set_app_data(Self { config, client });

        Ok(NoData {})
    }
}

static RUNTIME: once_cell::sync::Lazy<Runtime> = once_cell::sync::Lazy::new(|| {
    tokio::runtime::Builder::new_multi_thread()
        .enable_all()
        .build()
        .expect("Failed to create runtime.")
});

#[mlua::lua_module(skip_memory_check)]
pub fn youtrack_lib(lua: &'static Lua) -> mlua::Result<LuaTable> {
    let exports = lua.create_table()?;

    exports.set(
        "setup",
        lua.create_function(move |lua: &'static Lua, args| {
            Module::setup(lua, args).map_err(|err| err.into_lua_err())
        })?,
    )?;

    export_async_fn!(lua, exports, Some("get_issues"), get_issues, GetIssuesArgs)?;

    Ok(exports)
}
