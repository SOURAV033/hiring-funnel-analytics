-- ============================================================================
-- HIRING FUNNEL ANALYTICS DASHBOARD
-- ============================================================================
-- Drop-off Analysis SQL Queries
-- Description: Identifies where and why candidates exit the hiring funnel
-- ============================================================================

USE hiring_funnel_analytics;

-- ============================================================================
-- 1. OVERALL FUNNEL DROP-OFF BY STAGE
-- ============================================================================
-- Shows absolute numbers and percentage of candidates lost at each stage

SELECT
    ds.stage_name,
    ds.stage_order,
    ds.stage_category,
    COUNT(DISTINCT fst.application_id) AS candidates_entered,
    LAG(COUNT(DISTINCT fst.application_id)) OVER (ORDER BY ds.stage_order) AS candidates_from_prev_stage,
    COUNT(DISTINCT fst.application_id) - 
        COALESCE(LAG(COUNT(DISTINCT fst.application_id)) OVER (ORDER BY ds.stage_order), 
                 COUNT(DISTINCT fst.application_id)) AS candidates_dropped,
    ROUND(
        (1 - COUNT(DISTINCT fst.application_id) / 
         NULLIF(LAG(COUNT(DISTINCT fst.application_id)) OVER (ORDER BY ds.stage_order), 0)) * 100, 
        1
    ) AS drop_off_rate_pct,
    ROUND(
        COUNT(DISTINCT fst.application_id) / 
        NULLIF(FIRST_VALUE(COUNT(DISTINCT fst.application_id)) OVER (ORDER BY ds.stage_order), 0) * 100, 
        1
    ) AS cumulative_conversion_pct
FROM fact_stage_transition fst
JOIN dim_stage ds ON fst.to_stage_id = ds.stage_id
WHERE DATE(fst.transition_date) BETWEEN '2024-01-01' AND '2025-06-30'
GROUP BY ds.stage_id, ds.stage_name, ds.stage_order, ds.stage_category
ORDER BY ds.stage_order;


-- ============================================================================
-- 2. TOP DROP-OFF STAGES BY DEPARTMENT
-- ============================================================================
-- Identifies which stages have the highest attrition per department

WITH stage_counts AS (
    SELECT
        dj.department,
        ds.stage_name,
        ds.stage_order,
        COUNT(DISTINCT fst.application_id) AS candidates_at_stage
    FROM fact_stage_transition fst
    JOIN dim_stage ds ON fst.to_stage_id = ds.stage_id
    JOIN fact_application fa ON fst.application_id = fa.application_id
    JOIN dim_job dj ON fa.job_id = dj.job_id
    WHERE DATE(fst.transition_date) BETWEEN '2024-01-01' AND '2025-06-30'
    GROUP BY dj.department, ds.stage_id, ds.stage_name, ds.stage_order
),
drop_off_calc AS (
    SELECT
        department,
        stage_name,
        stage_order,
        candidates_at_stage,
        LAG(candidates_at_stage) OVER (PARTITION BY department ORDER BY stage_order) AS prev_stage_candidates,
        candidates_at_stage - LAG(candidates_at_stage) OVER (PARTITION BY department ORDER BY stage_order) AS dropped,
        ROUND(
            (1 - candidates_at_stage / NULLIF(LAG(candidates_at_stage) OVER (PARTITION BY department ORDER BY stage_order), 0)) * 100, 
            1
        ) AS drop_off_pct
    FROM stage_counts
)
SELECT
    department,
    stage_name,
    stage_order,
    prev_stage_candidates,
    candidates_at_stage,
    dropped,
    drop_off_pct,
    RANK() OVER (PARTITION BY department ORDER BY drop_off_pct DESC) AS drop_off_rank
FROM drop_off_calc
WHERE prev_stage_candidates IS NOT NULL
ORDER BY department, drop_off_pct DESC;


-- ============================================================================
-- 3. REJECTION REASON BREAKDOWN BY STAGE
-- ============================================================================
-- Why are candidates being rejected at each stage?

SELECT
    ds.stage_name,
    ds.stage_order,
    rr.reason_category,
    rr.reason_description,
    COUNT(DISTINCT fst.application_id) AS rejection_count,
    ROUND(
        COUNT(DISTINCT fst.application_id) / 
        NULLIF(SUM(COUNT(DISTINCT fst.application_id)) OVER (PARTITION BY ds.stage_id), 0) * 100, 
        1
    ) AS pct_of_stage_rejections
