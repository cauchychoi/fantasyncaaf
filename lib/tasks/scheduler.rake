require 'mysql2'
require 'time'
desc "This task is called by the Heroku scheduler add-on"

task :update_scores do
	client = Mysql2::Client.new(:host => "us-cdbr-iron-east-05.cleardb.net", :username => "b4078336a46f7e", :password => "10f5241c", :database => "heroku_28ca4c386152c4f")
	
	gameTimes = client.query("select * from gametimes")
	gameTimes.each do |game|
		utcGameTime = Time.parse(game['gametime'].strftime('%Y-%m-%d %H:%M:%S UTC'))
		if (utcGameTime..utcGameTime+(8*60*60)).cover?(Time.now.utc)
			puts "Updating scores from ESPN..."
			ruby "updateTimesPlayerUsed.rb"
			ruby "espn_scraper_main.rb #{game['week']} #{game['gameID']}" 
		end
	end
	#test
	#if (Time.now.utc..Time.now.utc+(10*60*60)).cover?(Time.now.utc+(2*60*60))
	#	puts "YAY"
	#end
	
end

task :test_update_scores do
	ruby "espn_scraper_main.rb 12 400935323"
	ruby "espn_scraper_main.rb 9 400935308"
	ruby "espn_scraper_main.rb 10 400935313"
	ruby "espn_scraper_main.rb 10 400935310"
end

task :update_leaguestandings do
	if Time.now.utc.wday == 1 && (Time.new(2020,9,6,7,0,0,"+00:00")..Time.new(2020,12,15,7,0,0,"+00:00")).cover?(Time.now.utc)
		ruby "update_leaguestandings.rb"
	end
end

# Get the next week's schedule (set to the Sunday before the week)
task :update_gametimes do
	sundayBeforeWeek1 = Time.new(2021,8,29,7,0,0,"+00:00")
	weekInSeconds = 7*24*60*60

	if (Time.now.utc > (sundayBeforeWeek1 + (15 * weekInSeconds)) && Time.now.utc < (sundayBeforeWeek1 + (16 * weekInSeconds)))
		ruby "get_schedule.rb 16 16"
	elsif (Time.now.utc > (sundayBeforeWeek1 + (14 * weekInSeconds)))
		ruby "get_schedule.rb 15 15"
	elsif (Time.now.utc > (sundayBeforeWeek1 + (13 * weekInSeconds)))
		ruby "get_schedule.rb 14 14"
	elsif (Time.now.utc > (sundayBeforeWeek1 + (12 * weekInSeconds)))
		ruby "get_schedule.rb 13 13"
	elsif (Time.now.utc > (sundayBeforeWeek1 + (11 * weekInSeconds))) 
		ruby "get_schedule.rb 12 12"
	elsif (Time.now.utc > (sundayBeforeWeek1 + (10 * weekInSeconds))) 
		ruby "get_schedule.rb 11 11"
	elsif (Time.now.utc > (sundayBeforeWeek1 + (9 * weekInSeconds))) 
		ruby "get_schedule.rb 10 10"
	elsif (Time.now.utc > (sundayBeforeWeek1 + (8 * weekInSeconds))) 
		ruby "get_schedule.rb 9 9"
	elsif (Time.now.utc > (sundayBeforeWeek1 + (7 * weekInSeconds))) 
		ruby "get_schedule.rb 8 8"
	elsif (Time.now.utc > (sundayBeforeWeek1 + (6 * weekInSeconds))) 
		ruby "get_schedule.rb 7 7"
	elsif (Time.now.utc > (sundayBeforeWeek1 + (5 * weekInSeconds))) 
		ruby "get_schedule.rb 6 6"
	elsif (Time.now.utc > (sundayBeforeWeek1 + (4 * weekInSeconds))) 
		ruby "get_schedule.rb 5 5"
	elsif (Time.now.utc > (sundayBeforeWeek1 + (3 * weekInSeconds)))
		ruby "get_schedule.rb 4 4"
	elsif (Time.now.utc > (sundayBeforeWeek1 + (2 * weekInSeconds)))
		ruby "get_schedule.rb 3 3"
	elsif (Time.now.utc > (sundayBeforeWeek1 + weekInSeconds))
		ruby "get_schedule.rb 2 2"
	elsif (Time.now.utc > sundayBeforeWeek1)
		ruby "get_schedule.rb 1 1"
	end	
end

# Refresh collegeteamroster for transfers
task :update_collegeteamroster do
	ruby "get_roster.rb"
end
