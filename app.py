# --- load_dotenv() MUST be the first line ---
from dotenv import load_dotenv
load_dotenv()

import os
import json
import logging
import asyncio # For async operations
import datetime # For timedelta conversion in formatting
# --- Removed load_dotenv from here ---
from flask import Flask, request, render_template, jsonify
from twilio.twiml.messaging_response import MessagingResponse

# Import custom modules
import database
import gemini_client

# Configure logging
logging.basicConfig(level=logging.INFO, format='%(asctime)s - %(levelname)s - %(message)s')

# --- Flask App Initialization ---
app = Flask(__name__, template_folder='static', static_folder='static')

# --- Conversation Memory (Simple Dictionary) ---
conversation_memory = {}


# --- NEW: Static answers for common questions ---
PLACEMENT_START_INFO = (
    "Placements generally start from the 5th semester onwards. "
    "Keep an eye on the placement cell notifications for exact dates and company visits!"
)

EXAM_REGISTRATION_INFO = (
    "Here is the process for F Grade (Backlog/Makeup) Registration:\n\n"
    "1. Open Contineo\n"
    "2. Login with your USN and DOB\n"
    "3. Click on 'F Grade Registration'\n"
    "4. **Note:** Registration is a one-time activity.\n"
    "5. Verify the failed course list before registration.\n"
    "6. If you are not getting a failed course, kindly contact the SDSC office.\n"
    "7. After selecting all the courses, submit the data.\n"
    "8. You can click 'DELETE' under 'Pending Transactions' to edit registrations *before* approval.\n"
    "9. If registrations are approved by SDSC, you cannot edit them.\n"
    "10. Download the PDF and pay the fees through the SIS portal.\n"
    "11. After fee payment, submit a copy of the receipt and PDF to the Exam Section (North/South as applicable).\n"
    "12. The SDSC office will then approve the registration."
)

LOST_ITEM_INFO = {
    "id card": (
        "Here is the process for a lost ID card:\n\n"
        "1. Log in to the SIS portal.\n"
        "2. Select the 'lost ID card' option.\n"
        "3. Pay the mentioned fees online.\n"
        "4. Download the payment receipt PDF.\n"
        "5. Submit the receipt to the college office."
    ),
    "hall ticket": (
        "Here is the process for a lost hall ticket:\n\n"
        "1. Log in to the SIS portal.\n"
        "2. Select the 'lost hall ticket' option.\n"
        "3. Pay the mentioned fees online.\n"
        "4. Download the payment receipt PDF.\n"
        "5. Submit the receipt to the college office."
    )
}
# --- END NEW STATIC ANSWERS ---


# --- NEW: Faculty Availability Helpers ---

def parse_time(time_str):
    """Parses a time string like '3pm' or '10:30' into a time object."""
    try:
        # Try parsing "3pm" or "10am"
        return datetime.datetime.strptime(time_str.strip().lower(), '%I%p').time()
    except ValueError:
        try:
            # Try parsing "3:30pm"
            return datetime.datetime.strptime(time_str.strip().lower(), '%I:%M%p').time()
        except ValueError:
            try:
                # Try parsing "15:00"
                return datetime.datetime.strptime(time_str.strip(), '%H:%M').time()
            except ValueError:
                try:
                    # Try parsing "15"
                    hour = int(time_str.strip().replace("pm", "").replace("am", ""))
                    if hour < 9: # Assume pm for 1, 2, 3, 4
                        hour += 12
                    return datetime.time(hour, 0)
                except ValueError:
                    return None

def calculate_free_slots(busy_slots):
    """
    Calculates the free time slots for a faculty member,
    considering college hours and breaks.
    """
    # Define college hours and breaks
    COLLEGE_START = datetime.time(9, 0)
    COLLEGE_END = datetime.time(16, 30)
    BREAK_START = datetime.time(11, 0)
    BREAK_END = datetime.time(11, 30)
    LUNCH_START = datetime.time(13, 30)
    LUNCH_END = datetime.time(14, 30)

    # Combine busy slots and breaks into a single list of "unavailable" times
    unavailable_slots = sorted(
        [s for s in busy_slots if s] + # Filter out None or empty slots
        [{'start_time': BREAK_START, 'end_time': BREAK_END},
         {'start_time': LUNCH_START, 'end_time': LUNCH_END}],
        key=lambda x: x['start_time']
    )

    free_slots = []
    current_time = COLLEGE_START

    for slot in unavailable_slots:
        busy_start = slot['start_time']
        busy_end = slot['end_time']

        # If there's a gap between current time and the next busy slot, it's free time
        if current_time < busy_start:
            free_slots.append((current_time, busy_start))
        
        # Move the "current_time" cursor to the end of this busy slot
        if current_time < busy_end:
            current_time = busy_end

    # After checking all busy slots, check if there's free time left until the end of the day
    if current_time < COLLEGE_END:
        free_slots.append((current_time, COLLEGE_END))

    return free_slots
# --- END NEW AVAILABILITY HELPERS ---


# --- Helper Functions ---

# --- NEW: Conversation Memory Helpers ---
def is_positive_reply(query):
    """Checks if a query is a 'yes' answer."""
    query_lower = query.lower().strip()
    return query_lower in ['yes', 'yep', 'ya', 'correct', 'y', 'that is right', "that's right", 'ok', 'yes please']

