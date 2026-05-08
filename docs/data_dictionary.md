# Data Dictionary

## Hiring Funnel Analytics Database

---

## Dimension Tables

### dim_candidate

| Column | Data Type | Description | Example Values |
|---|---|---|---|
| candidate_id | INT (PK) | Unique identifier for each candidate | 1, 2, 3 |
| first_name | VARCHAR(100) | Candidate's first name | Arjun, Priya |
| last_name | VARCHAR(100) | Candidate's last name | Mehta, Sharma |
| email | VARCHAR(255) | Email address (unique) | arjun.mehta@email.com |
| phone | VARCHAR(20) | Phone number with country code | +91-98765-43210 |
| current_location | VARCHAR(100) | Current city of residence | Bangalore, Mumbai |
| years_of_experience | DECIMAL(4,1) | Total professional experience in years | 3.0, 8.5, 15.0 |
| education_level | VARCHAR(50) | Highest education attained | Bachelors, Masters, PhD, MBA, CA |
| current_employer | VARCHAR(150) | Current company name | Infosys, Google, Fresh Graduate |
| source_channel | VARCHAR(50) | How the candidate was sourced | LinkedIn, Referral, Job Board, Career Page, Agency |
| created_at | DATETIME | Record creation timestamp | 2024-01-15 10:30:00 |
| updated_at | DATETIME | Record last update timestamp | 2024-03-20 14:45:00 |

---

### dim_job

| Column | Data Type | Description | Example Values |
|---|---|---|---|
| job_id | INT (PK) | Unique identifier for each job requisition | 1, 2, 3 |
| job_title | VARCHAR(150) | Title of the position | Senior Software Engineer |
| department | VARCHAR(100) | Department hiring for | Engineering, Marketing, Sales, HR, Finance, Operations |
| office_location | VARCHAR(100) | Primary office location | Bangalore, Mumbai, Remote |
| employment_type | VARCHAR(30) | Type of employment | Full-time, Part-time, Contract, Intern |
| seniority_level | VARCHAR(30) | Required seniority | Entry, Mid, Senior, Lead, Manager, Director, VP, C-Level |
| min_salary | DECIMAL(12,2) | Minimum salary for the role (INR) | 1800000 |
| max_salary | DECIMAL(12,2) | Maximum salary for the role (INR) | 2800000 |
| remote_eligible | BOOLEAN | Whether the role allows remote work | TRUE, FALSE |
| requisition_date | DATE | When the position was opened | 2024-01-15 |
| hiring_manager | VARCHAR(150) | Name of the hiring manager | Ravi Shekhar |
| target_fill_date | DATE | Target date to fill the position | 2024-04-15 |
| headcount_required | INT | Number of positions to fill | 1, 2, 3, 5 |
| is_urgent | BOOLEAN | Whether the req is marked urgent | TRUE, FALSE |
| created_at | DATETIME | Record creation timestamp | |
| updated_at | DATETIME | Record last update timestamp | |

---

### dim_recruiter

| Column | Data Type | Description | Example Values |
|---|---|---|---|
| recruiter_id | INT (PK) | Unique identifier for each recruiter | 1, 2, 3 |
| first_name | VARCHAR(100) | Recruiter's first name | Neha, Raj |
| last_name | VARCHAR(100) | Recruiter's last name | Bhatia, Shroff |
| email | VARCHAR(255) | Work email address | neha.bhatia@company.com |
| team | VARCHAR(80) | Recruiting team name | Tech Recruiting, GTM Recruiting, Executive Recruiting |
| specialization | VARCHAR(100) | Department/role focus area | Engineering, Sales & Marketing |
| hire_date | DATE | Recruiter's start date | 2022-03-15 |
| is_active | BOOLEAN | Currently employed | TRUE, FALSE |
| created_at | DATETIME | Record creation timestamp | |

---

### dim_stage

| Column | Data Type | Description | Example Values |
|---|---|---|---|
| stage_id | INT (PK) | Unique identifier for each stage | 1-14 |
| stage_name | VARCHAR(50) | Human-readable stage name | Application Received, Phone Screen |
| stage_order | INT | Sequential position in the funnel | 1, 2, 3...14 |
| stage_category | VARCHAR(30) | Grouping category | Screening, Interview, Assessment, Offer, Onboarding |
| is_active | BOOLEAN | Whether the stage is currently in use | TRUE |
| description | TEXT | Detailed description of the stage | |

**Standard Stages:**

| Order | Stage Name | Category |
|---|---|---|
| 1 | Application Received | Screening |
| 2 | Resume Screening | Screening |
| 3 | Phone Screen | Screening |
| 4 | Assessment/Test | Assessment |
| 5 | Hiring Manager Review | Interview |
| 6 | Technical Interview | Interview |
| 7 | Panel Interview | Interview |
| 8 | Culture Fit Interview | Interview |
| 9 | Reference Check | Assessment |
| 10 | Offer Discussion | Offer |
| 11 | Offer Extended | Offer |
| 12 | Offer Accepted | Offer |
| 13 | Background Check | Onboarding |
| 14 | Onboarding Started | Onboarding |

---

### dim_date

