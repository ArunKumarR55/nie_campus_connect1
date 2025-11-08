import os
import mysql.connector
from mysql.connector import pooling
import datetime # Added for timedelta conversion
import logging # Added for logging

# Global connection pool
db_pool = None
db_config = {} # Store config for logging

def connect():
    """Initializes the MySQL connection pool."""
    global db_pool, db_config # Include db_config
    try:
        # Store config details for logging
        db_config = {
            "host": os.getenv("DB_HOST"),
            "user": os.getenv("DB_USER"),
            "database": os.getenv("DB_NAME"),
            "port": 3306 # Default MySQL port
            # Don't log the password
        }

        db_pool = mysql.connector.pooling.MySQLConnectionPool(
            pool_name="chatbot_pool",
            pool_size=5,
            pool_reset_session=True,
            host=db_config["host"],
            user=os.getenv("DB_USER"), # Fetch user directly here
            password=os.getenv("DB_PASS"), # Fetch password directly here
            database=db_config["database"],
            port=db_config["port"]
        )
        print(f"Database connection pool created successfully for DB: {db_config['database']} on Host: {db_config['host']}") # Added more detail
    except mysql.connector.Error as err:
        print(f"Error creating connection pool: {err}")
        raise

def disconnect():
    """Closes all connections in the pool (not strictly necessary, but good practice)."""
    # In a real app, you'd just let the pool manage this.
    print("Database connection pool shutting down.")
    pass

def execute_query(query, params=None):
    """Executes a SQL SELECT query using a connection from the pool."""
    if not db_pool:
        raise Exception("Database pool is not initialized. Call connect() first.")

    # --- ADDED LOGGING ---
    print(f"Executing query on DB: {db_config.get('database', 'N/A')} @ Host: {db_config.get('host', 'N/A')}")
    print(f"SQL Query: {query}") # Log the query
    print(f"SQL Params: {params}") # Log the parameters
    # --- END LOGGING ---

    conn = None
    cursor = None
    try:
        conn = db_pool.get_connection()
        cursor = conn.cursor(dictionary=True) # Returns results as dictionaries

        cursor.execute(query, params or ())
        results = cursor.fetchall()
        print(f"Query returned {len(results)} results.") # Log result count

        # --- Convert timedelta to time object ---
        for row in results:
            for key, value in row.items():
                if isinstance(value, datetime.timedelta):
                    total_seconds = int(value.total_seconds())
                    # Ensure seconds are within a day for time object creation
                    if 0 <= total_seconds < 86400:
                         hours, remainder = divmod(total_seconds, 3600)
                         minutes, seconds = divmod(remainder, 60)
                         try:
                             time_obj = datetime.time(hours, minutes, seconds)
                             row[key] = time_obj # Keep as time object for formatter
                         except ValueError:
                              row[key] = f"Invalid Time ({total_seconds}s)"
                    else:
                         # Handle durations >= 24 hours if necessary, maybe as string
                         row[key] = f"Duration: {value}"


        return results

    except mysql.connector.Error as err:
        print(f"SQL Error: {err}")
        # Query and Params already logged above
        return None # Return None on error
    finally:
        if cursor:
            cursor.close()
        if conn:
            conn.close() # Returns the connection to the pool


