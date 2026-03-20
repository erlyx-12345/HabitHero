# HabitHero Architecture Documentation

---

## Introduction

HabitHero is a mobile application developed using Flutter that helps users manage habits, track daily activities, and monitor their progress over time.

In addition to tracking habits, the application also provides **motivational quotes** to encourage users and help them stay consistent in building positive routines.

To keep the system organized and easy to maintain, the application is structured into separate parts that handle user interface, logic, and data. This separation allows each part of the system to focus on a specific responsibility.

---

## Architecture Design

The application follows a **layered structure with controller-based logic**.

In this design:

- The user interface handles display and interaction
- Controllers manage how the app responds to user actions
- Services handle data processing and operations
- Models define how data is structured

This approach avoids mixing responsibilities and keeps the system clean and maintainable.

---

## System Structure

`User Interface (Screens)`

↓

`Controllers`

↓

`Services`

↓

`Data Sources (Database / API)`

↓

`Models`

Each layer communicates in a step-by-step flow, which makes the system easier to understand and debug.

---

## Project Structure

```
lib/
├── main.dart
├── components/
│   └── custom_navbar.dart
├── controllers/
│   ├── createhabit_controller.dart
│   ├── dashboard_controller.dart
│   ├── labs_controller.dart
│   ├── profile_controller.dart
│   ├── streaks_controller.dart
│   ├── target_controller.dart
│   ├── user_controller.dart
│   └── profile/
│       └── profile_controller.dart
├── models/
│   ├── daily_log.dart
│   ├── habit.dart
│   ├── habit_model.dart
│   └── user.dart
├── screens/
│   ├── create_habit_screen.dart
│   ├── dashboard_screen.dart
│   ├── habit_details_screen.dart
│   ├── hero_name_screen.dart
│   ├── home_screen.dart
│   ├── labs_screen.dart
│   ├── profile_screen.dart
│   ├── streaks_screen.dart
│   ├── welcome_screen.dart
│   └── profile/
│       └── profile_screen.dart
└── services/
    ├── database_helper.dart
    ├── habit_service.dart
    ├── notification_service.dart
    └── quote_api_service.dart
```

The structure groups related files together, which improves readability and keeps development organized.

---

## Component Explanation

### User Interface (Screens)

The screens are responsible for displaying information and interacting with the user.

They allow users to:

- Create and manage habits
- View progress and statistics
- Track daily activity
- Manage their profile

### Controllers

Controllers act as the middle layer between the UI and the data logic.

They are responsible for:

- Receiving input from the UI
- Deciding what action should be performed
- Calling the appropriate service
- Updating the UI when data changes

This keeps the UI simple and focused only on presentation.

### Services

Services handle the main logic related to data.

They are responsible for:

- Storing and retrieving data
- Communicating with the database
- Calling external APIs
- Managing background tasks such as notifications

This layer centralizes all data operations.

### Models

Models define the structure of the data used in the application.

They represent:

- Habit information
- User details
- Daily tracking records

Models help ensure data is consistent across the system.

### Components

Reusable UI elements are placed in a shared components folder.

These are used across multiple screens to:

- Keep the design consistent
- Reduce repeated code

---

## Data Flow

The application follows a clear flow of data:

`User Action`

↓

`UI (Screen)`

↓

`Controller`

↓

`Service`

↓

`Database / API`

↓

`Return Data`

↓

`UI updates`

This flow ensures that each part of the system has a clear responsibility.

---

## Database Architecture

The application uses a **local database system** based on SQLite (via `sqflite`).

**Pattern:** Singleton (`DatabaseHelper`) to ensure a single database instance and consistent access across the app.

**Operations supported:**

- Create
- Read
- Update
- Delete

---

## API Architecture

The application uses a **RESTful API** (HTTP-based communication).

### Details

- Implemented in the service layer (`quote_api_service.dart`)
- Uses HTTP GET requests to retrieve data
- Receives responses in JSON format
- JSON is parsed and converted into usable objects before being displayed in the UI

### Flow

`App`

→ `Service`

→ `HTTP Request`

→ `API`

→ `JSON Response`

→ `UI`

### Purpose

The API is mainly used to:

- Provide motivational quotes to users
- Add dynamic content that changes over time
- Improve user engagement by showing inspirational messages during habit tracking

---

## Technologies & Tools

### Language & Framework

- Dart
- Flutter

### Database

- SQLite (`sqflite`)

### API

- RESTful API
- `http` package

### Tools

- VS Code / Android Studio
- Flutter SDK
- Git & GitHub
- Emulator / Android device