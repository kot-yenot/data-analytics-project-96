WITH filtered_sessions AS (
    SELECT
        s.visitor_id,
        s.visit_date,
        s.source AS utm_source,
        s.medium AS utm_medium,
        s.campaign AS utm_campaign,
        l.lead_id,
        l.created_at,
        l.amount,
        l.closing_reason,
        l.status_id,
        ROW_NUMBER() OVER (
            PARTITION BY s.visitor_id, l.lead_id
            ORDER BY s.visit_date DESC
        ) AS rn
    FROM sessions AS s
    LEFT JOIN leads AS l
        ON
            s.visitor_id = l.visitor_id
            AND s.visit_date < l.created_at
    WHERE s.medium <> 'organic'
),

final_sessions AS (
    SELECT
        visitor_id,
        visit_date,
        utm_source,
        utm_medium,
        utm_campaign,
        lead_id,
        created_at,
        amount,
        closing_reason,
        status_id
    FROM filtered_sessions
    WHERE rn = 1
)

SELECT
    fs.visitor_id,
    fs.visit_date,
    fs.utm_source,
    fs.utm_medium,
    fs.utm_campaign,
    fs.lead_id,
    fs.created_at,
    fs.closing_reason,
    fs.status_id,
    SUM(fs.amount) OVER (PARTITION BY fs.visitor_id) AS amount
FROM final_sessions AS fs
ORDER BY
    amount DESC NULLS LAST,
    visit_date ASC,
    utm_source ASC,
    utm_medium ASC,
    utm_campaign ASC;

