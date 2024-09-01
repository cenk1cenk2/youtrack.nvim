use mlua::{AppDataRef, Lua};

use crate::api::types::Issue;
use crate::error::Error;
use crate::lua::NoData;
use crate::Module;

#[allow(unused_variables)]
pub async fn get_issues(
    lua: &Lua,
    m: AppDataRef<'static, Module>,
    _: Option<NoData>,
) -> Result<Vec<Issue>, Error> {
    let res = m
        .client
        .issues_get(
            Some(0),
            Some(20),
            None,
            Some("type,summary,description,project(id,name)"),
            Some("for: me #Unresolved"),
        )
        .await?;

    Ok(res.into_inner())
}
