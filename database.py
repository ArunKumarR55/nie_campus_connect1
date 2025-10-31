import os
import mysql.connector
from mysql.connector import pooling
import datetime # Added for timedelta conversion

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
    """Executes a SQL query using a connection from the pool."""
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
        SELECT f.name, f.email, f.department, f.office_location, 'faculty' as source_table
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
        faculty_conditions.append("f.name LIKE %s")
        faculty_params.append(f"%{name}%")
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
        # AND (optional) only if faculty search didn't already find them?
        # Let's keep it simple: search ragging if name was the input.
        if name:
            print("Searching anti_ragging_squad table by name as fallback/supplement...")
            ragging_query = """
                SELECT a.name, NULL as email, a.department, NULL as office_location, a.role, a.contact_phone, 'anti_ragging' as source_table
                FROM anti_ragging_squad a WHERE a.name LIKE %s
            """
            ragging_params = [f"%{name}%"]
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

        result.setdefault('email', None)
        result.setdefault('office_location', None)
        result.setdefault('role', None) # From anti_ragging
        result.setdefault('contact_phone', None) # From anti_ragging
        result.setdefault('source_table', 'faculty') # Default source
        processed_results.append(result)

    print(f"get_faculty_info returning {len(processed_results)} unique result(s).")
    return processed_results
    # --- END REVISION ---


def get_timetable(branch, section, study_year, day, faculty_name, course_name):
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
    if faculty_name:
        query += " AND f.name LIKE %s"
        params.append(f"%{faculty_name}%")
    if course_name:
        query += " AND co.course_name LIKE %s"
        params.append(f"%{course_name}%")

    # Order by day and time
    query += " ORDER BY FIELD(t.day_of_week, 'Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday', 'Sunday'), t.start_time"

    return execute_query(query, params)

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
    # This intent should remain separate unless specifically asked about the squad
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
    
    # --- FIX: Use the 'name' column from your screenshot ---
    sql = "SELECT name, location, mail_id FROM scholarship_details"
    params = []

    if scholarship_name:
        # Search the 'name' column using the 'scholarship_name' entity
        sql += " WHERE name LIKE %s"
        params.append(f"%{scholarship_name}%")
    
    # Call 'execute_query' (which we fixed last time)
    return execute_query(sql, params)


def get_event_info(title):
    """Fetches event details."""
    # Corrected DATE_FORMAT specifiers
    query = "SELECT title, DATE_FORMAT(event_date, '%W, %M %e, %Y') as event_date, description FROM events WHERE 1=1"
    params = []
    if title:
        query += " AND title LIKE %s"
        params.append(f"%{title}%")
    # Order by original date for correctness, formatting is just for display
    query += " ORDER BY event_date DESC"
    return execute_query(query, params)

def get_notice_info():
    """Fetches the 5 most recent notices."""
    # Corrected DATE_FORMAT specifiers
    query = "SELECT notice_text, DATE_FORMAT(posted_on, '%W, %M %e, %Y') as posted_on FROM notices ORDER BY posted_on DESC LIMIT 5"
    return execute_query(query)

