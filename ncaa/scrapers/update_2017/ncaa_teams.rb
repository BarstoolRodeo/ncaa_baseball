#!/usr/bin/env ruby

require 'csv'

require 'rubygems'
require 'nokogiri'
require 'open-uri'

year = 2017
division = 1

CSV.open("csv/ncaa_teams_#{year}_D#{division}.csv","w",{:col_sep => "\t"}) do |ncaa_teams|
user_agent = "Mozilla/5.0 (Macintosh; Intel Mac OS X 10_7_0) AppleWebKit/535.2 (KHTML, like Gecko) Chrome/15.0.854.0 Safari/535.2"

# Header for team file

ncaa_teams << ["year", "year_id", "team_id", "team_name", "team_url"]

# Base URL for relative team links
#base_url = 'http://anonymouse.org/cgi-bin/anon-www.cgi/stats.ncaa.org'
base_url = 'http://stats.ncaa.org'

#for year in 2012..2014
#	year_division_url = "http://anonymouse.org/cgi-bin/anon-www.cgi/http://stats.ncaa.org/team/inst_team_list?sport_code=MBA&academic_year=#{year}&division=#{division}&conf_id=-1&schedule_date="
	year_division_url = "http://stats.ncaa.org/team/inst_team_list?sport_code=MBA&academic_year=#{year}&division=#{division}&conf_id=-1&schedule_date="
#	print "\n#{year_division_url}"
	
	valid_url_substring = "team/" ##{year_id}?org_id="
	invalid = "academic_year="

	print "\nRetrieving division #{division} teams for #{year} ... "

	found_teams = 0

	doc = Nokogiri::HTML(open("#{year_division_url}",'User-Agent' => 'ruby'))

	doc.search("a").each do |link|

	  link_url = link.attributes["href"].text
	  
	  unless (link_url).include?(invalid)

	  # Valid team URLs

	  if (link_url).include?(valid_url_substring) 

		# NCAA year_id

		parameters = link_url.split("/")[-1]
		year_id = parameters.split("?")[0]

		# NCAA team_id

		team_id = link_url.split("/")[2]

		# NCAA team name

		team_name = link.text()

		# NCAA team URL

		team_url = base_url+link_url
		
		

		ncaa_teams << [year, year_id, team_id, team_name, team_url]
		found_teams += 1
		
		
		
		

	  end

	  ncaa_teams.flush

	end
	
	
#end

#ncaa_teams.close
end
	print "found #{found_teams} teams\n\n"
end
