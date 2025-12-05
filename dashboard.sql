select
    visit_date,
    sum(leads_count),
    SUM(leads_count) OVER () as total_leads,
    ROUND(SUM(leads_count) OVER (order by visit_date) * 100.0 
    / SUM(leads_count) OVER (), 2) as percentage
  from voronka
  group by visit_date
  order by visit_date
select
  sum(visitors_count),
  utm_source,
  sum(total_cost),
  sum(revenue)
  from voronka
  where utm_source = 'vk' or utm_source = 'yandex'
  group by utm_source
  order by revenue desc nulls last;
select
  *,
    total_cost / visitors_count as cpu,
    total_cost / leads_count as cpl,
    total_cost / purchases_count as cppu,
    (revenue - total_cost) / total_cost * 100 as roi
  from voronka;
