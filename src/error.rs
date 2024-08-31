use std::{
    fmt::{self, Display},
    sync::Arc,
};

use log::SetLoggerError;
use mlua::prelude::LuaError;

#[derive(Debug)]
pub enum Error {
    NoSetup,
    Generic(String),
    Validation(validator::ValidationErrors),
    HttpClient(reqwest::Error),
    Client(progenitor_client::Error),
    Lua(LuaError),
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
            Generic(ref err) => write!(f, "{}", err),
            Validation(ref err) => <validator::ValidationErrors as fmt::Display>::fmt(err, f),
            HttpClient(ref err) => <reqwest::Error as fmt::Display>::fmt(err, f),
            Client(ref err) => <progenitor_client::Error as fmt::Display>::fmt(err, f),
            Lua(ref err) => <LuaError as fmt::Display>::fmt(err, f),
            Logger(ref err) => <SetLoggerError as fmt::Display>::fmt(err, f),
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
        if err.is_status() {
            return Self::Generic(
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

impl From<progenitor_client::Error> for Error {
    fn from(err: progenitor_client::Error) -> Self {
        if let Some(status) = err.status() {
            return Self::Generic(format!("{}: {}", status.canonical_reason().unwrap(), err));
        }

        Self::Client(err)
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
        use Error::*;
        match err {
            Lua(err) => err,
            err => LuaError::ExternalError(Arc::new(err)),
        }
    }
}
