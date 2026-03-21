

**Davao Oriental State University**

College of Computing and Information Sciences

ITMSD 2 — Advance Mobile Application Development

| PROJECT PROPOSAL |
| :---: |

Application Concept and Planning

Second Semester, Academic Year 2025–2026

**HabitHero**

**ALBERT JHUN CANEDO**

**JOHN MARK PAJA**

**STEPHEN PUSTA** 

**CHRISTIAN VILLE RANQUE**

**ARLENE ROLLORATA**

**JOSHUA SERRANO**

**MARL LAURENCE SORIANO**

# **1\. App Information**

**App Name: HabitHero**

**App Description:**

HabitHero is a mobile habit-tracking application that helps users build positive routines and stay consistent with their personal goals. The app allows users to create habits, record daily logs, monitor streaks, and stay motivated through inspirational quotes fetched from a motivational quotes API. With a simple and user-friendly design, HabitHero supports self-improvement by making habit tracking easy and engaging.

**Problem Statement:** 

Many individuals struggle to maintain consistency when developing good habits such as exercising, studying, or practicing self-care. They often lose motivation due to lack of visible progress and encouragement. Existing habit trackers may be overly complex or require constant internet access, which can discourage regular use. There is a need for a simple, single-user habit tracker that records daily logs, tracks streaks, and provides motivational support.

*What problem does your app solve? Why is it needed?*

*HabitHero addresses the challenge of maintaining motivation and consistency in habit formation. By enabling users to log daily habits, track streaks, and receive motivational quotes, the app encourages continuous progress and positive behavior. It is needed because many students and individuals want a lightweight, easy-to-use tool that helps them stay disciplined, monitor their growth, and remain inspired throughout their self-improvement journey.*

# **2\. Target Users**

**Primary Users:** 

* Students who want to build productive study routines and manage daily tasks  
* Individuals aiming to improve personal habits such as exercising, reading, or self-care  
* Busy people who need a simple tool to stay consistent with daily goals  
* Anyone seeking motivation and structure for self-improvement

**User Needs:**

* An easy way to create and manage daily habits  
* A simple system to log daily progress and track streaks  
* Motivation through inspirational quotes to stay encouraged  
* A clean and distraction-free interface for quick habit updates  
* Offline accessibility for convenient use anytime, anywhere  
  Visual progress tracking to monitor improvement over time

# **3\. Key Features**

List 4–6 key features your app will provide:

| \# | Feature Name | Description | Priority |
| ----- | ----- | ----- | ----- |
| 1 | Habit Management  | Users can create, edit, and delete habits they want to track. | Must Have |
| 2 | Daily Habit Logging | Users can mark habits as completed each day to track consistency. | Must Have |
| 3 | Streak Tracking & Progress | The app displays streak counts and progress summaries to motivate users. | Must Have |
| 4 | Motivational Quotes | Displays inspirational quotes to encourage users to stay consistent. | Should Have |
| 5 | Habit Reminder Notifications | Allows users to set reminders for their habits so they do not forget to complete them. | Nice to Have |

# **4\. Technology Stack**

| Component | Choice | Justification |
| ----- | ----- | ----- |
| Framework | Flutter | Flutter 3.19.0 is the best choice for HabitHero because it is the latest stable version, ensuring better performance, security updates, and compatibility with modern packages. It allows the team to build a smooth and responsive mobile app using a single codebase. Flutter’s rich UI widgets make it easy to create clean and user-friendly screens such as Habit List, Add Habit, and Daily Log. Its strong community support and documentation also help the team resolve issues quickly during development. |
| Database | SQLite (sqflite) | Local storage requirement |
| State Management | setState | setState is suitable because HabitHero has simple data updates such as marking habits as complete and updating streaks. It keeps the app easy to maintain and avoids unnecessary complexity that comes with advanced state management tools. This makes development faster and easier for the team. |
| REST API (if any) | API Ninjas Quotes API / ZenQuotes API | Used to display motivational quotes that encourage users to maintain their habits and stay motivated. The APIs are free, easy to integrate, and enhance user engagement by providing dynamic inspirational content. |
| Key Packages | sqflite: ^2.3.0 path: ^1.8.0 http: ^1.2.0 intl: ^0.19.0 | These packages support the core functionality of the HabitHero app. The **sqflite** package enables local database storage for habits, daily logs, and streak data, allowing the app to work offline. The **path** package ensures the database is stored correctly on the device. The **http** package allows the app to connect to the quote API and retrieve motivational messages. The **intl** package is used to format dates properly, which is essential for tracking daily logs and calculating streaks. Together, these packages ensure reliable data storage, accurate tracking, and dynamic motivational content.  |

