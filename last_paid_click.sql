WITH users AS (
 SELECT
 visitor_id,
 MAX(visit_date) AS visit_date
 FROM sessions 
 WHERE medium IN ('cpc', 'cpa', 'youtube', 'cpp', 'tg', 'social')
 GROUP BY visitor_id
),
am AS (
    SELECT
        visitor_id,
        SUM(amount) AS total_amount
    FROM leads
    GROUP BY visitor_id
)
SELECT
 u.visitor_id,
 u.visit_date,
 s.source AS utm_source,
 s.medium AS utm_medium,
 s.campaign AS utm_campaign,
 l.visitor_id as lead_id,
 l.created_at,
 NULLIF(l.amount, 0) AS total_amount,
 l.closing_reason,
 l.status_id
FROM users AS u
INNER JOIN sessions AS s 
 ON s.visit_date = u.visit_date 
 AND s.visitor_id = u.visitor_id
LEFT JOIN leads AS l 
 ON u.visitor_id = l.visitor_id
 AND l.created_at >= u.visit_date
 LEFT JOIN am AS a
    ON a.visitor_id = l.visitor_id
ORDER BY 
 total_amount DESC NULLS LAST, 
 u.visit_date,
 utm_source,
 utm_medium,
 utm_campaign;