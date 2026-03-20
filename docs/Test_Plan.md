

**Davao Oriental State University**

College of Computing and Information Sciences

ITMSD 2 — Advance Mobile Application Development

| TEST PLAN |
| :---: |

Quality Assurance Strategy

Second Semester, Academic Year 2025–2026

**Group: HabitHero**

|   INSTRUCTIONS |
| :---- |
|   Both QA Engineers collaborate on this document during Week 13–14.   Define what will be tested, how, and when. This is your testing roadmap. |

# **1\. Test Strategy Overview**

**App Name: HabitHero**

**HabitHero** is a cross-platform habit tracker (Flutter) for iOS and Android built using SQLite for local data storage and a public REST API to pull motivational quotes. The overall test strategy consists of a two-part (dual-QA) approach that allows QA-1 **(**Christian Ville M. Ranque**)** to conduct functional and unit testing of core features (CRUD habit, track daily logs, calculate streaks, and maintain DB integrity). QA-2 **(**Albert Jhun Cañedo**)** will conduct widget, integration, system, and user acceptance testing on both screen flow and UI consistency. All test activities will follow entry criteria, only beginning execution after code has been merged and the pipeline has passed. Both QAs will work together to conduct regression testing, final verification, and to track/document/retest any bugs found during testing, such as failures to display a habit, failure to block completed habit actions, and missing functionality for deleting the user account. Automated flutter test runs will be supplemented with manual testing with a physical Android device (API 33/34) to cover edge cases not reachable by automated testing.

# **2\. Test Scope**

## **2.1 In Scope**

* All CRUD operations for each entity  
* Navigation between all screens  
* SQLite database operations  
* Form validation and error handling  
* Search and filter functionality  
* Streak and daily log tracking (currentStreak, bestStreak, daily\_logs table)  
* Motivational quote API — online fetch and offline fallback (QuoteApiService)  
* User onboarding — Hero name registration and target selection screens  
* Profile screen — user name display, profile image upload, and account reset  
* Dashboard date navigation and time-of-day filtering (All, Morning, Afternoon, Evening)

## **2.2 Out of Scope**

* Performance/load testing  
* Security penetration testing  
* iOS-specific testing (unless team has iOS devices)  
* Cloud synchronization and multi-device data merging  
* Social media API integrations

# **3\. Test Types**

| Test Type | Description | Tools | Owner |
| ----- | ----- | ----- | ----- |
| Unit Testing | Test individual functions and methods | flutter test | QA-1 \+ Devs |
| Widget Testing | Test UI components in isolation | flutter test | QA-2 |
| Integration Testing | Test screen-to-screen flows | flutter test integration | QA-2 |
| Manual Testing | Hands-on testing of all features | Physical device/emulator | Both QAs |
| Regression Testing | Re-test after bug fixes | All above | Both QAs |

# **4\. Test Environment**

| Environment | Details |
| ----- | ----- |
| Flutter Version | 3.41.2 |
| Dart Version | 3.11.0 (via Flutter SDK) |
| Test Device(s) | Android Phone (Physical Device) |
| Emulator | Android Emulator (AVD) via Android Studio |
| CI/CD | GitHub Actions |
| Database | SQLite (sqflite) |
| IDE | VS Code / Android Studio |

# **5\. Test Schedule**

| Phase | Week | Test Activities | Owner |
| ----- | ----- | ----- | ----- |
| Preparation | Week 13–14 | Write test plan, set up CI/CD | Both QAs |
| Sprint 1 Testing | Week 14 | Test core features, initial manual testing | QA-1 |
| Sprint 2 Testing | Week 15 | Test all features, full manual testing | Both QAs |
| Sprint 3 Testing | Week 16 | Regression, edge cases, final sweep | Both QAs |
| Final Verification | Week 17 | Verify all fixes, CI/CD green | Both QAs |

# **6\. Entry and Exit Criteria**

## **6.1 Entry Criteria (start testing when)**

* Feature code is merged to develop branch  
* CI/CD pipeline passes (flutter analyze \+ flutter test)  
* Developer has self-tested basic functionality

## **6.2 Exit Criteria (testing is complete when)**

* All test cases executed with pass/fail status  
* No critical or high-severity bugs remain open  
* CI/CD pipeline passes on main branch  
* All bug reports documented and tracked

# **7\. Bug Severity Definitions**

| Severity | Definition | Example |
| ----- | ----- | ----- |
| Critical | App crashes or data loss | Database corruption, unhandled exception |
| High | Major feature broken | Cannot save/edit records, navigation broken |
| Medium | Feature works but with issues | UI misalignment, slow performance |
| Low | Minor cosmetic issues | Typo, color inconsistency, spacing |

