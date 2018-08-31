#!/usr/bin/ruby -w

require 'mysql2'
require 'time'

currentWeek = 1
if (Time.now.utc > Time.new(2018,11,20,7,0,0,"+00:00"))
	currentWeek = 13
elsif (Time.now.utc > Time.new(2018,11,13,7,0,0,"+00:00"))
	currentWeek = 12;
elsif (Time.now.utc > Time.new(2018,11,6,7,0,0,"+00:00")) 
	currentWeek = 11;
elsif (Time.now.utc > Time.new(2018,10,30,7,0,0,"+00:00")) 
	currentWeek = 10;
elsif (Time.now.utc > Time.new(2018,10,23,7,0,0,"+00:00")) 
	currentWeek = 9;
elsif (Time.now.utc > Time.new(2018,10,16,7,0,0,"+00:00")) 
	currentWeek = 8;
elsif (Time.now.utc > Time.new(2018,10,9,7,0,0,"+00:00")) 
	currentWeek = 7;
elsif (Time.now.utc > Time.new(2018,10,2,7,0,0,"+00:00")) 
	currentWeek = 6;
elsif (Time.now.utc > Time.new(2018,9,25,7,0,0,"+00:00")) 
	currentWeek = 5;
elsif (Time.now.utc > Time.new(2018,9,18,7,0,0,"+00:00")) 
	currentWeek = 4;
elsif (Time.now.utc > Time.new(2018,9,11,7,0,0,"+00:00")) 
	currentWeek = 3;
elsif (Time.now.utc > Time.new(2018,9,4,7,0,0,"+00:00"))
	currentWeek = 2;
end

client = Mysql2::Client.new(:host => "us-cdbr-iron-east-05.cleardb.net", :username => "b4078336a46f7e", :password => "10f5241c", :database => "heroku_28ca4c386152c4f")
puts "Connection successful"

defenseProcessed = []

client.query("select distinct C.playerID, C.fantasyID, C.teamID, C.position, C.hasPlayed, D.gametime from (select A.playerName, A.fantasyID, B.playerID, B.teamID, A.position, A.hasPlayed from (select teamID as fantasyID, playerName, position, hasPlayed from teamroster where week="+currentWeek.to_s+") as A inner join collegeteamroster as B on A.playerName=B.PlayerName or A.playerName=B.team) as C inner join gameTimes as D on C.teamID=D.teamID and week="+currentWeek.to_s).each do |player|
	unless player["gametime"].nil?
		gametime = Time.parse(player['gametime'].strftime('%Y-%m-%d %H:%M:%S UTC'))
		if (Time.now.utc > gametime)
			if (player["hasPlayed"] == 0)				
				if (player["position"].eql?("DEF"))
					unless defenseProcessed.include?(player["fantasyID"])
						client.query("INSERT INTO timesplayerused (playerID, teamID, timesUsed) VALUES ("+player["teamID"].to_s+", "+player["fantasyID"].to_s+", 1) ON DUPLICATE KEY UPDATE timesUsed=timesUsed+1")
						client.query("UPDATE teamroster set hasPlayed = 1 where week = "+currentWeek.to_s+" and teamID = "+player["fantasyID"].to_s+" and position = \""+player["position"]+"\"")
						defenseProcessed.push(player["fantasyID"])
					end
				else
					client.query("INSERT INTO timesplayerused (playerID, teamID, timesUsed) VALUES ("+player["playerID"].to_s+", "+player["fantasyID"].to_s+", 1) ON DUPLICATE KEY UPDATE timesUsed=timesUsed+1")
					client.query("UPDATE teamroster set hasPlayed = 1 where week = "+currentWeek.to_s+" and teamID = "+player["fantasyID"].to_s+" and position = \""+player["position"]+"\"")
				end
			end
		end
	end
end
