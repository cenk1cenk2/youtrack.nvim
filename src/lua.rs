use mlua::prelude::*;
use mlua::{FromLua, IntoLua};
use serde::{Deserialize, Serialize};

use crate::api::types::Issue;

#[derive(Debug, Serialize, Deserialize)]
pub struct NoData;

impl<'lua> FromLua<'lua> for NoData {
    fn from_lua(_value: LuaValue<'lua>, _lua: &'lua Lua) -> LuaResult<Self> {
        Ok(NoData)
    }
}

impl<'lua> IntoLua<'lua> for NoData {
    fn into_lua(self, lua: &'lua Lua) -> LuaResult<LuaValue<'lua>> {
        Ok(lua.null())
    }
}

impl<'lua> FromLua<'lua> for Issue {
    fn from_lua(value: LuaValue<'lua>, lua: &'lua Lua) -> LuaResult<Self> {
        lua.from_value(value)
    }
}

impl<'lua> IntoLua<'lua> for Issue {
    fn into_lua(self, lua: &'lua Lua) -> LuaResult<LuaValue<'lua>> {
        lua.to_value(&self)
    }
}
