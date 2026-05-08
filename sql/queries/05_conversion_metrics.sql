-- ============================================================================
-- HIRING FUNNEL ANALYTICS DASHBOARD
-- ============================================================================
-- Conversion Metrics SQL Queries
-- Description: Stage-to-stage, end-to-end, and segmented conversion rates
-- ============================================================================

USE hiring_funnel_analytics;

-- ============================================================================
-- 1. END-TO-END CONVERSION RATE (Application → Hire)
-- ============================================================================

SELECT
    DATE_FORMAT(fa.application_date, '%Y-%m') AS month,
    COUNT(DISTINCT fa.application_id) AS applications,
    COUNT(DISTINCT CASE WHEN fa.current_status = 'Accepted' THEN fa.application_id END) AS hires,
    ROUND(
        COUNT(DISTINCT CASE WHEN fa.current_status = 'Accepted' THEN fa.application_id END) / 
        NULLIF(COUNT(DISTINCT fa.application_id), 0) * 100, 2
    ) AS end_to_end_conversion_pct,
    ROUND(
        COUNT(DISTINCT CASE WHEN fa.current_status = 'Rejected' THEN fa.application_id END) / 
        NULLIF(COUNT(DISTINCT fa.application_id), 0) * 100, 2
    ) AS rejection_rate_pct,
    ROUND(
        COUNT(DISTINCT CASE WHEN fa.current_status = 'Withdrawn' THEN fa.application_id END) / 
        NULLIF(COUNT(DISTINCT fa.application_id), 0) * 100, 2
    ) AS withdrawal_rate_pct
FROM fact_application fa
WHERE fa.application_date BETWEEN '2024-01-01' AND '2025-06-30'
GROUP BY DATE_FORMAT(fa.application_date, '%Y-%m')
ORDER BY month;


-- ============================================================================
-- 2. STAGE-TO-STAGE CONVERSION RATES
-- ============================================================================
-- The core funnel conversion metrics - each stage transition rate

WITH stage_volumes AS (
    SELECT
        ds.stage_id,
        ds.stage_name,
        ds.stage_order,
        COUNT(DISTINCT fst.application_id) AS volume
    FROM fact_stage_transition fst
    JOIN dim_stage ds ON fst.to_stage_id = ds.stage_id
    WHERE DATE(fst.transition_date) BETWEEN '2024-01-01' AND '2025-06-30'
    GROUP BY ds.stage_id, ds.stage_name, ds.stage_order
),
conversion_calc AS (
    SELECT
        curr.stage_name AS current_stage,
        curr.stage_order,
        curr.volume AS current_volume,
        prev.stage_name AS previous_stage,
        prev.volume AS previous_volume,
        ROUND(curr.volume / NULLIF(prev.volume, 0) * 100, 2) AS stage_conversion_pct
    FROM stage_volumes curr
    LEFT JOIN stage_volumes prev ON curr.stage_order = prev.stage_order + 1
)
SELECT
    previous_stage,
    current_stage,
    previous_volume,
    current_volume,
    stage_conversion_pct,
    previous_volume - current_volume AS candidates_lost,
    ROUND((1 - stage_conversion_pct / 100) * 100, 2) AS stage_drop_off_pct,
    -- Cumulative conversion from start
    ROUND(current_volume / NULLIF(FIRST_VALUE(current_volume) OVER (ORDER BY stage_order), 0) * 100, 2) AS cumulative_conversion_pct
FROM conversion_calc
ORDER BY stage_order;


-- ============================================================================
-- 3. CONVERSION RATES BY DEPARTMENT
-- ============================================================================

