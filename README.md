ncaa_baseball 2017
========

Attempting updates for 2017 compatability  
BR 3/21/17

Update 3/25/17
Scrapers should be done soon.  
Started adding additional scrapers including hand splits and base state splits. 
Started tampering with parsers.  Not sure if I'm going to have to buy Matlab yet.  Attempting work-around
Need to reconfigure pre-2012 data already in SQL

-LG


This is a cloned repository from the dormant ncaa_baseball

ncaa_baseball pre 2016
========

Baseball data and data science tools for NCAA Divisions 1-3, 2012-2014.

Currently this project contains data from ~2200 team-seasons, including rosters, schedules, box scores, and a play-by-play (unparsed).  All files are in CSV form but might not play well with Excel, since fields are separated by whitespace, not commas.

Running the code yourself on Windows will require Cygwin (cygwin.com) and RubyInstaller for Windows (rubyinstaller.org).  The files should be readable in any text editor (I prefer Notepad++). 

Obviously this is nowhere near as fun as the Retrosheet database, and there is a lot of useful information still missing.  Below is a partial list of stuff I want/need to add to make these data more useful:
- Conference affiliations
- Pitcher ID and batter position in lineup
- Handedness of batter and pitcher
- Fielder IDs (low priority)
- Relational database compatibility
 
I'm also open to requests/bug reports.  You can find me on Twitter at <a href="http://www.twitter.com/Doctor_Bryan">@Doctor_Bryan</a>.

-Bryan Cole<br>
Feb. 5, 2015

Updates
-------
- Jan. 27: Initial version
- Feb. 5: First crack at parsing events into base/out state, hit type, play description, etc.
