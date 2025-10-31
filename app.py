import os
import json
import logging
import asyncio # For async operations
import datetime # For timedelta conversion in formatting
from dotenv import load_dotenv

# --- FIX 1: Load .env file at the very top ---
# This MUST be called before importing other modules that need .env variables
load_dotenv()

from flask import Flask, request, render_template, jsonify
from twilio.twiml.messaging_response import MessagingResponse

# Import custom modules
import database
import gemini_client

# Configure logging
logging.basicConfig(level=logging.INFO, format='%(asctime)s - %(levelname)s - %(message)s')

# --- Flask App Initialization ---
# Tell Flask to look for templates/static files in the 'static' directory
app = Flask(__name__, template_folder='static', static_folder='static')

# --- Conversation Memory (Simple Dictionary) ---
# Store context for follow-up questions (e.g., timetable day)
# Key: user identifier (e.g., phone number), Value: dictionary of remembered entities
conversation_memory = {}

# --- Helper Functions ---

def format_timetable_response(results, entities):
    """Formats timetable results into a readable string."""
    if not results:
        return "I couldn't find any timetable entries matching your request."

    # --- Use entities passed from process_message for the title ---
    branch = entities.get('branch', 'Unknown Branch')
    section = entities.get('section', 'Unknown Section')
    year = entities.get('year', 'Unknown Year')
    day = entities.get('day', 'Unknown Day') # Get the specific day
    # --- End change ---

    response_lines = [f"Here is the schedule for {year} year {branch} {section} section on {day.capitalize()}:"]
    response_lines.append(f"\n--- {day.upper()} ---")

    current_time = None
    for row in results:
        # Format time - handles time objects now
        start_time_str = row['start_time'].strftime("%I:%M %p") if isinstance(row['start_time'], datetime.time) else "N/A"
        end_time_str = row['end_time'].strftime("%I:%M %p") if isinstance(row['end_time'], datetime.time) else "N/A"
        time_slot = f"{start_time_str} - {end_time_str}"

        # Group by time slot
        if time_slot != current_time:
            # response_lines.append("-" * 20) # Optional separator
            current_time = time_slot

        details = [f"{time_slot}: {row['course_name'] or 'N/A'}"]
        if row.get('faculty_name'):
            details.append(f"({row['faculty_name']})")
        location_parts = [part for part in [row.get('room_no'), row.get('location')] if part]
        if location_parts:
            details.append(f"@ {' - '.join(location_parts)}")
        if row.get('class_type') and row['class_type'].lower() != 'lecture':
            details.append(f"[{row['class_type']}]")
        if row.get('lab_batch'):
            details.append(f"(Batch {row['lab_batch']})")

        response_lines.append("\n".join(details))
        response_lines.append("") # Add a blank line for spacing


    return "\n".join(response_lines).strip()

def format_faculty_response(results):
    """Formats faculty results into a readable string."""
    if not results:
        return "I couldn't find information for that faculty member."

    response_lines = []
    if len(results) == 1:
        faculty = results[0]
        response_lines.append(f"Hello there! I found details for {faculty.get('name', 'N/A')}.")
        if faculty.get('department'):
            response_lines.append(f"\n**Department/Role:** {faculty['department']}")
        if faculty.get('email'):
            response_lines.append(f"**Email:** {faculty['email']}")
        if faculty.get('office_location'):
            response_lines.append(f"**Office Location:** {faculty['office_location']}")
        # Include info specific to anti_ragging if source is that table
        if faculty.get('source_table') == 'anti_ragging':
            if faculty.get('role'):
                 response_lines.append(f"**Squad Role:** {faculty['role']}")
            if faculty.get('contact_phone'):
                 response_lines.append(f"**Contact Phone:** {faculty['contact_phone']}")
        response_lines.append("\nLet me know if you need anything else!")

    else:
        response_lines.append(f"I found {len(results)} potential matches:")
        for i, faculty in enumerate(results):
            response_lines.append(f"\n{i+1}. **{faculty.get('name', 'N/A')}**")
            if faculty.get('department'):
                response_lines.append(f"   Department/Role: {faculty['department']}")
            if faculty.get('email'):
                 response_lines.append(f"   Email: {faculty['email']}")
            if faculty.get('source_table') == 'anti_ragging' and faculty.get('role'):
                 response_lines.append(f"   Squad Role: {faculty['role']}")
        response_lines.append("\nCould you please specify which one you're interested in?")


    return "\n".join(response_lines)


# --- Core Message Processing Logic ---

