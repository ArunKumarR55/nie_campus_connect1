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
    Fetches faculty information.
    NOTE: This function now expects a *confirmed, correct* name, 
    as fuzzy matching is handled by get_faculty_location().
    """
    faculty_results = []
    ragging_results = []
    final_results = []
    is_exclusive_role_search = False # Flag for searching ONLY faculty by role
    role_keywords_to_search = [] # Keywords to use in the faculty search

    print(f"get_faculty_info called with name='{name}', department='{department}', info_type='{info_type}'") # Debug Input

    primary_search_term = name
    if not name or name.lower() in ['principal', 'dean', 'controller', 'coe']:
        primary_search_term = department or info_type or name

    if primary_search_term:
        search_term_lower = primary_search_term.lower()
        role_map = {
            'principal': ['%principal%'], 'dean': ['%dean%'],
            'controller': ['%controller%', '%coe%'], 'coe': ['%controller%', '%coe%']
        }
        matched_role_key = None
        for role_key in role_map.keys():
             if role_key == search_term_lower or (len(search_term_lower) <= len(role_key) + 2 and role_key in search_term_lower):
                matched_role_key = role_key
                break

        if matched_role_key:
            is_exclusive_role_search = True
            role_keywords_to_search = role_map[matched_role_key]
            print(f"Detected EXCLUSIVE role search for '{matched_role_key}' using keywords: {role_keywords_to_search}")

    faculty_query = """
        SELECT f.id, f.name, f.email, f.department, f.office_location, f.image_url, 'faculty' as source_table
        FROM faculty f
    """
    faculty_params = []
    faculty_conditions = []

    if is_exclusive_role_search:
        role_clauses = ["f.department LIKE %s" for _ in role_keywords_to_search]
        faculty_conditions.append(f"( {' OR '.join(role_clauses)} )")
        faculty_params.extend(list(set(role_keywords_to_search)))
        print(f"Searching faculty table EXCLUSIVELY for roles: {list(set(role_keywords_to_search))}")
    elif name:
        # --- FIX: Use a normalized, exact-ish match ---
        # The spell-check logic in app.py will pass the *correct* name here.
        normalized_name = f"%{name.replace(' ', '').replace('.', '').lower()}%"
        faculty_conditions.append("REPLACE(REPLACE(LOWER(f.name), ' ', ''), '.', '') LIKE %s")
        faculty_params.append(normalized_name)
        # --- END FIX ---
        
        if department:
             faculty_conditions.append("f.department LIKE %s")
             faculty_params.append(f"%{department}%")
    elif department:
         faculty_conditions.append("f.department LIKE %s")
         faculty_params.append(f"%{department}%")

    if faculty_conditions:
        faculty_query += " WHERE " + " AND ".join(faculty_conditions)
        faculty_results = execute_query(faculty_query, faculty_params) or []

    if is_exclusive_role_search:
        final_results = faculty_results
        print("Exclusive role search completed. Using only faculty results.")
    else:
        final_results.extend(faculty_results)
        if name:
            print("Searching anti_ragging_squad table by name as fallback/supplement...")
            # --- FIX: Use normalized LIKE match ---
            ragging_query = """
                SELECT a.name, NULL as email, a.department, NULL as office_location, a.role, a.contact_phone, NULL as image_url, 'anti_ragging' as source_table
                FROM anti_ragging_squad a WHERE REPLACE(REPLACE(LOWER(a.name), ' ', ''), '.', '') LIKE %s
            """
            normalized_name_ragging = f"%{name.replace(' ', '').replace('.', '').lower()}%"
            ragging_params = [normalized_name_ragging]
            # --- END FIX ---
            ragging_results = execute_query(ragging_query, ragging_params) or []
            final_results.extend(ragging_results) # Add results

    processed_results = []
    seen_names = set()
    for result in final_results:
        current_name = result.get('name')
        if current_name and current_name in seen_names:
            print(f"Skipping duplicate entry for: {current_name}")
            continue
        if current_name:
            seen_names.add(current_name)

        result.setdefault('id', None); result.setdefault('email', None)
        result.setdefault('office_location', None); result.setdefault('role', None)
        result.setdefault('contact_phone', None); result.setdefault('image_url', None)
        result.setdefault('source_table', 'faculty')
        processed_results.append(result)

    print(f"get_faculty_info returning {len(processed_results)} unique result(s).")
    return processed_results


# --- MODIFIED FUNCTION ---
def get_faculty_location(name):
    """
    Fetches faculty name and location using SOUNDEX on the last name to catch typos.
    This is the "checker" function for app.py.
    """
    print(f"get_faculty_location (checker) called for name: '{name}'")
    
    # --- Step 1: Try a normalized, exact-ish match first ---
    # This finds "Dr. S Kuzhalvaimozhi" if user types "kuzhalvaimozhi"
    normalized_name = f"%{name.replace(' ', '').replace('.', '').lower()}%"
    query_exact = """
        SELECT id, name, office_location
        FROM faculty
        WHERE REPLACE(REPLACE(LOWER(name), ' ', ''), '.', '') LIKE %s
        LIMIT 5
    """
    params_exact = (normalized_name,)
    
    exact_results = execute_query(query_exact, params_exact)
    
    if exact_results:
        print(f"Found {len(exact_results)} exact-ish matches.")
        # Add 'match_type' for app.py
        for r in exact_results: r['match_type'] = 'exact'
        return exact_results

    # --- Step 2: If no exact match, try SOUNDEX on the last name ---
    print("No exact match found. Trying SOUNDEX search...")
    
    # SUBSTRING_INDEX(name, ' ', -1) gets the last word of the name (e.g., "Kuzhalvaimozhi")
    # This correctly compares SOUNDEX('Kuzhalvaimozhi') to SOUNDEX('kuzalvaimozhi')
    query_soundex = """
        SELECT id, name, office_location
        FROM faculty
        WHERE SOUNDEX(SUBSTRING_INDEX(name, ' ', -1)) = SOUNDEX(%s)
        LIMIT 5
    """
    params_soundex = (name,)
    
    soundex_results = execute_query(query_soundex, params_soundex)
    
    if soundex_results:
        print(f"Found {len(soundex_results)} SOUNDEX matches.")
        # Add 'match_type' for app.py
        for r in soundex_results: r['match_type'] = 'fuzzy' # Mark as fuzzy
        return soundex_results
        
    # --- Step 3: Still no match ---
    print("No faculty found by any method.")
    return []
# --- END MODIFIED FUNCTION ---


def get_timetable(branch, section, study_year, day, faculty_name, course_name, course_code):
    """Fetches timetable information. This is a complex join."""
    query = """
        SELECT
            t.day_of_week, t.start_time, t.end_time, t.room_no, t.location,
            co.course_name, f.name AS faculty_name, c.class_type, c.lab_batch,
            c.branch, c.section, c.study_year
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
        
    # --- FIX: Use normalized LIKE match (app.py provides correct name) ---
    if faculty_name:
        normalized_name = f"%{faculty_name.replace(' ', '').replace('.', '').lower()}%"
        query += " AND REPLACE(REPLACE(LOWER(f.name), ' ', ''), '.', '') LIKE %s"
        params.append(normalized_name)
    # --- END FIX ---
        
    if course_name:
        query += " AND co.course_name LIKE %s"
        params.append(f"%{course_name}%")
    if course_code:
        query += " AND co.course_code LIKE %s"
        params.append(f"%{course_code}%")
        
    query += " ORDER BY FIELD(t.day_of_week, 'Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday', 'Sunday'), t.start_time"
    return execute_query(query, params)