# --- Database Query Functions for each Intent ---
def get_faculty_info(name, department, info_type):
    """
    Fetches faculty information. Prioritizes faculty table for role searches based on keywords.
    Only searches anti-ragging table by specific name if not a role search or faculty search yields no results for the name.
    """
    faculty_results = []
    ragging_results = []
    final_results = []
    is_exclusive_role_search = False # Flag for searching ONLY faculty by role
    role_keywords_to_search = [] # Keywords to use in the faculty search

    # --- REVISED: Focus on Input Keywords for Role Detection ---
    print(f"get_faculty_info called with name='{name}', department='{department}', info_type='{info_type}'") # Debug Input

    # Consolidate potential search terms, prioritize name if it exists and isn't just a role word
    primary_search_term = name
    if not name or name.lower() in ['principal', 'dean', 'controller', 'coe']:
        primary_search_term = department or info_type or name # Use dept/info/name if name is empty or a role word

    # Check if the primary search term indicates a role search
    if primary_search_term:
        search_term_lower = primary_search_term.lower()
        # Define role mappings
        role_map = {
            'principal': ['%principal%'],
            'dean': ['%dean%'],
            'controller': ['%controller%', '%coe%'],
            'coe': ['%controller%', '%coe%']
        }
        # Check if the search term IS one of the role keys
        matched_role_key = None
        for role_key in role_map.keys():
            # Check for exact match or simple containment if appropriate
            # Be careful not to misinterpret names containing role words
             if role_key == search_term_lower or (len(search_term_lower) <= len(role_key) + 2 and role_key in search_term_lower): # Allow slight variations
                matched_role_key = role_key
                break

        if matched_role_key:
            is_exclusive_role_search = True
            role_keywords_to_search = role_map[matched_role_key]
            print(f"Detected EXCLUSIVE role search for '{matched_role_key}' using keywords: {role_keywords_to_search}")

    # Query 1: Search faculty table
    faculty_query = """
        SELECT f.id, f.name, f.email, f.department, f.office_location, f.image_url, 'faculty' as source_table
        FROM faculty f
    """
    faculty_params = []
    faculty_conditions = []

    if is_exclusive_role_search:
        # Search ONLY by role keywords in the department column
        role_clauses = ["f.department LIKE %s" for _ in role_keywords_to_search]
        faculty_conditions.append(f"( {' OR '.join(role_clauses)} )")
        faculty_params.extend(list(set(role_keywords_to_search))) # Use set for unique keywords
        print(f"Searching faculty table EXCLUSIVELY for roles: {list(set(role_keywords_to_search))}")
    elif name:
        # Standard search by name (potentially within a department)
        # --- NEW: NORMALIZE the search ---
        normalized_name = f"%{name.replace(' ', '').replace('.', '').lower()}%"
        faculty_conditions.append("REPLACE(REPLACE(LOWER(f.name), ' ', ''), '.', '') LIKE %s")
        faculty_params.append(normalized_name)
        # --- END NEW ---
        
        if department:
             faculty_conditions.append("f.department LIKE %s")
             faculty_params.append(f"%{department}%")
    elif department:
         # Standard search by department only
         faculty_conditions.append("f.department LIKE %s")
         faculty_params.append(f"%{department}%")
    # Add handling for info_type if it's not a role and could be relevant

    # Execute faculty query if there are conditions
    if faculty_conditions:
        faculty_query += " WHERE " + " AND ".join(faculty_conditions)
        faculty_results = execute_query(faculty_query, faculty_params) or []


    # --- Decision Point ---
    # Use faculty results directly if it was an exclusive role search
    if is_exclusive_role_search:
        final_results = faculty_results
        print("Exclusive role search completed. Using only faculty results.")
    else:
        # --- Not an exclusive role search (likely name or department search) ---
        final_results.extend(faculty_results)

        # Search anti-ragging ONLY if a NAME was provided
        if name:
            print("Searching anti_ragging_squad table by name as fallback/supplement...")
            # --- NEW: NORMALIZE the search ---
            ragging_query = """
                SELECT a.name, NULL as email, a.department, NULL as office_location, a.role, a.contact_phone, NULL as image_url, 'anti_ragging' as source_table
                FROM anti_ragging_squad a WHERE REPLACE(REPLACE(LOWER(a.name), ' ', ''), '.', '') LIKE %s
            """
            normalized_name_ragging = f"%{name.replace(' ', '').replace('.', '').lower()}%"
            ragging_params = [normalized_name_ragging]
            # --- END NEW ---
            ragging_results = execute_query(ragging_query, ragging_params) or []
            final_results.extend(ragging_results) # Add results

    # --- Add default fields & Deduplicate ---
    processed_results = []
    seen_names = set()
    for result in final_results:
        current_name = result.get('name')
        # Basic deduplication by name
        if current_name and current_name in seen_names:
            print(f"Skipping duplicate entry for: {current_name}") # Debug duplicate
            continue
        if current_name:
            seen_names.add(current_name)

        result.setdefault('id', None) # Add default id
        result.setdefault('email', None)
        result.setdefault('office_location', None)
        result.setdefault('role', None) # From anti_ragging
        result.setdefault('contact_phone', None) # From anti_ragging
        result.setdefault('image_url', None) # Add default image_url
        result.setdefault('source_table', 'faculty') # Default source
        processed_results.append(result)

    print(f"get_faculty_info returning {len(processed_results)} unique result(s).")
    return processed_results


# --- NEW FUNCTION ---
def get_faculty_location(name):
    """
    Fetches only the faculty name and location.
    This version does NOT self-heal, as requested.
    """
    print(f"get_faculty_location called for name: '{name}'")
    
    # 1. Find the faculty and their current location
    # --- NEW: NORMALIZE the search ---
    query = "SELECT id, name, office_location FROM faculty WHERE REPLACE(REPLACE(LOWER(name), ' ', ''), '.', '') LIKE %s"
    normalized_name = f"%{name.replace(' ', '').replace('.', '').lower()}%"
    params = (normalized_name,)
    # --- END NEW ---
    
    faculty_results = execute_query(query, params)
    
    if not faculty_results:
        print("No faculty found.")
        return [] # Return empty list if no faculty matches
        
    if len(faculty_results) > 1:
        print("Multiple faculty found, returning list for disambiguation.")
        # Return just the names for app.py to format
        return [{"name": f.get('name')} for f in faculty_results]

    # --- We have exactly one faculty member ---
    # Return the full result (name and location, even if location is NULL)
    return faculty_results

