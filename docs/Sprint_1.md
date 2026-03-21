

**Davao Oriental State University**

College of Computing and Information Sciences

ITMSD 2 — Advance Mobile Application Development

| SPRINT PLANNING |
| :---: |

Sprint Goals, Tasks, and Tracking

Second Semester, Academic Year 2025–2026

**Group: HabitHero**

|   INSTRUCTIONS |
| :---- |
|   The Project Manager fills out this document at the start of each sprint.   Update the status columns as work progresses. Include retrospective notes   at the end of each sprint. |

# **Sprint 1: Core Development (Week 14\)**

## **Sprint 1 Goal**

Establish the project architecture, set up local database persistence, and implement basic habit creation and viewing.

## **Sprint 1 Tasks**

| Task ID | Task Description | Assignee | Priority | Story Points | Status |
| ----- | ----- | ----- | ----- | ----- | ----- |
| S1-001 | Initialize Flutter project and set up the **lib/ folder structure (components, controllers, models, screens, services).**  | ROLLORATA, ARLENE V. | High | 5 | In Progress |
| S1-002 | Set up State Management boilerplate using **ChangeNotifier/Provider.** | ROLLORATA, ARLENE V. | High | 3 | In Progress |
| S1-003 | Define the base Habit and DailyLog data models. | SERRANO, JOSHUA S. | Medium | 3 | In Progress |
| S1-004 | Implement **db\_service.dart** and initialize SQLite using **sqflite**. | PAJA, JOHN MARK R. | High | 5 | In Progress |
| S1-005 | Create database tables for habits and **daily\_logs**. | PAJA, JOHN MARK. R. | High | 3 | In Progress |
| S1-006 | Build the Home Screen UI shell and empty state. | SORIANO, MARL LAURENCE A.  | Medium | 3 | In Progress |
| S1-007 | Create the **"Add Habit"** form (Title, Description, Frequency). | SERRANO, JOSHUA S.  | High | 4 | In Progress |
| S1-008 | Implement **createHabit() and getHabits()** in the database service and connect to the UI. | ROLLORATA, ARLENE V. | High | 5 | In Progress |
| S1-009 | Test SQLite database creation and basic CRUD operations on emulators. | RANQUE, CHRISTIAN VILLE M. | High | 4 | In Progress |
| S1-010 | Verify UI responsiveness across different simulated screen sizes. | CAÑEDO, ALBERT JHUN P. | Medium | 2 | In Progress |

## **Sprint 1 Retrospective**

**What went well:**

* Successfully initialized the Flutter project and established a clean, modular folder structure (components/, controllers/, models/, screens/, services/).  
* Local SQLite database (sqflite) and base tables (habits, daily\_logs) were implemented and tested smoothly.

**What could be improved:**

* Looking at the repository, all 29 commits are directly on the main branch. We didn't strictly follow the feature branching workflow yet.  
* Time estimation for the initial UI shell took slightly longer than expected due to setting up base widgets.

**Action items for next sprint:**

* Enforce the "Contributions and Workflow" outlined in the README: branch off a develop branch for new features and use Pull Requests.  
* Ensure local database migrations are handled cleanly if table structures change during tracking implementation.