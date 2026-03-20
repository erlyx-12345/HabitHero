

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

# **Sprint 2: Feature Development (Week 15\)**

## **Sprint 2 Goal**

Our Goal in this sprint is to enable users to log their daily progress, calculate completion streaks, and integrate the external motivational quotes API.

## **Sprint 2 Tasks**

| Task ID | Task Description | Assignee | Priority | Story Points | Status |
| ----- | ----- | ----- | ----- | ----- | ----- |
| S2-001 | Build the UI interaction for checking off a habit (checkbox or swipe).so users can easily find information.  | SORIANO, MARL LAURENCE A. | High | 3 | In Progress |
| S2-002 | Implement ***logCompletion()*** in **db\_service.dart** to insert into **daily\_logs.** | PAJA, JOHN MARK R. | High | 4 | In Progress |
| S2-003 | Write the SQL query to calculate ***currentStreak*** and ***bestStreak*** based on consecutive dates in **daily\_logs.** | ROLLORATA, ARLENE V. | High | 5 | In Progress |
| S2-004 | Update the Habit model and UI to display the calculated streaks. | SERRANO, JOSHUA S. | Medium | 3 | In Progress |
| S2-005 | Implement api\_service.dart to fetch data from the quotes API using the http package. | PAJA, JOHN MARK R. | High  | 4 | In Progress |
| S2-006 | Integrate the Quote model and display the daily quote on the Home Screen. | SORIANO, MARL LAURENCE A. | Medium | 3 | In Progress |
| S2-007 | Build offline fallback logic (displaying cached quotes if the API fetch fails). | ROLLORATA, ARLENE V. | Medium | 4 | In Progress |
| S2-008 | Conduct a mobile app security review, ensuring API payloads are handled safely and local SQLite data avoids exposure. | CAÑEDO, ALBERT JHUN P. | High | 5 | In Progress |
| S2-009 | Test offline mode behavior and API timeout handling. | RANQUE, CHRISTIAN VILLE M. | High | 3 | In Progress |

## **Sprint 2 Retrospective**

What went well:

* Daily check-in system and complex streak calculations (currentStreak, bestStreak) were successfully integrated using SQL queries. Team successfully developed and integrated key features like search and filtering.  
* The Motivational Quotes API was successfully integrated using the http package, including the offline fallback logic.

What could be improved:

* Managing state updates across the Habits List and Daily Log screens required careful ChangeNotifier coordination, which caused some minor merge conflicts.  
* Testing the API timeout and offline mode behavior required extra debugging to ensure the app didn't crash without internet. 

Action items for next sprint:

* Standardize our state management patterns across all controllers before moving on to the Statistics UI.  
* Running more tests on emulators without Wi-Fi to ensure the offline fallback message always works seamlessly. 

