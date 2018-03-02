@echo off

set PHP=0
set CMD="help"
set DEBUG=0
set VERSIONS="5.6" "7.0" "7.1" "7.2"

:: Display help and usage, skip the rest of the script
if "%1" == "" ( goto displayHelp )
if /I "%1" == "help" ( goto displayHelp )
if /I "%2" == "help" ( goto displayHelp )

:: To continue, we need to check if the first arg is a supported php version
for %%i in (%VERSIONS%) do (
    if /I "%1" == "%%~i" (
        set PHP=php%1
        set CMD=%2
    )
)

:: Fallback to the default php version
if %PHP% == 0 (
    echo The specified PHP version is not supported. Please use one of:
    echo.
    echo  %VERSIONS%
    echo.
    goto end
)

:: Name of the docker image and location of the dockerfile
set SUITE_DIR=%~dp0
set DOCKER_DIR=%SUITE_DIR%%PHP%
set DOCKER_IMG=phpsuite/docker-%PHP%

if "%CMD%" == "" ( set CMD=info )
if /I "%CMD%" == "info" (
    echo Toon info
    echo.
    echo Dockerfile:  %DOCKER_DIR%\Dockerfile
    echo Image name:  %DOCKER_IMG%
    echo.
    call phpsuite %1 -- php -v
    echo.
    call phpsuite %1 -- composer --version
    call phpsuite %1 -- phpcs --version
    call phpsuite %1 -- phpmd --version
    call phpsuite %1 -- phpstan --version
    goto end
)

:: Remove the php version and action arguments from the arguments list %*,
:: we don't need them anymore
shift
shift

:: Build the image from where we can start a container
if /I "%CMD%" == "build" (
    docker build -t %DOCKER_IMG% %DOCKER_DIR% --pull
    goto end
)

if not "%CMD%" == "--" (
    echo Invalid action "%CMD%"!
    echo.
    goto displayHelp
)

:: Strip the php version and -- command from the args list
set ARGS=%*
set ARGS=%ARGS:~7%

:: When the first argument (after --) is a valid filename, prepend the
:: arguments list with php so it's executed with php cli
if not "%1" == "" (
    if exist "%cd%\%1" (
        set ARGS=php %ARGS%
    )

    rem if %1 starts with . args[] = php
)

:: Figure out in wich folder and drive we're currently working.
:: These will be used to mount the complete drive in docker
:: to make sure local scripts work with in expected path
set CWD_DRIVE=%cd:~0,1%
set CWD_PATH=%cd:~3%
if not "%CWD_PATH%" == "" (
    set CWD_PATH=%CWD_PATH:\=/%
)

:: Create the actual docker run command options
set OPTIONS=--rm -it -p 2375 ^
            --name %PHP% ^
            --volume %CWD_DRIVE%:\:/mnt/%CWD_DRIVE% ^
            --volume %SUITE_DIR%.cache\%PHP%\composer:/root/.composer/cache ^
            --workdir /mnt/%CWD_DRIVE%/%CWD_PATH%

if %DEBUG%==1 (
    echo.
    echo Dockerfile:  %DOCKER_DIR%\Dockerfile
    echo Image name:  %DOCKER_IMG%
    echo Options:     %OPTIONS%
    echo Command:     %ARGS%
    echo.
)

docker run %OPTIONS% %DOCKER_IMG% %ARGS%
goto end

:displayHelp
echo phpsuite 0.1
echo.
echo Usage:
echo   phpsuite [version] [action] [args]
echo.
echo Supported versions:
echo   %VERSIONS%
echo.
echo Actions:
echo   help     Display this help section
echo   build    Build the Docker image for the specified version
echo   info     Display info about the tools inside the Docker image
echo   --       Run a command in the Docker container
echo.
echo Examples:
echo   phpsuite help
echo   phpsuite 7.2 build
echo   phpsuite 7.1 -- composer -v
echo.

:end
exit /b
