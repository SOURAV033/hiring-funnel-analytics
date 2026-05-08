-- ============================================================================
-- HIRING FUNNEL ANALYTICS DASHBOARD
-- ============================================================================
-- KPI Tracking SQL Queries
-- Description: Core KPIs for executive dashboard reporting
-- ============================================================================

USE hiring_funnel_analytics;

-- ============================================================================
-- 1. OVERALL HIRING FUNNEL SUMMARY KPIs
-- ============================================================================
-- Primary dashboard KPIs: Volume, Rate, and Time metrics

SELECT
    'Total Applications' AS kpi_name,
    COUNT(*) AS kpi_value,
    'count' AS kpi_unit
FROM fact_application
WHERE application_date BETWEEN '2024-01-01' AND '2025-06-30'

UNION ALL

SELECT
    'Active Pipeline' AS kpi_name,
    COUNT(*) AS kpi_value,
    'count' AS kpi_unit
FROM fact_application
WHERE current_status = 'Active'
  AND application_date BETWEEN '2024-01-01' AND '2025-06-30'

UNION ALL

SELECT
    'Offers Extended' AS kpi_name,
    COUNT(*) AS kpi_value,
    'count' AS kpi_unit
FROM fact_offer
WHERE offer_date BETWEEN '2024-01-01' AND '2025-06-30'

UNION ALL

SELECT
    'Offers Accepted' AS kpi_name,
    COUNT(*) AS kpi_value,
    'count' AS kpi_unit
FROM fact_offer
WHERE offer_status = 'Accepted'
  AND offer_date BETWEEN '2024-01-01' AND '2025-06-30'

UNION ALL

SELECT
    'Overall Offer Acceptance Rate' AS kpi_name,
    ROUND(
        COUNT(CASE WHEN offer_status = 'Accepted' THEN 1 END) / 
        NULLIF(COUNT(*), 0) * 100, 1
    ) AS kpi_value,
    '%' AS kpi_unit
FROM fact_offer
WHERE offer_date BETWEEN '2024-01-01' AND '2025-06-30'

UNION ALL

SELECT
    'Avg Days to Hire' AS kpi_name,
    ROUND(AVG(total_days_in_pipeline), 1) AS kpi_value,
    'days' AS kpi_unit
FROM fact_application
WHERE current_status = 'Accepted'
  AND application_date BETWEEN '2024-01-01' AND '2025-06-30'

UNION ALL

SELECT
    'Avg Days in Pipeline (All)' AS kpi_name,
    ROUND(AVG(total_days_in_pipeline), 1) AS kpi_value,
    'days' AS kpi_unit
FROM fact_application
WHERE application_date BETWEEN '2024-01-01' AND '2025-06-30';


-- ============================================================================
-- 2. MONTHLY KPI TRENDS (Time-Series for Dashboard)
-- ============================================================================

SELECT
    DATE_FORMAT(fa.application_date, '%Y-%m') AS month,
    COUNT(*) AS total_applications,
    COUNT(DISTINCT fa.job_id) AS active_positions,
    COUNT(DISTINCT fa.recruiter_id) AS active_recruiters,
    SUM(CASE WHEN fa.current_status = 'Accepted' THEN 1 ELSE 0 END) AS hires_made,
    SUM(CASE WHEN fa.current_status = 'Rejected' THEN 1 ELSE 0 END) AS rejections,
    SUM(CASE WHEN fa.current_status = 'Withdrawn' THEN 1 ELSE 0 END) AS withdrawals,
    ROUND(AVG(fa.total_days_in_pipeline), 1) AS avg_days_in_pipeline,
    ROUND(
        SUM(CASE WHEN fa.current_status = 'Accepted' THEN 1 ELSE 0 END) / 
        NULLIF(COUNT(*), 0) * 100, 1
    ) AS overall_conversion_pct
FROM fact_application fa
WHERE fa.application_date BETWEEN '2024-01-01' AND '2025-06-30'
GROUP BY DATE_FORMAT(fa.application_date, '%Y-%m')
ORDER BY month;


-- ============================================================================
-- 3. DEPARTMENT-WISE KPI DASHBOARD
-- ============================================================================

