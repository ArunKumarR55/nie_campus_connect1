-- 1. CREATE DATABASE

USE campus_bot4;

-- 2. DROP ALL TABLES (in reverse order of dependency)

-- 3. CREATE TABLES
CREATE TABLE faculty (
    id INT AUTO_INCREMENT PRIMARY KEY,
    name VARCHAR(100) NOT NULL,
    email VARCHAR(100) UNIQUE,
    department VARCHAR(100) DEFAULT NULL,
    office_location VARCHAR(255) DEFAULT NULL
);

CREATE TABLE departments (
    id INT AUTO_INCREMENT PRIMARY KEY,
    name VARCHAR(100) NOT NULL,
    hod VARCHAR(100),
    contact_email VARCHAR(100)
);

CREATE TABLE courses (
    course_code VARCHAR(20) PRIMARY KEY,
    course_name VARCHAR(200) NOT NULL,
    department VARCHAR(100)
);

CREATE TABLE classes (
    class_id INT AUTO_INCREMENT PRIMARY KEY,
    course_code VARCHAR(20),
    faculty_id INT NULL, -- Allowed to be NULL
    study_year INT NOT NULL,
    branch VARCHAR(50) NOT NULL,
    section VARCHAR(5) NOT NULL,
    class_type VARCHAR(10) NOT NULL DEFAULT 'Lecture',
    lab_batch VARCHAR(10) DEFAULT NULL,
    FOREIGN KEY (course_code) REFERENCES courses(course_code),
    FOREIGN KEY (faculty_id) REFERENCES faculty(id)
);

CREATE TABLE timetable_slots (
    slot_id INT AUTO_INCREMENT PRIMARY KEY,
    class_id INT,
    day_of_week VARCHAR(15) NOT NULL,
    start_time TIME NOT NULL,
    end_time TIME NOT NULL,
    room_no VARCHAR(50),
    location VARCHAR(100),
    FOREIGN KEY (class_id) REFERENCES classes(class_id)
);

CREATE TABLE dress_code (
    id INT AUTO_INCREMENT PRIMARY KEY,
    category VARCHAR(10) NOT NULL,
    type VARCHAR(20) NOT NULL,
    items TEXT NOT NULL
);

CREATE TABLE clubs (
    id INT AUTO_INCREMENT PRIMARY KEY,
    name VARCHAR(100) NOT NULL,
    description TEXT,
    contact_person VARCHAR(100),
    contact_phone VARCHAR(20)
);

CREATE TABLE anti_ragging_squad (
    id INT AUTO_INCREMENT PRIMARY KEY,
    name VARCHAR(100) NOT NULL,
    role VARCHAR(100),
    department VARCHAR(100),
    contact_phone VARCHAR(20)
);

CREATE TABLE events (
    id INT AUTO_INCREMENT PRIMARY KEY,
    title VARCHAR(200) NOT NULL,
    event_date DATE,
    description TEXT
);

CREATE TABLE notices (
    id INT AUTO_INCREMENT PRIMARY KEY,
    notice_text TEXT NOT NULL,
    posted_on DATE
);

CREATE TABLE hostels (
    id INT AUTO_INCREMENT PRIMARY KEY,
    name VARCHAR(150) NOT NULL UNIQUE,
    campus VARCHAR(50) NOT NULL,
    gender VARCHAR(10) NOT NULL,
    facilities TEXT,
    warden_name VARCHAR(100) DEFAULT NULL,
    contact_phone VARCHAR(20) DEFAULT NULL
);

CREATE TABLE placements (
    id INT AUTO_INCREMENT PRIMARY KEY,
    officer_name VARCHAR(100) NOT NULL,
    contact_phone VARCHAR(20),
    contact_email VARCHAR(100),
    description TEXT
);

CREATE TABLE admissions (
    id INT AUTO_INCREMENT PRIMARY KEY,
    contact_person VARCHAR(100) DEFAULT 'Admissions Office',
    contact_email VARCHAR(100),
    contact_phone VARCHAR(20),
    website_link VARCHAR(255)
);

CREATE TABLE fees (
    id INT AUTO_INCREMENT PRIMARY KEY,
    contact_person VARCHAR(100) DEFAULT 'Accounts Section',
    contact_email VARCHAR(100),
    contact_phone VARCHAR(20),
    payment_link VARCHAR(255)
);

CREATE TABLE transport (
    id INT AUTO_INCREMENT PRIMARY KEY,
    route_name VARCHAR(150) NOT NULL,
    description TEXT,
    contact_person VARCHAR(100) DEFAULT 'Transport Officer',
    contact_phone VARCHAR(20)
);

use campus_bot4;
CREATE TABLE scholarship_details(
	name varchar(50), 
    location varchar(50),
    mail_id varchar(50)
);


INSERT INTO scholarship_details (name, location, mail_id)
VALUES (
    'Scholarship Section',
    'Lab building, admissions section',
    'scholarshipnorthcampus@nie.ac.in'
);

-- 4. INSERT STATIC DATA
INSERT INTO dress_code (category, type, items) VALUES
('Boys', 'Allowed', 'Formal Pant, Jeans Pant, Shirt, T-Shirt, Kurtha'),
('Boys', 'Not Allowed', 'Low waist jeans, Torn Jeans, Cut Jeans, Faded Jeans, T-Shirt with slogans, Shorts, Sleeveless garments'),
('Girls', 'Allowed', 'Chudidhar, Jeans pant with long tops, Long Kurtha, Formal shirt'),
('Girls', 'Not Allowed', 'Low waist jeans, Torn Jeans, Cut Jeans, Faded Jeans, Shorts, Sleeveless garments, Transparent Tops, Capri, Tight fitting clothes, Skirts, Tube tops');

INSERT INTO clubs (name, description, contact_person, contact_phone) VALUES
('NISB', 'Dream of developing innovative software, managing vast databases, or leading IT projects? The Master of Computer Applications (MCA) is your path.', 'Club Coordinator', '9876500001'),
('ONYX', 'The fusion of mathematics & AI is transforming industries...', 'Club Coordinator', '9876500002'),
('Robotics', 'We encourage, motivate and equip the students in applications of robotics...', 'Club Coordinator', '9876500003'),
('AEROTantrix', 'At Aerotantrix, we are a group of students from the NIE who aim to provide a strong conceptual & practical platform for aeromodelling ventures in multidisciplinary engineering streams.', 'Club Coordinator', '9876500004'),
('AGNIE Racing', 'We design, simulate, fabricate go-karts and compete extensively in Go-kart design challenges and are intensively planning to take part in Formula Green national level competition.', 'Club Coordinator', '9876500005'),
('Credit Circle', 'The club aims to build a prominent acknowledgement of financial literacy amongst engineering students before they start their journey in financial independence.', 'Club Coordinator', '9876500006'),
('Force Ishvaku', 'We shape the future, from 5G to AI and space tech. We design the "brains" of devices, working in cutting-edge fields like semiconductors and robotics.', 'Club Coordinator', '9876500007'),
('GeeksforGeeks', 'We conduct events for all branches mainly on the computer science domain and other core technical competencies which is helpful for the students to access placements & professional development.', 'Club Coordinator', '9876500008'),
('ISSA', 'We PROVIDES EDUCATIONAL FORUMS, PUBLICATIONS, AND PEER INTERACTION OPPORTUNITIES THAT ENHANCE THE KNOWLEDGE, SKILL, AND PROFESSIONAL GROWTH OF ITS MEMBERS.', 'Club Coordinator', '9876500009'),
('Saenieks', 'Team SAENIEKS is a national level off road racing team. We design, simulate and fabricate the whole All-terrain vehicle and compete in various national level events.', 'Club Coordinator', '9876500010'),
('UCSP', 'The fusion of mathematics & AI is transforming industries, with techniques like linear algebra, calculus, & probability driving advances in machine learning, NLP, computer vision, and analytics.', 'Club Coordinator', '9876500011'),
('VLSI Club', 'A student community dedicated to acquire and develop skills in Very Large Scale Integration (VLSI) technology.', 'Club Coordinator', '9876500012');

INSERT INTO anti_ragging_squad (name, role, department, contact_phone) VALUES
('Dr. N V Archana', 'Chairperson', 'Anti ragging squad', '9900112233'),
('Sri. C N Nagesh Kumar', 'Member', 'Police Inspector, Lakshmipuram', '9900112234'),
('Dr. K M Subbaiah', 'Member', 'Professor, Industrial & Production Engg.', '9900112235');

INSERT INTO events (title, event_date, description) VALUES
('Club events', '2025-01-01', 'As organized by club Coordinators'),
('college Fest "TechNIEks"', '2025-05-01', 'Annual college fest-in the month of may');

INSERT INTO notices (notice_text, posted_on) VALUES
('Re-exam forms are available in the admin office.', '2025-09-01'),
('The library will be closed on weekends for maintenance.', '2025-08-28');

INSERT INTO departments (name, hod, contact_email) VALUES
('Computer Science & Engineering', 'Dr. Anitha R', 'ishod@nie.ac.in'),
('Information Science & Engineering', 'Dr. HP Girish', 'isedept@nie.ac.in'),
('Electronics & Communication', 'Dr. Anita r', 'hodcse@nie.ac.in');

INSERT INTO hostels (name, campus, gender, facilities, warden_name, contact_phone) VALUES
('NIE North Men\'s Hostel', 'North', 'Men', 'Wi-Fi enabled, Mess facility, Reading room, Recreation room with TV, Indoor games, Solar water heaters, 24/7 security.', 'Chief Warden - North Campus (Men)', '9876511111'),
('NIE North Women\'s Hostel', 'North', 'Women', 'Wi-Fi enabled, Mess facility, Reading room, Recreation room with TV, Indoor games, Solar water heaters, 24/7 security with female guards.', 'Chief Warden - North Campus (Women)', '9876522222'),
('NIE South Men\'s Hostel', 'South', 'Men', 'Wi-Fi connectivity, Mess facility, Common room with TV, Reading materials, Outdoor/Indoor sports facilities nearby, Hot water facility, Security.', 'Chief Warden - South Campus (Men)', '9876533333'),
('NIE South Women\'s Hostel', 'South', 'Women', 'Wi-Fi connectivity, Mess facility, Common room with TV, Reading materials, Hot water facility, 24/7 security.', 'Chief Warden - South Campus (Women)', '9876544444');

INSERT INTO placements (officer_name, contact_phone, contact_email, description)
VALUES ('Harshith Divakar', '8722266622', 'placement@nie.ac.in', 'The Training and Placement (T&P) department facilitates campus placements, internships, and provides career guidance and soft-skills training to students.');

INSERT INTO admissions (contact_email, contact_phone, website_link)
VALUES ('nie_admissions@infodesk.ac.in', '0821-2480475', 'https://www.nie.ac.in/admissions/');

INSERT INTO fees (contact_email, contact_phone, payment_link)
VALUES ('nie_accounts@feesdesk.ac.in', '0821-4004900', 'https.www.nie.ac.in/online-fee-payment');

INSERT INTO transport (route_name, description, contact_phone)
VALUES 
('NIE North Campus Routes', 'The college provides bus facilities from various prominent locations in Mysore city to the North Campus. Bus passes and route details are available at the admin office.', '9123456789'),
('North Campus to South Hostel Shuttle', 'A dedicated shuttle bus service is available for North Campus students residing in the NIE South Campus Hostels. The bus runs in the morning to the North Campus and returns to the South Campus in the evening after classes.', '9123456789');

-- 5. INSERT FACULTY DATA (Merged with Department and Location)
INSERT INTO faculty (id, name, email, department, office_location) VALUES
(1, 'Mrs Sandhya M K', 'sandhyamk@nie.ac.in', 'Mathematics', NULL),
(2, 'Dr. Chandra', 'sharath.chandra@nie.ac.in', 'Physics', NULL),
(3, 'Dr. Mahesh M', 'maheshm@nie.ac.in', 'Mechanical Engineering', NULL),
(4, 'Dr. Suresh Kumar S', 'sureshkumars@nie.ac.in', 'Mechanical Engineering', NULL),
(5, 'Prof. Deepak P', 'deepakp@nie.ac.in', 'Mechanical Engineering', NULL),
(6, 'Mr. Nitesh KA', 'niteshka@nie.ac.in', 'Electronics & Communication', NULL),
(7, 'Mrs Rashmi.M', 'rashmim@nie.ac.in', 'Computer Science & Engineering', NULL),
(8, 'Mr. Madhu MS', 'madhums@nie.ac.in', 'Humanities', NULL),
(9, 'Dr. BM Sankarshan', 'sankarshanbm@nie.ac.in', 'Physics', NULL),
(10, 'Dr. Prithvi C', 'prithvi.mech@nie.ac.in', 'Mechanical Engineering', NULL),
(11, 'Mrs. Ashwini D S', 'ashwinids@nie.ac.in', 'Electronics & Communication', NULL),
(12, 'Ms. Divyashree M.S', 'divyas@nie.ac.in', 'Computer Science & Engineering', NULL),
(13, 'Mr. Shishirranjan', 'sr@college.edu', 'Humanities', NULL),
(14, 'Dr Shivrajkumar', 'shivarajmacs@nie.ac.in', 'Mathematics', NULL),
(15, 'Dr. Vinaykumar D C', 'vinaykumardc@nie.ac.in', 'Physics', NULL),
(16, 'Prof. Nandini T S', 'nandinits.ip@nie.ac.in', 'Mechanical Engineering', NULL),
(17, 'Dr. Latha BM', 'lathabm@nie.ac.in', 'Mechanical Engineering', NULL),
(18, 'Mrs. Harshini C', 'harshinic@nie.ac.in', 'Computer Science & Engineering', NULL),
(19, 'Smt. Shraddha Marathe', 'shraddhamarathe@nie.ac.in', 'Physics', NULL),
(20, 'Prof. Srikanth NS', 'srikanthns43@nie.ac.in', 'Mechanical Engineering', NULL),
(21, 'Prof. Sanjaya Kumar V', 'sanjayakumarv@nie.ac.in', 'Mechanical Engineering', NULL),
(22, 'Mrs Amruthashree VM', 'amruthasreevm@nie.ac.in', 'Computer Science & Engineering', 'CSE Staff Room 1 - 1st Floor Lab Building'),
(23, 'Mr Srinivas S V', 'srinivasasv@nie.ac.in', 'Mathematics', NULL),
(24, 'Mr. Karthik V', 'karthikv@nie.ac.in', 'Physics', NULL),
(25, 'Dr. Sathisha H M', 'sathishahm@nie.ac.in', 'Mechanical Engineering', NULL),
(26, 'Dr. T Raghavendra', 'raghu@nie.ac.in', 'Mechanical Engineering', NULL),
(27, 'Mr. Janardhana Swamy G B', 'gbjanardhanaswamy@nie.ac.in', 'Computer Science & Engineering', 'CSE Staff Room 1 - 1st Floor Lab Building'),
(28, 'Dr. Vinuth M', 'vinuthm@nie.ac.in', 'Chemistry', NULL),
(29, 'Ms. Sushma MK', 'sushmamk@nie.ac.in', 'Computer Science & Engineering', NULL),
(30, 'Mrs. Chaithra M', 'chaithram@nie.ac.in', 'Computer Science & Engineering', 'CSE Staff Room 1 - 1st Floor Lab Building'),
(31, 'Mr. Santosh B K', 'santhoshbk@nie.ac.in', 'Humanities', NULL),
(32, 'Mr. Vinesh A', 'vinesha@nie.ac.in', 'Humanities', NULL),
(33, 'Mr Darshan NS', 'darshanns@nie.ac.in', 'Mathematics', NULL),
(34, 'Dr. Sayantan Halder', 'sayantanhalder@nie.ac.in', 'Chemistry', NULL),
(35, 'Mr Manoj S Sogi', 'manojnsogi@nie.ac.in', 'Computer Science & Engineering', NULL),
(36, 'Dr Suhas BN', 'suhasbn@nie.ac.in', 'Mathematics', NULL),
(37, 'Mrs. Zaiba Farheen', 'zaibafarheen@nie.ac.in', 'Computer Science & Engineering', NULL),
(38, 'Ms. Savitha S Sridharmurthy', 'savithasridharamurthy@nie.ac.in', 'Computer Science & Engineering', 'CSE Staff Room 1 - 1st Floor Lab Building'),
(39, 'Dr Bhuvan E Nalige', 'bhuvanenalige@nie.ac.in', 'Mathematics', NULL),
(40, 'Dr. G. S. Nanjundaswamy', 'nanjundaswamygs@nie.ac.in', 'Chemistry', NULL),
(41, 'Mr. Bharath G', 'bharathg@nie.ac.in', 'Computer Science & Engineering', NULL),
(42, 'Dr. Snigdharani Panda', 'snigdharani@nie.ac.in', 'Chemistry', NULL),
(43, 'Ms. Lavanya K B', 'lavanyakb@nie.ac.in', 'Computer Science & Engineering', NULL),
(44, 'Ms Krupa N', 'krupa@nie.ac.in', 'Mathematics', NULL),
(45, 'Mrs. Veena Mohan', 'veenamohanm@nie.ac.in', 'Computer Science & Engineering', 'CSE Staff Room 1 - 1st Floor Lab Building'),
(46, 'Mrs. Mahe Mubeen Akthar', 'mahemubeenakhtard@nie.ac.in', 'Computer Science & Engineering', 'CSE Staff Room 1 - 1st Floor Lab Building'),
(47, 'Dr. Narender M', 'narender@nie.ac.in', 'Computer Science & Engineering', 'CSE Staff Room 1 - 2nd Floor Lab Building'),
(48, 'Ms. Soujanya K V', 'soujanyakv@nie.ac.in', 'Computer Science & Engineering', 'CSE Staff Room 1 - 1st Floor Lab Building'),
(49, 'Mr. Gajendra L', 'gajendral@nie.ac.in', 'Computer Science & Engineering', NULL),
(50, 'Mrs. Padmavathi K', 'padmavatik@nie.ac.in', 'Computer Science & Engineering', 'CSE Staff Room 1 - 1st Floor Lab Building'),
(51, 'Mrs. Vidya NL', 'vidyanl@nie.ac.in', 'Computer Science & Engineering', 'CSE Staff Room 1 - 1st Floor Lab Building'),
(52, 'Dr. Naveen S Pagad', 'naveenspagad@nie.ac.in', 'Computer Science & Engineering', 'CSE Staff Room 1 - 1st Floor Lab Building'),
(53, 'Mr. Joyan Prajwal Alvares', 'joyanprajwalalvares@nie.ac.in', 'Computer Science & Engineering', NULL),
(54, 'Mr Darshan N S', 'darshans@nie.ac.in', 'Mathematics', NULL),
(55, 'Miss Sneha S', 'snehas@nie.ac.in', 'Computer Science & Engineering', NULL),
(56, 'Dr. Lokesh S', 'lokesh.sl29@nie.ac.in', 'Computer Science & Engineering', 'CSE Staff Room 1 - 2nd Floor Lab Building'),
(57, 'Dr. Shabana Sultana', 'shabana@nie.ac.in', 'Computer Science & Engineering', 'CSE Staff Room 1 - 2nd Floor Lab Building'),
(58, 'Mr. Sumanth CM', 'sumanthcm@nie.ac.in', 'Computer Science & Engineering', 'CSE Staff Room 1 - 1st Floor Lab Building'),
(59, 'Mrs. Priyanka R V', 'priyankarv@nie.ac.in', 'Computer Science & Engineering', 'CSE Staff Room 1 - 1st Floor Lab Building'),
(60, 'Mr. Mahesha A M', 'maheshaam@nie.ac.in', 'Computer Science & Engineering', 'CSE Staff Room 1 - 1st Floor Lab Building'),
(61, 'Dr SV Roopa', 'svrroopa@nie.ac.in', 'Mathematics', NULL),
(62, 'Mrs Lavanya.K.B', 'lavnyakb@nie.ac.in', 'Computer Science & Engineering', NULL),
(63, 'Mr N S Tejas', 'tejasns@nie.ac.in', 'Mathematics', NULL),
(64, 'Mrs. Smitha B', 'smithab@nie.ac.in', 'Computer Science & Engineering', 'CSE Staff Room 1 - 1st Floor Lab Building'),
(65, 'Dr. CK Vanamala', 'ckvanamala@nie.ac.in', 'Information Science & Engineering', 'Autonomous Cell'),
(66, 'Mr. CN Chinnaswamy', 'chinnaswamycn@nie.ac.in', 'Information Science & Engineering', 'Staff Room 1 - 1st Floor Lab Building'),
(67, 'Ms. Meghana NR', 'meghananr@nie.ac.in', 'Information Science & Engineering', 'Staff Room 2 - 3rd Floor Lab Building'),
(68, 'Ms. Prajakta M', 'prajakta@nie.ac.in', 'Information Science & Engineering', 'Staff Room 1 - 1st Floor Lab Building'),
(69, 'Dr. Bhat Geetalaxmi Jairam', 'bgj@nie.ac.in', 'Information Science & Engineering', 'CSE Staff Room - 2nd Floor Lab Building'),
(70, 'Mr. Rampur Srinath', 'rampursrinath@nie.ac.in', 'Information Science & Engineering', 'Staff Room 1 - 1st Floor Lab Building'),
(71, 'Ms. Supriya S', 'supriyashivaswamy@nie.ac.in', 'Information Science & Engineering', NULL),
(72, 'Dr. Sanjith S Anchan', 'sanjithsanchan@nie.ac.in', 'Civil Engineering', NULL),
(73, 'Ms. Spoorthy BN', 'spoorthibn@nie.ac.in', 'Information Science & Engineering', NULL),
(74, 'Dr. BM Nandini', 'nandinibm@nie.ac.in', 'Information Science & Engineering', 'Staff Room 2 - 3rd Floor Lab Building'),
(75, 'Dr. Rajeshwari D', 'drrajeshwari@nie.ac.in', 'Information Science & Engineering', 'Staff Room 2 - 3rd Floor Lab Building'),
(76, 'Dr. Shashank D', 'shashank@nie.ac.in', 'Information Science & Engineering', 'Staff Room 2 - 3rd Floor Lab Building'),
(77, 'Ms. Sandhya N', 'sandhyan@nie.ac.in', 'Information Science & Engineering', NULL),
(78, 'Dr. U Anil', 'unnamanil@nie.ac.in', 'Civil Engineering', NULL),
(79, 'Dr. K Raghuveer', 'ragh@nie.ac.in', 'Information Science & Engineering', 'Staff Room 1 - 1st Floor Lab Building'),
(80, 'Ms. Padma MT', 'padmamt@nie.ac.in', 'Information Science & Engineering', 'Staff Room 2 - 3rd Floor Lab Building'),
(81, 'Dr. S Kuzhalvaimozhi', 'kuzhali_mozhi@nie.ac.in', 'Professor and Controller Of Examination', NULL),
(82, 'Ms. Prathibha B S', 'prathibha@nie.ac.in', 'Information Science & Engineering', 'Staff Room 1 - 1st Floor Lab Building'),
(83, 'Mr. Suhas B R', 'suhasbharadwajr@nie.ac.in', 'Information Science & Engineering', NULL),
(84, 'Dr. P Devaki', 'devaki@nie.ac.in', 'Information Science & Engineering', 'Staff Room 1 - 1st Floor Lab Building'),
(85, 'Dr. Suhaas KP', 'suhaaskp@nie.ac.in', 'Information Science & Engineering', 'Autonomous Cell'),
(86, 'Ms. Bhavani R', 'bhavanir@nie.ac.in', 'Information Science & Engineering', NULL),
(87, 'Ms. Lammiya Huda', 'lammiyahuda@nie.ac.in', 'Information Science & Engineering', NULL),
(88, 'Dr. HP Girish', 'hpgirish@nie.ac.in', 'Information Science & Engineering', NULL),
(89, 'Mr. N Rajesh', 'nrajesh@nie.ac.in', 'Information Science & Engineering', NULL),
(90, 'Ms. ShalParni PY', 'shalparnipy@nie.ac.in', 'Information Science & Engineering', NULL),
(91, 'Mrs.Poornima .N', 'poorniman@nie.ac.in', 'Computer Science & Engineering', NULL),
(92, 'Mr. Nishanth R', 'nishanthr@nie.ac.in', 'Computer Science & Engineering', NULL),
(93, 'Mr. Gowtham R Naik', 'gowthamr@nie.ac.in', 'Computer Science & Engineering', 'CSE Staff Room 1 - 1st Floor Lab Building'),
(94, 'Mrs.Padmini.M.S', 'padminims@nie.ac.in', 'Computer Science & Engineering', 'CSE Staff Room 1 - 1st Floor Lab Building'),
(95, 'Ms.Sumana.K.M', 'sumanakm@nie.ac.in', 'Computer Science & Engineering', 'CSE Staff Room 1 - 1st Floor Lab Building'),
(96, 'Ms.Bhagyashree Katti', 'bhagyashreekatti@nie.ac.in', 'Computer Science & Engineering', NULL),
(97, 'Mr. Shashank T', 'shashankt@nie.ac.in', 'Civil Engineering', NULL),
(98, 'Dr. C Vidya Raj', 'cvr@nie.ac.in', 'Computer Science & Engineering', 'CSE Staff Room 1 - 2nd Floor Lab Building'),
(99, 'Mrs Usha K patil', 'ushakp@nie.ac.in', 'Computer Science & Engineering', 'CSE Staff Room 1 - 1st Floor Lab Building'),
(100, 'Dr. Rashmi.M. R', 'rashmimr@nie.ac.in', 'Computer Science & Engineering', 'CSE Staff Room 1 - 2nd Floor Lab Building'),
(101, 'Ms. Harshitha HS', 'harshithahs@nie.ac.in', 'Computer Science & Engineering', NULL),
(102, 'Dr. Usha M S', 'ushams@nie.ac.in', 'Computer Science & Engineering', NULL),
(103, 'Ms. Bhuvana S', 'bhuvanas@nie.ac.in', 'Computer Science & Engineering', NULL),
(104, 'Mr. Mohamad Adnan', 'madnan@nie.ac.in', 'Computer Science & Engineering', NULL),
(105, 'Dr. Aruna R', 'aruna.r@nie.ac.in', 'CSE', 'Cse staff room 2 - 2nd floor lab building'),
(106, 'Dr. V K Annapurna', 'annapurnavk@nie.ac.in', 'Computer Science & Engineering', 'CSE Staff Room 1 - 2nd Floor Lab Building'),
(107, 'Ms. Divyashree R', 'divyashreer@nie.ac.in', 'Computer Science & Engineering', 'CSE Staff Room 1 - 1st Floor Lab Building'),
(108, 'Dr. Vinod S', 'vinods.prof@nie.ac.in', 'ECE', 'ECE Staff Room 2'),
(109, 'Mrs. Lakshmi Devi', 'lakshmi.d@nie.ac.in', 'CSE', 'Cse- staff room, 2nd floor lab'),
(110, 'Mr. Chethan M', 'chethan.m@nie.ac.in', 'Information Science & Engineering', 'ISE Lab Annex'),
(111, 'Dr. Ayesha Begum', 'ayesha.b@nie.ac.in', 'CSE', 'Staff room 1- 1st floor lab building. Cse'),
(112, 'Mrs. Shilpashree', 'shilpashrees@nie.ac.in', 'Computer Science & Engineering', NULL),
(113, 'Dr. BRV', 'brvishwanath@nie.ac.in', 'Computer Science & Engineering', NULL),
(114, 'Dr. Jayasri B S', 'jayasribs@nie.ac.in', 'Computer Science & Engineering', 'CSE Staff Room 1 - 2nd Floor Lab Building'),
(115, 'Dr. S. K. Singh', 'sksingh@nie.ac.in', 'CSE', 'Cse staff room 1 - 2nd floor lab building'),
(116, 'Dr. Anitha Raghavendra', 'anitharaghavendra@nie.ac.in', 'Computer Science & Engineering', NULL),
(117, 'Mr. Balaji V', 'balajiv@nie.ac.in', 'Computer Science & Engineering', 'CSE Staff Room 1 - 1st Floor Lab Building'),
(118, 'Mrs.Nithya M R', 'nithyamr@nie.ac.in', 'Computer Science & Engineering', 'CSE Staff Room 1 - 1st Floor Lab Building');

