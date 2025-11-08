WITH base_sessions AS (
    SELECT
        s.visitor_id,
        CAST(s.visit_date AS DATE) AS visit_date,
        s.source AS utm_source,
        s.medium AS utm_medium,
        s.campaign AS utm_campaign,
        l.lead_id,
        l.amount,
        l.status_id
    FROM sessions s
    INNER JOIN (
        SELECT visitor_id, MAX(CAST(visit_date AS DATE)) AS last_visit_date
        FROM sessions
        WHERE medium <> 'organic'
        GROUP BY visitor_id
    ) ls ON s.visitor_id = ls.visitor_id
        AND CAST(s.visit_date AS DATE) = ls.last_visit_date
    LEFT JOIN leads l ON s.visitor_id = l.visitor_id
    WHERE s.medium <> 'organic' 
    AND s.source IN ('vk', 'yandex') 
),
leads_summary AS (
    SELECT
        visit_date,
        utm_source,
        utm_medium,
        utm_campaign,
        SUM(amount) AS total_amount
    FROM base_sessions
    WHERE lead_id IS NOT NULL
    GROUP BY visit_date, utm_source, utm_medium, utm_campaign
),
final_report AS (
    SELECT
        bs.visit_date,
        bs.utm_source, 
        bs.utm_medium, 
        bs.utm_campaign,
        COUNT(bs.visitor_id) AS visitors_count,
        COUNT(bs.lead_id) AS leads_count,
        SUM(CASE WHEN bs.status_id = 142 THEN 1 ELSE 0 END) AS purchases_count,
        COALESCE(ls.total_amount, 0) AS lead_total_amount  -- явно указываем источник суммы
    FROM base_sessions bs
    LEFT JOIN leads_summary ls 
        ON bs.visit_date = ls.visit_date
        AND bs.utm_source = ls.utm_source
        AND bs.utm_medium = ls.utm_medium
        AND bs.utm_campaign = ls.utm_campaign
    GROUP BY 
        bs.visit_date, 
        bs.utm_source, 
        bs.utm_medium, 
        bs.utm_campaign,
        ls.total_amount
),
final_report_with_ads AS (
    SELECT
        f.visit_date,
        f.visitors_count,
        f.utm_source,
        f.utm_medium,
        f.utm_campaign,
        f.leads_count,
        f.purchases_count,
        f.lead_total_amount as revenue,
        COALESCE(v.daily_spent, ya.daily_spent) AS daily_spent,
        row_number() over (partition by f.visit_date,
        f.visitors_count,
        f.utm_source,
        f.utm_medium,
        f.utm_campaign,
        f.leads_count,
        f.purchases_count,
        f.lead_total_amount) as row_number
    FROM final_report f
    LEFT JOIN vk_ads v
        ON f.utm_source = v.utm_source
        AND f.utm_medium = v.utm_medium
        AND f.utm_campaign = v.utm_campaign
        AND f.visit_date = CAST(v.campaign_date AS DATE)
    LEFT JOIN ya_ads ya
        ON f.utm_source = ya.utm_source
        AND f.utm_medium = ya.utm_medium
        AND f.utm_campaign = ya.utm_campaign
        AND f.visit_date = CAST(ya.campaign_date AS DATE)
)
SELECT 
    visit_date,
    visitors_count,
    utm_source,
    utm_medium,
    utm_campaign,
    SUM(daily_spent) OVER (
        PARTITION BY visit_date, utm_source, utm_medium, utm_campaign
    ) AS total_cost,
    leads_count,
    purchases_count,
    revenue
FROM final_report_with_ads
where row_number = 1
ORDER BY visit_date asc, visitors_count desc, utm_source asc, utm_medium asc, utm_campaign asc, revenue desc NULLS last;
