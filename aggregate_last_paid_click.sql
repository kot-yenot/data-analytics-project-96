WITH latest_sessions AS (
    SELECT
        visitor_id,
        MAX(CAST(s.visit_date AS DATE)) AS last_visit_date
    FROM sessions as s
    WHERE medium <> 'organic'
    GROUP BY visitor_id
),
filtered_sessions AS (
    SELECT
        s.visitor_id,
        CAST(s.visit_date AS DATE) AS visit_date,
        s.source as utm_source,
        s.medium as utm_medium,
        s.campaign as utm_campaign,
        l.lead_id,
        l.amount,
        l.status_id
    FROM sessions AS s
    INNER JOIN latest_sessions AS ls
        ON s.visitor_id = ls.visitor_id
        AND CAST(s.visit_date AS DATE) = ls.last_visit_date
    LEFT JOIN leads AS l
        ON s.visitor_id = l.visitor_id
    WHERE s.medium <> 'organic' 
),
vk AS (
    SELECT 
        CAST(campaign_date AS DATE) AS date,
        utm_source,
        utm_medium,
        utm_campaign,
        SUM(daily_spent) AS total_spent
    FROM vk_ads
    GROUP BY 
        CAST(campaign_date AS DATE),
        utm_source,
        utm_medium,
        utm_campaign
),
ya AS (
    SELECT 
        CAST(campaign_date AS DATE) AS date,
        utm_source,
        utm_campaign,
        SUM(daily_spent) AS total_spent
    FROM ya_ads
    GROUP BY 
        CAST(campaign_date AS DATE),
        utm_source,
        utm_campaign
),
group_days AS (
    SELECT
        gd.visit_date,
        gd.utm_source,
        gd.utm_medium,
        gd.utm_campaign,
        COUNT(DISTINCT visitor_id) AS visitors_count,
        COUNT(lead_id) AS leads_count,
        SUM(CASE WHEN status_id = 142 THEN 1 ELSE 0 END) AS purchases_count,
        SUM(amount) AS revenue,
        COALESCE(vk.total_spent, ya.total_spent, 0) AS total_cost
    FROM filtered_sessions gd
    LEFT JOIN vk
        ON gd.visit_date = vk.date
        AND gd.utm_source = vk.utm_source
        AND gd.utm_medium = vk.utm_medium
        AND gd.utm_campaign = vk.utm_campaign
    LEFT JOIN ya
        ON gd.visit_date = ya.date
        AND gd.utm_source = ya.utm_source
        AND gd.utm_campaign = ya.utm_campaign
    GROUP BY 
        gd.visit_date,
        gd.utm_source,
        gd.utm_medium,
        gd.utm_campaign,
        vk.total_spent,
        ya.total_spent
)
    SELECT 
        visit_date,
        visitors_count,
        utm_source,
        utm_medium,
        utm_campaign,
        total_cost,
        leads_count,
        purchases_count,
        revenue
    FROM group_days
    ORDER BY 
        visit_date, 
        visitors_count DESC,
        utm_source ASC,
        utm_medium ASC,
        utm_campaign ASC,
        revenue DESC NULLS LAST
LIMIT 15;
