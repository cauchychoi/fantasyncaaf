#!/usr/bin/ruby -w

require 'espn_scraper'
#require 'rubygems'
#gem 'dbi'
#require 'dbi'
require 'mysql2'

puts ESPN.responding?
#puts ESPN.get_teams_in('ncf')
#ESPN.get_ncf_scores(2017, 11)
weeklyStats = ESPN.get_pac12_games(2017, 12)
puts weeklyStats
#dbh = DBI.connect("DBI:Mysql:localhost:id3779293_ncaafstats", "id3779293_jcl", "jeffcauchylonny")

#client = Mysql2::Client.new(:host => "localhost", :username => "root")
#mysql://b4078336a46f7e:10f5241c@us-cdbr-iron-east-05.cleardb.net/heroku_28ca4c386152c4f?reconnect=true
#DB_HOST = us-cdbr-iron-east-05.cleardb.net
#DB_DATABASE = heroku_28ca4c386152c4f
#DB_USERNAME = b4078336a46f7e
#DB_PASSWORD = 10f5241c

client = Mysql2::Client.new(:host => "us-cdbr-iron-east-05.cleardb.net", :username => "b4078336a46f7e", :password => "10f5241c", :database => "heroku_28ca4c386152c4f")
puts "Connection successful"

# UPDATE <table> SET column1 = value1, column2=value2 WHERE playerName=<name> AND week=<weekNum>

weeklyStats.each do |statRow|
	week = statRow[:week]
	playerID = statRow[:playerID]
	teamName = statRow[:teamName]
	#puts statRow

	statRow.each do |statName, statValue|
		if (statValue.is_a? String)
			statValue = statValue.gsub("'", %q(\\\'))
		end
				
		if (statRow.has_key?(:fieldGoalAttempts) && !statName.to_s.eql?("week") && !statName.to_s.eql?("playerID") && !week.to_s.eql?("") && !playerID.to_s.eql?(""))
			client.query("INSERT INTO kickerStats (week, playerID, #{statName}) VALUES(#{week}, #{playerID}, '#{statValue}') ON DUPLICATE KEY UPDATE #{statName}=VALUES(#{statName})")
		elsif ((statRow.has_key?(:passAttempts) || statRow.has_key?(:rushingAttempts) || statRow.has_key?(:receptions)) && !statName.to_s.eql?("week") && !statName.to_s.eql?("playerID") && !week.to_s.eql?("") && !playerID.to_s.eql?(""))
			client.query("INSERT INTO offenseStats (week, playerID, #{statName}) VALUES(#{week}, #{playerID}, '#{statValue}') ON DUPLICATE KEY UPDATE #{statName}=VALUES(#{statName})") 
		elsif (!statName.to_s.eql?("teamName") && !statName.to_s.eql?("week") && statRow.has_key?(:fumblesRecovered) && !week.to_s.eql?("") && !teamName.to_s.eql?(""))
			client.query("INSERT INTO overallDefenseStats (week, teamName, #{statName}) VALUES(#{week}, '#{teamName}', '#{statValue}') ON DUPLICATE KEY UPDATE #{statName}=VALUES(#{statName})")
		end
	end
end

#result = client.query("select * from offenseStats")
#result.each do |row|
#	puts row
#end
#row = dbh.select_one("SELECT VERSION()")
#puts "Server version: " + row[0]