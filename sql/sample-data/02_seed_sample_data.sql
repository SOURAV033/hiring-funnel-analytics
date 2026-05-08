-- ============================================================================
-- HIRING FUNNEL ANALYTICS DASHBOARD
-- ============================================================================
-- Sample Data Generation Script
-- Description: Populates all dimension and fact tables with realistic 
--              hiring data spanning 18 months (Jan 2024 - Jun 2025).
--              ~2,500 applications across 40 open positions.
--              200 candidates seeded; CROSS JOIN produces 2,500+ applications.
-- ============================================================================

USE hiring_funnel_analytics;

-- ============================================================================
-- DIM_DATE: Populate calendar for 2023-2025
-- ============================================================================
INSERT INTO dim_date (date_key, day_of_week, day_name, day_of_month, week_of_year, month_number, month_name, quarter, year, is_weekend, fiscal_quarter, fiscal_year)
SELECT
    d AS date_key,
    DAYOFWEEK(d) AS day_of_week,
    DAYNAME(d) AS day_name,
    DAY(d) AS day_of_month,
    WEEK(d) AS week_of_year,
    MONTH(d) AS month_number,
    MONTHNAME(d) AS month_name,
    QUARTER(d) AS quarter,
    YEAR(d) AS year,
    (DAYOFWEEK(d) IN (1, 7)) AS is_weekend,
    CONCAT('Q', QUARTER(d), '_', YEAR(d)) AS fiscal_quarter,
    YEAR(d) AS fiscal_year
FROM (
    SELECT DATE_ADD('2023-01-01', INTERVAL t.n DAY) AS d
    FROM (
        SELECT a.n + b.n * 10 + c.n * 100 AS n
        FROM 
            (SELECT 0 AS n UNION SELECT 1 UNION SELECT 2 UNION SELECT 3 UNION SELECT 4 UNION SELECT 5 UNION SELECT 6 UNION SELECT 7 UNION SELECT 8 UNION SELECT 9) a,
            (SELECT 0 AS n UNION SELECT 1 UNION SELECT 2 UNION SELECT 3 UNION SELECT 4 UNION SELECT 5 UNION SELECT 6 UNION SELECT 7 UNION SELECT 8 UNION SELECT 9) b,
            (SELECT 0 AS n UNION SELECT 1 UNION SELECT 2 UNION SELECT 3 UNION SELECT 4 UNION SELECT 5 UNION SELECT 6 UNION SELECT 7 UNION SELECT 8 UNION SELECT 9) c
    ) t
    WHERE DATE_ADD('2023-01-01', INTERVAL t.n DAY) <= '2025-12-31'
) dates;

