INSERT INTO star.d_site (domain, name, created_at)
SELECT
  MD5(RANDOM()::text) as domain,
  MD5(RANDOM()::text) as name,
  now() as created_at
FROM
  generate_series(1,10000) as index;

-- INSERT Companies (Companies who visited my website)
INSERT INTO star.d_company (nk_company_id, name, domain, created_at)
SELECT
  index as nk_company_id,
  MD5(RANDOM()::text) as name,
  MD5(RANDOM()::text) as domain,
  now() as created_at
FROM
  generate_series(1, 1000000) as index;

-- INSERT N Session Visitors
INSERT INTO star.d_visitor (nk_visitor_id, nk_session_id, ip, created_at)
SELECT
  index as nk_visitor_id,
  index as nk_session_id,
  CONCAT(
    TRUNC(RANDOM() * 250), '.',
    TRUNC(RANDOM() * 250), '.',
    TRUNC(RANDOM() * 250), '.',
    TRUNC(RANDOM() * 250), '.'
  )::INET as ip,
  now() as created_at
FROM
  generate_series(1, 100000000) as index;

-- INSERT Times (when the session/visit occured)
INSERT INTO star.d_date (year, quarter, month, day, full_date, created_at)
SELECT
  EXTRACT(YEAR FROM time) as year,
  EXTRACT(QUARTER FROM time) as quarter,
  EXTRACT(MONTH FROM time) as month,
  EXTRACT(DAY FROM time) as day,
  time::date as full_date,
  now() as created_at
FROM
  generate_series('2019-01-01', '2021-12-31', INTERVAL '1 day' ) as time;

-- INSERT N Sessions
INSERT INTO star.f_session(site_id, company_id, date_id, visitor_id, start_time, end_time, duration, page_views_count, created_at)
SELECT
  ROUND(RANDOM() * (10000-1)+1)::int as site_id,
  ROUND(RANDOM() * (1000000-1)+1)::int as company_id,
  ROUND(RANDOM() * (365*3-1)+1)::int as date_id,
  ROUND(RANDOM() * (100000000-1)+1)::int as visitor_id,
  now() as start_time, -- just for the sake of simplicity
  now() as end_time, -- just for the sake of simplicity
  CONCAT(ROUND(RANDOM()), ' seconds')::interval,
  ROUND(random() * (300000-10000) + 10000)::int as page_views_count,
  now() as created_at
FROM
  generate_series(1, 10000000) as index;

SELECT
  d_company.name,
  d_company.domain,
  COUNT(DISTINCT f_session.visitor_id) as unique_visitors_count,
  SUM(f_session.page_views_count) as page_views_count,
  AVG(f_session.duration) as avg_duration
FROM
  star.f_session as f_session
INNER JOIN star.d_site as d_site ON d_site.id = f_session.site_id
INNER JOIN star.d_company as d_company ON d_company.id = f_session.company_id
INNER JOIN star.d_date as d_date ON d_date.id = f_session.date_id
WHERE
  d_date.year = 2019 and d_date.month = 2
GROUP BY
  d_company.name,
  d_company.domain;

SELECT
  d_company.name,
  d_company.domain,
  SUM(f_session.page_views_count) as page_views_count,
  AVG(f_session.duration) as avg_duration
FROM
  star.f_session as f_session
INNER JOIN star.d_company as d_company ON d_company.id = f_session.company_id
GROUP BY
  d_company.name,
  f_session.visitor_id;


