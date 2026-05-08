# KPI Definitions

## Hiring Funnel Analytics — Business Metric Definitions

---

## 1. Volume KPIs

### Total Applications
- **Definition**: Count of all candidate applications received within the reporting period
- **Formula**: `COUNT(fact_application) WHERE application_date IN [period]`
- **Business Context**: Measures overall talent pipeline health and recruitment marketing effectiveness. A declining trend may indicate brand or sourcing issues.
- **Granularity**: Monthly, Quarterly, Annually, By Department/Source
- **Target**: Varies by headcount plan; typically 25-50 applications per open role

### Active Pipeline
- **Definition**: Applications currently in progress (not rejected, withdrawn, or hired)
- **Formula**: `COUNT(fact_application) WHERE current_status = 'Active'`
- **Business Context**: Indicates the real-time load on the recruiting team. Too few active candidates risk missed targets; too many may indicate process bottlenecks.
- **Target**: 3-5x open headcount

### Offers Extended
- **Definition**: Count of formal offer letters sent to candidates
- **Formula**: `COUNT(fact_offer) WHERE offer_date IN [period]`
- **Business Context**: Directly correlates to hiring velocity. Low offer volume with high pipeline suggests conversion issues at later stages.

### Hires Made
- **Definition**: Candidates who accepted offers and completed onboarding
- **Formula**: `COUNT(fact_application) WHERE current_status = 'Accepted'`
- **Business Context**: The ultimate output metric. Measures whether the TA function is delivering against the headcount plan.

---

## 2. Rate KPIs

### Overall Conversion Rate
- **Definition**: Percentage of applications that convert to hires (end-to-end)
- **Formula**: `Hires / Total Applications × 100`
- **Business Context**: The single most important efficiency metric. A low rate indicates either poor sourcing quality or a leaky funnel. Industry average is 3-8%.
- **Target**: > 5%
- **Alert Threshold**: < 3%

### Offer Acceptance Rate
- **Definition**: Percentage of extended offers that are accepted
- **Formula**: `Accepted Offers / Total Offers × 100`
- **Business Context**: Reflects competitiveness of compensation packages and candidate experience. Declining rates may signal market misalignment.
- **Target**: > 75%
- **Alert Threshold**: < 65%

### Screening Pass Rate
- **Definition**: Percentage of resume screenings that advance to phone screen
- **Formula**: `Phone Screen Volume / Resume Screen Volume × 100`
- **Business Context**: Measures sourcing quality. A very high rate suggests overscreening (wasting recruiter time); a very low rate suggests poor sourcing.
- **Target**: 60-75%

### Interview-to-Offer Rate
- **Definition**: Percentage of technical interviews that result in an offer
- **Formula**: `Offers Extended / Technical Interviews × 100`
- **Business Context**: Measures interview effectiveness. Too high may mean low hiring bar; too low means mismatched screening or overly tough interviews.
- **Target**: 25-40%

### 90-Day Retention Rate
- **Definition**: Percentage of new hires still active at 90-day mark
- **Formula**: `Active at 90 Days / Total Onboarded × 100`
- **Business Context**: Critical quality-of-hire indicator. Early exits suggest mismatched expectations or poor onboarding.
- **Target**: > 85%
- **Alert Threshold**: < 75%

### Fill Rate
- **Definition**: Percentage of required headcount that has been filled
- **Formula**: `Hires Made / Headcount Required × 100`
- **Business Context**: Measures whether the TA team is meeting business demand. Directly impacts business growth plans.
- **Target**: > 80% by target fill date

---

## 3. Time KPIs

### Average Time to Hire
- **Definition**: Mean number of days from application submission to offer acceptance
- **Formula**: `AVG(total_days_in_pipeline) WHERE status = 'Accepted'`
- **Business Context**: Longer time-to-hire increases candidate drop-off and competitor poaching. Top companies target <30 days.
- **Target**: < 35 days
- **Alert Threshold**: > 45 days
- **Note**: Median is preferred over mean for skewed distributions; both are calculated in the dashboard.

### Average Days in Stage
- **Definition**: Mean duration candidates spend at each funnel stage
- **Formula**: `AVG(days_in_previous_stage) GROUP BY stage`
- **Business Context**: Identifies process bottlenecks. Assessment and interview stages typically take longest; any stage averaging >10 days needs review.
- **Target**: Stage-specific (see below)
  - Resume Screening: < 3 days
  - Phone Screen: < 5 days
  - Assessment: < 7 days
  - Technical Interview: < 10 days
  - Panel Interview: < 7 days
  - Offer Process: < 5 days

### Average Time to Offer
- **Definition**: Mean days from application date to offer date
- **Formula**: `AVG(offer_date - application_date)`
- **Business Context**: Measures total process speed before offer. Competitive markets require faster offers.
- **Target**: < 28 days

