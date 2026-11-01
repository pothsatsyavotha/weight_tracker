@echo off
REM Usage: build_and_deploy.bat C:\path\to\your\flutter_project
REM Optional: set APP_KEY=yourkey before running
if "%~1"=="" (echo Pass the path to your Flutter project & exit /b 1)
set HERE=%~dp0

pushd "%~1"
call flutter config --enable-web
if not exist web call flutter create . --platforms=web
if defined APP_KEY (
  call flutter build web --release --dart-define=APP_KEY=%APP_KEY%
) else (
  call flutter build web --release
)
if errorlevel 1 exit /b 1

del /q "%HERE%public\*" 2>nul
for /d %%D in ("%HERE%public\*") do rmdir /s /q "%%D"
xcopy /e /i /y build\web "%HERE%public" >nul
popd

pushd "%HERE%"
call vercel --prod
popd