# --- END NEW FUNCTION ---


def get_timetable(branch, section, study_year, day, faculty_name, course_name, course_code):
    """Fetches timetable information. This is a complex join."""
    query = """
        SELECT
            t.day_of_week,
            t.start_time,
            t.end_time,
            t.room_no,
            t.location,
            co.course_name,
            f.name AS faculty_name,
            c.class_type,
            c.lab_batch,
            c.branch,        -- Added branch
            c.section,       -- Added section
            c.study_year     -- Added study_year
        FROM timetable_slots t
        JOIN classes c ON t.class_id = c.class_id
        JOIN courses co ON c.course_code = co.course_code
        LEFT JOIN faculty f ON c.faculty_id = f.id
        WHERE 1=1
    """
    params = []
    if branch:
        query += " AND c.branch LIKE %s"
        params.append(f"%{branch}%")
    if section:
        query += " AND c.section LIKE %s"
        params.append(f"%{section}%")
    if study_year:
        query += " AND c.study_year = %s"
        params.append(study_year)
    if day:
        query += " AND t.day_of_week LIKE %s"
        params.append(f"%{day}%")
        
    # --- NEW: NORMALIZE the search ---
    if faculty_name:
        query += " AND REPLACE(REPLACE(LOWER(f.name), ' ', ''), '.', '') LIKE %s"
        normalized_name = f"%{faculty_name.replace(' ', '').replace('.', '').lower()}%"
        params.append(normalized_name)
    # --- END NEW ---
        
    if course_name:
        query += " AND co.course_name LIKE %s"
        params.append(f"%{course_name}%")
    # --- NEW: Added course_code ---
    if course_code:
        query += " AND co.course_code LIKE %s"
        params.append(f"%{course_code}%")
        
    query += " ORDER BY FIELD(t.day_of_week, 'Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday', 'Sunday'), t.start_time"
    return execute_query(query, params)

# --- NEW FUNCTION ---
def get_course_instructors(course_name, course_code):
    """Fetches all faculty who teach a given course."""
    print(f"get_course_instructors called with name='{course_name}', code='{course_code}'")
    
    query = """
        SELECT DISTINCT
            f.name AS faculty_name,
            co.course_name,
            co.course_code,
            c.branch,
            c.section
        FROM faculty f
        JOIN classes c ON f.id = c.faculty_id
        JOIN courses co ON c.course_code = co.course_code
        WHERE 1=1
    """
    params = []
    conditions = []
    
    if course_name:
        conditions.append("co.course_name LIKE %s")
        params.append(f"%{course_name}%")
    if course_code:
        conditions.append("co.course_code LIKE %s")
        params.append(f"%{course_code}%")
        
    if not conditions:
        print("No course name or code provided.")
        return [] # Don't return all instructors
        
    query += " AND (" + " OR ".join(conditions) + ")"
    query += " ORDER BY co.course_name, f.name, c.branch, c.section"
    
    return execute_query(query, params)
# --- END NEW FUNCTION ---


def get_club_info(name):
    """Fetches club information."""
    query = "SELECT name, description, contact_person, contact_phone FROM clubs WHERE 1=1"
    params = []
    if name:
        query += " AND name LIKE %s"
        params.append(f"%{name}%")
    return execute_query(query, params)

def get_dress_code(category):
    """Fetches dress code rules."""
    query = "SELECT category, type, items FROM dress_code WHERE 1=1"
    params = []
    if category:
        query += " AND category LIKE %s"
        params.append(f"%{category}%")
    return execute_query(query, params)

def get_admissions_info():
    """Fetches admissions contact."""
    query = "SELECT * FROM admissions"
    return execute_query(query)

def get_placements_info():
    """Fetches placements contact."""
    query = "SELECT * FROM placements"
    return execute_query(query)

def get_fees_info():
    """Fetches fees contact."""
    query = "SELECT * FROM fees"
    return execute_query(query)

def get_anti_ragging_info():
    """Fetches anti-ragging squad info."""
    query = "SELECT name, role, department, contact_phone FROM anti_ragging_squad"
    return execute_query(query)

