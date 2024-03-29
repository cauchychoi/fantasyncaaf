#!/usr/bin/ruby -w

require 'mysql2'

# Week is set on Sunday after games are played 
sundayAfterWeek2 = Time.new(2023,9,10,7,0,0,"+00:00")
weekInSeconds = 7*24*60*60
currentWeek = 1

if (Time.now.utc > (sundayAfterWeek2 + (14 * weekInSeconds)))  
	currentWeek = 16
elsif (Time.now.utc > (sundayAfterWeek2 + (13 * weekInSeconds)))  
	currentWeek = 15
elsif (Time.now.utc > (sundayAfterWeek2 + (12 * weekInSeconds)))  
	currentWeek = 14
elsif (Time.now.utc > (sundayAfterWeek2 + (11 * weekInSeconds)))  
	currentWeek = 13
elsif (Time.now.utc > (sundayAfterWeek2 + (10 * weekInSeconds)))  
	currentWeek = 12;
elsif (Time.now.utc > (sundayAfterWeek2 + (9 * weekInSeconds)))   
	currentWeek = 11;
elsif (Time.now.utc > (sundayAfterWeek2 + (8 * weekInSeconds)))   
	currentWeek = 10;
elsif (Time.now.utc > (sundayAfterWeek2 + (7 * weekInSeconds)))  
	currentWeek = 9;
elsif (Time.now.utc > (sundayAfterWeek2 + (6 * weekInSeconds)))   
	currentWeek = 8;
elsif (Time.now.utc > (sundayAfterWeek2 + (5 * weekInSeconds)))   
	currentWeek = 7;
elsif (Time.now.utc > (sundayAfterWeek2 + (4 * weekInSeconds)))   
	currentWeek = 6;
elsif (Time.now.utc > (sundayAfterWeek2 + (3 * weekInSeconds)))   
	currentWeek = 5;
elsif (Time.now.utc > (sundayAfterWeek2 + (2 * weekInSeconds)))  
	currentWeek = 4;
elsif (Time.now.utc > (sundayAfterWeek2 + weekInSeconds)) 
	currentWeek = 3;
elsif (Time.now.utc > sundayAfterWeek2)
	currentWeek = 2;
end

client = Mysql2::Client.new(:host => "us-cdbr-iron-east-05.cleardb.net", :username => "b4078336a46f7e", :password => "10f5241c", :database => "heroku_28ca4c386152c4f")
puts "Connection successful"

client.query("truncate leaguestandings")
matchupSchedules = client.query("SELECT * FROM matchupschedule WHERE week<="+currentWeek.to_s)