SELECT
    dj.department,
    -- Stage-to-stage conversion
    ROUND(
        COUNT(DISTINCT CASE WHEN fst.to_stage_id = 2 THEN fst.application_id END) / 
        NULLIF(COUNT(DISTINCT CASE WHEN fst.to_stage_id = 1 THEN fst.application_id END), 0) * 100, 1
    ) AS app_to_screen_pct,
    ROUND(
        COUNT(DISTINCT CASE WHEN fst.to_stage_id = 3 THEN fst.application_id END) / 
        NULLIF(COUNT(DISTINCT CASE WHEN fst.to_stage_id = 2 THEN fst.application_id END), 0) * 100, 1
    ) AS screen_to_phone_pct,
    ROUND(
        COUNT(DISTINCT CASE WHEN fst.to_stage_id = 4 THEN fst.application_id END) / 
        NULLIF(COUNT(DISTINCT CASE WHEN fst.to_stage_id = 3 THEN fst.application_id END), 0) * 100, 1
    ) AS phone_to_assessment_pct,
    ROUND(
        COUNT(DISTINCT CASE WHEN fst.to_stage_id = 6 THEN fst.application_id END) / 
        NULLIF(COUNT(DISTINCT CASE WHEN fst.to_stage_id = 5 THEN fst.application_id END), 0) * 100, 1
    ) AS manager_to_technical_pct,
    ROUND(
        COUNT(DISTINCT CASE WHEN fst.to_stage_id = 11 THEN fst.application_id END) / 
        NULLIF(COUNT(DISTINCT CASE WHEN fst.to_stage_id = 10 THEN fst.application_id END), 0) * 100, 1
    ) AS discussion_to_offer_pct,
    ROUND(
        COUNT(DISTINCT CASE WHEN fst.to_stage_id = 12 THEN fst.application_id END) / 
        NULLIF(COUNT(DISTINCT CASE WHEN fst.to_stage_id = 11 THEN fst.application_id END), 0) * 100, 1
    ) AS offer_to_acceptance_pct,
    -- End-to-end
    ROUND(
        COUNT(DISTINCT CASE WHEN fst.to_stage_id = 12 THEN fst.application_id END) / 
        NULLIF(COUNT(DISTINCT CASE WHEN fst.to_stage_id = 1 THEN fst.application_id END), 0) * 100, 1
    ) AS end_to_end_conversion_pct
FROM fact_stage_transition fst
JOIN fact_application fa ON fst.application_id = fa.application_id
JOIN dim_job dj ON fa.job_id = dj.job_id
WHERE DATE(fst.transition_date) BETWEEN '2024-01-01' AND '2025-06-30'
GROUP BY dj.department
ORDER BY end_to_end_conversion_pct DESC;


-- ============================================================================
-- 4. CONVERSION BY SOURCE CHANNEL
-- ============================================================================

SELECT
    COALESCE(fa.source_channel, dc.source_channel) AS source_channel,
    COUNT(DISTINCT fa.application_id) AS total_applications,
    COUNT(DISTINCT CASE WHEN fa.current_stage_id >= 2 THEN fa.application_id END) AS passed_screening,
    COUNT(DISTINCT CASE WHEN fa.current_stage_id >= 6 THEN fa.application_id END) AS reached_interview,
    COUNT(DISTINCT CASE WHEN fa.current_stage_id >= 11 THEN fa.application_id END) AS received_offer,
    COUNT(DISTINCT CASE WHEN fa.current_status = 'Accepted' THEN fa.application_id END) AS hired,
    ROUND(
        COUNT(DISTINCT CASE WHEN fa.current_stage_id >= 2 THEN fa.application_id END) / 
        NULLIF(COUNT(DISTINCT fa.application_id), 0) * 100, 1
    ) AS screening_rate_pct,
    ROUND(
        COUNT(DISTINCT CASE WHEN fa.current_stage_id >= 6 THEN fa.application_id END) / 
        NULLIF(COUNT(DISTINCT fa.application_id), 0) * 100, 1
    ) AS interview_rate_pct,
    ROUND(
        COUNT(DISTINCT CASE WHEN fa.current_status = 'Accepted' THEN fa.application_id END) / 
        NULLIF(COUNT(DISTINCT fa.application_id), 0) * 100, 1
    ) AS hire_rate_pct,
    ROUND(AVG(CASE WHEN fa.current_status = 'Accepted' THEN fa.total_days_in_pipeline END), 1) AS avg_time_to_hire
FROM fact_application fa
LEFT JOIN dim_candidate dc ON fa.candidate_id = dc.candidate_id
WHERE fa.application_date BETWEEN '2024-01-01' AND '2025-06-30'
GROUP BY COALESCE(fa.source_channel, dc.source_channel)
ORDER BY hire_rate_pct DESC;


-- ============================================================================
-- 5. CONVERSION BY SENIORITY LEVEL
-- ============================================================================

