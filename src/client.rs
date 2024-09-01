use mlua::prelude::*;
use mlua::{AppDataRef, FromLua, Lua, LuaSerdeExt};
use serde::{Deserialize, Serialize};

use crate::api::types::Issue;
use crate::error::Error;
use crate::Module;

#[derive(Debug, Serialize, Deserialize, Clone)]
pub struct GetIssues {
    query: Option<String>,
}

impl<'lua> FromLua<'lua> for GetIssues {
    fn from_lua(value: LuaValue<'lua>, lua: &'lua Lua) -> LuaResult<Self> {
        lua.from_value(value)
    }
}

impl<'lua> IntoLua<'lua> for GetIssues {
    fn into_lua(self, lua: &'lua Lua) -> LuaResult<LuaValue<'lua>> {
        lua.to_value(&self)
    }
}

#[allow(unused_variables)]
pub async fn get_issues(
    lua: &Lua,
    m: AppDataRef<'static, Module>,
    options: Option<GetIssues>,
) -> Result<Vec<Issue>, Error> {
    let opt = options.unwrap_or(GetIssues { query: None });

    let res = m
        .client
        .issues_get(
            Some(0),
            Some(20),
            None,
            Some("type,summary,description,project(id,name)"),
            Some(
                opt.query
                    .unwrap_or("for: me #Unresolved".to_string())
                    .as_str(),
            ),
        )
        .await?;

    Ok(res.into_inner())
}
