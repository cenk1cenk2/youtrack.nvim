use mlua::{AppDataRef, Lua};

use crate::api::types::Issue;
use crate::lua::NoData;
use crate::{api::Client, error::Error};

fn get_client(lua: &Lua) -> Result<AppDataRef<Client>, Error> {
    lua.app_data_ref::<Client>().ok_or_else(|| Error::NoSetup)
}

#[allow(unused_variables)]
pub async fn get_issues(lua: &Lua, _: Option<NoData>) -> Result<Vec<Issue>, Error> {
    let client = get_client(lua)?;

    let res = client
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