SELECT
    dj.seniority_level,
    COUNT(DISTINCT fa.application_id) AS total_applications,
    COUNT(DISTINCT CASE WHEN fa.current_status = 'Accepted' THEN fa.application_id END) AS hires,
    ROUND(
        COUNT(DISTINCT CASE WHEN fa.current_status = 'Accepted' THEN fa.application_id END) / 
        NULLIF(COUNT(DISTINCT fa.application_id), 0) * 100, 1
    ) AS conversion_pct,
    ROUND(AVG(CASE WHEN fa.current_status = 'Accepted' THEN fa.total_days_in_pipeline END), 1) AS avg_time_to_hire,
    -- Pass rates at key checkpoints
    ROUND(AVG(CASE WHEN fa.current_stage_id >= 3 THEN 1.0 ELSE 0.0 END) * 100, 1) AS phone_screen_pass_pct,
    ROUND(AVG(CASE WHEN fa.current_stage_id >= 6 THEN 1.0 ELSE 0.0 END) * 100, 1) AS technical_pass_pct,
    ROUND(AVG(CASE WHEN fa.current_stage_id >= 11 THEN 1.0 ELSE 0.0 END) * 100, 1) AS offer_rate_pct
FROM fact_application fa
JOIN dim_job dj ON fa.job_id = dj.job_id
WHERE fa.application_date BETWEEN '2024-01-01' AND '2025-06-30'
GROUP BY dj.seniority_level
ORDER BY FIELD(dj.seniority_level, 'Entry', 'Mid', 'Senior', 'Lead', 'Manager', 'Director', 'VP', 'C-Level');


-- ============================================================================
-- 6. MONTHLY CONVERSION TREND (TIME SERIES)
-- ============================================================================

WITH monthly_data AS (
    SELECT
        DATE_FORMAT(fa.application_date, '%Y-%m') AS month,
        COUNT(DISTINCT fa.application_id) AS applications,
        COUNT(DISTINCT CASE WHEN fa.current_status = 'Accepted' THEN fa.application_id END) AS hires
    FROM fact_application fa
    WHERE fa.application_date BETWEEN '2024-01-01' AND '2025-06-30'
    GROUP BY DATE_FORMAT(fa.application_date, '%Y-%m')
)
SELECT
    month,
    applications,
    hires,
    ROUND(hires / NULLIF(applications, 0) * 100, 2) AS conversion_pct,
    LAG(hires / NULLIF(applications, 0) * 100) OVER (ORDER BY month) AS prev_month_conversion,
    ROUND(
        (hires / NULLIF(applications, 0) * 100) - 
        LAG(hires / NULLIF(applications, 0) * 100) OVER (ORDER BY month),
        2
    ) AS mom_change_pct_points,
    -- Rolling 3-month average
    ROUND(
        AVG(hires / NULLIF(applications, 0) * 100) OVER (
            ORDER BY month ROWS BETWEEN 2 PRECEDING AND CURRENT ROW
        ), 2
    ) AS rolling_3m_avg_conversion
FROM monthly_data
ORDER BY month;


-- ============================================================================
-- 7. APPLICATION-TO-INTERVIEW CONVERSION (Speed metric)
-- ============================================================================

SELECT
    dj.department,
    COUNT(DISTINCT fa.application_id) AS total_applications,
    COUNT(DISTINCT CASE WHEN fa.current_stage_id >= 6 THEN fa.application_id END) AS reached_technical,
    ROUND(
        COUNT(DISTINCT CASE WHEN fa.current_stage_id >= 6 THEN fa.application_id END) / 
        NULLIF(COUNT(DISTINCT fa.application_id), 0) * 100, 1
    ) AS app_to_interview_pct,
    ROUND(
        AVG(CASE WHEN fa.current_stage_id >= 6 THEN 
            DATEDIFF(
                (SELECT MIN(DATE(fst2.transition_date)) 
                 FROM fact_stage_transition fst2 
                 WHERE fst2.application_id = fa.application_id AND fst2.to_stage_id = 6),
                fa.application_date
            )
        END), 1
    ) AS avg_days_to_first_interview
FROM fact_application fa
JOIN dim_job dj ON fa.job_id = dj.job_id
WHERE fa.application_date BETWEEN '2024-01-01' AND '2025-06-30'
GROUP BY dj.department
ORDER BY app_to_interview_pct DESC;