FROM fact_stage_transition fst
JOIN dim_stage ds ON fst.to_stage_id = ds.stage_id
JOIN dim_rejection_reason rr ON fst.rejection_reason_id = rr.reason_id
WHERE fst.outcome = 'Failed'
  AND DATE(fst.transition_date) BETWEEN '2024-01-01' AND '2025-06-30'
GROUP BY ds.stage_id, ds.stage_name, ds.stage_order, rr.reason_id, rr.reason_category, rr.reason_description
ORDER BY ds.stage_order, rejection_count DESC;


-- ============================================================================
-- 4. DROP-OFF BY CANDIDATE SOURCE CHANNEL
-- ============================================================================
-- Which channels produce the highest drop-off rates?

WITH source_stage_counts AS (
    SELECT
        COALESCE(fa.source_channel, dc.source_channel) AS source_channel,
        ds.stage_name,
        ds.stage_order,
        COUNT(DISTINCT fst.application_id) AS candidates
    FROM fact_stage_transition fst
    JOIN fact_application fa ON fst.application_id = fa.application_id
    LEFT JOIN dim_candidate dc ON fa.candidate_id = dc.candidate_id
    JOIN dim_stage ds ON fst.to_stage_id = ds.stage_id
    WHERE DATE(fst.transition_date) BETWEEN '2024-01-01' AND '2025-06-30'
    GROUP BY COALESCE(fa.source_channel, dc.source_channel), ds.stage_id, ds.stage_name, ds.stage_order
),
source_totals AS (
    SELECT
        source_channel,
        stage_name,
        stage_order,
        candidates,
        FIRST_VALUE(candidates) OVER (PARTITION BY source_channel ORDER BY stage_order) AS starting_pool
    FROM source_stage_counts
)
SELECT
    source_channel,
    stage_name,
    stage_order,
    candidates,
    starting_pool,
    ROUND(candidates / NULLIF(starting_pool, 0) * 100, 1) AS survival_rate_pct,
    ROUND((1 - candidates / NULLIF(starting_pool, 0)) * 100, 1) AS total_drop_off_pct,
    LAG(candidates) OVER (PARTITION BY source_channel ORDER BY stage_order) AS prev_stage_count,
    ROUND(
        (1 - candidates / NULLIF(LAG(candidates) OVER (PARTITION BY source_channel ORDER BY stage_order), 0)) * 100, 
        1
    ) AS stage_drop_off_pct
FROM source_totals
ORDER BY source_channel, stage_order;


-- ============================================================================
-- 5. WITHDRAWAL PATTERN ANALYSIS
-- ============================================================================
-- When do candidates voluntarily withdraw from the process?

SELECT
    ds.stage_name,
    ds.stage_order,
    COUNT(DISTINCT fst.application_id) AS total_withdrawals,
    ROUND(
        COUNT(DISTINCT fst.application_id) / 
        NULLIF(SUM(COUNT(DISTINCT fst.application_id)) OVER (), 0) * 100, 
        1
    ) AS pct_of_all_withdrawals,
    ROUND(AVG(fst.days_in_previous_stage), 1) AS avg_days_before_withdrawal,
    -- Breakdown by source
    COUNT(DISTINCT CASE WHEN fa.source_channel = 'LinkedIn' THEN fst.application_id END) AS from_linkedin,
    COUNT(DISTINCT CASE WHEN fa.source_channel = 'Referral' THEN fst.application_id END) AS from_referral,
    COUNT(DISTINCT CASE WHEN fa.source_channel = 'Job Board' THEN fst.application_id END) AS from_job_board,
    COUNT(DISTINCT CASE WHEN fa.source_channel = 'Career Page' THEN fst.application_id END) AS from_career_page,
    COUNT(DISTINCT CASE WHEN fa.source_channel = 'Agency' THEN fst.application_id END) AS from_agency
FROM fact_stage_transition fst
JOIN dim_stage ds ON fst.to_stage_id = ds.stage_id
JOIN fact_application fa ON fst.application_id = fa.application_id
WHERE fst.outcome = 'Withdrawn'
  AND DATE(fst.transition_date) BETWEEN '2024-01-01' AND '2025-06-30'
GROUP BY ds.stage_id, ds.stage_name, ds.stage_order
ORDER BY total_withdrawals DESC;


