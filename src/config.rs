use mlua::prelude::*;
use serde::{Deserialize, Serialize};
use url::Url;
use validator::Validate;

use crate::macros::into_lua;

#[derive(Debug, Clone, Deserialize, Serialize, Validate)]
pub struct Config {
    #[validate(url(message = "URL should be a full url of your Youtrack instance."))]
    pub url: String,

    pub token: String,
}

impl Config {}

impl<'lua> FromLua<'lua> for Config {
    fn from_lua(value: LuaValue<'lua>, lua: &'lua Lua) -> LuaResult<Self> {
        let c: Config = lua.from_value(value)?;

        match c.validate() {
            Ok(_) => Ok(c),
            Err(err) => Err(LuaError::external(err)),
        }
    }
}

into_lua!(Config);
