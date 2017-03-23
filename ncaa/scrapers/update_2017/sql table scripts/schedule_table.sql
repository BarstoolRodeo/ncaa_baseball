drop table if exists schedules_2017;


create table `test`.`schedules_2017`
(
`year`                     integer null,            
`year_id`                  integer null,               
`team_id`                  integer null,               
`team_name`                varchar(80) null,                 
`game_date`                varchar(80) null,                
 `game_string`             varchar(80) null,                    
 `opponent_id`             integer null,                    
 `opponent_name`           varchar(80) null,                      
 `opponent_url`            varchar(250) null,                     
 `neutral_site`            varchar(80) null,                     
 `neutral_location`        varchar(80) null,                         
 `home_game`               varchar(80) null,                  
 `score_string`            varchar(80) null,                     
 `team_won`                varchar(80) null,                 
 `score`                   integer null,              
 `team_score`              integer null,                   
 `opponent_score`          integer null,                       
 `is_final`                varchar(80) null,                 
 `innings`                 integer null,                
 `game_id`                 integer null,                
 `game_url`                varchar(255) null
);                       
