select * from pbp2014_d1;

# Run Expectancy (everybody's favorite!)
drop table if exists re2014;

create table re2014 as
SELECT
	e.outs_before
	, e.base_cd_before
	, SUM(IF(e.runs_this_inn - e.inn_runs_before = 0,1,0)) AS ZERO
	, SUM(IF(e.runs_this_inn - e.inn_runs_before = 1,1,0)) AS ONES
	, SUM(IF(e.runs_this_inn - e.inn_runs_before = 2,1,0)) AS TWOS
	, SUM(IF(e.runs_this_inn - e.inn_runs_before = 3,1,0)) AS THREES
	, SUM(IF(e.runs_this_inn - e.inn_runs_before = 4,1,0)) AS FOURS
	, SUM(IF(e.runs_this_inn - e.inn_runs_before = 5,1,0)) AS FIVES
	, SUM(IF(e.runs_this_inn - e.inn_runs_before = 6,1,0)) AS SIXES
	, SUM(IF(e.runs_this_inn - e.inn_runs_before = 7,1,0)) AS SEVENS
	, SUM(IF(e.runs_this_inn - e.inn_runs_before = 8,1,0)) AS EIGHTS
	, SUM(IF(e.runs_this_inn - e.inn_runs_before = 9,1,0)) AS NINES
	, SUM(IF(e.runs_this_inn - e.inn_runs_before >= 10,1,0)) AS TENS
	, SUM(e.runs_this_inn - e.inn_runs_before) AS RUNS
	, COUNT(*) AS PA
	, AVG(e.runs_this_inn - e.inn_runs_before) AS RUN_EXP
FROM pbp2014_d1 e 
where e.bat_event_fl = 1 and outs_before < 3 AND IF(inning >= 9 AND home_bats = 1,1,0)=0
GROUP BY
	outs_before, base_cd_before;

select * from re2014;

select p.base_cd_before, p.outs_before
, r1.run_exp as RE_before, avg(r2.run_exp) as RE_after, avg(p.runs_on_play) as 'Runs on Play', avg(runs_on_play + r2.run_exp - r1.run_exp) as RE_delta
, p.event_cd, p.event_str # just for reference
from pbp2014_d1 p
inner join re2014 r1
on (r1.base_cd_before = p.base_cd_before and r1.outs_before = p.outs_before)
inner join re2014 r2
on (r2.base_cd_before = p.base_cd_after and r2.outs_before = p.outs_after)
where p.outs_before < 3 AND IF(p.inning >= 9 AND p.home_bats = 1,1,0)=0

group by base_cd_before, outs_before, event_cd;