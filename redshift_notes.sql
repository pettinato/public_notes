-- Status of running queries
SELECT pid,
       status,
       user_name,
       starttime,
       query
FROM stv_recents
WHERE status = 'Running'
--AND user_name = 'stephenpettinato';

user_name IN ('auername','stephenpettinato');

-- Then to kill the query,


select pg_terminate_backend( 5897 );

-- Kill all my running queries
SELECT pg_terminate_backend(pid)
FROM stv_recents
WHERE status = 'Running'
AND   user_name IN ('stephenpettinato');


-- How large is my table?
SELECT *
FROM admin.table_statistics AS ts
WHERE ts."schema" = 'ashema'
AND   ts."table" = 'atable';


-- Why did my query fail?
select top 10 * from stl_error;


-- What tables depend on ashcma.sometable ?
SELECT DISTINCT c_p.oid AS tbloid
	,n_p.nspname AS schemaname
	,c_p.relname AS NAME
	,n_c.nspname AS refbyschemaname
	,c_c.relname AS refbyname
	,c_c.oid AS viewoid
FROM pg_class c_p
JOIN pg_depend d_p ON c_p.relfilenode = d_p.refobjid
JOIN pg_depend d_c ON d_p.objid = d_c.objid
JOIN pg_class c_c ON d_c.refobjid = c_c.relfilenode
LEFT JOIN pg_namespace n_p ON c_p.relnamespace = n_p.oid
LEFT JOIN pg_namespace n_c ON c_c.relnamespace = n_c.oid
WHERE d_c.deptype = 'i'::"char"
AND c_c.relkind = 'v'::"char"
AND schemaname = 'aschema'
AND name = 'atable';

-- Base make a table
CREATE TABLE myschema.mytablename
(
  row_id INT IDENTITY(0, 1) NOT NULL,
  col1 VARCHAR(256) NOT NULL,
  col2 INT NOT NULL,
  meta_update_date_time TIMESTAMP DEFAULT getdate()
)
DISTKEY(c1)
SORTKEY(c1, c2)
;
-- let everyone query the table
GRANT SELECT ON myschema.mytablename TO Public;

-- Copy into a table from a file in s3. File muyfile.csv must have columns in order c1, c2
COPY aschema.someschema
  (c1, c2)
  FROM 's3://mybucket/myfile.csv'
  FORMAT AS CSV
  ACCESS_KEY_ID 'blarg'
  SECRET_ACCESS_KEY 'hello'
  IGNOREHEADER 1
;

-- Dump a query into an s3 file
-- https://docs.aws.amazon.com/redshift/latest/dg/t_Unloading_tables.html
-- session_token is optional
-- parallel off doesn't guarantee a single file
unload ('select * from atable')
to 's3://bucket/topdir/prefix_'
parallel off
access_key_id '<access-key-id>'
secret_access_key '<secret-access-key>'
session_token '<temporary-token>';

-- What tables and schemas are available?
SELECT table_schema, table_name
FROM information_schema.tables;

-- What external tables and schemas are available?
SELECT schemaname, tablename
FROM SVV_EXTERNAL_TABLES;

-- What tables and schemas are available? - Written as a sub query to help with extending with filters
SELECT *
FROM (
	SELECT table_schema, table_name, is_ext
	FROM (SELECT table_schema, table_name, FALSE AS is_ext FROM information_schema.tables)
	UNION (SELECT schemaname AS table_schema, tablename AS table_name, TRUE AS is_ext FROM SVV_EXTERNAL_TABLES)
)
;

-- What are my recent queries?
SELECT TOP 5 *
FROM STL_QUERY
WHERE userid = CURRENT_USER_ID
ORDER BY starttime DESC
;

-- What users are in a group?
select usename
from pg_user , pg_group
where pg_user.usesysid = ANY(pg_group.grolist) and
      pg_group.groname='<YOUR_GROUP_NAME>';

-- What permissions does a group have on a partcicular table?
     
     
-- What's the size of a table in Redshift?
SELECT "schema", "table", "size" AS size_mb, "size" / 1024 AS size_gb , tbl_rows 
FROM SVV_TABLE_INFO
WHERE "table" = 'the_tablename'
AND "schema" = 'the_schema';


-- Pull duration/GBs for queries run in the last 2 days
-- Used to find queries that are draining Redshift resources
SELECT q.query,
       q.endtime - q.starttime             AS duration,
       SUM(( bytes ) / 1024 / 1024 / 1024) AS GigaBytes,
       aborted,
       q.querytxt
FROM   stl_query q
       join svl_query_summary qs
         ON qs.query = q.query
WHERE  qs.is_diskbased = 't'
       AND q.starttime BETWEEN SYSDATE - 2 AND SYSDATE
GROUP  BY q.query,
          q.querytxt,
          duration,
          aborted
ORDER  BY gigabytes DESC
;


-- What columns are available
SELECT *
FROM information_schema.columns
;

-- Pull a recent type of query run
SELECT TOP 50 usr.usename, qry.querytxt, qry.DATABASE, qry.starttime, qry.endtime, qry.aborted
FROM STL_QUERY AS qry
LEFT OUTER JOIN SVL_USER_INFO AS usr ON qry.userid = usr.usesysid
WHERE qry.querytxt ILIKE '%create table%'
ORDER BY qry.starttime DESC
;


-- What external tables and schemas are available?
SELECT count(*)
FROM SVV_EXTERNAL_TABLES
WHERE schemaname = 'some_schema';

-- Unload to s3 using an IAM role and a temp table
CREATE TEMPORARY TABLE schema_table 
AS (
  SELECT * FROM SCHEMA.table
);

unload ('SELECT * FROM schema_table')
to 's3://BUCKET/prefix'
parallel OFF
PARQUET
iam_role 'arn:aws:iam::something:role/somethingelse'
;
