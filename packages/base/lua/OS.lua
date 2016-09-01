-------------------------------------------------------------------------------------------
-- TerraME - a software platform for multiple scale spatially-explicit dynamic modeling.
-- Copyright (C) 2001-2016 INPE and TerraLAB/UFOP -- www.terrame.org

-- This code is part of the TerraME framework.
-- This framework is free software; you can redistribute it and/or
-- modify it under the terms of the GNU Lesser General Public
-- License as published by the Free Software Foundation; either
-- version 2.1 of the License, or (at your option) any later version.

-- You should have received a copy of the GNU Lesser General Public
-- License along with this library.

-- The authors reassure the license terms regarding the warranties.
-- They specifically disclaim any warranties, including, but not limited to,
-- the implied warranties of merchantability and fitness for a particular purpose.
-- The framework provided hereunder is on an "as is" basis, and the authors have no
-- obligation to provide maintenance, support, updates, enhancements, or modifications.
-- In no event shall INPE and TerraLAB / UFOP be held liable to any party for direct,
-- indirect, special, incidental, or consequential damages arising out of the use
-- of this software and its documentation.
--
-------------------------------------------------------------------------------------------

-- @header Functions to handle files and directories.
-- Most of the functions bellow are taken from LuaFileSystem 1.6.2.
-- Copyright Kepler Project 2003 (http://www.keplerproject.org/luafilesystem).

--- Change the current working directory to the given path.
-- Returns true in case of success or nil plus an error string.
-- @arg path A string with the path.
-- @usage -- DONTRUN
-- chDir("c:\\tests")
function chDir(path)
	mandatoryArgument(1, "string", path)

	return lfs.chdir(path)
end

--- Return a string with the current working directory or nil plus an error string.
-- @usage cdir = currentDir()
-- print(cdir)
function currentDir()
	return lfs.currentdir()
end

--- Returns true if the operating system is Windows, otherwise returns false.
-- @usage if isWindowsOS() then
--     print("is windows")
-- else
--     print("not windows")
-- end
function isWindowsOS()
	if sessionInfo().separator == "/" then -- SKIP
		return false
	end
	
	return true
end

--- Return the files in a given directory.
-- @arg directory A string describing a directory. The default value is the current directory (".").
-- @arg all A boolean value indicating whether hidden files should be returned. The default value is false.
-- @usage files = dir()
--
-- forEachFile(files, function(file)
--     print(file)
-- end)
function dir(directory, all)
	if directory == nil then directory = "." end

	mandatoryArgument(1, "string", directory)
	optionalArgument(2, "boolean", all)

	if all == nil then all = false end
	
	local command 

	if all then
		command = "ls -a1 \""..directory.."\""
	else
		command = "ls -1 \""..directory.."\""
	end

	local result = runCommand(command)

	if not result or not result[1] then
		customError(directory.." is not a directory or is empty or does not exist.")
	end

	return result
end	

--- Return whether a given string represents a directory stored in the computer.
-- @arg path A string.
-- @usage if isDir("C:\\TerraME\\bin") then
--     print("is dir")
-- end
function isDir(path)
	mandatoryArgument(1, "string", path)

	if string.sub(path, -1) == "/" then
		path = string.sub(path, 1, -2)
	end	

	if lfs.attributes(path:gsub("\\$", ""), "mode") == "directory" then
		return true
	end
	
	return false
end

--- Create a lockfile (called lockfile.lfs) in path if it does not exist and returns the lock. 
-- If the lock already exists checks if it's stale, using the second argeter (default for the 
-- second argeter is INT_MAX, which in practice means the lock will never be stale.
-- In case of any errors it returns nil and the error message. In particular, if the lock
-- exists and is not stale it returns the "File exists" message.
-- @arg path A string with the path.
-- @usage ld = lockDir(packageInfo("base").path)
function lockDir(path)
	mandatoryArgument(1, "string", path)

	return lfs.lock_dir
end

--- Create a new directory. The argument is the name of the new directory.
-- Returns true if the operation was successful; in case of error, it returns nil plus an error string.
-- @arg path A string with the path.
-- @usage -- DONTRUN
-- mkDir("mydirectory")
function mkDir(path)
	mandatoryArgument(1, "string", path)

	return lfs.mkdir(path)
end

--- Remove an existing directory. It removes all internal files and directories
-- recursively. If the directory does not exist or it cannot be removed,
-- this function stops with an error.
-- @arg path A string with the path. The function will automatically add
-- quotation marks in the beginning and in the end of this argument in order
-- to avoid problems related to empty spaces in the string. Therefore,
-- this string must not contain quotation marks.
-- @usage mkDir("mydirectory")
--
-- rmDir("mydirectory")
function rmDir(path)
	mandatoryArgument(1, "string", path)

	if string.find(path, "\"") then
		customError("Argument #1 should not contain quotation marks.")
	elseif not isDir(path) then
		resourceNotFoundError(1, path)
	end

	local result = os.execute("rm -rf \""..path.."\"")

	if result ~= true then
		customError(result) -- SKIP
	end
end

--- Execute a system command and return its output. It returns two tables. 
-- The first one contains each standard output line as a position.
-- The second one contains  each error output line as a position.
-- @arg command A command.
-- @usage result, error = runCommand("dir")
function runCommand(command)
	mandatoryArgument(1, "string", command)

	local result, err = cpp_runcommand(command)

	local function convertToTable(str)
		local t = {}
		local i = 0
		local v
		local oldv = 0
		while true do
			i, v = string.find(str, "\n", i + 1) -- find 'next' newline
			if i == nil then break end
			table.insert(t, string.sub(str, oldv + 1, v - 1))
			oldv = v
		end

		return t
	end

	result = convertToTable(result)
	err = convertToTable(err)

	return result, err
end

--- Return information about the current execution. The result is a table
-- with the following values.
-- @tabular NONE
-- Attribute & Description \
-- dbVersion & A string with the current TerraLib version for databases. \
-- mode & A string with the current mode for warnings ("normal", "debug", or "quiet"). \
-- path & A string with the location of TerraME in the computer. \
-- separator & A string with the directory separator. \
-- silent & A boolean value indicating whether print() calls should not be shown in the
-- screen. This element is true when TerraME is executed with mode "silent".
-- @usage print(sessionInfo().mode)
function sessionInfo()
	return info_ -- this is a global variable created when TerraME is initialized
end

--- Create a temporary directory and return its name.
-- If this function is used without any argument, the directory will be deleted
-- in the end of the simulation. Otherwise, the modeler will need to remove the
-- directory manually if necessary.
-- If the directory was deleted between two calls of this function without any
-- argument then it is created again. 
-- @arg directory Name of the directory to be created. It might contain a path 
-- to a given directory
-- where the new one will be created. The end of the string might contain X's,
-- which are going to be replaced by random alphanumerica values in order to
-- guarantee that the created directory will not replace a previous one.
-- @usage tmpf = tmpDir("mytmpdir_XXX")
-- print(tmpf)
--
-- rmDir(tmpf)
function tmpDir(directory)
	if directory then
		optionalArgument(1, "string", directory)
		return runCommand("mktemp -d "..directory)[1]
	elseif not _Gtme.tmpdirectory__ then
		_Gtme.tmpdirectory__ = runCommand("mktemp -d .terrametmp_XXXXX")[1] -- SKIP
	elseif not isDir(_Gtme.tmpdirectory__) then
		os.execute("mkdir ".._Gtme.tmpdirectory__)
	end

	return _Gtme.tmpdirectory__
end

