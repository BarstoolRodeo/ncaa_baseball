#!/bin/bash

# updated again!
ruby scrapers/ncaa_teams.rb

# updated again!
ruby scrapers/ncaa_team_rosters_mt.rb

# updated again!
ruby scrapers/ncaa_hitting_summaries.rb
ruby scrapers/ncaa_pitching_summaries.rb
ruby scrapers/ncaa_fielding_summaries.rb

# updated again! (missing 2013 St. Bonaventure and 2013 Fordham)
ruby scrapers/ncaa_team_schedules_mt.rb
 
# updated!
ruby scrapers/ncaa_hit_box_scores_mt.rb
ruby scrapers/ncaa_pitch_box_scores_mt.rb
ruby scrapers/ncaa_field_box_scores_mt.rb

# updated! (events as strings ONLY)
ruby scrapers/ncaa_play_by_play_mt.rb
