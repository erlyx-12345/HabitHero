# Habit Hero API DOCUMENTATION

## Overview

HabitHero integrates with an external API to display motivational quotes to users. These quotes serve as encouragement for users to maintain consistency in building positive habits. The application fetches a daily motivational quote from the ZenQuotes API and displays it on the dashboard screen.

The API interaction is handled through a service class within the application, ensuring that the user interface remains responsive and organized while retrieving external data.

## API Provider

### ZenQuotes API

ZenQuotes is a public API that provides inspirational and motivational quotes. HabitHero uses this API to retrieve a daily quote that motivates users while tracking their habits.

- Base URL: `https://zenquotes.io/api`
- Official endpoint used in the project: `https://zenquotes.io/api/today`

## API Endpoint: Get Daily Quote

- HTTP Method: `GET`
- Endpoint: `/today`
- Full Request URL: `https://zenquotes.io/api/today`

Description: This endpoint retrieves a daily motivational quote along with the author's name. The response returns a JSON array containing the quote details.

## Example API Request

`GET https://zenquotes.io/api/today`

This request is triggered when the application loads the dashboard screen.

## Example JSON Response

`[{"q":"The secret of your future is hidden in your daily routine.","a":"Mike Murdock","h":"<blockquote>The secret of your future is hidden in your daily routine.</blockquote>"}]`

## Response Fields

- `q`: The motivational quote text
- `a`: The author of the quote
- `h`: HTML formatted quote

## API Integration in HabitHero

The API request is handled in the QuoteApiService class located in the service layer of the project. This class is responsible for sending HTTP requests and processing the returned JSON data.

Example code snippet used in the application:

`final response = await http.get(Uri.parse('https://zenquotes.io/api/today'));`

Once the data is received, the JSON response is parsed and the quote text and author are extracted for display.

## Data Processing

After retrieving the API response:

1. The system checks if the request is successful.
2. The JSON response is decoded.
3. The quote (`q`) and author (`a`) are extracted.
4. The quote is displayed on the dashboard screen.

## Error Handling

To ensure application reliability, HabitHero implements fallback handling when the API request fails due to network errors or server issues.

Possible scenarios include:

- Internet connection failure
- API server unavailability
- Invalid response format

If an error occurs, the system automatically displays a default motivational quote.

Example fallback quote:

`"The secret of your future is hidden in your daily routine." — Mike Murdock`

## HTTP Status Codes

- `200`: Request successful
- `400`: Bad request
- `404`: Resource not found
- `500`: Internal server error

## API Request Flow

1. The user opens the HabitHero application.
2. The dashboard screen is loaded.
3. The application sends a GET request to the ZenQuotes API.
4. The API returns a motivational quote in JSON format.
5. The application parses the response.
6. The quote and author are displayed on the dashboard.

## Project File Structure for API Integration

```
lib/
├── services/
│   └── quote_api_service.dart
├── screens/
    └── dashboard_screen.dart

```

- `quote_api_service.dart`: Handles API requests
- `dashboard_screen.dart`: Displays quotes to the user
- `quote_model.dart`: Represents the quote data structure

## Advantages of Using an External Quote API

Using the ZenQuotes API helps the HabitHero app because:

- It shows new motivational quotes (not the same quote every time).
- It helps keep users interested and motivated.
- The app does not need to save quotes inside the project.
- Quotes are updated daily, so the content stays fresh.

## Future API Improvements

In the future, the app could be improved by:

- Adding other quote APIs (more sources of quotes).
- Saving quotes so users can still see them without internet.
- Suggesting quotes based on what the user likes.
- Letting users choose quote categories (example: success, habits, health).