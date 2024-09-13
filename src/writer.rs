use std::fmt::Display;
use std::str::FromStr;
use std::{
    collections::BTreeMap,
    io::{self},
};

use crate::error::Error;
use log::kv::{Key, Value};
use mlua::prelude::*;
use structured_logger::Writer;

#[derive(Debug)]
pub enum LogLevel {
    Level(String),
    Error,
    Warn,
    Info,
    Debug,
    Trace,
}

impl From<String> for LogLevel {
    fn from(level: String) -> Self {
        match log::Level::from_str(level.as_str()).unwrap_or(log::Level::Info) {
            log::Level::Error => LogLevel::Error,
            log::Level::Warn => LogLevel::Warn,
            log::Level::Info => LogLevel::Info,
            log::Level::Debug => LogLevel::Debug,
            log::Level::Trace => LogLevel::Trace,
        }
    }
}

impl Display for LogLevel {
    fn fmt(&self, f: &mut std::fmt::Formatter<'_>) -> std::fmt::Result {
        match self {
            LogLevel::Level(level) => write!(f, "{}", level.to_lowercase()),
            LogLevel::Error => write!(f, "error"),
            LogLevel::Warn => write!(f, "warn"),
            LogLevel::Info => write!(f, "info"),
            LogLevel::Debug => write!(f, "debug"),
            LogLevel::Trace => write!(f, "trace"),
        }
    }
}

pub struct LuaWriter {
    log: LuaTable<'static>,
    lua: &'static Lua,
}

impl LuaWriter {
    pub fn new(lua: &'static Lua, import: &str) -> Result<Self, Error> {
        let globals = lua.globals();
        let require: LuaFunction = globals.get("require")?;
        let log: LuaTable<'static> = require.call(import)?;

        Ok(Self { lua, log })
    }

    pub fn get(self) -> Box<dyn Writer> {
        Box::new(self)
    }
}

impl Writer for LuaWriter {
    fn write_log(&self, value: &BTreeMap<Key, Value>) -> Result<(), io::Error> {
        let level = value
            .get("level")
            .map(|v| v.to_string())
            .unwrap_or_else(|| "info".to_string());
        let message = value
            .get("message")
            .map(|v| v.to_string())
            .unwrap_or_default();
        let target = value
            .get("target")
            .map(|v| v.to_string())
            .unwrap_or_default();

        self.log
            .get::<_, LuaTable>("p")
            .map_err(io::Error::other)?
            .get::<_, LuaFunction>(LogLevel::Level(level).to_string())
            .map_err(io::Error::other)?
            .call(format!("[{}] {}", target, message).into_lua(self.lua))
            .map_err(io::Error::other)?;

        Ok(())
    }
}
