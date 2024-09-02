use mlua::prelude::*;
use mlua::{AppDataRef, Lua};
use serde::{Deserialize, Serialize};

use crate::error::Error;
use crate::lua::NoData;
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
) -> Result<NoData, Error> {
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
            Some("type,state"),
            Some("type,id,idReadable,summary,description,project(id,name),fields(value(id,name,description,localizedName,isResolved,color(@color)"),
            Some(
                options
                    .clone()
                    .unwrap_or_default()
                    .query
                    .unwrap_or_default()
                    .as_str(),
            ),
        )
        .await;

    match res {
        Ok(res) => {
            log::debug!(
                "Youtrack issues matching: {:?} -> {:?}",
                options.unwrap_or_default(),
                res
            );
            callback.call((LuaNil, res.into_inner().into_lua(lua)))?;
        }
        Err(err) => {
            let e = Error::Client(err);
            log::debug!(
                "Youtrack issues can not be fetched: {:?} -> {}",
                options.unwrap_or_default(),
                e
            );
            callback.call((e.to_string(), LuaNil))?;
        }
    }

    Ok(NoData)
}