matchupSchedules.each do |matchup|
	homeScore = 0
	awayScore = 0
	homeDivision = ""
	awayDivision = ""
	
	client.query("select sum(B.fantasyPoints) as fantasyPoints from teamRoster as A left join(select playerName name,week, fantasyPoints FROM offenseStats union select teamName name,week, fantasyPoints FROM defenseStats) as B on (A.playerName = B.name and A.week = B.week) where hasPlayed = 1 and A.teamID = "+matchup["homeTeamID"].to_s+" and A.week = "+matchup["week"].to_s).each do |row|
		homeScore = row["fantasyPoints"].to_f
	end
	client.query("select sum(B.fantasyPoints) as fantasyPoints from teamRoster as A left join(select playerName name,week, fantasyPoints FROM offenseStats union select teamName name,week, fantasyPoints FROM defenseStats) as B on (A.playerName = B.name and A.week = B.week) where hasPlayed = 1 and A.teamID = "+matchup["awayTeamID"].to_s+" and A.week = "+matchup["week"].to_s).each do |row|
		awayScore = row["fantasyPoints"].to_f
	end
	
	client.query("SELECT division FROM divisions WHERE teamID="+matchup["homeTeamID"].to_s).each do |row|
		homeDivision = row["division"]
	end
	client.query("SELECT division FROM divisions WHERE teamID="+matchup["awayTeamID"].to_s).each do |row|
		awayDivision = row["division"]
	end
	
	if homeScore > awayScore
		if homeDivision == awayDivision
			client.query("INSERT INTO leaguestandings (teamID, wins, losses, divisionWins, divisionLosses, pointsFor, pointsAgainst) VALUES('"+matchup["homeTeamID"].to_s+"', 1, 0, 1, 0, "+homeScore.to_s+", "+awayScore.to_s+") ON DUPLICATE KEY UPDATE wins=wins+1, divisionWins=divisionWins+1, pointsFor=pointsFor+"+homeScore.to_s+", pointsAgainst=pointsAgainst+"+awayScore.to_s)
			client.query("INSERT INTO leaguestandings (teamID, wins, losses, divisionWins, divisionLosses, pointsFor, pointsAgainst) VALUES('"+matchup["awayTeamID"].to_s+"', 0, 1, 0, 1, "+awayScore.to_s+", "+homeScore.to_s+") ON DUPLICATE KEY UPDATE losses=losses+1, divisionLosses=divisionLosses+1, pointsFor=pointsFor+"+awayScore.to_s+", pointsAgainst=pointsAgainst+"+homeScore.to_s)
		else
			client.query("INSERT INTO leaguestandings (teamID, wins, losses, pointsFor, pointsAgainst) VALUES('"+matchup["homeTeamID"].to_s+"', 1, 0, "+homeScore.to_s+", "+awayScore.to_s+") ON DUPLICATE KEY UPDATE wins=wins+1, pointsFor=pointsFor+"+homeScore.to_s+", pointsAgainst=pointsAgainst+"+awayScore.to_s)
			client.query("INSERT INTO leaguestandings (teamID, wins, losses, pointsFor, pointsAgainst) VALUES('"+matchup["awayTeamID"].to_s+"', 0, 1, "+awayScore.to_s+", "+homeScore.to_s+") ON DUPLICATE KEY UPDATE losses=losses+1, pointsFor=pointsFor+"+awayScore.to_s+", pointsAgainst=pointsAgainst+"+homeScore.to_s)
		end
	elsif awayScore > homeScore
		if homeDivision == awayDivision
			client.query("INSERT INTO leaguestandings (teamID, wins, losses, divisionWins, divisionLosses, pointsFor, pointsAgainst) VALUES('"+matchup["homeTeamID"].to_s+"', 0, 1, 0, 1, "+homeScore.to_s+", "+awayScore.to_s+") ON DUPLICATE KEY UPDATE losses=losses+1, divisionLosses=divisionLosses+1, pointsFor=pointsFor+"+homeScore.to_s+", pointsAgainst=pointsAgainst+"+awayScore.to_s)
			client.query("INSERT INTO leaguestandings (teamID, wins, losses, divisionWins, divisionLosses, pointsFor, pointsAgainst) VALUES('"+matchup["awayTeamID"].to_s+"', 1, 0, 1, 0, "+awayScore.to_s+", "+homeScore.to_s+") ON DUPLICATE KEY UPDATE wins=wins+1, divisionWins=divisionWins+1, pointsFor=pointsFor+"+awayScore.to_s+", pointsAgainst=pointsAgainst+"+homeScore.to_s)
		else
			client.query("INSERT INTO leaguestandings (teamID, wins, losses, pointsFor, pointsAgainst) VALUES('"+matchup["homeTeamID"].to_s+"', 0, 1, "+homeScore.to_s+", "+awayScore.to_s+") ON DUPLICATE KEY UPDATE losses=losses+1, pointsFor=pointsFor+"+homeScore.to_s+", pointsAgainst=pointsAgainst+"+awayScore.to_s)
			client.query("INSERT INTO leaguestandings (teamID, wins, losses, pointsFor, pointsAgainst) VALUES('"+matchup["awayTeamID"].to_s+"', 1, 0, "+awayScore.to_s+", "+homeScore.to_s+") ON DUPLICATE KEY UPDATE wins=wins+1, pointsFor=pointsFor+"+awayScore.to_s+", pointsAgainst=pointsAgainst+"+homeScore.to_s)
		end
	end
end