-- ============================================================================
-- DIM_CANDIDATE: 2,800 unique candidates
-- ============================================================================
INSERT INTO dim_candidate (first_name, last_name, email, phone, current_location, years_of_experience, education_level, current_employer, source_channel) VALUES
-- Engineering Candidates
('Arjun', 'Mehta', 'arjun.mehta@email.com', '+91-98765-43210', 'Bangalore', 6.5, 'Masters', 'Infosys', 'LinkedIn'),
('Priya', 'Sharma', 'priya.sharma@email.com', '+91-87654-32109', 'Hyderabad', 3.0, 'Bachelors', 'TCS', 'Job Board'),
('Vikram', 'Reddy', 'vikram.reddy@email.com', '+91-76543-21098', 'Pune', 8.0, 'Masters', 'Wipro', 'Referral'),
('Sneha', 'Patil', 'sneha.patil@email.com', '+91-65432-10987', 'Mumbai', 2.5, 'Bachelors', 'Fresh Graduate', 'Career Page'),
('Rahul', 'Krishnan', 'rahul.k@email.com', '+91-54321-09876', 'Chennai', 11.0, 'PhD', 'Google', 'Agency'),
('Ananya', 'Gupta', 'ananya.g@email.com', '+91-43210-98765', 'Delhi NCR', 5.0, 'Masters', 'Amazon', 'LinkedIn'),
('Karthik', 'Nair', 'karthik.nair@email.com', '+91-32109-87654', 'Bangalore', 7.5, 'Masters', 'Microsoft', 'Referral'),
('Divya', 'Iyer', 'divya.iyer@email.com', '+91-21098-76543', 'Pune', 1.5, 'Bachelors', 'Fresh Graduate', 'Job Board'),
('Suresh', 'Babu', 'suresh.b@email.com', '+91-10987-65432', 'Hyderabad', 14.0, 'Masters', 'Deloitte', 'LinkedIn'),
('Meera', 'Joshi', 'meera.j@email.com', '+91-09876-54321', 'Mumbai', 4.0, 'Bachelors', 'Flipkart', 'Career Page'),
('Amit', 'Singh', 'amit.singh@email.com', '+91-99887-76655', 'Bangalore', 9.0, 'Masters', 'Adobe', 'Referral'),
('Pooja', 'Das', 'pooja.das@email.com', '+91-88776-65544', 'Kolkata', 2.0, 'Bachelors', 'Cognizant', 'Job Board'),
('Rajesh', 'Kumar', 'rajesh.k@email.com', '+91-77665-54433', 'Delhi NCR', 6.0, 'Masters', 'HCL', 'LinkedIn'),
('Lakshmi', 'Venkat', 'lakshmi.v@email.com', '+91-66554-43322', 'Chennai', 3.5, 'Bachelors', 'Tech Mahindra', 'Agency'),
('Nikhil', 'Agarwal', 'nikhil.a@email.com', '+91-55443-32211', 'Pune', 10.0, 'Masters', 'Oracle', 'Referral'),
-- Marketing & Sales Candidates
('Shruti', 'Malhotra', 'shruti.m@email.com', '+91-44332-21100', 'Mumbai', 5.5, 'MBA', 'Byju\'s', 'LinkedIn'),
('Deepak', 'Verma', 'deepak.v@email.com', '+91-33221-10099', 'Delhi NCR', 7.0, 'MBA', 'Swiggy', 'Referral'),
('Nisha', 'Kapoor', 'nisha.k@email.com', '+91-22110-09988', 'Bangalore', 3.0, 'Bachelors', 'Zomato', 'Job Board'),
('Manish', 'Tiwari', 'manish.t@email.com', '+91-11009-98877', 'Hyderabad', 8.5, 'MBA', 'Ola', 'Agency'),
('Ritu', 'Saxena', 'ritu.s@email.com', '+91-00998-87766', 'Pune', 4.5, 'Masters', 'Razorpay', 'Career Page'),
-- Finance & Operations
('Sunil', 'Jain', 'sunil.j@email.com', '+91-11998-88776', 'Mumbai', 12.0, 'CA', 'EY', 'LinkedIn'),
('Kavita', 'Rao', 'kavita.rao@email.com', '+91-22889-99887', 'Bangalore', 6.0, 'MBA', 'KPMG', 'Referral'),
('Pradeep', 'Shukla', 'pradeep.s@email.com', '+91-33778-00998', 'Delhi NCR', 9.5, 'CA', 'PwC', 'Agency'),
('Asha', 'Menon', 'asha.m@email.com', '+91-44667-11009', 'Chennai', 2.5, 'Bachelors', 'Deloitte', 'Job Board'),
('Vivek', 'Pillai', 'vivek.p@email.com', '+91-55556-22110', 'Hyderabad', 15.0, 'MBA', 'McKinsey', 'LinkedIn'),
-- More Engineering
('Tanvi', 'Bhatt', 'tanvi.b@email.com', '+91-66645-33221', 'Pune', 4.0, 'Masters', 'Salesforce', 'Career Page'),
('Rohan', 'Deshmukh', 'rohan.d@email.com', '+91-77734-44332', 'Mumbai', 1.0, 'Bachelors', 'Fresh Graduate', 'Job Board'),
('Isha', 'Pandey', 'isha.p@email.com', '+91-88823-55443', 'Bangalore', 7.0, 'Masters', 'Atlassian', 'Referral'),
('Gaurav', 'Chauhan', 'gaurav.c@email.com', '+91-99912-66554', 'Delhi NCR', 5.5, 'Bachelors', 'Paytm', 'LinkedIn'),
('Swati', 'Kulkarni', 'swati.k@email.com', '+91-11101-77665', 'Pune', 3.0, 'Masters', 'Freshworks', 'Agency'),
('Aditya', 'Mishra', 'aditya.m@email.com', '+91-22290-88776', 'Hyderabad', 10.5, 'PhD', 'IBM Research', 'LinkedIn'),
-- More diverse candidates
('Fatima', 'Khan', 'fatima.k@email.com', '+91-33389-99887', 'Mumbai', 6.0, 'Masters', 'Tata Consultancy', 'Referral'),
('Joseph', 'Abraham', 'joseph.a@email.com', '+91-44478-00998', 'Chennai', 8.0, 'Bachelors', 'Cognizant', 'Job Board'),
('Simran', 'Gill', 'simran.g@email.com', '+91-55567-11009', 'Delhi NCR', 2.0, 'Bachelors', 'Fresh Graduate', 'Career Page'),
('Arun', 'Prasad', 'arun.p@email.com', '+91-66656-22110', 'Bangalore', 13.0, 'Masters', 'SAP', 'Agency'),
('Bhavna', 'Thakur', 'bhavna.t@email.com', '+91-77745-33221', 'Pune', 4.5, 'MBA', 'PhonePe', 'LinkedIn'),
('Chirag', 'Shah', 'chirag.s@email.com', '+91-88834-44332', 'Ahmedabad', 7.5, 'Bachelors', 'Zydus', 'Referral'),
('Dimple', 'Sethi', 'dimple.s@email.com', '+91-99923-55443', 'Hyderabad', 1.5, 'Bachelors', 'Fresh Graduate', 'Job Board'),
('Esha', 'Banerjee', 'esha.b@email.com', '+91-11112-66554', 'Kolkata', 9.0, 'Masters', 'ITC', 'LinkedIn'),
('Farhan', 'Ali', 'farhan.a@email.com', '+91-22201-77665', 'Bangalore', 5.0, 'Masters', 'Myntra', 'Career Page'),
('Geeta', 'Rangan', 'geeta.r@email.com', '+91-33390-88776', 'Chennai', 3.5, 'Bachelors', 'Zoho', 'Referral');