-- ============================================================================
-- 8. OFFER CONVERSION FUNNEL
-- ============================================================================
-- Detailed view of the offer stage specifically

SELECT
    'Offer Discussion' AS stage, COUNT(DISTINCT fo.offer_id) AS volume
FROM fact_offer fo
JOIN fact_application fa ON fo.application_id = fa.application_id
WHERE fo.offer_date BETWEEN '2024-01-01' AND '2025-06-30'

UNION ALL

SELECT
    'Offer Extended' AS stage, COUNT(DISTINCT fo.offer_id) AS volume
FROM fact_offer fo
WHERE fo.offer_date BETWEEN '2024-01-01' AND '2025-06-30'

UNION ALL

SELECT
    'Negotiating' AS stage, COUNT(DISTINCT fo.offer_id) AS volume
FROM fact_offer fo
WHERE fo.offer_status = 'Negotiating' AND fo.offer_date BETWEEN '2024-01-01' AND '2025-06-30'

UNION ALL

SELECT
    'Accepted' AS stage, COUNT(DISTINCT fo.offer_id) AS volume
FROM fact_offer fo
WHERE fo.offer_status = 'Accepted' AND fo.offer_date BETWEEN '2024-01-01' AND '2025-06-30'

UNION ALL

SELECT
    'Declined' AS stage, COUNT(DISTINCT fo.offer_id) AS volume
FROM fact_offer fo
WHERE fo.offer_status = 'Declined' AND fo.offer_date BETWEEN '2024-01-01' AND '2025-06-30'

UNION ALL

SELECT
    'Expired' AS stage, COUNT(DISTINCT fo.offer_id) AS volume
FROM fact_offer fo
WHERE fo.offer_status = 'Expired' AND fo.offer_date BETWEEN '2024-01-01' AND '2025-06-30'


-- ============================================================================
-- 9. RECRUITER CONVERSION EFFICIENCY
-- ============================================================================

SELECT
    CONCAT(dr.first_name, ' ', dr.last_name) AS recruiter,
    dr.specialization,
    COUNT(DISTINCT fa.application_id) AS assigned_applications,
    COUNT(DISTINCT CASE WHEN fa.current_stage_id >= 3 THEN fa.application_id END) AS passed_phone_screen,
    COUNT(DISTINCT CASE WHEN fa.current_stage_id >= 6 THEN fa.application_id END) AS passed_technical,
    COUNT(DISTINCT CASE WHEN fa.current_status = 'Accepted' THEN fa.application_id END) AS hires,
    ROUND(
        COUNT(DISTINCT CASE WHEN fa.current_stage_id >= 3 THEN fa.application_id END) / 
        NULLIF(COUNT(DISTINCT fa.application_id), 0) * 100, 1
    ) AS screening_efficiency_pct,
    ROUND(
        COUNT(DISTINCT CASE WHEN fa.current_status = 'Accepted' THEN fa.application_id END) / 
        NULLIF(COUNT(DISTINCT fa.application_id), 0) * 100, 1
    ) AS overall_conversion_pct,
    ROUND(AVG(CASE WHEN fa.current_status = 'Accepted' THEN fa.total_days_in_pipeline END), 1) AS avg_time_to_hire
FROM fact_application fa
JOIN dim_recruiter dr ON fa.recruiter_id = dr.recruiter_id
WHERE fa.application_date BETWEEN '2024-01-01' AND '2025-06-30'
  AND dr.is_active = TRUE
GROUP BY dr.recruiter_id, dr.first_name, dr.last_name, dr.specialization
ORDER BY overall_conversion_pct DESC;


-- ============================================================================
-- 10. QUARTERLY CONVERSION COMPARISON
-- ============================================================================

