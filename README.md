# Video Downloader

Spring Boot приложение для скачивания видео с YouTube, Instagram, VK и других платформ.

## Особенности

- 🎬 Скачивание видео через yt-dlp
- 🌐 Веб-интерфейс для удобной работы
- 📦 yt-dlp встроен в приложение (не требует установки)
- 🔒 Один видео-файл за раз (очередь загрузок)

## Требования

- Java 17+

## Сборка

```bash
mvn clean package
```

## Запуск

```bash
java -jar target/video-downloader-1.0.0.jar
```

Приложение будет доступно на http://localhost:8080

## Использование

1. Откройте http://localhost:8080 в браузере
2. Вставьте ссылку на видео (YouTube, Instagram, VK и др.)
3. Нажмите "Скачать видео"
4. Дождитесь окончания загрузки
5. Нажмите "Скачать файл" чтобы сохранить видео

## API

| Метод | Путь | Описание |
|-------|------|----------|
| `POST` | `/api/video` | Начать загрузку |
| `GET` | `/api/video/status` | Проверить статус |
| `GET` | `/api/video/file` | Скачать готовый файл |
| `DELETE` | `/api/video` | Очистить и начать заново |

## Docker

```bash
docker build -t video-downloader .
docker run -p 8080:8080 video-downloader
```

## Структура проекта

```
video-downloader/
├── src/main/java/com/example/downloader/
│   ├── VideoDownloaderApplication.java
│   ├── controller/VideoController.java
│   └── service/VideoService.java
├── src/main/resources/
│   ├── static/index.html
│   └── bin/yt-dlp
├── pom.xml
└── Dockerfile
```
