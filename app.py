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
# --- MODIFIED: This will now hold our 'DialogueManager' instances ---
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

# --- NEW: Entity Normalizer ---
def _normalize_entities(entities):
    """Normalizes synonyms like CS/CSE and IS/ISE across all entities."""
    if not entities:
        return entities
    
    # Normalize branch
    if entities.get('branch'):
        branch_upper = entities['branch'].upper()
        if branch_upper == 'CS':
            entities['branch'] = 'CSE'
        if branch_upper == 'IS':
            entities['branch'] = 'ISE'
    
    # Normalize lab name
    if entities.get('lab_name'):
        lab_upper = entities['lab_name'].upper()
        if lab_upper == 'CS':
            entities['lab_name'] = 'CSE'
        if lab_upper == 'IS':
            entities['lab_name'] = 'ISE'
    
    # Normalize course name (if it's just 'cs' or 'is')
    if entities.get('course_name'):
        course_upper = entities['course_name'].upper()
        if course_upper == 'CS':
            entities['course_name'] = 'CSE'
        if course_upper == 'IS':
            entities['course_name'] = 'ISE'
            
    return entities
# --- END NEW Normalizer ---


# --- NEW: Dialogue Manager Class ---

class DialogueManager:
    """
    Manages the conversation state for a single user using slot-filling.
    """
    def __init__(self, user_id):
        self.user_id = user_id
        self.current_intent = None
        self.required_slots = []
        self.filled_slots = {}
        self.questions = {} # Stores the question to ask for each slot
        
        # This is for special cases like faculty spell-check
        self.pending_action = None 
        self.action_context = {}

        # This map defines the "forms" for each intent
        self.intent_forms = {
            "get_timetable": {
                # Define *all* possible slots
                "all_slots": ["day", "branch", "section", "year", "faculty_name", "course_name", "course_code"],
                # Define the *minimum* required to ask
                "required_slots": ["day"], # We'll ask for day first
                "questions": {
                    "day": "Sure, which day of the week?",
                    "branch": "Which branch?",
                    "section": "Which section?",
                    "year": "Which year?"
                }
                # "stay_open" is False by default, which is correct for this intent
            },
            "get_faculty_availability": {
                "all_slots": ["faculty_name", "day", "time_of_day"],
                "required_slots": ["faculty_name", "day"],
                "questions": {
                    "faculty_name": "Which faculty member are you asking about?",
                    "day": "Sure, which day of the week?"
                }
            },
            "get_course_instructors": {
                "all_slots": ["course_name", "course_code", "branch", "section"],
                "required_slots": ["course_name"], # Will be adapted if code is given
                "questions": {
                    "course_name": "What is the course name?",
                    "branch": "Which branch?",
                    "section": "Which section?"
                },
                "stay_open": True # --- This intent allows follow-ups ---
            },
            "get_placement_companies_by_ctc": {
                "all_slots": ["ctc_operator", "ctc_amount"],
                "required_slots": ["ctc_operator", "ctc_amount"],
                "questions": {
                    "ctc_operator": "Are you looking for packages 'more than' or 'less than' a certain amount?",
                    "ctc_amount": "What is the CTC amount (in LPA)?"
                },
                "stay_open": True # --- This intent allows follow-ups ---
            },
            "get_placement_count_by_ctc": {
                "all_slots": ["ctc_operator", "ctc_amount"],
                "required_slots": ["ctc_operator", "ctc_amount"],
                "questions": {
                    "ctc_operator": "Are you looking for packages 'more than' or 'less than' a certain amount?",
                    "ctc_amount": "What is the CTC amount (in LPA)?"
                },
                "stay_open": True # --- This intent allows follow-ups ---
            }
        }

    def is_in_conversation(self):
        """Is the bot currently waiting for a slot to be filled?"""
        return self.current_intent is not None

    def should_stay_open(self):
        """Checks if the current intent is marked to stay open after completion."""
        if not self.current_intent:
            return False
        return self.intent_forms[self.current_intent].get("stay_open", False)

    def start_conversation(self, intent, entities):
        """Starts a new slot-filling conversation."""
        if intent not in self.intent_forms:
            return None # This intent doesn't have a form

        self.current_intent = intent
        self.required_slots = list(self.intent_forms[intent]["required_slots"]) # Make a copy
        self.questions = self.intent_forms[intent]["questions"]
        self.filled_slots = {}

        # Fill any slots we *already* got from the first query
        return self.fill_slots(entities)

    def fill_slots(self, entities):
        """
        Fills slots from new user entities and checks if the form is complete.
        Returns a question if more info is needed, or 'COMPLETED' if done.
        """
        if not self.is_in_conversation():
            return None # Not in a form-filling state

        # Get *all* possible slots for this intent
        all_slots = self.intent_forms[self.current_intent].get("all_slots", self.required_slots)

        # Fill any new slots
        for slot, value in entities.items():
            if slot in all_slots:
                self.filled_slots[slot] = value
        
        # --- Special logic for get_course_instructors ---
        # If user provides code, it can satisfy the 'course_name' requirement
        if self.current_intent == 'get_course_instructors':
            if 'course_code' in self.filled_slots:
                # If we have a code, we don't *need* a name
                if 'course_name' in self.required_slots:
                    self.required_slots.remove('course_name')
            if 'course_name' in self.filled_slots:
                # if we have a name, we don't *need* a code
                if 'course_code' in self.required_slots:
                    self.required_slots.remove('course_code')

        # Check if any *required* slots are still missing
        for slot in self.required_slots:
            if slot not in self.filled_slots:
                # Found a missing slot. Ask the question for it.
                return self.questions.get(slot, f"What is the {slot}?")
        
        # All required slots are filled
        return "COMPLETED"

    def get_full_context(self):
        """Returns the final intent and all filled entities."""
        return self.current_intent, self.filled_slots

    def reset(self):
        """Clears the conversation state."""
        logging.info(f"Resetting dialogue manager for user {self.user_id}")
        self.current_intent = None
        self.required_slots = []
        self.filled_slots = {}
        self.questions = {}
        self.pending_action = None
        self.action_context = {}