def get_hostel_info(name, gender, campus):
    """Fetches hostel details."""
    query = "SELECT name, campus, gender, facilities, warden_name, contact_phone FROM hostels WHERE 1=1"
    params = []
    if name:
        query += " AND name LIKE %s"
        params.append(f"%{name}%")
    if gender:
        query += " AND gender LIKE %s"
        params.append(f"%{gender}%")
    if campus:
        query += " AND campus LIKE %s"
        params.append(f"%{campus}%")
    return execute_query(query, params)

def get_transport_info(route_name):
    """Fetches transport details."""
    query = "SELECT route_name, description, contact_person, contact_phone FROM transport WHERE 1=1"
    params = []
    if route_name:
        query += " AND route_name LIKE %s"
        params.append(f"%{route_name}%")
    return execute_query(query, params)

def get_scholarship_info(scholarship_name=None, branch=None, year=None):
    """
    Fetches scholarship contact details from the database.
    Searches the 'name' column.
    """
    print(f"get_scholarship_info called with name='{scholarship_name}', branch='{branch}', year='{year}'")
    sql = "SELECT name, location, mail_id FROM scholarship_details"
    params = []
    if scholarship_name:
        sql += " WHERE name LIKE %s"
        params.append(f"%{scholarship_name}%")
    return execute_query(sql, params)


def get_event_info(title):
    """Fetches event details."""
    query = "SELECT title, DATE_FORMAT(event_date, '%W, %M %e, %Y') as event_date, description FROM events WHERE 1=1"
    params = []
    if title:
        query += " AND title LIKE %s"
        params.append(f"%{title}%")
    query += " ORDER BY event_date DESC"
    return execute_query(query, params)

def get_notice_info():
    """Fetches the 5 most recent notices."""
    query = "SELECT notice_text, DATE_FORMAT(posted_on, '%W, %M %e, %Y') as posted_on FROM notices ORDER BY posted_on DESC LIMIT 5"
    return execute_query(query)

# --- get_campus_map_data (Unchanged) ---
def get_campus_map_data(location_name=None):
    """
    Returns the campus map URL.
    This function does NOT query the SQL database.
    """
    print(f"get_campus_map_data called for location: {location_name}")
    
    # Get the URL from the environment variable
    map_url = os.getenv("COLLEGE_MAP_URL")
    
    response_text = ""
    
    if not map_url:
        # If the URL is missing, send an error message
        logging.error("CRITICAL: get_campus_map_data failed. COLLEGE_MAP_URL is not set in .env file.")
        response_text = "I'm sorry, I couldn't retrieve the campus map. The feature seems to be misconfigured."
    else:
        # If a specific location was asked for, customize the text
        if location_name:
            response_text = f"Here is the campus map. You can use it to find the {location_name}."
        else:
            # Generic map request
            response_text = "Here is the campus map!"
            
    # Return the dictionary in the format app.py now expects
    return {
        'text': response_text,
        'media_url': map_url # This will be None if not map_url, which is correct
    }
# --- END NEW FUNCTION ---

# --- get_placement_stats_data (Unchanged) ---
def get_placement_stats_data():
    """
    Returns the placement stats PDF URL.
    This function does NOT query the SQL database.
    """
    print("get_placement_stats_data called.")
    
    # Get the URL from the environment variable
    pdf_url = os.getenv("PLACEMENT_PDF_URL")
    
    response_text = ""
    
    if not pdf_url:
        # If the URL is missing, send an error message
        logging.error("CRITICAL: get_placement_stats_data failed. PLACEMENT_PDF_URL is not set in .env file.")
        response_text = "I'm sorry, I couldn't retrieve the placement statistics document. The feature seems to be misconfigured."
    else:
        # Generic map request
        # --- NEW: Updated text as requested by guide ---
        response_text = "That's a lot of data! Here is the complete placement report PDF."
            
    # Return the dictionary in the format app.py now expects
    return {
        'text': response_text,
        'media_url': pdf_url # This will be None if not pdf_url, which is correct
    }
# --- END NEW FUNCTION ---

# --- get_student_portal_data (Unchanged) ---
def get_student_portal_data():
    """
    Returns the student portal URL (for attendance/marks).
    This function does NOT query the SQL database.
    """
    print("get_student_portal_data called.")
    
    # Get the URL from the environment variable
    portal_url = os.getenv("ATTENDANCE_URL")
    
    response_text = ""
    
    if not portal_url:
        # If the URL is missing, send an error message
        logging.error("CRITICAL: get_student_portal_data failed. ATTENDANCE_URL is not set in .env file.")
        response_text = "I'm sorry, I couldn't retrieve the student portal link. The feature seems to be misconfigured."
    else:
        # Generic map request
        response_text = (
            "You can check your attendance, CIE marks, and internal marks on the official student portal here:\n"
            f"{portal_url}"
        )
            
    # Return the dictionary in the format app.py now expects
    return {
        'text': response_text,
        'media_url': None # This is a text-only response
    }