# --- MODIFIED FUNCTION ---
def get_course_instructors(course_name, course_code, branch, section):
    """Fetches all faculty who teach a given course, with optional branch/section filter."""
    print(f"get_course_instructors called with name='{course_name}', code='{course_code}', branch='{branch}', section='{section}'")
    
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
    
    course_conditions = []
    if course_name:
        course_conditions.append("co.course_name LIKE %s")
        params.append(f"%{course_name}%")
    if course_code:
        course_conditions.append("co.course_code LIKE %s")
        params.append(f"%{course_code}%")
        
    if not course_conditions:
        print("No course name or code provided.")
        return []
        
    conditions.append("(" + " OR ".join(course_conditions) + ")")
    
    if branch:
        conditions.append("c.branch LIKE %s")
        params.append(f"%{branch}%")
    if section:
        conditions.append("c.section LIKE %s")
        params.append(f"%{section}%")
        
    query += " AND " + " AND ".join(conditions)
    query += " ORDER BY co.course_name, f.name, c.branch, c.section"
    
    return execute_query(query, params)
# --- END MODIFIED FUNCTION ---


def get_club_info(name):
    query = "SELECT name, description, contact_person, contact_phone FROM clubs WHERE 1=1"
    params = []
    if name:
        query += " AND name LIKE %s"
        params.append(f"%{name}%")
    return execute_query(query, params)