-- ============================================================================
-- 6. DROP-OFF HEATMAP: DEPARTMENT × STAGE
-- ============================================================================
-- Matrix view for Power BI heatmap visualization

SELECT
    dj.department,
    ds.stage_name,
    ds.stage_order,
    COUNT(DISTINCT CASE WHEN fst.outcome = 'Failed' THEN fst.application_id END) AS failed_count,
    COUNT(DISTINCT CASE WHEN fst.outcome = 'Withdrawn' THEN fst.application_id END) AS withdrawn_count,
    COUNT(DISTINCT fst.application_id) AS total_at_stage,
    ROUND(
        (COUNT(DISTINCT CASE WHEN fst.outcome = 'Failed' THEN fst.application_id END) + 
         COUNT(DISTINCT CASE WHEN fst.outcome = 'Withdrawn' THEN fst.application_id END)) / 
        NULLIF(COUNT(DISTINCT fst.application_id), 0) * 100, 
        1
    ) AS combined_drop_off_pct,
    ROUND(
        COUNT(DISTINCT CASE WHEN fst.outcome = 'Failed' THEN fst.application_id END) / 
        NULLIF(COUNT(DISTINCT fst.application_id), 0) * 100, 
        1
    ) AS rejection_rate_pct,
    ROUND(
        COUNT(DISTINCT CASE WHEN fst.outcome = 'Withdrawn' THEN fst.application_id END) / 
        NULLIF(COUNT(DISTINCT fst.application_id), 0) * 100, 
        1
    ) AS withdrawal_rate_pct
FROM fact_stage_transition fst
JOIN dim_stage ds ON fst.to_stage_id = ds.stage_id
JOIN fact_application fa ON fst.application_id = fa.application_id
JOIN dim_job dj ON fa.job_id = dj.job_id
WHERE DATE(fst.transition_date) BETWEEN '2024-01-01' AND '2025-06-30'
GROUP BY dj.department, ds.stage_id, ds.stage_name, ds.stage_order
ORDER BY dj.department, ds.stage_order;


-- ============================================================================
-- 7. SENIORITY-LEVEL DROP-OFF ANALYSIS
-- ============================================================================
-- Do senior roles have higher drop-off than junior ones?

WITH seniority_stage AS (
    SELECT
        dj.seniority_level,
        ds.stage_name,
        ds.stage_order,
        COUNT(DISTINCT fst.application_id) AS candidates
    FROM fact_stage_transition fst
    JOIN fact_application fa ON fst.application_id = fa.application_id
    JOIN dim_job dj ON fa.job_id = dj.job_id
    JOIN dim_stage ds ON fst.to_stage_id = ds.stage_id
    WHERE DATE(fst.transition_date) BETWEEN '2024-01-01' AND '2025-06-30'
    GROUP BY dj.seniority_level, ds.stage_id, ds.stage_name, ds.stage_order
)
SELECT
    seniority_level,
    stage_name,
    stage_order,
    candidates,
    LAG(candidates) OVER (PARTITION BY seniority_level ORDER BY stage_order) AS prev_stage_candidates,
    ROUND(
        (1 - candidates / NULLIF(LAG(candidates) OVER (PARTITION BY seniority_level ORDER BY stage_order), 0)) * 100, 
        1
    ) AS stage_drop_off_pct,
    FIRST_VALUE(candidates) OVER (PARTITION BY seniority_level ORDER BY stage_order) AS starting_pool,
    ROUND(candidates / NULLIF(FIRST_VALUE(candidates) OVER (PARTITION BY seniority_level ORDER BY stage_order), 0) * 100, 1) AS survival_rate_pct
FROM seniority_stage
ORDER BY FIELD(seniority_level, 'Entry', 'Mid', 'Senior', 'Lead', 'Manager', 'Director', 'VP', 'C-Level'), stage_order;


-- ============================================================================
-- 8. TIME-BASED DROP-OFF: ARE WE LOSING CANDIDATES DUE TO SLOW PROCESS?
-- ============================================================================
-- Correlation between days in stage and drop-off rate