-- 6. INSERT COURSES DATA (Cleaned and Merged)
INSERT INTO courses (course_code, course_name, department) VALUES
('1BMACS101', 'Applied Mathematics - I for CSE Stream', 'Mathematics'),
('1BPHCS102', 'Applied Physics for CSE Stream', 'Physics'),
('1BCEDCS103', 'Computer-Aided Engineering Drawing for CSE stream', 'CSE'),
('1BESC104C', 'Introduction to Electronics & Communication Engineering', 'ECE'),
('1BEIT105', 'Programming in C', 'CSE'),
('1BPOPL107', 'C Programming Lab', 'CSE'),
('1BPHCSL102', 'Applied Physics Laboratory for CSE Stream', 'Physics'),
('1BKSK109', 'Samskrutika Kannada', 'Humanities'),
('1BKBK109', 'Balake Kannada', 'Humanities'),
('1BPRJ158', 'Interdisciplinary Project Based Learning', 'General'),
('1BCHCS102', 'Applied Chemistry for CSE Stream', 'Chemistry'),
('1BAIA103', 'Introduction to AI and Applications', 'CSE'),
('1BESC104D', 'Introduction to Mechanical Engineering', 'Mechanical'),
('1BENGL106', 'Communication Skills', 'Humanities'),
('1BCHCSL102', 'Applied Chemistry Lab for CSE Stream', 'Chemistry'),
('1BIDTL158', 'Innovation and Design Thinking Lab', 'General'),
('1BICO107', 'Indian Constitution & Engineering Ethics', 'Humanities'),
('BCS301', 'Mathematics for Computer Science', 'Mathematics'),
('BCS302', 'Digital Design & Computer Organization', 'CSE'),
('BCS303', 'Operating Systems', 'CSE'),
('BCS304', 'Data Structures and Applications', 'CSE'),
('BCSL305', 'Data Structures Laboratory', 'CSE'),
('BCS306A', 'ESC Object Oriented Programming with Java', 'CSE'),
('BSCK307', 'Social Connect and Responsibility', 'Humanities'),
('BCS358D', 'AEC Data visualization with Python', 'CSE'),
('BNSK359', 'National Service Scheme (NSS)', 'General'),
('BPEK359', 'Physical Education (PE) (Sports & Athletics)', 'General'),
('BYOK359', 'Yoga', 'General'),
('BIS501', 'Software Engineering & Project Management', 'ISE'),
('BIS502', 'Computer Networks', 'ISE'),
('BIS503', 'Theory of Computation', 'ISE'),
('BIS505', 'Cloud Computing', 'ISE'),
('BIS516B', 'Artificial Intelligence', 'ISE'),
('BIS516C', 'Distributed Systems', 'ISE'),
('BIS516D', 'Unix System Programming', 'ISE'),
('BRMIS557', 'Research Methodology and IPR', 'ISE'),
('BISL504', 'Data Visualization Lab', 'ISE'),
('BIS586', 'Minor Project', 'ISE'),
('BESK508', 'Environmental Studies', 'General'),
('BNSK559', 'National Service Scheme (NSS)', 'General'),
('BPEK559', 'Physical Education (PE)', 'General'),
('BYOK559', 'Yoga', 'General'),
('BCS501', 'Software Engineering & Project Management', 'CSE'),
('BCS502', 'Computer Networks', 'CSE'),
('BCS503', 'Automata Theory and Computation', 'CSE'),
('BCSL504', 'Full Stack Development Lab', 'CSE'),
('BCS505', 'Full Stack Development', 'CSE'),
('BCS516B', 'Artificial Intelligence', 'CSE'),
('BCS586', 'Minor Project', 'CSE'),
('BRMCS557', 'Research Methodology and IPR', 'CSE'),
('BCI516B', 'Information Retrieval', 'CSE'),
('BCI586', 'Minor Project', 'CSE'),
('BCS701', 'Cryptography & Network Security', 'CSE'),
('BCS702', 'Parallel Computing', 'CSE'),
('BCS713X', 'Professional Elective Course (Group III)', 'CSE'),
('BCS713A', 'Deep Learning', 'CSE'),
('BCS713C', 'NoSQL', 'CSE'),
('BCI713D', 'Big Data Analytics', 'CSE'),
('BCS754X', 'Open Elective Course (Group II)', 'General'),
('BCS785', 'Major Project', 'CSE'),
('BCS786', 'Major Project', 'CSE'),
('BCI701', 'Natural Language Processing', 'CSE'),
('BCI702', 'Machine Learning - II', 'CSE'),
('BCI713X', 'Professional Elective Course (AI&ML)', 'CSE'),
('BCI785', 'Major Project', 'CSE');