-- ============================================================================
-- Additional bulk candidates (160+ more to support 2,500+ applications)
-- ============================================================================
INSERT INTO dim_candidate (first_name, last_name, email, phone, current_location, years_of_experience, education_level, current_employer, source_channel)
SELECT
    CONCAT(ELT(FLOOR(RAND()*20)+1, 'Amit','Neha','Raj','Pooja','Vikram','Sneha','Rahul','Ananya','Karthik','Divya','Suresh','Meera','Deepak','Nisha','Manish','Ritu','Sunil','Kavita','Pradeep','Asha')),
    CONCAT(ELT(FLOOR(RAND()*20)+1, 'Kumar','Sharma','Patel','Singh','Reddy','Joshi','Nair','Das','Gupta','Iyer','Babu','Menon','Verma','Kapoor','Tiwari','Saxena','Jain','Rao','Shukla','Pillai')),
    CONCAT('candidate', n, '@email.com'),
    CONCAT('+91-', LPAD(FLOOR(RAND()*99999), 5, '0'), '-', LPAD(FLOOR(RAND()*99999), 5, '0')),
    ELT(FLOOR(RAND()*8)+1, 'Bangalore','Mumbai','Delhi NCR','Hyderabad','Pune','Chennai','Kolkata','Ahmedabad'),
    ROUND(RAND()*18 + 0.5, 1),
    ELT(FLOOR(RAND()*5)+1, 'Bachelors','Masters','MBA','PhD','CA'),
    ELT(FLOOR(RAND()*10)+1, 'TCS','Infosys','Wipro','HCL','Cognizant','Tech Mahindra','Fresh Graduate','Accenture','Capgemini','L&T'),
    ELT(FLOOR(RAND()*5)+1, 'LinkedIn','Referral','Job Board','Career Page','Agency')
FROM (
    SELECT a.n + b.n*10 + c.n*100 AS n
    FROM 
        (SELECT 0 AS n UNION SELECT 1 UNION SELECT 2 UNION SELECT 3 UNION SELECT 4 UNION SELECT 5 UNION SELECT 6 UNION SELECT 7 UNION SELECT 8 UNION SELECT 9) a,
        (SELECT 0 AS n UNION SELECT 1 UNION SELECT 2 UNION SELECT 3 UNION SELECT 4 UNION SELECT 5 UNION SELECT 6 UNION SELECT 7 UNION SELECT 8 UNION SELECT 9) b,
        (SELECT 0 AS n UNION SELECT 1 UNION SELECT 2 UNION SELECT 3 UNION SELECT 4 UNION SELECT 5 UNION SELECT 6 UNION SELECT 7 UNION SELECT 8 UNION SELECT 9) c
) nums
WHERE n BETWEEN 1 AND 160;

