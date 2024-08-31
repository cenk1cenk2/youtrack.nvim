use mlua::prelude::*;
use serde::{Deserialize, Serialize};
use validator::Validate;

#[derive(Debug, Clone, Deserialize, Serialize, Validate)]
pub struct Config {
    #[validate(url(message = "URL should be a full url of your Youtrack instance."))]
    pub url: String,

    pub token: String,
}

impl Config {}

impl<'lua> FromLua<'lua> for Config {
    fn from_lua(value: LuaValue<'lua>, lua: &'lua Lua) -> LuaResult<Self> {
        let mut c: Config = lua.from_value(value)?;

        c.url = format!("{}/api", c.url);

        match c.validate() {
            Ok(_) => Ok(c),
            Err(err) => Err(LuaError::external(err)),
        }
    }
}

impl<'lua> IntoLua<'lua> for Config {
    fn into_lua(self, lua: &'lua Lua) -> LuaResult<LuaValue<'lua>> {
        lua.to_value(&self)
    }
}