-- 7. INSERT CLASSES DATA (All 27 Sections)
INSERT INTO classes (class_id, course_code, faculty_id, study_year, branch, section, class_type, lab_batch) VALUES
(1, '1BMACS101', 1, 1, 'CSE', 'A', 'Lecture', NULL), (2, '1BPHCS102', 2, 1, 'CSE', 'A', 'Lecture', NULL), (3, '1BCEDCS103', 3, 1, 'CSE', 'A', 'Lab', NULL), (4, '1BESC104C', 6, 1, 'CSE', 'A', 'Lecture', NULL), (5, '1BEIT105', 7, 1, 'CSE', 'A', 'Lecture', NULL), (6, '1BPOPL107', 7, 1, 'CSE', 'A', 'Lab', 'A1'), (7, '1BPOPL107', 7, 1, 'CSE', 'A', 'Lab', 'A2'), (8, '1BPHCSL102', 2, 1, 'CSE', 'A', 'Lab', 'A1'), (9, '1BPHCSL102', 2, 1, 'CSE', 'A', 'Lab', 'A2'), (10, '1BKSK109', 8, 1, 'CSE', 'A', 'Lecture', NULL), (11, '1BKBK109', 8, 1, 'CSE', 'A', 'Lecture', NULL), (12, '1BPRJ158', NULL, 1, 'CSE', 'A', 'Lab', NULL),
(13, '1BMACS101', 1, 1, 'CSE', 'B', 'Lecture', NULL), (14, '1BPHCS102', 9, 1, 'CSE', 'B', 'Lecture', NULL), (15, '1BCEDCS103', 10, 1, 'CSE', 'B', 'Lab', NULL), (16, '1BESC104C', 11, 1, 'CSE', 'B', 'Lecture', NULL), (17, '1BEIT105', 12, 1, 'CSE', 'B', 'Lecture', NULL), (18, '1BPOPL107', 12, 1, 'CSE', 'B', 'Lab', 'B1'), (19, '1BPOPL107', 12, 1, 'CSE', 'B', 'Lab', 'B2'), (20, '1BPHCSL102', 9, 1, 'CSE', 'B', 'Lab', 'B1'), (21, '1BPHCSL102', 9, 1, 'CSE', 'B', 'Lab', 'B2'), (22, '1BKSK109', 13, 1, 'CSE', 'B', 'Lecture', NULL), (23, '1BKBK109', 13, 1, 'CSE', 'B', 'Lecture', NULL), (24, '1BPRJ158', NULL, 1, 'CSE', 'B', 'Lab', NULL),
(25, '1BMACS101', 14, 1, 'CSE', 'C', 'Lecture', NULL), (26, '1BPHCS102', 15, 1, 'CSE', 'C', 'Lecture', NULL), (27, '1BCEDCS103', 10, 1, 'CSE', 'C', 'Lab', NULL), (28, '1BESC104C', 11, 1, 'CSE', 'C', 'Lecture', NULL), (29, '1BEIT105', 18, 1, 'CSE', 'C', 'Lecture', NULL), (30, '1BPOPL107', 18, 1, 'CSE', 'C', 'Lab', 'C1'), (31, '1BPOPL107', 18, 1, 'CSE', 'C', 'Lab', 'C2'), (32, '1BPHCSL102', 15, 1, 'CSE', 'C', 'Lab', 'C1'), (33, '1BPHCSL102', 15, 1, 'CSE', 'C', 'Lab', 'C2'), (34, '1BKSK109', 8, 1, 'CSE', 'C', 'Lecture', NULL), (35, '1BKBK109', 8, 1, 'CSE', 'C', 'Lecture', NULL), (36, '1BPRJ158', NULL, 1, 'CSE', 'C', 'Lab', NULL),
(37, '1BMACS101', 1, 1, 'CSE', 'D', 'Lecture', NULL), (38, '1BPHCS102', 19, 1, 'CSE', 'D', 'Lecture', NULL), (39, '1BCEDCS103', 20, 1, 'CSE', 'D', 'Lab', NULL), (40, '1BESC104C', 6, 1, 'CSE', 'D', 'Lecture', NULL), (41, '1BEIT105', 22, 1, 'CSE', 'D', 'Lecture', NULL), (42, '1BPOPL107', 22, 1, 'CSE', 'D', 'Lab', 'D1'), (43, '1BPOPL107', 22, 1, 'CSE', 'D', 'Lab', 'D2'), (44, '1BPHCSL102', 19, 1, 'CSE', 'D', 'Lab', 'D1'), (45, '1BPHCSL102', 19, 1, 'CSE', 'D', 'Lab', 'D2'), (46, '1BKSK109', 8, 1, 'CSE', 'D', 'Lecture', NULL), (47, '1BKBK109', 8, 1, 'CSE', 'D', 'Lecture', NULL), (48, '1BPRJ158', NULL, 1, 'CSE', 'D', 'Lab', NULL),
(49, '1BMACS101', 23, 1, 'CSE', 'E', 'Lecture', NULL), (50, '1BPHCS102', 24, 1, 'CSE', 'E', 'Lecture', NULL), (51, '1BCEDCS103', 25, 1, 'CSE', 'E', 'Lab', NULL), (52, '1BESC104C', 11, 1, 'CSE', 'E', 'Lecture', NULL), (53, '1BEIT105', 27, 1, 'CSE', 'E', 'Lecture', NULL), (54, '1BPOPL107', 27, 1, 'CSE', 'E', 'Lab', 'E1'), (55, '1BPOPL107', 27, 1, 'CSE', 'E', 'Lab', 'E2'), (56, '1BPHCSL102', 24, 1, 'CSE', 'E', 'Lab', 'E1'), (57, '1BPHCSL102', 24, 1, 'CSE', 'E', 'Lab', 'E2'), (58, '1BKSK109', 8, 1, 'CSE', 'E', 'Lecture', NULL), (59, '1BKBK109', 8, 1, 'CSE', 'E', 'Lecture', NULL), (60, '1BPRJ158', NULL, 1, 'CSE', 'E', 'Lab', NULL),
(61, '1BMACS101', 23, 1, 'CSE', 'F', 'Lecture', NULL), (62, '1BCHCS102', 28, 1, 'CSE', 'F', 'Lecture', NULL), (63, '1BAIA103', 29, 1, 'CSE', 'F', 'Lecture', NULL), (64, '1BESC104D', 10, 1, 'CSE', 'F', 'Lecture', NULL), (65, '1BEIT105', 30, 1, 'CSE', 'F', 'Lecture', NULL), (66, '1BENGL106', 31, 1, 'CSE', 'F', 'Lecture', NULL), (67, '1BPOPL107', 30, 1, 'CSE', 'F', 'Lab', 'F1'), (68, '1BPOPL107', 30, 1, 'CSE', 'F', 'Lab', 'F2'), (69, '1BCHCSL102', 28, 1, 'CSE', 'F', 'Lab', 'F1'), (70, '1BCHCSL102', 28, 1, 'CSE', 'F', 'Lab', 'F2'), (71, '1BIDTL158', 5, 1, 'CSE', 'F', 'Lab', NULL), (72, '1BICO107', 32, 1, 'CSE', 'F', 'Lecture', NULL),
(73, '1BMACS101', 33, 1, 'CSE', 'G', 'Lecture', NULL), (74, '1BCHCS102', 34, 1, 'CSE', 'G', 'Lecture', NULL), (75, '1BAIA103', 18, 1, 'CSE', 'G', 'Lecture', NULL), (76, '1BESC104D', 3, 1, 'CSE', 'G', 'Lecture', NULL), (77, '1BEIT105', 35, 1, 'CSE', 'G', 'Lecture', NULL), (78, '1BENGL106', 31, 1, 'CSE', 'G', 'Lecture', NULL), (79, '1BPOPL107', 35, 1, 'CSE', 'G', 'Lab', 'G1'), (80, '1BPOPL107', 35, 1, 'CSE', 'G', 'Lab', 'G2'), (81, '1BCHCSL102', 34, 1, 'CSE', 'G', 'Lab', 'G1'), (82, '1BCHCSL102', 34, 1, 'CSE', 'G', 'Lab', 'G2'), (83, '1BIDTL158', 3, 1, 'CSE', 'G', 'Lab', NULL), (84, '1BICO107', 32, 1, 'CSE', 'G', 'Lecture', NULL),
(85, '1BMACS101', 36, 1, 'CSE', 'H', 'Lecture', NULL), (86, '1BCHCS102', 28, 1, 'CSE', 'H', 'Lecture', NULL), (87, '1BAIA103', 37, 1, 'CSE', 'H', 'Lecture', NULL), (88, '1BESC104D', 4, 1, 'CSE', 'H', 'Lecture', NULL), (89, '1BEIT105', 38, 1, 'CSE', 'H', 'Lecture', NULL), (90, '1BENGL106', 31, 1, 'CSE', 'H', 'Lecture', NULL), (91, '1BPOPL107', 38, 1, 'CSE', 'H', 'Lab', 'H1'), (92, '1BPOPL107', 38, 1, 'CSE', 'H', 'Lab', 'H2'), (93, '1BCHCSL102', 28, 1, 'CSE', 'H', 'Lab', 'H1'), (94, '1BCHCSL102', 28, 1, 'CSE', 'H', 'Lab', 'H2'), (95, '1BIDTL158', 17, 1, 'CSE', 'H', 'Lab', NULL), (96, '1BICO107', 32, 1, 'CSE', 'H', 'Lecture', NULL),
(97, '1BMACS101', 39, 1, 'AI&ML', 'A', 'Lecture', NULL), (98, '1BCHCS102', 40, 1, 'AI&ML', 'A', 'Lecture', NULL), (99, '1BAIA103', 41, 1, 'AI&ML', 'A', 'Lecture', NULL), (100, '1BESC104D', 5, 1, 'AI&ML', 'A', 'Lecture', NULL), (101, '1BEIT105', 30, 1, 'AI&ML', 'A', 'Lecture', NULL), (102, '1BENGL106', 31, 1, 'AI&ML', 'A', 'Lecture', NULL), (103, '1BPOPL107', 30, 1, 'AI&ML', 'A', 'Lab', 'A1'), (104, '1BPOPL107', 30, 1, 'AI&ML', 'A', 'Lab', 'A2'), (105, '1BCHCSL102', 40, 1, 'AI&ML', 'A', 'Lab', 'A1'), (106, '1BCHCSL102', 40, 1, 'AI&ML', 'A', 'Lab', 'A2'), (107, '1BIDTL158', 3, 1, 'AI&ML', 'A', 'Lab', NULL), (108, '1BICO107', 32, 1, 'AI&ML', 'A', 'Lecture', NULL),
(109, '1BMACS101', 23, 1, 'AI&ML', 'B', 'Lecture', NULL), (110, '1BCHCS102', 42, 1, 'AI&ML', 'B', 'Lecture', NULL), (111, '1BAIA103', 43, 1, 'AI&ML', 'B', 'Lecture', NULL), (112, '1BESC104D', 21, 1, 'AI&ML', 'B', 'Lecture', NULL), (113, '1BEIT105', 7, 1, 'AI&ML', 'B', 'Lecture', NULL), (114, '1BENGL106', 31, 1, 'AI&ML', 'B', 'Lecture', NULL), (115, '1BPOPL107', 7, 1, 'AI&ML', 'B', 'Lab', 'B1'), (116, '1BPOPL107', 7, 1, 'AI&ML', 'B', 'Lab', 'B2'), (117, '1BCHCSL102', 42, 1, 'AI&ML', 'B', 'Lab', 'B1'), (118, '1BCHCSL102', 42, 1, 'AI&ML', 'B', 'Lab', 'B2'), (119, '1BIDTL158', 4, 1, 'AI&ML', 'B', 'Lab', NULL), (120, '1BICO107', 32, 1, 'AI&ML', 'B', 'Lecture', NULL),
(121, 'BCS301', 44, 2, 'CSE', 'A', 'Lecture', NULL), (122, 'BCS302', 45, 2, 'CSE', 'A', 'Lecture', NULL), (123, 'BCS302', 45, 2, 'CSE', 'A', 'Lab', 'A1'), (124, 'BCS302', 45, 2, 'CSE', 'A', 'Lab', 'A2'), (125, 'BCS302', 45, 2, 'CSE', 'A', 'Lab', 'A3'), (126, 'BCS303', 46, 2, 'CSE', 'A', 'Lecture', NULL), (127, 'BCS303', 46, 2, 'CSE', 'A', 'Lab', 'A1'), (128, 'BCS303', 46, 2, 'CSE', 'A', 'Lab', 'A2'), (129, 'BCS303', 46, 2, 'CSE', 'A', 'Lab', 'A3'), (130, 'BCS304', 47, 2, 'CSE', 'A', 'Lecture', NULL), (131, 'BCSL305', NULL, 2, 'CSE', 'A', 'Lab', 'A1'), (132, 'BCSL305', NULL, 2, 'CSE', 'A', 'Lab', 'A2'), (133, 'BCSL305', 47, 2, 'CSE', 'A', 'Lab', 'A3'), (134, 'BCS306A', 48, 2, 'CSE', 'A', 'Lecture', NULL), (135, 'BCS306A', 48, 2, 'CSE', 'A', 'Lab', 'A1'), (136, 'BCS306A', 48, 2, 'CSE', 'A', 'Lab', 'A2'), (137, 'BCS306A', 48, 2, 'CSE', 'A', 'Lab', 'A3'), (138, 'BSCK307', NULL, 2, 'CSE', 'A', 'Lecture', NULL), (139, 'BCS358D', 49, 2, 'CSE', 'A', 'Lecture', NULL), (140, 'BNSK359', NULL, 2, 'CSE', 'A', 'Lab', NULL), (141, 'BPEK359', NULL, 2, 'CSE', 'A', 'Lab', NULL), (142, 'BYOK359', NULL, 2, 'CSE', 'A', 'Lab', NULL),
(143, 'BCS301', 63, 2, 'CSE', 'B', 'Lecture', NULL), (144, 'BCS302', 50, 2, 'CSE', 'B', 'Lecture', NULL), (145, 'BCS302', 50, 2, 'CSE', 'B', 'Lab', 'B1'), (146, 'BCS302', 50, 2, 'CSE', 'B', 'Lab', 'B2'), (147, 'BCS302', 50, 2, 'CSE', 'B', 'Lab', 'B3'), (148, 'BCS303', 51, 2, 'CSE', 'B', 'Lecture', NULL), (149, 'BCS303', 51, 2, 'CSE', 'B', 'Lab', 'B1'), (150, 'BCS303', 51, 2, 'CSE', 'B', 'Lab', 'B2'), (151, 'BCS303', 51, 2, 'CSE', 'B', 'Lab', 'B3'), (152, 'BCS304', 52, 2, 'CSE', 'B', 'Lecture', NULL), (153, 'BCSL305', NULL, 2, 'CSE', 'B', 'Lab', 'B1'), (154, 'BCSL305', 52, 2, 'CSE', 'B', 'Lab', 'B2'), (155, 'BCSL305', 52, 2, 'CSE', 'B', 'Lab', 'B3'), (156, 'BCS306A', 49, 2, 'CSE', 'B', 'Lecture', NULL), (157, 'BCS306A', 49, 2, 'CSE', 'B', 'Lab', 'B1'), (158, 'BCS306A', 49, 2, 'CSE', 'B', 'Lab', 'B2'), (159, 'BCS306A', 49, 2, 'CSE', 'B', 'Lab', 'B3'), (160, 'BSCK307', NULL, 2, 'CSE', 'B', 'Lecture', NULL), (161, 'BCS358D', 53, 2, 'CSE', 'B', 'Lecture', NULL),
(162, 'BCS301', 54, 2, 'CSE', 'C', 'Lecture', NULL), (163, 'BCS302', 50, 2, 'CSE', 'C', 'Lecture', NULL), (164, 'BCS302', 50, 2, 'CSE', 'C', 'Lab', 'C1'), (165, 'BCS302', 50, 2, 'CSE', 'C', 'Lab', 'C2'), (166, 'BCS302', 50, 2, 'CSE', 'C', 'Lab', 'C3'), (167, 'BCS303', 46, 2, 'CSE', 'C', 'Lecture', NULL), (168, 'BCS303', 46, 2, 'CSE', 'C', 'Lab', 'C1'), (169, 'BCS303', 46, 2, 'CSE', 'C', 'Lab', 'C2'), (170, 'BCS303', 46, 2, 'CSE', 'C', 'Lab', 'C3'), (171, 'BCS304', 22, 2, 'CSE', 'C', 'Lecture', NULL), (172, 'BCSL305', 22, 2, 'CSE', 'C', 'Lab', 'C1'), (173, 'BCSL305', 22, 2, 'CSE', 'C', 'Lab', 'C2'), (174, 'BCSL305', 22, 2, 'CSE', 'C', 'Lab', 'C3'), (175, 'BCS306A', 48, 2, 'CSE', 'C', 'Lecture', NULL), (176, 'BCS306A', 48, 2, 'CSE', 'C', 'Lab', 'C1'), (177, 'BCS306A', 48, 2, 'CSE', 'C', 'Lab', 'C2'), (178, 'BCS306A', 48, 2, 'CSE', 'C', 'Lab', 'C3'), (179, 'BSCK307', NULL, 2, 'CSE', 'C', 'Lecture', NULL), (180, 'BCS358D', 55, 2, 'CSE', 'C', 'Lecture', NULL),
(181, 'BCS301', 36, 2, 'CSE', 'D', 'Lecture', NULL), (182, 'BCS302', 56, 2, 'CSE', 'D', 'Lecture', NULL), (183, 'BCS302', 56, 2, 'CSE', 'D', 'Lab', 'D1'), (184, 'BCS302', 56, 2, 'CSE', 'D', 'Lab', 'D2'), (185, 'BCS302', 56, 2, 'CSE', 'D', 'Lab', 'D3'), (186, 'BCS303', 57, 2, 'CSE', 'D', 'Lecture', NULL), (187, 'BCS303', 57, 2, 'CSE', 'D', 'Lab', 'D1'), (188, 'BCS303', 57, 2, 'CSE', 'D', 'Lab', 'D2'), (189, 'BCS303', 57, 2, 'CSE', 'D', 'Lab', 'D3'), (190, 'BCS304', 58, 2, 'CSE', 'D', 'Lecture', NULL), (191, 'BCSL305', 58, 2, 'CSE', 'D', 'Lab', 'D1'), (192, 'BCSL305', 58, 2, 'CSE', 'D', 'Lab', 'D2'), (193, 'BCSL305', 58, 2, 'CSE', 'D', 'Lab', 'D3'), (194, 'BCS306A', 59, 2, 'CSE', 'D', 'Lecture', NULL), (195, 'BCS306A', 59, 2, 'CSE', 'D', 'Lab', 'D1'), (196, 'BCS306A', 59, 2, 'CSE', 'D', 'Lab', 'D2'), (197, 'BCS306A', 59, 2, 'CSE', 'D', 'Lab', 'D3'), (198, 'BSCK307', NULL, 2, 'CSE', 'D', 'Lecture', NULL), (199, 'BCS358D', 60, 2, 'CSE', 'D', 'Lecture', NULL),
(200, 'BCS301', 61, 2, 'AI&ML', 'E', 'Lecture', NULL), (201, 'BCS302', 45, 2, 'AI&ML', 'E', 'Lecture', NULL), (202, 'BCS302', 45, 2, 'AI&ML', 'E', 'Lab', 'E1'), (203, 'BCS302', 45, 2, 'AI&ML', 'E', 'Lab', 'E2'), (204, 'BCS302', 45, 2, 'AI&ML', 'E', 'Lab', 'E3'), (205, 'BCS303', 51, 2, 'AI&ML', 'E', 'Lecture', NULL), (206, 'BCS303', 51, 2, 'AI&ML', 'E', 'Lab', 'E1'), (207, 'BCS303', 51, 2, 'AI&ML', 'E', 'Lab', 'E2'), (208, 'BCS303', 51, 2, 'AI&ML', 'E', 'Lab', 'E3'), (209, 'BCS304', 47, 2, 'AI&ML', 'E', 'Lecture', NULL), (210, 'BCSL305', NULL, 2, 'AI&ML', 'E', 'Lab', 'E1'), (211, 'BCSL305', 22, 2, 'AI&ML', 'E', 'Lab', 'E2'), (212, 'BCSL305', 47, 2, 'AI&ML', 'E', 'Lab', 'E3'), (213, 'BCS306A', 29, 2, 'AI&ML', 'E', 'Lecture', NULL), (214, 'BCS306A', 29, 2, 'AI&ML', 'E', 'Lab', 'E1'), (215, 'BCS306A', 29, 2, 'AI&ML', 'E', 'Lab', 'E2'), (216, 'BCS306A', NULL, 2, 'AI&ML', 'E', 'Lab', 'E3'), (217, 'BSCK307', 62, 2, 'AI&ML', 'E', 'Lecture', NULL), (218, 'BCS358D', 62, 2, 'AI&ML', 'E', 'Lecture', NULL),
(219, 'BCS301', 63, 2, 'AI&ML', 'F', 'Lecture', NULL), (220, 'BCS302', 56, 2, 'AI&ML', 'F', 'Lecture', NULL), (221, 'BCS302', 56, 2, 'AI&ML', 'F', 'Lab', 'F1'), (222, 'BCS302', 56, 2, 'AI&ML', 'F', 'Lab', 'F2'), (223, 'BCS302', 56, 2, 'AI&ML', 'F', 'Lab', 'F3'), (224, 'BCS303', 57, 2, 'AI&ML', 'F', 'Lecture', NULL), (225, 'BCS303', 57, 2, 'AI&ML', 'F', 'Lab', 'F1'), (226, 'BCS303', 57, 2, 'AI&ML', 'F', 'Lab', 'F2'), (227, 'BCS303', 57, 2, 'AI&ML', 'F', 'Lab', 'F3'), (228, 'BCS304', 64, 2, 'AI&ML', 'F', 'Lecture', NULL), (229, 'BCSL305', 64, 2, 'AI&ML', 'F', 'Lab', 'F1'), (230, 'BCSL305', 64, 2, 'AI&ML', 'F', 'Lab', 'F2'), (231, 'BCSL305', NULL, 2, 'AI&ML', 'F', 'Lab', 'F3'), (232, 'BCS306A', 59, 2, 'AI&ML', 'F', 'Lecture', NULL), (233, 'BCS306A', 59, 2, 'AI&ML', 'F', 'Lab', 'F1'), (234, 'BCS306A', 59, 2, 'AI&ML', 'F', 'Lab', 'F2'), (235, 'BCS306A', 30, 2, 'AI&ML', 'F', 'Lab', 'F3'), (236, 'BSCK307', NULL, 2, 'AI&ML', 'F', 'Lecture', NULL), (237, 'BCS358D', 60, 2, 'AI&ML', 'F', 'Lecture', NULL),
(238, 'BCS301', 87, 2, 'ISE', 'A', 'Lecture', NULL), (239, 'BCS302', 82, 2, 'ISE', 'A', 'Lecture', NULL), (240, 'BCS302', 82, 2, 'ISE', 'A', 'Lab', 'A1'), (241, 'BCS302', 82, 2, 'ISE', 'A', 'Lab', 'A2'), (242, 'BCS302', 82, 2, 'ISE', 'A', 'Lab', 'A3'), (243, 'BCS303', 83, 2, 'ISE', 'A', 'Lecture', NULL), (244, 'BCS303', 83, 2, 'ISE', 'A', 'Lab', 'A1'), (245, 'BCS303', 83, 2, 'ISE', 'A', 'Lab', 'A2'), (246, 'BCS303', 83, 2, 'ISE', 'A', 'Lab', 'A3'), (247, 'BCS304', 84, 2, 'ISE', 'A', 'Lecture', NULL), (248, 'BCS306A', 85, 2, 'ISE', 'A', 'Lecture', NULL), (249, 'BCS306A', 85, 2, 'ISE', 'A', 'Lab', 'A1'), (250, 'BCS306A', 85, 2, 'ISE', 'A', 'Lab', 'A2'), (251, 'BSCK307', 67, 2, 'ISE', 'A', 'Lecture', NULL), (252, 'BCS358D', 86, 2, 'ISE', 'A', 'Lecture', NULL), (253, 'BCSL305', 84, 2, 'ISE', 'A', 'Lab', 'A1'), (254, 'BCSL305', 84, 2, 'ISE', 'A', 'Lab', 'A2'), (255, 'BCSL305', 84, 2, 'ISE', 'A', 'Lab', 'A3'),
(256, 'BCS301', 87, 2, 'ISE', 'B', 'Lecture', NULL), (257, 'BCS302', 82, 2, 'ISE', 'B', 'Lecture', NULL), (258, 'BCS302', 82, 2, 'ISE', 'B', 'Lab', 'B1'), (259, 'BCS302', 82, 2, 'ISE', 'B', 'Lab', 'B2'), (260, 'BCS302', 82, 2, 'ISE', 'B', 'Lab', 'B3'), (261, 'BCS303', 83, 2, 'ISE', 'B', 'Lecture', NULL), (262, 'BCS303', 83, 2, 'ISE', 'B', 'Lab', 'B1'), (263, 'BCS303', 83, 2, 'ISE', 'B', 'Lab', 'B2'), (264, 'BCS303', 83, 2, 'ISE', 'B', 'Lab', 'B3'), (265, 'BCS304', 84, 2, 'ISE', 'B', 'Lecture', NULL), (266, 'BCS306A', 86, 2, 'ISE', 'B', 'Lecture', NULL), (267, 'BCS306A', 86, 2, 'ISE', 'B', 'Lab', 'B1'), (268, 'BCS306A', 86, 2, 'ISE', 'B', 'Lab', 'B2'), (269, 'BSCK307', 67, 2, 'ISE', 'B', 'Lecture', NULL), (270, 'BCS358D', 86, 2, 'ISE', 'B', 'Lecture', NULL), (271, 'BCSL305', 84, 2, 'ISE', 'B', 'Lab', 'B1'), (272, 'BCSL305', 84, 2, 'ISE', 'B', 'Lab', 'B2'), (273, 'BCSL305', 84, 2, 'ISE', 'B', 'Lab', 'B3'),
(274, 'BCS301', 87, 2, 'ISE', 'C', 'Lecture', NULL), (275, 'BCS302', 87, 2, 'ISE', 'C', 'Lecture', NULL), (276, 'BCS302', 87, 2, 'ISE', 'C', 'Lab', 'C1'), (277, 'BCS302', 87, 2, 'ISE', 'C', 'Lab', 'C2'), (278, 'BCS302', 87, 2, 'ISE', 'C', 'Lab', 'C3'), (279, 'BCS303', 88, 2, 'ISE', 'C', 'Lecture', NULL), (280, 'BCS303', 88, 2, 'ISE', 'C', 'Lab', 'C1'), (281, 'BCS303', 88, 2, 'ISE', 'C', 'Lab', 'C2'), (282, 'BCS303', 88, 2, 'ISE', 'C', 'Lab', 'C3'), (283, 'BCS304', 89, 2, 'ISE', 'C', 'Lecture', NULL), (284, 'BCS306A', 85, 2, 'ISE', 'C', 'Lecture', NULL), (285, 'BCS306A', 85, 2, 'ISE', 'C', 'Lab', 'C1'), (286, 'BCS306A', 85, 2, 'ISE', 'C', 'Lab', 'C2'), (287, 'BSCK307', 90, 2, 'ISE', 'C', 'Lecture', NULL), (288, 'BCS358D', 87, 2, 'ISE', 'C', 'Lecture', NULL), (289, 'BCSL305', 89, 2, 'ISE', 'C', 'Lab', 'C1'), (290, 'BCSL305', 89, 2, 'ISE', 'C', 'Lab', 'C2'), (291, 'BCSL305', 89, 2, 'ISE', 'C', 'Lab', 'C3'),
(292, 'BCS301', 90, 2, 'ISE', 'D', 'Lecture', NULL), (293, 'BCS302', 90, 2, 'ISE', 'D', 'Lecture', NULL), (294, 'BCS302', 90, 2, 'ISE', 'D', 'Lab', 'D1'), (295, 'BCS302', 90, 2, 'ISE', 'D', 'Lab', 'D2'), (296, 'BCS302', 90, 2, 'ISE', 'D', 'Lab', 'D3'), (297, 'BCS303', 70, 2, 'ISE', 'D', 'Lecture', NULL), (298, 'BCS303', 70, 2, 'ISE', 'D', 'Lab', 'D1'), (299, 'BCS303', 70, 2, 'ISE', 'D', 'Lab', 'D2'), (300, 'BCS303', 70, 2, 'ISE', 'D', 'Lab', 'D3'), (301, 'BCS304', 89, 2, 'ISE', 'D', 'Lecture', NULL), (302, 'BCS306A', 71, 2, 'ISE', 'D', 'Lecture', NULL), (303, 'BCS306A', 71, 2, 'ISE', 'D', 'Lab', 'D1'), (304, 'BCS306A', 71, 2, 'ISE', 'D', 'Lab', 'D2'), (305, 'BSCK307', 90, 2, 'ISE', 'D', 'Lecture', NULL), (306, 'BCS358D', 87, 2, 'ISE', 'D', 'Lecture', NULL), (307, 'BCSL305', 89, 2, 'ISE', 'D', 'Lab', 'D1'), (308, 'BCSL305', 89, 2, 'ISE', 'D', 'Lab', 'D2'), (309, 'BCSL305', 89, 2, 'ISE', 'D', 'Lab', 'D3'),
(310, 'BIS501', 65, 3, 'ISE', 'A', 'Lecture', NULL), (311, 'BIS502', 66, 3, 'ISE', 'A', 'Lecture', NULL), (312, 'BIS502', 66, 3, 'ISE', 'A', 'Lab', 'A1'), (313, 'BIS502', 66, 3, 'ISE', 'A', 'Lab', 'A2'), (314, 'BIS503', 67, 3, 'ISE', 'A', 'Lecture', NULL), (315, 'BIS505', 68, 3, 'ISE', 'A', 'Lecture', NULL), (316, 'BIS516B', 69, 3, 'ISE', 'A', 'Lecture', NULL), (317, 'BIS516C', 66, 3, 'ISE', 'A', 'Lecture', NULL), (318, 'BIS516D', 70, 3, 'ISE', 'A', 'Lecture', NULL), (319, 'BRMIS557', 71, 3, 'ISE', 'A', 'Lecture', NULL), (320, 'BISL504', 65, 3, 'ISE', 'A', 'Lab', 'A1'), (321, 'BISL504', 65, 3, 'ISE', 'A', 'Lab', 'A2'), (322, 'BIS586', 68, 3, 'ISE', 'A', 'Lab', NULL), (323, 'BESK508', 72, 3, 'ISE', 'A', 'Lecture', NULL), (324, 'BNSK559', NULL, 3, 'ISE', 'A', 'Lab', NULL),
(325, 'BIS501', 73, 3, 'ISE', 'B', 'Lecture', NULL), (326, 'BIS502', 74, 3, 'ISE', 'B', 'Lecture', NULL), (327, 'BIS502', 74, 3, 'ISE', 'B', 'Lab', 'B1'), (328, 'BIS502', 74, 3, 'ISE', 'B', 'Lab', 'B2'), (329, 'BIS503', 75, 3, 'ISE', 'B', 'Lecture', NULL), (330, 'BIS505', 76, 3, 'ISE', 'B', 'Lecture', NULL), (331, 'BIS516B', 69, 3, 'ISE', 'B', 'Lecture', NULL), (332, 'BIS516C', 66, 3, 'ISE', 'B', 'Lecture', NULL), (333, 'BIS516D', 70, 3, 'ISE', 'B', 'Lecture', NULL), (334, 'BRMIS557', 77, 3, 'ISE', 'B', 'Lecture', NULL), (335, 'BISL504', NULL, 3, 'ISE', 'B', 'Lab', 'B1'), (336, 'BISL504', 65, 3, 'ISE', 'B', 'Lab', 'B2'), (337, 'BIS586', 68, 3, 'ISE', 'B', 'Lab', NULL), (338, 'BESK508', 78, 3, 'ISE', 'B', 'Lecture', NULL), (339, 'BNSK559', NULL, 3, 'ISE', 'B', 'Lab', NULL),
(340, 'BIS501', 65, 3, 'ISE', 'C', 'Lecture', NULL), (341, 'BIS502', 79, 3, 'ISE', 'C', 'Lecture', NULL), (342, 'BIS502', 79, 3, 'ISE', 'C', 'Lab', 'C1'), (343, 'BIS502', 79, 3, 'ISE', 'C', 'Lab', 'C2'), (344, 'BIS503', 75, 3, 'ISE', 'C', 'Lecture', NULL), (345, 'BIS505', 76, 3, 'ISE', 'C', 'Lecture', NULL), (346, 'BIS516B', 69, 3, 'ISE', 'C', 'Lecture', NULL), (347, 'BIS516C', 66, 3, 'ISE', 'C', 'Lecture', NULL), (348, 'BIS516D', 70, 3, 'ISE', 'C', 'Lecture', NULL), (349, 'BRMIS557', 80, 3, 'ISE', 'C', 'Lecture', NULL), (350, 'BISL504', NULL, 3, 'ISE', 'C', 'Lab', 'C1'), (351, 'BISL504', NULL, 3, 'ISE', 'C', 'Lab', 'C2'), (352, 'BIS586', 68, 3, 'ISE', 'C', 'Lab', NULL), (353, 'BESK508', 78, 3, 'ISE', 'C', 'Lecture', NULL), (354, 'BNSK559', NULL, 3, 'ISE', 'C', 'Lab', NULL),
(355, 'BIS501', 73, 3, 'ISE', 'D', 'Lecture', NULL), (356, 'BIS502', 74, 3, 'ISE', 'D', 'Lecture', NULL), (357, 'BIS502', 74, 3, 'ISE', 'D', 'Lab', 'D1'), (358, 'BIS502', 74, 3, 'ISE', 'D', 'Lab', 'D2'), (359, 'BIS503', 81, 3, 'ISE', 'D', 'Lecture', NULL), (360, 'BIS505', 68, 3, 'ISE', 'D', 'Lecture', NULL), (361, 'BIS516B', 69, 3, 'ISE', 'D', 'Lecture', NULL), (362, 'BIS516C', 66, 3, 'ISE', 'D', 'Lecture', NULL), (363, 'BIS516D', 70, 3, 'ISE', 'D', 'Lecture', NULL), (364, 'BRMIS557', 77, 3, 'ISE', 'D', 'Lecture', NULL), (365, 'BISL504', NULL, 3, 'ISE', 'D', 'Lab', 'D1'), (366, 'BISL504', NULL, 3, 'ISE', 'D', 'Lab', 'D2'), (367, 'BIS586', 68, 3, 'ISE', 'D', 'Lab', NULL), (368, 'BESK508', 72, 3, 'ISE', 'D', 'Lecture', NULL), (369, 'BNSK559', NULL, 3, 'ISE', 'D', 'Lab', NULL),
(370, 'BCS501', 91, 3, 'CSE', 'A', 'Lecture', NULL), (371, 'BCS502', 92, 3, 'CSE', 'A', 'Lecture', NULL), (372, 'BCS502', 92, 3, 'CSE', 'A', 'Lab', 'A1'), (373, 'BCS502', 92, 3, 'CSE', 'A', 'Lab', 'A2'), (374, 'BCS502', 92, 3, 'CSE', 'A', 'Lab', 'A3'), (375, 'BCS503', 93, 3, 'CSE', 'A', 'Lecture', NULL), (376, 'BCSL504', 94, 3, 'CSE', 'A', 'Lab', 'A1'), (377, 'BCSL504', 94, 3, 'CSE', 'A', 'Lab', 'A2'), (378, 'BCSL504', 94, 3, 'CSE', 'A', 'Lab', 'A3'), (379, 'BCS505', 94, 3, 'CSE', 'A', 'Lecture', NULL), (380, 'BCS516B', 95, 3, 'CSE', 'A', 'Lecture', NULL), (381, 'BCS586', 52, 3, 'CSE', 'A', 'Lab', NULL), (382, 'BRMCS557', 96, 3, 'CSE', 'A', 'Lecture', NULL), (383, 'BESK508', 97, 3, 'CSE', 'A', 'Lecture', NULL), (384, 'BNSK559', NULL, 3, 'CSE', 'A', 'Lab', NULL),
(385, 'BCS501', 98, 3, 'CSE', 'B', 'Lecture', NULL), (386, 'BCS502', 99, 3, 'CSE', 'B', 'Lecture', NULL), (387, 'BCS502', 99, 3, 'CSE', 'B', 'Lab', 'B1'), (388, 'BCS502', 99, 3, 'CSE', 'B', 'Lab', 'B2'), (389, 'BCS502', 27, 3, 'CSE', 'B', 'Lab', 'B3'), (390, 'BCS503', 100, 3, 'CSE', 'B', 'Lecture', NULL), (391, 'BCSL504', 37, 3, 'CSE', 'B', 'Lab', 'B1'), (392, 'BCSL504', 37, 3, 'CSE', 'B', 'Lab', 'B2'), (393, 'BCSL504', 37, 3, 'CSE', 'B', 'Lab', 'B3'), (394, 'BCS505', 37, 3, 'CSE', 'B', 'Lecture', NULL), (395, 'BCS516B', 101, 3, 'CSE', 'B', 'Lecture', NULL), (396, 'BCS586', 52, 3, 'CSE', 'B', 'Lab', NULL), (397, 'BRMCS557', 43, 3, 'CSE', 'B', 'Lecture', NULL), (398, 'BESK508', 97, 3, 'CSE', 'B', 'Lecture', NULL), (399, 'BNSK559', NULL, 3, 'CSE', 'B', 'Lab', NULL),
(400, 'BCS501', 102, 3, 'CSE', 'C', 'Lecture', NULL), (401, 'BCS502', 103, 3, 'CSE', 'C', 'Lecture', NULL), (402, 'BCS502', 103, 3, 'CSE', 'C', 'Lab', 'C1'), (403, 'BCS502', 103, 3, 'CSE', 'C', 'Lab', 'C2'), (404, 'BCS502', 103, 3, 'CSE', 'C', 'Lab', 'C3'), (405, 'BCS503', 100, 3, 'CSE', 'C', 'Lecture', NULL), (406, 'BCSL504', 94, 3, 'CSE', 'C', 'Lab', 'C1'), (407, 'BCSL504', 37, 3, 'CSE', 'C', 'Lab', 'C2'), (408, 'BCSL504', 37, 3, 'CSE', 'C', 'Lab', 'C3'), (409, 'BCS505', 94, 3, 'CSE', 'C', 'Lecture', NULL), (410, 'BCS516B', 104, 3, 'CSE', 'C', 'Lecture', NULL), (411, 'BCS586', 52, 3, 'CSE', 'C', 'Lab', NULL), (412, 'BRMCS557', 55, 3, 'CSE', 'C', 'Lecture', NULL), (413, 'BESK508', 97, 3, 'CSE', 'C', 'Lecture', NULL), (414, 'BNSK559', NULL, 3, 'CSE', 'C', 'Lab', NULL),
(415, 'BCS501', 60, 3, 'CSE', 'D', 'Lecture', NULL), (416, 'BCS502', 106, 3, 'CSE', 'D', 'Lecture', NULL), (417, 'BCS502', 103, 3, 'CSE', 'D', 'Lab', 'D1'), (418, 'BCS502', 50, 3, 'CSE', 'D', 'Lab', 'D2'), (419, 'BCS502', 103, 3, 'CSE', 'D', 'Lab', 'D3'), (420, 'BCS503', 58, 3, 'CSE', 'D', 'Lecture', NULL), (421, 'BCSL504', 107, 3, 'CSE', 'D', 'Lab', 'D1'), (422, 'BCSL504', 107, 3, 'CSE', 'D', 'Lab', 'D2'), (423, 'BCSL504', 107, 3, 'CSE', 'D', 'Lab', 'D3'), (424, 'BCS505', 107, 3, 'CSE', 'D', 'Lecture', NULL), (425, 'BCS516B', 95, 3, 'CSE', 'D', 'Lecture', NULL), (426, 'BCS586', 52, 3, 'CSE', 'D', 'Lab', NULL), (427, 'BRMCS557', 103, 3, 'CSE', 'D', 'Lecture', NULL), (428, 'BESK508', 72, 3, 'CSE', 'D', 'Lecture', NULL), (429, 'BNSK559', NULL, 3, 'CSE', 'D', 'Lab', NULL),
(430, 'BCS501', 91, 3, 'AI&ML', 'E', 'Lecture', NULL), (431, 'BCS502', 99, 3, 'AI&ML', 'E', 'Lecture', NULL), (432, 'BCS502', 99, 3, 'AI&ML', 'E', 'Lab', 'E1'), (433, 'BCS502', 99, 3, 'AI&ML', 'E', 'Lab', 'E2'), (434, 'BCS502', 99, 3, 'AI&ML', 'E', 'Lab', 'E3'), (435, 'BCS503', 116, 3, 'AI&ML', 'E', 'Lecture', NULL), (436, 'BCSL504', 117, 3, 'AI&ML', 'E', 'Lab', 'E1'), (437, 'BCSL504', 117, 3, 'AI&ML', 'E', 'Lab', 'E2'), (438, 'BCSL504', 117, 3, 'AI&ML', 'E', 'Lab', 'E3'), (439, 'BCS505', 117, 3, 'AI&ML', 'E', 'Lecture', NULL), (440, 'BCI516B', 118, 3, 'AI&ML', 'E', 'Lecture', NULL), (441, 'BCI586', 52, 3, 'AI&ML', 'E', 'Lab', NULL), (442, 'BRMCS557', 35, 3, 'AI&ML', 'E', 'Lecture', NULL), (443, 'BESK508', 72, 3, 'AI&ML', 'E', 'Lecture', NULL), (444, 'BNSK559', NULL, 3, 'AI&ML', 'E', 'Lab', NULL),
(445, 'BCS501', 102, 3, 'AI&ML', 'F', 'Lecture', NULL), (446, 'BCS502', 92, 3, 'AI&ML', 'F', 'Lecture', NULL), (447, 'BCS502', 92, 3, 'AI&ML', 'F', 'Lab', 'F1'), (448, 'BCS502', 118, 3, 'AI&ML', 'F', 'Lab', 'F2'), (449, 'BCS502', 92, 3, 'AI&ML', 'F', 'Lab', 'F3'), (450, 'BCS503', 93, 3, 'AI&ML', 'F', 'Lecture', NULL), (451, 'BCSL504', 104, 3, 'AI&ML', 'F', 'Lab', 'F1'), (452, 'BCSL504', 117, 3, 'AI&ML', 'F', 'Lab', 'F2'), (453, 'BCSL504', 104, 3, 'AI&ML', 'F', 'Lab', 'F3'), (454, 'BCS505', 117, 3, 'AI&ML', 'F', 'Lecture', NULL), (455, 'BCI516B', 118, 3, 'AI&ML', 'F', 'Lecture', NULL), (456, 'BCI586', 52, 3, 'AI&ML', 'F', 'Lab', NULL), (457, 'BRMCS557', 53, 3, 'AI&ML', 'F', 'Lecture', NULL), (458, 'BESK508', 78, 3, 'AI&ML', 'F', 'Lecture', NULL), (459, 'BNSK559', NULL, 3, 'AI&ML', 'F', 'Lab', NULL),
(460, 'BCS701', 101, 4, 'CSE', 'A', 'Lecture', NULL), (461, 'BCS702', 38, 4, 'CSE', 'A', 'Lecture', NULL), (462, 'BCS702', 38, 4, 'CSE', 'A', 'Lab', 'A1'), (463, 'BCS702', 38, 4, 'CSE', 'A', 'Lab', 'A2'), (464, 'BCS713A', 107, 4, 'CSE', 'A', 'Lecture', NULL), (465, 'BCS713C', 27, 4, 'CSE', 'A', 'Lecture', NULL), (466, 'BCI713D', NULL, 4, 'CSE', 'A', 'Lecture', NULL), (467, 'BCS754X', NULL, 4, 'CSE', 'A', 'Lecture', NULL), (468, 'BCS785', 99, 4, 'CSE', 'A', 'Lab', NULL),
(469, 'BCS701', 112, 4, 'CSE', 'B', 'Lecture', NULL), (470, 'BCS702', 113, 4, 'CSE', 'B', 'Lecture', NULL), (471, 'BCS702', 113, 4, 'CSE', 'B', 'Lab', 'B1'), (472, 'BCS702', 38, 4, 'CSE', 'B', 'Lab', 'B2'), (473, 'BCS713A', 107, 4, 'CSE', 'B', 'Lecture', NULL), (474, 'BCS713C', 27, 4, 'CSE', 'B', 'Lecture', NULL), (475, 'BCI713D', NULL, 4, 'CSE', 'B', 'Lecture', NULL), (476, 'BCS754X', NULL, 4, 'CSE', 'B', 'Lecture', NULL), (477, 'BCS785', 99, 4, 'CSE', 'B', 'Lab', NULL),
(478, 'BCS701', 114, 4, 'CSE', 'C', 'Lecture', NULL), (479, 'BCS702', 113, 4, 'CSE', 'C', 'Lecture', NULL), (480, 'BCS702', 38, 4, 'CSE', 'C', 'Lab', 'C1'), (481, 'BCS702', 38, 4, 'CSE', 'C', 'Lab', 'C2'), (482, 'BCS713A', 107, 4, 'CSE', 'C', 'Lecture', NULL), (483, 'BCS713C', NULL, 4, 'CSE', 'C', 'Lecture', NULL), (484, 'BCI713D', NULL, 4, 'CSE', 'C', 'Lecture', NULL), (485, 'BCS754X', NULL, 4, 'CSE', 'C', 'Lecture', NULL), (486, 'BCS785', 99, 4, 'CSE', 'C', 'Lab', NULL),
(487, 'BCS701', 112, 4, 'CSE', 'D', 'Lecture', NULL), (488, 'BCS702', 41, 4, 'CSE', 'D', 'Lecture', NULL), (489, 'BCS702', 41, 4, 'CSE', 'D', 'Lab', 'D1'), (490, 'BCS702', 41, 4, 'CSE', 'D', 'Lab', 'D2'), (491, 'BCS713A', 107, 4, 'CSE', 'D', 'Lecture', NULL), (492, 'BCS713C', NULL, 4, 'CSE', 'D', 'Lecture', NULL), (493, 'BCI713D', NULL, 4, 'CSE', 'D', 'Lecture', NULL), (494, 'BCS754X', NULL, 4, 'CSE', 'D', 'Lecture', NULL), (495, 'BCS786', 99, 4, 'CSE', 'D', 'Lab', NULL),
(496, 'BCI701', 116, 4, 'AI&ML', 'E', 'Lecture', NULL), (497, 'BCI701', 116, 4, 'AI&ML', 'E', 'Lecture', 'E1'), (498, 'BCI701', 116, 4, 'AI&ML', 'E', 'Lecture', 'E2'), (499, 'BCI702', 104, 4, 'AI&ML', 'E', 'Lecture', NULL), (500, 'BCI702', 104, 4, 'AI&ML', 'E', 'Lab', 'E1'), (501, 'BCI702', 104, 4, 'AI&ML', 'E', 'Lab', 'E2'), (502, 'BCI713D', 52, 4, 'AI&ML', 'E', 'Lecture', NULL), (503, 'BCS754X', NULL, 4, 'AI&ML', 'E', 'Lecture', NULL), (504, 'BCI785', 99, 4, 'AI&ML', 'E', 'Lab', NULL);

