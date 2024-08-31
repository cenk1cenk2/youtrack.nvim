use config::Config;
use mlua::prelude::*;
use reqwest::header::{self, HeaderMap};

mod api;
mod config;
mod error;

fn setup(lua: &Lua, config: Config) -> Result<Config, error::Error> {
    let mut headers = HeaderMap::new();

    let auth = header::HeaderValue::from_str(format!("Bearer {}", config.token).as_str()).unwrap();
    headers.insert(header::AUTHORIZATION, auth);

    let client = api::Client::new_with_client(
        &config.clone().url,
        reqwest::Client::builder()
            .user_agent("youtrack-nvim")
            .default_headers(headers)
            .build()?,
    );

    lua.set_app_data(client);

    lua.set_app_data(config.clone());

    Ok(config)
}

macro_rules! export_fn {
    ($lua:expr, $exports:expr, $fn:expr) => {
        $exports.set(
            stringify!($fn),
            $lua.create_function(move |lua: &Lua, args| $fn(lua, args).map_err(|err| err.into()))?,
        )
    };
}

#[mlua::lua_module]
pub fn youtrack_lib(lua: &Lua) -> mlua::Result<LuaTable> {
    let exports = lua.create_table()?;

    export_fn!(lua, exports, setup)?;

    Ok(exports)
}
