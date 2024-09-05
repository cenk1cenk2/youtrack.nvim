use mlua::prelude::*;
use mlua::{AppDataRef, Lua};
use serde::{Deserialize, Serialize};

use crate::error::Error;
use crate::lua::NoData;
use crate::macros::{self, from_lua, into_lua};
use crate::Module;
use serde_json::Value as JsonValue;

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

into_lua!(GetIssues);
from_lua!(GetIssues);

pub type GetIssuesArgs<'lua> = (Option<GetIssues>, LuaFunction<'lua>);

#[derive(Debug, Serialize, Deserialize, Clone)]
pub struct GetIssue {
    id: String,
}

into_lua!(GetIssue);
from_lua!(GetIssue);

pub type GetIssueArgs<'lua> = (GetIssue, LuaFunction<'lua>);

#[derive(Debug, Serialize, Deserialize, Clone)]
pub struct ApplyCommand {
    id: String,
    query: String,
}

into_lua!(ApplyCommand);
from_lua!(ApplyCommand);

pub type ApplyCommandArgs<'lua> = (ApplyCommand, LuaFunction<'lua>);

#[allow(unused_variables)]
pub async fn get_issues(
    lua: &Lua,
    m: AppDataRef<'static, Module>,
    (options, callback): GetIssuesArgs<'_>,
) -> Result<NoData, Error> {
    let mut url = m.api_url.clone();

    url.path_segments_mut().unwrap().push("issues");

    let query: Vec<(&str, JsonValue)> = vec![
        (
            "fields",
            JsonValue::String(
                "id,idReadable,summary,description,project(id,name),customFields(name,value(name))"
                    .into(),
            ),
        ),
        ("customFields", JsonValue::String("Priority".into())),
        ("customFields", JsonValue::String("Subsystem".into())),
        (
            "query",
            JsonValue::String(
                options
                    .clone()
                    .unwrap_or_default()
                    .query
                    .unwrap_or_default(),
            ),
        ),
        (
            "$top",
            JsonValue::Number(
                options
                    .clone()
                    .unwrap_or_default()
                    .page
                    .unwrap_or_default()
                    .take
                    .unwrap_or_default()
                    .into(),
            ),
        ),
        (
            "$skip",
            JsonValue::Number(
                options
                    .clone()
                    .unwrap_or_default()
                    .page
                    .unwrap_or_default()
                    .skip
                    .unwrap_or_default()
                    .into(),
            ),
        ),
    ];

    let req = m.client.get(url).query(&query);

    log::debug!("Youtrack issues request: {:?}", req);

    let res = req.send().await?;

    match res.status() {
        reqwest::StatusCode::OK => {
            let json: JsonValue = res.json().await?;
            log::debug!(
                "Youtrack issues matching: {:?} -> {:#?}",
                options.unwrap_or_default(),
                json
            );
            callback.call((LuaNil, lua.to_value(&json)))?;
        }
        _ => {
            log::debug!(
                "Youtrack issues can not be fetched: {:?} -> {:#?}",
                options.unwrap_or_default(),
                res.text().await?
            );
            callback.call(("Can not fetch youtrack issues.", LuaNil))?;
        }
    }

    Ok(NoData)
}

#[allow(unused_variables)]
pub async fn get_issue(
    lua: &Lua,
    m: AppDataRef<'static, Module>,
    (options, callback): GetIssueArgs<'_>,
) -> Result<NoData, Error> {
    let mut url = m.api_url.clone();

    url.path_segments_mut()
        .unwrap()
        .push("issues")
        .push(options.clone().id.as_str());

    let query: Vec<(&str, JsonValue)> = vec![(
        "fields",
        JsonValue::String(
            "id,idReadable,summary,description,project(id,name),customFields(name,value(name))"
                .into(),
        ),
    )];

    let req = m.client.get(url).query(&query);

    log::debug!("Youtrack issue detail request: {:?}", req);

    let res = req.send().await?;

    match res.status() {
        reqwest::StatusCode::OK => {
            let json: JsonValue = res.json().await?;
            log::debug!("Youtrack issues matching: {:?} -> {:#?}", options, json);
            callback.call((LuaNil, lua.to_value(&json)))?;
        }
        _ => {
            log::debug!(
                "Youtrack issues can not be fetched: {:?} -> {:#?}",
                options,
                res.text().await?
            );
            callback.call((
                format!("Can not fetch youtrack issue: {}", options.id),
                LuaNil,
            ))?;
        }
    }

    Ok(NoData)
}
//
// #[allow(unused_variables)]
// pub async fn apply_command(
//     lua: &Lua,
//     m: AppDataRef<'static, Module>,
//     (options, callback): ApplyCommandArgs<'_>,
// ) -> Result<NoData, Error> {
//     let res = m.client.commands_post(
//         None,
//         Some(true),
//         CommandList {
//             issues: Vec::new()
//                 .push(Issue {
//                     id: options.clone().id,
//                 })
//                 .borrow(),
//             query: None,
//         },
//     );
//     Ok(NoData)
// }
