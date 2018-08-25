To run the program in Heroku, go to the scheduler and run:
	bundle exec rake update_scores
	
To refresh the college football roster, run:
	ruby get_roster.rb
Currently set to Pac12 only using an IF statement to filter the teams in get_roster.rb
	
To refresh the season schedule, run:
	ruby get_schedule.rb
Configurations in ESPN.get_schedule():
	Year (Current = 2018)
	Conference (Pac12 = 9)
	week (configurable for loop)
	
	
If changes are made to scores.rb:
	gem uninstall espn_scraper-1.5.1
	gem build espn_scraper.gemspec
	gem install espn_scraper-1.5.1.gem
Before pushing to github/heroku, remove espn_scraper-1.5.1.gem from the folder