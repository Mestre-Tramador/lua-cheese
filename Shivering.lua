--[[
  Lua Cheese is a Command Interface to manage a cheese store.
  Copyright (C) 2022  Mestre Tramador

  This program is free software: you can redistribute it and/or modify
  it under the terms of the GNU General Public License as published by
  the Free Software Foundation, either version 3 of the License, or
  (at your option) any later version.

  This program is distributed in the hope that it will be useful,
  but WITHOUT ANY WARRANTY; without even the implied warranty of
  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
  GNU General Public License for more details.

  You should have received a copy of the GNU General Public License
  along with this program.  If not, see <https://www.gnu.org/licenses/>.
--]]

--[[
  Don't worry, pals, this requires will be used someday...

  local driver = require "luasql.mysql"
  local env = driver.mysql()
  local db = env:connect('schema', 'username', 'password')
  local lfs = require "lfs"
  local cjson = require "cjson"
--]]

---Just check if the Door to the Madness was opened.
---@type boolean
local opened = false

---The protected globals table.
---@type table
local _P = {}

---The Global metatable.
---@type {__index: table, __newindex: function}
local _M = {
  __index = _P,
  __newindex = function(__table, __key, __value)
    if _P[__key] and _P[__key] ~= __value then
      error("Attempting to overwrite constant " .. tostring(__key) .. " to " .. tostring(__value), 2)
    end
  end
}

---Mark a `value`, by a `key`, as a `protected` Global.
---@param key string "The key, or name, of the Global."
---@param value any "The value it shall hold, as of any type."
local function protect(key, value)
  if _G[key] then
    _P[key] = _G[key]
    _G[key] = nil
  else
    _P[key] = value
  end

  setmetatable(_G, _M)
end

---Create a `readonly` table, with defined fields that can't be updated.
---@param table table "The table marked to be readonly."
---@return table "The same table, perfectly set to be readonly."
local function readonly(table)
  ---A new instance for the `table` parameter.
  ---@type table
  local instance = {}

  ---The metatable for the instance.
  ---@type {__index: table, __newindex: function}
  local meta = {
    __index = table,
    __newindex = function(__table, __key, __value)
      error("Attempting to update a read-only table field " .. tostring(__key) .. " to " .. tostring(__value), 2)
    end
  }

  setmetatable(instance, meta)

  return instance
end

---This is a simple caller to create a `readonly` table, but also a `protected` Global.
---@param table table "The table to be used as a value."
---@param key string "The key, or the variable name, for the Global control."
---@return table "The value is correctly set as `readonly` and `protected`."
local function protectedreadonly(table, key)
  ---An auxiliar table which is already `readonly`.
  ---@type table
  local value = readonly(table)

  protect(key, value)

  return value
end

---Get the current OS by the path to the C libraries.
---@return string|nil "If found, the `string` can be **DOS** or **UNIX**."
local function getos()
  ---The extension of the C Path.
  ---@type string
  local bin = package.config:sub(1,1)

  if     bin == "\\" then return "DOS"
  elseif bin == "/"  then return "UNIX"
  else                    return nil
  end
end

---Load all the Lua modules and files on the `src` path.
---@return boolean "It is always `true`."
local function autoload()
  if opened then return true end

  ---Get the correct command for the automatic loading.
  ---@return string "The command should be `dir /B /W` or `ls -p`, depending on the OS."
  local function getcmd()
    if Shivering.isle == "DOS" then
      return "dir /B /W "
    else
      return "ls -p "
    end
  end

  ---Check if the given file (of directory) has a extension.
  ---@param file string "It is a result for the scan command."
  ---@return boolean "According with the presence of a dot in the file."
  local function hasext(file) return file:find("%.") end

  ---Check if the given path is a directory.
  ---@param dir string "The path get on the scan command."
  ---@return boolean "Depends on the OS, but it envolves the presence of a slash of not extension."
  local function isdir(dir)
    return (dir:sub(-1) == "/") or (Shivering.isle == "DOS" and not hasext(dir))
  end

  ---Check if the given path is a Lua module.
  ---@param file string
  ---@return boolean
  local function ismod(file)
    if
      file:sub(-1) == ":" or
      file:len() == 0     or
      isdir(file)         or
      not hasext(file)
    then
      return false
    end

    return file:find("%.lua$")
  end

  ---Run through a directory path and `require` all Lua modules.
  ---@param cmd string "The command to scan the directory, from the `src` and so on."
  ---@param dir string "The current path that is been scanned."
  local function load(cmd, dir)
    ---Make the room to enter, or assemble the module string, as a matter of speak.
    ---@param path string "The Lua file."
    ---@return string "It follows the `require` syntax."
    local function makeroom(path)
      ---The full path of the "room".
      ---@type string
      local room = dir:gsub("[\\/]", ".")

      if(room:sub(-1) ~= ".") then room = room .. "." end

      return room .. path:gsub("%.lua$", "")
    end

    ---Make the door to enter, or assemble the subdirectory to scan, as a matter of speak.
    ---@param path string "The current path of the loader."
    ---@param room string "The directory to enter."
    ---@return string "It follows the OS folder separator syntax."
    local function makedoor(path, room)
      ---The full path of the "door".
      ---@type string
      local door = path

      if dir:sub(-1) ~= "/" and dir:sub(-1) ~= "\\" then
        if Shivering.isle == "DOS"
        then door = door .. "\\"
        else door = door .. "/"
        end
      end

      door = door .. room

      return door
    end

    for room in io.popen(cmd .. dir):lines() do
      if isdir(room) then
        ---If the given room is a directory,
        ---then it is recursively loaded instead.
        load(cmd, makedoor(dir, room))
      elseif ismod(room) then
        ---This room is a Lua module,
        ---then it is required.
        require(makeroom(room))
      end
    end
  end

  load(getcmd(), "src")

  opened = true

  return true
end

---The Shivering, the kingdom and the environment.
---@class Shivering
---@field isle string "The island you're on, also known as your computer."
---@field enter function "Enter the madness, load all the modules."
---@field god function "Ascend to godhood, reach the Oblivion."
---@version 0.0.1
---@author Mestre Tramador
Shivering = protectedreadonly({
  isle = getos(),
  enter = autoload,
  god = protectedreadonly
}, "Shivering")

Shivering.enter()