async def process_message(user_query, user_id):
    """Processes the user's message, interacts with Gemini and DB."""
    logging.info(f"Processing message from {user_id}: '{user_query}'")
    bot_response = "I'm sorry, I encountered an issue and couldn't process your request." # Default error

    try:
        # --- Step 1: Get Intent and Entities from Gemini ---
        intent_data = await gemini_client.get_query_intent(user_query)
        if not intent_data:
            logging.error("Failed to get intent from Gemini.")
            return "Sorry, I couldn't understand your request due to an internal error."

        intent = intent_data.get('intent', 'unknown')
        entities = intent_data.get('entities', {})
        logging.info(f"Intent: {intent}, Entities: {entities}")

        # --- Step 1.5: Override entities if a clear role keyword is in the user query ---
        # (This logic from your file is good, no changes needed)
        user_query_lower = user_query.lower()
        role_keywords_in_query = []
        is_explicit_role_query = False # Flag if the query IS the role
        if 'principal' in user_query_lower:
            role_keywords_in_query.append('principal')
            if "principal" in user_query_lower.split(): is_explicit_role_query = True
        if 'dean' in user_query_lower:
             role_keywords_in_query.append('dean')
             if "dean" in user_query_lower.split(): is_explicit_role_query = True
        # Check for controller/coe variations
        controller_keywords = ['controller', 'coe']
        if any(keyword in user_query_lower for keyword in controller_keywords):
             role_keywords_in_query.append('controller') # Use canonical 'controller'
             # Check if the query is primarily about the controller role
             if any(keyword in user_query_lower.split() for keyword in controller_keywords):
                 is_explicit_role_query = True


        if intent == 'get_faculty_info' and role_keywords_in_query:
            # (This logic from your file is good, no changes needed)
            role_to_search = role_keywords_in_query[0]
            if is_explicit_role_query and entities.get('faculty_name'):
                logging.warning(f"Overriding Gemini's faculty_name '{entities.get('faculty_name')}' due to EXPLICIT role keyword '{role_to_search}' in query.")
                entities.pop('faculty_name', None) 
            elif entities.get('faculty_name') and entities.get('faculty_name').lower() not in user_query_lower:
                logging.warning(f"Overriding Gemini's faculty_name '{entities.get('faculty_name')}' due to role keyword '{role_to_search}' in query.")
                entities.pop('faculty_name', None) 

            if 'faculty_name' not in entities: 
                entities['department'] = role_to_search 
                entities.pop('info_type', None) 
            elif 'department' not in entities: 
                 entities['department'] = role_to_search

            logging.info(f"Role keyword detected. Updated Entities for DB search: {entities}")
        # --- End Override Logic ---


        # --- Step 2: Handle Conversation Memory (Timetable Example) ---
        # (This logic from your file is good, no changes needed)
        if intent == 'get_timetable':
            if user_id in conversation_memory and 'day' in entities and len(entities) == 1:
                logging.info(f"Using memory for user {user_id}: {conversation_memory[user_id]}")
                entities.update(conversation_memory[user_id])
                conversation_memory.pop(user_id, None) 
            elif 'day' not in entities:
                 logging.info(f"Asking for day, saving memory for user {user_id}: {entities}")
                 memory_to_save = {k: v for k, v in entities.items() if k in ['branch', 'section', 'year']}
                 if memory_to_save: 
                    conversation_memory[user_id] = memory_to_save
                 bot_response = "Please specify which day you'd like the timetable for (e.g., 'timetable for 1st cse a on monday')."
                 if bot_response is None or bot_response.strip() == "":
                    logging.error("CRITICAL: Generated empty response after asking for day.")
                    return "Oops! Something went wrong while processing your request. (Error code: TT-EMPTY1)"
                 return bot_response
            else:
                 conversation_memory.pop(user_id, None)
             # Clear memory if the intent is not a timetable follow-up
             


        # --- Step 3: Fetch Data from Database based on Intent ---
        db_results = []
        if intent == "get_faculty_info":
             name = entities.get('faculty_name')
             dept = entities.get('department')
             info = entities.get('info_type')
             db_results = database.get_faculty_info(name, dept, info)
        elif intent == "get_timetable":
             branch = entities.get('branch')
             section = entities.get('section')
             year = entities.get('year') 
             day = entities.get('day')
             faculty_name = entities.get('faculty_name')
             course_name = entities.get('course_name')
             if day:
                 db_results = database.get_timetable(branch, section, year, day, faculty_name, course_name)
             else:
                 logging.warning("Timetable query attempted without a day specified, after memory check.")
                 bot_response = "It seems I missed which day you wanted the timetable for. Please specify the day."
                 if bot_response is None or bot_response.strip() == "":
                    logging.error("CRITICAL: Generated empty response in timetable no-day fallback.")
                    return "Oops! Something went wrong while processing your request. (Error code: TT-EMPTY2)"
                 return bot_response
        elif intent == "get_club_info":
             db_results = database.get_club_info(entities.get('club_name'))
        elif intent == "get_dress_code":
             db_results = database.get_dress_code(entities.get('category'))
        elif intent == "get_admissions_info":
             db_results = database.get_admissions_info()
        elif intent == "get_placements_info":
             db_results = database.get_placements_info()
        elif intent == "get_fees_info":
             db_results = database.get_fees_info()
        elif intent == "get_anti_ragging_info":
             db_results = database.get_anti_ragging_info()
        elif intent == "get_hostel_info":
             db_results = database.get_hostel_info(entities.get('hostel_name'), entities.get('gender'), entities.get('campus'))
        elif intent == "get_transport_info":
             db_results = database.get_transport_info(entities.get('route_name'))
        elif intent == "get_event_info":
             db_results = database.get_event_info(entities.get('event_title'))
        elif intent == "get_notice_info":
             db_results = database.get_notice_info()
        
        # --- NEW SCHOLARSHIP INTENT ---
        elif intent == "get_scholarship_info":
             db_results = database.get_scholarship_info(
                 entities.get('scholarship_name'), 
                 entities.get('branch'), 
                 entities.get('year')
             )
        # --- END NEW INTENT ---

        # --- Step 4: Generate Final Response ---
        if intent == "general_chat" or intent == "unknown":
            logging.info("Handling general chat or unknown intent.")
            # We will fix this path inside gemini_client.py
            bot_response = await gemini_client.generate_final_response(user_query, db_results)
        elif intent == "get_timetable" and db_results:
             logging.info("Formatting timetable response.")
             bot_response = format_timetable_response(db_results, entities) 
        elif intent == "get_faculty_info" and db_results:
             logging.info("Formatting faculty response.")
             bot_response = format_faculty_response(db_results)
        elif db_results: # For other intents with results, use Gemini to format
            logging.info(f"Generating final response via Gemini with DB results: {db_results[:1]}...") 
            bot_response = await gemini_client.generate_final_response(user_query, db_results)
        # --- NO CHANGE to this part ---
        else: # Intent was recognized, but DB returned no results
            logging.info("Intent recognized, but no DB results found. Generating suggestion response.")
            # This function will be replaced in gemini_client.py to include the link
            bot_response = await gemini_client.generate_suggestion_response(user_query)
            

        # --- Paranoid Check: Ensure response is not empty ---
        if bot_response is None or bot_response.strip() == "":
            logging.error(f"CRITICAL: Final response generated was empty for intent '{intent}' and query '{user_query}'. DB results count: {len(db_results if db_results else [])}")
            bot_response = "I found some information, but had trouble formulating a response. Please try rephrasing your question."


    except Exception as e:
        logging.exception(f"An error occurred in process_message: {e}") 
        bot_response = f"Oops! Something went wrong while processing your request. (Error: {e})"


    logging.info(f"Generated response: '{bot_response[:100]}...'") 
    logging.info(f"Generated response: '{bot_response[:100]}...'") # Log beginning of response
    return bot_response


