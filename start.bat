@echo off
chcp 65001 >nul
title Video Downloader

echo 🎬 Video Downloader Launcher
echo.

REM Check Java
java -version >nul 2>&1
if errorlevel 1 (
    echo ❌ Java не найдена. Установите Java 17+:
    echo    Скачайте с https://adoptium.net/
    pause
    exit /b 1
)

echo ✅ Java найдена

REM Check if JAR exists
if not exist "target\video-downloader-1.0.0.jar" (
    echo 📦 JAR файл не найден. Собираю проект...
    
    call mvn -version >nul 2>&1
    if errorlevel 1 (
        echo ❌ Maven не найден. Установите Maven:
        echo    Скачайте с https://maven.apache.org/download.cgi
        pause
        exit /b 1
    )
    
    call mvn clean package -q
    
    if not exist "target\video-downloader-1.0.0.jar" (
        echo ❌ Ошибка сборки
        pause
        exit /b 1
    )
    
    echo ✅ Сборка завершена
)

REM Check if port is already in use
netstat -ano | findstr ":8080" >nul
if not errorlevel 1 (
    echo ⚠️  Порт 8080 занят. Останавливаю предыдущий процесс...
    for /f "tokens=5" %%a in ('netstat -ano ^| findstr ":8080"') do taskkill /F /PID %%a 2>nul
    timeout /t 2 /nobreak >nul
)

echo.
echo 🚀 Запускаю приложение...
echo.

REM Start Java application in background
start /B javaw -jar target\video-downloader-1.0.0.jar > app.log 2>&1

echo ⏳ Ожидание запуска...

set /a count=0
:wait_loop
    timeout /t 1 /nobreak >nul
    
    REM Check if service is ready using PowerShell
    powershell -Command "try { Invoke-WebRequest -Uri 'http://localhost:8080/api/video/status' -UseBasicParsing -ErrorAction Stop | Out-Null; exit 0 } catch { exit 1 }" >nul 2>&1
    
    if not errorlevel 1 (
        echo.
        echo ✅ Приложение запущено!
        echo.
        echo 🌐 Откройте в браузере: http://localhost:8080
        echo.
        echo 📋 Команды:
        echo    Остановить: taskkill /F /IM javaw.exe
        echo    Логи: type app.log
        echo.
        start http://localhost:8080
        exit /b 0
    )
    
    set /a count+=1
    if %count% GEQ 60 goto timeout
    echo|set /p=.
goto wait_loop

:timeout
echo.
echo ⚠️  Приложение запускается дольше обычного...
echo 🌐 Попробуйте открыть вручную: http://localhost:8080
echo.
echo 📋 Команды:
echo    Проверить логи: type app.log
echo    Остановить: taskkill /F /IM javaw.exe
echo.
pause