-- ============================================================================
-- DIM_JOB: 40 open positions across departments
-- ============================================================================
INSERT INTO dim_job (job_title, department, office_location, employment_type, seniority_level, min_salary, max_salary, remote_eligible, requisition_date, hiring_manager, target_fill_date, headcount_required, is_urgent) VALUES
-- Engineering (15 positions)
('Senior Software Engineer', 'Engineering', 'Bangalore', 'Full-time', 'Senior', 1800000, 2800000, TRUE, '2024-01-15', 'Ravi Shekhar', '2024-04-15', 3, FALSE),
('Staff Engineer', 'Engineering', 'Bangalore', 'Full-time', 'Lead', 3000000, 4500000, TRUE, '2024-02-01', 'Ravi Shekhar', '2024-05-01', 1, TRUE),
('Frontend Developer', 'Engineering', 'Pune', 'Full-time', 'Mid', 1200000, 2000000, TRUE, '2024-03-10', 'Pallavi Dutta', '2024-06-10', 2, FALSE),
('Backend Developer', 'Engineering', 'Hyderabad', 'Full-time', 'Mid', 1300000, 2200000, TRUE, '2024-01-20', 'Pallavi Dutta', '2024-04-20', 2, FALSE),
('Data Engineer', 'Engineering', 'Bangalore', 'Full-time', 'Senior', 2000000, 3200000, TRUE, '2024-04-05', 'Ravi Shekhar', '2024-07-05', 1, FALSE),
('DevOps Engineer', 'Engineering', 'Pune', 'Full-time', 'Mid', 1400000, 2400000, TRUE, '2024-02-15', 'Sanjay Gupta', '2024-05-15', 1, FALSE),
('ML Engineer', 'Engineering', 'Bangalore', 'Full-time', 'Senior', 2200000, 3800000, TRUE, '2024-05-01', 'Ravi Shekhar', '2024-08-01', 2, TRUE),
('QA Engineer', 'Engineering', 'Hyderabad', 'Full-time', 'Entry', 800000, 1400000, FALSE, '2024-03-20', 'Sanjay Gupta', '2024-06-20', 2, FALSE),
('Engineering Manager', 'Engineering', 'Bangalore', 'Full-time', 'Manager', 3500000, 5000000, TRUE, '2024-01-10', 'CTO Office', '2024-04-10', 1, TRUE),
('iOS Developer', 'Engineering', 'Pune', 'Full-time', 'Mid', 1300000, 2200000, TRUE, '2024-06-01', 'Pallavi Dutta', '2024-09-01', 1, FALSE),
('Platform Engineer', 'Engineering', 'Bangalore', 'Full-time', 'Senior', 1900000, 3000000, TRUE, '2024-04-15', 'Ravi Shekhar', '2024-07-15', 1, FALSE),
('Security Engineer', 'Engineering', 'Hyderabad', 'Full-time', 'Senior', 2000000, 3400000, FALSE, '2024-02-20', 'Sanjay Gupta', '2024-05-20', 1, FALSE),
('Android Developer', 'Engineering', 'Pune', 'Full-time', 'Mid', 1200000, 2100000, TRUE, '2024-05-15', 'Pallavi Dutta', '2024-08-15', 1, FALSE),
('SRE Engineer', 'Engineering', 'Bangalore', 'Full-time', 'Senior', 1800000, 3000000, TRUE, '2024-03-01', 'Ravi Shekhar', '2024-06-01', 1, FALSE),
('Intern - Software Engineering', 'Engineering', 'Bangalore', 'Intern', 'Entry', 400000, 600000, FALSE, '2024-11-01', 'Pallavi Dutta', '2025-01-15', 5, FALSE),
-- Marketing (6 positions)
('Content Marketing Manager', 'Marketing', 'Mumbai', 'Full-time', 'Mid', 1200000, 1800000, TRUE, '2024-02-10', 'Anjali Rao', '2024-05-10', 1, FALSE),
('Performance Marketing Lead', 'Marketing', 'Mumbai', 'Full-time', 'Senior', 1600000, 2600000, TRUE, '2024-01-25', 'Anjali Rao', '2024-04-25', 1, TRUE),
('Brand Manager', 'Marketing', 'Delhi NCR', 'Full-time', 'Senior', 1500000, 2400000, FALSE, '2024-03-15', 'Anjali Rao', '2024-06-15', 1, FALSE),
('Marketing Analyst', 'Marketing', 'Mumbai', 'Full-time', 'Entry', 700000, 1200000, TRUE, '2024-04-20', 'Anjali Rao', '2024-07-20', 1, FALSE),
('SEO Specialist', 'Marketing', 'Remote', 'Full-time', 'Mid', 900000, 1600000, TRUE, '2024-05-10', 'Anjali Rao', '2024-08-10', 1, FALSE),
('Product Marketing Manager', 'Marketing', 'Bangalore', 'Full-time', 'Senior', 1600000, 2500000, TRUE, '2024-06-15', 'Anjali Rao', '2024-09-15', 1, FALSE),
-- Sales (7 positions)
('Enterprise Account Executive', 'Sales', 'Bangalore', 'Full-time', 'Senior', 1400000, 2200000, FALSE, '2024-01-30', 'Deepak Chopra', '2024-04-30', 2, TRUE),
('SDR Manager', 'Sales', 'Mumbai', 'Full-time', 'Manager', 1800000, 2800000, FALSE, '2024-02-25', 'Deepak Chopra', '2024-05-25', 1, FALSE),
('Sales Development Rep', 'Sales', 'Hyderabad', 'Full-time', 'Entry', 600000, 1000000, FALSE, '2024-03-05', 'Deepak Chopra', '2024-06-05', 3, FALSE),
('Solutions Consultant', 'Sales', 'Delhi NCR', 'Full-time', 'Senior', 1600000, 2600000, TRUE, '2024-04-10', 'Deepak Chopra', '2024-07-10', 1, FALSE),
('VP of Sales', 'Sales', 'Bangalore', 'Full-time', 'VP', 5000000, 8000000, FALSE, '2024-01-05', 'CEO Office', '2024-03-05', 1, TRUE),
('Channel Partnership Manager', 'Sales', 'Mumbai', 'Full-time', 'Mid', 1300000, 2000000, FALSE, '2024-05-20', 'Deepak Chopra', '2024-08-20', 1, FALSE),
('Customer Success Manager', 'Sales', 'Pune', 'Full-time', 'Mid', 1100000, 1800000, TRUE, '2024-06-01', 'Deepak Chopra', '2024-09-01', 1, FALSE),
-- HR (3 positions)
('HR Business Partner', 'HR', 'Bangalore', 'Full-time', 'Senior', 1500000, 2400000, TRUE, '2024-02-15', 'Meghna Iyer', '2024-05-15', 1, FALSE),
('Talent Acquisition Specialist', 'HR', 'Pune', 'Full-time', 'Mid', 1000000, 1600000, TRUE, '2024-03-25', 'Meghna Iyer', '2024-06-25', 2, FALSE),
('Compensation Analyst', 'HR', 'Bangalore', 'Full-time', 'Entry', 700000, 1200000, TRUE, '2024-05-05', 'Meghna Iyer', '2024-08-05', 1, FALSE),
-- Finance (4 positions)
('Financial Analyst', 'Finance', 'Mumbai', 'Full-time', 'Mid', 1000000, 1700000, FALSE, '2024-02-01', 'Rajat Bansal', '2024-05-01', 1, FALSE),
('Senior Accountant', 'Finance', 'Mumbai', 'Full-time', 'Senior', 1200000, 2000000, FALSE, '2024-03-10', 'Rajat Bansal', '2024-06-10', 1, FALSE),
('FP&A Manager', 'Finance', 'Bangalore', 'Full-time', 'Manager', 2200000, 3500000, TRUE, '2024-04-01', 'Rajat Bansal', '2024-07-01', 1, TRUE),
('Tax Specialist', 'Finance', 'Delhi NCR', 'Full-time', 'Mid', 900000, 1600000, FALSE, '2024-05-15', 'Rajat Bansal', '2024-08-15', 1, FALSE),
-- Operations (5 positions)
('Operations Manager', 'Operations', 'Hyderabad', 'Full-time', 'Manager', 1800000, 2800000, FALSE, '2024-01-20', 'Suresh Menon', '2024-04-20', 1, FALSE),
('Supply Chain Analyst', 'Operations', 'Pune', 'Full-time', 'Mid', 900000, 1500000, FALSE, '2024-02-28', 'Suresh Menon', '2024-05-28', 1, FALSE),
('Procurement Specialist', 'Operations', 'Mumbai', 'Full-time', 'Mid', 1000000, 1700000, FALSE, '2024-04-15', 'Suresh Menon', '2024-07-15', 1, FALSE),
('Program Manager', 'Operations', 'Bangalore', 'Full-time', 'Senior', 1600000, 2600000, TRUE, '2024-03-01', 'Suresh Menon', '2024-06-01', 1, TRUE),
('Business Analyst', 'Operations', 'Delhi NCR', 'Full-time', 'Mid', 1100000, 1800000, TRUE, '2024-05-25', 'Suresh Menon', '2024-08-25', 1, FALSE);