def get_dress_code(category):
    query = "SELECT category, type, items FROM dress_code WHERE 1=1"
    params = []
    if category:
        query += " AND category LIKE %s"
        params.append(f"%{category}%")
    return execute_query(query, params)

def get_admissions_info():
    query = "SELECT * FROM admissions"
    return execute_query(query)

def get_placements_info():
    query = "SELECT * FROM placements"
    return execute_query(query)

def get_fees_info():
    query = "SELECT * FROM fees"
    return execute_query(query)

def get_anti_ragging_info():
    query = "SELECT name, role, department, contact_phone FROM anti_ragging_squad"
    return execute_query(query)

def get_hostel_info(name, gender, campus):
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
    query = "SELECT route_name, description, contact_person, contact_phone FROM transport WHERE 1=1"
    params = []
    if route_name:
        query += " AND route_name LIKE %s"
        params.append(f"%{route_name}%")
    return execute_query(query, params)

def get_scholarship_info(scholarship_name=None, branch=None, year=None):
    print(f"get_scholarship_info called with name='{scholarship_name}', branch='{branch}', year='{year}'")
    sql = "SELECT name, location, mail_id FROM scholarship_details"
    params = []
    if scholarship_name:
        sql += " WHERE name LIKE %s"
        params.append(f"%{scholarship_name}%")
    return execute_query(sql, params)


def get_event_info(title):
    query = "SELECT title, DATE_FORMAT(event_date, '%W, %M %e, %Y') as event_date, description FROM events WHERE 1=1"
    params = []
    if title:
        query += " AND title LIKE %s"
        params.append(f"%{title}%")
    query += " ORDER BY event_date DESC"
    return execute_query(query, params)

def get_notice_info():
    query = "SELECT notice_text, DATE_FORMAT(posted_on, '%W, %M %e, %Y') as posted_on FROM notices ORDER BY posted_on DESC LIMIT 5"
    return execute_query(query)

def get_campus_map_data(location_name=None):
    print(f"get_campus_map_data called for location: {location_name}")
    map_url = os.getenv("COLLEGE_MAP_URL")
    response_text = ""
    if not map_url:
        logging.error("CRITICAL: get_campus_map_data failed. COLLEGE_MAP_URL is not set in .env file.")
        response_text = "I'm sorry, I couldn't retrieve the campus map. The feature seems to be misconfigured."
    else:
        if location_name:
            response_text = f"Here is the campus map. You can use it to find the {location_name}."
        else:
            response_text = "Here is the campus map!"
    return {'text': response_text, 'media_url': map_url}