def is_negative_reply(query):
    """Checks if a query is a 'no' answer."""
    query_lower = query.lower().strip()
    return query_lower in ['no', 'nope', 'n', 'wrong', 'that is wrong', "that's wrong", 'no thanks']

def is_similar_faculty_name(name_from_user, name_from_db):
    """
    Simple check to see if the user's query is *different* from the DB result.
    e.g., user="kuzalvaimozhi", db="Dr S Kuzhalvaimozhi" -> True (different)
    e.g., user="Dr S Kuzhalvaimozhi", db="Dr S Kuzhalvaimozhi" -> False (same)
    e.g., user="kuzhalvaimozhi", db="Dr S Kuzhalvaimozhi" -> False (same enough)
    """
    user_norm = name_from_user.lower().replace('.', '').replace('dr', '').replace(' ', '')
    db_norm = name_from_db.lower().replace('.', '').replace('dr', '').replace(' ', '')
    
    if user_norm == db_norm:
        return False # They are identical
    
    # If the user's query is a substring of the full name, it's close enough
    if user_norm in db_norm:
        return False # e.g., "kuzhalvaimozhi" in "drskuzhalvaimozhi"
        
    # If we are here, the names are different enough to warrant a check
    # e.g., user="kuzalvaimozhi" is NOT in "drskuzhalvaimozhi"
    return True

# --- END NEW MEMORY HELPERS ---

def format_faculty_courses(results, faculty_name):
    """Formats the list of courses taught by a faculty member."""
    if not results:
        return f"I'm sorry, I couldn't find any courses taught by '{faculty_name}'."
    
    # Use the first result to get the faculty's properly cased name if possible
    # This is a bit tricky as the query doesn't return faculty name, let's stick with the entity
    response_lines = [f"Here are the courses taught by **{faculty_name}**:\n"]
    
    for course in results:
        code = course.get('course_code')
        name = course.get('course_name')
        response_lines.append(f"• **{name}** ({code})")
        
    return "\n".join(response_lines)


# --- Helper Functions ---
def format_timetable_response(results, entities):
    """Formats timetable results into a readable string."""
    if not results:
        return "I couldn't find any timetable entries matching your request."

    # --- Use entities passed from process_message for the title ---
    branch = entities.get('branch') # Get just the value, or None
    section = entities.get('section')
    year = entities.get('year')
    day = entities.get('day')
    
    # --- NEW: Get course name/code for title ---
    course_name = entities.get('course_name')
    course_code = entities.get('course_code')
    faculty_name = entities.get('faculty_name') # Get the faculty name
    
    title_parts = []
    
    # Build the title based on what we *do* have
    if year:
        title_parts.append(f"{year} year")
    if branch:
        title_parts.append(branch)
    if section:
        title_parts.append(section)
    
    if course_name:
        title_parts.append(f"for {course_name}")
    elif course_code:
        title_parts.append(f"for {course_code}")
    elif not title_parts and faculty_name:
        # If the main title is empty, but we have a faculty name, use that.
        title_parts.append(f"for {faculty_name}")

    title_string = ' '.join(title_parts)

    if day:
        # If we have a title, use "on [day]".
        if title_string:
            response_lines = [f"Here is the schedule {title_string} on {day.capitalize()}:"]
        else:
            # This will probably be "Here is the schedule on [day]"
            response_lines = [f"Here is the schedule on {day.capitalize()}:"]
        
        response_lines.append(f"\n--- {day.upper()} ---")
    else:
        # No day provided (full week schedule)
        if title_string:
            response_lines = [f"Here is the schedule {title_string}:"]
        else:
            # Should be rare, but a fallback
            response_lines = [f"Here is the schedule:"]
            
    current_day = ""
    current_time = None
    for row in results:
        # --- NEW: Handle full week schedule printing ---
        if row['day_of_week'] != current_day and not day:
             current_day = row['day_of_week']
             response_lines.append(f"\n--- {current_day.upper()} ---")
             current_time = None # Reset time for new day
        # --- END NEW ---

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
        if row.get('class_type') and row.get('class_type').lower() != 'lecture':
            details.append(f"[{row['class_type']}]")
        if row.get('lab_batch'):
            details.append(f"(Batch {row['lab_batch']})")

        response_lines.append("\n".join(details))
        response_lines.append("") # Add a blank line for spacing


    return "\n".join(response_lines).strip()

def format_faculty_response(results):
    """Formats faculty results (full details) into a readable string."""
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
        
        # --- MODIFIED: This logic is correct, it already hides NULL locations ---
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

# --- NEW FORMATTER FUNCTION ---
def format_faculty_location(results):
    """Formats faculty location results into a readable string."""
    if not results:
        return "I couldn't find a faculty member by that name."

    if len(results) == 1:
        faculty = results[0]
        name = faculty.get('name', 'N/A')
        location = faculty.get('office_location')
        
        if location:
            return f"The office location for **{name}** is **{location}**."
        else:
            # This is the case where the guide's request is met
            return f"I found **{name}**, but I'm sorry, their office location is not in my records right now."
            
    else:
        # This means multiple matches were found
        response_lines = [f"I found {len(results)} potential matches:"]
        for i, faculty in enumerate(results):
            response_lines.append(f"\n{i+1}. **{faculty.get('name', 'N/A')}**")
        response_lines.append("\nWhose office location would you like to know?")
        return "\n".join(response_lines)
# --- END NEW FORMATTER ---

