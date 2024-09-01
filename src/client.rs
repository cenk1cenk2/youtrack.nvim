use mlua::prelude::*;
use mlua::{AppDataRef, Lua};
use serde::{Deserialize, Serialize};

use crate::api::types::Issue;
use crate::error::Error;
use crate::macros::{self, from_lua, into_lua};
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

macros::from_lua!(Pagination);

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

from_lua!(GetIssues);
into_lua!(GetIssues);

pub type GetIssuesArgs<'lua> = (Option<GetIssues>, LuaFunction<'lua>);

#[allow(unused_variables)]
pub async fn get_issues(
    lua: &Lua,
    m: AppDataRef<'static, Module>,
    (options, callback): GetIssuesArgs<'_>,
) -> Result<(), Error> {
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

    log::info!("get_issues: {:?}", res);

    callback.call(res.into_inner().into_lua(lua))?;

    Ok(())
}
