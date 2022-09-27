DROP SCHEMA star CASCADE;
CREATE SCHEMA star;

CREATE TABLE star.d_site (
  id serial PRIMARY KEY,
  domain varchar unique not null,
  name varchar unique not null,
  created_at timestamp not null
);

create index idx_site_domain on star.d_site(domain);

-- Session star
CREATE TABLE star.d_company (
  id serial PRIMARY KEY,
  nk_company_id int not null,
  name varchar not null,
  domain varchar not null,
  created_at timestamp NOT NULL
);

CREATE TABLE star.d_date (
  id serial PRIMARY KEY,
  year int not null,
  quarter int not null,
  month int not null,
  day int not null,
  full_date date not null,
  created_at timestamp NOT NULL
);

create unique index idx_date_dimension_uniqueness
on star.d_date(full_date);

create index idx_date_year on star.d_date(year);
create index idx_date_quarter on star.d_date(quarter);
create index idx_date_month on star.d_date(month);

CREATE TABLE star.d_visitor (
  id serial PRIMARY KEY,
  nk_visitor_id int not null,
  nk_session_id varchar not null,
  ip inet not null,
  created_at timestamp NOT NULL
);

create unique index idx_visitor_uniqueness
on star.d_visitor(nk_session_id, nk_visitor_id, ip);

CREATE TABLE star.f_session (
  site_id int not null,
  company_id int not null,
  date_id int not null, -- date when the session started
  session_visitor_id int not null,
  start_time timestamp not null,  -- degenarated dimensions to have access to hour/minutes/seconds
  end_time timestamp not null,  -- degenarated dimensions to have access to hour/minutes/seconds
  duration interval not null, -- duration in seconds
  page_views_count int not null,
  created_at timestamp not null,
  FOREIGN KEY (site_id) REFERENCES star.d_site(id),
  FOREIGN KEY (company_id) REFERENCES star.d_company(id),
  FOREIGN KEY (date_id) REFERENCES star.d_date(id),
  FOREIGN KEY (session_visitor_id) REFERENCES star.d_visitor(id)
);

create index idx_site_id on star.f_session(site_id);
create index idx_date_id on star.f_session(date_id);

-- Visit Star
-- CREATE TABLE star.d_page (
--   id serial PRIMARY KEY,
--   title varchar not null,
--   url varchar unique not null,
--   created_at timestamp NOT NULL
-- );

-- CREATE TABLE star.f_visit (
--   -- TODO
-- )