# --- END NEW Dialogue Manager Class ---


def format_faculty_courses(results, faculty_name):
    """Formats the list of courses taught by a faculty member."""
    if not results:
        return f"I'm sorry, I couldn't find any courses taught by '{faculty_name}'."
    
    response_lines = [f"Here are the courses taught by **{faculty_name}**:\n"]
    
    for course in results:
        code = course.get('course_code')
        name = course.get('course_name')
        response_lines.append(f"• **{name}** ({code})")
        
    return "\n".join(response_lines)


def format_timetable_response(results, entities):
    """Formats timetable results into a readable string."""
    if not results:
        return "I couldn't find any timetable entries matching your request."

    # --- Use entities passed from process_message for the title ---
    branch = entities.get('branch') # Get just the value, or None
    section = entities.get('section')
    year = entities.get('year')
    day = entities.get('day')
    
    course_name = entities.get('course_name')
    course_code = entities.get('course_code')
    faculty_name = entities.get('faculty_name') # Get the faculty name
    
    title_parts = []
    
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
        title_parts.append(f"for {faculty_name}")

    title_string = ' '.join(title_parts)

    if day:
        if title_string:
            response_lines = [f"Here is the schedule {title_string} on {day.capitalize()}:"]
        else:
            response_lines = [f"Here is the schedule on {day.capitalize()}:"]
        
        response_lines.append(f"\n--- {day.upper()} ---")
    else:
        if title_string:
            response_lines = [f"Here is the schedule {title_string}:"]
        else:
            response_lines = [f"Here is the schedule:"]
            
    current_day = ""
    current_time = None
    for row in results:
        if row['day_of_week'] != current_day and not day:
             current_day = row['day_of_week']
             response_lines.append(f"\n--- {current_day.upper()} ---")
             current_time = None # Reset time for new day

        start_time_str = row['start_time'].strftime("%I:%M %p") if isinstance(row['start_time'], datetime.time) else "N/A"
        end_time_str = row['end_time'].strftime("%I:%M %p") if isinstance(row['end_time'], datetime.time) else "N/A"
        time_slot = f"{start_time_str} - {end_time_str}"

        if time_slot != current_time:
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
        
        if faculty.get('office_location'):
            response_lines.append(f"**Office Location:** {faculty['office_location']}")
            
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
            return f"I found **{name}**, but I'm sorry, their office location is not in my records right now."
            
    else:
        response_lines = [f"I found {len(results)} potential matches:"]
        for i, faculty in enumerate(results):
            response_lines.append(f"\n{i+1}. **{faculty.get('name', 'N/A')}**")
        response_lines.append("\nWhose office location would you like to know?")
        return "\n".join(response_lines)

