use mlua::prelude::*;
use mlua::{FromLua, IntoLua};
use serde::{Deserialize, Serialize};

#[derive(Debug, Serialize, Deserialize)]
pub struct NoData;

impl<'lua> FromLua<'lua> for NoData {
    fn from_lua(_value: LuaValue<'lua>, _lua: &'lua Lua) -> LuaResult<Self> {
        Ok(NoData)
    }
}

impl<'lua> IntoLua<'lua> for NoData {
    fn into_lua(self, _lua: &'lua Lua) -> LuaResult<LuaValue<'lua>> {
        Ok(mlua::Value::Nil)
    }
}