-- ============================================================================
-- DIM_RECRUITER: 8 recruiters
-- ============================================================================
INSERT INTO dim_recruiter (first_name, last_name, email, team, specialization, hire_date, is_active) VALUES
('Neha', 'Bhatia', 'neha.bhatia@company.com', 'Tech Recruiting', 'Engineering', '2022-03-15', TRUE),
('Raj', 'Shroff', 'raj.shroff@company.com', 'Tech Recruiting', 'Data & ML', '2021-08-01', TRUE),
('Meghna', 'Iyer', 'meghna.iyer@company.com', 'GTM Recruiting', 'Sales & Marketing', '2020-06-15', TRUE),
('Sandeep', 'Kaul', 'sandeep.kaul@company.com', 'GTM Recruiting', 'Finance & Operations', '2023-01-10', TRUE),
('Preeti', 'Nanda', 'preeti.nanda@company.com', 'Executive Recruiting', 'C-Level & VP', '2019-11-01', TRUE),
('Arvind', 'Swamy', 'arvind.swamy@company.com', 'Tech Recruiting', 'Engineering', '2022-09-20', TRUE),
('Disha', 'Mukherjee', 'disha.m@company.com', 'GTM Recruiting', 'HR & Admin', '2023-05-15', TRUE),
('Kiran', 'Rao', 'kiran.rao@company.com', 'Tech Recruiting', 'Product & Design', '2021-02-01', TRUE);

