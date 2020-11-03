To reset a season:
	truncate collegeteamroster
	truncate offensestats
	truncate defensestats
	truncate teamroster
	truncate timesplayerused
	truncate leaguestandings
	Manually modify matchupschedule
	Manually modify divisions (if necessary)
	Change get_schedule.rb to current year
	Update currentWeek in updateTimesPlayerUsed.rb
	Update currentWeek in update_leaguestandings.rb
	Update currentWeek in lib/tasks/scheduler.rake
	Comment out bonus game logic in updateTimesPlayerUsed.rb

To upload to github:
	git add . (in the context of your current folder)
	git commit -m "<commit message>"
	git push (or git push origin master)

To run the program in Heroku, go to the scheduler and run:
	bundle exec rake update_scores
	
To refresh the college football roster, run:
	ruby get_roster.rb
Currently set to Pac12 only using an IF statement to filter the teams in get_roster.rb
	
To refresh the season schedule, run:
	ruby get_schedule.rb <weekRangeStart> <weekRangeEnd>
Configurations in ESPN.get_schedule():
	Year (Current = 2018)
	Conference (Pac12 = 9)
	#week (configurable for loop)
	
To refresh league standings, run:
	ruby update_leaguestandings.rb
	
If changes are made to scores.rb:
	gem uninstall espn_scraper-1.5.1
	gem build espn_scraper.gemspec
	gem install espn_scraper-1.5.1.gem
Before pushing to github/heroku, remove espn_scraper-1.5.1.gem from the folder

For testing score scraping:
	ruby espn_scraper_main.rb <week> <gameID>

For MAC:
xcode-select --install

ruby -e "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/master/install)"
brew update
brew install rbenv
echo 'eval "$(rbenv init -)"' >> ~/.bash_profile
source ~/.bash_profile

rbenv install 2.5.6
rbenv global 2.5.6
gem install rails --no-document

brew install openssl
export LIBRARY_PATH=$LIBRARY_PATH:/usr/local/opt/openssl/lib/
bundle config --local build.mysql2 "--with-ldflags=-L/usr/local/opt/openssl/lib --with-cppflags=-I/usr/local/opt/openssl/include"

brew install postgresql

gem install bundler
bundle install
