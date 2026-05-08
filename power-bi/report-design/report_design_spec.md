# Power BI Report Design Specification

## Hiring Funnel Analytics Dashboard

---

## 1. Report Overview

This document specifies the layout, visuals, and interactions for the **Hiring Funnel Analytics Dashboard** built in Power BI. The report is designed for HR leaders, Talent Acquisition teams, and executives to monitor, analyze, and optimize their hiring pipeline.

---

## 2. Data Model

### 2.1 Schema: Star Schema

```
                    dim_candidate ──┐
                                   │
                    dim_job ────────┤
                                   │
                    dim_recruiter ──┤
                                   ├── fact_application ──── fact_offer
                    dim_stage ──────┤       │
                                   │       └── fact_stage_transition
                    dim_date ───────┤       │
                                   │       └── fact_onboarding
                    dim_rejection ──┘
```

### 2.2 Relationships

| Fact Table | Dimension Table | Join Key | Cardinality |
|---|---|---|---|
| fact_application | dim_candidate | candidate_id | Many-to-One |
| fact_application | dim_job | job_id | Many-to-One |
| fact_application | dim_recruiter | recruiter_id | Many-to-One |
| fact_application | dim_stage | current_stage_id | Many-to-One |
| fact_stage_transition | fact_application | application_id | Many-to-One |
| fact_stage_transition | dim_stage (from) | from_stage_id | Many-to-One |
| fact_stage_transition | dim_stage (to) | to_stage_id | Many-to-One |
| fact_stage_transition | dim_date | transition_date_key | Many-to-One |
| fact_offer | fact_application | application_id | One-to-One |
| fact_onboarding | fact_application | application_id | One-to-One |

### 2.3 Import vs DirectQuery

- **Recommended**: Import mode for optimal DAX performance
- **Refresh Schedule**: Daily at 6:00 AM IST (before standup)
- **Incremental Refresh**: Enabled for fact_stage_transition (rolling 24 months)

---

## 3. Report Pages

### Page 1: Executive Summary

**Purpose**: High-level KPIs and trends for leadership review

| Position | Visual | Fields | Notes |
|---|---|---|---|
| Top Row | KPI Cards (5) | Total Applications, Active Pipeline, Total Hires, Avg Time to Hire, Conversion Rate | Conditional formatting: Green/Yellow/Red thresholds |
| Left | Line Chart | X: Month, Y: Total Applications, Total Hires | Dual-axis, 18-month view |
| Center | Funnel Chart | Stage Name → Funnel Volume | Custom colors per stage category |
| Right | Donut Chart | Source Channel → Applications | Top 5 channels + "Other" |
| Bottom Left | Bar Chart | Department → Hires, Applications | Stacked bar |
| Bottom Right | Scorecard | Fill Rate by Department vs. Target | Bullet chart variant |

**Slicers**: Date Range, Department, Source Channel

**Conditional Formatting Rules**:
- Conversion Rate: 🟢 >8%, 🟡 5-8%, 🔴 <5%
- Time to Hire: 🟢 <30 days, 🟡 30-45 days, 🔴 >45 days
- Fill Rate: 🟢 >80%, 🟡 50-80%, 🔴 <50%

---

### Page 2: Funnel Deep Dive

**Purpose**: Detailed stage-by-stage funnel analysis with drop-off insights

| Position | Visual | Fields | Notes |
|---|---|---|---|
| Top | Funnel Chart | Stage → Volume, Drop-off Rate | Annotated with % at each level |
| Left | Waterfall Chart | Stage → Cumulative Drop-off | Shows contribution of each stage to total loss |
| Center | Heatmap (Matrix) | Rows: Department, Cols: Stage, Values: Drop-off % | Conditional formatting: White→Red |
| Right | Stacked Bar | Stage → Failed/Withdrawn/No Show | Breakdown of exits by type |
| Bottom Left | Scatter Plot | X: Avg Days in Stage, Y: Drop-off Rate, Size: Volume | Bubble chart by stage |
| Bottom Right | Table | Stage, Volume, Conv%, Drop-off%, Avg Days, Top Rejection Reason | Sortable columns |

**Slicers**: Date Range, Department, Seniority Level

---

### Page 3: Drop-off Analysis

**Purpose**: Identify root causes of candidate loss

| Position | Visual | Fields | Notes |
|---|---|---|---|
| Top Left | Bar Chart | Rejection Reason Category → Count | Horizontal, sorted by count |
| Top Right | Treemap | Rejection Reason → Count | Drill-down from category to specific reason |
| Middle Left | Line Chart | X: Month, Y: Drop-off Rate by Stage | Multiple lines (one per stage) |
| Middle Right | Gauge Chart | Current Drop-off Rate vs. Benchmark | Target: Industry benchmark per stage |
| Bottom Left | Stacked Column | Stage → Withdrawal by Source | Shows which sources have most withdrawals |
| Bottom Right | Table | Top 10 Jobs with Highest Drop-off | Includes stage, reason, count, rate |

**Slicers**: Date Range, Department, Stage, Source Channel

---

### Page 4: Conversion Metrics

**Purpose**: Track and compare conversion rates across segments

