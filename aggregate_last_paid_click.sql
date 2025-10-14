WITH daily_visits AS (
    SELECT
        DATE(visit_date) AS visit_date,
        source,
        medium,
        campaign,
        COUNT(*) AS visitors_count
    FROM sessions
    WHERE source <> 'organic'
    GROUP BY 
        DATE(visit_date),
        source,
        medium,
        campaign
),
ad_costs AS (
    SELECT
        DATE(campaign_date) AS visit_date,
        utm_source,
        utm_medium,
        utm_campaign,
        SUM(daily_spent) AS total_cost
    FROM (
        SELECT campaign_date, utm_source, utm_medium, utm_campaign, daily_spent FROM vk_ads
        UNION ALL
        SELECT campaign_date, utm_source, utm_medium, utm_campaign, daily_spent FROM ya_ads
    ) ads
    GROUP BY 
        DATE(campaign_date),
        utm_source,
        utm_medium,
        utm_campaign
),
lead_stats AS (
    SELECT
        DATE(leads.created_at) AS visit_date,
        sessions.source,
        sessions.medium,
        sessions.campaign,
        COUNT(DISTINCT leads.lead_id) AS leads_count,
        SUM(CASE 
            WHEN closing_reason = 'Успешно реализовано' OR status_id = 142 
            THEN 1 
            ELSE 0 
        END) AS purchases_count,
        SUM(CASE 
            WHEN closing_reason = 'Успешно реализовано' OR status_id = 142 
            THEN amount 
            ELSE 0 
        END) AS revenue
    FROM leads
    LEFT JOIN sessions ON leads.visitor_id = sessions.visitor_id
    WHERE sessions.source <> 'organic'
    GROUP BY 
        DATE(leads.created_at),
        sessions.source,
        sessions.medium,
        sessions.campaign
)
SELECT
    dv.visit_date,
    dv.visitors_count,
    dv.source,
    dv.medium,
    dv.campaign,
    ac.total_cost,
    ls.leads_count,
    ls.purchases_count,
    ls.revenue
FROM daily_visits dv
LEFT JOIN ad_costs ac 
    ON dv.visit_date = ac.visit_date 
    AND dv.source = ac.utm_source 
    AND dv.medium = ac.utm_medium 
    AND dv.campaign = ac.utm_campaign
LEFT JOIN lead_stats ls 
    ON dv.visit_date = ls.visit_date 
    AND dv.source = ls.source 
    AND dv.medium = ls.medium 
    AND dv.campaign = ls.campaign
ORDER BY 
    dv.visit_date ASC,          
    dv.visitors_count DESC,    
    dv.source ASC,            
    dv.medium ASC,             
    dv.campaign ASC,          
    ls.revenue DESC NULLS LAST; 
