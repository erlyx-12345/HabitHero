

**Davao Oriental State University**

College of Computing and Information Sciences

ITMSD 2 — Advance Mobile Application Development

| TEST CASE REPORT |
| :---: |

Test Execution and Results

Second Semester, Academic Year 2025–2026

**Group: HabitHero**

|   INSTRUCTIONS |
| :---- |
|   QA Engineers write test cases as features are completed. Execute each   test case and record the result. Use PASS, FAIL, or BLOCKED as status.   Add more rows as needed. Each QA owns their test focus area. |

# **1\. Test Summary**

| Metric | Count |
| ----- | ----- |
| Total Test Cases | 11 |
| Passed | 8 |
| Failed | 3 |
| Blocked | 0 |
| Not Executed | 0 |
| Pass Rate | 72.73% |

# **2\. Functional Test Cases (QA-1)**

| TC-ID | Test Case Description | Steps | Expected Result | Actual Result | Status | Tester |
| ----- | ----- | ----- | ----- | ----- | ----- | ----- |
| TC-001 | Create new habit | 1\. Tap \+ on Dashboard2\. Fill title, select focus area3\. Tap Save | Habit saved to habits table and appears on Dashboard | Habit saved to habits table and appeared as a card on the Dashboard immediately after tapping Save.  | **PASS** | Albert Jhun Cañedo |
| TC-002 | View habit details | 1\. Tap a habit card on Dashboard2\. View habit details screen | Habit title, streak, focus area, and time of day all displayed correctly | Habit title, streak count, focus area, and time of day all displayed correctly on the Habit Details screen.  | **PASS** | Albert Jhun Cañedo |
| TC-003 | Update existing habit | 1\. Open habit details2\. Tap Edit3\. Modify title or settings4\. Save | Changes saved to habits table and reflected on Dashboard | Updated fields reflected in the habits table. Changes visible on Dashboard card after saving.  | **PASS** | Albert Jhun Cañedo |
| TC-004 | Delete habit | 1\. Open habit details2\. Tap Delete3\. Confirm deletion | Habit removed from habits table. Daily logs cascade-deleted. Card gone from Dashboard | Habit removed from the habits table. Daily logs cascade-deleted. Habit card no longer visible on Dashboard.  | **PASS** | Albert Jhun Cañedo |
| TC-005 | Log daily habit completion | 1\. On Dashboard tap completion button on a habit2\. Check daily\_logs table | Row inserted with correct habitId, date, isCompleted=1. Habit shows as completed | daily\_logs row inserted with correct habitId, today's date, and isCompleted=1. Habit card showed as completed with reduced opacity.  | **PASS** | Albert Jhun Cañedo |
| TC-006 | Time-of-day filter on Dashboard | 1\. On Dashboard select Morning filter2\. Observe habit list | Only habits with timeOfDay \= Morning shown. Others hidden | Dashboard showed 'No habits for this selection.' when Morning filter was applied. Habits created during a passed time slot were hidden due to an isCompleted=-1 log entry inserted at creation time, preventing them from appearing under any filter. See BUG-006.  | **FAIL** | Albert Jhun Cañedo |

# **3\. UI/Integration Test Cases (QA-2)**

| TC-ID | Test Case Description | Steps | Expected Result | Actual Result | Status | Tester |
| ----- | ----- | ----- | ----- | ----- | ----- | ----- |
| TC-101 | Screen navigation flow | 1\. Launch app2\. Navigate Welcome \> Target \> Dashboard3\. Tap each navbar tab4\. Use back button | All screens reachable, back navigation works, no crash | All screens reachable via navbar tabs (Targets, Streaks, Labs). Back navigation worked correctly on all flows. No crash observed.  | **PASS** | Christian Ville M. Ranque |
| TC-102 | Empty state on Dashboard | 1\. Ensure no habits in DB2\. Open Dashboard | Friendly empty state message shown, no crash, no blank screen | Empty state message 'No habits for this selection.' displayed correctly on Dashboard when no habits exist. App did not crash and no blank screen appeared.  | **PASS** | Christian Ville M. Ranque |
| TC-103 | Form validation — empty habit title | 1\. Open create habit screen2\. Leave title blank3\. Tap Save | Validation error shown. Habit NOT saved to database | No validation error shown for blank habit title. App proceeded to the duplicate check and displayed 'Already Exist' dialog instead of a required-field error. Habit with blank name was not blocked at the UI level.  | **FAIL** | Christian Ville M. Ranque |
| TC-104 | Theme consistency across screens | 1\. Navigate through all screens2\. Check colors and fonts | Consistent green (\#10B981), Poppins font, and spacing across all screens | Consistent green (\#10B981), Poppins font, and uniform spacing confirmed across Dashboard, Create Habit, Streaks, and Profile screens.  | **PASS** | Christian Ville M. Ranque |
| TC-105 | Welcome screen smoke test (widget test) | 1\. Run flutter test2\. App pumped with WelcomeScreen | RichText containing HabitHero visible. Get Started button found. No counter widget | Test failed: find.textContaining('Habit') returned 0 widgets — RichText/TextSpan not detected by plain text finder. Button text mismatch: test expected 'GET STARTED' but actual label is 'Get Started'.  | **FAIL** | Christian Ville M. Ranque |

