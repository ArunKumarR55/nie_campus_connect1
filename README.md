CampusBot: A Smart College AI Assistant

An intelligent campus assistant powered by the Google Gemini API to answer student queries (faculty, schedules, timetables, scholarships, clubs, placements, and more) from a SQL database via WhatsApp.

The core of the project is built with Python (Flask) and uses the Google Gemini API for Natural Language Understanding (NLU) and the Twilio API for WhatsApp integration.

Key Features

Natural Language Understanding: Uses the Google Gemini API (gemini-2.5-flash-preview-09-2025) to understand user intent (e.g., get_faculty_info) and extract entities (e.g., faculty_name: "Dr. Anitha").

Twilio WhatsApp Integration: Connects to the Twilio API, using webhooks (/twilio) to receive incoming messages and send formatted replies back to users on WhatsApp.

Database-Backed: Queries a central SQL database (database.py) to fetch real-time, accurate information.

Web Test Environment: Includes a simple HTML/JavaScript test page (index.html) served from the root (/) to allow for direct testing of the bot's logic via a browser interface before connecting to WhatsApp.

Conversation Memory: Remembers context for follow-up questions (e.g., asking for a timetable and then specifying the day).

Smart Fallback Logic: When the bot recognizes an intent but can't find the data (e.g., a new faculty member), it provides a Google Form link for users to suggest missing information, helping to improve the database.

Resilient API Calls: Includes exponential backoff and retry logic for handling API errors (like 503 Service Unavailable).

Supported Queries

The bot is currently trained to handle intents for:

Faculty Info: "Who is the principal?" or "Tell me about Dr. Anitha"

Class Timetables: "What is the 3rd year CSE 'A' section timetable for Monday?"

Scholarship Info: "How can i contact the scholarship section?"

...and many more (Clubs, Events, Placements, Fees, Hostels, etc.)

Tech Stack

Backend: Flask

AI / NLU: Google Gemini API

Messaging: Twilio API for WhatsApp

Database: MySQL (via mysql-connector-python)

Core Logic: asyncio for asynchronous API calls

Configuration: python-dotenv for environment variable management

