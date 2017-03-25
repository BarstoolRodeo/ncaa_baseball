#!/usr/bin/env ruby

#needs cat_id's 2012-2016

require 'csv'

require 'nokogiri'
require 'open-uri'

year = 2017
division = 1
hand =  "rhp" #"lhp"

base_sleep = 0
sleep_increment = 3
retries = 4

ncaa_teams = CSV.open("csv/master/teams/ncaa_teams_#{year}_D#{division}.csv","r",{:col_sep => "\t", :headers => TRUE})

CSV.open("csv/ncaa_player_#{hand}_hitting_split_#{year}_D#{division}.csv","w",{:col_sep => "\t"}) do |ncaa_player_summaries|

ncaa_player_summaries << ["year","year_id","team_id","team_name","jersey_number","player_id","player_name","player_url","class_year","position","GP","GS","BA","OBP","SLG","AB","R","H","2B","3B","HR","RBI","BB","HBP","SF","SH","K","DP","SB","CS","PickedOff"]


# Base URL for relative team links

#base_url = 'http://stats.ncaa.org'
base_url = 'http://anype.com/SURF/http://stats.ncaa.org&ANYPE_SUBMIT=0'
  
sleep_time = base_sleep

ncaa_teams.each do |team|

  year = team[0]
  year_id = team[1]
  team_id = team[2]
  team_name = team[3]
  
   if year == '2017' and hand == 'lhp'
	cat_id = 10588
   elsif year == '2017' and hand == 'rhp'
	cat_id = 10581
	end
	
	

  players_xpath = '//*[@id="stat_grid"]/tbody/tr'

  teams_xpath = '//*[@id="stat_grid"]/tfoot/tr'

  stat_url = "http://stats.ncaa.org/team/#{team_id}/stats?id=#{year_id}&available_stat_id=#{cat_id}"
  #stat_url = "http://stats.ncaa.org/team/#{team_id}/stats/#{year_id}"
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
print "\n\nfinished LHP split summaries!\n\n"

ncaa_player_summaries.close

end #ncaa_player_summaries