def format_course_instructors(results, entities):
    """Formats the list of course instructors into a readable string."""
    
    req_branch = entities.get('branch')
    req_section = entities.get('section')

    # --- FIX: Handle "no results" first ---
    if not results:
        # Get the course name/code from the entities for the error message
        course_name = entities.get('course_name')
        course_code = entities.get('course_code')
        course_display = course_name or course_code or "that course"
        
        if req_branch or req_section:
            return f"I couldn't find any instructors for **{course_display}** in the **{req_branch or ''} {req_section or ''}** section."
        else:
            return f"I'm sorry, I couldn't find any instructors for **{course_display}**."
    
    # --- FIX: If we have results, get the name/code from the DATABASE RESULTS ---
    # This is the "source of truth"
    course_name = results[0].get('course_name')
    course_code = results[0].get('course_code')

    # --- Handle specific section/branch query correctly ---
    if (req_branch or req_section):
        response_lines = [
            f"Here are the instructors for **{course_name} ({course_code})** "
            f"for **{req_branch or ''} {req_section or ''}**:\n"
        ]
        
        for row in results:
            name = row.get('faculty_name', 'N/A')
            branch = row.get('branch', 'N/A')
            section = row.get('section', 'N/A')
            response_lines.append(f"• **{name}** teaches **{branch} - {section}** section.")
        return "\n".join(response_lines)
    
    # --- Default: List all found instructors (initial query) ---
    response_lines = [f"Here are the instructors for **{course_name} ({course_code})**:\n"]
    
    for row in results:
        name = row.get('faculty_name', 'N/A')
        branch = row.get('branch', 'N/A')
        section = row.get('section', 'N/A')
        response_lines.append(f"• **{name}** teaches **{branch} - {section}** section.")
    
    return "\n".join(response_lines)

def format_placement_summary(results, entities):
    """
    Formats the high-level placement stats.
    """
    if not results:
        return "I'm sorry, I couldn't retrieve the overall placement summary."
        
    stats = results[0] # Should only be one row
    stat_type = entities.get("stat_type")
    
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
            pass 
    
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

def format_placement_count_by_type(results, ctc_type):
    """Formats the count of companies by ctc_type."""
    if not results:
        return f"I'm sorry, I couldn't find any companies matching the type '{ctc_type}'."
    
    total_count = sum(row.get('company_count', 0) for row in results)
    
    if total_count == 0:
         return f"I couldn't find any companies matching the type '{ctc_type}'."
         
    type_name = ctc_type.capitalize()
    if total_count == 1:
        return f"I found **1** company that offered a '{type_name}' package."
    else:
        return f"I found a total of **{total_count}** companies that offered '{type_name}' packages."

def format_placement_count_by_ctc(results, operator, amount):
    """Formats the count of students/companies by CTC threshold."""
    if not results or not results[0] or results[0].get('total_companies') is None:
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

def format_faculty_availability(db_results, entities, day, faculty_name_from_db):
    """Formats the faculty's free/busy schedule."""
    
    faculty_name = faculty_name_from_db or entities.get('faculty_name', 'This faculty member')
    time_str = entities.get('time_of_day')
    
    # 1. Check for "No classes"
    if not db_results:
        # --- This is the line you wanted changed back ---
        return f"**{faculty_name}** has no classes scheduled on {day.capitalize()}. They are likely not on campus."

    # 2. Calculate free slots
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