-- 8. INSERT TIMETABLE SLOTS DATA
-- (This is the complete, manually transcribed slot data for all sections)
-- [This space is intentionally left blank for you to paste the
-- INSERT INTO timetable_slots... data from the previous step]
-- 1st Year CSE 'A' (IDs: 1-12)
INSERT INTO timetable_slots (class_id, day_of_week, start_time, end_time, room_no, location) VALUES
(2, 'Monday', '09:00:00', '10:00:00', '101', 'Ramanujacharya Bhavan, ground floor'),
(1, 'Monday', '10:00:00', '11:00:00', '101', 'Ramanujacharya Bhavan, ground floor'),
(5, 'Monday', '11:30:00', '12:30:00', '101', 'Ramanujacharya Bhavan, ground floor'),
(8, 'Monday', '14:30:00', '16:30:00', NULL, 'PHY LAB-1'),
(7, 'Monday', '14:30:00', '16:30:00', NULL, 'PSC LAB-2'),
(1, 'Tuesday', '10:00:00', '11:00:00', '101', 'Ramanujacharya Bhavan, ground floor'),
(9, 'Tuesday', '14:30:00', '16:30:00', NULL, 'PHY LAB-2'),
(6, 'Tuesday', '14:30:00', '16:30:00', NULL, 'PSC LAB-1'),
(4, 'Wednesday', '10:00:00', '11:00:00', '101', 'Ramanujacharya Bhavan, ground floor'),
(2, 'Wednesday', '11:30:00', '12:30:00', '101', 'Ramanujacharya Bhavan, ground floor'),
(3, 'Wednesday', '14:30:00', '16:30:00', NULL, 'CAED Lab'),
(3, 'Thursday', '10:00:00', '12:30:00', NULL, 'CAED Lab'),
(5, 'Thursday', '14:30:00', '15:30:00', '101', 'Ramanujacharya Bhavan, ground floor'),
(11, 'Thursday', '15:30:00', '16:30:00', '101', 'Ramanujacharya Bhavan, ground floor'),
(4, 'Friday', '09:00:00', '10:00:00', '101', 'Ramanujacharya Bhavan, ground floor'),
(1, 'Friday', '11:30:00', '12:30:00', '101', 'Ramanujacharya Bhavan, ground floor'),
(2, 'Friday', '14:30:00', '15:30:00', '101', 'Ramanujacharya Bhavan, ground floor'),
(5, 'Friday', '15:30:00', '16:30:00', '101', 'Ramanujacharya Bhavan, ground floor'),
(10, 'Friday', '16:30:00', '17:30:00', '101', 'Ramanujacharya Bhavan, ground floor'),
(12, 'Saturday', '10:00:00', '11:00:00', '101', 'Ramanujacharya Bhavan, ground floor');

-- 1st Year CSE 'B' (IDs: 13-24)
INSERT INTO timetable_slots (class_id, day_of_week, start_time, end_time, room_no, location) VALUES
(17, 'Monday', '09:00:00', '10:00:00', '107', 'Ramanujacharya Bhavan, ground floor'),
(16, 'Monday', '11:30:00', '12:30:00', '107', 'Ramanujacharya Bhavan, ground floor'),
(13, 'Monday', '12:30:00', '13:30:00', '107', 'Ramanujacharya Bhavan, ground floor'),
(20, 'Monday', '14:30:00', '16:30:00', NULL, 'PHY LAB-1'),
(19, 'Monday', '14:30:00', '16:30:00', NULL, 'PSC LAB-2'),
(13, 'Tuesday', '10:00:00', '11:00:00', '107', 'Ramanujacharya Bhavan, ground floor'),
(17, 'Tuesday', '11:30:00', '12:30:00', '107', 'Ramanujacharya Bhavan, ground floor'),
(21, 'Wednesday', '09:00:00', '11:00:00', NULL, 'PHY LAB-2'),
(18, 'Wednesday', '09:00:00', '11:00:00', NULL, 'PSC LAB-1'),
(14, 'Wednesday', '11:30:00', '12:30:00', '107', 'Ramanujacharya Bhavan, ground floor'),
(17, 'Wednesday', '14:30:00', '15:30:00', '107', 'Ramanujacharya Bhavan, ground floor'),
(16, 'Wednesday', '15:30:00', '16:30:00', '107', 'Ramanujacharya Bhavan, ground floor'),
(14, 'Thursday', '09:00:00', '10:00:00', '107', 'Ramanujacharya Bhavan, ground floor'),
(16, 'Thursday', '11:30:00', '12:30:00', '107', 'Ramanujacharya Bhavan, ground floor'),
(15, 'Thursday', '14:30:00', '16:30:00', NULL, 'CAED Lab'),
(22, 'Friday', '12:30:00', '13:30:00', '107', 'Ramanujacharya Bhavan, ground floor'),
(13, 'Friday', '14:30:00', '15:30:00', '107', 'Ramanujacharya Bhavan, ground floor'),
(23, 'Friday', '15:30:00', '16:30:00', '107', 'Ramanujacharya Bhavan, ground floor'),
(24, 'Saturday', '09:00:00', '10:00:00', '107', 'Ramanujacharya Bhavan, ground floor');

-- 1st Year CSE 'C' (IDs: 25-36)
INSERT INTO timetable_slots (class_id, day_of_week, start_time, end_time, room_no, location) VALUES
(26, 'Monday', '10:00:00', '11:00:00', '108', 'Ramanujacharya Bhavan, ground floor'),
(29, 'Monday', '11:30:00', '12:30:00', '108', 'Ramanujacharya Bhavan, ground floor'),
(25, 'Monday', '12:30:00', '13:30:00', '108', 'Ramanujacharya Bhavan, ground floor'),
(27, 'Monday', '14:30:00', '16:30:00', NULL, 'CAED Lab'),
(29, 'Tuesday', '09:00:00', '10:00:00', '108', 'Ramanujacharya Bhavan, ground floor'),
(25, 'Tuesday', '11:30:00', '12:30:00', '108', 'Ramanujacharya Bhavan, ground floor'),
(32, 'Tuesday', '14:30:00', '16:30:00', NULL, 'PHY LAB-1'),
(31, 'Tuesday', '14:30:00', '16:30:00', NULL, 'PSC LAB-2'),
(28, 'Wednesday', '09:00:00', '10:00:00', '108', 'Ramanujacharya Bhavan, ground floor'),
(25, 'Wednesday', '10:00:00', '11:00:00', '108', 'Ramanujacharya Bhavan, ground floor'),
(26, 'Wednesday', '12:30:00', '13:30:00', '108', 'Ramanujacharya Bhavan, ground floor'),
(28, 'Thursday', '09:00:00', '10:00:00', '108', 'Ramanujacharya Bhavan, ground floor'),
(27, 'Thursday', '09:00:00', '11:00:00', NULL, 'CAED Lab'), -- Assuming 9-11 slot
(34, 'Thursday', '11:30:00', '12:30:00', '108', 'Ramanujacharya Bhavan, ground floor'),
(33, 'Thursday', '14:30:00', '16:30:00', NULL, 'PHY LAB-2'),
(30, 'Thursday', '14:30:00', '16:30:00', NULL, 'PSC LAB-1'),
(26, 'Friday', '09:00:00', '10:00:00', '108', 'Ramanujacharya Bhavan, ground floor'),
(28, 'Friday', '10:00:00', '11:00:00', '108', 'Ramanujacharya Bhavan, ground floor'),
(29, 'Friday', '14:30:00', '15:30:00', '108', 'Ramanujacharya Bhavan, ground floor'),
(25, 'Friday', '15:30:00', '16:30:00', '108', 'Ramanujacharya Bhavan, ground floor'),
(35, 'Friday', '16:30:00', '17:30:00', '108', 'Ramanujacharya Bhavan, ground floor'),
(36, 'Saturday', '10:00:00', '11:00:00', '108', 'Ramanujacharya Bhavan, ground floor');

-- 1st Year CSE 'd'
INSERT INTO timetable_slots (class_id, day_of_week, start_time, end_time, room_no, location) VALUES
(41, 'Monday', '10:00:00', '11:00:00', '109', 'Ramanujacharya Bhavan, ground floor'),
(37, 'Monday', '11:30:00', '12:30:00', '109', 'Ramanujacharya Bhavan, ground floor'),
(44, 'Monday', '14:30:00', '16:30:00', NULL, 'PHY LAB-1'),
(43, 'Monday', '14:30:00', '16:30:00', NULL, 'PSC LAB-2'),
(45, 'Tuesday', '09:00:00', '11:00:00', NULL, 'PHY LAB-2'),
(42, 'Tuesday', '09:00:00', '11:00:00', NULL, 'PSC LAB-1'),
(37, 'Tuesday', '11:30:00', '12:30:00', '109', 'Ramanujacharya Bhavan, ground floor'),
(38, 'Tuesday', '12:30:00', '13:30:00', '109', 'Ramanujacharya Bhavan, ground floor'),
(41, 'Wednesday', '09:00:00', '10:00:00', '109', 'Ramanujacharya Bhavan, ground floor'),
(38, 'Wednesday', '10:00:00', '11:00:00', '109', 'Ramanujacharya Bhavan, ground floor'),
(37, 'Wednesday', '12:30:00', '13:30:00', '109', 'Ramanujacharya Bhavan, ground floor'),
(39, 'Wednesday', '14:30:00', '16:30:00', NULL, 'CAED Lab'),
(37, 'Thursday', '09:00:00', '10:00:00', '109', 'Ramanujacharya Bhavan, ground floor'),
(40, 'Thursday', '10:00:00', '11:00:00', '109', 'Ramanujacharya Bhavan, ground floor'),
(41, 'Thursday', '14:30:00', '15:30:00', '109', 'Ramanujacharya Bhavan, ground floor'),
(40, 'Thursday', '15:30:00', '16:30:00', '109', 'Ramanujacharya Bhavan, ground floor'),
(40, 'Friday', '09:00:00', '10:00:00', '109', 'Ramanujacharya Bhavan, ground floor'),
(47, 'Friday', '10:00:00', '11:00:00', '109', 'Ramanujacharya Bhavan, ground floor'),
(46, 'Friday', '11:30:00', '12:30:00', '109', 'Ramanujacharya Bhavan, ground floor'),
(38, 'Friday', '12:30:00', '13:30:00', '109', 'Ramanujacharya Bhavan, ground floor'),
(39, 'Friday', '14:30:00', '16:30:00', NULL, 'CAED Lab'),
(48, 'Saturday', '10:00:00', '11:00:00', '109', 'Ramanujacharya Bhavan, ground floor');
-- ---------------------------------
-- 1st Year CSE 'E' (IDs: 49-60)
-- ---------------------------------
INSERT INTO timetable_slots (class_id, day_of_week, start_time, end_time, room_no, location) VALUES
(53, 'Monday', '09:00:00', '10:00:00', 'MB-1', 'Madhvacharya Bhavana'),
(50, 'Monday', '10:00:00', '11:00:00', 'MB-1', 'Madhvacharya Bhavana'),
(51, 'Monday', '11:30:00', '13:30:00', NULL, 'CAED Lab'),
(56, 'Tuesday', '09:00:00', '11:00:00', NULL, 'PHY LAB-1'),
(55, 'Tuesday', '09:00:00', '11:00:00', NULL, 'PSC LAB-2'),
(50, 'Tuesday', '11:30:00', '12:30:00', 'MB-1', 'Madhvacharya Bhavana'),
(53, 'Tuesday', '12:30:00', '13:30:00', 'MB-1', 'Madhvacharya Bhavana'),
(49, 'Tuesday', '14:30:00', '15:30:00', 'MB-1', 'Madhvacharya Bhavana'),
(49, 'Wednesday', '09:00:00', '10:00:00', 'MB-1', 'Madhvacharya Bhavana'),
(52, 'Wednesday', '14:30:00', '15:30:00', 'MB-1', 'Madhvacharya Bhavana'),
(53, 'Wednesday', '15:30:00', '16:30:00', 'MB-1', 'Madhvacharya Bhavana'),
(50, 'Thursday', '09:00:00', '10:00:00', 'MB-1', 'Madhvacharya Bhavana'),
(49, 'Thursday', '10:00:00', '11:00:00', 'MB-1', 'Madhvacharya Bhavana'),
(52, 'Thursday', '11:30:00', '12:30:00', 'MB-1', 'Madhvacharya Bhavana'),
(58, 'Thursday', '12:30:00', '13:30:00', 'MB-1', 'Madhvacharya Bhavana'),
(52, 'Thursday', '14:30:00', '15:30:00', 'MB-1', 'Madhvacharya Bhavana'),
(57, 'Friday', '09:00:00', '11:00:00', NULL, 'PHY LAB-2'),
(54, 'Friday', '09:00:00', '11:00:00', NULL, 'PSC LAB-1'),
(49, 'Friday', '11:30:00', '12:30:00', 'MB-1', 'Madhvacharya Bhavana'),
(59, 'Friday', '12:30:00', '13:30:00', 'MB-1', 'Madhvacharya Bhavana'),
(51, 'Friday', '14:30:00', '16:30:00', NULL, 'CAED Lab'),
(60, 'Saturday', '09:00:00', '10:00:00', 'MB-1', 'Madhvacharya Bhavana');

-- ---------------------------------
-- 1st Year CSE 'F' (IDs: 61-72)
-- ---------------------------------
INSERT INTO timetable_slots (class_id, day_of_week, start_time, end_time, room_no, location) VALUES
(72, 'Monday', '09:00:00', '10:00:00', 'MB-2', 'Madhvacharya Bhavana'),
(62, 'Monday', '10:00:00', '11:00:00', 'MB-2', 'Madhvacharya Bhavana'),
(64, 'Monday', '11:30:00', '12:30:00', 'MB-2', 'Madhvacharya Bhavana'),
(61, 'Monday', '12:30:00', '13:30:00', 'MB-2', 'Madhvacharya Bhavana'),
(71, 'Monday', '14:30:00', '16:30:00', NULL, 'IDT LAB'),
(62, 'Tuesday', '09:00:00', '10:00:00', 'MB-2', 'Madhvacharya Bhavana'),
(65, 'Tuesday', '10:00:00', '11:00:00', 'MB-2', 'Madhvacharya Bhavana'),
(63, 'Tuesday', '11:30:00', '12:30:00', 'MB-2', 'Madhvacharya Bhavana'),
(69, 'Tuesday', '14:30:00', '16:30:00', NULL, 'CHE LAB-1'),
(68, 'Tuesday', '14:30:00', '16:30:00', NULL, 'PSC LAB-2'),
(66, 'Wednesday', '09:00:00', '10:00:00', 'MB-2', 'Madhvacharya Bhavana'),
(64, 'Wednesday', '10:00:00', '11:00:00', 'MB-2', 'Madhvacharya Bhavana'),
(61, 'Wednesday', '11:30:00', '12:30:00', 'MB-2', 'Madhvacharya Bhavana'),
(65, 'Wednesday', '12:30:00', '13:30:00', 'MB-2', 'Madhvacharya Bhavana'),
(63, 'Wednesday', '14:30:00', '15:30:00', 'MB-2', 'Madhvacharya Bhavana'),
(63, 'Thursday', '09:00:00', '10:00:00', 'MB-2', 'Madhvacharya Bhavana'),
(62, 'Thursday', '10:00:00', '11:00:00', 'MB-2', 'Madhvacharya Bhavana'),
(61, 'Thursday', '11:30:00', '12:30:00', 'MB-2', 'Madhvacharya Bhavana'),
(62, 'Thursday', '14:30:00', '15:30:00', 'MB-2', 'Madhvacharya Bhavana'),
(70, 'Friday', '14:30:00', '16:30:00', NULL, 'CHE LAB-2'),
(67, 'Friday', '14:30:00', '16:30:00', NULL, 'PSC LAB-1'),
(65, 'Friday', '12:30:00', '13:30:00', 'MB-2', 'Madhvacharya Bhavana');

-- ---------------------------------
-- 1st Year CSE 'G' (IDs: 73-84)
-- ---------------------------------
INSERT INTO timetable_slots (class_id, day_of_week, start_time, end_time, room_no, location) VALUES
(74, 'Monday', '09:00:00', '10:00:00', 'MB-3', 'Madhvacharya Bhavana'),
(75, 'Monday', '10:00:00', '11:00:00', 'MB-3', 'Madhvacharya Bhavana'),
(73, 'Monday', '11:30:00', '12:30:00', 'MB-3', 'Madhvacharya Bhavana'),
(81, 'Monday', '14:30:00', '16:30:00', NULL, 'CHE LAB-1'),
(80, 'Monday', '14:30:00', '16:30:00', NULL, 'PSC LAB-2'),
(77, 'Tuesday', '09:00:00', '10:00:00', 'MB-3', 'Madhvacharya Bhavana'),
(78, 'Tuesday', '11:30:00', '12:30:00', 'MB-3', 'Madhvacharya Bhavana'),
(84, 'Tuesday', '12:30:00', '13:30:00', 'MB-3', 'Madhvacharya Bhavana'),
(83, 'Tuesday', '14:30:00', '16:30:00', NULL, 'IDT LAB'),
(77, 'Wednesday', '09:00:00', '10:00:00', 'MB-3', 'Madhvacharya Bhavana'),
(74, 'Wednesday', '10:00:00', '11:00:00', 'MB-3', 'Madhvacharya Bhavana'),
(76, 'Wednesday', '11:30:00', '12:30:00', 'MB-3', 'Madhvacharya Bhavana'),
(73, 'Wednesday', '12:30:00', '13:30:00', 'MB-3', 'Madhvacharya Bhavana'),
(75, 'Wednesday', '14:30:00', '15:30:00', 'MB-3', 'Madhvacharya Bhavana'),
(74, 'Thursday', '10:00:00', '11:00:00', 'MB-3', 'Madhvacharya Bhavana'),
(82, 'Thursday', '14:30:00', '16:30:00', NULL, 'CHE LAB-2'),
(79, 'Thursday', '14:30:00', '16:30:00', NULL, 'PSC LAB-1'),
(75, 'Thursday', '12:30:00', '13:30:00', 'MB-3', 'Madhvacharya Bhavana'),
(76, 'Friday', '09:00:00', '10:00:00', 'MB-3', 'Madhvacharya Bhavana'),
(77, 'Friday', '10:00:00', '11:00:00', 'MB-3', 'Madhvacharya Bhavana'),
(73, 'Friday', '11:30:00', '12:30:00', 'MB-3', 'Madhvacharya Bhavana'),
(76, 'Friday', '14:30:00', '15:30:00', 'MB-3', 'Madhvacharya Bhavana'),
(73, 'Friday', '15:30:00', '16:30:00', 'MB-3', 'Madhvacharya Bhavana');

-- ---------------------------------
-- 1st Year CSE 'H' (IDs: 85-96)
-- ---------------------------------
INSERT INTO timetable_slots (class_id, day_of_week, start_time, end_time, room_no, location) VALUES
(89, 'Monday', '10:00:00', '11:00:00', 'MB-4', 'Madhvacharya Bhavana'),
(85, 'Monday', '11:30:00', '12:30:00', 'MB-4', 'Madhvacharya Bhavana'),
(87, 'Monday', '14:30:00', '15:30:00', 'MB-4', 'Madhvacharya Bhavana'),
(96, 'Monday', '15:30:00', '16:30:00', 'MB-4', 'Madhvacharya Bhavana'),
(85, 'Tuesday', '09:00:00', '10:00:00', 'MB-4', 'Madhvacharya Bhavana'),
(93, 'Tuesday', '10:00:00', '12:30:00', NULL, 'CHE LAB-1'),
(92, 'Tuesday', '10:00:00', '12:30:00', NULL, 'PSC LAB-2'),
(86, 'Tuesday', '14:30:00', '15:30:00', 'MB-4', 'Madhvacharya Bhavana'),
(88, 'Tuesday', '15:30:00', '16:30:00', 'MB-4', 'Madhvacharya Bhavana'),
(86, 'Wednesday', '10:00:00', '11:00:00', 'MB-4', 'Madhvacharya Bhavana'),
(85, 'Wednesday', '12:30:00', '13:30:00', 'MB-4', 'Madhvacharya Bhavana'),
(95, 'Wednesday', '14:30:00', '16:30:00', NULL, 'IDT LAB'),
(85, 'Thursday', '09:00:00', '10:00:00', 'MB-4', 'Madhvacharya Bhavana'),
(86, 'Thursday', '11:30:00', '12:30:00', 'MB-4', 'Madhvacharya Bhavana'),
(88, 'Thursday', '12:30:00', '13:30:00', 'MB-4', 'Madhvacharya Bhavana'),
(87, 'Thursday', '14:30:00', '15:30:00', 'MB-4', 'Madhvacharya Bhavana'),
(89, 'Thursday', '15:30:00', '16:30:00', 'MB-4', 'Madhvacharya Bhavana'),
(90, 'Friday', '09:00:00', '10:00:00', 'MB-4', 'Madhvacharya Bhavana'),
(88, 'Friday', '10:00:00', '11:00:00', 'MB-4', 'Madhvacharya Bhavana'),
(94, 'Friday', '11:30:00', '13:30:00', NULL, 'CHE LAB-2'),
(91, 'Friday', '11:30:00', '13:30:00', NULL, 'PSC LAB-1'),
(89, 'Friday', '14:30:00', '15:30:00', 'MB-4', 'Madhvacharya Bhavana'),
(87, 'Friday', '15:30:00', '16:30:00', 'MB-4', 'Madhvacharya Bhavana');

-- ---------------------------------
-- 1st Year AI&ML 'A' (IDs: 97-108)
-- ---------------------------------
INSERT INTO timetable_slots (class_id, day_of_week, start_time, end_time, room_no, location) VALUES
(100, 'Monday', '09:00:00', '10:00:00', 'MB-5', 'Madhvacharya Bhavana'),
(98, 'Monday', '10:00:00', '11:00:00', 'MB-5', 'Madhvacharya Bhavana'),
(97, 'Monday', '11:30:00', '12:30:00', 'MB-5', 'Madhvacharya Bhavana'),
(101, 'Monday', '14:30:00', '15:30:00', 'MB-5', 'Madhvacharya Bhavana'),
(99, 'Monday', '15:30:00', '16:30:00', 'MB-5', 'Madhvacharya Bhavana'),
(105, 'Tuesday', '10:00:00', '12:30:00', NULL, 'CHE LAB-1'),
(104, 'Tuesday', '10:00:00', '12:30:00', NULL, 'PSC LAB-2'),
(100, 'Tuesday', '12:30:00', '13:30:00', 'MB-5', 'Madhvacharya Bhavana'),
(99, 'Tuesday', '14:30:00', '15:30:00', 'MB-5', 'Madhvacharya Bhavana'),
(101, 'Wednesday', '09:00:00', '10:00:00', 'MB-5', 'Madhvacharya Bhavana'),
(98, 'Wednesday', '10:00:00', '11:00:00', 'MB-5', 'Madhvacharya Bhavana'),
(106, 'Wednesday', '11:30:00', '13:30:00', NULL, 'CHE LAB-2'),
(103, 'Wednesday', '11:30:00', '13:30:00', NULL, 'PSC LAB-1'),
(107, 'Wednesday', '14:30:00', '16:30:00', NULL, 'IDT LAB'),
(102, 'Thursday', '09:00:00', '10:00:00', 'MB-5', 'Madhvacharya Bhavana'),
(97, 'Thursday', '10:00:00', '11:00:00', 'MB-5', 'Madhvacharya Bhavana'),
(98, 'Thursday', '11:30:00', '12:30:00', 'MB-5', 'Madhvacharya Bhavana'),
(100, 'Thursday', '12:30:00', '13:30:00', 'MB-5', 'Madhvacharya Bhavana'),
(101, 'Thursday', '14:30:00', '15:30:00', 'MB-5', 'Madhvacharya Bhavana'),
(108, 'Thursday', '15:30:00', '16:30:00', 'MB-5', 'Madhvacharya Bhavana'),
(97, 'Friday', '09:00:00', '10:00:00', 'MB-5', 'Madhvacharya Bhavana'),
(97, 'Friday', '10:00:00', '11:00:00', 'MB-5', 'Madhvacharya Bhavana'),
(99, 'Friday', '12:30:00', '13:30:00', 'MB-5', 'Madhvacharya Bhavana');

