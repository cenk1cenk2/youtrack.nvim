use mlua::prelude::*;
use mlua::{AppDataRef, FromLua, Lua, LuaSerdeExt};
use serde::{Deserialize, Serialize};

use crate::api::types::Issue;
use crate::error::Error;
use crate::Module;

#[derive(Debug, Serialize, Deserialize, Clone)]
pub struct Pagination {
    skip: Option<i32>,
    take: Option<i32>,
}

impl Default for Pagination {
    fn default() -> Self {
        Pagination {
            skip: Some(0),
            take: Some(20),
        }
    }
}

impl<'lua> FromLua<'lua> for Pagination {
    fn from_lua(value: LuaValue<'lua>, lua: &'lua Lua) -> LuaResult<Self> {
        lua.from_value(value)
    }
}

impl<'lua> IntoLua<'lua> for Pagination {
    fn into_lua(self, lua: &'lua Lua) -> LuaResult<LuaValue<'lua>> {
        lua.to_value(&self)
    }
}

#[derive(Debug, Serialize, Deserialize, Clone)]
pub struct GetIssues {
    query: Option<String>,
    page: Option<Pagination>,
}

impl Default for GetIssues {
    fn default() -> Self {
        GetIssues {
            query: Some("for: me #Unresolved".to_string()),
            page: Some(Pagination::default()),
        }
    }
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
    let res = m
        .client
        .issues_get(
            Some(
                options
                    .clone()
                    .unwrap_or_default()
                    .page
                    .unwrap_or_default()
                    .skip
                    .unwrap_or_default(),
            ),
            Some(
                options
                    .clone()
                    .unwrap_or_default()
                    .page
                    .unwrap_or_default()
                    .take
                    .unwrap_or_default(),
            ),
            None,
            Some("type,summary,description,project(id,name)"),
            Some(
                options
                    .clone()
                    .unwrap_or_default()
                    .query
                    .unwrap_or_default()
                    .as_str(),
            ),
        )
        .await?;

    Ok(res.into_inner())
}
