::
:: TerraME - a software platform for multiple scale spatially-explicit dynamic modeling.
:: Copyright (C) 2001-2017 INPE and TerraLAB/UFOP -- www.terrame.org
::
:: This code is part of the TerraME framework.
:: This framework is free software; you can redistribute it and/or
:: modify it under the terms of the GNU Lesser General Public
:: License as published by the Free Software Foundation; either
:: version 2.1 of the License, or (at your option) any later version.
::
:: You should have received a copy of the GNU Lesser General Public
:: License along with this library.
::
:: The authors reassure the license terms regarding the warranties.
:: They specifically disclaim any warranties, including, but not limited to,
:: the implied warranties of merchantability and fitness for a particular purpose.
:: The framework provided hereunder is on an "as is" basis, and the authors have no
:: obligation to provide maintenance, support, updates, enhancements, or modifications.
:: In no event shall INPE and TerraLAB / UFOP be held liable to any party for direct,
:: indirect, special, incidental, or consequential damages arising out of the use
:: of this software and its documentation.

:: 
:: It performs TerraME compilation. It does not create installer or even build as bundle.'
::
::
:: USAGE:
:: terrame-build-windows-10.bat
::

:: Turn off system messages

@echo off

set "_CURL_DIR=C:\curl"
set "PATH=%PATH%;%_CURL_DIR%"

echo ""
echo "TerraME Dependencies compilation on Windows 10"
echo ""

set "_TERRALIB_3RDPARTY_NAME=terralib5-3rdparty-msvc12.zip"
set "_TERRALIB_TARGET_URL=http://www.dpi.inpe.br/terralib5-devel/3rdparty/src/$_TERRALIB_3RDPARTY_NAME"
set "_TERRAME_3RDPARTY_DIR=C:\MyDevel\terrame\daily-build\terrame\3rdparty"
set "_BUILD_PATH=C:\tme-3rdparty"
:: TerraLib 3rdparty variables
set "TERRALIB_X64=1"
set "_config=x64"
set "QMAKE_FILEPATH=C:\Qt\5.6\msvc2013_64\bin"
set "TERRALIB_DEPENDENCIES_DIR=C:\MyDevel\terrame\daily-build\terralib\3rdparty\5.2"
set "TERRALIB5_CODEBASE_PATH=%CD%\terralib"
set "VCVARS_FILEPATH=%PROGRAMFILES(x86)%\Microsoft Visual Studio 12.0\VC"

:: Configuring VStudio
echo | set /p="Configuring visual studio... "<nul

call "%VCVARS_FILEPATH%"\vcvarsall.bat %_config%

echo done.

echo | set /p="Cleaning up old builds ... "<nul
rmdir %_BUILD_PATH% /s /q >nul 2>nul
rmdir %TERRALIB_DEPENDENCIES_DIR% /s /q >nul 2>nul
rmdir %TERRALIB5_CODEBASE_PATH% /s /q >nul 2>nul
rmdir %_TERRAME_3RDPARTY_DIR% /s /q >nul 2>nul
mkdir %TERRALIB5_CODEBASE_PATH% /s /q >nul 2>nul
mkdir %_TERRAME_3RDPARTY_DIR% /s /q >nul 2>nul
echo done.

:: Downloading TerraLib
echo | set /p="Downloading TerraLib ... "<nul
git clone -b release-5.2 https://gitlab.dpi.inpe.br/rodrigo.avancini/terralib.git %TERRALIB5_CODEBASE_PATH% --quiet
echo done.
:: Downloading TerraME
echo | set /p="Downloading TerraME ... "<nul
git clone https://github.com/TerraME/terrame.git terrame --quiet
echo done.

echo | set /p="Downloading TerraLib 3rdparty ... "<nul
curl -L -s -O %_TERRALIB_TARGET_3RDPARTY_DIR%
echo done.

copy terrame\build\scripts\win\terrame-deps-conf.bat %_TERRAME_3RDPARTY_DIR%
:: Extracting TerraLib 3rdparty and moving short-named directory. It prevents Windows directory and filename limitation (255 chars)
"C:\Program Files\7-Zip\7z.exe" x terralib-3rdparty-msvc12.zip -y
mv terralib-3rdparty-msvc12 %_BUILD_PATH%
cd %_BUILD_PATH%\terralib-3rdparty-msvc12

:: Compile TerraLib 3rdparty Dependencies
start /wait %TERRALIB5_CODEBASE_PATH%\install\install-3rdparty.bat

cd %_TERRAME_3RDPARTY_DIR%

echo | set /p="Downloading Protobuf ... "<nul
curl -O -J -L https://github.com/google/protobuf/releases/download/v2.6.1/protobuf-2.6.1.zip --silent
echo done.
"C:\Program Files\7-Zip\7z.exe" x protobuf-2.6.1.zip -y
rename protobuf-2.6.1 protobuf

echo | set /p="Downloading Luacheck ... "<nul
curl -L -s -O https://github.com/mpeterv/luacheck/archive/0.17.0.zip
echo done.
"C:\Program Files\7-Zip\7z.exe" x 0.17.0.zip -y
rename luacheck-0.17.0 luacheck

copy %WORKSPACE%\build\scripts\win\terrame-deps-conf.bat .
:: Installing Luacheck
call terrame-deps-conf.bat

:: Compiling Protobuf
cd %_TERRAME_3RDPARTY_DIR%\protobuf\vsprojects
msbuild /m protobuf.sln /target:libprotobuf /p:Configuration=Release /p:Platform=x64 /maxcpucount:4
msbuild /m protobuf.sln /target:libprotobuf-lite /p:Configuration=Release /p:Platform=x64 /maxcpucount:4
msbuild /m protobuf.sln /target:libprotoc /p:Configuration=Release /p:Platform=x64 /maxcpucount:4
msbuild /m protobuf.sln /target:protoc /p:Configuration=Release /p:Platform=x64 /maxcpucount:4
:: Extract Protobuf includes
call extract_includes.bat
:: Copying Protobuf includes
xcopy include %_TERRAME_3RDPARTY_DIR%\install\include /i /h /e /y

exit %ERRORLEVEL%