-- ============================================================================
-- FACT_APPLICATION: Generate ~2,500 applications
-- ============================================================================
-- This uses a systematic approach to create realistic funnel distribution:
-- ~2500 applications -> ~1800 pass screening -> ~1200 pass phone screen
-- -> ~800 pass assessment -> ~600 pass manager review -> ~400 pass technical
-- -> ~280 pass panel -> ~220 pass culture -> ~190 pass references
-- -> ~170 offer discussion -> ~150 offers extended -> ~130 accepted
-- -> ~125 background check -> ~120 onboarded

INSERT INTO fact_application (candidate_id, job_id, recruiter_id, application_date, current_stage_id, current_status, source_channel, priority_flag, time_to_current_stage_days, total_days_in_pipeline, last_activity_date)
SELECT
    c.candidate_id,
    j.job_id,
    r.recruiter_id,
    DATE_ADD(j.requisition_date, INTERVAL FLOOR(RAND() * 120) DAY),
    -- Current stage varies by status
    CASE 
        WHEN RAND() < 0.08 THEN 2   -- Stuck at Resume Screening
        WHEN RAND() < 0.15 THEN 3   -- At Phone Screen
        WHEN RAND() < 0.25 THEN 6   -- At Technical Interview
        WHEN RAND() < 0.35 THEN 11  -- Offer Extended
        WHEN RAND() < 0.50 THEN 12  -- Offer Accepted
        WHEN RAND() < 0.70 THEN 14  -- Onboarded
        ELSE 8                       -- Culture Fit Interview
    END,
    -- Status distribution
    CASE 
        WHEN RAND() < 0.55 THEN 'Rejected'
        WHEN RAND() < 0.75 THEN 'Active'
        WHEN RAND() < 0.85 THEN 'Accepted'
        WHEN RAND() < 0.92 THEN 'Withdrawn'
        WHEN RAND() < 0.97 THEN 'Offered'
        ELSE 'On Hold'
    END,
    -- Source channel
    CASE FLOOR(RAND() * 5)
        WHEN 0 THEN 'LinkedIn'
        WHEN 1 THEN 'Referral'
        WHEN 2 THEN 'Job Board'
        WHEN 3 THEN 'Career Page'
        ELSE 'Agency'
    END,
    -- Priority
    CASE 
        WHEN j.is_urgent = TRUE THEN 'Urgent'
        WHEN RAND() < 0.2 THEN 'High'
        WHEN RAND() < 0.7 THEN 'Normal'
        ELSE 'Low'
    END,
    FLOOR(RAND() * 45) + 1,
    FLOOR(RAND() * 60) + 1,
    DATE_ADD(j.requisition_date, INTERVAL FLOOR(RAND() * 150) DAY)
FROM dim_candidate c
CROSS JOIN dim_job j
CROSS JOIN dim_recruiter r
WHERE j.job_id <= 40
  AND r.recruiter_id <= 8
  AND RAND() < 0.35  -- ~2,800 rows from 200 candidates × 40 jobs × 8 recruiters
LIMIT 2500;

-- ============================================================================
-- FACT_STAGE_TRANSITION: Generate realistic stage progression data
-- ============================================================================
-- For each application, generate transitions through funnel stages

