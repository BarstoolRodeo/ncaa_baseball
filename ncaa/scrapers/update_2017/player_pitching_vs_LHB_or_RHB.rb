#!/usr/bin/env ruby

require 'csv'

require 'nokogiri'
require 'open-uri'

year = 2016
division = 1
hand = "rhb" #lhb

base_sleep = 0
sleep_increment = 3
retries = 4

ncaa_teams = CSV.open("csv/master/teams/ncaa_teams_#{year}_D#{division}.csv","r",{:col_sep => "\t", :headers => TRUE})

#ncaa_player_summaries = CSV.open("csv/ncaa_player_summaries.csv","w",{:col_sep => "\t"})
CSV.open("csv/ncaa_player_#{hand}_pitch_split#{year}_D#{division}.csv","w",{:col_sep => "\t"}) do |ncaa_player_summaries|


#http://stats.ncaa.org/team/roster/11540?org_id=2

# Headers for files

ncaa_player_summaries << ["year","year_id","team_id","team_name","jersey_number","player_id","player_name","player_url","class_year","position","GP","GS","App","GS","ERA","IP","H","R","ER","BB","SO","SHO","BF","OppAB","2B","3B","HR","WP","Balk","HBP","IBB","IR","IR-S","SH","SF","Pitches","GO","FO","W","L","SV","KC"]

# Base URL for relative team links

#base_url = 'http://stats.ncaa.org'
base_url = 'http://anype.com/SURF/http://stats.ncaa.org&ANYPE_SUBMIT=0'
  
sleep_time = base_sleep

ncaa_teams.each do |team|

  year = team[0]
  year_id = team[1]
  team_id = team[2]
  team_name = team[3]

  if year == '2012' and hand == 'rhb'
	split_id = 10117  and cat_id = 10083
  elsif year == '2013' and hand == 'rhb'
	split_id = 10185  and cat_id = 10121
  elsif year == '2014' and hand == 'rhb'
	split_id = 10225  and cat_id = 10461
  elsif year == '2015' and hand == 'rhb'
	split_id = 10305  and cat_id = 10781
  elsif year == '2016' and hand == 'rhb'
	split_id = 10559 and cat_id = 10947
  elsif year == '2017' and hand == 'rhb'
	split_id = 10605  and cat_id = 11001
  elsif year == '2012' and hand == 'lhb'
	split_id = 10110  and cat_id = 10083
  elsif year == '2013' and hand == 'lhb'
	split_id = 10178  and cat_id = 10121
  elsif year == '2014' and hand == 'lhb'
	split_id = 10218  and cat_id = 10461
  elsif year == '2015' and hand == 'lhb'
	split_id = 10298  and cat_id = 10781
  elsif year == '2016' and hand == 'lhb'
	split_id = 10552 and cat_id = 10947
  elsif year == '2017' and hand == 'lhb'
	split_id = 10598 and cat_id = 11001
  end

  players_xpath = '//*[@id="stat_grid"]/tbody/tr'

  teams_xpath = '//*[@id="stat_grid"]/tfoot/tr'

  #stat_url = "http://anonymouse.org/cgi-bin/anon-www.cgi/http://stats.ncaa.org/team/stats/#{year_id}?org_id=#{team_id}&year_stat_category_id=#{cat_id}"
  stat_url = "http://stats.ncaa.org/team/#{team_id}/stats?id=#{year_id}&year_stat_category_id=#{cat_id}&available_stat_id=#{split_id}"

  print "Sleep #{sleep_time} ... "
  sleep sleep_time

  found_players = 0
  missing_id = 0

  tries = 0
  begin
    doc = Nokogiri::HTML(open("#{stat_url}",'User-Agent' => 'ruby'))
  rescue
    sleep_time += sleep_increment
    print "sleep #{sleep_time} ... "
    sleep sleep_time
    tries += 1
    if (tries > retries)
      next
    else
      retry
    end
  end

  sleep_time = base_sleep

  print "#{year} #{team_name} ..."

  doc.xpath(players_xpath).each do |player|

    row = [year, year_id, team_id, team_name]
    player.xpath("td").each_with_index do |element,i|
      case i
      when 1
        player_name = element.text.strip

        link = element.search("a").first
        if (link==nil)
          missing_id += 1
          link_url = nil
          player_id = nil
          player_url = nil
        else
          link_url = link.attributes["href"].text
          parameters = link_url.split("/")[-1]

          # player_id

          player_id = parameters.split("=")[2]

          # opponent URL

          player_url = "http://stats.ncaa.org/player/index?game_sport_year_ctl_id=#{year_id}&stats_player_seq=#{player_id}"
        end

        found_players += 1
        row += [player_id, player_name, player_url]
      else
        field_string = element.text.strip

        row += [field_string]
      end
    end

    ncaa_player_summaries << row
    
  end

  print " #{found_players} players, #{missing_id} missing ID"

 
 

end
print ", #{found_summaries} team summaries\n"

ncaa_player_summaries.close
end #ncaa_player_summaries
ncaa_team_summaries.close
#end #ncaa_team_summaries