-- ---------------------------------
-- 1st Year AI&ML 'B' (IDs: 109-120)
-- ---------------------------------
INSERT INTO timetable_slots (class_id, day_of_week, start_time, end_time, room_no, location) VALUES
(109, 'Monday', '10:00:00', '11:00:00', '201', 'Ramanujacharya Bhavan 1st Floor'),
(110, 'Monday', '11:30:00', '12:30:00', '201', 'Ramanujacharya Bhavan 1st Floor'),
(111, 'Monday', '12:30:00', '13:30:00', '201', 'Ramanujacharya Bhavan 1st Floor'),
(120, 'Monday', '14:30:00', '15:30:00', '201', 'Ramanujacharya Bhavan 1st Floor'),
(111, 'Tuesday', '09:00:00', '10:00:00', '201', 'Ramanujacharya Bhavan 1st Floor'),
(113, 'Tuesday', '10:00:00', '11:00:00', '201', 'Ramanujacharya Bhavan 1st Floor'),
(110, 'Tuesday', '11:30:00', '12:30:00', '201', 'Ramanujacharya Bhavan 1st Floor'),
(109, 'Tuesday', '14:30:00', '15:30:00', '201', 'Ramanujacharya Bhavan 1st Floor'),
(117, 'Wednesday', '09:00:00', '11:00:00', NULL, 'CHE LAB-1'),
(116, 'Wednesday', '09:00:00', '11:00:00', NULL, 'PSC LAB-2'),
(110, 'Wednesday', '11:30:00', '12:30:00', '201', 'Ramanujacharya Bhavan 1st Floor'),
(112, 'Wednesday', '12:30:00', '13:30:00', '201', 'Ramanujacharya Bhavan 1st Floor'),
(109, 'Thursday', '09:00:00', '10:00:00', '201', 'Ramanujacharya Bhavan 1st Floor'),
(112, 'Thursday', '10:00:00', '11:00:00', '201', 'Ramanujacharya Bhavan 1st Floor'),
(118, 'Thursday', '11:30:00', '13:30:00', NULL, 'CHE LAB-2'),
(115, 'Thursday', '11:30:00', '13:30:00', NULL, 'PSC LAB-1'),
(114, 'Thursday', '14:30:00', '15:30:00', '201', 'Ramanujacharya Bhavan 1st Floor'),
(111, 'Thursday', '15:30:00', '16:30:00', '201', 'Ramanujacharya Bhavan 1st Floor'),
(113, 'Friday', '09:00:00', '10:00:00', '201', 'Ramanujacharya Bhavan 1st Floor'),
(112, 'Friday', '10:00:00', '11:00:00', '201', 'Ramanujacharya Bhavan 1st Floor'),
(109, 'Friday', '12:30:00', '13:30:00', '201', 'Ramanujacharya Bhavan 1st Floor'),
(119, 'Friday', '14:30:00', '16:30:00', NULL, 'IDT LAB');

-- =================================================================
-- DATA ENTRY - TIMETABLE SLOTS (2nd Year / 3rd Semester)
-- =================================================================

-- ---------------------------------
-- 2nd Year CSE 'A' (IDs: 121-142) [File: 3rd final, Page 1]
-- ---------------------------------
INSERT INTO timetable_slots (class_id, day_of_week, start_time, end_time, room_no, location) VALUES
(139, 'Monday', '09:00:00', '10:00:00', '202', 'Ramanujacharya Bhavan 1st Floor'),
(121, 'Monday', '10:00:00', '11:00:00', '202', 'Ramanujacharya Bhavan 1st Floor'),
(129, 'Monday', '11:30:00', '13:30:00', NULL, 'OS Lab (A3)'),
(132, 'Monday', '11:30:00', '13:30:00', NULL, 'DSC Lab (A2)'),
(123, 'Monday', '14:30:00', '16:30:00', NULL, 'DDCO Lab (A1)'),
(128, 'Monday', '14:30:00', '16:30:00', NULL, 'OS Lab (A2)'),
(124, 'Tuesday', '09:00:00', '11:00:00', NULL, 'DDCO Lab (A2)'),
(137, 'Tuesday', '09:00:00', '11:00:00', NULL, 'JAVA Lab (A3)'),
(131, 'Tuesday', '09:00:00', '11:00:00', NULL, 'DSC Lab (A1)'),
(121, 'Tuesday', '11:30:00', '12:30:00', '202', 'Ramanujacharya Bhavan 1st Floor'),
(134, 'Tuesday', '12:30:00', '13:30:00', '202', 'Ramanujacharya Bhavan 1st Floor'),
(130, 'Wednesday', '09:00:00', '10:00:00', '202', 'Ramanujacharya Bhavan 1st Floor'),
(126, 'Wednesday', '10:00:00', '11:00:00', '202', 'Ramanujacharya Bhavan 1st Floor'),
(122, 'Wednesday', '11:30:00', '12:30:00', '202', 'Ramanujacharya Bhavan 1st Floor'),
(138, 'Wednesday', '12:30:00', '13:30:00', '202', 'Ramanujacharya Bhavan 1st Floor'),
(121, 'Wednesday', '14:30:00', '15:30:00', '202', 'Ramanujacharya Bhavan 1st Floor'),
(134, 'Thursday', '09:00:00', '10:00:00', '202', 'Ramanujacharya Bhavan 1st Floor'),
(130, 'Thursday', '10:00:00', '11:00:00', '202', 'Ramanujacharya Bhavan 1st Floor'),
(125, 'Thursday', '11:30:00', '13:30:00', NULL, 'DDCO Lab (A3)'),
(136, 'Thursday', '11:30:00', '13:30:00', NULL, 'JAVA Lab (A2)'),
(122, 'Thursday', '12:30:00', '13:30:00', '202', 'Ramanujacharya Bhavan 1st Floor'),
(126, 'Thursday', '14:30:00', '15:30:00', '202', 'Ramanujacharya Bhavan 1st Floor'),
(127, 'Thursday', '15:30:00', '17:30:00', NULL, 'OS Lab (A1)'), -- 15:30-17:30
(126, 'Friday', '09:00:00', '10:00:00', '202', 'Ramanujacharya Bhavan 1st Floor'),
(122, 'Friday', '10:00:00', '11:00:00', '202', 'Ramanujacharya Bhavan 1st Floor'),
(121, 'Friday', '11:30:00', '12:30:00', '202', 'Ramanujacharya Bhavan 1st Floor'),
(130, 'Friday', '12:30:00', '13:30:00', '202', 'Ramanujacharya Bhavan 1st Floor');
-- Saturday Activity Points (140, 141, 142) ignored as they are not fixed slots

-- ---------------------------------
-- 2nd Year CSE 'B' (IDs: 143-161) [File: 3rd final, Page 2]
-- ---------------------------------
INSERT INTO timetable_slots (class_id, day_of_week, start_time, end_time, room_no, location) VALUES
(145, 'Monday', '09:00:00', '11:00:00', NULL, 'DDCO Lab (B1)'),
(154, 'Monday', '09:00:00', '11:00:00', NULL, 'DSC Lab (B2)'),
(151, 'Monday', '09:00:00', '11:00:00', NULL, 'OS Lab (B3)'),
(143, 'Monday', '11:30:00', '12:30:00', '203', 'Ramanujacharya Bhavan 1st Floor'),
(152, 'Monday', '12:30:00', '13:30:00', '203', 'Ramanujacharya Bhavan 1st Floor'),
(144, 'Monday', '14:30:00', '15:30:00', '203', 'Ramanujacharya Bhavan 1st Floor'),
(161, 'Monday', '15:30:00', '16:30:00', '203', 'Ramanujacharya Bhavan 1st Floor'),
(143, 'Tuesday', '09:00:00', '10:00:00', '203', 'Ramanujacharya Bhavan 1st Floor'),
(144, 'Tuesday', '10:00:00', '11:00:00', '203', 'Ramanujacharya Bhavan 1st Floor'),
(148, 'Tuesday', '11:30:00', '12:30:00', '203', 'Ramanujacharya Bhavan 1st Floor'),
(152, 'Tuesday', '12:30:00', '13:30:00', '203', 'Ramanujacharya Bhavan 1st Floor'),
(143, 'Tuesday', '15:30:00', '16:30:00', '203', 'Ramanujacharya Bhavan 1st Floor'),
(146, 'Wednesday', '09:00:00', '11:00:00', NULL, 'DDCO Lab (B2)'),
(159, 'Wednesday', '09:00:00', '11:00:00', NULL, 'JAVA Lab (B3)'),
(153, 'Wednesday', '09:00:00', '11:00:00', NULL, 'DSC Lab (B1)'),
(149, 'Wednesday', '11:30:00', '13:30:00', NULL, 'OS Lab (B1)'),
(158, 'Wednesday', '11:30:00', '13:30:00', NULL, 'JAVA Lab (B2)'),
(147, 'Wednesday', '11:30:00', '13:30:00', NULL, 'DDCO Lab (B3)'),
(156, 'Thursday', '09:00:00', '10:00:00', '203', 'Ramanujacharya Bhavan 1st Floor'),
(160, 'Thursday', '10:00:00', '11:00:00', '203', 'Ramanujacharya Bhavan 1st Floor'),
(148, 'Thursday', '11:30:00', '12:30:00', '203', 'Ramanujacharya Bhavan 1st Floor'),
(143, 'Thursday', '12:30:00', '13:30:00', '203', 'Ramanujacharya Bhavan 1st Floor'),
(144, 'Thursday', '14:30:00', '15:30:00', '203', 'Ramanujacharya Bhavan 1st Floor'),
(152, 'Thursday', '15:30:00', '16:30:00', '203', 'Ramanujacharya Bhavan 1st Floor'),
(156, 'Friday', '09:00:00', '10:00:00', '203', 'Ramanujacharya Bhavan 1st Floor'),
(148, 'Friday', '10:00:00', '11:00:00', '203', 'Ramanujacharya Bhavan 1st Floor'),
(155, 'Friday', '11:30:00', '13:30:00', NULL, 'DSC Lab (B3)'),
(150, 'Friday', '11:30:00', '13:30:00', NULL, 'OS Lab (B2)'),
(157, 'Friday', '11:30:00', '13:30:00', NULL, 'JAVA Lab (B1)');

-- ---------------------------------
-- 2nd Year CSE 'C' (IDs: 162-180) [File: 3rd final, Page 3]
-- ---------------------------------
INSERT INTO timetable_slots (class_id, day_of_week, start_time, end_time, room_no, location) VALUES
(180, 'Monday', '09:00:00', '10:00:00', '204', 'Ramanujacharya Bhavan 1st Floor'),
(175, 'Monday', '10:00:00', '11:00:00', '204', 'Ramanujacharya Bhavan 1st Floor'),
(162, 'Monday', '11:30:00', '12:30:00', '204', 'Ramanujacharya Bhavan 1st Floor'),
(171, 'Monday', '12:30:00', '13:30:00', '204', 'Ramanujacharya Bhavan 1st Floor'),
(163, 'Monday', '14:30:00', '15:30:00', '204', 'Ramanujacharya Bhavan 1st Floor'),
(162, 'Tuesday', '09:00:00', '10:00:00', '204', 'Ramanujacharya Bhavan 1st Floor'),
(167, 'Tuesday', '10:00:00', '11:00:00', '204', 'Ramanujacharya Bhavan 1st Floor'),
(168, 'Tuesday', '11:30:00', '13:30:00', NULL, 'OS Lab (C1)'),
(174, 'Tuesday', '11:30:00', '13:30:00', NULL, 'DSC Lab (C3)'),
(165, 'Tuesday', '11:30:00', '13:30:00', NULL, 'DDCO Lab (C2)'),
(179, 'Tuesday', '14:30:00', '15:30:00', '204', 'Ramanujacharya Bhavan 1st Floor'),
(162, 'Wednesday', '09:00:00', '10:00:00', '204', 'Ramanujacharya Bhavan 1st Floor'),
(162, 'Wednesday', '10:00:00', '11:00:00', '204', 'Ramanujacharya Bhavan 1st Floor'), -- MATHS TUTORIAL
(177, 'Wednesday', '11:30:00', '13:30:00', NULL, 'JAVA Lab (C2)'),
(170, 'Wednesday', '11:30:00', '13:30:00', NULL, 'OS Lab (C3)'),
(172, 'Wednesday', '11:30:00', '13:30:00', NULL, 'DSC Lab (C1)'),
(166, 'Wednesday', '14:30:00', '16:30:00', NULL, 'DDCO Lab (C3)'),
(169, 'Wednesday', '14:30:00', '16:30:00', NULL, 'OS Lab (C2)'),
(176, 'Wednesday', '14:30:00', '16:30:00', NULL, 'JAVA Lab (C1)'),
(163, 'Thursday', '09:00:00', '10:00:00', '204', 'Ramanujacharya Bhavan 1st Floor'),
(167, 'Thursday', '10:00:00', '11:00:00', '204', 'Ramanujacharya Bhavan 1st Floor'),
(162, 'Thursday', '11:30:00', '12:30:00', '204', 'Ramanujacharya Bhavan 1st Floor'),
(171, 'Thursday', '12:30:00', '13:30:00', '204', 'Ramanujacharya Bhavan 1st Floor'),
(175, 'Friday', '09:00:00', '10:00:00', '204', 'Ramanujacharya Bhavan 1st Floor'),
(163, 'Friday', '10:00:00', '11:00:00', '204', 'Ramanujacharya Bhavan 1st Floor'),
(167, 'Friday', '11:30:00', '12:30:00', '204', 'Ramanujacharya Bhavan 1st Floor'),
(171, 'Friday', '12:30:00', '13:30:00', '204', 'Ramanujacharya Bhavan 1st Floor'),
(164, 'Friday', '14:30:00', '16:30:00', NULL, 'DDCO Lab (C1)'),
(173, 'Friday', '14:30:00', '16:30:00', NULL, 'DSC Lab (C2)'),
(178, 'Friday', '14:30:00', '16:30:00', NULL, 'JAVA Lab (C3)');

-- ---------------------------------
-- 2nd Year CSE 'D' (IDs: 181-199) [File: 3rd final, Page 4]
-- ---------------------------------
INSERT INTO timetable_slots (class_id, day_of_week, start_time, end_time, room_no, location) VALUES
(182, 'Monday', '09:00:00', '10:00:00', '203', 'Ramanujacharya Bhavan 1st Floor'),
(194, 'Monday', '10:00:00', '11:00:00', '305', 'Ramanujacharya Bhavan 2nd Floor'),
(186, 'Monday', '11:30:00', '12:30:00', '305', 'Ramanujacharya Bhavan 2nd Floor'),
(188, 'Monday', '14:30:00', '16:30:00', NULL, 'OS Lab (D2)'),
(191, 'Monday', '14:30:00', '16:30:00', NULL, 'DSC Lab (D1)'),
(197, 'Monday', '14:30:00', '16:30:00', NULL, 'JAVA Lab (D3)'),
(190, 'Tuesday', '09:00:00', '10:00:00', '203', 'Ramanujacharya Bhavan 1st Floor'),
(182, 'Tuesday', '10:00:00', '11:00:00', '305', 'Ramanujacharya Bhavan 2nd Floor'),
(199, 'Tuesday', '11:30:00', '12:30:00', '305', 'Ramanujacharya Bhavan 2nd Floor'),
(190, 'Tuesday', '12:30:00', '13:30:00', '305', 'Ramanujacharya Bhavan 2nd Floor'),
(198, 'Tuesday', '14:30:00', '15:30:00', '305', 'Ramanujacharya Bhavan 2nd Floor'),
(182, 'Wednesday', '09:00:00', '10:00:00', '203', 'Ramanujacharya Bhavan 1st Floor'),
(190, 'Wednesday', '10:00:00', '11:00:00', '203', 'Ramanujacharya Bhavan 1st Floor'),
(181, 'Wednesday', '11:30:00', '12:30:00', '305', 'Ramanujacharya Bhavan 2nd Floor'),
(194, 'Wednesday', '12:30:00', '13:30:00', '305', 'Ramanujacharya Bhavan 2nd Floor'),
(186, 'Wednesday', '14:30:00', '15:30:00', '305', 'Ramanujacharya Bhavan 2nd Floor'),
(192, 'Wednesday', '15:30:00', '17:30:00', NULL, 'DSC Lab (D2)'), -- 15:30-17:30
(184, 'Wednesday', '15:30:00', '17:30:00', NULL, 'DDCO Lab (D2)'), -- 15:30-17:30
(181, 'Thursday', '09:00:00', '10:00:00', '308', 'Ramanujacharya Bhavan 2nd Floor'),
(187, 'Thursday', '11:30:00', '13:30:00', NULL, 'OS Lab (D1)'),
(185, 'Thursday', '11:30:00', '13:30:00', NULL, 'DDCO Lab (D3)'),
(195, 'Thursday', '14:30:00', '16:30:00', NULL, 'JAVA Lab (D1)'),
(189, 'Thursday', '14:30:00', '16:30:00', NULL, 'OS Lab (D3)'),
(196, 'Friday', '09:00:00', '11:00:00', NULL, 'JAVA Lab (D2)'),
(183, 'Friday', '09:00:00', '11:00:00', NULL, 'DDCO Lab (D1)'),
(193, 'Friday', '09:00:00', '11:00:00', NULL, 'DSC Lab (D3)'),
(181, 'Friday', '11:30:00', '12:30:00', '305', 'Ramanujacharya Bhavan 2nd Floor'),
(186, 'Friday', '12:30:00', '13:30:00', '305', 'Ramanujacharya Bhavan 2nd Floor'),
(181, 'Friday', '14:30:00', '15:30:00', '305', 'Ramanujacharya Bhavan 2nd Floor'); -- MATHS TUTORIAL

-- ---------------------------------
-- 2nd Year AI&ML 'E' (IDs: 200-218) [File: 3rd final, Page 5]
-- ---------------------------------
INSERT INTO timetable_slots (class_id, day_of_week, start_time, end_time, room_no, location) VALUES
(201, 'Monday', '09:00:00', '10:00:00', '401', 'Ramanujacharya Bhavan 3rd Floor'),
(213, 'Monday', '10:00:00', '11:00:00', '401', 'Ramanujacharya Bhavan 3rd Floor'),
(206, 'Monday', '11:30:00', '13:30:00', NULL, 'OS Lab (E1)'),
(204, 'Monday', '11:30:00', '13:30:00', NULL, 'DDCO Lab (E3)'),
(205, 'Monday', '14:30:00', '15:30:00', '401', 'Ramanujacharya Bhavan 3rd Floor'),
(200, 'Monday', '15:30:00', '16:30:00', '401', 'Ramanujacharya Bhavan 3rd Floor'),
(205, 'Tuesday', '09:00:00', '10:00:00', '401', 'Ramanujacharya Bhavan 3rd Floor'),
(200, 'Tuesday', '10:00:00', '11:00:00', '401', 'Ramanujacharya Bhavan 3rd Floor'),
(209, 'Tuesday', '11:30:00', '12:30:00', '401', 'Ramanujacharya Bhavan 3rd Floor'),
(201, 'Tuesday', '12:30:00', '13:30:00', '401', 'Ramanujacharya Bhavan 3rd Floor'),
(203, 'Tuesday', '14:30:00', '16:30:00', NULL, 'DDCO Lab (E2)'),
(201, 'Wednesday', '09:00:00', '10:00:00', '401', 'Ramanujacharya Bhavan 3rd Floor'),
(213, 'Wednesday', '10:00:00', '11:00:00', '401', 'Ramanujacharya Bhavan 3rd Floor'),
(209, 'Wednesday', '11:30:00', '12:30:00', '401', 'Ramanujacharya Bhavan 3rd Floor'),
(218, 'Wednesday', '12:30:00', '13:30:00', '401', 'Ramanujacharya Bhavan 3rd Floor'),
(214, 'Wednesday', '14:30:00', '16:30:00', NULL, 'JAVA Lab (E1)'),
(207, 'Wednesday', '14:30:00', '16:30:00', NULL, 'OS Lab (E2)'),
(215, 'Thursday', '09:00:00', '11:00:00', NULL, 'JAVA Lab (E2)'),
(212, 'Thursday', '09:00:00', '11:00:00', NULL, 'DSC Lab (E3)'),
(202, 'Thursday', '09:00:00', '11:00:00', NULL, 'DDCO Lab (E1)'),
(200, 'Thursday', '11:30:00', '12:30:00', '401', 'Ramanujacharya Bhavan 3rd Floor'),
(209, 'Thursday', '12:30:00', '13:30:00', '401', 'Ramanujacharya Bhavan 3rd Floor'),
(205, 'Thursday', '14:30:00', '15:30:00', '401', 'Ramanujacharya Bhavan 3rd Floor'),
(217, 'Thursday', '15:30:00', '16:30:00', '401', 'Ramanujacharya Bhavan 3rd Floor'),
(211, 'Friday', '09:00:00', '11:00:00', NULL, 'DSC Lab (E2)'),
(208, 'Friday', '09:00:00', '11:00:00', NULL, 'OS Lab (E3)'),
(200, 'Friday', '11:30:00', '12:30:00', '401', 'Ramanujacharya Bhavan 3rd Floor'),
(210, 'Friday', '14:30:00', '16:30:00', NULL, 'DSC Lab (E1)'),
(216, 'Friday', '14:30:00', '16:30:00', NULL, 'JAVA Lab (E3)');

-- ---------------------------------
-- 2nd Year AI&ML 'F' (IDs: 219-237) [File: 3rd final, Page 6]
-- ---------------------------------
INSERT INTO timetable_slots (class_id, day_of_week, start_time, end_time, room_no, location) VALUES
(237, 'Monday', '09:00:00', '10:00:00', '106', 'North Campus, 1st Floor'),
(228, 'Monday', '10:00:00', '11:00:00', '106', 'North Campus, 1st Floor'),
(224, 'Monday', '11:30:00', '12:30:00', '202', 'Ramanujacharya Bhavan 1st Floor'),
(220, 'Monday', '12:30:00', '13:30:00', '202', 'Ramanujacharya Bhavan 1st Floor'),
(219, 'Monday', '14:30:00', '15:30:00', '202', 'Ramanujacharya Bhavan 1st Floor'),
(219, 'Tuesday', '09:00:00', '10:00:00', '202', 'Ramanujacharya Bhavan 1st Floor'),
(220, 'Tuesday', '10:00:00', '11:00:00', '202', 'Ramanujacharya Bhavan 1st Floor'),
(224, 'Tuesday', '11:30:00', '12:30:00', '204', 'Ramanujacharya Bhavan 1st Floor'),
(232, 'Tuesday', '12:30:00', '13:30:00', '204', 'Ramanujacharya Bhavan 1st Floor'),
(222, 'Tuesday', '14:30:00', '16:30:00', NULL, 'DDCO Lab (F2)'),
(229, 'Tuesday', '14:30:00', '16:30:00', NULL, 'DSC Lab (F1)'),
(227, 'Tuesday', '14:30:00', '16:30:00', NULL, 'OS Lab (F3)'),
(234, 'Wednesday', '09:00:00', '11:00:00', NULL, 'JAVA Lab (F2)'),
(231, 'Wednesday', '09:00:00', '11:00:00', NULL, 'DSC Lab (F3)'),
(225, 'Wednesday', '09:00:00', '11:00:00', NULL, 'OS Lab (F1)'),
(228, 'Wednesday', '11:30:00', '12:30:00', '204', 'Ramanujacharya Bhavan 1st Floor'),
(224, 'Wednesday', '12:30:00', '13:30:00', '204', 'Ramanujacharya Bhavan 1st Floor'),
(220, 'Thursday', '09:00:00', '10:00:00', '401', 'Ramanujacharya Bhavan 3rd Floor'),
(219, 'Thursday', '10:00:00', '11:00:00', '401', 'Ramanujacharya Bhavan 3rd Floor'),
(232, 'Thursday', '11:30:00', '12:30:00', '202', 'Ramanujacharya Bhavan 1st Floor'),
(228, 'Thursday', '12:30:00', '13:30:00', '202', 'Ramanujacharya Bhavan 1st Floor'),
(221, 'Friday', '09:00:00', '11:00:00', NULL, 'DDCO Lab (F1)'),
(235, 'Friday', '09:00:00', '11:00:00', NULL, 'JAVA Lab (F3)'),
(226, 'Friday', '09:00:00', '11:00:00', NULL, 'OS Lab (F2)'),
(219, 'Friday', '11:30:00', '12:30:00', '401', 'Ramanujacharya Bhavan 3rd Floor'),
(236, 'Friday', '12:30:00', '13:30:00', '401', 'Ramanujacharya Bhavan 3rd Floor'),
(223, 'Friday', '14:30:00', '16:30:00', NULL, 'DDCO Lab (F3)'),
(233, 'Friday', '14:30:00', '16:30:00', NULL, 'JAVA Lab (F1)'),
(230, 'Friday', '14:30:00', '16:30:00', NULL, 'DSC Lab (F2)');

-- ---------------------------------
-- 2nd Year ISE 'A' (IDs: 238-255) [File: 3rd Sem TT, Page 1]
-- ---------------------------------
INSERT INTO timetable_slots (class_id, day_of_week, start_time, end_time, room_no, location) VALUES
(240, 'Monday', '09:00:00', '11:00:00', NULL, 'DD&CO Lab (A1)'),
(245, 'Monday', '09:00:00', '11:00:00', NULL, 'OS Lab (A2)'),
(255, 'Monday', '09:00:00', '11:00:00', NULL, 'DS Lab (A3)'),
(239, 'Monday', '11:30:00', '12:30:00', '402', 'Ramanujacharya Bhavan 3rd Floor'),
(238, 'Monday', '12:30:00', '13:30:00', '402', 'Ramanujacharya Bhavan 3rd Floor'),
(247, 'Monday', '14:30:00', '15:30:00', '402', 'Ramanujacharya Bhavan 3rd Floor'),
(243, 'Monday', '15:30:00', '16:30:00', '402', 'Ramanujacharya Bhavan 3rd Floor'),
(251, 'Tuesday', '09:00:00', '10:00:00', '402', 'Ramanujacharya Bhavan 3rd Floor'),
(248, 'Tuesday', '10:00:00', '11:00:00', '402', 'Ramanujacharya Bhavan 3rd Floor'),
(241, 'Tuesday', '11:30:00', '13:30:00', NULL, 'DD&CO Lab (A2)'),
(246, 'Tuesday', '11:30:00', '13:30:00', NULL, 'OS Lab (A3)'),
(253, 'Tuesday', '11:30:00', '13:30:00', NULL, 'DS Lab (A1)'),
(238, 'Tuesday', '14:30:00', '15:30:00', '402', 'Ramanujacharya Bhavan 3rd Floor'),
(252, 'Tuesday', '15:30:00', '16:30:00', '402', 'Ramanujacharya Bhavan 3rd Floor'),
(239, 'Wednesday', '09:00:00', '10:00:00', '402', 'Ramanujacharya Bhavan 3rd Floor'),
(243, 'Wednesday', '10:00:00', '11:00:00', '402', 'Ramanujacharya Bhavan 3rd Floor'),
(248, 'Wednesday', '11:30:00', '12:30:00', '402', 'Ramanujacharya Bhavan 3rd Floor'),
(247, 'Wednesday', '12:30:00', '13:30:00', '402', 'Ramanujacharya Bhavan 3rd Floor'),
(242, 'Wednesday', '14:30:00', '16:30:00', NULL, 'DD&CO Lab (A3)'),
(244, 'Wednesday', '14:30:00', '16:30:00', NULL, 'OS Lab (A1)'),
(254, 'Wednesday', '14:30:00', '16:30:00', NULL, 'DS Lab (A2)'),
(238, 'Thursday', '09:00:00', '10:00:00', '402', 'Ramanujacharya Bhavan 3rd Floor'),
(247, 'Thursday', '11:30:00', '12:30:00', '402', 'Ramanujacharya Bhavan 3rd Floor'),
(243, 'Thursday', '12:30:00', '13:30:00', '402', 'Ramanujacharya Bhavan 3rd Floor'),
(239, 'Friday', '09:00:00', '10:00:00', '402', 'Ramanujacharya Bhavan 3rd Floor'),
(249, 'Friday', '09:00:00', '11:00:00', NULL, 'OOPJ Lab (A1)'),
(250, 'Friday', '09:00:00', '11:00:00', NULL, 'OOPJ Lab (A2)'),
(238, 'Friday', '12:30:00', '13:30:00', '402', 'Ramanujacharya Bhavan 3rd Floor');