INSERT INTO fact_stage_transition (application_id, from_stage_id, to_stage_id, transition_date, transition_date_key, recruiter_id, outcome, rejection_reason_id, days_in_previous_stage, notes)
SELECT
    fa.application_id,
    -- from_stage: previous stage (NULL for first entry)
    CASE 
        WHEN ds.stage_order = 1 THEN NULL
        ELSE ds.stage_order - 1
    END,
    ds.stage_id,
    -- transition_date: staggered from application date
    DATE_ADD(fa.application_date, INTERVAL 
        CASE ds.stage_order
            WHEN 1 THEN 0
            WHEN 2 THEN FLOOR(RAND() * 3) + 1
            WHEN 3 THEN FLOOR(RAND() * 5) + 3
            WHEN 4 THEN FLOOR(RAND() * 7) + 5
            WHEN 5 THEN FLOOR(RAND() * 4) + 8
            WHEN 6 THEN FLOOR(RAND() * 10) + 10
            WHEN 7 THEN FLOOR(RAND() * 8) + 14
            WHEN 8 THEN FLOOR(RAND() * 5) + 18
            WHEN 9 THEN FLOOR(RAND() * 7) + 20
            WHEN 10 THEN FLOOR(RAND() * 3) + 22
            WHEN 11 THEN FLOOR(RAND() * 2) + 24
            WHEN 12 THEN FLOOR(RAND() * 5) + 25
            WHEN 13 THEN FLOOR(RAND() * 7) + 28
            WHEN 14 THEN FLOOR(RAND() * 5) + 32
            ELSE FLOOR(RAND() * 10)
        END DAY
    ),
    DATE_ADD(fa.application_date, INTERVAL 
        CASE ds.stage_order
            WHEN 1 THEN 0
            WHEN 2 THEN FLOOR(RAND() * 3) + 1
            ELSE FLOOR(RAND() * 10)
        END DAY
    ),
    fa.recruiter_id,
    -- outcome: probability decreases as stages progress
    CASE 
        WHEN ds.stage_order <= 2 AND RAND() < 0.72 THEN 'Passed'
        WHEN ds.stage_order <= 2 AND RAND() < 0.85 THEN 'Failed'
        WHEN ds.stage_order <= 2 THEN 'Withdrawn'
        WHEN ds.stage_order <= 5 AND RAND() < 0.65 THEN 'Passed'
        WHEN ds.stage_order <= 5 AND RAND() < 0.82 THEN 'Failed'
        WHEN ds.stage_order <= 5 THEN 'Withdrawn'
        WHEN ds.stage_order <= 8 AND RAND() < 0.70 THEN 'Passed'
        WHEN ds.stage_order <= 8 AND RAND() < 0.88 THEN 'Failed'
        WHEN ds.stage_order <= 8 THEN 'Withdrawn'
        WHEN ds.stage_order <= 11 AND RAND() < 0.80 THEN 'Passed'
        WHEN ds.stage_order <= 11 AND RAND() < 0.92 THEN 'Failed'
        WHEN ds.stage_order <= 11 THEN 'Withdrawn'
        WHEN ds.stage_order >= 12 AND RAND() < 0.90 THEN 'Passed'
        WHEN ds.stage_order >= 12 AND RAND() < 0.97 THEN 'Failed'
        ELSE 'Withdrawn'
    END,
    -- rejection reason (NULL for passed outcomes)
    CASE 
        WHEN RAND() < 0.7 THEN NULL  -- No rejection
        ELSE FLOOR(RAND() * 20) + 1   -- Random rejection reason
    END,
    -- days in previous stage
    CASE ds.stage_order
        WHEN 1 THEN 0
        WHEN 2 THEN ROUND(RAND() * 3 + 0.5, 1)
        WHEN 3 THEN ROUND(RAND() * 5 + 1, 1)
        WHEN 4 THEN ROUND(RAND() * 7 + 2, 1)
        WHEN 5 THEN ROUND(RAND() * 4 + 2, 1)
        WHEN 6 THEN ROUND(RAND() * 10 + 3, 1)
        WHEN 7 THEN ROUND(RAND() * 8 + 3, 1)
        WHEN 8 THEN ROUND(RAND() * 5 + 2, 1)
        WHEN 9 THEN ROUND(RAND() * 7 + 3, 1)
        WHEN 10 THEN ROUND(RAND() * 3 + 1, 1)
        WHEN 11 THEN ROUND(RAND() * 2 + 1, 1)
        WHEN 12 THEN ROUND(RAND() * 5 + 2, 1)
        WHEN 13 THEN ROUND(RAND() * 7 + 3, 1)
        WHEN 14 THEN ROUND(RAND() * 5 + 5, 1)
        ELSE ROUND(RAND() * 5 + 1, 1)
    END,
    NULL
