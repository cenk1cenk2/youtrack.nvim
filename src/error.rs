use std::fmt;
use std::sync::Arc;

use mlua::prelude::LuaError;

#[derive(Debug)]
pub enum Error {
    SetupFailed,
    MalformedToken,
    Unauthorized,
    PermissionDenied,
    Validation(validator::ValidationErrors),
    HttpClient(reqwest::Error),
    Lua(LuaError),
}

impl std::error::Error for Error {}

impl fmt::Display for Error {
    fn fmt(&self, f: &mut fmt::Formatter<'_>) -> fmt::Result {
        use Error::*;
        match self {
            SetupFailed => write!(f, "Lib wasn't setup or error occured during setup"),
            MalformedToken => write!(f, "Malformed token"),
            Unauthorized => write!(f, "Unauthorized"),
            PermissionDenied => write!(f, "Permission denied"),
            Validation(ref err) => <validator::ValidationErrors as fmt::Display>::fmt(err, f),
            HttpClient(ref err) => <reqwest::Error as fmt::Display>::fmt(err, f),
            Lua(ref err) => <LuaError as fmt::Display>::fmt(err, f),
        }
    }
}

impl From<validator::ValidationErrors> for Error {
    fn from(err: validator::ValidationErrors) -> Self {
        Self::Validation(err)
    }
}

impl From<reqwest::Error> for Error {
    fn from(err: reqwest::Error) -> Self {
        Self::HttpClient(err)
    }
}

impl From<LuaError> for Error {
    fn from(err: LuaError) -> Self {
        Self::Lua(err)
    }
}

impl From<Error> for mlua::Error {
    fn from(val: Error) -> Self {
        use Error::*;
        match val {
            Lua(err) => err,
            err => LuaError::ExternalError(Arc::new(err)),
        }
    }
}