SELECT
    ds.stage_name,
    ds.stage_order,
    CASE 
        WHEN fst.days_in_previous_stage <= 3 THEN '1-3 days'
        WHEN fst.days_in_previous_stage <= 7 THEN '4-7 days'
        WHEN fst.days_in_previous_stage <= 14 THEN '8-14 days'
        WHEN fst.days_in_previous_stage <= 21 THEN '15-21 days'
        WHEN fst.days_in_previous_stage <= 30 THEN '22-30 days'
        ELSE '30+ days'
    END AS time_bucket,
    COUNT(DISTINCT fst.application_id) AS total_candidates,
    COUNT(DISTINCT CASE WHEN fst.outcome = 'Failed' THEN fst.application_id END) AS failed,
    COUNT(DISTINCT CASE WHEN fst.outcome = 'Withdrawn' THEN fst.application_id END) AS withdrawn,
    ROUND(
        (COUNT(DISTINCT CASE WHEN fst.outcome = 'Failed' THEN fst.application_id END) + 
         COUNT(DISTINCT CASE WHEN fst.outcome = 'Withdrawn' THEN fst.application_id END)) / 
        NULLIF(COUNT(DISTINCT fst.application_id), 0) * 100, 1
    ) AS drop_off_rate_pct
FROM fact_stage_transition fst
JOIN dim_stage ds ON fst.to_stage_id = ds.stage_id
WHERE DATE(fst.transition_date) BETWEEN '2024-01-01' AND '2025-06-30'
  AND fst.from_stage_id IS NOT NULL
GROUP BY ds.stage_id, ds.stage_name, ds.stage_order,
    CASE 
        WHEN fst.days_in_previous_stage <= 3 THEN '1-3 days'
        WHEN fst.days_in_previous_stage <= 7 THEN '4-7 days'
        WHEN fst.days_in_previous_stage <= 14 THEN '8-14 days'
        WHEN fst.days_in_previous_stage <= 21 THEN '15-21 days'
        WHEN fst.days_in_previous_stage <= 30 THEN '22-30 days'
        ELSE '30+ days'
    END
ORDER BY ds.stage_order, time_bucket;


-- ============================================================================
-- 9. MONTHLY DROP-OFF TREND
-- ============================================================================
-- Is the drop-off rate improving or worsening over time?

WITH monthly_stage AS (
    SELECT
        DATE_FORMAT(fst.transition_date, '%Y-%m') AS month,
        ds.stage_name,
        ds.stage_order,
        COUNT(DISTINCT CASE WHEN fst.outcome IN ('Failed', 'Withdrawn') THEN fst.application_id END) AS dropped,
        COUNT(DISTINCT fst.application_id) AS total_at_stage
    FROM fact_stage_transition fst
    JOIN dim_stage ds ON fst.to_stage_id = ds.stage_id
    WHERE DATE(fst.transition_date) BETWEEN '2024-01-01' AND '2025-06-30'
    GROUP BY DATE_FORMAT(fst.transition_date, '%Y-%m'), ds.stage_id, ds.stage_name, ds.stage_order
)
SELECT
    month,
    stage_name,
    stage_order,
    dropped,
    total_at_stage,
    ROUND(dropped / NULLIF(total_at_stage, 0) * 100, 1) AS drop_off_rate_pct,
    -- Month-over-month change
    LAG(dropped / NULLIF(total_at_stage, 0) * 100) OVER (PARTITION BY stage_name ORDER BY month) AS prev_month_drop_rate,
    ROUND(
        dropped / NULLIF(total_at_stage, 0) * 100 - 
        LAG(dropped / NULLIF(total_at_stage, 0) * 100) OVER (PARTITION BY stage_name ORDER BY month),
        1
    ) AS mom_change_pct_points
FROM monthly_stage
ORDER BY stage_order, month;


-- ============================================================================
-- 10. NO-SHOW ANALYSIS
-- ============================================================================
-- Candidates who didn't show up for scheduled interviews

SELECT
    ds.stage_name,
    COUNT(DISTINCT fst.application_id) AS no_show_count,
    ROUND(AVG(fst.days_in_previous_stage), 1) AS avg_days_before_no_show,
    COUNT(DISTINCT CASE WHEN fa.source_channel = 'Job Board' THEN fst.application_id END) AS from_job_board,
    COUNT(DISTINCT CASE WHEN fa.source_channel = 'LinkedIn' THEN fst.application_id END) AS from_linkedin,
    COUNT(DISTINCT CASE WHEN fa.source_channel = 'Referral' THEN fst.application_id END) AS from_referral,
    COUNT(DISTINCT CASE WHEN fa.source_channel = 'Career Page' THEN fst.application_id END) AS from_career_page,
    COUNT(DISTINCT CASE WHEN fa.source_channel = 'Agency' THEN fst.application_id END) AS from_agency
