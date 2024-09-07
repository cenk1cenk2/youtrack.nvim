use std::{
    fmt::{self, Display},
    sync::Arc,
};

use log::SetLoggerError;
use mlua::prelude::LuaError;

#[derive(Debug)]
pub enum Error {
    NoSetup,
    Str(String),
    Std(Box<dyn std::error::Error + Send + Sync>),
    Validation(validator::ValidationErrors),
    HttpClient(reqwest::Error),
    Url(url::ParseError),
    Lua(mlua::Error),
    Logger(SetLoggerError),
}

impl std::error::Error for Error {}

impl Display for Error {
    fn fmt(&self, f: &mut fmt::Formatter<'_>) -> fmt::Result {
        use Error::*;
        match self {
            NoSetup => write!(
                f,
                "Library did not get setup correctly. Did you call setup?"
            ),
            Str(ref err) => write!(f, "{}", err),
            Std(ref err) => <dyn std::error::Error as fmt::Display>::fmt(&**err, f),
            Validation(ref err) => <validator::ValidationErrors as fmt::Display>::fmt(err, f),
            HttpClient(ref err) => <reqwest::Error as fmt::Display>::fmt(err, f),
            Url(ref err) => <url::ParseError as fmt::Display>::fmt(err, f),
            Lua(ref err) => <LuaError as fmt::Display>::fmt(err, f),
            Logger(ref err) => <SetLoggerError as fmt::Display>::fmt(err, f),
        }
    }
}

impl From<Box<dyn std::error::Error + Send + Sync>> for Error {
    fn from(err: Box<dyn std::error::Error + Send + Sync>) -> Self {
        Self::Std(err)
    }
}

impl From<validator::ValidationErrors> for Error {
    fn from(err: validator::ValidationErrors) -> Self {
        Self::Validation(err)
    }
}

impl From<reqwest::Error> for Error {
    fn from(err: reqwest::Error) -> Self {
        if err.is_status() {
            return Self::Str(
                err.status()
                    .unwrap()
                    .canonical_reason()
                    .unwrap()
                    .to_string(),
            );
        }

        Self::HttpClient(err)
    }
}

impl From<url::ParseError> for Error {
    fn from(err: url::ParseError) -> Self {
        Self::Url(err)
    }
}

impl From<SetLoggerError> for Error {
    fn from(err: SetLoggerError) -> Self {
        Self::Logger(err)
    }
}

impl From<LuaError> for Error {
    fn from(err: LuaError) -> Self {
        Self::Lua(err)
    }
}

impl From<Error> for mlua::Error {
    fn from(err: Error) -> Self {
        match err {
            Error::Lua(err) => err,
            err => LuaError::ExternalError(Arc::new(err)),
        }
    }
}