SELECT
    dj.department,
    COUNT(DISTINCT fa.application_id) AS total_applications,
    COUNT(DISTINCT CASE WHEN fa.current_status = 'Active' THEN fa.application_id END) AS active_candidates,
    COUNT(DISTINCT CASE WHEN fa.current_status = 'Accepted' THEN fa.application_id END) AS hires,
    COUNT(DISTINCT CASE WHEN fa.current_status = 'Rejected' THEN fa.application_id END) AS rejections,
    COUNT(DISTINCT CASE WHEN fa.current_status = 'Withdrawn' THEN fa.application_id END) AS withdrawals,
    ROUND(AVG(CASE WHEN fa.current_status = 'Accepted' THEN fa.total_days_in_pipeline END), 1) AS avg_time_to_hire_days,
    ROUND(
        COUNT(DISTINCT CASE WHEN fa.current_status = 'Accepted' THEN fa.application_id END) / 
        NULLIF(COUNT(DISTINCT fa.application_id), 0) * 100, 1
    ) AS hire_conversion_pct,
    ROUND(
        COUNT(DISTINCT CASE WHEN fa.current_status = 'Withdrawn' THEN fa.application_id END) / 
        NULLIF(COUNT(DISTINCT fa.application_id), 0) * 100, 1
    ) AS withdrawal_rate_pct,
    dj.headcount_required AS target_headcount,
    COUNT(DISTINCT CASE WHEN fa.current_status = 'Accepted' THEN fa.application_id END) AS filled_headcount,
    ROUND(
        COUNT(DISTINCT CASE WHEN fa.current_status = 'Accepted' THEN fa.application_id END) / 
        NULLIF(dj.headcount_required, 0) * 100, 1
    ) AS fill_rate_pct
FROM fact_application fa
JOIN dim_job dj ON fa.job_id = dj.job_id
WHERE fa.application_date BETWEEN '2024-01-01' AND '2025-06-30'
GROUP BY dj.department, dj.headcount_required
ORDER BY total_applications DESC;


-- ============================================================================
-- 4. RECRUITER PERFORMANCE KPIs
-- ============================================================================

SELECT
    CONCAT(dr.first_name, ' ', dr.last_name) AS recruiter_name,
    dr.team AS recruiter_team,
    dr.specialization,
    COUNT(DISTINCT fa.application_id) AS total_assigned,
    COUNT(DISTINCT CASE WHEN fa.current_status = 'Accepted' THEN fa.application_id END) AS successful_hires,
    COUNT(DISTINCT CASE WHEN fa.current_status = 'Rejected' THEN fa.application_id END) AS rejections,
    COUNT(DISTINCT CASE WHEN fa.current_status = 'Active' THEN fa.application_id END) AS active_pipeline,
    ROUND(
        COUNT(DISTINCT CASE WHEN fa.current_status = 'Accepted' THEN fa.application_id END) / 
        NULLIF(COUNT(DISTINCT fa.application_id), 0) * 100, 1
    ) AS hire_rate_pct,
    ROUND(AVG(CASE WHEN fa.current_status = 'Accepted' THEN fa.total_days_in_pipeline END), 1) AS avg_time_to_hire,
    ROUND(AVG(fa.total_days_in_pipeline), 1) AS avg_pipeline_duration,
    COUNT(DISTINCT CASE WHEN fa.priority_flag = 'Urgent' THEN fa.application_id END) AS urgent_reqs_handled
FROM fact_application fa
JOIN dim_recruiter dr ON fa.recruiter_id = dr.recruiter_id
WHERE fa.application_date BETWEEN '2024-01-01' AND '2025-06-30'
  AND dr.is_active = TRUE
GROUP BY dr.recruiter_id, dr.first_name, dr.last_name, dr.team, dr.specialization
ORDER BY successful_hires DESC;


-- ============================================================================
-- 5. SOURCE CHANNEL EFFECTIVENESS KPIs
-- ============================================================================