FROM fact_stage_transition fst
JOIN dim_stage ds ON fst.to_stage_id = ds.stage_id
JOIN fact_application fa ON fst.application_id = fa.application_id
WHERE fst.outcome = 'No Show'
  AND DATE(fst.transition_date) BETWEEN '2024-01-01' AND '2025-06-30'
GROUP BY ds.stage_id, ds.stage_name
ORDER BY no_show_count DESC;


-- ============================================================================
-- 11. OFFER STAGE DROP-OFF DEEP DIVE
-- ============================================================================
-- Why do candidates decline offers?

SELECT
    fo.decline_reason,
    dj.department,
    dj.seniority_level,
    COUNT(*) AS decline_count,
    ROUND(AVG(fo.base_salary_offered), 0) AS avg_salary_offered,
    ROUND(AVG(fo.total_compensation), 0) AS avg_total_comp_offered,
    ROUND(AVG(DATEDIFF(fo.response_date, fo.offer_date)), 1) AS avg_days_to_respond
FROM fact_offer fo
JOIN fact_application fa ON fo.application_id = fa.application_id
JOIN dim_job dj ON fa.job_id = dj.job_id
WHERE fo.offer_status = 'Declined'
  AND fo.offer_date BETWEEN '2024-01-01' AND '2025-06-30'
GROUP BY fo.decline_reason, dj.department, dj.seniority_level
ORDER BY decline_count DESC;


-- ============================================================================
-- 12. FUNNEL LEAKAGE QUANTIFICATION (EXECUTIVE SUMMARY)
-- ============================================================================
-- How many candidates are we losing at each stage vs. ideal benchmarks?

WITH funnel_base AS (
    SELECT
        ds.stage_name,
        ds.stage_order,
        COUNT(DISTINCT fst.application_id) AS actual_candidates,
        FIRST_VALUE(COUNT(DISTINCT fst.application_id)) OVER (ORDER BY ds.stage_order) AS starting_pool
    FROM fact_stage_transition fst
    JOIN dim_stage ds ON fst.to_stage_id = ds.stage_id
    WHERE DATE(fst.transition_date) BETWEEN '2024-01-01' AND '2025-06-30'
    GROUP BY ds.stage_id, ds.stage_name, ds.stage_order
),
benchmarks AS (
    SELECT 'Application Received' AS stage_name, 100.0 AS benchmark_pct UNION ALL
    SELECT 'Resume Screening', 75.0 UNION ALL
    SELECT 'Phone Screen', 55.0 UNION ALL
    SELECT 'Assessment/Test', 40.0 UNION ALL
    SELECT 'Hiring Manager Review', 32.0 UNION ALL
    SELECT 'Technical Interview', 22.0 UNION ALL
    SELECT 'Panel Interview', 16.0 UNION ALL
    SELECT 'Culture Fit Interview', 14.0 UNION ALL
    SELECT 'Reference Check', 12.0 UNION ALL
    SELECT 'Offer Discussion', 11.0 UNION ALL
    SELECT 'Offer Extended', 10.0 UNION ALL
    SELECT 'Offer Accepted', 8.5 UNION ALL
    SELECT 'Background Check', 8.2 UNION ALL
    SELECT 'Onboarding Started', 8.0
)
SELECT
    fb.stage_name,
    fb.stage_order,
    fb.actual_candidates,
    ROUND(fb.actual_candidates / NULLIF(fb.starting_pool, 0) * 100, 1) AS actual_survival_pct,
    b.benchmark_pct AS industry_benchmark_pct,
    ROUND(fb.actual_candidates / NULLIF(fb.starting_pool, 0) * 100 - b.benchmark_pct, 1) AS variance_from_benchmark,
    CASE 
        WHEN fb.actual_candidates / NULLIF(fb.starting_pool, 0) * 100 < b.benchmark_pct - 5 THEN 'BELOW BENCHMARK'
        WHEN fb.actual_candidates / NULLIF(fb.starting_pool, 0) * 100 > b.benchmark_pct + 5 THEN 'ABOVE BENCHMARK'
        ELSE 'ON TRACK'
    END AS status
FROM funnel_base fb
JOIN benchmarks b ON fb.stage_name = b.stage_name
ORDER BY fb.stage_order;