-- ---------------------------------
-- 2nd Year ISE 'B' (IDs: 256-273) [File: 3rd Sem TT, Page 2]
-- ---------------------------------
INSERT INTO timetable_slots (class_id, day_of_week, start_time, end_time, room_no, location) VALUES
(269, 'Monday', '09:00:00', '10:00:00', '403', 'Ramanujacharya Bhavan 3rd Floor'),
(266, 'Monday', '10:00:00', '11:00:00', '403', 'Ramanujacharya Bhavan 3rd Floor'),
(258, 'Monday', '11:30:00', '13:30:00', NULL, 'DD&CO Lab (B1)'),
(263, 'Monday', '11:30:00', '13:30:00', NULL, 'OS Lab (B2)'),
(273, 'Monday', '11:30:00', '13:30:00', NULL, 'DS Lab (B3)'),
(270, 'Monday', '14:30:00', '15:30:00', '403', 'Ramanujacharya Bhavan 3rd Floor'),
(256, 'Monday', '15:30:00', '16:30:00', '403', 'Ramanujacharya Bhavan 3rd Floor'),
(257, 'Tuesday', '09:00:00', '10:00:00', '403', 'Ramanujacharya Bhavan 3rd Floor'),
(261, 'Tuesday', '10:00:00', '11:00:00', '403', 'Ramanujacharya Bhavan 3rd Floor'),
(265, 'Tuesday', '11:30:00', '12:30:00', '403', 'Ramanujacharya Bhavan 3rd Floor'),
(266, 'Tuesday', '12:30:00', '13:30:00', '403', 'Ramanujacharya Bhavan 3rd Floor'),
(259, 'Tuesday', '14:30:00', '16:30:00', NULL, 'DD&CO Lab (B2)'),
(264, 'Tuesday', '14:30:00', '16:30:00', NULL, 'OS Lab (B3)'),
(271, 'Tuesday', '14:30:00', '16:30:00', NULL, 'DS Lab (B1)'),
(260, 'Wednesday', '09:00:00', '11:00:00', NULL, 'DD&CO Lab (B3)'),
(262, 'Wednesday', '09:00:00', '11:00:00', NULL, 'OS Lab (B1)'),
(272, 'Wednesday', '09:00:00', '11:00:00', NULL, 'DS Lab (B2)'),
(257, 'Wednesday', '11:30:00', '12:30:00', '403', 'Ramanujacharya Bhavan 3rd Floor'),
(256, 'Wednesday', '12:30:00', '13:30:00', '403', 'Ramanujacharya Bhavan 3rd Floor'),
(265, 'Wednesday', '14:30:00', '15:30:00', '403', 'Ramanujacharya Bhavan 3rd Floor'),
(261, 'Wednesday', '15:30:00', '16:30:00', '403', 'Ramanujacharya Bhavan 3rd Floor'),
(256, 'Thursday', '10:00:00', '11:00:00', '403', 'Ramanujacharya Bhavan 3rd Floor'),
(267, 'Thursday', '11:30:00', '13:30:00', NULL, 'OOPJ Lab (B1)'),
(268, 'Thursday', '11:30:00', '13:30:00', NULL, 'OOPJ Lab (B2)'),
(257, 'Friday', '09:00:00', '10:00:00', '403', 'Ramanujacharya Bhavan 3rd Floor'),
(256, 'Friday', '10:00:00', '11:00:00', '403', 'Ramanujacharya Bhavan 3rd Floor'),
(265, 'Friday', '11:30:00', '12:30:00', '403', 'Ramanujacharya Bhavan 3rd Floor'),
(261, 'Friday', '12:30:00', '13:30:00', '403', 'Ramanujacharya Bhavan 3rd Floor');

-- ---------------------------------
-- 2nd Year ISE 'C' (IDs: 274-291) [File: 3rd Sem TT, Page 3]
-- ---------------------------------
INSERT INTO timetable_slots (class_id, day_of_week, start_time, end_time, room_no, location) VALUES
(274, 'Monday', '09:00:00', '10:00:00', '404', 'Ramanujacharya Bhavan 3rd Floor'),
(275, 'Monday', '10:00:00', '11:00:00', '404', 'Ramanujacharya Bhavan 3rd Floor'),
(283, 'Monday', '11:30:00', '12:30:00', '404', 'Ramanujacharya Bhavan 3rd Floor'),
(279, 'Monday', '12:30:00', '13:30:00', '404', 'Ramanujacharya Bhavan 3rd Floor'),
(283, 'Monday', '14:30:00', '15:30:00', '404', 'Ramanujacharya Bhavan 3rd Floor'),
(279, 'Monday', '15:30:00', '16:30:00', '404', 'Ramanujacharya Bhavan 3rd Floor'),
(276, 'Tuesday', '09:00:00', '11:00:00', NULL, 'DD&CO Lab (C1)'),
(281, 'Tuesday', '09:00:00', '11:00:00', NULL, 'OS Lab (C2)'),
(291, 'Tuesday', '09:00:00', '11:00:00', NULL, 'DS Lab (C3)'),
(275, 'Tuesday', '11:30:00', '12:30:00', '404', 'Ramanujacharya Bhavan 3rd Floor'),
(274, 'Tuesday', '12:30:00', '13:30:00', '404', 'Ramanujacharya Bhavan 3rd Floor'),
(284, 'Tuesday', '14:30:00', '15:30:00', '404', 'Ramanujacharya Bhavan 3rd Floor'),
(288, 'Tuesday', '15:30:00', '16:30:00', '404', 'Ramanujacharya Bhavan 3rd Floor'),
(274, 'Wednesday', '09:00:00', '10:00:00', '404', 'Ramanujacharya Bhavan 3rd Floor'),
(287, 'Wednesday', '10:00:00', '11:00:00', '404', 'Ramanujacharya Bhavan 3rd Floor'),
(277, 'Wednesday', '11:30:00', '13:30:00', NULL, 'DD&CO Lab (C2)'),
(282, 'Wednesday', '11:30:00', '13:30:00', NULL, 'OS Lab (C3)'),
(289, 'Wednesday', '11:30:00', '13:30:00', NULL, 'DS Lab (C1)'),
(278, 'Wednesday', '14:30:00', '16:30:00', NULL, 'DD&CO Lab (C3)'),
(275, 'Thursday', '09:00:00', '10:00:00', '404', 'Ramanujacharya Bhavan 3rd Floor'),
(279, 'Thursday', '10:00:00', '11:00:00', '404', 'Ramanujacharya Bhavan 3rd Floor'),
(284, 'Thursday', '11:30:00', '12:30:00', '404', 'Ramanujacharya Bhavan 3rd Floor'),
(274, 'Thursday', '12:30:00', '13:30:00', '404', 'Ramanujacharya Bhavan 3rd Floor'),
(285, 'Friday', '09:00:00', '11:00:00', NULL, 'OOPJ Lab (C1)'),
(286, 'Friday', '09:00:00', '11:00:00', NULL, 'OOPJ Lab (C2)'),
(283, 'Friday', '11:30:00', '12:30:00', '404', 'Ramanujacharya Bhavan 3rd Floor'),
(274, 'Friday', '12:30:00', '13:30:00', '404', 'Ramanujacharya Bhavan 3rd Floor'),
(280, 'Friday', '14:30:00', '16:30:00', NULL, 'OS Lab (C1)'),
(290, 'Friday', '14:30:00', '16:30:00', NULL, 'DS Lab (C2)');

-- ---------------------------------
-- 2nd Year ISE 'D' (IDs: 292-309) [File: 3rd Sem TT, Page 4]
-- ---------------------------------
INSERT INTO timetable_slots (class_id, day_of_week, start_time, end_time, room_no, location) VALUES
(293, 'Monday', '09:00:00', '10:00:00', '402', 'Ramanujacharya Bhavan 3rd Floor'),
(301, 'Monday', '10:00:00', '11:00:00', '402', 'Ramanujacharya Bhavan 3rd Floor'),
(297, 'Monday', '11:30:00', '12:30:00', '403', 'Ramanujacharya Bhavan 3rd Floor'),
(302, 'Monday', '12:30:00', '13:30:00', '403', 'Ramanujacharya Bhavan 3rd Floor'),
(294, 'Monday', '14:30:00', '16:30:00', NULL, 'DD&CO Lab (D1)'),
(299, 'Monday', '14:30:00', '16:30:00', NULL, 'OS Lab (D2)'),
(309, 'Monday', '14:30:00', '16:30:00', NULL, 'DS Lab (D3)'),
(303, 'Tuesday', '09:00:00', '11:00:00', NULL, 'OOPJ Lab (D1)'),
(297, 'Tuesday', '11:30:00', '12:30:00', '402', 'Ramanujacharya Bhavan 3rd Floor'),
(301, 'Tuesday', '12:30:00', '13:30:00', '402', 'Ramanujacharya Bhavan 3rd Floor'),
(293, 'Tuesday', '14:30:00', '15:30:00', '403', 'Ramanujacharya Bhavan 3rd Floor'),
(292, 'Tuesday', '15:30:00', '16:30:00', '403', 'Ramanujacharya Bhavan 3rd Floor'),
(304, 'Wednesday', '09:00:00', '11:00:00', NULL, 'OOPJ Lab (D2)'),
(295, 'Wednesday', '09:00:00', '11:00:00', NULL, 'DD&CO Lab (D2)'),
(300, 'Wednesday', '09:00:00', '11:00:00', NULL, 'OS Lab (D3)'),
(307, 'Wednesday', '09:00:00', '11:00:00', NULL, 'DS Lab (D1)'),
(292, 'Wednesday', '11:30:00', '12:30:00', '404', 'Ramanujacharya Bhavan 3rd Floor'),
(293, 'Wednesday', '14:30:00', '15:30:00', '402', 'Ramanujacharya Bhavan 3rd Floor'),
(301, 'Wednesday', '15:30:00', '16:30:00', '402', 'Ramanujacharya Bhavan 3rd Floor'),
(302, 'Thursday', '09:00:00', '10:00:00', '402', 'Ramanujacharya Bhavan 3rd Floor'),
(305, 'Thursday', '10:00:00', '11:00:00', '402', 'Ramanujacharya Bhavan 3rd Floor'),
(292, 'Thursday', '11:30:00', '12:30:00', '404', 'Ramanujacharya Bhavan 3rd Floor'),
(292, 'Thursday', '12:30:00', '13:30:00', '403', 'Ramanujacharya Bhavan 3rd Floor'), -- MCS Tutorial
(297, 'Thursday', '14:30:00', '15:30:00', '403', 'Ramanujacharya Bhavan 3rd Floor'),
(292, 'Thursday', '15:30:00', '16:30:00', '403', 'Ramanujacharya Bhavan 3rd Floor'),
(296, 'Friday', '11:30:00', '13:30:00', NULL, 'DD&CO Lab (D3)'),
(298, 'Friday', '11:30:00', '13:30:00', NULL, 'OS Lab (D1)'),
(308, 'Friday', '11:30:00', '13:30:00', NULL, 'DS Lab (D2)'),
(306, 'Friday', '15:30:00', '16:30:00', '402', 'Ramanujacharya Bhavan 3rd Floor');


-- ---------------------------------
-- 5th Sem (Year 3) ISE 'A' (IDs: 310-324) [File: 5th-Sem_Updated_TT]
-- ---------------------------------
INSERT INTO timetable_slots (class_id, day_of_week, start_time, end_time, room_no, location) VALUES
(310, 'Monday', '09:00:00', '10:00:00', '405', 'Ramanujacharya Bhavan 3rd Floor'), -- SE & PM
(316, 'Monday', '09:00:00', '10:00:00', '405', 'Ramanujacharya Bhavan 3rd Floor'), -- AI (PEC)
(317, 'Monday', '09:00:00', '10:00:00', '406', 'Ramanujacharya Bhavan 3rd Floor'), -- DS (PEC)
(318, 'Monday', '09:00:00', '10:00:00', '407', 'Ramanujacharya Bhavan 3rd Floor'), -- USP (PEC)
(323, 'Monday', '11:30:00', '12:30:00', '405', 'Ramanujacharya Bhavan 3rd Floor'), -- ES
(315, 'Monday', '14:30:00', '15:30:00', '405', 'Ramanujacharya Bhavan 3rd Floor'), -- CC
(311, 'Monday', '15:30:00', '16:30:00', '405', 'Ramanujacharya Bhavan 3rd Floor'), -- CN
(324, 'Monday', '16:30:00', '17:30:00', NULL, 'NSS'),
(319, 'Tuesday', '09:00:00', '10:00:00', '405', 'Ramanujacharya Bhavan 3rd Floor'), -- RM & IPR
(316, 'Tuesday', '09:00:00', '10:00:00', '405', 'Ramanujacharya Bhavan 3rd Floor'), -- AI (PEC)
(317, 'Tuesday', '09:00:00', '10:00:00', '406', 'Ramanujacharya Bhavan 3rd Floor'), -- DS (PEC)
(318, 'Tuesday', '09:00:00', '10:00:00', '407', 'Ramanujacharya Bhavan 3rd Floor'), -- USP (PEC)
(316, 'Tuesday', '10:00:00', '11:00:00', '405', 'Ramanujacharya Bhavan 3rd Floor'), -- AI
(310, 'Tuesday', '11:30:00', '12:30:00', '405', 'Ramanujacharya Bhavan 3rd Floor'), -- SE & PM
(311, 'Tuesday', '14:30:00', '15:30:00', '405', 'Ramanujacharya Bhavan 3rd Floor'), -- CN
(314, 'Tuesday', '15:30:00', '16:30:00', '405', 'Ramanujacharya Bhavan 3rd Floor'), -- TOC
(314, 'Wednesday', '09:00:00', '10:00:00', '405', 'Ramanujacharya Bhavan 3rd Floor'), -- TOC
(316, 'Wednesday', '10:00:00', '11:00:00', '405', 'Ramanujacharya Bhavan 3rd Floor'), -- AI
(314, 'Wednesday', '11:30:00', '12:30:00', '405', 'Ramanujacharya Bhavan 3rd Floor'), -- TOC
(315, 'Wednesday', '12:30:00', '13:30:00', '405', 'Ramanujacharya Bhavan 3rd Floor'), -- CC
(311, 'Wednesday', '14:30:00', '15:30:00', '405', 'Ramanujacharya Bhavan 3rd Floor'), -- CN
(310, 'Wednesday', '15:30:00', '16:30:00', '405', 'Ramanujacharya Bhavan 3rd Floor'), -- SE & PM
(312, 'Thursday', '09:00:00', '11:00:00', NULL, 'CN Lab A1'),
(321, 'Thursday', '09:00:00', '11:00:00', NULL, 'DV Lab A2'),
(316, 'Thursday', '11:30:00', '12:30:00', '405', 'Ramanujacharya Bhavan 3rd Floor'), -- AI
(311, 'Thursday', '12:30:00', '13:30:00', '405', 'Ramanujacharya Bhavan 3rd Floor'), -- CN
(319, 'Thursday', '14:30:00', '15:30:00', '405', 'Ramanujacharya Bhavan 3rd Floor'), -- RM & IPR
(314, 'Thursday', '15:30:00', '17:30:00', '405', 'Ramanujacharya Bhavan 3rd Floor'), -- ToC Tutorial
(315, 'Friday', '10:00:00', '11:00:00', '405', 'Ramanujacharya Bhavan 3rd Floor'), -- CC
(313, 'Friday', '11:30:00', '13:30:00', NULL, 'CN Lab A2'),
(320, 'Friday', '11:30:00', '13:30:00', NULL, 'DV Lab A1'),
(324, 'Friday', '14:30:00', '16:30:00', NULL, 'NSS');

-- ---------------------------------
-- 5th Sem (Year 3) ISE 'B' (IDs: 325-339) [File: 5th-Sem_Updated_TT]
-- ---------------------------------
INSERT INTO timetable_slots (class_id, day_of_week, start_time, end_time, room_no, location) VALUES
(331, 'Monday', '09:00:00', '10:00:00', '405', 'Ramanujacharya Bhavan 3rd Floor'), -- AI (PEC)
(332, 'Monday', '09:00:00', '10:00:00', '406', 'Ramanujacharya Bhavan 3rd Floor'), -- DS (PEC)
(333, 'Monday', '09:00:00', '10:00:00', '407', 'Ramanujacharya Bhavan 3rd Floor'), -- USP (PEC)
(325, 'Monday', '10:00:00', '11:00:00', '406', 'Ramanujacharya Bhavan 3rd Floor'), -- SE & PM
(326, 'Monday', '11:30:00', '12:30:00', '406', 'Ramanujacharya Bhavan 3rd Floor'), -- CN
(329, 'Monday', '14:30:00', '15:30:00', '406', 'Ramanujacharya Bhavan 3rd Floor'), -- TOC
(326, 'Monday', '15:30:00', '16:30:00', '406', 'Ramanujacharya Bhavan 3rd Floor'), -- CN
(331, 'Tuesday', '09:00:00', '10:00:00', '405', 'Ramanujacharya Bhavan 3rd Floor'), -- AI (PEC)
(332, 'Tuesday', '09:00:00', '10:00:00', '406', 'Ramanujacharya Bhavan 3rd Floor'), -- DS (PEC)
(333, 'Tuesday', '09:00:00', '10:00:00', '407', 'Ramanujacharya Bhavan 3rd Floor'), -- USP (PEC)
(334, 'Tuesday', '10:00:00', '11:00:00', '406', 'Ramanujacharya Bhavan 3rd Floor'), -- RM & IPR
(325, 'Tuesday', '11:30:00', '12:30:00', '406', 'Ramanujacharya Bhavan 3rd Floor'), -- SE & PM
(334, 'Tuesday', '14:30:00', '15:30:00', '406', 'Ramanujacharya Bhavan 3rd Floor'), -- RM & IPR
(330, 'Tuesday', '15:30:00', '16:30:00', '406', 'Ramanujacharya Bhavan 3rd Floor'), -- CC
(331, 'Wednesday', '09:00:00', '10:00:00', '405', 'Ramanujacharya Bhavan 3rd Floor'), -- AI (PEC)
(332, 'Wednesday', '09:00:00', '10:00:00', '406', 'Ramanujacharya Bhavan 3rd Floor'), -- DS (PEC)
(333, 'Wednesday', '09:00:00', '10:00:00', '407', 'Ramanujacharya Bhavan 3rd Floor'), -- USP (PEC)
(329, 'Wednesday', '10:00:00', '11:00:00', '406', 'Ramanujacharya Bhavan 3rd Floor'), -- TOC
(338, 'Wednesday', '11:30:00', '12:30:00', '406', 'Ramanujacharya Bhavan 3rd Floor'), -- ES
(325, 'Wednesday', '14:30:00', '15:30:00', '406', 'Ramanujacharya Bhavan 3rd Floor'), -- SE & PM
(329, 'Wednesday', '15:30:00', '16:30:00', '406', 'Ramanujacharya Bhavan 3rd Floor'), -- TOC
(330, 'Thursday', '10:00:00', '11:00:00', '406', 'Ramanujacharya Bhavan 3rd Floor'), -- CC
(330, 'Thursday', '11:30:00', '12:30:00', '406', 'Ramanujacharya Bhavan 3rd Floor'), -- CC
(327, 'Thursday', '11:30:00', '13:30:00', NULL, 'CN Lab B1'),
(336, 'Thursday', '11:30:00', '13:30:00', NULL, 'DV Lab B2'),
(329, 'Thursday', '12:30:00', '13:30:00', '406', 'Ramanujacharya Bhavan 3rd Floor'), -- TOC
(326, 'Thursday', '15:30:00', '16:30:00', '406', 'Ramanujacharya Bhavan 3rd Floor'), -- CN
(339, 'Thursday', '16:30:00', '17:30:00', NULL, 'NSS'),
(328, 'Friday', '14:30:00', '16:30:00', NULL, 'CN Lab B2'),
(335, 'Friday', '14:30:00', '16:30:00', NULL, 'DV Lab B1'),
(339, 'Friday', '16:30:00', '17:30:00', NULL, 'NSS');

-- ---------------------------------
-- 5th Sem (Year 3) ISE 'C' (IDs: 340-354) [File: 5th-Sem_Updated_TT]
-- ---------------------------------
INSERT INTO timetable_slots (class_id, day_of_week, start_time, end_time, room_no, location) VALUES
(346, 'Monday', '09:00:00', '10:00:00', '405', 'Ramanujacharya Bhavan 3rd Floor'), -- AI (PEC)
(347, 'Monday', '09:00:00', '10:00:00', '406', 'Ramanujacharya Bhavan 3rd Floor'), -- DS (PEC)
(348, 'Monday', '09:00:00', '10:00:00', '407', 'Ramanujacharya Bhavan 3rd Floor'), -- USP (PEC)
(344, 'Monday', '10:00:00', '11:00:00', '407', 'Ramanujacharya Bhavan 3rd Floor'), -- TOC
(346, 'Monday', '11:30:00', '12:30:00', '405', 'Ramanujacharya Bhavan 3rd Floor'), -- AI
(349, 'Monday', '12:30:00', '13:30:00', '407', 'Ramanujacharya Bhavan 3rd Floor'), -- RM & IPR
(340, 'Monday', '14:30:00', '15:30:00', '407', 'Ramanujacharya Bhavan 3rd Floor'), -- SE & PM
(345, 'Monday', '15:30:00', '16:30:00', '407', 'Ramanujacharya Bhavan 3rd Floor'), -- CC
(340, 'Tuesday', '09:00:00', '10:00:00', '407', 'Ramanujacharya Bhavan 3rd Floor'), -- SE & PM
(341, 'Tuesday', '10:00:00', '11:00:00', '407', 'Ramanujacharya Bhavan 3rd Floor'), -- CN
(341, 'Tuesday', '11:30:00', '12:30:00', '407', 'Ramanujacharya Bhavan 3rd Floor'), -- CN
(346, 'Tuesday', '12:30:00', '13:30:00', '405', 'Ramanujacharya Bhavan 3rd Floor'), -- AI
(353, 'Tuesday', '14:30:00', '15:30:00', '407', 'Ramanujacharya Bhavan 3rd Floor'), -- ES
(349, 'Tuesday', '15:30:00', '16:30:00', '407', 'Ramanujacharya Bhavan 3rd Floor'), -- RM & IPR
(346, 'Wednesday', '09:00:00', '10:00:00', '405', 'Ramanujacharya Bhavan 3rd Floor'), -- AI (PEC)
(347, 'Wednesday', '09:00:00', '10:00:00', '406', 'Ramanujacharya Bhavan 3rd Floor'), -- DS (PEC)
(348, 'Wednesday', '09:00:00', '10:00:00', '407', 'Ramanujacharya Bhavan 3rd Floor'), -- USP (PEC)
(341, 'Wednesday', '10:00:00', '11:00:00', '407', 'Ramanujacharya Bhavan 3rd Floor'), -- CN
(344, 'Wednesday', '12:30:00', '13:30:00', '407', 'Ramanujacharya Bhavan 3rd Floor'), -- TOC
(346, 'Wednesday', '14:30:00', '15:30:00', '405', 'Ramanujacharya Bhavan 3rd Floor'), -- AI
(345, 'Wednesday', '15:30:00', '16:30:00', '407', 'Ramanujacharya Bhavan 3rd Floor'), -- CC
(344, 'Thursday', '11:30:00', '12:30:00', '407', 'Ramanujacharya Bhavan 3rd Floor'), -- TOC
(344, 'Thursday', '14:30:00', '16:30:00', '407', 'Ramanujacharya Bhavan 3rd Floor'), -- ToC Tutorial
(342, 'Thursday', '14:30:00', '16:30:00', NULL, 'CN Lab C1'),
(351, 'Thursday', '14:30:00', '16:30:00', NULL, 'DV Lab C2'),
(354, 'Thursday', '16:30:00', '17:30:00', NULL, 'NSS'),
(343, 'Friday', '09:00:00', '11:00:00', NULL, 'CN Lab C2'),
(350, 'Friday', '09:00:00', '11:00:00', NULL, 'DV Lab C1'),
(345, 'Friday', '11:30:00', '12:30:00', '407', 'Ramanujacharya Bhavan 3rd Floor'), -- CC
(354, 'Friday', '16:30:00', '17:30:00', NULL, 'NSS');

