import os
import aiohttp
import json
import time
import asyncio # Import asyncio

# --- FIX 2: Read the Google Form URL from your .env file ---
# (This file is loaded by app.py *before* this import happens)
SUGGESTION_FORM_URL = os.getenv("GOOGLE_FORM_SUGGESTION_URL")

# --- NEW: Prompts for when data is not found ---
# (This section is unchanged from your file)
_FORM_SUGGESTION_PROMPT = (
    "The user asked a query but no results were found in the database. "
    "Generate a friendly, apologetic response that includes the following suggestion for improvement. "
    "The suggestion must be: 'We are always looking to improve our knowledge base! You can suggest this missing information by filling out our brief suggestion form here: {form_url}'"
    "\n\nUSER QUERY: {user_query}"
    "\n\nTASK: Generate a single, apologetic response incorporating the form link."
)
_FALLBACK_SUGGESTION_PROMPT = (
    "The user asked a query but no results were found in the database. "
    "Generate a friendly, apologetic response that asks the user if they would like to suggest this data be added to the database. "
    "The suggestion must be: 'Would you like to suggest that this data be added to our knowledge base? That helps us improve for future students!'"
    "\n\nUSER QUERY: {user_query}"
    "\n\nTASK: Generate a single, apologetic response incorporating the fallback suggestion question."
)
# --- END NEW PROMPTS ---


MODEL_NAME = "gemini-2.5-flash-preview-09-2025"
# --- FIX: Added '//' after 'https:' ---
GEMINI_API_BASE_URL = "https://generativelanguage.googleapis.com/v1beta/models/"

def configure_gemini():
    """Checks if the GEMINI_API_KEY is available."""
    api_key = os.environ.get('GEMINI_API_KEY')
    if not api_key:
        raise ValueError("Error: GEMINI_API_KEY environment variable not set.")
    
    # --- NEW: Check for the placement PDF URL ---
    if os.getenv("PLACEMENT_PDF_URL"):
        print("Placement Stats PDF URL is LOADED.")
    else:
        print("WARNING: PLACEMENT_PDF_URL is NOT SET in .env file. Stats feature will fail.")
    # --- END NEW ---
    
    if os.getenv("COLLEGE_MAP_URL"):
        print("College Map URL is LOADED.")
    else:
        print("WARNING: COLLEGE_MAP_URL is NOT SET in .env file. Map feature will fail.")

    if SUGGESTION_FORM_URL:
        print("Gemini client configured successfully. Suggestion Form URL is LOADED.")
    else:
        print("Gemini client configured successfully. (Suggestion Form URL is NOT SET)")

def _build_url(intent_or_response):
    """Builds the correct API URL based on the task."""
    api_key = os.environ.get('GEMINI_API_KEY')
    if not api_key:
        print("CRITICAL: API_KEY is not configured in _build_url. Returning empty URL.")
        return "" 

    if intent_or_response == "intent":
        model = "gemini-2.5-flash-preview-09-2025" 
    else:
        model = MODEL_NAME 
        
    return f"{GEMINI_API_BASE_URL}{model}:generateContent?key={api_key}"

async def _call_gemini_with_retry(payload, intent_or_response="response", max_retries=3, delay=2):
    """Calls the Gemini API with exponential backoff retry logic."""
    # (This function is unchanged from your file)
    headers = {'Content-Type': 'application/json'}
    url = _build_url(intent_or_response)
    
    if not url:
         print(f"CRITICAL: API call failed. URL is empty. Check GEMINI_API_KEY.")
         raise Exception("API_KEY is not configured, cannot make API call.")

    async with aiohttp.ClientSession() as session:
        for attempt in range(max_retries):
            try:
                async with session.post(url, json=payload, headers=headers) as response:
                    if response.status == 200:
                        try:
                            result = await response.json()
                            if 'candidates' in result and result['candidates']:
                                part = result['candidates'][0].get('content', {}).get('parts', [{}])[0]
                                if 'text' in part:
                                    return part['text']
                            
                            print(f"API Warning: Response 200 but no valid candidate text. Response: {result}")
                            return None

                        except aiohttp.ContentTypeError:
                            text_response = await response.text()
                            print(f"API Error: Response 200 but not valid JSON. Response: {text_response}")
                            raise Exception(f"API returned non-JSON 200 response: {text_response[:100]}...")
                    
                    elif response.status == 500 or response.status == 503:
                        print(f"API Error {response.status}: Model overloaded or internal error. Retrying in {delay}s...")
                        await asyncio.sleep(delay) 
                        delay *= 2
                    
                    else:
                        error_text = await response.text()
                        print(f"API Error {response.status}: {error_text}")
                        raise Exception(f"API Client Error {response.status}: {error_text}")

            except aiohttp.ClientError as e:
                print(f"API request failed: {e}. Retrying in {delay}s...")
                await asyncio.sleep(delay) 
                delay *= 2
            except Exception as e:
                print(f"A non-retryable error occurred: {e}")
                raise e 

    print("API call failed after 3 retries.")
    raise Exception("API call failed after 3 retries.")