SELECT
    COALESCE(fa.source_channel, dc.source_channel) AS source_channel,
    COUNT(DISTINCT fa.application_id) AS total_applications,
    COUNT(DISTINCT CASE WHEN fa.current_status = 'Accepted' THEN fa.application_id END) AS hires,
    ROUND(
        COUNT(DISTINCT CASE WHEN fa.current_status = 'Accepted' THEN fa.application_id END) / 
        NULLIF(COUNT(DISTINCT fa.application_id), 0) * 100, 1
    ) AS conversion_rate_pct,
    ROUND(AVG(CASE WHEN fa.current_status = 'Accepted' THEN fa.total_days_in_pipeline END), 1) AS avg_time_to_hire,
    COUNT(DISTINCT CASE WHEN fa.current_status = 'Rejected' THEN fa.application_id END) AS rejections,
    ROUND(
        COUNT(DISTINCT CASE WHEN fa.current_status = 'Withdrawn' THEN fa.application_id END) / 
        NULLIF(COUNT(DISTINCT fa.application_id), 0) * 100, 1
    ) AS withdrawal_rate_pct
FROM fact_application fa
LEFT JOIN dim_candidate dc ON fa.candidate_id = dc.candidate_id
WHERE fa.application_date BETWEEN '2024-01-01' AND '2025-06-30'
GROUP BY COALESCE(fa.source_channel, dc.source_channel)
ORDER BY total_applications DESC;


-- ============================================================================
-- 6. SENIORITY-LEVEL HIRING KPIs
-- ============================================================================

SELECT
    dj.seniority_level,
    COUNT(DISTINCT fa.application_id) AS applications,
    COUNT(DISTINCT CASE WHEN fa.current_status = 'Accepted' THEN fa.application_id END) AS hires,
    ROUND(
        COUNT(DISTINCT CASE WHEN fa.current_status = 'Accepted' THEN fa.application_id END) / 
        NULLIF(COUNT(DISTINCT fa.application_id), 0) * 100, 1
    ) AS conversion_pct,
    ROUND(AVG(CASE WHEN fa.current_status = 'Accepted' THEN fa.total_days_in_pipeline END), 1) AS avg_time_to_hire,
    ROUND(AVG(fo.total_compensation), 0) AS avg_compensation
FROM fact_application fa
JOIN dim_job dj ON fa.job_id = dj.job_id
LEFT JOIN fact_offer fo ON fa.application_id = fo.application_id
WHERE fa.application_date BETWEEN '2024-01-01' AND '2025-06-30'
GROUP BY dj.seniority_level
ORDER BY FIELD(dj.seniority_level, 'Entry', 'Mid', 'Senior', 'Lead', 'Manager', 'Director', 'VP', 'C-Level');


-- ============================================================================
-- 7. TIME-TO-HIRE BY DEPARTMENT (Detailed KPI)
-- ============================================================================

SELECT
    dj.department,
    COUNT(CASE WHEN fa.current_status = 'Accepted' THEN 1 END) AS total_hires,
    ROUND(MIN(CASE WHEN fa.current_status = 'Accepted' THEN fa.total_days_in_pipeline END), 1) AS min_days,
    ROUND(MAX(CASE WHEN fa.current_status = 'Accepted' THEN fa.total_days_in_pipeline END), 1) AS max_days,
    ROUND(AVG(CASE WHEN fa.current_status = 'Accepted' THEN fa.total_days_in_pipeline END), 1) AS avg_days,
    ROUND(
        -- Median approximation
        (SELECT AVG(total_days_in_pipeline) 
         FROM fact_application fa2 
         JOIN dim_job dj2 ON fa2.job_id = dj2.job_id
         WHERE dj2.department = dj.department 
           AND fa2.current_status = 'Accepted'
           AND fa2.application_date BETWEEN '2024-01-01' AND '2025-06-30'
         ORDER BY total_days_in_pipeline 
         LIMIT 1 OFFSET (
             SELECT FLOOR(COUNT(*)/2) 
             FROM fact_application fa3 
             JOIN dim_job dj3 ON fa3.job_id = dj3.job_id
             WHERE dj3.department = dj.department 
               AND fa3.current_status = 'Accepted'
               AND fa3.application_date BETWEEN '2024-01-01' AND '2025-06-30'
         )), 1
    ) AS median_days,
    ROUND(AVG(fo.total_compensation), 0) AS avg_compensation_offered
FROM fact_application fa
JOIN dim_job dj ON fa.job_id = dj.job_id
LEFT JOIN fact_offer fo ON fa.application_id = fo.application_id AND fo.offer_status = 'Accepted'
WHERE fa.application_date BETWEEN '2024-01-01' AND '2025-06-30'
GROUP BY dj.department
ORDER BY avg_days DESC;


