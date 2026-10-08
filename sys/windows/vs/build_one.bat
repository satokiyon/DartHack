@echo off

if "%VSCMD_VER%"=="" (
	echo MSBuild environment not set ... attempting to setup build environment.
	call :setup_environment
)

if "%VSCMD_VER%"=="" (
	echo Unable to setup build environment.  Exiting.
	goto :EOF
)

msbuild NetHack.sln /t:Build "/p:Configuration=Release;Platform=x64"

goto :EOF

:setup_environment

if "%VS150COMNTOOLS%"=="" (
	call :set_vs15comntools
)

if "%VS150COMNTOOLS%"=="" (
	echo Can not find Visual Studio Common Tools path.
	echo Set VS150COMNTOOLS appropriately.
	goto :EOF
)

call "%VS150COMNTOOLS%VsMSBuildCmd.bat"
cd %~dp0

goto :EOF

:set_vs15comntools

if exist "C:\Program Files\Microsoft Visual Studio\18\Community\Common7\Tools" (
	set "VS150COMNTOOLS=C:\Program Files\Microsoft Visual Studio\18\Community\Common7\Tools\"
) else if exist "%ProgramFiles(x86)%\Microsoft Visual Studio\2017\Professional\Common7\Tools" (
	set "VS150COMNTOOLS=%ProgramFiles(x86)%\Microsoft Visual Studio\2017\Professional\Common7\Tools\"
) else if exist "%ProgramFiles(x86)%\Microsoft Visual Studio\2019\Community\Common7\Tools" (
	set "VS150COMNTOOLS=%ProgramFiles(x86)%\Microsoft Visual Studio\2019\Community\Common7\Tools\"
) else if exist "%ProgramFiles(x86)%\Microsoft Visual Studio\2022\Community\Common7\Tools" (
	set "VS150COMNTOOLS=%ProgramFiles(x86)%\Microsoft Visual Studio\2022\Community\Common7\Tools\"
) else if exist "%ProgramFiles%\Microsoft Visual Studio\2022\Community\Common7\Tools" (
	set "VS150COMNTOOLS=%ProgramFiles%\Microsoft Visual Studio\2022\Community\Common7\Tools\"
) else if exist "%ProgramFiles(x86)%\Microsoft Visual Studio\2017\Community\Common7\Tools" (
	set "VS150COMNTOOLS=%ProgramFiles(x86)%\Microsoft Visual Studio\2017\Community\Common7\Tools\"
)

goto :EOF