| Column | Data Type | Description | Example Values |
|---|---|---|---|
| date_key | DATE (PK) | Calendar date | 2024-01-15 |
| day_of_week | TINYINT | 1=Monday...7=Sunday | 1, 2, 3 |
| day_name | VARCHAR(10) | Day name | Monday, Tuesday |
| day_of_month | TINYINT | Day number within month | 1-31 |
| week_of_year | TINYINT | ISO week number | 1-52 |
| month_number | TINYINT | Month number | 1-12 |
| month_name | VARCHAR(15) | Month name | January |
| quarter | TINYINT | Calendar quarter | 1, 2, 3, 4 |
| year | SMALLINT | Calendar year | 2024, 2025 |
| is_weekend | BOOLEAN | Saturday or Sunday | TRUE, FALSE |
| is_holiday | BOOLEAN | Company holiday | TRUE, FALSE |
| fiscal_quarter | VARCHAR(6) | Fiscal quarter label | Q1_2024 |
| fiscal_year | SMALLINT | Fiscal year | 2024 |

---

### dim_rejection_reason

| Column | Data Type | Description | Example Values |
|---|---|---|---|
| reason_id | INT (PK) | Unique identifier | 1-20 |
| reason_category | VARCHAR(50) | High-level category | Skills, Experience, Culture Fit, Compensation, Timing, Availability, Other |
| reason_description | VARCHAR(255) | Specific reason text | Insufficient technical skills for the role |
| is_active | BOOLEAN | Currently in use | TRUE |

---

## Fact Tables

### fact_application

| Column | Data Type | Description | Example Values |
|---|---|---|---|
| application_id | INT (PK) | Unique identifier per candidate-job pair | 1, 2, 3 |
| candidate_id | INT (FK) | Reference to dim_candidate | |
| job_id | INT (FK) | Reference to dim_job | |
| recruiter_id | INT (FK) | Assigned recruiter | |
| application_date | DATE | Date application was submitted | 2024-02-15 |
| current_stage_id | INT (FK) | Current funnel stage | 1-14 |
| current_status | VARCHAR(30) | Application status | Active, Offered, Accepted, Rejected, Withdrawn, On Hold |
| source_channel | VARCHAR(50) | Application source override | LinkedIn, Referral |
| referral_employee_id | INT | Referring employee (NULL if not referral) | 101, NULL |
| priority_flag | VARCHAR(20) | Priority level | Urgent, High, Normal, Low |
| time_to_current_stage_days | INT | Days from application to current stage | 12 |
| total_days_in_pipeline | INT | Total days the application has been active | 45 |
| last_activity_date | DATE | Most recent activity date | 2024-03-30 |
| created_at | DATETIME | Record creation timestamp | |
| updated_at | DATETIME | Record last update timestamp | |

---

### fact_stage_transition

| Column | Data Type | Description | Example Values |
|---|---|---|---|
| transition_id | BIGINT (PK) | Unique identifier for each transition | 1, 2, 3 |
| application_id | INT (FK) | Reference to fact_application | |
| from_stage_id | INT (FK) | Previous stage (NULL for initial entry) | NULL, 2, 5 |
| to_stage_id | INT (FK) | New stage entered | 1, 3, 6 |
| transition_date | DATETIME | When the transition occurred | 2024-02-15 14:30:00 |
| transition_date_key | DATE | Date key for dim_date join | 2024-02-15 |
| recruiter_id | INT (FK) | Recruiter who processed the transition | |
| decision_maker | VARCHAR(150) | Person who made the decision | Ravi Shekhar |
| outcome | VARCHAR(30) | Result of the transition | Passed, Failed, Withdrawn, No Show |
| rejection_reason_id | INT (FK) | Reason if outcome is Failed | NULL, 1-20 |
| days_in_previous_stage | DECIMAL(8,2) | Time spent in the from_stage | 3.5, 12.0 |
| notes | TEXT | Additional context | |
| created_at | DATETIME | Record creation timestamp | |

---

### fact_offer

| Column | Data Type | Description | Example Values |
|---|---|---|---|
| offer_id | INT (PK) | Unique identifier for each offer | 1, 2, 3 |
| application_id | INT (FK) | Reference to fact_application | |
| offer_date | DATE | Date offer was extended | 2024-03-20 |
| offer_status | VARCHAR(30) | Current offer status | Pending, Accepted, Declined, Negotiating, Expired |
| base_salary_offered | DECIMAL(12,2) | Annual base salary (INR) | 2500000 |
| bonus_potential | DECIMAL(12,2) | Annual bonus potential (INR) | 300000 |
| equity_value | DECIMAL(12,2) | Equity/RSU value (INR) | 500000 |
| total_compensation | DECIMAL(12,2) | Total annual compensation (INR) | 3300000 |
| acceptance_deadline | DATE | Deadline for candidate response | 2024-04-03 |
| response_date | DATE | Actual response date | 2024-03-28 |
| decline_reason | VARCHAR(200) | Reason if declined | Salary expectations too high |
| negotiator_id | INT | Recruiter who handled negotiation | |
| created_at | DATETIME | Record creation timestamp | |

---

### fact_onboarding

| Column | Data Type | Description | Example Values |
|---|---|---|---|
| onboarding_id | INT (PK) | Unique identifier | 1, 2, 3 |
| application_id | INT (FK) | Reference to fact_application | |
| start_date | DATE | Employee start date | 2024-04-15 |
| onboarding_status | VARCHAR(30) | Onboarding completion status | In Progress, Completed, Early Termination |
| onboarding_complete_date | DATE | Date onboarding was completed | 2024-05-20 |
| first_90_day_status | VARCHAR(30) | Status at 90-day mark | Active, On PIP, Voluntary Exit, Involuntary Exit |
| manager_satisfaction_score | DECIMAL(3,1) | Manager's rating (1.0-5.0) | 4.2, 3.8 |
| ramp_score | DECIMAL(5,2) | Productivity % at 90 days | 78.50, 92.00 |
| created_at | DATETIME | Record creation timestamp | |