# --- MODIFIED FORMATTER FUNCTION ---
def format_course_instructors(results, entities):
    """Formats the list of course instructors into a readable string."""
    if not results:
        return "I couldn't find any instructors for that course, or the course code/name might be incorrect."

    # Use the first result to get the course name/code
    first_result = results[0]
    course_name = first_result.get('course_name')
    course_code = first_result.get('course_code')
    
    # --- NEW: Handle specific section/branch query ---
    req_branch = entities.get('branch')
    req_section = entities.get('section')
    
    if (req_branch or req_section) and len(results) == 1:
        # User asked for a specific section and got one result
        row = results[0]
        name = row.get('faculty_name', 'N/A')
        branch = row.get('branch', 'N/A')
        section = row.get('section', 'N/A')
        return (
            f"The instructor for **{course_name} ({course_code})** "
            f"for the **{branch} - {section}** section is **{name}**."
        )
    
    # --- Default: List all found instructors ---
    response_lines = [f"Here are the instructors for **{course_name} ({course_code})**:\n"]
    
    for row in results:
        name = row.get('faculty_name', 'N/A')
        branch = row.get('branch', 'N/A')
        section = row.get('section', 'N/A')
        response_lines.append(f"• **{name}** teaches **{branch} - {section}** section.")
    
    return "\n".join(response_lines)
# --- END MODIFIED FORMATTER ---

# --- UPDATED PLACEMENT FORMATTER ---
def format_placement_summary(results, entities):
    """
    Formats the high-level placement stats.
    If a specific 'stat_type' entity is passed, it returns only that stat.
    Otherwise, it returns the full summary.
    """
    if not results:
        return "I'm sorry, I couldn't retrieve the overall placement summary."
        
    stats = results[0] # Should only be one row
    stat_type = entities.get("stat_type")
    
    # --- NEW: Specific Stat Logic ---
    if stat_type:
        if stat_type == "highest_ctc" and stats.get('highest_ctc'):
            return f"The **Highest Salary** was **{stats['highest_ctc']} LPA**."
        elif stat_type == "average_ctc" and stats.get('average_ctc'):
            return f"The **Average Salary** was **{stats['average_ctc']} LPA**."
        elif stat_type == "median_ctc" and stats.get('median_ctc'):
            return f"The **Median Salary** was **{stats['median_ctc']} LPA**."
        elif stat_type == "lowest_ctc" and stats.get('lowest_ctc'):
            return f"The **Lowest Salary (Mass)** was **{stats['lowest_ctc']} LPA**."
        elif stat_type == "total_selects" and stats.get('total_selects'):
            return f"There were **{stats['total_selects']} Total Selections**."
        elif stat_type == "total_companies" and stats.get('total_companies'):
            return f"A total of **{stats['total_companies']} Companies** visited for placements."
        else:
            # Fallback in case the stat_type is weird, just return all
            pass 
    # --- END NEW: Specific Stat Logic ---

    # --- Default: Full Summary ---
    response_lines = ["Here are the key placement statistics:\n"]
    if stats.get('highest_ctc'):
        response_lines.append(f"• **Highest Salary:** {stats['highest_ctc']} LPA")
    if stats.get('average_ctc'):
        response_lines.append(f"• **Average Salary:** {stats['average_ctc']} LPA")
    if stats.get('median_ctc'):
        response_lines.append(f"• **Median Salary:** {stats['median_ctc']} LPA")
    if stats.get('lowest_ctc'):
        response_lines.append(f"• **Lowest Salary (Mass):** {stats['lowest_ctc']} LPA")
    if stats.get('total_selects'):
        response_lines.append(f"• **Total Selections:** {stats['total_selects']}")
    if stats.get('total_companies'):
        response_lines.append(f"• **Total Companies Visited:** {stats['total_companies']}")
        
    return "\n".join(response_lines)

def format_company_stats(results, company_name):
    """Formats stats for a specific company."""
    if not results:
        return f"I'm sorry, I couldn't find any placement data for a company matching '{company_name}'."
    
    response_lines = []
    if len(results) == 1:
        company = results[0]
        name = company.get('company_name')
        selects = company.get('num_selects')
        ctc = company.get('ctc')
        ctype = company.get('ctc_type')
        
        response_lines.append(f"Here are the stats for **{name}**:")
        if ctc:
            response_lines.append(f"• **Offered CTC:** {ctc} LPA ({ctype})")
        if selects is not None:
            response_lines.append(f"• **Number of Selections:** {selects}")
    else:
        response_lines.append(f"I found {len(results)} matches for '{company_name}':\n")
        for company in results:
            name = company.get('company_name')
            selects = company.get('num_selects')
            ctc = company.get('ctc')
            response_lines.append(f"• **{name}**: {selects} selections at {ctc} LPA")
            
    return "\n".join(response_lines)

# --- NEW: Formatter for count by type ---
def format_placement_count_by_type(results, ctc_type):
    """Formats the count of companies by ctc_type."""
    if not results:
        return f"I'm sorry, I couldn't find any companies matching the type '{ctc_type}'."
    
    # The query groups by ctc_type, so we need to sum them up
    # e.g., "Dream" and "Open Dream" if user asks for "Dream"
    total_count = sum(row.get('company_count', 0) for row in results)
    
    if total_count == 0:
         return f"I couldn't find any companies matching the type '{ctc_type}'."
         
    # Make the ctc_type more readable
    type_name = ctc_type.capitalize()
    if total_count == 1:
        return f"I found **1** company that offered a '{type_name}' package."
    else:
        return f"I found a total of **{total_count}** companies that offered '{type_name}' packages."