-- ---------------------------------
-- 5th Sem (Year 3) ISE 'D' (IDs: 355-369) [File: 5th-Sem_Updated_TT]
-- ---------------------------------
INSERT INTO timetable_slots (class_id, day_of_week, start_time, end_time, room_no, location) VALUES
(361, 'Monday', '09:00:00', '10:00:00', '405', 'Ramanujacharya Bhavan 3rd Floor'), -- AI (PEC)
(362, 'Monday', '09:00:00', '10:00:00', '406', 'Ramanujacharya Bhavan 3rd Floor'), -- DS (PEC)
(363, 'Monday', '09:00:00', '10:00:00', '407', 'Ramanujacharya Bhavan 3rd Floor'), -- USP (PEC)
(360, 'Monday', '10:00:00', '11:00:00', '408', 'Ramanujacharya Bhavan 3rd Floor'), -- CC
(364, 'Monday', '11:30:00', '12:30:00', '408', 'Ramanujacharya Bhavan 3rd Floor'), -- RM & IPR
(361, 'Monday', '12:30:00', '13:30:00', '405', 'Ramanujacharya Bhavan 3rd Floor'), -- AI
(356, 'Monday', '14:30:00', '15:30:00', '410', 'Ramanujacharya Bhavan 3rd Floor'), -- CN
(355, 'Monday', '15:30:00', '16:30:00', '410', 'Ramanujacharya Bhavan 3rd Floor'), -- SE & PM
(361, 'Tuesday', '09:00:00', '10:00:00', '405', 'Ramanujacharya Bhavan 3rd Floor'), -- AI (PEC)
(362, 'Tuesday', '09:00:00', '10:00:00', '406', 'Ramanujacharya Bhavan 3rd Floor'), -- DS (PEC)
(363, 'Tuesday', '09:00:00', '10:00:00', '407', 'Ramanujacharya Bhavan 3rd Floor'), -- USP (PEC)
(359, 'Tuesday', '10:00:00', '11:00:00', '406', 'Ramanujacharya Bhavan 3rd Floor'), -- TOC
(357, 'Tuesday', '11:30:00', '13:30:00', NULL, 'CN Lab D1'),
(366, 'Tuesday', '11:30:00', '13:30:00', NULL, 'DV Lab D2'),
(368, 'Tuesday', '12:30:00', '13:30:00', '410', 'Ramanujacharya Bhavan 3rd Floor'), -- ES
(361, 'Wednesday', '09:00:00', '10:00:00', '405', 'Ramanujacharya Bhavan 3rd Floor'), -- AI (PEC)
(362, 'Wednesday', '09:00:00', '10:00:00', '406', 'Ramanujacharya Bhavan 3rd Floor'), -- DS (PEC)
(363, 'Wednesday', '09:00:00', '10:00:00', '407', 'Ramanujacharya Bhavan 3rd Floor'), -- USP (PEC)
(359, 'Wednesday', '10:00:00', '11:00:00', '406', 'Ramanujacharya Bhavan 3rd Floor'), -- TOC
(361, 'Wednesday', '11:30:00', '12:30:00', '405', 'Ramanujacharya Bhavan 3rd Floor'), -- AI
(358, 'Wednesday', '14:30:00', '16:30:00', NULL, 'CN Lab D2'),
(365, 'Wednesday', '14:30:00', '16:30:00', NULL, 'DV Lab D1'),
(369, 'Wednesday', '16:30:00', '17:30:00', NULL, 'NSS'),
(355, 'Thursday', '09:00:00', '10:00:00', '405', 'Ramanujacharya Bhavan 3rd Floor'), -- SE & PM
(356, 'Thursday', '10:00:00', '11:00:00', '405', 'Ramanujacharya Bhavan 3rd Floor'), -- CN
(359, 'Thursday', '11:30:00', '12:30:00', '406', 'Ramanujacharya Bhavan 3rd Floor'), -- TOC
(360, 'Thursday', '12:30:00', '13:30:00', '406', 'Ramanujacharya Bhavan 3rd Floor'), -- CC
(359, 'Thursday', '14:30:00', '16:30:00', '407', 'Ramanujacharya Bhavan 3rd Floor'), -- ToC Tutorial
(369, 'Thursday', '16:30:00', '17:30:00', NULL, 'NSS'),
(356, 'Friday', '09:00:00', '10:00:00', '407', 'Ramanujacharya Bhavan 3rd Floor'), -- CN
(355, 'Friday', '10:00:00', '11:00:00', '407', 'Ramanujacharya Bhavan 3rd Floor'), -- SE & PM
(364, 'Friday', '11:30:00', '12:30:00', '405', 'Ramanujacharya Bhavan 3rd Floor'); -- RM & IPR

-- ---------------------------------
-- 5th Sem (Year 3) CSE 'a' 
-- ---------------------------------
INSERT INTO timetable_slots (class_id, day_of_week, start_time, end_time, room_no, location) VALUES
(374, 'Monday', '09:00:00', '11:00:00', 'CSLAB-8', 'CSE Dept'), -- A3 CN lab
(379, 'Monday', '11:30:00', '12:30:00', '301', 'Ramanujacharya Bhavan 2nd Floor'), -- FSD
(380, 'Monday', '12:30:00', '13:30:00', '301', 'Ramanujacharya Bhavan 2nd Floor'), -- AI
(370, 'Monday', '14:30:00', '15:30:00', '301', 'Ramanujacharya Bhavan 2nd Floor'), -- SPM
(383, 'Monday', '15:30:00', '16:30:00', '301', 'Ramanujacharya Bhavan 2nd Floor'), -- EVS
(384, 'Monday', '16:30:00', '17:30:00', NULL, 'NSS/YOGA/PE'),
(376, 'Tuesday', '09:00:00', '11:00:00', 'AIML LAB-3', 'AI&ML Dept'), -- A1 FSD Lab
(377, 'Tuesday', '09:00:00', '11:00:00', 'AIML LAB-3', 'AI&ML Dept'), -- A2 FSD Lab
(375, 'Tuesday', '11:30:00', '12:30:00', '301', 'Ramanujacharya Bhavan 2nd Floor'), -- ATC
(371, 'Tuesday', '12:30:00', '13:30:00', '301', 'Ramanujacharya Bhavan 2nd Floor'), -- CN
(379, 'Tuesday', '14:30:00', '15:30:00', '301', 'Ramanujacharya Bhavan 2nd Floor'), -- FSD
(380, 'Tuesday', '15:30:00', '16:30:00', '301', 'Ramanujacharya Bhavan 2nd Floor'), -- AI
(384, 'Tuesday', '16:30:00', '17:30:00', NULL, 'NSS/YOGA/PE'),
(373, 'Wednesday', '09:00:00', '11:00:00', 'CSLAB-8', 'CSE Dept'), -- A2 CN Lab
(378, 'Wednesday', '09:00:00', '11:00:00', 'AIML LAB-3', 'AI&ML Dept'), -- A3 FSD Lab
(370, 'Wednesday', '11:30:00', '12:30:00', '301', 'Ramanujacharya Bhavan 2nd Floor'), -- SPM
(382, 'Wednesday', '12:30:00', '13:30:00', '301', 'Ramanujacharya Bhavan 2nd Floor'), -- RM
(380, 'Wednesday', '14:30:00', '15:30:00', '301', 'Ramanujacharya Bhavan 2nd Floor'), -- AI
(375, 'Wednesday', '15:30:00', '16:30:00', '301', 'Ramanujacharya Bhavan 2nd Floor'), -- ATC
(375, 'Thursday', '09:00:00', '10:00:00', '301', 'Ramanujacharya Bhavan 2nd Floor'), -- ATC
(371, 'Thursday', '10:00:00', '11:00:00', '301', 'Ramanujacharya Bhavan 2nd Floor'), -- CN
(370, 'Thursday', '11:30:00', '12:30:00', '301', 'Ramanujacharya Bhavan 2nd Floor'), -- SPM
(379, 'Thursday', '12:30:00', '13:30:00', '301', 'Ramanujacharya Bhavan 2nd Floor'), -- FSD
(375, 'Thursday', '14:30:00', '16:30:00', '301', 'Ramanujacharya Bhavan 2nd Floor'), -- ATC Tutorial A
(372, 'Friday', '09:00:00', '11:00:00', 'CSLAB-8', 'CSE Dept'), -- A1 CN Lab
(380, 'Friday', '11:30:00', '12:30:00', '301', 'Ramanujacharya Bhavan 2nd Floor'), -- AI
(371, 'Friday', '12:30:00', '13:30:00', '301', 'Ramanujacharya Bhavan 2nd Floor'), -- CN
(382, 'Friday', '14:30:00', '15:30:00', '301', 'Ramanujacharya Bhavan 2nd Floor'), -- RM
(370, 'Friday', '15:30:00', '16:30:00', '301', 'Ramanujacharya Bhavan 2nd Floor'), -- SPM
(381, 'Friday', '16:30:00', '17:30:00', NULL, 'Minor Project');
-- Saturday Activity Points ignored

-- ---------------------------------
-- 5th Sem (Year 3) CSE 'B' (IDs: 385-399) [File: 5th Final, Page 2]
-- ---------------------------------
INSERT INTO timetable_slots (class_id, day_of_week, start_time, end_time, room_no, location) VALUES
(397, 'Monday', '09:00:00', '10:00:00', '302', 'Ramanujacharya Bhavan 2nd Floor'), -- RM
(385, 'Monday', '10:00:00', '11:00:00', '302', 'Ramanujacharya Bhavan 2nd Floor'), -- SPM
(394, 'Monday', '11:30:00', '12:30:00', '302', 'Ramanujacharya Bhavan 2nd Floor'), -- FSD
(388, 'Monday', '14:30:00', '16:30:00', 'CSLAB-8', 'CSE Dept'), -- B2 CN Lab
(391, 'Monday', '15:30:00', '17:30:00', 'AIML LAB-3', 'AI&ML Dept'), -- B1 FSD Lab
(399, 'Monday', '16:30:00', '17:30:00', NULL, 'NSS/YOGA/PE'), -- Overlaps FSD Lab end
(395, 'Tuesday', '09:00:00', '10:00:00', '302', 'Ramanujacharya Bhavan 2nd Floor'), -- AI
(398, 'Tuesday', '10:00:00', '11:00:00', '302', 'Ramanujacharya Bhavan 2nd Floor'), -- EVS
(394, 'Tuesday', '11:30:00', '12:30:00', '302', 'Ramanujacharya Bhavan 2nd Floor'), -- FSD
(390, 'Tuesday', '12:30:00', '13:30:00', '302', 'Ramanujacharya Bhavan 2nd Floor'), -- ATC
(386, 'Tuesday', '14:30:00', '15:30:00', '302', 'Ramanujacharya Bhavan 2nd Floor'), -- CN
(387, 'Wednesday', '09:00:00', '11:00:00', 'CSLAB-8', 'CSE Dept'), -- B1 CN Lab
(393, 'Wednesday', '09:00:00', '11:00:00', 'AIML LAB-3', 'AI&ML Dept'), -- B3 FSD Lab
(386, 'Wednesday', '11:30:00', '12:30:00', '302', 'Ramanujacharya Bhavan 2nd Floor'), -- CN
(385, 'Wednesday', '12:30:00', '13:30:00', '302', 'Ramanujacharya Bhavan 2nd Floor'), -- SPM
(394, 'Thursday', '09:00:00', '10:00:00', '302', 'Ramanujacharya Bhavan 2nd Floor'), -- FSD
(385, 'Thursday', '10:00:00', '11:00:00', '302', 'Ramanujacharya Bhavan 2nd Floor'), -- SPM
(395, 'Thursday', '11:30:00', '12:30:00', '302', 'Ramanujacharya Bhavan 2nd Floor'), -- AI
(390, 'Thursday', '12:30:00', '13:30:00', '302', 'Ramanujacharya Bhavan 2nd Floor'), -- ATC
(389, 'Thursday', '14:30:00', '16:30:00', 'CSLAB-8', 'CSE Dept'), -- B3 CN Lab
(392, 'Thursday', '15:30:00', '17:30:00', 'AIML LAB-3', 'AI&ML Dept'), -- B2 FSD Lab
(399, 'Thursday', '16:30:00', '17:30:00', NULL, 'NSS/YOGA/PE'), -- Overlaps FSD Lab end
(386, 'Friday', '09:00:00', '10:00:00', '302', 'Ramanujacharya Bhavan 2nd Floor'), -- CN
(395, 'Friday', '10:00:00', '11:00:00', '302', 'Ramanujacharya Bhavan 2nd Floor'), -- AI
(390, 'Friday', '11:30:00', '12:30:00', '302', 'Ramanujacharya Bhavan 2nd Floor'), -- ATC
(397, 'Friday', '12:30:00', '13:30:00', '302', 'Ramanujacharya Bhavan 2nd Floor'), -- RM
(390, 'Friday', '14:30:00', '16:30:00', '302', 'Ramanujacharya Bhavan 2nd Floor'), -- ATC Tutorial B
(396, 'Friday', '16:30:00', '17:30:00', NULL, 'Minor Project');
-- Saturday Activity Points ignored

-- ---------------------------------
-- 5th Sem (Year 3) CSE 'C' (IDs: 400-414) [File: 5th Final, Page 3]
-- ---------------------------------
INSERT INTO timetable_slots (class_id, day_of_week, start_time, end_time, room_no, location) VALUES
(405, 'Monday', '09:00:00', '11:00:00', '303', 'Ramanujacharya Bhavan 2nd Floor'), -- ATC Tutorial C
(400, 'Monday', '11:30:00', '12:30:00', '303', 'Ramanujacharya Bhavan 2nd Floor'), -- SPM
(410, 'Monday', '12:30:00', '13:30:00', '303', 'Ramanujacharya Bhavan 2nd Floor'), -- AI
(401, 'Monday', '14:30:00', '15:30:00', '303', 'Ramanujacharya Bhavan 2nd Floor'), -- CN
(405, 'Monday', '15:30:00', '16:30:00', '303', 'Ramanujacharya Bhavan 2nd Floor'), -- ATC
(414, 'Monday', '16:30:00', '17:30:00', NULL, 'NSS/YOGA/PE'),
(405, 'Tuesday', '09:00:00', '10:00:00', '303', 'Ramanujacharya Bhavan 2nd Floor'), -- ATC
(410, 'Tuesday', '10:00:00', '11:00:00', '303', 'Ramanujacharya Bhavan 2nd Floor'), -- AI
(400, 'Tuesday', '11:30:00', '12:30:00', '303', 'Ramanujacharya Bhavan 2nd Floor'), -- SPM
(409, 'Tuesday', '12:30:00', '13:30:00', '303', 'Ramanujacharya Bhavan 2nd Floor'), -- FSD
(412, 'Tuesday', '14:30:00', '15:30:00', '303', 'Ramanujacharya Bhavan 2nd Floor'), -- RM
(413, 'Tuesday', '15:30:00', '16:30:00', '303', 'Ramanujacharya Bhavan 2nd Floor'), -- EVS
(401, 'Wednesday', '09:00:00', '10:00:00', '303', 'Ramanujacharya Bhavan 2nd Floor'), -- CN
(405, 'Wednesday', '10:00:00', '11:00:00', '303', 'Ramanujacharya Bhavan 2nd Floor'), -- ATC
(407, 'Wednesday', '11:30:00', '13:30:00', 'AIML LAB-3', 'AI&ML Dept'), -- C2 FSD Lab
(404, 'Wednesday', '11:30:00', '13:30:00', 'CSLAB-8', 'CSE Dept'), -- C3 CN Lab
(400, 'Thursday', '09:00:00', '10:00:00', '303', 'Ramanujacharya Bhavan 2nd Floor'), -- SPM
(412, 'Thursday', '10:00:00', '11:00:00', '303', 'Ramanujacharya Bhavan 2nd Floor'), -- RM
(401, 'Thursday', '11:30:00', '12:30:00', '303', 'Ramanujacharya Bhavan 2nd Floor'), -- CN
(409, 'Thursday', '12:30:00', '13:30:00', '303', 'Ramanujacharya Bhavan 2nd Floor'), -- FSD
(402, 'Thursday', '14:30:00', '16:30:00', 'CSLAB-8', 'CSE Dept'), -- C1 CN Lab
(408, 'Thursday', '14:30:00', '16:30:00', 'AIML LAB-3', 'AI&ML Dept'), -- C3 FSD Lab
(414, 'Thursday', '16:30:00', '17:30:00', NULL, 'NSS/YOGA/PE'),
(411, 'Friday', '09:00:00', '10:00:00', NULL, 'Minor Project'),
(409, 'Friday', '11:30:00', '12:30:00', '303', 'Ramanujacharya Bhavan 2nd Floor'), -- FSD
(410, 'Friday', '12:30:00', '13:30:00', '303', 'Ramanujacharya Bhavan 2nd Floor'), -- AI
(403, 'Friday', '14:30:00', '16:30:00', 'CSLAB-8', 'CSE Dept'), -- C2 CN Lab
(406, 'Friday', '14:30:00', '16:30:00', 'AIML LAB-3', 'AI&ML Dept'); -- C1 FSD Lab
-- Saturday Activity Points ignored

-- ---------------------------------
-- 5th Sem (Year 3) CSE 'D' (IDs: 415-429) [File: 5th Final, Page 4]
-- ---------------------------------
INSERT INTO timetable_slots (class_id, day_of_week, start_time, end_time, room_no, location) VALUES
(416, 'Monday', '09:00:00', '10:00:00', '301', 'Ramanujacharya Bhavan 2nd Floor'), -- CN
(427, 'Monday', '10:00:00', '11:00:00', '301', 'Ramanujacharya Bhavan 2nd Floor'), -- RM
(426, 'Monday', '11:30:00', '13:30:00', NULL, 'Minor Project'),
(429, 'Monday', '16:30:00', '17:30:00', NULL, 'NSS/YOGA/PE'),
(420, 'Tuesday', '09:00:00', '10:00:00', '307', 'Ramanujacharya Bhavan 2nd Floor'), -- ATC
(427, 'Tuesday', '10:00:00', '11:00:00', '307', 'Ramanujacharya Bhavan 2nd Floor'), -- RM
(415, 'Tuesday', '11:30:00', '12:30:00', '301', 'Ramanujacharya Bhavan 2nd Floor'), -- SPM
(424, 'Tuesday', '12:30:00', '13:30:00', '307', 'Ramanujacharya Bhavan 2nd Floor'), -- FSD
(428, 'Tuesday', '14:30:00', '15:30:00', '307', 'Ramanujacharya Bhavan 2nd Floor'), -- EVS
(425, 'Tuesday', '15:30:00', '16:30:00', '307', 'Ramanujacharya Bhavan 2nd Floor'), -- AI
(425, 'Wednesday', '09:00:00', '10:00:00', '302', 'Ramanujacharya Bhavan 2nd Floor'), -- AI
(416, 'Wednesday', '10:00:00', '11:00:00', '307', 'Ramanujacharya Bhavan 2nd Floor'), -- CN
(416, 'Wednesday', '11:30:00', '12:30:00', '302', 'Ramanujacharya Bhavan 2nd Floor'), -- CN
(424, 'Wednesday', '12:30:00', '13:30:00', '301', 'Ramanujacharya Bhavan 2nd Floor'), -- FSD
(420, 'Wednesday', '14:30:00', '16:30:00', '307', 'Ramanujacharya Bhavan 2nd Floor'), -- ATC Tutorial D
(429, 'Wednesday', '16:30:00', '17:30:00', NULL, 'NSS/YOGA/PE'),
(415, 'Thursday', '09:00:00', '10:00:00', '303', 'Ramanujacharya Bhavan 2nd Floor'), -- SPM
(420, 'Thursday', '10:00:00', '11:00:00', '303', 'Ramanujacharya Bhavan 2nd Floor'), -- ATC
(421, 'Thursday', '11:30:00', '13:30:00', 'AIML LAB-3', 'AI&ML Dept'), -- D1 FSD Lab
(418, 'Thursday', '11:30:00', '13:30:00', 'CSLAB-8', 'CSE Dept'), -- D2 CN Lab
(417, 'Friday', '09:00:00', '11:00:00', 'CSLAB-8', 'CSE Dept'), -- D1 CN Lab
(423, 'Friday', '09:00:00', '11:00:00', 'AIML LAB-3', 'AI&ML Dept'), -- D3 FSD Lab
(420, 'Friday', '11:30:00', '12:30:00', '303', 'Ramanujacharya Bhavan 2nd Floor'), -- ATC
(425, 'Friday', '12:30:00', '13:30:00', '303', 'Ramanujacharya Bhavan 2nd Floor'), -- AI
(415, 'Friday', '14:30:00', '15:30:00', '303', 'Ramanujacharya Bhavan 2nd Floor'), -- SPM
(424, 'Friday', '15:30:00', '16:30:00', '303', 'Ramanujacharya Bhavan 2nd Floor'); -- FSD
-- Saturday Activity Points ignored

-- ---------------------------------
-- 5th Sem (Year 3) AI&ML 'E' (IDs: 430-444) [File: 5th Final, Page 5]
-- ---------------------------------
INSERT INTO timetable_slots (class_id, day_of_week, start_time, end_time, room_no, location) VALUES
(430, 'Monday', '09:00:00', '10:00:00', '303', 'Ramanujacharya Bhavan 2nd Floor'), -- SPM
(440, 'Monday', '10:00:00', '11:00:00', '303', 'Ramanujacharya Bhavan 2nd Floor'), -- IR (ML2->IR)
(435, 'Monday', '11:30:00', '12:30:00', '309', 'Ramanujacharya Bhavan 2nd Floor'), -- ATC (NLP->ATC)
(431, 'Monday', '12:30:00', '13:30:00', '307', 'Ramanujacharya Bhavan 2nd Floor'), -- CN
(443, 'Monday', '14:30:00', '15:30:00', '307', 'Ramanujacharya Bhavan 2nd Floor'), -- EVS
(442, 'Monday', '15:30:00', '16:30:00', '307', 'Ramanujacharya Bhavan 2nd Floor'), -- RM
(444, 'Monday', '16:30:00', '17:30:00', NULL, 'NSS/YOGA/PE'),
(441, 'Tuesday', '09:00:00', '11:00:00', NULL, 'Minor Project'),
(435, 'Tuesday', '11:30:00', '12:30:00', '309', 'Ramanujacharya Bhavan 2nd Floor'), -- ATC (NLP->ATC)
(430, 'Tuesday', '12:30:00', '13:30:00', '307', 'Ramanujacharya Bhavan 2nd Floor'), -- SPM
(432, 'Tuesday', '14:30:00', '16:30:00', 'CSLAB-1', 'CSE Dept'), -- E1 CN Lab
(437, 'Tuesday', '14:30:00', '16:30:00', 'AIML LAB-4', 'AI&ML Dept'), -- E2 ML Lab
(439, 'Wednesday', '09:00:00', '10:00:00', '309', 'Ramanujacharya Bhavan 2nd Floor'), -- ML
(440, 'Wednesday', '10:00:00', '11:00:00', '310', 'Ramanujacharya Bhavan 2nd Floor'), -- IR
(435, 'Wednesday', '11:30:00', '12:30:00', '309', 'Ramanujacharya Bhavan 2nd Floor'), -- ATC (NLP->ATC)
(431, 'Wednesday', '12:30:00', '13:30:00', '307', 'Ramanujacharya Bhavan 2nd Floor'), -- CN
(433, 'Wednesday', '14:30:00', '16:30:00', 'CSLAB-8', 'CSE Dept'), -- E2 CN Lab
(438, 'Wednesday', '14:30:00', '16:30:00', 'AIML LAB-4', 'AI&ML Dept'), -- E3 ML Lab
(444, 'Wednesday', '16:30:00', '17:30:00', NULL, 'NSS/YOGA/PE'),
(439, 'Thursday', '09:00:00', '10:00:00', '309', 'Ramanujacharya Bhavan 2nd Floor'), -- ML
(440, 'Thursday', '10:00:00', '11:00:00', '303', 'Ramanujacharya Bhavan 2nd Floor'), -- IR
(435, 'Thursday', '11:30:00', '12:30:00', '309', 'Ramanujacharya Bhavan 2nd Floor'), -- ATC (NLP->ATC)
(439, 'Thursday', '12:30:00', '13:30:00', '309', 'Ramanujacharya Bhavan 2nd Floor'), -- ML
(436, 'Thursday', '14:30:00', '16:30:00', 'AIML LAB-4', 'AI&ML Dept'), -- E1 ML Lab
(434, 'Thursday', '14:30:00', '16:30:00', 'CSLAB-8', 'CSE Dept'), -- E3 CN Lab
(435, 'Friday', '09:00:00', '11:00:00', '307', 'Ramanujacharya Bhavan 2nd Floor'), -- ATC Tutorial E
(430, 'Friday', '11:30:00', '12:30:00', '307', 'Ramanujacharya Bhavan 2nd Floor'), -- SPM
(431, 'Friday', '12:30:00', '13:30:00', '307', 'Ramanujacharya Bhavan 2nd Floor'), -- CN
(439, 'Friday', '14:30:00', '15:30:00', '307', 'Ramanujacharya Bhavan 2nd Floor'), -- ML
(442, 'Friday', '15:30:00', '16:30:00', '307', 'Ramanujacharya Bhavan 2nd Floor'); -- RM
-- Saturday Activity Points ignored

-- ---------------------------------
-- 5th Sem (Year 3) AI&ML 'F' (IDs: 445-459) [File: 5th Final, Page 6]
-- ---------------------------------
INSERT INTO timetable_slots (class_id, day_of_week, start_time, end_time, room_no, location) VALUES
(454, 'Monday', '09:00:00', '10:00:00', '308', 'Ramanujacharya Bhavan 2nd Floor'), -- ML
(445, 'Monday', '10:00:00', '11:00:00', '308', 'Ramanujacharya Bhavan 2nd Floor'), -- SPM
(450, 'Monday', '11:30:00', '12:30:00', '308', 'Ramanujacharya Bhavan 2nd Floor'), -- ATC
(455, 'Monday', '12:30:00', '13:30:00', '308', 'Ramanujacharya Bhavan 2nd Floor'), -- IR
(448, 'Monday', '14:30:00', '16:30:00', 'CSLAB-1', 'CSE Dept'), -- F2 CN Lab
(451, 'Monday', '14:30:00', '16:30:00', 'AIML LAB-4', 'AI&ML Dept'), -- F1 ML Lab
(459, 'Monday', '16:30:00', '17:30:00', NULL, 'NSS/YOGA/PE'),
(445, 'Tuesday', '09:00:00', '10:00:00', '308', 'Ramanujacharya Bhavan 2nd Floor'), -- SPM
(455, 'Tuesday', '10:00:00', '11:00:00', '308', 'Ramanujacharya Bhavan 2nd Floor'), -- IR
(446, 'Tuesday', '11:30:00', '12:30:00', '308', 'Ramanujacharya Bhavan 2nd Floor'), -- CN
(458, 'Tuesday', '12:30:00', '13:30:00', '308', 'Ramanujacharya Bhavan 2nd Floor'), -- EVS
(450, 'Tuesday', '14:30:00', '16:30:00', '308', 'Ramanujacharya Bhavan 2nd Floor'), -- ATC F Tutorial
(446, 'Wednesday', '09:00:00', '10:00:00', '308', 'Ramanujacharya Bhavan 2nd Floor'), -- CN
(450, 'Wednesday', '10:00:00', '11:00:00', '308', 'Ramanujacharya Bhavan 2nd Floor'), -- ATC
(456, 'Wednesday', '11:30:00', '13:30:00', NULL, 'Minor project'),
(459, 'Wednesday', '16:30:00', '17:30:00', NULL, 'NSS/YOGA/PE'),
(457, 'Thursday', '09:00:00', '10:00:00', '308', 'Ramanujacharya Bhavan 2nd Floor'), -- RM
(454, 'Thursday', '10:00:00', '11:00:00', '308', 'Ramanujacharya Bhavan 2nd Floor'), -- ML
(455, 'Thursday', '11:30:00', '12:30:00', '308', 'Ramanujacharya Bhavan 2nd Floor'), -- IR
(445, 'Thursday', '12:30:00', '13:30:00', '308', 'Ramanujacharya Bhavan 2nd Floor'), -- SPM
(447, 'Thursday', '14:30:00', '16:30:00', 'CSLAB-1', 'CSE Dept'), -- F1 CN Lab
(453, 'Thursday', '14:30:00', '16:30:00', 'AIML LAB-4', 'AI&ML Dept'), -- F3 ML Lab
(450, 'Friday', '09:00:00', '10:00:00', '308', 'Ramanujacharya Bhavan 2nd Floor'), -- ATC
(454, 'Friday', '10:00:00', '11:00:00', '308', 'Ramanujacharya Bhavan 2nd Floor'), -- ML
(446, 'Friday', '11:30:00', '12:30:00', '308', 'Ramanujacharya Bhavan 2nd Floor'), -- CN
(457, 'Friday', '12:30:00', '13:30:00', '308', 'Ramanujacharya Bhavan 2nd Floor'), -- RM
(449, 'Friday', '14:30:00', '16:30:00', 'CSLAB-1', 'CSE Dept'), -- F3 CN Lab
(452, 'Friday', '14:30:00', '16:30:00', 'AIML LAB-4', 'AI&ML Dept'); -- F2 ML Lab
-- Saturday Activity Points ignored

