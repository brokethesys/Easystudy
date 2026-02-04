# Техническая (технологическая) документация EasyStudy

Дата: 2026-02-04

## 1. Назначение документа
Этот документ описывает технические аспекты кода и инфраструктуры EasyStudy: сборка, запуск, зависимости, структура модулей, ключевые классы и форматы данных.

## 2. Требования и окружение
- Flutter SDK (актуальная стабильная версия).
- Dart SDK (идет с Flutter).
- Android Studio / Xcode (для мобильных платформ).
- Python 3.10+ (для backend сервиса).

## 3. Сборка и запуск

### 3.1 Клиент (Flutter)
```bash
flutter pub get
flutter run
```

Сборка релиза:
```bash
flutter build apk
flutter build ios
```

### 3.2 Backend (FastAPI)
```bash
cd backend
python -m venv .venv
source .venv/bin/activate
pip install -r requirements.txt
uvicorn app:app --reload --port 8000
```

## 4. Конфигурация

### 4.1 Backend URL
Клиент ожидает переменную окружения:
- `BACKEND_URL` — базовый адрес API.
По умолчанию: `http://10.0.2.2:8000`.

### 4.2 Backend переменные
- `JWT_SECRET` (обязательно для prod)
- `JWT_TTL_MIN` (по умолчанию `43200`)
- `CORS_ORIGINS` (по умолчанию `*`)

## 5. Структура проекта
```
lib/
  main.dart
  data/
    game_state.dart
    account_service.dart
    backend_client.dart
  audio/
    audio_manager.dart
  screens/
    home_screen.dart
    welcome_screen.dart
    map_screen.dart
    quiz_screen.dart
    subquestion_screen.dart
    shop_screen.dart
    achievements_screen.dart
    settings_screen.dart
  widgets/
    top_hud.dart
    settings_panel.dart
  theme/
    app_theme.dart
assets/
  questions/
    software_engineering.json
backend/
  app.py
  data/
  requirements.txt
```

## 6. Ключевые модули и классы

### 6.1 `GameState` (`lib/data/game_state.dart`)
Единый источник состояния:
- Пользователь: `nickname`, `playerLevel`, `currentXP`, `coins`.
- Настройки: `soundEnabled`, `musicEnabled`, `vibrationEnabled`, `musicVolume`, `themeMode`.
- Прогресс: `currentSubject`, `currentLevels`, `completedLevels`, `unlockedTickets`.
- Билеты: `ticketsProgress` (карта `TicketProgress`).
- Магазин: `ownedBackgrounds`, `ownedFrames`, `ownedAvatars`.
- Достижения: `collectedAchievements`.

Сериализация:
- `TicketProgress.serialize()` / `deserialize()` — компактная строка.
- `GameState.toConfigMap()` — JSON-слепок для sync.
- `GameState.applyConfigMap()` — применяет серверный слепок.

### 6.2 `AccountService` (`lib/data/account_service.dart`)
Логика аккаунтов и синхронизации:
- `register`, `login`, `syncUp`, `syncDown`.
- Хранит токен и email в `SharedPreferences`.

### 6.3 `BackendClient` (`lib/data/backend_client.dart`)
HTTP клиент:
- `POST /auth/register`
- `POST /auth/login`
- `GET /config`
- `PUT /config`

### 6.4 `AudioManager` (`lib/audio/audio_manager.dart`)
Singleton:
- Фоновая музыка (loop).
- Звуки: `tap`, `correct`, `wrong`, `win`, `level_up`.
- Методы: `setMusicEnabled`, `setSoundEnabled`, `setMusicVolume`.

## 7. Экраны и навигация

Маршруты в `main.dart`:
- `/welcome` → `WelcomeScreen`
- `/home` → `HomeScreen`
- `/map` → `MapScreen`

Основные экраны:
- `MapScreen` — карта уровней, выбор билета.
- `QuizScreen` — прогресс и вход в вопросы.
- `SubquestionScreen` — поэтапные вопросы.
- `ShopScreen`, `AchievementsScreen`, `SettingsScreen`.

Навигация: стандартный `Navigator` + `MaterialPageRoute`.

## 8. Хранение данных

### 8.1 Локальное
Используется `SharedPreferences`:
- Настройки и прогресс сохраняются по ключам в `GameState`.
- Сериализация прогресса билетов: строковые записи.

### 8.2 Серверное
Backend хранит JSON-конфиги:
- `backend/data/users.json`
- `backend/data/configs/<user_id>.json`

## 9. Формат данных вопросов
`assets/questions/software_engineering.json`
- `tickets`: список билетов
- `ticket.id`: номер
- `ticket.subquestions`: список вопросов

## 10. Сборка UI-тем
`lib/theme/app_theme.dart`:
- Светлая/темная темы
- Связана с `GameState.themeMode`

## 11. Тестирование
В репозитории нет автоматизированных тестов.
Рекомендуется добавить:
- unit-тесты для `GameState` (сериализация, прогресс).
- widget-тесты для основных экранов.

## 12. Известные ограничения
- Backend file-based, без масштабирования.
- Отсутствует стратегия разрешения конфликтов при sync.
- Единый JSON с вопросами без разделения по предметам.
