require 'csv'

require 'nokogiri'
require 'open-uri'

year = 2017
division = 1

nthreads = 10

base_sleep = 0
sleep_increment = 5
retries = 9

# Base URL for relative team links

base_url = 'http://stats.ncaa.org'
#base_url = 'http://anonymouse.org/cgi-bin/anon-www.cgi/stats.ncaa.org'

member_xpath = '//*[@width="100%"]/tr'

ncaa_confs = CSV.open("csv/ncaa_conferences_#{year}_D#{division}.csv","r",{:col_sep => "\t", :headers => TRUE})
# if already created(?)
#ncaa_team_rosters = CSV.open("ncaa_team_rosters_mt.csv","w",{:col_sep => "\t"})
CSV.open("csv/ncaa_conf_members_#{year}_D#{division}.csv","w",{:col_sep => "\t"}) do |ncaa_conf_members|

# Header for conference member file

ncaa_conf_members << ["year", "division", "conf_id", "conf_name", "team_id", "team_name", "team_url"]
# Get conference IDs

confs = []
ncaa_confs.each do |conf|
  confs << conf
end

n = confs.size
fails = 0

tpt = (n.to_f/nthreads.to_f).ceil

threads = []

confs.each_slice(tpt).with_index do |confs_slice,i|

  threads << Thread.new(confs_slice) do |t_confs|

    t_confs.each_with_index do |conf,j|

      sleep_time = base_sleep

      year = conf[0]
      conf_id = conf[1]
      conf_name = conf[2]
      conf_url = conf[3]

	
#	if conf_id > 0
	      #conference_url = "http://anonymouse.org/cgi-bin/anon-www.cgi/http://stats.ncaa.org/team/roster/#{year_id}?org_id=#{team_id}"
	      conference_url = "http://stats.ncaa.org/team/inst_team_list?academic_year=#{year}&division=#{division}&sport_code=MBA&conf_id=#{conf_id}"
	      #print "\n#{conference_url}"

	      print "Sleep #{sleep_time} ... "
	      sleep sleep_time

	      found_members = 0
	      missing_id = 0

	      tries = 0
	      begin
		doc = Nokogiri::HTML(open("#{conference_url}",'User-Agent' => 'ruby'))
	      rescue
		sleep_time += sleep_increment
		print "sleep #{sleep_time} ... "
		sleep sleep_time
		tries += 1
		if (tries > retries)
		  fails += 1
		  print "**failed!**\n"
		  next
		else
		  retry
		end
	      end

	      sleep_time = base_sleep

	      print " #{year} #{conf_name} ..."

	      doc.xpath(member_xpath).each do |member|

		row = [year, division, conf_id, conf_name]
		member.xpath("td").each_with_index do |element,k|
	
		team_name = element.text.strip

		link = element.search("a").first

		link_url = link.attributes["href"].text
		parameters = link_url.split("/")[-1]

		# member_id

		team_id = link_url.split("/")[-2]

		
		# team URL

		team_url = base_url+link_url
		

		found_members += 1
		row += [team_id, team_name, team_url]

		end

		ncaa_conf_members << row
	    
	      end

	      print " #{found_members} members, #{missing_id} missing ID\n"

	    end
	#end
  end

end

threads.each(&:join)
print "\n\nfinished conferences!\n"
print "missed #{fails}!\n"
#ncaa_conf_members.close
end