# --- NEW: Location Formatter ---
def format_specific_location(entities):
    """
    Handles all the custom logic for specific location questions.
    Returns a dictionary {'text': '...', 'media_url': '...'}
    """
    room_number = entities.get('room_number')
    lab_name = entities.get('lab_name')
    office_name = entities.get('office_name')
    location_name = entities.get('location_name') # Fallback
    
    response_text = None
    
    if room_number:
        # Clean up the room number (e.g., "MB-1", "303")
        room_str = room_number.upper().replace(" ", "").replace("-", "")
        
        if room_str.startswith('MB'):
            response_text = f"Room {room_number.upper()} is located in the **Madhvacharya Bhavan**."
        
        elif room_str.isdigit() and len(room_str) == 3:
            # --- THIS IS THE CORRECTED LOGIC ---
            floor_char = room_str[0] # Get the first digit (e.g., '3' from '303')
            if floor_char == '1':
                floor_text = "Ground Floor"
            elif floor_char == '2':
                floor_text = "1st Floor"
            elif floor_char == '3':
                floor_text = "2nd Floor"
            elif floor_char == '4':
                floor_text = "3rd Floor"
            else:
                # Fallback for other floors, though less likely
                floor_text = f"{int(floor_char)-1}th Floor"
            response_text = f"Room {room_str} is on the **{floor_text}** of the **Ramanujacharya Block**."
            # --- END OF CORRECTED LOGIC ---

        elif room_str.isdigit() and len(room_str) < 3:
            # Handle ambiguous queries like "room 3" or "room 20"
            response_text = f"I'm not sure which room you mean. Classrooms in the Ramanujacharya Block are 3 digits, like 101 (Ground Floor), 201 (1st Floor), or 301 (2nd Floor). Could you please specify the full room number?"
        
        else:
            # Fallback for non-digit rooms not starting with MB
            response_text = f"I'm not sure where {room_number} is. Classrooms in the main block are 3 digits (e.g., 205) and rooms in Madhvacharya Bhavan start with 'MB' (e.g., MB-1)."
    
    elif lab_name:
        lab_upper = lab_name.upper()
        if 'ISE' in lab_upper or 'IS' in lab_upper:
            response_text = "All ISE (IS) labs are located on the **3rd Floor** of the **Shankaracharya Block**."
        elif 'CSE' in lab_upper or 'CS' in lab_upper:
            response_text = "All CSE (CS) labs are located on the **2nd Floor** of the **Shankaracharya Block**."
    
    elif office_name:
        office = office_name.lower()
        if office == 'principal' or office == 'academic' or office == 'examination' or office == 'scholarship' or office == 'fees':
            # Capitalize the office name
            office_display = office.replace("principal", "Principal's").capitalize()
            if office == 'academic': office_display = "Academic Cell"
            if office == 'examination': office_display = "Examination Section"
                
            response_text = f"The **{office_display}** is on the **Ground Floor** of the **Ramanujacharya Block**."
        
        elif office == 'placement' or office == 'admissions' or office == 'stationary' or office == 'auditorium':
            office_display = office.capitalize()
            if office == 'placement': office_display = "Placement Office"
            if office == 'admissions': office_display = "Admissions Section"
                
            response_text = f"The **{office_display}** is on the **Ground Floor** of the **Shankaracharya Block**."
        
        elif office == 'hod':
            response_text = "All HOD (Head of Department) offices are located in the **Ramanujacharya Block**."
    
    elif location_name:
        loc = location_name.lower()
        if loc == 'library':
            response_text = "The Main Library is located in the **Madhvacharya Bhavan**."
    
    # --- Check if we found a specific text answer ---
    if response_text:
        return {'text': response_text, 'media_url': None}
    
    # --- Fallback: No specific logic matched, show the map ---
    logging.info(f"No specific location logic for '{entities}'. Showing map.")
    map_data = database.get_campus_map_data(location_name)
    return map_data

# --- END NEW Location Formatter ---

# --- Core Message Processing Logic ---

