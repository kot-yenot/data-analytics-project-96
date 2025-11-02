WITH aggregated_leads AS (
    SELECT
        visitor_id,
        SUM(amount) AS total_amount_per_visitor
    FROM leads
    GROUP BY visitor_id
),

ranked_sessions AS (
    SELECT
        s.visitor_id,
        s.visit_date,
        s.source AS utm_source,
        s.medium AS utm_medium,
        s.campaign AS utm_campaign,
        l.total_amount_per_visitor AS amount,
        ROW_NUMBER() OVER (
            PARTITION BY s.visitor_id
            ORDER BY s.visit_date DESC
        ) AS rn
    FROM sessions AS s
    LEFT JOIN aggregated_leads AS l
        ON s.visitor_id = l.visitor_id
    WHERE s.medium <> 'organic'
)

SELECT
    visitor_id,
    visit_date,
    utm_source,
    utm_medium,
    utm_campaign,
    amount
FROM ranked_sessions
WHERE rn = 1
ORDER BY
    amount DESC NULLS LAST,
    visit_date ASC,
    utm_source ASC,
    utm_medium ASC,
    utm_campaign ASC;