---

## 4. Quality KPIs

### Quality of Hire Score (Composite)
- **Definition**: Weighted composite of retention, satisfaction, and ramp metrics
- **Formula**: `(Retention Rate × 0.40) + (Manager Satisfaction / 5 × 0.35) + (Ramp Score / 100 × 0.25) × 100`
- **Business Context**: A single metric to assess hiring effectiveness beyond just volume. Balances speed with quality.
- **Target**: > 70 (on 0-100 scale)
- **Components**:
  - Retention Rate (40% weight): Most critical — a bad hire that leaves is costly
  - Manager Satisfaction (35% weight): Direct measure of hiring decision quality
  - Ramp Score (25% weight): Measures onboarding and selection alignment

### Manager Satisfaction Score
- **Definition**: Hiring manager's rating of new hire's performance (1.0-5.0 scale)
- **Formula**: `AVG(manager_satisfaction_score)`
- **Business Context**: Direct feedback from the hiring manager on whether the candidate meets expectations. Collected at 90-day mark.
- **Target**: > 4.0

### Ramp Score
- **Definition**: Percentage of expected productivity achieved at 90 days
- **Formula**: `AVG(ramp_score)` where ramp_score = actual productivity / target × 100
- **Business Context**: Measures how quickly new hires reach expected performance levels. Low scores may indicate gaps in job requirements, screening, or onboarding.
- **Target**: > 75%

### Onboarding Completion Rate
- **Definition**: Percentage of new hires who complete the full onboarding program
- **Formula**: `Completed Onboarding / Total Started Onboarding × 100`
- **Business Context**: Incomplete onboarding correlates with early attrition and low productivity.
- **Target**: > 90%

---

## 5. Cost KPIs

### Cost per Hire (Estimated)
- **Definition**: Total recruitment costs divided by number of hires
- **Formula**: `(Recruiter Time + Agency Fees + Tool Costs + Advertising) / Hires`
- **Business Context**: Industry benchmarks range from $4,000-$7,000 USD per hire. Should be compared against quality metrics — cheap hires that leave are expensive.
- **Target**: Varies by role seniority
  - Entry: < $3,000
  - Mid: < $5,000
  - Senior: < $8,000
  - Executive: < $15,000

---

## 6. Efficiency KPIs

### Conversion Efficiency Index
- **Definition**: Conversion rate adjusted for time-to-hire
- **Formula**: `(Conversion Rate / Avg Time to Hire) × 100`
- **Business Context**: Higher index = more efficient hiring (high conversion, low time). Useful for comparing departments with different role complexities.
- **Usage**: Rank departments or recruiters by efficiency

### Recruiter Productivity
- **Definition**: Number of hires per recruiter per quarter
- **Formula**: `Total Hires / Number of Active Recruiters`
- **Business Context**: Standard TA capacity metric. Varies by role complexity.
- **Target**: 8-12 hires per recruiter per quarter

---

## 7. Drop-off KPIs

### Stage Drop-off Rate
- **Definition**: Percentage of candidates lost between consecutive funnel stages
- **Formula**: `(Previous Stage Volume - Current Stage Volume) / Previous Stage Volume × 100`
- **Business Context**: The primary diagnostic metric for funnel optimization. Highest drop-off stages are priority improvement targets.
- **Target**: Stage-specific
  - Screening stages: < 30%
  - Interview stages: < 25%
  - Offer stages: < 20%

### Withdrawal Rate
- **Definition**: Percentage of candidates who voluntarily withdraw from the process
- **Formula**: `Withdrawn Applications / Total Applications × 100`
- **Business Context**: High withdrawal rates often correlate with slow processes or poor candidate experience. Track by stage and source to identify patterns.
- **Target**: < 10%

### No-Show Rate
- **Definition**: Percentage of scheduled interviews where the candidate did not appear
- **Formula**: `No Shows / Scheduled Interviews × 100`
- **Business Context**: Wastes interviewer time and slows the process. Higher for job board candidates; lower for referrals.
- **Target**: < 5%

---

## 8. Benchmark Targets Summary

| KPI | Target | Alert | Critical |
|---|---|---|---|
| Overall Conversion Rate | > 5% | < 4% | < 3% |
| Offer Acceptance Rate | > 75% | < 70% | < 65% |
| Avg Time to Hire | < 35 days | > 40 days | > 50 days |
| 90-Day Retention | > 85% | < 80% | < 75% |
| Fill Rate | > 80% | < 65% | < 50% |
| Quality of Hire | > 70 | < 60 | < 50 |
| Stage Drop-off (max) | < 35% | > 40% | > 50% |
| Withdrawal Rate | < 10% | > 15% | > 20% |
