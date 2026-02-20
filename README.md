# HabitHero

**HabitHero** is a mobile habit tracker designed to help users build positive routines, monitor daily progress, and maintain streaks. The app promotes consistency, accountability, and personal growth through simple tracking and visual feedback.

---

## Project Overview

The HabitHero application allows users to:

- Manage personal habits  
- Log daily progress  
- Maintain streaks for consistency  
- Stay motivated with quotes from a Motivational Quotes API  

This application is developed as part of the **Advance Mobile Application Development** course. It demonstrates Flutter development, SQLite integration, and collaborative Git workflow practices.

---

## Features

- Create and manage daily habits  
- Track progress and streaks  
- View habit history  
- Simple and user-friendly interface
- Motivational quotes via API integration  
- Offline data storage using SQLite

---
## API Integration

The app integrates a **Motivational Quotes API** to display inspiring quotes that encourage users to stay consistent with their habits.

**Example Use:**
- Display a quote on the home screen
- Show a new quote each day

---
## Tech Stack

- **Framework:** Flutter  
- **Language:** Dart  
- **Database:** SQLite  
- **API:** Motivational Quotes API  
- **Version Control:** Git & GitHub

---
## Branching Strategy

- **main** ensures a stable, submission-ready version of the project.  
- **develop** allows safe collaboration and integration of team contributions.  

---
### 📌 Workflow

1. Create branch from `develop`
2. Implement feature or fix
3. Submit Pull Request → `develop`
4. Final merge → `main` (protected)

---
## Project Structure

lib/
├── models/
├── services/
├── screens/
├── widgets/
└── main.dart

---

## How to Run the Project

1. Clone the repository  
2. Open in VS Code or Android Studio  
3. Run the following commands:
   - flutter pub get
   - flutter run