async def get_query_intent(user_query):
    """
    Uses Gemini to classify the user's intent and extract entities.
    """
    system_prompt = f"""
    You are an intent classification system for a college chatbot. Your goal is to analyze the user's query and categorize it into one of the following intents, extracting relevant entities.

    Possible Intents:
    - "get_timetable": User is asking for a class schedule.
    - "get_faculty_info": User is asking *about* a professor (e.g., "who is", "tell me about"). This is for FULL details.
    - "get_faculty_location": User is asking *only* for the office location of a faculty member (e.g., "where is", "location of").
    - "get_course_instructors": User is asking *who* teaches a specific course.
    - "get_faculty_courses": User is asking for a list of all courses taught by a specific faculty member.
    - "get_faculty_availability": User is asking when a faculty member is free, what their schedule is, or if they are free at a specific time.
    - "get_club_info": User is asking about student clubs.
    - "get_hostel_info": User is asking about student housing/hostels.
    - "get_placements_info": User is asking about *contact info* for the placement office.
    - "get_admissions_info": User is asking about college admissions.
    - "get_fees_info": User is asking about tuition fees or payments.
    - "get_transport_info": User is asking about college bus routes or transport.
    - "get_dress_code": User is asking about the college dress code.
    - "get_anti_ragging_info": User is asking about anti-ragging policies or contacts.
    - "get_events_info": User is asking about college events or fests.
    - "get_notices": User is asking for recent notices or announcements.
    - "get_scholarship_info": User is asking about scholarships.
    - "get_campus_map": User is asking for the college map, directions, or location of a specific place.
    - "get_student_portal_info": User is asking about attendance, CIE marks, or internal marks.

    --- STUDENT INFO INTENTS ---
    - "get_placement_start_info": User is asking when placements begin (e.g., "when do placements start?").
    - "get_exam_registration_info": User is asking about makeup exams, backlog registration, or what to do if they fail.
    - "get_lost_item_info": User is asking about losing an ID card or hall ticket.
    
    --- PLACEMENT INTENTS ---
    - "get_placement_stats": User is asking for the *full report*, *all companies*, or *complete details*. This will send a PDF.
    - "get_placement_summary": User is asking for *specific high-level stats* (e.g., highest salary, average salary, median salary, total students placed).
    - "get_company_stats": User is asking for stats related to *one specific company*.
    - "get_placement_count_by_type": User is asking *how many* companies of a certain type came (e.g., "how many dream companies", "total mass recruiters").
    - "get_placement_count_by_ctc": User is asking *how many* students or companies got packages *above or below* a certain CTC.
    - "get_placement_companies_by_ctc": User is asking to *list* the companies *above or below* a certain CTC.
     
    - "general_chat": User is making small talk, greeting, or asking a question not related to the database. (e.g., "yes", "no", "ok", "thanks").
    - "unknown": The user's intent is unclear or not covered.
    - "suggest_data": The user is suggesting new information to be added.

    Extracted Entities:
    - "faculty_name": The name of the faculty member (e.g., "Dr. Anitha R", "MNR", "SK").
    - "course_name": The name of a course (e.g., "Applied Physics", "CN", "TOC").
    - "course_code": The code for a course (e.g., "18CS45", "PHY101").
    - "company_name": The name of a company (e.g., "VISA", "JPMC", "Google").
    - "branch": The student branch (e.g., "CSE", "AI&ML", "ISE").
    - "year": The year of study (e.g., 1, 2, 3, 4).
    - "section": The class section (e.g., "A", "B").
    - "day": The day of the week (e.g., "Monday").
    - "club_name": The name of the club (e.g., "NISB", "Robotics").
    - "hostel_name": The name of the hostel (e.g., "NIE North Men's Hostel").
    - "scholarship_name": The name of the scholarship (e.g., "Merit Scholarship", "TVS Scholarship").
    - "location_name": The specific place the user wants to find (e.g., "canteen", "library", "admin block", "ground").
    - "topic": A general topic (e.g., "ragging", "TechNIEks", "library notice").
    
    --- PLACEMENT ENTITIES ---
    - "stat_type": The specific placement stat requested (e.g., "highest_ctc", "average_ctc", "median_ctc", "lowest_ctc", "total_selects", "total_companies").
    - "ctc_type": The type of placement package (e.g., "Dream", "Mass", "Core", "Open Dream", "Startup").
    - "ctc_amount": The CTC value in lakhs (e.g., 12, 8.5).
    - "ctc_operator": The comparison operator ("gt" for greater than, "lt" for less than).
    
    --- OTHER ENTITIES ---
    - "lost_item": The item the user lost (e.g., "id card", "hall ticket").
    - "time_of_day": A specific time mentioned by the user (e.g., "3pm", "10:00").

    You must respond in JSON format only. Do not add any other text.
    Handle spelling mistakes gracefully.
    "hi", "hello", "thanks", "bye", "yes", "no", "yep", "nope", "ok" are "general_chat".
    
    --- NEW RULE ---
    You must also ignore all honorifics like 'sir', 'mam', 'madam'. They are not part of the name.
    --- END NEW RULE ---

    Example for "can i get timetable for cse a 1st year on monday":
    {{"intent": "get_timetable", "entities": {{"branch": "CSE", "year": 1, "section": "A", "day": "Monday"}}}}
    
    Example for "who is dr anitha r":
    {{"intent": "get_faculty_info", "entities": {{"faculty_name": "Dr. Anitha R"}}}}
    
    Example for "who is principal":
    {{"intent": "get_faculty_info", "entities": {{"faculty_name": "Dr. N V Archana"}}}}
    
    Example for "tell me about dr vanamala mam":
    {{"intent": "get_faculty_info", "entities": {{"faculty_name": "Dr. CK Vanamala"}}}}
    
    Example for "details about principal sir":
    {{"intent": "get_faculty_info", "entities": {{"faculty_name": "Dr. N V Archana"}}}}

    Example for "where can i find vanamal":
    {{"intent": "get_faculty_location", "entities": {{"faculty_name": "vanamal"}}}}
    
    Example for "where is dr anitha r's office":
    {{"intent": "get_faculty_location", "entities": {{"faculty_name": "Dr. Anitha R"}}}}
    
    Example for "location of principal's office":
    {{"intent": "get_faculty_location", "entities": {{"faculty_name": "Dr. N V Archana"}}}}

    Example for "who teaches applied physics":
    {{"intent": "get_course_instructors", "entities": {{"course_name": "Applied Physics"}}}}
    
    Example for "who is the instructor for 18CS45":
    {{"intent": "get_course_instructors", "entities": {{"course_code": "18CS45"}}}}
    
    Example for "show me the schedule for 18CS45":
    {{"intent": "get_timetable", "entities": {{"course_code": "18CS45"}}}} 

    Example for "what clubs are there":
    {{"intent": "get_club_info", "entities": {{}}}}

    Example for "show me the college map":
    {{"intent": "get_campus_map", "entities": {{}}}}
    
    Example for "where is the canteen":
    {{"intent": "get_campus_map", "entities": {{"location_name": "canteen"}}}}

    --- PLACEMENT EXAMPLES ---
    Example for "show me all placement stats":
    {{"intent": "get_placement_stats", "entities": {{}}}}

    Example for "give me the full placement report":
    {{"intent": "get_placement_stats", "entities": {{}}}}

    Example for "list of all companies that visited":
    {{"intent": "get_placement_stats", "entities": {{}}}}

    Example for "what was the highest salary":
    {{"intent": "get_placement_summary", "entities": {{"stat_type": "highest_ctc"}}}}
    
    Example for "what is the highest ctc":
    {{"intent": "get_placement_summary", "entities": {{"stat_type": "highest_ctc"}}}}

    Example for "how many students were placed in total":
    {{"intent": "get_placement_summary", "entities": {{"stat_type": "total_selects"}}}}
    
    Example for "total selections":
    {{"intent": "get_placement_summary", "entities": {{"stat_type": "total_selects"}}}}

    Example for "average ctc":
    {{"intent": "get_placement_summary", "entities": {{"stat_type": "average_ctc"}}}}

    Example for "what is the median salary":
    {{"intent": "get_placement_summary", "entities": {{"stat_type": "median_ctc"}}}}
    
    Example for "lowest package":
    {{"intent": "get_placement_summary", "entities": {{"stat_type": "lowest_ctc"}}}}
    
    Example for "how many companies came":
    {{"intent": "get_placement_summary", "entities": {{"stat_type": "total_companies"}}}}
    
    Example for "placement summary":
    {{"intent": "get_placement_summary", "entities": {{}}}}

    Example for "stats for VISA":
    {{"intent": "get_company_stats", "entities": {{"company_name": "VISA"}}}}

    Example for "how many people did JPMC hire":
    {{"intent": "get_company_stats", "entities": {{"company_name": "JPMC"}}}}
    
    Example for "what was the ctc for Pure Storage":
    {{"intent": "get_company_stats", "entities": {{"company_name": "Pure Storage"}}}}

    Example for "who is the placement officer":
    {{"intent": "get_placements_info", "entities": {{}}}}
    
    Example for "how many dream companies offered packages":
    {{"intent": "get_placement_count_by_type", "entities": {{"ctc_type": "Dream"}}}}

    Example for "how many comapanies offerd dream packages":
    {{"intent": "get_placement_count_by_type", "entities": {{"ctc_type": "Dream"}}}}
    
    Example for "total mass recruiters":
    {{"intent": "get_placement_count_by_type", "entities": {{"ctc_type": "Mass"}}}}
    
    Example for "how many core companies came":
    {{"intent": "get_placement_count_by_type", "entities": {{"ctc_type": "Core"}}}}
    
    Example for "how many students got placed with a ctc of more than 12 lakhs":
    {{"intent": "get_placement_count_by_ctc", "entities": {{"ctc_operator": "gt", "ctc_amount": 12}}}}
    
    Example for "total selections with packages less than 8 lakhs":
    {{"intent": "get_placement_count_by_ctc", "entities": {{"ctc_operator": "lt", "ctc_amount": 8}}}}
    
    Example for "number of students who got over 20 lpa":
    {{"intent": "get_placement_count_by_ctc", "entities": {{"ctc_operator": "gt", "ctc_amount": 20}}}}
    
    Example for "list the companies that offered more than 15 lpa":
    {{"intent": "get_placement_companies_by_ctc", "entities": {{"ctc_operator": "gt", "ctc_amount": 15}}}}
    
    Example for "show me which companies gave packages under 5 lpa":
    {{"intent": "get_placement_companies_by_ctc", "entities": {{"ctc_operator": "lt", "ctc_amount": 5}}}}
    
    Example for "list those companies":
    {{"intent": "get_placement_companies_by_ctc", "entities": {{}}}}
    
    Example for "which ones":
    {{"intent": "get_placement_companies_by_ctc", "entities": {{}}}}
    --- END PLACEMENT EXAMPLES ---

    Example for "how to check attendance":
    {{"intent": "get_student_portal_info", "entities": {{}}}}
    
    Example for "where can i check my cie marks":
    {{"intent": "get_student_portal_info", "entities": {{}}}}

    --- STUDENT INFO EXAMPLES ---
    Example for "when do placements start":
    {{"intent": "get_placement_start_info", "entities": {{}}}}
    
    Example for "when do placement activities begin for 5th sem":
    {{"intent": "get_placement_start_info", "entities": {{}}}}

    Example for "what to do if I fail a class":
    {{"intent": "get_exam_registration_info", "entities": {{}}}}

    Example for "how to register for makeup exam":
    {{"intent": "get_exam_registration_info", "entities": {{}}}}

    Example for "i lost my id card":
    {{"intent": "get_lost_item_info", "entities": {{"lost_item": "id card"}}}}

    Example for "what to do if i lose my hall ticket":
    {{"intent": "get_lost_item_info", "entities": {{"lost_item": "hall ticket"}}}}
    --- END STUDENT INFO EXAMPLES ---
    
    --- FACULTY COURSES EXAMPLES ---
    Example for "what courses are taught by Dr. Kuzhalvaimozhi":
    {{"intent": "get_faculty_courses", "entities": {{"faculty_name": "Dr. Kuzhalvaimozhi"}}}}

    Example for "what subjects does Dr. Anitha R teach":
    {{"intent": "get_faculty_courses", "entities": {{"faculty_name": "Dr. Anitha R"}}}}

    Example for "list all of principal's courses":
    {{"intent": "get_faculty_courses", "entities": {{"faculty_name": "Dr. N V Archana"}}}}
    --- END FACULTY COURSES EXAMPLES ---

    --- FACULTY AVAILABILITY EXAMPLES ---
    Example for "when is Dr Vanamala free on monday":
    {{"intent": "get_faculty_availability", "entities": {{"faculty_name": "Dr Vanamala", "day": "Monday"}}}}

    Example for "is Dr Anitha R free at 3pm on tuesday":
    {{"intent": "get_faculty_availability", "entities": {{"faculty_name": "Dr Anitha R", "day": "Tuesday", "time_of_day": "3pm"}}}}
    
    Example for "is principal sir free":
    {{"intent": "get_faculty_availability", "entities": {{"faculty_name": "Dr. N V Archana"}}}}

    Example for "what is dr smith's schedule on friday":
    {{"intent": "get_faculty_availability", "entities": {{"faculty_name": "dr smith", "day": "Friday"}}}}
    
    Example for "show me all of dr anitha's classes":
    {{"intent": "get_timetable", "entities": {{"faculty_name": "dr anitha"}}}}
    --- END FACULTY AVAILABILITY EXAMPLES ---
    
    --- FOLLOW-UP EXAMPLES ---
    Example for "what about for A section":
    {{"intent": "get_course_instructors", "entities": {{"section": "A"}}}}
    
    Example for "and for cse b":
    {{"intent": "get_course_instructors", "entities": {{"branch": "CSE", "section": "B"}}}}
    
    Example for "yes":
    {{"intent": "general_chat", "entities": {{}}}}
    
    Example for "no that's wrong":
    {{"intent": "general_chat", "entities": {{}}}}
    --- END FOLLOW-UP EXAMPLES ---
    
    --- INITIALS EXAMPLES ---
    Example for "who is mnr":
    {{"intent": "get_faculty_info", "entities": {{"faculty_name": "Meghana NR"}}}}
    
    Example for "where is mnr's office":
    {{"intent": "get_faculty_location", "entities": {{"faculty_name": "Meghana NR"}}}}
    
    Example for "is sk free on monday":
    {{"intent": "get_faculty_availability", "entities": {{"faculty_name": "Dr S Kuzhalvaimozhi", "day": "Monday"}}}}
    
    Example for "what does sk teach":
    {{"intent": "get_faculty_courses", "entities": {{"faculty_name": "Dr S Kuzhalvaimozhi"}}}}
    
    Example for "who teaches cn":
    {{"intent": "get_course_instructors", "entities": {{"course_name": "Computer Networks"}}}}
    
    Example for "schedule for ds":
    {{"intent": "get_timetable", "entities": {{"course_name": "Distributed Systems"}}}}
    
    Example for "who teaches toc":
    {{"intent": "get_course_instructors", "entities": {{"course_name": "Theory of Computation"}}}}
    --- END INITIALS EXAMPLES ---

    Example for "thanks":
    {{"intent": "general_chat", "entities": {{}}}}
    """
    
    payload = {
        "contents": [
            {
                "parts": [
                    {"text": system_prompt},
                    {"text": f"User query: {user_query}"}
                ]
            }
        ],
        "generationConfig": {
            "responseMimeType": "application/json",
        }
    }
    
    try:
        # --- FIX: Corrected function call typo ---
        response_text = await _call_gemini_with_retry(payload, "intent")
        if response_text:
            json_text = response_text.strip().replace("```json\n", "").replace("\n```", "")
            return json.loads(json_text)
        else:
            print("Error: get_query_intent received None from API.")
            return {"intent": "unknown", "entities": {}}
            
    except Exception as e:
        print(f"Error getting intent from Gemini: {e}")
        try:
            return json.loads(str(e))
        except json.JSONDecodeError:
            print(f"Error: Could not parse Gemini response as JSON. Error: {e}")
            return {"intent": "unknown", "entities": {}}


