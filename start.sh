#!/bin/bash

# Video Downloader Launcher
# Запускает приложение на http://localhost:8080

set -e

APP_NAME="video-downloader"
JAR_FILE="target/video-downloader-1.0.0.jar"
PORT=8080

# Colors
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m' # No Color

echo -e "${GREEN}🎬 Video Downloader Launcher${NC}"
echo ""

# Check Java
if ! command -v java &> /dev/null; then
    echo -e "${RED}❌ Java не найдена. Установите Java 17+:${NC}"
    echo "   macOS: brew install openjdk@17"
    echo "   Ubuntu: sudo apt install openjdk-17-jdk"
    exit 1
fi

JAVA_VERSION=$(java -version 2>&1 | head -1 | cut -d'"' -f2 | cut -d'.' -f1)
if [ "$JAVA_VERSION" -lt 17 ]; then
    echo -e "${RED}❌ Требуется Java 17+. У вас: Java $JAVA_VERSION${NC}"
    exit 1
fi

echo -e "${GREEN}✅ Java найден:$(java -version 2>&1 | head -1 | cut -d'"' -f2)${NC}"

# Check if JAR exists
if [ ! -f "$JAR_FILE" ]; then
    echo -e "${YELLOW}📦 JAR файл не найден. Собираю проект...${NC}"
    
    if ! command -v mvn &> /dev/null; then
        echo -e "${RED}❌ Maven не найден. Установите Maven:${NC}"
        echo "   macOS: brew install maven"
        echo "   Ubuntu: sudo apt install maven"
        exit 1
    fi
    
    mvn clean package -q
    
    if [ ! -f "$JAR_FILE" ]; then
        echo -e "${RED}❌ Ошибка сборки${NC}"
        exit 1
    fi
    
    echo -e "${GREEN}✅ Сборка завершена${NC}"
fi

# Check if port is already in use
if lsof -ti:$PORT &> /dev/null; then
    echo -e "${YELLOW}⚠️  Порт $PORT занят. Останавливаю предыдущий процесс...${NC}"
    lsof -ti:$PORT | xargs kill -9 2>/dev/null || true
    sleep 2
fi

# Start application
echo ""
echo -e "${GREEN}🚀 Запускаю приложение...${NC}"
echo ""

java -jar "$JAR_FILE" &
APP_PID=$!

# Wait for application to start
echo -n "⏳ Ожидание запуска"
for i in {1..60}; do
    if curl -s http://localhost:$PORT/api/video/status &> /dev/null; then
        echo ""
        echo ""
        echo -e "${GREEN}✅ Приложение запущено!${NC}"
        echo ""
        echo -e "${GREEN}🌐 Откройте в браузере: http://localhost:$PORT${NC}"
        echo ""
        echo "📋 Команды:"
        echo "   Остановить: kill $APP_PID"
        echo "   Логи: tail -f /tmp/video-downloader.log"
        echo ""
        exit 0
    fi
    echo -n "."
    sleep 1
done

echo ""
echo -e "${YELLOW}⚠️  Приложение запускается дольше обычного...${NC}"
echo -e "${GREEN}🌐 Попробуйте открыть вручную: http://localhost:$PORT${NC}"
echo ""
echo "📋 Команды:"
echo "   Проверить статус: curl http://localhost:$PORT/api/video/status"
echo "   Остановить: kill $APP_PID"
echo ""
exit 0
