use config::Config;
use mlua::prelude::*;

mod config;
mod error;

fn setup(lua: &Lua, config: Config) -> Result<Config, error::Error> {
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
