-- ==============================================================================
-- STRMLFIX SUBSCRIBER CHURN INTELLIGENCE SCRIPT
-- Objective: Root-cause diagnostic queries to isolate a 44.8% subscriber leak 
-- Author: Daliya Chakraborty
-- Domain: Subscription-Based Digital Ecosystems
-- ==============================================================================

-- ------------------------------------------------------------------------------
-- PHASE 1: STAGING & DATA EXTRACTION SETUP
-- Creating the enterprise table structure based on ingested staging schemas.
-- ------------------------------------------------------------------------------

CREATE TABLE streamflix_customer_data (
    customer_id VARCHAR(50) PRIMARY KEY,
    age INT,
    gender VARCHAR(20),
    subscription_length_months INT,
    region VARCHAR(50),
    payment_method VARCHAR(50),
    support_tickets_raised INT,
    satisfaction_score INT,
    discount_offered DECIMAL(5,2),
    last_activity_days INT,
    monthly_spend DECIMAL(10,2),
    churned INT,                         -- 1 for Churned, 0 for Retained
    churn_status VARCHAR(20),            -- 'Churned' vs 'Retained'
    age_group VARCHAR(20),
    inactivity_segment VARCHAR(50),
    satisfaction_tier VARCHAR(50),
    tenure_band VARCHAR(50),
    spend_tier VARCHAR(50),
    churn_risk_score DECIMAL(5,2),
    churn_risk_label VARCHAR(50),
    primary_pain_point VARCHAR(100),
    viewer_persona VARCHAR(100),
    streaming_access_model VARCHAR(100),
    estimated_device_profile VARCHAR(100),
    monetization_sensitivity VARCHAR(50),
    reengagement_priority VARCHAR(50),
    monthly_revenue_inr DECIMAL(10,2),
    revenue_at_risk_inr DECIMAL(10,2)
);

-- ------------------------------------------------------------------------------
-- PHASE 2: HIGH-LEVEL EXECUTIVE METRICS (THE TOP-LINE KPI PANEL)
-- Replicating the main dashboard high-level metric summaries.
-- ------------------------------------------------------------------------------

-- Query 1: Total Base, Global Churn/Retention Rates, and Macro Financial Leakages
SELECT 
    COUNT(*) AS total_tracked_subscribers,
    SUM(CASE WHEN churned = 1 THEN 1 ELSE 0 END) AS total_churned_subscribers,
    ROUND(AVG(churned) * 100, 1) AS churn_rate_percentage,
    ROUND((1 - AVG(churned)) * 100, 1) AS retention_rate_percentage,
    
    -- Financial loss calculations (INR Lakhs and Crores)
    ROUND(SUM(CASE WHEN churned = 1 THEN monthly_revenue_inr ELSE 0 END) / 100000.0, 1) AS monthly_revenue_lost_lakhs,
    ROUND((SUM(CASE WHEN churned = 1 THEN monthly_revenue_inr ELSE 0 END) * 12) / 10000000.0, 2) AS annualized_revenue_lost_crores
FROM streamflix_customer_data;


-- ------------------------------------------------------------------------------
-- PHASE 3: THE "DIAGNOSTIC CLIFFS" & HARD PRODUCT THRESHOLDS
-- Verifying the high-conviction risk zones identified in the visualization.
-- ------------------------------------------------------------------------------

-- Query 2: Testing the Satisfaction Cliff (Proving the <= 3 Satisfaction Rule)
SELECT 
    satisfaction_tier,
    COUNT(*) AS pool_size,
    SUM(churned) AS churn_count,
    ROUND(AVG(churned) * 100, 1) AS group_churn_rate,
    ROUND(SUM(CASE WHEN churned = 1 THEN monthly_revenue_inr ELSE 0 END) / 100000.0, 2) AS monthly_leakage_lakhs,
    ROUND((SUM(CASE WHEN churned = 1 THEN monthly_revenue_inr ELSE 0 END) / 
           SUM(SUM(CASE WHEN churned = 1 THEN monthly_revenue_inr ELSE 0 END)) OVER()) * 100, 1) AS share_of_total_revenue_lost
FROM streamflix_customer_data
GROUP BY satisfaction_tier
ORDER BY group_churn_rate DESC;


-- Query 3: Tracking Customer Support Burnout Escalations (The Ticket Cliff)
SELECT 
    CASE 
        WHEN support_tickets_raised >= 5 THEN 'Critical Risk (5+ Tickets)'
        ELSE CONCAT(CAST(support_tickets_raised AS CHAR), ' Ticket(s)')
    END AS customer_support_cohort,
    COUNT(*) AS cohort_size,
    SUM(churned) AS churned_count,
    ROUND(AVG(churned) * 100, 1) AS cohort_churn_rate
FROM streamflix_customer_data
GROUP BY 
    CASE 
        WHEN support_tickets_raised >= 5 THEN 'Critical Risk (5+ Tickets)'
        ELSE CONCAT(CAST(support_tickets_raised AS CHAR), ' Ticket(s)')
    END
ORDER BY MIN(support_tickets_raised) ASC;


-- ------------------------------------------------------------------------------
-- PHASE 4: PAIN POINT SEGMENTATION & DEBUNKING OPERATIONAL MYTHS
-- Deep dive into qualitative churn attributes to map the "Reasons for Leaving".
-- ------------------------------------------------------------------------------

-- Query 4: Revenue Leaks Sorted by Concrete Qualitative Pain Points
SELECT 
    primary_pain_point,
    COUNT(*) AS total_affected_users,
    SUM(churned) AS churn_volume,
    ROUND((COUNT(CASE WHEN churned = 1 THEN 1 END) / SUM(COUNT(CASE WHEN churned = 1 THEN 1 END)) OVER()) * 100, 0) AS percentage_contribution,
    ROUND(SUM(CASE WHEN churned = 1 THEN monthly_revenue_inr ELSE 0 END), 0) AS exact_monthly_leakage_inr
FROM streamflix_customer_data
WHERE primary_pain_point IS NOT NULL AND churned = 1
GROUP BY primary_pain_point
ORDER BY exact_monthly_leakage_inr DESC;


-- Query 5: Mitigating False Alarms (Proving that Tenure Group Churn is Flat)
-- This query confirms that churn risk is uniform across long-term and short-term cohorts.
SELECT 
    tenure_band,
    COUNT(*) AS cohort_total,
    ROUND(AVG(churned) * 100, 1) AS churn_rate_variance
FROM streamflix_customer_data
GROUP BY tenure_band
ORDER BY tenure_band ASC;