| Position | Visual | Fields | Notes |
|---|---|---|---|
| Top | KPI Cards (4) | E2E Conversion, Offer Accept Rate, Screening Pass Rate, Interview-to-Offer Rate | With MoM trend arrows |
| Left | Line Chart | X: Month, Y: Conversion Rate + Rolling 3M Avg | Trend line with forecast |
| Center | Clustered Bar | Department → Conversion Rate by Quarter | QoQ comparison |
| Right | 100% Stacked Bar | Seniority Level → Stage Survival Rate | Shows funnel compression by level |
| Bottom Left | Table | Source Channel → Applications, Hires, Conv%, Avg TTH, Quality Score | Ranked by conversion |
| Bottom Right | Scatter Plot | X: Conversion Rate, Y: Avg TTH, Size: Volume, Color: Department | Efficiency quadrant |

**Slicers**: Date Range, Department, Source Channel, Seniority

---

### Page 5: Recruiter Performance

**Purpose**: Evaluate individual and team recruiter effectiveness

| Position | Visual | Fields | Notes |
|---|---|---|---|
| Top | KPI Cards (3) | Total Recruiters, Avg Conversion Rate, Avg Time to Hire | Team-level aggregates |
| Left | Bar Chart | Recruiter → Hires | Horizontal, top 8 recruiters |
| Center | Scatter Plot | X: Pipeline Load, Y: Conversion Rate, Size: Hires | Performance quadrants |
| Right | Table | Recruiter, Team, Assigned, Hires, Conv%, Avg TTH, Quality Score | Full detail table |
| Bottom Left | Stacked Column | Recruiter Team → Active/Rejected/Accepted/Withdrawn | Team-level distribution |
| Bottom Right | Gauge | Team → Avg Time to Hire vs. Target | Per-team gauge |

**Slicers**: Date Range, Recruiter Team

---

### Page 6: Offer & Compensation

**Purpose**: Analyze offer outcomes and compensation trends

| Position | Visual | Fields | Notes |
|---|---|---|---|
| Top Left | KPI Cards (3) | Offer Accept Rate, Avg Total Comp, Offer Decline Rate | |
| Top Right | Funnel | Offer Discussion → Extended → Accepted | Offer-specific funnel |
| Middle Left | Box Plot | Department → Total Compensation | Distribution visualization |
| Middle Right | Pie Chart | Decline Reason → Count | Top reasons |
| Bottom Left | Line Chart | X: Month, Y: Avg Compensation Offered vs. Accepted | Salary trends |
| Bottom Right | Table | Department, Offers, Acceptances, Accept%, Avg Comp, Top Decline Reason | Detailed table |

---

### Page 7: Quality of Hire

**Purpose**: Track post-hire success metrics

| Position | Visual | Fields | Notes |
|---|---|---|---|
| Top | KPI Cards (4) | 90-Day Retention, Avg Manager Satisfaction, Avg Ramp Score, Quality of Hire Score | |
| Left | Line Chart | X: Cohort Month, Y: Retention Rate | Rolling 3-month |
| Center | Stacked Bar | 90-Day Status by Department | Active / PIP / Voluntary Exit / Involuntary Exit |
| Right | Scatter Plot | X: Ramp Score, Y: Manager Satisfaction | Bubble by department |
| Bottom | Table | Department, Onboarded, Completed, Retention%, Avg Satisfaction, Avg Ramp Score | Detailed table |

---

## 4. Color Palette

| Element | Hex | Usage |
|---|---|---|
| Primary | #2563EB | Headers, primary bars, active elements |
| Secondary | #10B981 | Positive indicators, "on track" |
| Warning | #F59E0B | Caution states, "needs attention" |
| Danger | #EF4444 | Critical alerts, "below benchmark" |
| Neutral | #6B7280 | Secondary text, borders |
| Background | #F9FAFB | Page background |
| Card BG | #FFFFFF | KPI card backgrounds |
| Screening | #3B82F6 | Funnel - screening stages |
| Interview | #8B5CF6 | Funnel - interview stages |
| Assessment | #F97316 | Funnel - assessment stages |
| Offer | #10B981 | Funnel - offer stages |
| Onboarding | #06B6D4 | Funnel - onboarding stages |

---

## 5. Bookmarks & Navigation

| Bookmark | Description |
|---|---|
| Executive View | Default view with all departments |
| Engineering Focus | Pre-filtered to Engineering dept |
| Current Quarter | Filtered to current quarter dates |
| Year over Year | Side-by-side comparison layout |

**Navigation**: Top navigation bar with page icons and labels

---

## 6. Row-Level Security (RLS)

| Role | Filter | DAX Rule |
|---|---|---|
| HR Admin | Full access | No filter |
| Dept Head | Own department | `[department] = USERNAMEORPRINCIPAL()` |
| Recruiter | Own pipeline | `[recruiter_id] = LOOKUPVALUE(...)` |

---

## 7. Performance Optimization

1. **Aggregation Table**: Pre-aggregate fact_stage_transition by date + stage
2. **Calculation Group**: Use for time intelligence (MTD, QTD, YTD)
3. **VertiPaq Analyzer**: Monitor after import, target <500MB model
4. **Auto Date/Time**: Disabled — use dim_date table
5. **Bi-directional Filters**: Only where necessary (fact_stage_transition → dim_stage)