async def generate_final_response(user_query, db_results):
    """
    Uses Gemini to generate a natural language response based on the query and DB results.
    This is used for 'general_chat' or when DB results are found.
    """
    # (This function is unchanged from your file)
    simple_queries = ['hi', 'hello', 'hey', 'thanks', 'thank you', 'ok', 'bye', 'goodbye', '?']
    is_simple_query = user_query.lower().strip() in simple_queries or len(user_query.strip()) < 4

    suggestion_text = ""
    if SUGGESTION_FORM_URL:
        suggestion_text = (
            f"If you were asking about specific college information and I missed it, "
            f"you can suggest this missing data by filling out our brief suggestion form here: {SUGGESTION_FORM_URL}"
        )
    else:
        suggestion_text = (
            "If you were asking about specific college information and I missed it, "
            "please try rephrasing your question with more details."
        )

    if is_simple_query:
        system_prompt = f"""
        You are a friendly and helpful college chatbot assistant.
        - The user has sent a simple greeting or a very short, unclear query (like 'yes' or 'no').
        - Respond naturally and conversationally (e.g., "Hello!", "How can I help?", "You're welcome!", "Okay.").
        - Do NOT add any suggestion links or ask the user to rephrase, just be polite.
        """
    else:
        system_prompt = f"""
        You are a friendly and helpful college chatbot assistant. Your job is to answer the user's query based on the information provided.
        - Be conversational and polite.
        - The "Database Results" are empty or "[]", meaning you are in a 'general_chat' or 'unknown' intent.
        - The user's query seems like a real question, but you don't have a specific function for it.
        - First, try to answer the query naturally (e.g., "I'm a bot...").
        - THEN, politely add the following suggestion: "{suggestion_text}"
        - Do not make up information.
        - Keep answers concise and clear.
        """
    
    payload = {
        "contents": [
            {
                "parts": [
                    {"text": system_prompt},
                    {"text": f"User Query: {user_query}"},
                    {"text": f"Database Results: {json.dumps(db_results, default=str)}"}
                ]
            }
        ],
        "generationConfig": {
            "temperature": 0.5 
        }
    }
    
    try:
        # --- FIX: Corrected function call typo ---
        response_text = await _call_gemini_with_retry(payload, "response")
        return response_text
    except Exception as e:
        print(f"Error generating final response from Gemini: {e}")
        return f"I'm sorry, I encountered an error trying to generate a response. (Error: {e})"


async def generate_suggestion_response(user_query):
    """
    Generates an apology and asks the user for a suggestion, optionally providing a form link.
    This is called when the DB returns no results for a *recognized* intent.
    """
    # (This function is unchanged from your file)
    if SUGGESTION_FORM_URL:
        prompt = _FORM_SUGGESTION_PROMPT.format(user_query=user_query, form_url=SUGGESTION_FORM_URL)
        print("Using Form Suggestion URL.")
    else:
        prompt = _FALLBACK_SUGGESTION_PROMPT.format(user_query=user_query)
        print("Using Fallback Suggestion Prompt.")

    payload = {
        "contents": [{"parts": [{"text": prompt}]}],
        "generationConfig": {
            "temperature": 0.5
        },
    }
    
    try:
        # --- FIX: Corrected function call typo ---
        response_text = await _call_gemini_with_retry(payload, "response")
        return response_text
    except Exception as e:
        print(f"Error generating suggestion response from Gemini: {e}")
        return f"I'm sorry, I couldn't find information about that. (Error: {e})"