# --- END NEW FORMATTER ---

# --- NEW: Formatter for count by ctc ---
def format_placement_count_by_ctc(results, operator, amount):
    """Formats the count of students/companies by CTC threshold."""
    if not results or results[0] is None:
        return f"I'm sorry, I couldn't calculate the placement data for that CTC range."
        
    stats = results[0]
    total_students = stats.get('total_students') or 0
    total_companies = stats.get('total_companies') or 0
    
    op_text = "more than" if operator == 'gt' else "less than"
    
    if total_companies == 0:
        return f"I couldn't find any companies that offered packages {op_text} {amount} LPA."
        
    student_text = "student" if total_students == 1 else "students"
    company_text = "company" if total_companies == 1 else "companies"
    
    return (
        f"I found that **{total_students} {student_text}** were placed by "
        f"**{total_companies} {company_text}** with a CTC *{op_text}* **{amount} LPA**."
    )
# --- END NEW FORMATTER ---

# --- NEW: Formatter for LISTING companies by ctc ---
def format_placement_companies_by_ctc(results, operator, amount):
    """Formats the LIST of companies by CTC threshold."""
    if not results:
        op_text = "more than" if operator == 'gt' else "less than"
        return f"I'm sorry, I couldn't find any companies that offered packages {op_text} {amount} LPA."
        
    op_text = "more than" if operator == 'gt' else "less than"
    
    response_lines = [f"Here are the companies with a CTC **{op_text} {amount} LPA**:\n"]
    
    for company in results:
        name = company.get('company_name', 'N/A')
        ctc = company.get('ctc', 'N/A')
        selects = company.get('num_selects', 'N/A')
        response_lines.append(f"• **{name}**: {ctc} LPA ({selects} selections)")
        
    return "\n".join(response_lines)
# --- END NEW FORMATTER ---

# --- NEW: Formatter for faculty availability ---
def format_faculty_availability(db_results, entities, day, faculty_name_from_db):
    """Formats the faculty's free/busy schedule."""
    
    # --- MODIFIED: Use the confirmed name ---
    faculty_name = faculty_name_from_db or entities.get('faculty_name', 'This faculty member')
    time_str = entities.get('time_of_day')
    
    # 1. Check for "No classes"
    if not db_results:
        # --- MODIFIED: This is now accurate, as existence is checked *before* this ---
        return f"**{faculty_name}** has no classes scheduled on {day.capitalize()}. They are likely no in the campus"

    # 2. Calculate free slots
    # db_results is a list of {'start_time': time_obj, 'end_time': time_obj}
    free_slots = calculate_free_slots(db_results)

    # 3. Check for a specific time
    if time_str:
        user_time = parse_time(time_str)
        if not user_time:
            return f"I'm sorry, I couldn't understand the time '{time_str}'. Please try a format like '3pm' or '15:00'."
        
        is_free = False
        for start, end in free_slots:
            if start <= user_time < end:
                is_free = True
                break
        
        if is_free:
            return f"**Yes**, **{faculty_name}** appears to be **free** at {time_str} on {day.capitalize()}."
        else:
            return f"**No**, **{faculty_name}** appears to be **busy** at {time_str} on {day.capitalize()}."

    # 4. List all free slots
    if not free_slots:
        return f"**{faculty_name}** appears to be busy for the entire day on {day.capitalize()}."

    response_lines = [f"Here are the **free** slots for **{faculty_name}** on {day.capitalize()}:\n"]
    for start, end in free_slots:
        start_str = start.strftime("%I:%M %p")
        end_str = end.strftime("%I:%M %p")
        response_lines.append(f"• **{start_str}** to **{end_str}**")
        
    return "\n".join(response_lines)


# --- Core Message Processing Logic ---

