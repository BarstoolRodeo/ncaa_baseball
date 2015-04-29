#!/usr/bin/env ruby

require 'csv'

require 'nokogiri'
require 'open-uri'

year = 2015
division = 1

CSV.open("csv/ncaa_teams_#{year}_D#{division}.csv","w",{:col_sep => "\t"}) do |ncaa_teams|

# Header for team file

ncaa_teams << ["year", "year_id", "team_id", "team_name", "team_url"]

# Base URL for relative team links

base_url = 'http://stats.ncaa.org'

#for year in 2012..2014
	year_division_url = "http://anonymouse.org/cgi-bin/anon-www.cgi/http://stats.ncaa.org/team/inst_team_list?sport_code=MBA&academic_year=#{year}&division=#{division}&conf_id=-1&schedule_date="

	valid_url_substring = "team/index/" ##{year_id}?org_id="

	print "\nRetrieving division #{division} teams for #{year} ... "

	found_teams = 0

	doc = Nokogiri::HTML(open(year_division_url))

	doc.search("a").each do |link|

	  link_url = link.attributes["href"].text

	  # Valid team URLs

	  if (link_url).include?(valid_url_substring)

		# NCAA year_id

		parameters = link_url.split("/")[-1]
		year_id = parameters.split("?")[0]

		# NCAA team_id

		team_id = parameters.split("=")[1]

		# NCAA team name

		team_name = link.text()

		# NCAA team URL

		team_url = base_url+link_url

		ncaa_teams << [year, year_id, team_id, team_name, team_url]
		found_teams += 1

	  end

	  ncaa_teams.flush

	end
	
	print "found #{found_teams} teams\n\n"
#end

#ncaa_teams.close
end

