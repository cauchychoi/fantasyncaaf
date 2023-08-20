To reset a season:
	truncate collegeteamroster
	truncate offensestats
	truncate defensestats
	truncate teamroster
	truncate timesplayerused
	truncate leaguestandings
	truncate gametimes
	Manually modify matchupschedule
	Manually modify divisions (if necessary)
	Change get_schedule.rb to current year
	Update tuesdayAfterWeek1 in updateTimesPlayerUsed.rb
	Update sundayAfterWeek2 in update_leaguestandings.rb
	Update sundayBeforeWeek1 in lib/tasks/scheduler.rake
	Update update_leaguestandings task date range in lib/tasks/scheduler.rake
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
	Year (Current = 2023)
	Conference (Pac12 = 9)
	#week (configurable for loop)
	
To refresh league standings, run:
	ruby update_leaguestandings.rb
	
If changes are made to scores.rb:
	gem build espn_scraper.gemspec
	gem install espn_scraper-1.5.3.gem
Before pushing to github/heroku, remove espn_scraper-1.5.3.gem from the folder

For testing score scraping:
	ruby espn_scraper_main.rb <week> <gameID>

For MAC:
git clone https://github.com/cauchychoi/fantasyncaaf

//xcode-select --install

/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
brew update
brew install rbenv
echo 'eval "$(rbenv init -)"' >> ~/.bash_profile
source ~/.bash_profile

CFLAGS="-Wno-error=implicit-function-declaration" RUBY_CONFIGURE_OPTS='--with-readline-dir=/usr/local/opt/readline/' arch -x86_64 rbenv install 2.5.6
export PATH="$HOME/.rbenv/bin:$PATH"
eval "$(rbenv init -)"
rbenv global 2.5.6
export GEM_HOME="$HOME/.gem"
gem install rails --no-document

//brew install openssl
brew install rbenv/tap/openssl@1.0
ln -sfn /usr/local/Cellar/openssl@1.0/1.0.2t /usr/local/opt/openssl
export LIBRARY_PATH=$LIBRARY_PATH:/usr/local/opt/openssl/lib/
bundle config --local build.mysql2 "--with-ldflags=-L/usr/local/opt/openssl/lib --with-cppflags=-I/usr/local/opt/openssl/include"

brew install mysql
brew install libpq
export PATH="/opt/homebrew/opt/libpq/bin:$PATH"
brew tap homebrew/core
brew install postgresql

gem install bundler
bundle install

Credentials in git:
https://docs.github.com/en/get-started/getting-started-with-git/caching-your-github-credentials-in-git

brew install git
brew tap microsoft/git
brew install --cask git-credential-manager
