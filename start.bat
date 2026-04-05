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

echo ✅ Java найденa

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

start /B java -jar target\video-downloader-1.0.0.jar > app.log 2>&1

set APP_PID=%!
echo ⏳ Ожидание запуска...

set /a count=0
:wait_loop
    timeout /t 1 /nobreak >nul
    curl -s http://localhost:8080/api/video/status >nul 2>&1
    if not errorlevel 1 (
        echo.
        echo ✅ Приложение запущено!
        echo.
        echo 🌐 Откройте в браузере: http://localhost:8080
        echo.
        echo 📋 Команды:
        echo    Остановить: taskkill /F /PID %APP_PID%
        echo    Логи: type app.log
        echo.
        pause
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
echo    Проверить статус: curl http://localhost:8080/api/video/status
echo    Остановить: taskkill /F /IM java.exe
echo.
pause
