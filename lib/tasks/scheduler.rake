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
	if Time.now.utc.wday == 1 && (Time.new(2019,8,24,7,0,0,"+00:00")..Time.new(2018,11,12,7,0,0,"+00:00")).cover?(Time.now.utc)
		ruby "update_leaguestandings.rb"
	end
end
