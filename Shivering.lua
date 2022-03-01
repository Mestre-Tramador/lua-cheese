-- #region WIP
-- Don't worry, pals, this requires will be used someday...
--
-- local driver = require "luasql.mysql"
-- local env = driver.mysql()
-- local db = env:connect('schema', 'username', 'password')
-- local lfs = require "lfs"
-- local cjson = require "cjson"
-- #endregion

---Just check if the Door to the Madness was opened.
---@type boolean
local opened = false

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
    ---@param room string "The Lua file."
    ---@return string "It follows the `require` syntax."
    local function makeroom(room) return dir:gsub("[\\/]", ".") .. "." .. room:gsub("%.lua$", "") end

    ---Make the door to enter, or assemble the subdirectory to scan, as a matter of speak.
    ---@param path string "The current path of the loader."
    ---@param room string "The directory to enter."
    ---@return string "It follows the OS folder separatr syntax."
    local function makedoor(path, room)
      ---The full path of the "door".
      ---@type string
      local door = path

      if(Shivering.isle == "DOS")
      then door = door .. "\\"
      else door = door .. "/"
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
        ---This room is a Lua module, then it is required.

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
Shivering = {
  isle = getos(),
  enter = autoload
}

Shivering.enter()