async def process_message(user_query, user_id):
    """
    Processes the user's message using the new Dialogue Manager.
    """
    logging.info(f"Processing message from {user_id}: '{user_query}'")
    intent = None
    entities = {}
    
    bot_response_dict = {
        'text': "I'm sorry, I encountered an issue and couldn't process your request.",
        'media_url': None
    }
    bot_response_text = None

    # --- NEW: Get the user's DialogueManager from memory ---
    if user_id not in conversation_memory:
        conversation_memory[user_id] = DialogueManager(user_id)
    manager = conversation_memory[user_id]

    try:
        # --- Pre-Filter (This is a good cost-saving measure to keep) ---
        query_lower = user_query.lower().strip()
        simple_greetings = ['hi', 'hello', 'hey', 'heyy', 'hii']
        simple_thanks = ['thanks', 'thank you', 'thx', 'thankyou']
        simple_bye = ['bye', 'goodbye', 'see ya']

        if query_lower in simple_greetings:
            logging.info("Handling simple greeting (pre-filter).")
            manager.reset() # Reset any pending conversation
            bot_response_dict['text'] = "Hello! How can I help you today?"
            return bot_response_dict
        if query_lower in simple_thanks:
            logging.info("Handling simple thanks (pre-filter).")
            manager.reset()
            bot_response_dict['text'] = "You're welcome! Let me know if you need anything else."
            return bot_response_dict
        if query_lower in simple_bye:
            logging.info("Handling simple bye (pre-filter).")
            manager.reset()
            bot_response_dict['text'] = "Goodbye!"
            return bot_response_dict
        # --- END PRE-FILTER ---
        
        
        # --- Step 1: Get Intent and Entities from Gemini ---
        logging.info("Calling get_query_intent...")
        intent_data = await gemini_client.get_query_intent(user_query)

        if not intent_data:
            logging.error("Failed to get intent from Gemini.")
            bot_response_dict['text'] = "Sorry, I couldn't understand your request."
            return bot_response_dict

        intent = intent_data.get('intent', 'unknown')
        entities = intent_data.get('entities', {})
        
        # --- NEW: Step 1.1 - Normalize Entities ---
        entities = _normalize_entities(entities)
        logging.info(f"Got Intent: {intent}, Normalized Entities: {entities}")
        # --- END NEW ---

        # --- Step 1.5: Handle Special Actions (like Faculty Spell-Check) ---
        # This runs *before* the dialogue manager
        
        if manager.pending_action == 'confirm_faculty_name':
            if is_positive_reply(user_query):
                logging.info("Using 'confirm_faculty_name' (POSITIVE) memory.")
                # Restore the original context
                intent = manager.action_context['intent']
                entities = manager.action_context['entities']
                entities['faculty_name'] = manager.action_context['suggested_name']
                entities['faculty_name_confirmed'] = True
                manager.reset() # This action is done
            elif is_negative_reply(user_query):
                logging.info("Using 'confirm_faculty_name' (NEGATIVE) memory.")
                manager.reset()
                bot_response_dict['text'] = "My apologies. Could you please spell out the name?"
                return bot_response_dict
            else:
                manager.reset() # Unrelated query, reset
                # Let the new intent/entities be processed
        
        elif manager.pending_action == 'clarify_faculty_name':
            if entities.get('faculty_name'):
                logging.info("Using 'clarify_faculty_name' memory.")
                intent = manager.action_context['intent'] # Restore original intent
                # The new 'entities' (with the user's typed name) will be used
                manager.reset()
            else:
                manager.reset() # Unrelated query
        

        # --- Step 1.6: Dialogue Management (THE FIX IS HERE) ---
        if manager.is_in_conversation():
            logging.info(f"User is already in conversation for: {manager.current_intent}")
            
            # --- NEW LOGIC ---
            # Is this a *follow-up* (unknown intent, but has entities) or just chatting?
            is_follow_up = (intent == "unknown" and entities) or \
                           (intent == "general_chat") or \
                           (intent == manager.current_intent and not entities) # e.g. "list those companies"
            
            # --- FIX: Check if it's a *new* question with the *same* intent ---
            is_new_question = (intent == manager.current_intent and entities)
            
            if not is_follow_up and not is_new_question:
                # This is a NEW, DIFFERENT QUESTION.
                logging.warning(f"New intent '{intent}' breaks old conversation. Resetting.")
                manager.reset()
            
            elif is_new_question:
                # This is a NEW question but the SAME intent (e.g. "who teaches cn" again)
                logging.info(f"New query for same intent. Resetting and starting over.")
                manager.reset()

            else:
                # User is continuing the conversation (e.g., "for ise a")
                # We pass 'entities' which might be {'branch': 'ISE', 'section': 'A'}
                response_or_status = manager.fill_slots(entities)
                
                if response_or_status == "COMPLETED":
                    logging.info("Form is complete. Getting full context.")
                    intent, entities = manager.get_full_context()
                    # --- We will reset (or not) at the *end* of the function ---
                
                elif response_or_status:
                    # Bot needs to ask the next question
                    logging.info("Form is incomplete. Asking next question.")
                    bot_response_dict['text'] = response_or_status
                    return bot_response_dict
                
                else:
                    # This should not happen, but as a fallback:
                    manager.reset()
        
        # --- Step 1.7: Role Override Logic (Restored) ---
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
            # If the AI provided a faculty_name, DELETE IT. We trust the role keyword.
            if entities.get('faculty_name'):
                logging.warning(f"Overriding Gemini's faculty_name '{entities.get('faculty_name')}' due to role keyword '{role_to_search}' in query.")
                entities.pop('faculty_name', None) 

            # Now, set the department to search for
            entities['department'] = role_to_search 
            entities.pop('info_type', None) 
            logging.info(f"Role keyword detected. Updated Entities for DB search: {entities}")
        # --- End Override Logic ---
        
        # --- Step 1.8: Faculty Spellcheck (Still valuable!) ---
        faculty_intents = ['get_faculty_info', 'get_faculty_location', 'get_faculty_availability', 'get_faculty_courses']
        faculty_name_from_user = entities.get('faculty_name')
        faculty_name_confirmed = entities.get('faculty_name_confirmed', False)
        
        # Only run spellcheck if we are NOT in a conversation and NOT handling a pending action
        if intent in faculty_intents and faculty_name_from_user and \
           not faculty_name_confirmed and not manager.is_in_conversation() and not manager.pending_action:
            
            logging.info(f"Performing faculty existence/spellcheck for: '{faculty_name_from_user}'")
            check_results = database.get_faculty_location(faculty_name_from_user)
            
            if not check_results:
                logging.warning("Faculty check: No results found.")
                bot_response_dict['text'] = "I'm sorry, I couldn't find a faculty member by that name."
                return bot_response_dict
                
            closest_match = check_results[0]
            suggested_name = closest_match['name']
            match_type = closest_match.get('match_type', 'none')

            if len(check_results) > 1:
                logging.info(f"Faculty check: Ambiguous results found ({len(check_results)} matches).")
                # Save context for clarification
                manager.pending_action = 'clarify_faculty_name'
                manager.action_context = {'intent': intent}
                bot_response_text = format_faculty_location(check_results)
                bot_response_dict['text'] = bot_response_text
                return bot_response_dict
                
            if match_type == 'fuzzy':
                logging.info(f"Faculty check: Prompting for confirmation. User='{faculty_name_from_user}', DB='{suggested_name}'")
                # Save context for confirmation
                manager.pending_action = 'confirm_faculty_name'
                manager.action_context = {
                    'intent': intent,
                    'entities': entities,
                    'suggested_name': suggested_name
                }
                bot_response_dict['text'] = f"I found **{suggested_name}**. Did you mean this person?"
                return bot_response_dict
            
            logging.info(f"Faculty check: Name '{suggested_name}' (Exact Match) confirmed. Proceeding.")
            entities['faculty_name'] = suggested_name
            entities['faculty_name_confirmed'] = True
            
        # --- End Faculty Spellcheck ---


        # --- Step 2: Check if a *new* conversation needs to be started ---
        if intent in manager.intent_forms and not manager.is_in_conversation():
            logging.info(f"Starting new slot-filling conversation for: {intent}")
            response_or_status = manager.start_conversation(intent, entities)
            
            if response_or_status == "COMPLETED":
                logging.info("Form was completed in one shot.")
                intent, entities = manager.get_full_context()
                # --- We will reset (or not) at the *end* of the function ---
            
            elif response_or_status:
                # Bot needs to ask the *first* question
                logging.info("Form is incomplete. Asking first question.")
                bot_response_dict['text'] = response_or_status
                return bot_response_dict


        # --- Step 3: Fetch Data from Database based on Intent ---
        db_results = []
        
        # Reset memory for any simple, non-form intent
        if not manager.is_in_conversation():
             manager.reset() # Clear any old state
        
        # --- UPDATED: This is the new 'get_location' intent ---
        if intent == "get_location":
            # This function contains all the new logic
            location_data = format_specific_location(entities)
            bot_response_dict['text'] = location_data.get('text')
            bot_response_dict['media_url'] = location_data.get('media_url')
            return bot_response_dict
        
        elif intent == "get_placement_stats":
            stats_data = database.get_placement_stats_data()
            bot_response_dict['text'] = stats_data.get('text')
            bot_response_dict['media_url'] = stats_data.get('media_url')
            return bot_response_dict
        
        elif intent == "get_placement_summary":
            db_results = database.get_placement_summary_data()
            
        elif intent == "get_company_stats":
            company_name = entities.get('company_name')
            if not company_name:
                 bot_response_text = "Which company's stats are you looking for?"
            else:
                 db_results = database.get_company_stats_data(company_name)

        elif intent == "get_placement_start_info":
            bot_response_dict['text'] = PLACEMENT_START_INFO
            return bot_response_dict
            
        elif intent == "get_exam_registration_info":
            bot_response_dict['text'] = EXAM_REGISTRATION_INFO
            return bot_response_dict
            
        elif intent == "get_lost_item_info":
            item = entities.get('lost_item', 'id card')
            if 'hall ticket' in item.lower():
                bot_response_text = LOST_ITEM_INFO.get('hall ticket')
            else:
                bot_response_text = LOST_ITEM_INFO.get('id card')
            bot_response_dict['text'] = bot_response_text
            return bot_response_dict
        
        elif intent == "get_faculty_availability":
            faculty_name = entities.get('faculty_name')
            day = entities.get('day') 
            
            if not faculty_name or not day:
                 bot_response_dict['text'] = "I'm sorry, I missed who or which day. Please ask again."
                 return bot_response_dict
                 
            db_results = database.get_faculty_schedule(faculty_name, day)
            bot_response_text = format_faculty_availability(db_results, entities, day, faculty_name)
            bot_response_dict['text'] = bot_response_text
            # We will let the manager reset at the end
        
        elif intent == "get_placement_count_by_type":
            ctc_type = entities.get('ctc_type')
            if not ctc_type:
                 bot_response_text = "Which CTC type are you asking about (e.g., Dream, Core)?"
            else:
                 db_results = database.get_placement_count_by_type_data(ctc_type)
            
        elif intent == "get_placement_count_by_ctc":
            operator = entities.get('ctc_operator')
            amount = entities.get('ctc_amount')
            if not operator or not amount:
                 bot_response_text = "I'm not sure which CTC range you're asking about."
            else:
                db_results = database.get_placement_count_by_ctc_data(operator, amount)
            
        elif intent == "get_placement_companies_by_ctc":
            operator = entities.get('ctc_operator')
            amount = entities.get('ctc_amount')
            if not operator or not amount:
                bot_response_text = "I'm not sure which CTC range you're asking about."
            else:
                db_results = database.get_placement_companies_by_ctc_data(operator, amount)
            
        elif intent == "get_faculty_courses":
            faculty_name = entities.get('faculty_name')
            if not faculty_name:
                 bot_response_text = "Which faculty's courses are you looking for?"
            else:
                db_results = database.get_courses_for_faculty(faculty_name)
            
        elif intent == "get_student_portal_info":
            portal_data = database.get_student_portal_data()
            bot_response_dict['text'] = portal_data.get('text')
            bot_response_dict['media_url'] = portal_data.get('media_url')
            return bot_response_dict
        
        elif intent == "get_faculty_location":
            search_term = entities.get('faculty_name') or entities.get('department')
            if not search_term:
                 bot_response_text = "Whose office location are you looking for?"
            else:
                db_results = database.get_faculty_location(search_term)
            
        elif intent == "get_course_instructors":
            course_name = entities.get('course_name')
            course_code = entities.get('course_code')
            branch = entities.get('branch')
            section = entities.get('section')
            
            if not course_name and not course_code:
                 bot_response_text = "Which course are you asking about?"
            else:
                db_results = database.get_course_instructors(course_name, course_code, branch, section)

        elif intent == "get_faculty_info":
             name = entities.get('faculty_name')
             dept = entities.get('department')
             info = entities.get('info_type')
             if not name and not dept:
                  bot_response_text = "Which faculty member are you asking about?"
             else:
                db_results = database.get_faculty_info(name, dept, info)
             
        elif intent == "get_timetable":
             branch = entities.get('branch')
             section = entities.get('section')
             year = entities.get('year') 
             day = entities.get('day')
             faculty_name = entities.get('faculty_name')
             course_name = entities.get('course_name')
             course_code = entities.get('course_code') 
             
             if not (day or branch or section or year or faculty_name or course_name or course_code):
                 bot_response_text = "I'm sorry, I missed what you wanted the timetable for."
             else:
                 db_results = database.get_timetable(branch, section, year, day, faculty_name, course_name, course_code)
        
        # --- Other intents ---
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
        
        # If bot_response_text was set above, use it
        if bot_response_text:
             pass
        elif intent == "general_chat" or intent == "unknown":
            logging.info("Handling general chat or unknown intent.")
            bot_response_text = await gemini_client.generate_final_response(user_query, db_results)
        elif intent == "get_timetable" and db_results:
             logging.info("Formatting timetable response.")
             bot_response_text = format_timetable_response(db_results, entities) 
             
        elif intent == "get_faculty_location" and db_results:
            logging.info("Formatting faculty LOCATION response.")
            bot_response_text = format_faculty_location(db_results)
            
        elif intent == "get_course_instructors": # Handles db_results or not
            logging.info("Formatting course instructors response.")
            bot_response_text = format_course_instructors(db_results, entities)
             
        elif intent == "get_faculty_info" and db_results:
             logging.info("Formatting faculty (FULL) response.")
             if len(db_results) == 1 and db_results[0].get('image_url'):
                 logging.info(f"Found image_url for faculty: {db_results[0]['image_url']}")
                 bot_response_dict['media_url'] = db_results[0]['image_url']
             bot_response_text = format_faculty_response(db_results)
        
        elif intent == "get_placement_summary" and db_results:
            logging.info("Formatting placement SUMMARY response.")
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
            
        elif intent == "get_placement_companies_by_ctc": # Handles db_results or not
            logging.info("Formatting placement COMPANIES BY CTC response.")
            bot_response_text = format_placement_companies_by_ctc(
                db_results, entities.get('ctc_operator'), entities.get('ctc_amount')
            )
            
        elif intent == "get_faculty_courses" and db_results:
            logging.info("Formatting faculty COURSES response.")
            bot_response_text = format_faculty_courses(db_results, entities.get('faculty_name'))
             
        elif db_results:
            logging.info(f"Generating final response via Gemini with DB results: {db_results[:1]}...") 
            bot_response_text = await gemini_client.generate_final_response(user_query, db_results)
        
        else: # No db_results and no formatter text
            logging.info("Intent recognized, but no DB results found. Generating suggestion response.")
            bot_response_text = await gemini_client.generate_suggestion_response(user_query)
            
        # --- Paranoid Check (Unchanged) ---
        if bot_response_text is None or bot_response_text.strip() == "":
            logging.error(f"CRITICAL: Final response generated was empty for intent '{intent}' and query '{user_query}'.")
            bot_response_text = "I'm sorry, I couldn't find a response for that."

        bot_response_dict['text'] = bot_response_text

    except Exception as e:
        logging.exception(f"An error occurred in process_message: {e}") 
        manager.reset() # Clear state on a major error
        bot_response_dict['text'] = f"Oops! Something went wrong while processing your request. (Error: {e})"

    # --- STEP 5: (THE FIX) Reset manager *only* if the conversation is not meant to stay open ---
    if not manager.should_stay_open() and manager.is_in_conversation():
        logging.info(f"Intent {manager.current_intent} does not stay open. Resetting manager.")
        manager.reset()
    # --- END FIX ---

    logging.info(f"Generated response: '{bot_response_dict['text'][:100]}...', Media: {bot_response_dict['media_url']}") 
    return bot_response_dict


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
    
    bot_response_dict = await process_message(user_message, user_id)
    bot_response_text = bot_response_dict.get('text') 

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
        bot_response_dict = await process_message(incoming_msg, from_number)
        bot_response_text = bot_response_dict.get('text')
        bot_response_media = bot_response_dict.get('media_url')

        if bot_response_text is None or bot_response_text.strip() == "":
             logging.error(f"CRITICAL: Empty response generated by process_message for Twilio query '{incoming_msg}' from {from_number}")
             bot_response_text = "I'm sorry, I couldn't generate a response. Please try again."

        msg.body(bot_response_text)

        if bot_response_media:
            logging.info(f"Attaching media to response: {bot_response_media}")
            msg.media(bot_response_media)

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