-- ============================================================================
-- 8. OFFER-TO-ACCEPTANCE KPIs
-- ============================================================================

SELECT
    dj.department,
    COUNT(fo.offer_id) AS total_offers,
    SUM(CASE WHEN fo.offer_status = 'Accepted' THEN 1 ELSE 0 END) AS accepted,
    SUM(CASE WHEN fo.offer_status = 'Declined' THEN 1 ELSE 0 END) AS declined,
    SUM(CASE WHEN fo.offer_status = 'Negotiating' THEN 1 ELSE 0 END) AS negotiating,
    SUM(CASE WHEN fo.offer_status = 'Expired' THEN 1 ELSE 0 END) AS expired,
    ROUND(
        SUM(CASE WHEN fo.offer_status = 'Accepted' THEN 1 ELSE 0 END) / 
        NULLIF(COUNT(fo.offer_id), 0) * 100, 1
    ) AS acceptance_rate_pct,
    ROUND(AVG(fo.base_salary_offered), 0) AS avg_base_salary,
    ROUND(AVG(fo.total_compensation), 0) AS avg_total_comp
FROM fact_offer fo
JOIN fact_application fa ON fo.application_id = fa.application_id
JOIN dim_job dj ON fa.job_id = dj.job_id
WHERE fo.offer_date BETWEEN '2024-01-01' AND '2025-06-30'
GROUP BY dj.department
ORDER BY acceptance_rate_pct DESC;


-- ============================================================================
-- 9. QUALITY-OF-HIRE KPIs (Post-Hire Performance)
-- ============================================================================

SELECT
    dj.department,
    COUNT(fon.onboarding_id) AS total_onboarded,
    SUM(CASE WHEN fon.onboarding_status = 'Completed' THEN 1 ELSE 0 END) AS completed,
    SUM(CASE WHEN fon.first_90_day_status = 'Active' THEN 1 ELSE 0 END) AS active_at_90,
    SUM(CASE WHEN fon.first_90_day_status = 'Voluntary Exit' THEN 1 ELSE 0 END) AS voluntary_exit,
    SUM(CASE WHEN fon.first_90_day_status = 'Involuntary Exit' THEN 1 ELSE 0 END) AS involuntary_exit,
    ROUND(AVG(fon.manager_satisfaction_score), 1) AS avg_manager_satisfaction,
    ROUND(AVG(fon.ramp_score), 1) AS avg_ramp_score,
    ROUND(
        SUM(CASE WHEN fon.first_90_day_status = 'Active' THEN 1 ELSE 0 END) / 
        NULLIF(COUNT(fon.onboarding_id), 0) * 100, 1
    ) AS retention_rate_90d
FROM fact_onboarding fon
JOIN fact_application fa ON fon.application_id = fa.application_id
JOIN dim_job dj ON fa.job_id = dj.job_id
WHERE fon.start_date BETWEEN '2024-01-01' AND '2025-06-30'
GROUP BY dj.department
ORDER BY retention_rate_90d DESC;


-- ============================================================================
-- 10. DIVERSITY & INCLUSION HIRING KPIs
-- ============================================================================

SELECT
    dc.education_level,
    COUNT(DISTINCT fa.application_id) AS applications,
    COUNT(DISTINCT CASE WHEN fa.current_status = 'Accepted' THEN fa.application_id END) AS hires,
    ROUND(
        COUNT(DISTINCT CASE WHEN fa.current_status = 'Accepted' THEN fa.application_id END) / 
        NULLIF(COUNT(DISTINCT fa.application_id), 0) * 100, 1
    ) AS conversion_rate_pct,
    ROUND(AVG(fo.total_compensation), 0) AS avg_compensation
FROM fact_application fa
JOIN dim_candidate dc ON fa.candidate_id = dc.candidate_id
LEFT JOIN fact_offer fo ON fa.application_id = fo.application_id AND fo.offer_status = 'Accepted'
WHERE fa.application_date BETWEEN '2024-01-01' AND '2025-06-30'
GROUP BY dc.education_level
ORDER BY applications DESC;


-- ============================================================================
-- 11. COST-PER-HIRE KPI (Estimated)
-- ============================================================================