-- Query Plan to return data for One Specific Customer
--                                                                          QUERY PLAN
-- -------------------------------------------------------------------------------------------------------------------------------------------------------------
--  GroupAggregate  (cost=3949.49..3950.17 rows=25 width=98) (actual time=1.882..2.014 rows=14 loops=1)
--    Group Key: d_company.name, d_company.domain
--    ->  Sort  (cost=3949.49..3949.55 rows=25 width=90) (actual time=1.835..1.844 rows=14 loops=1)
--          Sort Key: d_company.name, d_company.domain
--          Sort Method: quicksort  Memory: 26kB
--          ->  Nested Loop  (cost=36.43..3948.90 rows=25 width=90) (actual time=0.824..1.781 rows=14 loops=1)
--                ->  Nested Loop  (cost=36.00..3756.48 rows=25 width=28) (actual time=0.772..1.617 rows=14 loops=1)
--                      ->  Index Only Scan using d_site_pkey on d_site  (cost=0.29..8.30 rows=1 width=4) (actual time=0.046..0.050 rows=1 loops=1)
--                            Index Cond: (id = 1)
--                            Heap Fetches: 1
--                      ->  Hash Join  (cost=35.72..3747.93 rows=25 width=32) (actual time=0.708..1.544 rows=14 loops=1)
--                            Hash Cond: (f_session.date_id = d_date.id)
--                            ->  Bitmap Heap Scan on f_session  (cost=20.17..3729.75 rows=998 width=36) (actual time=0.520..1.277 rows=473 loops=1)
--                                  Recheck Cond: (site_id = 1)
--                                  Heap Blocks: exact=473
--                                  ->  Bitmap Index Scan on idx_site_id  (cost=0.00..19.92 rows=998 width=0) (actual time=0.379..0.380 rows=473 loops=1)
--                                        Index Cond: (site_id = 1)
--                            ->  Hash  (cost=15.20..15.20 rows=28 width=4) (actual time=0.090..0.093 rows=28 loops=1)
--                                  Buckets: 1024  Batches: 1  Memory Usage: 9kB
--                                  ->  Bitmap Heap Scan on d_date  (cost=4.92..15.20 rows=28 width=4) (actual time=0.048..0.074 rows=28 loops=1)
--                                        Recheck Cond: (month = 2)
--                                        Filter: (year = 2019)
--                                        Rows Removed by Filter: 57
--                                        Heap Blocks: exact=4
--                                        ->  Bitmap Index Scan on idx_date_month  (cost=0.00..4.92 rows=85 width=0) (actual time=0.030..0.031 rows=85 loops=1)
--                                              Index Cond: (month = 2)
--                ->  Index Scan using d_company_pkey on d_company  (cost=0.42..7.70 rows=1 width=70) (actual time=0.009..0.009 rows=1 loops=14)
--                      Index Cond: (id = f_session.company_id)
--  Planning Time: 2.884 ms
--  Execution Time: 58.960 ms
-- (30 rows)

-- Query Plan to return data for All Customers
--                                                                                 QUERY PLAN
-- ---------------------------------------------------------------------------------------------------------------------------------------------------------------------------
--  GroupAggregate  (cost=262542.61..269568.20 rows=255476 width=98) (actual time=3436.394..3707.915 rows=225715 loops=1)
--    Group Key: d_company.name, d_company.domain
--    ->  Sort  (cost=262542.61..263181.30 rows=255476 width=90) (actual time=3436.343..3487.523 rows=255816 loops=1)
--          Sort Key: d_company.name, d_company.domain
--          Sort Method: external merge  Disk: 26552kB
--          ->  Gather  (cost=169996.45..226496.75 rows=255476 width=90) (actual time=3143.456..3205.833 rows=255816 loops=1)
--                Workers Planned: 2
--                Workers Launched: 2
--                ->  Parallel Hash Join  (cost=168996.45..199949.15 rows=106448 width=90) (actual time=3112.893..3189.529 rows=85272 loops=3)
--                      Hash Cond: (d_company.id = f_session.company_id)
--                      ->  Parallel Seq Scan on d_company  (cost=0.00..18452.67 rows=416667 width=70) (actual time=1.642..216.068 rows=333333 loops=3)
--                      ->  Parallel Hash  (cost=166937.85..166937.85 rows=106448 width=28) (actual time=2760.589..2760.598 rows=85272 loops=3)
--                            Buckets: 65536  Batches: 8  Memory Usage: 2560kB
--                            ->  Hash Join  (cost=374.55..166937.85 rows=106448 width=28) (actual time=19.981..2725.915 rows=85272 loops=3)
--                                  Hash Cond: (f_session.site_id = d_site.id)
--                                  ->  Hash Join  (cost=15.55..166299.31 rows=106448 width=32) (actual time=3.111..2671.452 rows=85272 loops=3)
--                                        Hash Cond: (f_session.date_id = d_date.id)
--                                        ->  Parallel Seq Scan on f_session  (cost=0.00..155303.90 rows=4166690 width=36) (actual time=1.780..2313.859 rows=3333333 loops=3)
--                                        ->  Hash  (cost=15.20..15.20 rows=28 width=4) (actual time=0.142..0.148 rows=28 loops=3)
--                                              Buckets: 1024  Batches: 1  Memory Usage: 9kB
--                                              ->  Bitmap Heap Scan on d_date  (cost=4.92..15.20 rows=28 width=4) (actual time=0.066..0.097 rows=28 loops=3)
--                                                    Recheck Cond: (month = 2)
--                                                    Filter: (year = 2019)
--                                                    Rows Removed by Filter: 57
--                                                    Heap Blocks: exact=4
--                                                    ->  Bitmap Index Scan on idx_date_month  (cost=0.00..4.92 rows=85 width=0) (actual time=0.042..0.044 rows=85 loops=3)
--                                                          Index Cond: (month = 2)
--                                  ->  Hash  (cost=234.00..234.00 rows=10000 width=4) (actual time=15.418..15.419 rows=10000 loops=3)
--                                        Buckets: 16384  Batches: 1  Memory Usage: 480kB
--                                        ->  Seq Scan on d_site  (cost=0.00..234.00 rows=10000 width=4) (actual time=0.052..6.541 rows=10000 loops=3)
--  Planning Time: 1.640 ms
--  Execution Time: 3718.086 ms