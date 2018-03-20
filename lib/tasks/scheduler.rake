require 'mysql2'
require 'time'
desc "This task is called by the Heroku scheduler add-on"

task :update_scores do
	client = Mysql2::Client.new(:host => "us-cdbr-iron-east-05.cleardb.net", :username => "b4078336a46f7e", :password => "10f5241c", :database => "heroku_28ca4c386152c4f")
	
	gameTimes = client.query("select * from gametimes")
	gameTimes.each do |game|
		utcGameTime = Time.parse(game['gametime'].strftime('%Y-%m-%d %H:%M:%S UTC'))
		if (utcGameTime..utcGameTime+(4.5*60*60)).cover?(Time.now.utc)
			puts "Updating scores from ESPN..."
			ruby "espn_scraper_main.rb"
		end
	end
	
	#test
	#if (Time.now.utc..Time.now.utc+(4.5*60*60)).cover?(Time.now.utc+(2*60*60))
	#	puts "YAY"
	#end
	
end

task :testrake do
	puts "TEST"
end