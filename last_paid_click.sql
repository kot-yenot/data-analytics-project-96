WITH tab AS (
    SELECT
        visitor_id,
        MAX(visit_date) AS visit_date
    FROM sessions
    GROUP BY visitor_id
),
am AS (
    SELECT
        visitor_id,
        SUM(amount) AS total_amount  -- добавлен алиас для суммы
    FROM leads
    GROUP BY visitor_id
)
SELECT
    t.visitor_id,
    t.visit_date,
    s.source AS utm_source,
    s.medium AS utm_medium,
    s.campaign AS utm_campaign,
    l.visitor_id,
    l.created_at,
    a.total_amount,
    l.closing_reason,
    status_id
FROM tab AS t
INNER JOIN sessions AS s 
    ON s.visit_date = t.visit_date 
    AND s.visitor_id = t.visitor_id
LEFT JOIN leads AS l 
    ON t.visitor_id = l.visitor_id
LEFT JOIN am AS a  -- изменено на LEFT JOIN
    ON a.visitor_id = l.visitor_id
order by amount NULLS last,  t.visit_date, utm_source, utm_medium, utm_campaign;
