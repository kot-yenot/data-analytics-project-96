WITH latest_sessions AS (
    SELECT
        visitor_id,
        MAX(visit_date) AS last_visit_date
    FROM sessions
    WHERE medium <> 'organic'
    GROUP BY visitor_id
),

filtered_sessions AS (
    SELECT
        s.visitor_id,
        s.visit_date,
        s.source,
        s.medium,
        s.campaign,
        l.lead_id,
        l.created_at,
        l.amount,
        l.closing_reason,
        l.status_id
    FROM sessions AS s
    INNER JOIN latest_sessions AS ls
        ON
            s.visitor_id = ls.visitor_id
            AND s.visit_date = ls.last_visit_date
    LEFT JOIN leads AS l
        ON s.visitor_id = l.visitor_id
    WHERE s.medium <> 'organic'
)

SELECT
    fs.visitor_id,
    fs.visit_date,
    fs.source AS utm_source,
    fs.medium AS utm_medium,
    fs.campaign AS utm_campaign,
    fs.lead_id,
    fs.created_at,
    fs.closing_reason,
    fs.status_id,
    SUM(fs.amount) OVER (PARTITION BY fs.visitor_id) AS amount
FROM filtered_sessions AS fs
ORDER BY
    amount DESC NULLS LAST,
    fs.visit_date ASC,
    fs.source ASC,
    fs.medium ASC,
    fs.campaign ASC;
