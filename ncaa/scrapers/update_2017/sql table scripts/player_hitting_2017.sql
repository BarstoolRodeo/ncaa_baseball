drop table if exists player_hitting_2017;

CREATE TABLE `test`.`player_hitting_2017`

(
`year` integer null,
`year_id` integer null,
`team_id`         integer null                 ,
`team_name`       varchar(80) null             ,
`jersey_number`   integer null               ,
`player_id`       integer null               ,
`player_name`     varchar(80) null               ,
`player_url`      varchar(255) null        ,
`class_year`      varchar(80) null            ,
`position`        varchar(80) null          ,
`GP`             integer null,
`GS`             integer null,
`G` integer null,
`BA`            integer null ,
`OBP`            integer null,
`SLG`            integer null,
`R`              integer null,
`AB`             integer null,
`H`              integer null,
`2B`             integer null,
`3B`            integer null ,
`TB` integer null,
`HR`             integer null,
`RBI`            integer null,
`BB`             integer null,
`HBP`            integer null,
`SF`             integer null,
`SH`             integer null,
`K`             integer null ,
`DP`             integer null,
`CS`            integer null ,
`PickedOff`       integer null,
`SB`            integer null
);  

LOAD DATA Local INFILE 'C:\\Users\\Lewis\\Desktop\\baseball\\csv\\ncaa_player_hit_summaries_2017_D1.csv' INTO TABLE player_hitting_2017 FIELDS TERMINATED BY '\t' LINES TERMINATED BY '\n' IGNORE 1 LINES;