# **5\. Team Members**

| Name | Student ID | Role | Assigned Features |
| ----- | ----- | ----- | ----- |
| ARLENE ROLLORATA | 2023- 0448 | Senior Fullstack Developer | Project setup & folder structure SQLite database setup (DatabaseHelper & CRUD operations) Data models (Habit, DailyLog, Streak logic) Service layer for data handling App navigation & routing setup Motivational Quotes API integration Shared widgets & theme setup Error handling & performance optimization Code review & pull request approval ERD & database design documentation Technical guidance & architecture decisions  |
| MARL LAURENCE SORIANO | 2023- 0030 | Junior Fullstack Developer | Habit List Screen Habit Detail Screen Search & filter habits Display streak & progress summary Connect screens to database layer Loading states & empty state UI Unit tests for viewing features |
| JOHN MARK PAJA | 2021- 3090 | Junior Fullstack Developer | Add Habit Screen Edit Habit Screen Delete habit feature Form validation & duplicate prevention Database insert/update/delete integration Success & error feedback messages Unit tests for habit management |
| JOSHUA SERRANO | 2023- 0387 | Junior Fullstack Developer | Daily Log Screen (mark habit complete) Streak tracking display Weekly progress summary Visual indicators for streaks Prevent duplicate logs per day Connect logs to database layer Unit tests for logging features |
| STEPHEN PUSTA | 2020- 1779 | Project Manager | Project proposal & documentation Sprint planning & task assignment Meeting minutes & progress tracking GitHub project board management User manual compilation README.md coordination Presentation slides preparation Team coordination & deadline monitoring Supporting screen: About App / Help |
| CHRISTIAN VILLE RANQUE | 2023- 0024 | QA Engineer (QA-1) | Test habit CRUD operations Verify daily logs & streak calculations Database accuracy & data persistence Functional test cases Bug reporting & verification |
| ALBERT JUHN CANEDO | 2021- 5350 | QA Engineer (QA-2) | UI/UX consistency testing Navigation & integration testing Responsive layout testing Motivational Quotes API display testing Edge case testing (empty states, no internet) Automated code checking and test running UI bug reports & usability feedback |

# **6\. Timeline Overview**

| Week | Sprint | Planned Activities |
| ----- | ----- | ----- |
| Week 13 | Planning | Finalize project idea and scope Assign roles and responsibilities Define app features and screen ownership Create GitHub repository and project board Design database structure (ERD) Prepare Project Proposal and initial SRS sections Create wireframes for assigned screens |
| Week 14 | Sprint 1 | Set up Flutter project and folder structure Implement SQLite database (tables & models) Develop basic UI layouts for all screens Implement navigation between screens Begin Habit List and Add Habit screens Conduct initial testing of UI navigation |
| Week 15 | Sprint 2 | Complete Habit management features (add, edit, delete) Implement Daily Log and streak tracking Connect screens to database (CRUD operations) Integrate motivational quotes API Add search and filter functionality QA begins functional and UI testing |
| Week 16 | Sprint 3 | Fix bugs identified by QA Improve UI consistency and responsiveness Add loading indicators and error handling Perform regression testing Optimize performance and finalize features Complete User Manual sections |
| Week 17 | Submission | Final code cleanup and merge to main branch Verify all features are working correctly Complete and compile documentation Finalize User Manual and README.md Ensure project meets submission requirements Submit final project files |
| Week 18 | Presentation | Group presentation and defense |

# **7\. Risks and Mitigation**

| Risk | Impact | Mitigation Strategy |
| ----- | ----- | ----- |
| API service unavailable or request limit reached | Medium | Use a fallback message or default motivational quote when the API fails. Implement error handling to ensure the app continues to function even without internet access. |
| Merge conflicts or overlapping code changes | High | Assign clear screen ownership to each developer and require pull requests for all changes. The Senior Developer will review and merge code to prevent conflicts. |
| Data loss or database errors | High | Test database operations thoroughly and implement validation checks before saving data. Regularly back up the project repository to prevent data loss. |
| Team member delays or missed deadlines | Medium | Use sprint planning and weekly check-ins to monitor progress. The Project Manager will track tasks and assist members who encounter blockers. |
| UI inconsistencies across screens | Medium | Use a shared theme and reusable widgets to maintain consistent design. QA will perform UI testing to ensure uniform layout and styling. |

