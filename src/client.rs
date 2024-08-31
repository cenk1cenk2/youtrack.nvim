use mlua::prelude::*;
use mlua::{AppDataRef, FromLua, Lua};

use crate::api::types::Issue;
use crate::{api::Client, error::Error};

pub struct NoData {}

impl<'lua> FromLua<'lua> for NoData {
    fn from_lua(_value: LuaValue<'lua>, _lua: &'lua Lua) -> LuaResult<Self> {
        Ok(NoData {})
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

fn get_client(lua: &Lua) -> Result<AppDataRef<Client>, Error> {
    lua.app_data_ref::<Client>().ok_or_else(|| Error::NoSetup)
}

#[allow(unused_variables)]
pub async fn get_issues(lua: &Lua, _: Option<NoData>) -> Result<Vec<Issue>, Error> {
    let client = get_client(lua)?;

    let response = client.issues_get(None, None, None, None, None).await?;

    Ok(response.into_inner())
}
