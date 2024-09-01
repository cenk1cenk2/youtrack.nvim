macro_rules! into_lua {
    ($structname: ident) => {
        impl<'lua> mlua::IntoLua<'lua> for $structname {
            fn into_lua(self, lua: &'lua Lua) -> LuaResult<LuaValue<'lua>> {
                lua.to_value(&self)
            }
        }
    };
}

macro_rules! from_lua {
    ($structname: ident) => {
        impl<'lua> mlua::FromLua<'lua> for $structname {
            fn from_lua(value: LuaValue<'lua>, lua: &'lua Lua) -> LuaResult<Self> {
                lua.from_value(value)
            }
        }
    };
}

macro_rules! export_fn {
    ($lua:expr, $exports:expr, $name:expr, $fn:expr) => {
        $exports.set(
            $name.unwrap_or(stringify!($fn)),
            $lua.create_function(move |lua: &'static Lua, args| {
                let m = lua.app_data_ref::<Module>().ok_or_else(|| Error::NoSetup);

                $fn(lua, m, args).map_err(|err| err.into_lua_err())
            })?,
        )
    };
}

macro_rules! export_async_blocking_fn {
    ($lua:expr, $exports:expr, $name: expr, $fn:expr) => {
        $exports.set(
            $name.unwrap_or(stringify!($fn)),
            $lua.create_function(move |lua: &'static Lua, args| {
                let m = lua.app_data_ref::<Module>().ok_or_else(|| Error::NoSetup)?;

                m.runtime.block_on(async {
                    let m = lua.app_data_ref::<Module>().ok_or_else(|| Error::NoSetup)?;

                    $fn(lua, m, args).await.map_err(|err| err.into_lua_err())
                })
            })?,
        )
    };
}

pub(crate) use export_async_blocking_fn;
pub(crate) use export_fn;
pub(crate) use from_lua;
pub(crate) use into_lua;