# --- END NEW FUNCTION ---

# --- NEW PLACEMENT DB FUNCTIONS ---

def get_placement_summary_data():
    """Fetches the overall placement summary stats."""
    print("get_placement_summary_data called.")
    query = "SELECT * FROM placement_summary ORDER BY id DESC LIMIT 1"
    return execute_query(query)

def get_company_stats_data(company_name):
    """Fetches placement stats for a specific company."""
    print(f"get_company_stats_data called for: {company_name}")
    query = "SELECT company_name, ctc, num_selects, ctc_type FROM placement_companies WHERE company_name LIKE %s"
    
    # Normalize the search to be more flexible
    # e.g., "JPMC (CFG)" can be found by "JPMC"
    params = (f"%{company_name}%",) 
    
    return execute_query(query, params)

# --- NEW: Function to count by ctc_type ---
def get_placement_count_by_type_data(ctc_type):
    """Fetches the count of companies for a specific ctc_type."""
    print(f"get_placement_count_by_type_data called for: {ctc_type}")
    
    # Use LIKE to be flexible (e.g., 'Dream' matches 'Open Dream' and 'Dream')
    # Use LOWER to make it case-insensitive
    query = """
        SELECT ctc_type, COUNT(*) as company_count
        FROM placement_companies
        WHERE LOWER(ctc_type) LIKE %s
        GROUP BY ctc_type
    """
    params = (f"%{ctc_type.lower()}%",)
    
    return execute_query(query, params)
# --- END NEW FUNCTION ---

# --- NEW: Function to count by ctc amount ---
def get_placement_count_by_ctc_data(operator, amount):
    """
    Fetches the number of students and companies above/below a certain CTC.
    """
    print(f"get_placement_count_by_ctc_data called for: {operator} {amount}")
    
    # 1. Validate and map the operator to a safe SQL operator
    if operator == 'gt':
        sql_operator = '>'
    elif operator == 'lt':
        sql_operator = '<'
    else:
        print(f"Invalid operator provided: {operator}")
        return None # Invalid operator
        
    # 2. Build the query.
    # We use a subquery to handle companies with NULL CTC
    # SUM(num_selects) will correctly sum up all students
    # COUNT(company_name) will count the number of companies
    query = f"""
        SELECT 
            SUM(num_selects) as total_students,
            COUNT(company_name) as total_companies
        FROM placement_companies
        WHERE ctc {sql_operator} %s
    """
    
    # 3. Set the parameters
    try:
        ctc_amount = float(amount)
        params = (ctc_amount,)
    except ValueError:
        print(f"Invalid CTC amount provided: {amount}")
        return None # Invalid amount
    
    # 4. Execute
    return execute_query(query, params)
# --- END NEW FUNCTION ---
def get_faculty_schedule(faculty_name, day):
    """
    Fetches all busy slots (start and end times) for a specific faculty on a specific day.
    """
    print(f"get_faculty_schedule called for: {faculty_name} on {day}")
    
    query = """
        SELECT
            t.start_time,
            t.end_time
        FROM timetable_slots t
        JOIN classes c ON t.class_id = c.class_id
        JOIN faculty f ON c.faculty_id = f.id
        WHERE 1=1
        AND REPLACE(REPLACE(LOWER(f.name), ' ', ''), '.', '') LIKE %s
        AND t.day_of_week LIKE %s
        ORDER BY t.start_time
    """
    
    normalized_name = f"%{faculty_name.replace(' ', '').replace('.', '').lower()}%"
    params = (normalized_name, f"%{day}%")
    
    return execute_query(query, params)
def get_courses_for_faculty(faculty_name):
    """
    Fetches a distinct list of all courses taught by a specific faculty member.
    """
    print(f"get_courses_for_faculty called for: {faculty_name}")
    
    # This query finds the distinct courses taught by a faculty
    query = """
        SELECT DISTINCT
            co.course_code,
            co.course_name
        FROM courses co
        JOIN classes c ON co.course_code = c.course_code
        JOIN faculty f ON c.faculty_id = f.id
        WHERE REPLACE(REPLACE(LOWER(f.name), ' ', ''), '.', '') LIKE %s
        ORDER BY co.course_name
    """
    
    # Use the same name normalization
    normalized_name = f"%{faculty_name.replace(' ', '').replace('.', '').lower()}%"
    params = (normalized_name,)
    
    return execute_query(query, params)