def get_placement_stats_data():
    print("get_placement_stats_data called.")
    pdf_url = os.getenv("PLACEMENT_PDF_URL")
    response_text = ""
    if not pdf_url:
        logging.error("CRITICAL: get_placement_stats_data failed. PLACEMENT_PDF_URL is not set in .env file.")
        response_text = "I'm sorry, I couldn't retrieve the placement statistics document. The feature seems to be misconfigured."
    else:
        response_text = "That's a lot of data! Here is the complete placement report PDF."
    return {'text': response_text, 'media_url': pdf_url}

def get_student_portal_data():
    print("get_student_portal_data called.")
    portal_url = os.getenv("ATTENDANCE_URL")
    response_text = ""
    if not portal_url:
        logging.error("CRITICAL: get_student_portal_data failed. ATTENDANCE_URL is not set in .env file.")
        response_text = "I'm sorry, I couldn't retrieve the student portal link. The feature seems to be misconfigured."
    else:
        response_text = (
            "You can check your attendance, CIE marks, and internal marks on the official student portal here:\n"
            f"{portal_url}"
        )
    return {'text': response_text, 'media_url': None}

def get_placement_summary_data():
    print("get_placement_summary_data called.")
    query = "SELECT * FROM placement_summary ORDER BY id DESC LIMIT 1"
    return execute_query(query)

def get_company_stats_data(company_name):
    print(f"get_company_stats_data called for: {company_name}")
    query = "SELECT company_name, ctc, num_selects, ctc_type FROM placement_companies WHERE company_name LIKE %s"
    params = (f"%{company_name}%",) 
    return execute_query(query, params)

def get_placement_count_by_type_data(ctc_type):
    print(f"get_placement_count_by_type_data called for: {ctc_type}")
    query = """
        SELECT ctc_type, COUNT(*) as company_count
        FROM placement_companies
        WHERE LOWER(ctc_type) LIKE %s
        GROUP BY ctc_type
    """
    params = (f"%{ctc_type.lower()}%",)
    return execute_query(query, params)

def get_placement_count_by_ctc_data(operator, amount):
    print(f"get_placement_count_by_ctc_data called for: {operator} {amount}")
    if operator == 'gt': sql_operator = '>'
    elif operator == 'lt': sql_operator = '<'
    else:
        print(f"Invalid operator provided: {operator}")
        return None
    query = f"""
        SELECT SUM(num_selects) as total_students, COUNT(company_name) as total_companies
        FROM placement_companies
        WHERE ctc {sql_operator} %s
    """
    try:
        ctc_amount = float(amount)
        params = (ctc_amount,)
    except (ValueError, TypeError):
        print(f"Invalid CTC amount provided: {amount}")
        return None
    return execute_query(query, params)

def get_placement_companies_by_ctc_data(operator, amount):
    print(f"get_placement_companies_by_ctc_data called for: {operator} {amount}")
    if operator == 'gt': sql_operator = '>'
    elif operator == 'lt': sql_operator = '<'
    else:
        print(f"Invalid operator provided: {operator}")
        return None
    query = f"""
        SELECT company_name, ctc, num_selects, ctc_type
        FROM placement_companies
        WHERE ctc {sql_operator} %s
        ORDER BY ctc DESC, company_name
    """
    try:
        ctc_amount = float(amount)
        params = (ctc_amount,)
    except (ValueError, TypeError):
        print(f"Invalid CTC amount provided: {amount}")
        return None
    return execute_query(query, params)


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
    # --- FIX: Use normalized LIKE (app.py provides correct name) ---
    normalized_name = f"%{faculty_name.replace(' ', '').replace('.', '').lower()}%"
    params = (normalized_name, f"%{day}%")
    # --- END FIX ---
    
    return execute_query(query, params)

def get_courses_for_faculty(faculty_name):
    """
    Fetches a distinct list of all courses taught by a specific faculty member.
    """
    print(f"get_courses_for_faculty called for: {faculty_name}")
    
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
    # --- FIX: Use normalized LIKE (app.py provides correct name) ---
    normalized_name = f"%{faculty_name.replace(' ', '').replace('.', '').lower()}%"
    params = (normalized_name,)
    # --- END FIX ---
    
    return execute_query(query, params)