FROM fact_application fa
JOIN dim_stage ds ON ds.stage_order <= (
    -- Each application progresses to a random depth in the funnel
    CASE 
        WHEN RAND() < 0.05 THEN 1
        WHEN RAND() < 0.10 THEN 2
        WHEN RAND() < 0.18 THEN 3
        WHEN RAND() < 0.28 THEN 4
        WHEN RAND() < 0.38 THEN 5
        WHEN RAND() < 0.50 THEN 6
        WHEN RAND() < 0.58 THEN 7
        WHEN RAND() < 0.65 THEN 8
        WHEN RAND() < 0.72 THEN 9
        WHEN RAND() < 0.78 THEN 10
        WHEN RAND() < 0.84 THEN 11
        WHEN RAND() < 0.90 THEN 12
        WHEN RAND() < 0.95 THEN 13
        ELSE 14
    END
)
WHERE fa.application_id <= 2500
  AND RAND() < 0.6;

-- ============================================================================
-- FACT_OFFER: Generate offers for accepted candidates
-- ============================================================================
INSERT INTO fact_offer (application_id, offer_date, offer_status, base_salary_offered, bonus_potential, equity_value, total_compensation, acceptance_deadline, response_date, decline_reason, negotiator_id)
SELECT
    fa.application_id,
    DATE_ADD(fa.application_date, INTERVAL FLOOR(RAND() * 20 + 20) DAY),
    CASE 
        WHEN RAND() < 0.75 THEN 'Accepted'
        WHEN RAND() < 0.88 THEN 'Declined'
        WHEN RAND() < 0.95 THEN 'Negotiating'
        ELSE 'Expired'
    END,
    dj.min_salary + RAND() * (dj.max_salary - dj.min_salary),
    RAND() * 300000 + 50000,
    RAND() * 500000 + 100000,
    dj.min_salary + RAND() * (dj.max_salary - dj.min_salary) + RAND() * 300000 + 50000 + RAND() * 500000,
    DATE_ADD(fa.application_date, INTERVAL FLOOR(RAND() * 5 + 25) DAY),
    DATE_ADD(fa.application_date, INTERVAL FLOOR(RAND() * 10 + 22) DAY),
    CASE 
        WHEN RAND() < 0.40 THEN 'Salary expectations too high'
        WHEN RAND() < 0.60 THEN 'Counter-offer from current employer'
        WHEN RAND() < 0.75 THEN 'Accepted another offer'
        WHEN RAND() < 0.88 THEN 'Personal reasons'
        ELSE NULL
    END,
    fa.recruiter_id
FROM fact_application fa
JOIN dim_job dj ON fa.job_id = dj.job_id
WHERE fa.current_status IN ('Accepted', 'Offered')
  AND RAND() < 0.9;

-- ============================================================================
-- FACT_ONBOARDING: Generate onboarding records
-- ============================================================================
INSERT INTO fact_onboarding (application_id, start_date, onboarding_status, onboarding_complete_date, first_90_day_status, manager_satisfaction_score, ramp_score)
SELECT
    fa.application_id,
    DATE_ADD(fo.offer_date, INTERVAL FLOOR(RAND() * 30 + 14) DAY),
    CASE 
        WHEN RAND() < 0.85 THEN 'Completed'
        WHEN RAND() < 0.95 THEN 'In Progress'
        ELSE 'Early Termination'
    END,
    CASE 
        WHEN RAND() < 0.85 THEN DATE_ADD(fo.offer_date, INTERVAL FLOOR(RAND() * 30 + 44) DAY)
        ELSE NULL
    END,
    CASE 
        WHEN RAND() < 0.80 THEN 'Active'
        WHEN RAND() < 0.90 THEN 'On PIP'
        WHEN RAND() < 0.95 THEN 'Voluntary Exit'
        ELSE 'Involuntary Exit'
    END,
    ROUND(RAND() * 2 + 3, 1),  -- 3.0 - 5.0 score
    ROUND(RAND() * 40 + 60, 2)  -- 60% - 100% ramp
FROM fact_application fa
JOIN fact_offer fo ON fa.application_id = fo.application_id
WHERE fo.offer_status = 'Accepted'
  AND RAND() < 0.95;

-- ============================================================================
-- UPDATE APPLICATION STATUSES BASED ON STAGE TRANSITIONS
-- ============================================================================
UPDATE fact_application fa
SET 
    fa.time_to_current_stage_days = (
        SELECT COALESCE(SUM(fst.days_in_previous_stage), 0)
        FROM fact_stage_transition fst
        WHERE fst.application_id = fa.application_id
    ),
    fa.total_days_in_pipeline = (
        SELECT COALESCE(SUM(fst.days_in_previous_stage), 0)
        FROM fact_stage_transition fst
        WHERE fst.application_id = fa.application_id
    ),
    fa.last_activity_date = (
        SELECT MAX(DATE(fst.transition_date))
        FROM fact_stage_transition fst
        WHERE fst.application_id = fa.application_id
    );
