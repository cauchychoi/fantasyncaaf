#!/usr/bin/ruby -w

require 'espn_scraper'
#require 'rubygems'
#gem 'dbi'
#require 'dbi'
require 'mysql2'

puts ESPN.responding?

#client = Mysql2::Client.new(:host => "localhost", :username => "root")
#mysql://b4078336a46f7e:10f5241c@us-cdbr-iron-east-05.cleardb.net/heroku_28ca4c386152c4f?reconnect=true
#DB_HOST = us-cdbr-iron-east-05.cleardb.net
#DB_DATABASE = heroku_28ca4c386152c4f
#DB_USERNAME = b4078336a46f7e
#DB_PASSWORD = 10f5241c

client = Mysql2::Client.new(:host => "us-cdbr-iron-east-05.cleardb.net", :username => "b4078336a46f7e", :password => "10f5241c", :database => "heroku_28ca4c386152c4f")
puts "Connection successful"

for week in 5..5   # update this depending on what weeks you want
	schedule = ESPN.get_schedule(2018, 9, week)

	# Populating gametimes table
	deleteString = "DELETE FROM gametimes WHERE week=" + week.to_s
	client.query(deleteString)
	client.query("set session time_zone = \"+00:00\"")
	schedule.each do |game|
		game.each do |row|
			queryString = "INSERT INTO gametimes (teamID, gameID, week, team, gameTime, homeAway) VALUES("
			row.each_with_index do |(key,value),i|
				if i == row.size - 1
					queryString += "'" + value.to_s + "') ON DUPLICATE KEY UPDATE teamID=VALUES(teamID), gameID=VALUES(gameID), week=VALUES(week), team=VALUES(team), gameTime=VALUES(gameTime), homeAway=VALUES(homeAway)"
				else
					queryString += "'" + value.to_s + "', "
				end
			end
			client.query(queryString)
		end

	end
end
