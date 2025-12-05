select
    visit_date,
    sum(leads_count) as sum_leads_count,
    sum(leads_count) over () as total_leads,
    round(
        sum(leads_count) over (order by visit_date) * 100.0
        / sum(leads_count) over (), 2
    ) as percentage
from voronka
group by visit_date
order by visit_date;
select
    utm_source,
    sum(visitors_count) as sum_visitors_count,
    sum(total_cost) as sum_total_cost,
    sum(revenue) as sum_revenue
from voronka
where utm_source = 'vk' or utm_source = 'yandex'
group by utm_source
order by revenue desc nulls last;
select
    visit_date,
    visitors_count,
    utm_source,
    utm_medium,
    utm_campaign,
    total_cost,
    leads_count,
    purchases_count,
    revenue,
    total_cost / visitors_count as cpu,
    total_cost / leads_count as cpl,
    total_cost / purchases_count as cppu,
    (revenue - total_cost) / total_cost * 100 as roi
from voronka;
select
    date(sessions.visit_date) as visit_date,
    count(sessions.visitor_id) as visitors_count,
    sum(case
        when leads.status_id = 142 then 1.0
        else 0.0
    end) / count(sessions.visitor_id) * 100 as purchases_percentage,
    sum(case
        when leads.status_id = 142 then 1
        else 0
    end) as purchases_count
from sessions
left join leads on sessions.visitor_id = leads.visitor_id
where sessions.medium = 'organic'
group by date(sessions.visit_date)
order by sessions.visit_date;
