use mlua::prelude::*;
use mlua::{AppDataRef, Lua};
use serde::{Deserialize, Serialize};

use crate::error::Error;
use crate::lua::NoData;
use crate::macros::{self, from_lua, into_lua};
use crate::Module;
use serde_json::{json, Value as JsonValue};

#[derive(Debug, Serialize, Deserialize, Clone)]
pub struct Pagination {
    pub skip: Option<i32>,
    pub take: Option<i32>,
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
    pub query: Option<String>,
    pub page: Option<Pagination>,
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
                "id,idReadable,summary,description,project(id,name),customFields(name,value)"
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
            callback.call(("Youtrack issues can not be fetched.", LuaNil))?;
        }
    }

    Ok(NoData)
}

#[derive(Debug, Serialize, Deserialize, Clone)]
pub struct GetIssue {
    pub id: String,
}

into_lua!(GetIssue);
from_lua!(GetIssue);

pub type GetIssueArgs<'lua> = (GetIssue, LuaFunction<'lua>);

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
            "id,idReadable,summary,description,project(id,name),customFields(name,presentation,value($type,name,presentation)),comments(author(fullName),text,created)"
                .into(),
        ),
    )];

    let req = m.client.get(url).query(&query);

    log::debug!("Youtrack issue detail request: {:?}", req);

    let res = req.send().await?;

    match res.status() {
        reqwest::StatusCode::OK => {
            let json: JsonValue = res.json().await?;
            log::debug!("Youtrack issue details: {:?} -> {:#?}", options, json);
            callback.call((LuaNil, lua.to_value(&json)))?;
        }
        _ => {
            log::debug!(
                "Youtrack issue details can not be fetched: {:?} -> {:#?}",
                options,
                res.text().await?
            );
            callback.call((
                format!("Youtrack issue details can not be fetched: {}", options.id),
                LuaNil,
            ))?;
        }
    }

    Ok(NoData)
}

#[derive(Debug, Serialize, Deserialize, Clone)]
pub struct ApplyIssueCommand {
    pub id: String,
    pub query: String,
}

into_lua!(ApplyIssueCommand);
from_lua!(ApplyIssueCommand);

pub type ApplyIssueCommandArgs<'lua> = (ApplyIssueCommand, LuaFunction<'lua>);

#[allow(unused_variables)]
pub async fn apply_issue_command(
    lua: &Lua,
    m: AppDataRef<'static, Module>,
    (options, callback): ApplyIssueCommandArgs<'_>,
) -> Result<NoData, Error> {
    let mut url = m.api_url.clone();

    url.path_segments_mut().unwrap().push("commands");

    let query: Vec<(&str, JsonValue)> = vec![];

    let req = m.client.post(url).query(&query).json(&json!({
        "issues": [{ "id": options.id }],
        "query": options.query
    }));

    log::debug!("Youtrack issue apply command request: {:?}", req);

    let res = req.send().await?;

    match res.status() {
        reqwest::StatusCode::OK => {
            let json: JsonValue = res.json().await?;
            log::debug!(
                "Youtrack issue command applied: {:?} -> {:#?}",
                options,
                json
            );
            callback.call((LuaNil, lua.to_value(&json)))?;
        }
        _ => {
            log::debug!(
                "Youtrack issue command can not be applied: {:?} -> {:#?}",
                options,
                res.text().await?
            );
            callback.call((
                format!("Youtrack issue command can not be applied: {}", options.id),
                LuaNil,
            ))?;
        }
    }

    Ok(NoData)
}

#[derive(Debug, Serialize, Deserialize, Clone)]
pub struct AddIssueComment {
    pub id: String,
    pub comment: String,
}

into_lua!(AddIssueComment);
from_lua!(AddIssueComment);

pub type AddIssueCommentArgs<'lua> = (AddIssueComment, LuaFunction<'lua>);

#[allow(unused_variables)]
pub async fn add_issue_comment(
    lua: &Lua,
    m: AppDataRef<'static, Module>,
    (options, callback): AddIssueCommentArgs<'_>,
) -> Result<NoData, Error> {
    let mut url = m.api_url.clone();

    url.path_segments_mut()
        .unwrap()
        .push("issues")
        .push(options.clone().id.as_str())
        .push("comments");

    let query: Vec<(&str, JsonValue)> = vec![];

    let req = m.client.post(url).query(&query).json(&json!({
        "text": options.comment
    }));

    log::debug!("Youtrack issue add comment request: {:?}", req);

    let res = req.send().await?;

    match res.status() {
        reqwest::StatusCode::OK => {
            let json: JsonValue = res.json().await?;
            log::debug!("Youtrack issue comment added: {:?} -> {:#?}", options, json);
            callback.call((LuaNil, lua.to_value(&json)))?;
        }
        _ => {
            log::debug!(
                "Youtrack issue comment can not be added: {:?} -> {:#?}",
                options,
                res.text().await?
            );
            callback.call((
                format!("Youtrack issue comment can not be added: {}", options.id),
                LuaNil,
            ))?;
        }
    }

    Ok(NoData)
}

#[derive(Debug, Serialize, Deserialize, Clone)]
pub struct GetSavedQueries {
    pub page: Option<Pagination>,
}

impl Default for GetSavedQueries {
    fn default() -> Self {
        GetSavedQueries {
            page: Some(Pagination::default()),
        }
    }
}

into_lua!(GetSavedQueries);
from_lua!(GetSavedQueries);

pub type GetSavedQueriesArgs<'lua> = (Option<GetSavedQueries>, LuaFunction<'lua>);

#[allow(unused_variables)]
pub async fn get_saved_queries(
    lua: &Lua,
    m: AppDataRef<'static, Module>,
    (options, callback): GetSavedQueriesArgs<'_>,
) -> Result<NoData, Error> {
    let mut url = m.api_url.clone();

    url.path_segments_mut().unwrap().push("savedQueries");

    let query: Vec<(&str, JsonValue)> = vec![
        ("fields", JsonValue::String("name,query".into())),
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

    log::debug!("Youtrack issue add comment request: {:?}", req);

    let res = req.send().await?;

    match res.status() {
        reqwest::StatusCode::OK => {
            let json: JsonValue = res.json().await?;
            log::debug!(
                "Youtrack saved queries fetched: {:?} -> {:#?}",
                options,
                json
            );
            callback.call((LuaNil, lua.to_value(&json)))?;
        }
        _ => {
            log::debug!(
                "Youtrack saved queries can not be fetched: {:?} -> {:#?}",
                options,
                res.text().await?
            );
            callback.call(("Youtrack saved queries can not be fetched.", LuaNil))?;
        }
    }

    Ok(NoData)
}
