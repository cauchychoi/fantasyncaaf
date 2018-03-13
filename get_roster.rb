#!/usr/bin/ruby -w

require 'espn_scraper'
#require 'rubygems'
#gem 'dbi'
#require 'dbi'
require 'mysql2'

puts ESPN.responding?
#puts ESPN.get_teams_in('ncf')
#ESPN.get_ncf_scores(2017, 11)
roster = ESPN.get_All_Rosters()
#puts roster
#dbh = DBI.connect("DBI:Mysql:localhost:id3779293_ncaafstats", "id3779293_jcl", "jeffcauchylonny")

#client = Mysql2::Client.new(:host => "localhost", :username => "root")
#mysql://b4078336a46f7e:10f5241c@us-cdbr-iron-east-05.cleardb.net/heroku_28ca4c386152c4f?reconnect=true
#DB_HOST = us-cdbr-iron-east-05.cleardb.net
#DB_DATABASE = heroku_28ca4c386152c4f
#DB_USERNAME = b4078336a46f7e
#DB_PASSWORD = 10f5241c

client = Mysql2::Client.new(:host => "us-cdbr-iron-east-05.cleardb.net", :username => "b4078336a46f7e", :password => "10f5241c", :database => "heroku_28ca4c386152c4f")
puts "Connection successful"

roster.each do |player|
	teamName = player[:teamName]
	playerName = player[:playerName]
	position = player[:position]
	playerID = player[:playerID]
	if (playerName.is_a? String)
		playerName = playerName.gsub("'", %q(\\\'))
	end
	
	#DEBUG PAC 12
	if (teamName.to_s.eql?("Arizona") || teamName.to_s.eql?("Arizona State") || teamName.to_s.eql?("Washington") || teamName.to_s.eql?("Washington State") || teamName.to_s.eql?("Oregon") || teamName.to_s.eql?("Oregon State") || teamName.to_s.eql?("USC") || teamName.to_s.eql?("UCLA") || teamName.to_s.eql?("Cal") || teamName.to_s.eql?("Stanford") || teamName.to_s.eql?("Utah") || teamName.to_s.eql?("Colorado"))
	
	if (!teamName.to_s.eql?("") && !playerName.to_s.eql?("") && !position.to_s.eql?("") && !playerID.to_s.eql?("") && !position.to_s.eql?("DB") && !position.to_s.eql?("LB") && !position.to_s.eql?("G") && !position.to_s.eql?("LS") && !position.to_s.eql?("OL") && !position.to_s.eql?("DT") && !position.to_s.eql?("S") && !position.to_s.eql?("CB") && !position.to_s.eql?("P") && !position.to_s.eql?("C") && !position.to_s.eql?("DL") && !position.to_s.eql?("DE") && !position.to_s.eql?("OT") && !position.to_s.eql?("NT"))
		playerAbbr = playerName[0] + ".  " + playerName.split[1..-1].join(' ')
		
		client.query("INSERT INTO collegeTeamRoster (team, PlayerName, PlayerAbbr, position, playerID) VALUES ('#{teamName}', '#{playerName}', '#{playerAbbr}', '#{position}', '#{playerID}') ON DUPLICATE KEY UPDATE team=VALUES(team), PlayerName=VALUES(PlayerName), PlayerAbbr=VALUES(PlayerAbbr), position=VALUES(position)")
		#client.query("INSERT INTO collegeTeamRoster (team, PlayerName, position, playerID) VALUES ('#{teamName}', '#{playerName}', '#{position}', '#{playerID}') ON DUPLICATE KEY IGNORE")
		#client.query("INSERT INTO collegeTeamRoster (team, PlayerName, position, playerID) VALUES (#{player[:teamName]}, #{player[:playerName]}, #{player[:position]}, #{player[:playerID]}) ON DUPLICATE KEY UPDATE team=VALUES(team), PlayerName=VALUES(PlayerName), position=VALUES(position)")
		#client.query("INSERT INTO collegeTeamRoster (team, PlayerName, position, playerID) VALUES (#{player[:teamName]}, #{player[:playerName]}, #{player[:position]}, #{player[:playerID]}) ON DUPLICATE KEY IGNORE")
	end
	
	#DEBUG PAC 12
	end
end