async def process_message(user_query, user_id):
    """
    Processes the user's message, interacts with Gemini and DB.
    
    --- MODIFIED ---
    This function now *always* returns a dictionary:
    {'text': 'Your response here', 'media_url': 'URL_or_None'}
    """
    logging.info(f"Processing message from {user_id}: '{user_query}'")
    memory_handled = False
    intent = None
    entities = {}
    
    # --- MODIFIED: Default response is now a dictionary ---
    bot_response_dict = {
        'text': "I'm sorry, I encountered an issue and couldn't process your request.",
        'media_url': None
    }
    bot_response_text = None # Will hold the string response

    try:
        # --- Step 1: Get Intent and Entities from Gemini ---
        intent_data = await gemini_client.get_query_intent(user_query)
        if not intent_data:
            logging.error("Failed to get intent from Gemini.")
            bot_response_dict['text'] = "Sorry, I couldn't understand your request due to an internal error."
            return bot_response_dict # Return the dictionary

        intent = intent_data.get('intent', 'unknown')
        entities = intent_data.get('entities', {})
        logging.info(f"Intent: {intent}, Entities: {entities}")
        
        # --- Step 1.5: Check for Memory Handlers ---
        if user_id in conversation_memory:
            logging.info(f"User {user_id} has saved memory: {conversation_memory[user_id]}")
            saved_context = conversation_memory[user_id]
            pending_intent = saved_context.get('pending_intent')

            # --- A: Handle "Forgot Day" ---
            if pending_intent == 'ask_for_day':
                days_of_week = ['monday', 'tuesday', 'wednesday', 'thursday', 'friday', 'saturday', 'sunday']
                user_reply_as_day = user_query.lower().strip()
                if user_reply_as_day in days_of_week:
                    logging.info(f"Using 'ask_for_day' memory for user {user_id}.")
                    entities = saved_context.get('entities', {}) # Restore saved context
                    intent = saved_context.get('intent') # Restore original intent
                    entities['day'] = user_reply_as_day # Add the new day
                    conversation_memory.pop(user_id, None) # Clear memory
                    memory_handled = True
                else:
                    conversation_memory.pop(user_id, None) # Unrelated query, clear memory
            
            # --- B: Handle "Confirm Faculty Name" ---
            elif pending_intent == 'confirm_faculty_name':
                if is_positive_reply(user_query):
                    logging.info(f"Using 'confirm_faculty_name' (POSITIVE) memory for user {user_id}.")
                    intent = saved_context['intent']
                    entities = saved_context['entities']
                    entities['faculty_name'] = saved_context['suggested_name']
                    entities['faculty_name_confirmed'] = True # Flag to skip re-checking
                    conversation_memory.pop(user_id, None)
                    memory_handled = True
                elif is_negative_reply(user_query):
                    logging.info(f"Using 'confirm_faculty_name' (NEGATIVE) memory for user {user_id}.")
                    conversation_memory.pop(user_id, None)
                    bot_response_dict['text'] = "My apologies. Could you please spell out the name of the faculty member you are looking for?"
                    return bot_response_dict
                else:
                    conversation_memory.pop(user_id, None) # Unrelated query
            
            # --- C: Handle "Clarify Instructor Section" ---
            elif pending_intent == 'clarify_instructor_section':
                # Check if new query is just a section/branch
                if intent == 'get_course_instructors' and (entities.get('branch') or entities.get('section')):
                    logging.info(f"Using 'clarify_instructor_section' memory for user {user_id}.")
                    saved_entities = saved_context.get('entities', {})
                    entities.update(saved_entities) # Merge old (course) + new (section)
                    intent = 'get_course_instructors' # Ensure intent is correct
                    conversation_memory.pop(user_id, None)
                    memory_handled = True
                else:
                    conversation_memory.pop(user_id, None) # Unrelated query

            # --- D: Handle "List Companies by CTC" ---
            elif pending_intent == 'list_companies_by_ctc':
                if intent == 'get_placement_companies_by_ctc':
                    logging.info(f"Using 'list_companies_by_ctc' memory for user {user_id}.")
                    saved_entities = saved_context.get('entities', {})
                    entities.update(saved_entities) # Merge old (op, amount) + new (nothing)
                    intent = 'get_placement_companies_by_ctc'
                    conversation_memory.pop(user_id, None)
                    memory_handled = True
                else:
                    conversation_memory.pop(user_id, None) # Unrelated query
                    
            # --- E: Clear old "Forgot Day" memory if user provided a day ---
            # This is a fallback from your original code
            elif 'day' in entities and not memory_handled:
                conversation_memory.pop(user_id, None)

        # --- Step 1.6: Role Override Logic (Unchanged) ---
        user_query_lower = user_query.lower()
        role_keywords_in_query = []
        is_explicit_role_query = False 
        if 'principal' in user_query_lower:
            role_keywords_in_query.append('principal')
            if "principal" in user_query_lower.split(): is_explicit_role_query = True
        if 'dean' in user_query_lower:
             role_keywords_in_query.append('dean')
             if "dean" in user_query_lower.split(): is_explicit_role_query = True
        controller_keywords = ['controller', 'coe']
        if any(keyword in user_query_lower for keyword in controller_keywords):
             role_keywords_in_query.append('controller')
             if any(keyword in user_query_lower.split() for keyword in controller_keywords):
                 is_explicit_role_query = True
        
        if (intent == 'get_faculty_info' or intent == 'get_faculty_location') and role_keywords_in_query:
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
        
        # --- Step 1.7: NEW - Faculty Spellcheck/Existence Check ---
        faculty_intents = ['get_faculty_info', 'get_faculty_location', 'get_faculty_availability', 'get_faculty_courses']
        faculty_name_from_user = entities.get('faculty_name')
        faculty_name_confirmed = entities.get('faculty_name_confirmed', False) # Get confirmation flag
        
        if intent in faculty_intents and faculty_name_from_user and not faculty_name_confirmed and not memory_handled:
            logging.info(f"Performing faculty existence/spellcheck for: '{faculty_name_from_user}'")
            check_results = database.get_faculty_location(faculty_name_from_user) # This now returns exact or fuzzy matches
            
            if not check_results:
                logging.warning("Faculty check: No results found.")
                bot_response_dict['text'] = "I'm sorry, I couldn't find a faculty member by that name."
                return bot_response_dict
                
            # Check the match type of the first result
            closest_match = check_results[0]
            suggested_name = closest_match['name']
            match_type = closest_match.get('match_type', 'none')

            # Check for ambiguity: multiple results were found (regardless of type)
            if len(check_results) > 1:
                logging.info(f"Faculty check: Ambiguous results found ({len(check_results)} matches).")
                # Format a "Did you mean..." list
                bot_response_text = format_faculty_location(check_results) # Use existing formatter
                bot_response_dict['text'] = bot_response_text
                return bot_response_dict
                
            # --- Exactly one clear best match found ---
            
            # If it was a 'fuzzy' match, it's a typo. Ask for confirmation.
            if match_type == 'fuzzy':
                logging.info(f"Faculty check: Prompting for confirmation. User='{faculty_name_from_user}', DB='{suggested_name}' (Fuzzy Match)")
                # Save context and ask for confirmation
                conversation_memory[user_id] = {
                    'pending_intent': 'confirm_faculty_name',
                    'intent': intent,
                    'entities': entities,
                    'suggested_name': suggested_name
                }
                bot_response_dict['text'] = f"I found **{suggested_name}**. Did you mean this person?"
                return bot_response_dict
            
            # --- Name is an 'exact' match ---
            # (This means the normalized 'kuzalvaimozhi' matched 'drskuzhalvaimozhi')
            logging.info(f"Faculty check: Name '{suggested_name}' (Exact Match) confirmed. Proceeding.")
            entities['faculty_name'] = suggested_name # Correct the name for all other functions
            entities['faculty_name_confirmed'] = True # Mark as confirmed
            
        # --- End Faculty Spellcheck ---

        # --- Step 2: Handle "Forgot Day" Memory (Save) ---
        if (intent == 'get_timetable' or intent == 'get_faculty_availability') and 'day' not in entities:
            # User asked for timetable or availability but forgot the day.
            # Ask for the day and save the context.
            logging.info(f"Asking for day, saving 'ask_for_day' memory for user {user_id}")
            memory_to_save = {
                'pending_intent': 'ask_for_day', # NEW pending intent
                'intent': intent,
                'entities': entities
            }
            conversation_memory[user_id] = memory_to_save

            bot_response_dict['text'] = "Sure, which day of the week are you asking about?"
            return bot_response_dict

        # --- Step 3: Fetch Data from Database based on Intent ---
        db_results = []
        
        # --- get_campus_map (Unchanged) ---
        if intent == "get_campus_map":
            location = entities.get('location_name')
            map_data = database.get_campus_map_data(location)
            bot_response_dict['text'] = map_data.get('text')
            bot_response_dict['media_url'] = map_data.get('media_url')
            return bot_response_dict
        
        # --- get_placement_stats (This is now the PDF SENDER) ---
        elif intent == "get_placement_stats":
            stats_data = database.get_placement_stats_data()
            bot_response_dict['text'] = stats_data.get('text')
            bot_response_dict['media_url'] = stats_data.get('media_url')
            return bot_response_dict
        
        # --- NEW: get_placement_summary ---
        elif intent == "get_placement_summary":
            db_results = database.get_placement_summary_data()
            # This intent never sends media
            
        # --- NEW: get_company_stats ---
        elif intent == "get_company_stats":
            company_name = entities.get('company_name')
            db_results = database.get_company_stats_data(company_name)

            # This intent never sends media
        elif intent == "get_placement_start_info":
            bot_response_dict['text'] = PLACEMENT_START_INFO
            return bot_response_dict
            
        elif intent == "get_exam_registration_info":
            bot_response_dict['text'] = EXAM_REGISTRATION_INFO
            return bot_response_dict
            
        elif intent == "get_lost_item_info":
            item = entities.get('lost_item', 'id card') # Default to id card
            if 'hall ticket' in item.lower():
                bot_response_text = LOST_ITEM_INFO.get('hall ticket')
            else:
                bot_response_text = LOST_ITEM_INFO.get('id card')
            bot_response_dict['text'] = bot_response_text
            return bot_response_dict
        # --- END NEW STATIC INTENTS ---
        
        # --- NEW: Handle Faculty Availability ---
        elif intent == "get_faculty_availability":
            # --- MODIFIED: Existence/Day is already checked by this point ---
            faculty_name = entities.get('faculty_name') # This is the *confirmed* name
            day = entities.get('day') 
            
            db_results = database.get_faculty_schedule(faculty_name, day)
            # Pass confirmed name to formatter
            bot_response_text = format_faculty_availability(db_results, entities, day, faculty_name)
            bot_response_dict['text'] = bot_response_text
            return bot_response_dict
        # --- END NEW FACULTY AVAILABILITY ---

        # --- NEW: get_placement_count_by_type ---
        elif intent == "get_placement_count_by_type":
            ctc_type = entities.get('ctc_type')
            db_results = database.get_placement_count_by_type_data(ctc_type)
            # This intent never sends media
            
        # --- NEW: get_placement_count_by_ctc ---
        elif intent == "get_placement_count_by_ctc":
            operator = entities.get('ctc_operator')
            amount = entities.get('ctc_amount')
            db_results = database.get_placement_count_by_ctc_data(operator, amount)
            # --- NEW: Save memory for follow-up ---
            if db_results and db_results[0] and db_results[0].get('total_companies', 0) > 0:
                conversation_memory[user_id] = {
                    'pending_intent': 'list_companies_by_ctc',
                    'entities': { 'ctc_operator': operator, 'ctc_amount': amount }
                }
            # This intent never sends media
            
        # --- NEW: get_placement_companies_by_ctc ---
        elif intent == "get_placement_companies_by_ctc":
            operator = entities.get('ctc_operator')
            amount = entities.get('ctc_amount')
            
            if not operator or not amount:
                bot_response_text = "I'm not sure which CTC range you're asking about. Please try 'list companies with ctc over 10 lpa'."
                bot_response_dict['text'] = bot_response_text
                return bot_response_dict
                
            db_results = database.get_placement_companies_by_ctc_data(operator, amount)
            # This intent never sends media
            
        elif intent == "get_faculty_courses":
            # --- MODIFIED: Existence checked ---
            faculty_name = entities.get('faculty_name') # Confirmed name
            db_results = database.get_courses_for_faculty(faculty_name)
            # This intent never sends media
            
        # --- get_student_portal_info (Unchanged) ---
        elif intent == "get_student_portal_info":
            portal_data = database.get_student_portal_data()
            bot_response_dict['text'] = portal_data.get('text')
            bot_response_dict['media_url'] = portal_data.get('media_url') # This will be None
            return bot_response_dict
        
        # --- get_faculty_location (Unchanged from prev) ---
        elif intent == "get_faculty_location":
            # --- MODIFIED: Existence checked ---
            search_term = entities.get('faculty_name') or entities.get('department')
            db_results = database.get_faculty_location(search_term)
            # --- This intent NEVER sends an image ---
            
        # --- get_course_instructors (Unchanged from prev) ---
        elif intent == "get_course_instructors":
            course_name = entities.get('course_name')
            course_code = entities.get('course_code')
            # --- NEW: Pass branch/section ---
            branch = entities.get('branch')
            section = entities.get('section')
            
            db_results = database.get_course_instructors(course_name, course_code, branch, section)
            
            # --- NEW: Save memory for follow-up ---
            if db_results and (course_name or course_code) and not (branch or section):
                conversation_memory[user_id] = {
                    'pending_intent': 'clarify_instructor_section',
                    'entities': { 'course_name': course_name, 'course_code': course_code }
                }
            # --- This intent NEVER sends an image ---

        elif intent == "get_faculty_info":
             # --- MODIFIED: Existence checked ---
             name = entities.get('faculty_name') # Confirmed name
             dept = entities.get('department')
             info = entities.get('info_type')
             db_results = database.get_faculty_info(name, dept, info)
             # --- This intent WILL send an image, see Step 4 ---
             
        elif intent == "get_timetable":
             # --- MODIFIED: Faculty name is confirmed if present ---
             branch = entities.get('branch')
             section = entities.get('section')
             year = entities.get('year') 
             day = entities.get('day') # Day is present
             faculty_name = entities.get('faculty_name')
             course_name = entities.get('course_name')
             course_code = entities.get('course_code') 
             
             db_results = database.get_timetable(branch, section, year, day, faculty_name, course_name, course_code)
        
        # ... (all other existing elif intents are unchanged) ...
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
        elif intent == "get_scholarship_info":
             db_results = database.get_scholarship_info(
                 entities.get('scholarship_name'), 
                 entities.get('branch'), 
                 entities.get('year')
             )

        # --- Step 4: Generate Final Response ---
        if intent == "general_chat" or intent == "unknown":
            logging.info("Handling general chat or unknown intent.")
            bot_response_text = await gemini_client.generate_final_response(user_query, db_results)
        elif intent == "get_timetable" and db_results:
             logging.info("Formatting timetable response.")
             bot_response_text = format_timetable_response(db_results, entities) 
             
        # --- NEW: Handle faculty location (no image) ---
        elif intent == "get_faculty_location" and db_results:
            logging.info("Formatting faculty LOCATION response.")
            bot_response_text = format_faculty_location(db_results)
            # media_url remains None
            
        # --- NEW: Handle course instructors (no image) ---
        elif intent == "get_course_instructors": # Handles db_results or not
            logging.info("Formatting course instructors response.")
            # --- MODIFIED: Pass entities ---
            bot_response_text = format_course_instructors(db_results, entities)
            # media_url remains None
             
        elif intent == "get_faculty_info" and db_results:
             logging.info("Formatting faculty (FULL) response.")
             
             # --- MODIFIED: Check for image_url (This is the *only* place it's set now) ---
             if len(db_results) == 1 and db_results[0].get('image_url'):
                 logging.info(f"Found image_url for faculty: {db_results[0]['image_url']}")
                 bot_response_dict['media_url'] = db_results[0]['image_url']
             # --- END MODIFIED ---
                 
             bot_response_text = format_faculty_response(db_results)
        
        # --- NEW: Handle new placement intents ---
        elif intent == "get_placement_summary" and db_results:
            logging.info("Formatting placement SUMMARY response.")
            # --- MODIFIED: Pass entities to the formatter ---
            bot_response_text = format_placement_summary(db_results, entities)
            
        elif intent == "get_company_stats" and db_results:
            logging.info("Formatting company stats response.")
            bot_response_text = format_company_stats(db_results, entities.get('company_name'))
            
        elif intent == "get_placement_count_by_type" and db_results:
            logging.info("Formatting placement COUNT BY TYPE response.")
            bot_response_text = format_placement_count_by_type(db_results, entities.get('ctc_type'))
            
        elif intent == "get_placement_count_by_ctc": # Handles db_results or not
            logging.info("Formatting placement COUNT BY CTC response.")
            bot_response_text = format_placement_count_by_ctc(
                db_results, entities.get('ctc_operator'), entities.get('ctc_amount')
            )
            
        # --- NEW: Handle LISTING companies ---
        elif intent == "get_placement_companies_by_ctc": # Handles db_results or not
            logging.info("Formatting placement COMPANIES BY CTC response.")
            bot_response_text = format_placement_companies_by_ctc(
                db_results, entities.get('ctc_operator'), entities.get('ctc_amount')
            )
            
        elif intent == "get_faculty_courses": # Handles db_results or not
            logging.info("Formatting faculty COURSES response.")
            # We pass the original entity name for the title
            bot_response_text = format_faculty_courses(db_results, entities.get('faculty_name'))
        # --- END NEW ---
        # --- END NEW ---
             
        elif db_results: # For other intents with results, use Gemini to format
            logging.info(f"Generating final response via Gemini with DB results: {db_results[:1]}...") 
            bot_response_text = await gemini_client.generate_final_response(user_query, db_results)
        else: # Intent was recognized, but DB returned no results
            logging.info("Intent recognized, but no DB results found. Generating suggestion response.")
            
            # --- NEW: Give better "no results" messages ---
            # These are fallbacks, as formatters now handle most "no results"
            if intent == "get_course_instructors":
                bot_response_text = "I'm sorry, I couldn't find any instructors for that course. The course name or code might be misspelled."
            elif intent == "get_faculty_location":
                bot_response_text = "I'm sorry, I couldn't find a faculty member by that name."
            elif intent == "get_faculty_info":
                bot_response_text = "I'm sorry, I couldn't find a faculty member by that name."
            elif intent == "get_timetable":
                bot_response_text = "I'm sorry, I couldn't find any schedule matching your request."
            # --- NEW: Better "no results" for placements ---
            elif intent == "get_placement_summary":
                bot_response_text = "I'm sorry, I couldn't retrieve the overall placement summary."
            elif intent == "get_company_stats":
                bot_response_text = f"I'm sorry, I couldn't find any placement data for a company matching '{entities.get('company_name')}'."
            elif intent == "get_placement_count_by_type":
                bot_response_text = f"I'm sorry, I couldn't find any companies matching the type '{entities.get('ctc_type')}'."
            elif intent == "get_placement_count_by_ctc":
                 bot_response_text = f"I'm sorry, I couldn't find any placement data for that CTC range."
            elif intent == "get_placement_companies_by_ctc":
                 bot_response_text = f"I'm sorry, I couldn't find any companies for that CTC range."
            elif intent == "get_faculty_availability":
                # This is handled by the formatter, but as a fallback:
                bot_response_text = f"I'm sorry, I couldn't find a schedule for '{entities.get('faculty_name')}'."
            # --- END NEW ---
            elif intent == "get_faculty_courses":
                bot_response_text = f"I'm sorry, I couldn't find any courses taught by '{entities.get('faculty_name')}'."
            # --- END NEW ---
            # --- END NEW ---
            else:
                # Use the default suggestion generator
                bot_response_text = await gemini_client.generate_suggestion_response(user_query)
            # --- END NEW ---
            
        # --- Paranoid Check (Unchanged) ---
        if bot_response_text is None or bot_response_text.strip() == "":
            logging.error(f"CRITICAL: Final response generated was empty for intent '{intent}' and query '{user_query}'. DB results count: {len(db_results if db_results else [])}")
            bot_response_text = "I found some information, but had trouble formulating a response. Please try rephrasing your question."

        # --- MODIFIED: Assign text to the dictionary ---
        bot_response_dict['text'] = bot_response_text

    except Exception as e:
        logging.exception(f"An error occurred in process_message: {e}") 
        # --- MODIFIED: Assign error text to the dictionary ---
        bot_response_dict['text'] = f"Oops! Something went wrong while processing your request. (Error: {e})"

    logging.info(f"Generated response: '{bot_response_dict['text'][:100]}...', Media: {bot_response_dict['media_url']}") 
    return bot_response_dict # Return the final dictionary