# --- Flask Routes ---

@app.route('/')
def index():
    """Serves the simple HTML test page."""
    try:
        return render_template('index.html')
    except Exception as e:
        logging.exception("Error rendering index.html")
        return f"Error loading page: {e}", 500


@app.route('/chat', methods=['POST'])
async def chat():
    """Handles chat messages from the web interface."""
    user_message = request.json.get('message')
    if not user_message:
        return jsonify({"error": "No message provided"}), 400

    user_id = "web_user"
    bot_response = await process_message(user_message, user_id)

    if bot_response is None or bot_response.strip() == "":
        logging.error(f"CRITICAL: Empty response generated by process_message for web query '{user_message}'")
        bot_response = "I'm sorry, I couldn't generate a response. Please try again."

    return jsonify({"response": bot_response})


@app.route('/twilio', methods=['POST'])
async def twilio_webhook():
    """Handles incoming WhatsApp messages via Twilio."""
    incoming_msg = request.values.get('Body', '').strip()
    from_number = request.values.get('From', '') 

    logging.info(f"Twilio Message From: {from_number}, Body: {incoming_msg}")

    resp = MessagingResponse()
    msg = resp.message()

    if not incoming_msg:
        msg.body("Please send a message.")
        return str(resp)

    try:
        bot_response = await process_message(incoming_msg, from_number)
        if bot_response is None or bot_response.strip() == "":
             logging.error(f"CRITICAL: Empty response generated by process_message for Twilio query '{incoming_msg}' from {from_number}")
             bot_response = "I'm sorry, I couldn't generate a response. Please try again."
        msg.body(bot_response)

    except Exception as e:
        logging.exception(f"Error in /twilio webhook: {e}") 
        msg.body(f"I'm sorry, a critical error occurred while processing your request: {e}")

    return str(resp)

# --- Main Execution ---

if __name__ == '__main__':
    logging.info("Starting Flask application...")
    try:
        gemini_client.configure_gemini()
        database.connect()
        logging.info("Database connection initialized successfully.")

        print("==================================================")
        print(f"🚀 Flask App is running on http://127.0.0.1:5000")
        print("==================================================")
        print("📋 ACTION REQUIRED:")
        print("1. Open a NEW terminal window.")
        print("2. In that new terminal, run: ngrok http 5000")
        print("3. Copy the 'Forwarding' URL (it looks like https://....ngrok-free.app)")
        print("4. Go to your Twilio WhatsApp Sandbox settings and paste that URL into the")
        print("   'WHEN A MESSAGE COMES IN' field, followed by /twilio")
        print("   (e.g., https://....ngrok-free.app/twilio)")
        print("5. Set the method to 'HTTP POST' and save.")
        print("==================================================")


        app.run(port=5000, debug=False) # Turn debug=False for cleaner logs unless actively debugging Flask itself

    except Exception as startup_error:
        logging.critical(f"CRITICAL STARTUP ERROR: {startup_error}", exc_info=True)
    finally:
        logging.info("Flask application stopped.")