WITH quarterly AS (
    SELECT
        CONCAT('Q', QUARTER(fa.application_date), ' ', YEAR(fa.application_date)) AS quarter_label,
        YEAR(fa.application_date) AS yr,
        QUARTER(fa.application_date) AS qtr,
        COUNT(DISTINCT fa.application_id) AS applications,
        COUNT(DISTINCT CASE WHEN fa.current_status = 'Accepted' THEN fa.application_id END) AS hires,
        COUNT(DISTINCT CASE WHEN fa.current_status = 'Rejected' THEN fa.application_id END) AS rejections,
        ROUND(AVG(CASE WHEN fa.current_status = 'Accepted' THEN fa.total_days_in_pipeline END), 1) AS avg_tth
    FROM fact_application fa
    WHERE fa.application_date BETWEEN '2024-01-01' AND '2025-06-30'
    GROUP BY YEAR(fa.application_date), QUARTER(fa.application_date)
)
SELECT
    quarter_label,
    applications,
    hires,
    rejections,
    ROUND(hires / NULLIF(applications, 0) * 100, 1) AS conversion_pct,
    avg_tth AS avg_time_to_hire_days,
    LAG(hires / NULLIF(applications, 0) * 100) OVER (ORDER BY yr, qtr) AS prev_q_conversion,
    ROUND(
        (hires / NULLIF(applications, 0) * 100) - 
        LAG(hires / NULLIF(applications, 0) * 100) OVER (ORDER BY yr, qtr),
        1
    ) AS qoq_change
FROM quarterly
ORDER BY yr, qtr;


-- ============================================================================
-- 11. REFERRAL VS NON-REFERRAL CONVERSION
-- ============================================================================

SELECT
    CASE WHEN fa.referral_employee_id IS NOT NULL THEN 'Referral' ELSE 'Non-Referral' END AS candidate_type,
    COUNT(DISTINCT fa.application_id) AS applications,
    COUNT(DISTINCT CASE WHEN fa.current_status = 'Accepted' THEN fa.application_id END) AS hires,
    ROUND(
        COUNT(DISTINCT CASE WHEN fa.current_status = 'Accepted' THEN fa.application_id END) / 
        NULLIF(COUNT(DISTINCT fa.application_id), 0) * 100, 1
    ) AS conversion_pct,
    ROUND(AVG(CASE WHEN fa.current_status = 'Accepted' THEN fa.total_days_in_pipeline END), 1) AS avg_time_to_hire,
    ROUND(AVG(fo.total_compensation), 0) AS avg_compensation,
    COUNT(DISTINCT CASE WHEN fa.current_status = 'Withdrawn' THEN fa.application_id END) AS withdrawals,
    ROUND(
        COUNT(DISTINCT CASE WHEN fa.current_status = 'Withdrawn' THEN fa.application_id END) / 
        NULLIF(COUNT(DISTINCT fa.application_id), 0) * 100, 1
    ) AS withdrawal_rate_pct
FROM fact_application fa
LEFT JOIN fact_offer fo ON fa.application_id = fo.application_id AND fo.offer_status = 'Accepted'
WHERE fa.application_date BETWEEN '2024-01-01' AND '2025-06-30'
GROUP BY CASE WHEN fa.referral_employee_id IS NOT NULL THEN 'Referral' ELSE 'Non-Referral' END;


-- ============================================================================
-- 12. CONVERSION EFFICIENCY INDEX
-- ============================================================================
-- Composite metric: conversion rate adjusted for time-to-hire
-- Higher is better: more hires in less time

WITH dept_metrics AS (
    SELECT
        dj.department,
        COUNT(DISTINCT CASE WHEN fa.current_status = 'Accepted' THEN fa.application_id END) AS hires,
        COUNT(DISTINCT fa.application_id) AS applications,
        ROUND(
            COUNT(DISTINCT CASE WHEN fa.current_status = 'Accepted' THEN fa.application_id END) / 
            NULLIF(COUNT(DISTINCT fa.application_id), 0) * 100, 2
        ) AS conversion_pct,
        ROUND(AVG(CASE WHEN fa.current_status = 'Accepted' THEN fa.total_days_in_pipeline END), 1) AS avg_tth
    FROM fact_application fa
    JOIN dim_job dj ON fa.job_id = dj.job_id
    WHERE fa.application_date BETWEEN '2024-01-01' AND '2025-06-30'
    GROUP BY dj.department
)
SELECT
    department,
    applications,
    hires,
    conversion_pct,
    avg_tth,
    -- Efficiency Index = (Conversion Rate / Time-to-Hire) * 100
    -- Higher = more efficient (high conversion, low time)
    ROUND(conversion_pct / NULLIF(avg_tth, 0) * 100, 2) AS efficiency_index,
    RANK() OVER (ORDER BY conversion_pct / NULLIF(avg_tth, 0) * 100 DESC) AS efficiency_rank
FROM dept_metrics
ORDER BY efficiency_index DESC;