# --- Flask Routes ---
# (Routes are all unchanged)
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
    
    # --- MODIFIED: Get dictionary response ---
    bot_response_dict = await process_message(user_message, user_id)
    bot_response_text = bot_response_dict.get('text') # Get just the text

    if bot_response_text is None or bot_response_text.strip() == "":
        logging.error(f"CRITICAL: Empty response generated by process_message for web query '{user_message}'")
        bot_response_text = "I'm sorry, I couldn't generate a response. Please try again."

    return jsonify({"response": bot_response_text})


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
        # --- MODIFIED: Get dictionary response ---
        bot_response_dict = await process_message(incoming_msg, from_number)
        bot_response_text = bot_response_dict.get('text')
        bot_response_media = bot_response_dict.get('media_url')

        if bot_response_text is None or bot_response_text.strip() == "":
             logging.error(f"CRITICAL: Empty response generated by process_message for Twilio query '{incoming_msg}' from {from_number}")
             bot_response_text = "I'm sorry, I couldn't generate a response. Please try again."

        # --- MODIFIED: Always set the body ---
        msg.body(bot_response_text)

        # --- NEW: Conditionally add media ---
        if bot_response_media:
            logging.info(f"Attaching media to response: {bot_response_media}")
            msg.media(bot_response_media)
        # --- END NEW ---

    except Exception as e:
        logging.exception(f"Error in /twilio webhook: {e}") 
        msg.body(f"I'm sorry, a critical error occurred while processing your request: {e}")

    return str(resp)

# --- Main Execution ---
# (This part is unchanged)
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


        app.run(port=5000, debug=False)

    except Exception as startup_error:
        logging.critical(f"CRITICAL STARTUP ERROR: {startup_error}", exc_info=True)
    finally:
        logging.info("Flask application stopped.")