SELECT
    dj.department,
    COUNT(DISTINCT CASE WHEN fa.current_status = 'Accepted' THEN fa.application_id END) AS total_hires,
    COUNT(DISTINCT fa.application_id) AS total_applications,
    ROUND(
        -- Estimated cost per hire = (Recruiter time + Tools + Agency fees) / Hires
        -- Simplified: Using average stage duration as proxy for recruiter effort
        (AVG(fa.total_days_in_pipeline) * 5000 +   -- ~5000/day recruiter cost estimate
         COUNT(DISTINCT CASE WHEN fa.source_channel = 'Agency' THEN fa.application_id END) * 150000 + -- Agency fee
         COUNT(DISTINCT CASE WHEN fa.source_channel = 'LinkedIn' THEN fa.application_id END) * 8000    -- LinkedIn cost
        ) / NULLIF(COUNT(DISTINCT CASE WHEN fa.current_status = 'Accepted' THEN fa.application_id END), 0),
        0
    ) AS estimated_cost_per_hire_inr,
    ROUND(AVG(fo.total_compensation), 0) AS avg_compensation,
    ROUND(
        (AVG(fa.total_days_in_pipeline) * 5000 +
         COUNT(DISTINCT CASE WHEN fa.source_channel = 'Agency' THEN fa.application_id END) * 150000 +
         COUNT(DISTINCT CASE WHEN fa.source_channel = 'LinkedIn' THEN fa.application_id END) * 8000
        ) / NULLIF(COUNT(DISTINCT CASE WHEN fa.current_status = 'Accepted' THEN fa.application_id END), 0)
        / NULLIF(AVG(fo.total_compensation), 0) * 100, 2
    ) AS cost_per_hire_as_pct_of_comp
FROM fact_application fa
JOIN dim_job dj ON fa.job_id = dj.job_id
LEFT JOIN fact_offer fo ON fa.application_id = fo.application_id AND fo.offer_status = 'Accepted'
WHERE fa.application_date BETWEEN '2024-01-01' AND '2025-06-30'
GROUP BY dj.department;


-- ============================================================================
-- 12. EXECUTIVE SUMMARY - SINGLE ROW KPI CARD
-- ============================================================================

SELECT
    (SELECT COUNT(*) FROM fact_application WHERE application_date BETWEEN '2024-01-01' AND '2025-06-30') AS total_applications,
    (SELECT COUNT(DISTINCT job_id) FROM fact_application WHERE application_date BETWEEN '2024-01-01' AND '2025-06-30') AS open_positions,
    (SELECT COUNT(*) FROM fact_offer WHERE offer_status = 'Accepted' AND offer_date BETWEEN '2024-01-01' AND '2025-06-30') AS total_hires,
    (SELECT ROUND(COUNT(*) / NULLIF((SELECT COUNT(*) FROM fact_offer WHERE offer_date BETWEEN '2024-01-01' AND '2025-06-30'), 0) * 100, 1)
     FROM fact_offer WHERE offer_status = 'Accepted' AND offer_date BETWEEN '2024-01-01' AND '2025-06-30') AS offer_accept_rate_pct,
    (SELECT ROUND(AVG(total_days_in_pipeline), 1) FROM fact_application 
     WHERE current_status = 'Accepted' AND application_date BETWEEN '2024-01-01' AND '2025-06-30') AS avg_time_to_hire_days,
    (SELECT ROUND(AVG(total_compensation), 0) FROM fact_offer 
     WHERE offer_status = 'Accepted' AND offer_date BETWEEN '2024-01-01' AND '2025-06-30') AS avg_total_comp,
    (SELECT COUNT(*) FROM fact_application 
     WHERE current_status = 'Active' AND application_date BETWEEN '2024-01-01' AND '2025-06-30') AS current_pipeline,
    (SELECT ROUND(AVG(manager_satisfaction_score), 1) FROM fact_onboarding 
     WHERE start_date BETWEEN '2024-01-01' AND '2025-06-30') AS avg_quality_score,
    (SELECT ROUND(AVG(ramp_score), 1) FROM fact_onboarding 
     WHERE start_date BETWEEN '2024-01-01' AND '2025-06-30') AS avg_ramp_score;