USE campus_bot3;

-- =================================================================
-- DATA ENTRY - TIMETABLE SLOTS (7th Semester / 4th Year)
-- =================================================================

-- ---------------------------------
-- 7th Sem (Year 4) CSE 'A' (IDs: 460-468) [File: 7th sem, Page 1]
-- ---------------------------------
INSERT INTO timetable_slots (class_id, day_of_week, start_time, end_time, room_no, location) VALUES
(467, 'Monday', '09:00:00', '10:00:00', '304', 'Ramanujacharya Bhavan 2nd Floor'), -- OE
(460, 'Monday', '10:00:00', '11:00:00', '304', 'Ramanujacharya Bhavan 2nd Floor'), -- CNS
(462, 'Monday', '11:30:00', '13:30:00', NULL, 'PC Lab A1'),
(463, 'Monday', '14:30:00', '16:30:00', NULL, 'PC Lab A2'),
(467, 'Tuesday', '09:00:00', '10:00:00', '304', 'Ramanujacharya Bhavan 2nd Floor'), -- OE
(464, 'Tuesday', '10:00:00', '11:00:00', '304', 'Ramanujacharya Bhavan 2nd Floor'), -- PE (BCS713A)
(465, 'Tuesday', '10:00:00', '11:00:00', '304', 'Ramanujacharya Bhavan 2nd Floor'), -- PE (BCS713C)
(466, 'Tuesday', '10:00:00', '11:00:00', '304', 'Ramanujacharya Bhavan 2nd Floor'), -- PE (BCI713D)
(460, 'Tuesday', '11:30:00', '12:30:00', '304', 'Ramanujacharya Bhavan 2nd Floor'), -- CNS
(461, 'Tuesday', '12:30:00', '13:30:00', '304', 'Ramanujacharya Bhavan 2nd Floor'), -- PC
(467, 'Wednesday', '09:00:00', '10:00:00', '304', 'Ramanujacharya Bhavan 2nd Floor'), -- OE
(464, 'Wednesday', '10:00:00', '11:00:00', '304', 'Ramanujacharya Bhavan 2nd Floor'), -- PE (BCS713A)
(465, 'Wednesday', '10:00:00', '11:00:00', '304', 'Ramanujacharya Bhavan 2nd Floor'), -- PE (BCS713C)
(466, 'Wednesday', '10:00:00', '11:00:00', '304', 'Ramanujacharya Bhavan 2nd Floor'), -- PE (BCI713D)
(460, 'Wednesday', '11:30:00', '12:30:00', '304', 'Ramanujacharya Bhavan 2nd Floor'), -- CNS
(461, 'Wednesday', '12:30:00', '13:30:00', '304', 'Ramanujacharya Bhavan 2nd Floor'), -- PC
(461, 'Thursday', '09:00:00', '10:00:00', '304', 'Ramanujacharya Bhavan 2nd Floor'), -- PC
(464, 'Thursday', '10:00:00', '11:00:00', '304', 'Ramanujacharya Bhavan 2nd Floor'), -- PE (BCS713A)
(465, 'Thursday', '10:00:00', '11:00:00', '304', 'Ramanujacharya Bhavan 2nd Floor'), -- PE (BCS713C)
(466, 'Thursday', '10:00:00', '11:00:00', '304', 'Ramanujacharya Bhavan 2nd Floor'), -- PE (BCI713D)
(460, 'Thursday', '11:30:00', '12:30:00', '304', 'Ramanujacharya Bhavan 2nd Floor'); -- CNS
-- Note: Major Project (468) is not in the grid

-- ---------------------------------
-- 7th Sem (Year 4) CSE 'B' (IDs: 469-477) [File: 7th sem, Page 2]
-- ---------------------------------
INSERT INTO timetable_slots (class_id, day_of_week, start_time, end_time, room_no, location) VALUES
(476, 'Monday', '09:00:00', '10:00:00', '305', 'Ramanujacharya Bhavan 2nd Floor'), -- OE
(470, 'Monday', '10:00:00', '11:00:00', '305', 'Ramanujacharya Bhavan 2nd Floor'), -- PC
(469, 'Monday', '11:30:00', '12:30:00', '305', 'Ramanujacharya Bhavan 2nd Floor'), -- CNS
(476, 'Tuesday', '09:00:00', '10:00:00', '305', 'Ramanujacharya Bhavan 2nd Floor'), -- OE
(473, 'Tuesday', '10:00:00', '11:00:00', '305', 'Ramanujacharya Bhavan 2nd Floor'), -- PE (BCS713A)
(474, 'Tuesday', '10:00:00', '11:00:00', '305', 'Ramanujacharya Bhavan 2nd Floor'), -- PE (BCS713C)
(475, 'Tuesday', '10:00:00', '11:00:00', '305', 'Ramanujacharya Bhavan 2nd Floor'), -- PE (BCI713D)
(471, 'Tuesday', '11:30:00', '13:30:00', NULL, 'PC Lab B1'),
(469, 'Tuesday', '14:30:00', '15:30:00', '305', 'Ramanujacharya Bhavan 2nd Floor'), -- CNS
(476, 'Wednesday', '09:00:00', '10:00:00', '305', 'Ramanujacharya Bhavan 2nd Floor'), -- OE
(473, 'Wednesday', '10:00:00', '11:00:00', '305', 'Ramanujacharya Bhavan 2nd Floor'), -- PE (BCS713A)
(474, 'Wednesday', '10:00:00', '11:00:00', '305', 'Ramanujacharya Bhavan 2nd Floor'), -- PE (BCS713C)
(475, 'Wednesday', '10:00:00', '11:00:00', '305', 'Ramanujacharya Bhavan 2nd Floor'), -- PE (BCI713D)
(469, 'Wednesday', '11:30:00', '12:30:00', '305', 'Ramanujacharya Bhavan 2nd Floor'), -- CNS
(470, 'Wednesday', '12:30:00', '13:30:00', '305', 'Ramanujacharya Bhavan 2nd Floor'), -- PC
(469, 'Wednesday', '14:30:00', '15:30:00', '305', 'Ramanujacharya Bhavan 2nd Floor'), -- CNS
(470, 'Thursday', '09:00:00', '10:00:00', '305', 'Ramanujacharya Bhavan 2nd Floor'), -- PC
(473, 'Thursday', '10:00:00', '11:00:00', '305', 'Ramanujacharya Bhavan 2nd Floor'), -- PE (BCS713A)
(474, 'Thursday', '10:00:00', '11:00:00', '305', 'Ramanujacharya Bhavan 2nd Floor'), -- PE (BCS713C)
(475, 'Thursday', '10:00:00', '11:00:00', '305', 'Ramanujacharya Bhavan 2nd Floor'), -- PE (BCI713D)
(472, 'Thursday', '11:30:00', '13:30:00', NULL, 'PC Lab B2');
-- Note: Major Project (477) is not in the grid

-- ---------------------------------
-- 7th Sem (Year 4) CSE 'C' (IDs: 478-486) [File: 7th sem, Page 3]
-- ---------------------------------
INSERT INTO timetable_slots (class_id, day_of_week, start_time, end_time, room_no, location) VALUES
(485, 'Monday', '09:00:00', '10:00:00', '306', 'Ramanujacharya Bhavan 2nd Floor'), -- OE
(478, 'Monday', '10:00:00', '11:00:00', '306', 'Ramanujacharya Bhavan 2nd Floor'), -- CNS
(479, 'Monday', '11:30:00', '12:30:00', '306', 'Ramanujacharya Bhavan 2nd Floor'), -- PC
(480, 'Monday', '15:30:00', '17:30:00', NULL, 'PC Lab C1'),
(485, 'Tuesday', '09:00:00', '10:00:00', '306', 'Ramanujacharya Bhavan 2nd Floor'), -- OE
(482, 'Tuesday', '10:00:00', '11:00:00', '306', 'Ramanujacharya Bhavan 2nd Floor'), -- PE (BCS713A)
(483, 'Tuesday', '10:00:00', '11:00:00', '306', 'Ramanujacharya Bhavan 2nd Floor'), -- PE (BCS713C)
(484, 'Tuesday', '10:00:00', '11:00:00', '306', 'Ramanujacharya Bhavan 2nd Floor'), -- PE (BCI713D)
(478, 'Tuesday', '11:30:00', '12:30:00', '306', 'Ramanujacharya Bhavan 2nd Floor'), -- CNS
(479, 'Tuesday', '15:30:00', '16:30:00', '306', 'Ramanujacharya Bhavan 2nd Floor'), -- PC
(485, 'Wednesday', '09:00:00', '10:00:00', '306', 'Ramanujacharya Bhavan 2nd Floor'), -- OE
(482, 'Wednesday', '10:00:00', '11:00:00', '306', 'Ramanujacharya Bhavan 2nd Floor'), -- PE (BCS713A)
(483, 'Wednesday', '10:00:00', '11:00:00', '306', 'Ramanujacharya Bhavan 2nd Floor'), -- PE (BCS713C)
(484, 'Wednesday', '10:00:00', '11:00:00', '306', 'Ramanujacharya Bhavan 2nd Floor'), -- PE (BCI713D)
(478, 'Wednesday', '11:30:00', '12:30:00', '306', 'Ramanujacharya Bhavan 2nd Floor'), -- CNS
(479, 'Wednesday', '12:30:00', '13:30:00', '306', 'Ramanujacharya Bhavan 2nd Floor'), -- PC
(481, 'Wednesday', '14:30:00', '16:30:00', NULL, 'PC Lab C2'),
(482, 'Thursday', '10:00:00', '11:00:00', '306', 'Ramanujacharya Bhavan 2nd Floor'), -- PE (BCS713A)
(483, 'Thursday', '10:00:00', '11:00:00', '306', 'Ramanujacharya Bhavan 2nd Floor'), -- PE (BCS713C)
(484, 'Thursday', '10:00:00', '11:00:00', '306', 'Ramanujacharya Bhavan 2nd Floor'), -- PE (BCI713D)
(478, 'Thursday', '11:30:00', '12:30:00', '306', 'Ramanujacharya Bhavan 2nd Floor'); -- CNS
-- Note: Major Project (486) is not in the grid

-- ---------------------------------
-- 7th Sem (Year 4) CSE 'D' (IDs: 487-495) [File: 7th sem, Page 4]
-- ---------------------------------
INSERT INTO timetable_slots (class_id, day_of_week, start_time, end_time, room_no, location) VALUES
(494, 'Monday', '09:00:00', '10:00:00', '309', 'Ramanujacharya Bhavan 2nd Floor'), -- OE
(487, 'Monday', '10:00:00', '11:00:00', '309', 'Ramanujacharya Bhavan 2nd Floor'), -- CNS
(488, 'Monday', '11:30:00', '12:30:00', '304', 'Ramanujacharya Bhavan 2nd Floor'), -- PC
(494, 'Tuesday', '09:00:00', '10:00:00', '309', 'Ramanujacharya Bhavan 2nd Floor'), -- OE
(491, 'Tuesday', '10:00:00', '11:00:00', '309', 'Ramanujacharya Bhavan 2nd Floor'), -- PE (BCS713A)
(492, 'Tuesday', '10:00:00', '11:00:00', '309', 'Ramanujacharya Bhavan 2nd Floor'), -- PE (BCS713C)
(493, 'Tuesday', '10:00:00', '11:00:00', '309', 'Ramanujacharya Bhavan 2nd Floor'), -- PE (BCI713D)
(487, 'Tuesday', '11:30:00', '12:30:00', '305', 'Ramanujacharya Bhavan 2nd Floor'), -- CNS
(488, 'Tuesday', '12:30:00', '13:30:00', '305', 'Ramanujacharya Bhavan 2nd Floor'), -- PC
(494, 'Wednesday', '09:00:00', '10:00:00', '309', 'Ramanujacharya Bhavan 2nd Floor'), -- OE
(491, 'Wednesday', '10:00:00', '11:00:00', '309', 'Ramanujacharya Bhavan 2nd Floor'), -- PE (BCS713A)
(492, 'Wednesday', '10:00:00', '11:00:00', '309', 'Ramanujacharya Bhavan 2nd Floor'), -- PE (BCS713C)
(493, 'Wednesday', '10:00:00', '11:00:00', '309', 'Ramanujacharya Bhavan 2nd Floor'), -- PE (BCI713D)
(489, 'Wednesday', '11:30:00', '13:30:00', NULL, 'PC Lab D1'),
(487, 'Thursday', '09:00:00', '10:00:00', '309', 'Ramanujacharya Bhavan 2nd Floor'), -- CNS
(491, 'Thursday', '10:00:00', '11:00:00', '309', 'Ramanujacharya Bhavan 2nd Floor'), -- PE (BCS713A)
(492, 'Thursday', '10:00:00', '11:00:00', '309', 'Ramanujacharya Bhavan 2nd Floor'), -- PE (BCS713C)
(493, 'Thursday', '10:00:00', '11:00:00', '309', 'Ramanujacharya Bhavan 2nd Floor'), -- PE (BCI713D)
(487, 'Thursday', '11:30:00', '12:30:00', '305', 'Ramanujacharya Bhavan 2nd Floor'), -- CNS
(488, 'Thursday', '12:30:00', '13:30:00', '305', 'Ramanujacharya Bhavan 2nd Floor'), -- PC
(490, 'Thursday', '15:30:00', '17:30:00', NULL, 'PC Lab D2');
-- Note: Major Project (495) is not in the grid

-- ---------------------------------
-- 7th Sem (Year 4) AI&ML 'E' (IDs: 496-504) [File: 7th sem, Page 5]
-- ---------------------------------
INSERT INTO timetable_slots (class_id, day_of_week, start_time, end_time, room_no, location) VALUES
(503, 'Monday', '09:00:00', '10:00:00', '303', 'Ramanujacharya Bhavan 2nd Floor'), -- OE
(499, 'Monday', '10:00:00', '11:00:00', '303', 'Ramanujacharya Bhavan 2nd Floor'), -- ML2
(496, 'Monday', '11:30:00', '12:30:00', '309', 'Ramanujacharya Bhavan 2nd Floor'), -- NLP
(497, 'Monday', '14:30:00', '16:30:00', '309', 'Ramanujacharya Bhavan 2nd Floor'), -- NLP tutorial E1
(503, 'Tuesday', '09:00:00', '10:00:00', '310', 'Ramanujacharya Bhavan 2nd Floor'), -- OE
(502, 'Tuesday', '10:00:00', '11:00:00', '310', 'Ramanujacharya Bhavan 2nd Floor'), -- PE (Big Data)
(496, 'Tuesday', '11:30:00', '12:30:00', '309', 'Ramanujacharya Bhavan 2nd Floor'), -- NLP
(500, 'Tuesday', '14:30:00', '16:30:00', NULL, 'ML2 LAB E1'),
(503, 'Wednesday', '09:00:00', '10:00:00', '303', 'Ramanujacharya Bhavan 2nd Floor'), -- OE
(502, 'Wednesday', '10:00:00', '11:00:00', '303', 'Ramanujacharya Bhavan 2nd Floor'), -- PE (Big Data)
(499, 'Wednesday', '11:30:00', '12:30:00', '309', 'Ramanujacharya Bhavan 2nd Floor'), -- ML2
(501, 'Wednesday', '14:30:00', '16:30:00', NULL, 'ML2 LAB E2'),
(502, 'Thursday', '10:00:00', '11:00:00', '303', 'Ramanujacharya Bhavan 2nd Floor'), -- PE (Big Data)
(496, 'Thursday', '11:30:00', '12:30:00', '309', 'Ramanujacharya Bhavan 2nd Floor'), -- NLP
(499, 'Thursday', '12:30:00', '13:30:00', '309', 'Ramanujacharya Bhavan 2nd Floor'), -- ML2
(498, 'Thursday', '14:30:00', '16:30:00', NULL, 'NLP tutorial E2');
-- Note: Major Project (504) is not in the grid
INSERT INTO faculty (id, name, email, department, office_location) VALUES
(119, 'Dr.Rohini Nagapadma', 'principal@nie.ac.in', 'principal','Ramanujacharya Bhavan 1st Floor' );

INSERT INTO faculty (id, name, email, department, office_location) VALUES
(120, 'C Vidya Raj', 'deanaa@nie.ac.in', 'Dean & Professor','Ramanujacharya Bhavan 1st Floor' );

INSERT INTO dress_code (category, type, items) VALUES
('Everyone','Compulsary','ID CARD');
 
use campus_bot4;
Select * from faculty where id =119;
ALTER TABLE faculty
ADD COLUMN image_url TEXT;
UPDATE faculty
SET office_location = 'Principal office-Ramanujacharya Bhavan 1st Floor'
WHERE id = 119;



-- 9. DATA CORRECTION QUERIES
-- (No longer needed as data is inserted correctly)
use campus_bot4;

-- Table 1: Stores the overall summary statistics
CREATE TABLE placement_summary (
    id INT AUTO_INCREMENT PRIMARY KEY,
    highest_ctc DECIMAL(5, 2), -- e.g., 47.00
    average_ctc DECIMAL(5, 2), -- e.g., 10.92
    median_ctc DECIMAL(5, 2),  -- e.g., 10.00
    lowest_ctc DECIMAL(5, 2),   -- e.g., 3.25
    total_selects INT,
    total_companies INT
);

-- Table 2: Stores data for each company
CREATE TABLE placement_companies (
    id INT AUTO_INCREMENT PRIMARY KEY,
    company_name VARCHAR(255) NOT NULL,
    ctc DECIMAL(5, 2), -- The offered CTC in LPA
    num_selects INT,
    ctc_type VARCHAR(100) -- e.g., "Dream", "Open Dream", "Mass"
);

-- --- DATA INSERTION ---

-- Insert the summary data (Calculated from the PDF)
INSERT INTO placement_summary 
(highest_ctc, average_ctc, median_ctc, lowest_ctc, total_selects, total_companies) 
VALUES 
(47.00, 10.92, 10.00, 3.25, 272, 110);

-- Insert the COMPLETE company data (All 110 companies)
-- Data has been parsed and cleaned from the PDF.
-- num_selects = (Offers - Not Converted)
INSERT INTO placement_companies (company_name, ctc, num_selects, ctc_type) VALUES
('Fidelity Investments', 12.00, 4, 'Dream'), -- (5 Offers - 1 Not Converted)
('VISA', 31.00, 1, 'Open Dream'), -- (2 Offers - 1 Not Converted)
('Infineon Technologies', 10.00, 0, 'Dream'),
('Akamai Technologies', 18.00, 3, 'Dream'),
('JPMC (CFG)', 17.00, 6, 'Dream'),
('Halodoc', 12.40, 11, 'Dream'),
('Turing', 7.00, 0, 'Mass'),
('LG Soft India', 7.50, 3, 'Dream'),
('ZScaler', 24.00, 1, 'Open Dream'),
('A.P. Moller Maersk', 10.83, 9, 'Dream'),
('Epicor', 9.25, 2, 'Dream'),
('OpenMynz', 9.00, 3, 'Dream'),
('TVS Motors', 10.00, 4, 'Core'),
('Afford Medical Technologies', 5.50, 0, 'Mass'),
('Lowe\'s', 18.00, 11, 'Dream'),
('Tejas Networks', 10.00, 4, 'Dream'),
('Schneider Electric', 12.00, 13, 'Dream'),
('Juspay', 27.00, 1, 'Open Dream'),
('TE Connectivity', 9.10, 3, 'Dream'),
('OIT Dharmayana', 7.50, 4, 'Startup'),
('Ingersoll Rand', 7.50, 1, 'Core'),
('Accenture', 4.20, 0, 'Mass'),
('Alstom', 6.80, 30, 'Core'),
('Infosys', 9.50, 2, 'Dream'),
('Lam Research', 13.40, 2, 'Dream'),
('Pure Storage', 47.00, 1, 'Open Dream'),
('MiQ Digital', 13.00, 3, 'Dream'),
('MulticoreWare', 10.20, 0, 'Dream'),
('Spense', 7.00, 3, 'Startup'),
('Western Digital', 14.50, 4, 'Dream'),
('Lam Research - II', 11.40, 2, 'Dream'),
('LTIMindtree', 6.00, 0, 'Mass'),
('Capillary Technologies', 6.50, 1, 'Core'),
('CynLr', 18.00, 0, 'Dream'),
('Hewlett Packard Enterprise (HPE)', 17.50, 4, 'Dream'),
('Amadeus Labs', 12.60, 7, 'Dream'),
('Aptus data labs', 7.50, 0, 'Core'),
('TheMathCompany', 5.50, 6, 'Core'),
('IBM', 4.50, 0, 'Mass'),
('Nokia', 8.20, 5, 'Core'),
('Thermo Fisher Scientific', 12.50, 0, 'Dream'),
('Incture', 8.00, 5, 'Core'),
('Cognizant', 6.75, 0, 'Mass'),
('SAP Labs', 23.50, 6, 'Open Dream'),
('Accolite', 8.00, 0, 'Dream'),
('Aurigo', 8.00, 2, 'Dream'),
('Boeing', 9.00, 0, 'Dream'),
('National Instruments', 12.00, 4, 'Dream'),
('Texas Instruments', 27.00, 9, 'Open Dream'),
('Samsung', 21.00, 5, 'Open Dream'),
('CoreEL', 6.00, 1, 'Core'),
('Bosch Limited', 7.00, 2, 'Core'),
('Daimler Trucks', 10.00, 0, 'Dream'),
('Havells', 8.00, 3, 'Dream'),
('Dish Network Technologies', 8.60, 3, 'Dream'),
('Transunion', 8.00, 4, 'Dream'),
('Deltax', 7.00, 0, 'Core'),
('Infosys-II', 3.60, 19, 'Mass'),
('Aptiv', 8.50, 6, 'Dream'),
('Cohesity', 13.30, 0, 'Dream'),
('HPE-II', 8.00, 1, 'Dream'),
('Big Basket', 9.50, 5, 'Dream'),
('London Stock Exchange', 11.50, 1, 'Dream'),
('Oracle', 10.00, 7, 'Dream'), -- (9 Offers - 2 Not Converted)
('SQUADCAST', 20.00, 0, 'Open Dream'),
('Roboyo', 4.50, 1, 'Core'),
('CommScope', 13.00, 0, 'Dream'),
('Philips', 14.50, 0, 'Dream'),
('L7 Informatics', 6.50, 0, 'Core'),
('Applied Materials', 13.90, 4, 'Dream'),
('Kare ai Inc', 12.00, 0, 'Startup'),
('Vicharak', 6.00, 0, 'Startup'),
('Tech Mahindra', 3.25, 0, 'Mass'),
('Thoughtworks', 11.10, 0, 'Dream'),
('EPAM', 8.00, 0, 'Dream'),
('Columbia Sportswear', 8.26, 0, 'Dream'),
('Hashedin', 8.10, 3, 'Dream'), -- (4 Offers - 1 Not Converted)
('TCS Ninja', 3.60, 10, 'Mass'), -- (10 * 3.6 = 36)
('TCS Digital', 7.00, 3, 'Mass'), -- (3 * 7 = 21)
('Anora Labs', 6.00, 3, 'Core'), -- (3 * 6 = 18)
('Amagi Media Labs', 18.00, 1, 'Dream'), -- (1 * 18 = 18)
('OneTrust', 9.00, 0, 'Dream'),
('TCE', 4.50, 0, 'Mass'),
('Resollect Technologies', NULL, 0, 'Startup'),
('Thales Group', 9.00, 0, 'Dream'),
('Bosch Global Software Technologies', NULL, 0, 'Dream'),
('JSW Group', 8.00, 0, 'Core'),
('DevRev', 12.00, 0, 'Dream'),
('Acclime India', 6.00, 0, 'Mass'),
('Azentio', 10.00, 1, 'Dream'),
('Webknot Technologies', 7.00, 2, 'Startup'),
('SofTronicLabs', NULL, 0, 'Startup'),
('Evobi Automation', NULL, 0, 'Core'),
('LeadSquared', 10.00, 0, 'Dream'),
('Unilog', NULL, 10, NULL),
('Akamai Technologies IT Support', 10.00, 0, 'Dream'),
('Think 41', 8.00, 0, 'Startup'),
('Cariad India', 8.00, 0, 'Dream'),
('Enaviya', 3.00, 0, 'Mass'),
('Skit.ai', NULL, 0, 'Startup'),
('Ultimate Kronos Group', 13.50, 0, 'Dream');


-- 10. VERIFY DATA (Optional)
SELECT id, name, department, office_location FROM faculty;
SELECT * FROM scholarship_details;
SELECT study_year, branch, section, COUNT(*) FROM classes GROUP BY study_year, branch, section ORDER BY study_year, branch, section;