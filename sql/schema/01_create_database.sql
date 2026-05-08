-- ============================================================================
-- HIRING FUNNEL ANALYTICS DASHBOARD
-- ============================================================================
-- Database Schema Creation Script
-- Description: Creates the complete database structure for tracking and 
--              analyzing the hiring funnel from application to onboarding.
-- Author: Hiring Analytics Team
-- Version: 1.0
-- ============================================================================

-- Create Database
CREATE DATABASE IF NOT EXISTS hiring_funnel_analytics;
USE hiring_funnel_analytics;

-- ============================================================================
-- DIMENSION TABLES
-- ============================================================================

-- -----------------------------------------------------------------------------
-- dim_candidate: Stores candidate demographic and profile information
-- -----------------------------------------------------------------------------
DROP TABLE IF EXISTS dim_candidate;
CREATE TABLE dim_candidate (
    candidate_id         INT PRIMARY KEY AUTO_INCREMENT,
    first_name           VARCHAR(100) NOT NULL,
    last_name            VARCHAR(100) NOT NULL,
    email                VARCHAR(255) NOT NULL,
    phone                VARCHAR(20),
    current_location     VARCHAR(100),
    years_of_experience  DECIMAL(4,1),
    education_level      VARCHAR(50),       -- Bachelors, Masters, PhD, etc.
    current_employer     VARCHAR(150),
    source_channel       VARCHAR(50),       -- LinkedIn, Referral, Job Board, Career Page, Agency
    created_at           DATETIME DEFAULT CURRENT_TIMESTAMP,
    updated_at           DATETIME DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    INDEX idx_source_channel (source_channel),
    INDEX idx_experience (years_of_experience),
    INDEX idx_location (current_location)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- -----------------------------------------------------------------------------
-- dim_job: Stores job requisition details
-- -----------------------------------------------------------------------------
DROP TABLE IF EXISTS dim_job;
CREATE TABLE dim_job (
    job_id               INT PRIMARY KEY AUTO_INCREMENT,
    job_title            VARCHAR(150) NOT NULL,
    department           VARCHAR(100) NOT NULL,  -- Engineering, Marketing, Sales, HR, Finance, Operations
    office_location      VARCHAR(100),
    employment_type      VARCHAR(30),            -- Full-time, Part-time, Contract, Intern
    seniority_level      VARCHAR(30),            -- Entry, Mid, Senior, Lead, Manager, Director, VP, C-Level
    min_salary           DECIMAL(12,2),
    max_salary           DECIMAL(12,2),
    remote_eligible      BOOLEAN DEFAULT FALSE,
    requisition_date     DATE,
    hiring_manager       VARCHAR(150),
    target_fill_date     DATE,
    headcount_required   INT DEFAULT 1,
    is_urgent            BOOLEAN DEFAULT FALSE,
    created_at           DATETIME DEFAULT CURRENT_TIMESTAMP,
    updated_at           DATETIME DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    INDEX idx_department (department),
    INDEX idx_seniority (seniority_level),
    INDEX idx_location (office_location)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- -----------------------------------------------------------------------------
-- dim_recruiter: Stores recruiter team information
-- -----------------------------------------------------------------------------
DROP TABLE IF EXISTS dim_recruiter;
CREATE TABLE dim_recruiter (
    recruiter_id         INT PRIMARY KEY AUTO_INCREMENT,
    first_name           VARCHAR(100) NOT NULL,
    last_name            VARCHAR(100) NOT NULL,
    email                VARCHAR(255) NOT NULL,
    team                 VARCHAR(80),           -- Tech Recruiting, GTM Recruiting, Executive Recruiting
    specialization       VARCHAR(100),          -- Engineering, Product, Sales, etc.
    hire_date            DATE,
    is_active            BOOLEAN DEFAULT TRUE,
    created_at           DATETIME DEFAULT CURRENT_TIMESTAMP,
    INDEX idx_team (team),
    INDEX idx_active (is_active)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- -----------------------------------------------------------------------------
-- dim_stage: Defines all stages in the hiring funnel
-- -----------------------------------------------------------------------------
DROP TABLE IF EXISTS dim_stage;
CREATE TABLE dim_stage (
    stage_id             INT PRIMARY KEY AUTO_INCREMENT,
    stage_name           VARCHAR(50) NOT NULL,
    stage_order          INT NOT NULL,           -- Sequential order in funnel
    stage_category       VARCHAR(30),            -- Screening, Interview, Assessment, Offer, Onboarding
    is_active            BOOLEAN DEFAULT TRUE,
    description          TEXT,
    UNIQUE KEY uk_stage_name (stage_name),
    INDEX idx_stage_order (stage_order)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- -----------------------------------------------------------------------------
-- dim_date: Calendar dimension for time-based analysis
-- -----------------------------------------------------------------------------
DROP TABLE IF EXISTS dim_date;
CREATE TABLE dim_date (
    date_key             DATE PRIMARY KEY,
    day_of_week          TINYINT,               -- 1=Monday .. 7=Sunday
    day_name             VARCHAR(10),
    day_of_month         TINYINT,
    week_of_year         TINYINT,
    month_number         TINYINT,
    month_name           VARCHAR(15),
    quarter              TINYINT,
    year                 SMALLINT,
    is_weekend           BOOLEAN,
    is_holiday           BOOLEAN DEFAULT FALSE,
    fiscal_quarter       VARCHAR(6),
    fiscal_year          SMALLINT
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- -----------------------------------------------------------------------------
-- dim_rejection_reason: Standardized rejection reasons
-- -----------------------------------------------------------------------------
DROP TABLE IF EXISTS dim_rejection_reason;
CREATE TABLE dim_rejection_reason (
    reason_id            INT PRIMARY KEY AUTO_INCREMENT,
    reason_category      VARCHAR(50),            -- Skills, Culture Fit, Compensation, Timing, etc.
    reason_description   VARCHAR(255) NOT NULL,
    is_active            BOOLEAN DEFAULT TRUE,
    INDEX idx_category (reason_category)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- ============================================================================
-- FACT TABLES
-- ============================================================================

-- -----------------------------------------------------------------------------
-- fact_application: Core fact table - one row per candidate-job application
-- -----------------------------------------------------------------------------
DROP TABLE IF EXISTS fact_application;
CREATE TABLE fact_application (
    application_id       INT PRIMARY KEY AUTO_INCREMENT,
    candidate_id         INT NOT NULL,
    job_id               INT NOT NULL,
    recruiter_id         INT,
    application_date     DATE NOT NULL,
    current_stage_id     INT,
    current_status       VARCHAR(30) NOT NULL,   -- Active, Offered, Accepted, Rejected, Withdrawn, On Hold
    source_channel       VARCHAR(50),
    referral_employee_id INT,
    priority_flag        VARCHAR(20) DEFAULT 'Normal',  -- Urgent, High, Normal, Low
    time_to_current_stage_days INT,
    total_days_in_pipeline INT,
    last_activity_date   DATE,
    created_at           DATETIME DEFAULT CURRENT_TIMESTAMP,
    updated_at           DATETIME DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    FOREIGN KEY (candidate_id) REFERENCES dim_candidate(candidate_id),
    FOREIGN KEY (job_id) REFERENCES dim_job(job_id),
    FOREIGN KEY (recruiter_id) REFERENCES dim_recruiter(recruiter_id),
    FOREIGN KEY (current_stage_id) REFERENCES dim_stage(stage_id),
    INDEX idx_application_date (application_date),
    INDEX idx_status (current_status),
    INDEX idx_job (job_id),
    INDEX idx_candidate (candidate_id),
    INDEX idx_recruiter (recruiter_id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- -----------------------------------------------------------------------------
-- fact_stage_transition: Tracks every stage movement for funnel analysis
-- -----------------------------------------------------------------------------
DROP TABLE IF EXISTS fact_stage_transition;
CREATE TABLE fact_stage_transition (
    transition_id        BIGINT PRIMARY KEY AUTO_INCREMENT,
    application_id       INT NOT NULL,
    from_stage_id        INT,                   -- NULL for initial entry
    to_stage_id          INT NOT NULL,
    transition_date      DATETIME NOT NULL,
    transition_date_key  DATE,                  -- Link to dim_date
    recruiter_id         INT,
    decision_maker       VARCHAR(150),
    outcome              VARCHAR(30),           -- Passed, Failed, Withdrawn, No Show
    rejection_reason_id  INT,
    days_in_previous_stage DECIMAL(8,2),
    notes                TEXT,
    created_at           DATETIME DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (application_id) REFERENCES fact_application(application_id),
    FOREIGN KEY (from_stage_id) REFERENCES dim_stage(stage_id),
    FOREIGN KEY (to_stage_id) REFERENCES dim_stage(stage_id),
    FOREIGN KEY (recruiter_id) REFERENCES dim_recruiter(recruiter_id),
    FOREIGN KEY (rejection_reason_id) REFERENCES dim_rejection_reason(reason_id),
    INDEX idx_transition_date (transition_date),
    INDEX idx_from_stage (from_stage_id),
    INDEX idx_to_stage (to_stage_id),
    INDEX idx_application (application_id),
    INDEX idx_outcome (outcome)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- -----------------------------------------------------------------------------
-- fact_offer: Tracks offer details for accepted candidates
-- -----------------------------------------------------------------------------
DROP TABLE IF EXISTS fact_offer;
CREATE TABLE fact_offer (
    offer_id             INT PRIMARY KEY AUTO_INCREMENT,
    application_id       INT NOT NULL,
    offer_date           DATE NOT NULL,
    offer_status         VARCHAR(30),           -- Pending, Accepted, Declined, Negotiating, Expired
    base_salary_offered  DECIMAL(12,2),
    bonus_potential      DECIMAL(12,2),
    equity_value         DECIMAL(12,2),
    total_compensation   DECIMAL(12,2),
    acceptance_deadline  DATE,
    response_date        DATE,
    decline_reason       VARCHAR(200),
    negotiator_id        INT,
    created_at           DATETIME DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (application_id) REFERENCES fact_application(application_id),
    INDEX idx_offer_status (offer_status),
    INDEX idx_offer_date (offer_date)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- -----------------------------------------------------------------------------
-- fact_onboarding: Tracks onboarding completion metrics
-- -----------------------------------------------------------------------------
DROP TABLE IF EXISTS fact_onboarding;
CREATE TABLE fact_onboarding (
    onboarding_id        INT PRIMARY KEY AUTO_INCREMENT,
    application_id       INT NOT NULL,
    start_date           DATE NOT NULL,
    onboarding_status    VARCHAR(30),           -- In Progress, Completed, Early Termination
    onboarding_complete_date DATE,
    first_90_day_status  VARCHAR(30),           -- Active, On PIP, Voluntary Exit, Involuntary Exit
    manager_satisfaction_score DECIMAL(3,1),    -- 1.0 - 5.0
    ramp_score           DECIMAL(5,2),          -- % of productivity target at 90 days
    created_at           DATETIME DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (application_id) REFERENCES fact_application(application_id),
    INDEX idx_start_date (start_date),
    INDEX idx_status (onboarding_status)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- ============================================================================
-- SEED DIM_STAGE with standard funnel stages
-- ============================================================================
INSERT INTO dim_stage (stage_name, stage_order, stage_category, description) VALUES
('Application Received',    1,  'Screening',   'Candidate has submitted an application'),
('Resume Screening',        2,  'Screening',   'Recruiter/TA reviews resume against job requirements'),
('Phone Screen',            3,  'Screening',   'Initial phone call with recruiter to assess basic fit'),
('Assessment/Test',         4,  'Assessment',  'Technical test, coding challenge, or skills assessment'),
('Hiring Manager Review',   5,  'Interview',   'Hiring manager reviews screened candidates'),
('Technical Interview',     6,  'Interview',   'Deep-dive technical evaluation with team members'),
('Panel Interview',         7,  'Interview',   'Cross-functional or panel interview round'),
('Culture Fit Interview',   8,  'Interview',   'Values and culture alignment evaluation'),
('Reference Check',         9,  'Assessment',  'Professional reference verification'),
('Offer Discussion',        10, 'Offer',       'Internal alignment on offer terms'),
('Offer Extended',          11, 'Offer',       'Formal offer letter sent to candidate'),
('Offer Accepted',          12, 'Offer',       'Candidate has accepted the offer'),
('Background Check',        13, 'Onboarding',  'Pre-employment verification in progress'),
('Onboarding Started',      14, 'Onboarding',  'Candidate has started onboarding process');

-- ============================================================================
-- SEED DIM_REJECTION_REASON with standardized reasons
-- ============================================================================
INSERT INTO dim_rejection_reason (reason_category, reason_description) VALUES
('Skills',           'Insufficient technical skills for the role'),
('Skills',           'Lack of required domain expertise'),
('Skills',           'Overqualified for the position'),
('Experience',       'Insufficient years of experience'),
('Experience',       'No relevant industry experience'),
('Culture Fit',      'Not aligned with company values'),
('Culture Fit',      'Communication style mismatch'),
('Culture Fit',      'Team dynamics concern'),
('Compensation',     'Salary expectations too high'),
('Compensation',     'Counter-offer from current employer'),
('Compensation',     'Benefits package insufficient'),
('Timing',           'Candidate withdrew - accepted another offer'),
('Timing',           'Candidate withdrew - personal reasons'),
('Timing',           'Candidate not available for start date'),
('Availability',     'Candidate did not respond to outreach'),
('Availability',     'Candidate no-showed for interview'),
('Availability',     'Candidate declined to proceed'),
('Other',            'Position put on hold'),
('Other',            'Requisition cancelled'),
('Other',            'Internal transfer selected instead');

-- ============================================================================
-- VIEWS for Power BI Integration
-- ============================================================================

-- View: Application Summary (denormalized for reporting)
CREATE OR REPLACE VIEW vw_application_summary AS
SELECT
    fa.application_id,
    dc.candidate_id,
    CONCAT(dc.first_name, ' ', dc.last_name) AS candidate_name,
    dc.source_channel AS candidate_source,
    dc.years_of_experience,
    dc.education_level,
    dc.current_location,
    dj.job_id,
    dj.job_title,
    dj.department,
    dj.seniority_level,
    dj.employment_type,
    dj.office_location,
    dj.remote_eligible,
    CONCAT(dr.first_name, ' ', dr.last_name) AS recruiter_name,
    dr.team AS recruiter_team,
    fa.application_date,
    ds.stage_name AS current_stage,
    fa.current_status,
    fa.priority_flag,
    fa.time_to_current_stage_days,
    fa.total_days_in_pipeline,
    fo.base_salary_offered,
    fo.offer_status,
    fo.total_compensation
FROM fact_application fa
LEFT JOIN dim_candidate dc ON fa.candidate_id = dc.candidate_id
LEFT JOIN dim_job dj ON fa.job_id = dj.job_id
LEFT JOIN dim_recruiter dr ON fa.recruiter_id = dr.recruiter_id
LEFT JOIN dim_stage ds ON fa.current_stage_id = ds.stage_id
LEFT JOIN fact_offer fo ON fa.application_id = fo.application_id;

-- View: Funnel Metrics (stage-level aggregation)
CREATE OR REPLACE VIEW vw_funnel_metrics AS
SELECT
    fst.to_stage_id,
    ds.stage_name,
    ds.stage_order,
    ds.stage_category,
    COUNT(DISTINCT fst.application_id) AS candidates_entered,
    COUNT(DISTINCT CASE WHEN fst.outcome = 'Passed' THEN fst.application_id END) AS candidates_passed,
    COUNT(DISTINCT CASE WHEN fst.outcome = 'Failed' THEN fst.application_id END) AS candidates_failed,
    COUNT(DISTINCT CASE WHEN fst.outcome = 'Withdrawn' THEN fst.application_id END) AS candidates_withdrawn,
    AVG(fst.days_in_previous_stage) AS avg_days_in_stage,
    DATE(fst.transition_date) AS transition_date
FROM fact_stage_transition fst
JOIN dim_stage ds ON fst.to_stage_id = ds.stage_id
GROUP BY fst.to_stage_id, ds.stage_name, ds.stage_order, ds.stage_category, DATE(fst.transition_date);

-- ============================================================================
-- STORED PROCEDURES
-- ============================================================================

DELIMITER //

-- Procedure: Calculate conversion rates between any two stages
CREATE PROCEDURE sp_stage_conversion_rate(
    IN p_from_stage VARCHAR(50),
    IN p_to_stage VARCHAR(50),
    IN p_start_date DATE,
    IN p_end_date DATE
)
BEGIN
    SELECT
        p_from_stage AS from_stage,
        p_to_stage AS to_stage,
        entered_count,
        exited_count,
        ROUND((exited_count / NULLIF(entered_count, 0)) * 100, 2) AS conversion_rate_pct,
        ROUND((1 - (exited_count / NULLIF(entered_count, 0))) * 100, 2) AS drop_off_rate_pct
    FROM (
        SELECT
            (SELECT COUNT(DISTINCT application_id) 
             FROM fact_stage_transition 
             WHERE to_stage_id = (SELECT stage_id FROM dim_stage WHERE stage_name = p_from_stage)
             AND DATE(transition_date) BETWEEN p_start_date AND p_end_date
            ) AS entered_count,
            (SELECT COUNT(DISTINCT application_id) 
             FROM fact_stage_transition 
             WHERE to_stage_id = (SELECT stage_id FROM dim_stage WHERE stage_name = p_to_stage)
             AND DATE(transition_date) BETWEEN p_start_date AND p_end_date
            ) AS exited_count
    ) AS counts;
END //

-- Procedure: Monthly hiring funnel summary
CREATE PROCEDURE sp_monthly_funnel_summary(
    IN p_year INT,
    IN p_month INT
)
BEGIN
    SELECT
        ds.stage_name,
        ds.stage_order,
        COUNT(DISTINCT fst.application_id) AS total_candidates,
        COUNT(DISTINCT CASE WHEN fst.outcome = 'Passed' THEN fst.application_id END) AS passed,
        COUNT(DISTINCT CASE WHEN fst.outcome = 'Failed' THEN fst.application_id END) AS failed,
        COUNT(DISTINCT CASE WHEN fst.outcome = 'Withdrawn' THEN fst.application_id END) AS withdrawn,
        ROUND(AVG(fst.days_in_previous_stage), 1) AS avg_days_in_stage,
        LAG(COUNT(DISTINCT fst.application_id)) OVER (ORDER BY ds.stage_order) AS prev_stage_count,
        ROUND(
            COUNT(DISTINCT fst.application_id) / 
            NULLIF(LAG(COUNT(DISTINCT fst.application_id)) OVER (ORDER BY ds.stage_order), 0) * 100, 
            2
        ) AS stage_conversion_pct
    FROM fact_stage_transition fst
    JOIN dim_stage ds ON fst.to_stage_id = ds.stage_id
    WHERE YEAR(fst.transition_date) = p_year
      AND MONTH(fst.transition_date) = p_month
    GROUP BY ds.stage_name, ds.stage_order
    ORDER BY ds.stage_order;
END //

DELIMITER ;

-- ============================================================================
-- GRANT PERMISSIONS (adjust for your environment)
-- ============================================================================
-- GRANT SELECT ON hiring_funnel_analytics.* TO 'powerbi_user'@'%';
-- GRANT SELECT ON hiring_funnel_analytics.* TO 'analyst_user'@'%';
