# Step 1: Make that table and populate it
drop table if exists pbp2014_d1;

CREATE TABLE `ncaa_baseball`.`pbp2014_d1`
(
	`unique_id` Integer primary key,
	`year_id` Integer null,
	`div_id` Integer null,
	`game_id` Integer null,
	`inning` Integer null,
	`home_bats` Integer null,
	`event_seq` Integer null,
	`road_text` Varchar(455) null,
	`road_score` Integer null,
	`home_score` Integer null,
	`home_text` Varchar(455) null,
	`bat_name` Varchar(80) null,
	`run1_name` Varchar(80) null,
	`run2_name` Varchar(80) null,
	`run3_name` Varchar(80) null,
	`sub_in` Varchar(255) null,
	`sub_pos` Integer null,
	`sub_out` Varchar(255) null,
	`base_cd_before` Integer null,
	`outs_before` Integer null,
	`event_str` Varchar(99) null,
	`balls` Integer null,
	`strikes` Integer null,
	`pitch_str` Varchar(25) null,
	`base_cd_after` Integer null,
	`outs_after` Integer null,
	`rbi` Integer null,
	`uer` Integer null,
	`tm_uer` Integer null,
	`ab_fl` Integer null,
	`pa_fl` Integer null,
	`bat_event_fl` Integer null,
	`bip_fl` Integer null,
	`event_cd` Integer null,
	`hit_cd` Integer null,
	`hit_type` Varchar(5) null,
	`hit_loc` Varchar(12) null,
	`bunt_fl` Integer null,
	`sf_fl` Integer null,
	`sh_fl` Integer null,
	`sb_fl` Integer null,
	`cs_fl` Integer null,
	`pk_fl` Integer null,
	`asst1` Integer null,
	`asst2` Integer null,
	`asst3` Integer null,
	`asst4` Integer null,
	`asst5` Integer null,
	`asst6` Integer null,
	`putout1` Integer null,
	`putout2` Integer null,
	`putout3` Integer null,
	`error1` Integer null,
	`error2` Integer null,
	`error3` Integer null,
	`err1_type` Varchar(5) null,
	`err2_type` Varchar(5) null,
	`err3_type` Varchar(5) null,
	`inn_st_fl` Integer null,
	`inn_end_fl` Integer null,
	`inn_runs_before` Integer null,
	`runs_on_play` Integer null,
	`runs_this_inn` Integer null
);

# THIS WILL OBVIOUSLY NEED TO BE CHANGED TO MATCH YOUR DIRECTORY STRUCTURE!
LOAD DATA INFILE 'C:\\Retrosheet\\ncaa\\events_2014_D1.dat' INTO TABLE pbp2014_d1 FIELDS TERMINATED BY '\t' LINES TERMINATED BY '\n' IGNORE 1 LINES;

# oooh, ahhhh
SELECT * FROM pbp2014_d1;

# As an added bonus (because an 800K+ database isn't enough), free simple analytics!
# Stolen Base Percentage (even with the increased run environment, breakeven is 
# 	still around 75%
create table sb_pct_2014 as
select year_id, outs_before, base_cd_before
, sum(if(event_cd = 4,1,0)) as SB
, sum(if(event_cd = 6,1,0)) as CS
, sum(if(event_cd = 8,1,0)) as PK
, sum(if(event_cd = 4,1,0))/(sum(if(event_cd = 4,1,0))+sum(if(event_cd = 6,1,0))+sum(if(event_cd = 8,1,0))) as SB_rate
from pbp2014_d1 where base_cd_before = 1 and outs_before < 3
group by outs_before;

# Run Expectancy (everybody's favorite!)
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
where e.bat_event_fl = 1
GROUP BY
	outs_before, base_cd_before;

# BABIP (higher than MLB because of metal bats, worse fielders, worse pitchers)
create table ncaa_babip as 
select year_id, outs_before, base_cd_before,
sum(if(event_cd between 20 and 23,1,0)) as H,
sum(if(event_cd = 23,1,0)) as HR,
sum(if(event_cd = 18,1,0)) as ROE,
sum(if(ab_fl = 1,1,0)) as AB,
sum(if(event_cd = 3,1,0)) as K,
sum(if(sf_fl = 1,1,0)) as SF
from pbp2014_d1 where outs_before < 3
group by outs_before, base_cd_before;

create table ncaa_babip2 as 
select year_id, outs_before, base_cd_before, AB, H, ROE, HR, K, SF
, round((H-HR)/(AB-HR-K+SF),3) as BABIP
, round((H+ROE-HR)/(AB-HR-K+SF),3) as rBIP
from ncaa_babip;

select * from ncaa_babip2;
