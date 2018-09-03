#!/usr/bin/ruby -w

require 'mysql2'

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

matchupSchedules = client.query("SELECT * FROM matchupschedule WHERE week="+currentWeek.to_s)

matchupSchedules.each do |matchup|
	homeScore = 0
	awayScore = 0
	#homeDivision = ""
	#awayDivision = ""
	
	client.query("select sum(B.fantasyPoints) as fantasyPoints from teamRoster as A left join(select playerName name,week, fantasyPoints FROM offenseStats union select teamName name,week, fantasyPoints FROM defenseStats) as B on (A.playerName = B.name and A.week = B.week) where hasPlayed = 1 and A.teamID = "+matchup["homeTeamID"].to_s+" and A.week = "+currentWeek.to_s).each do |row|
		homeScore = row["fantasyPoints"].to_f
	end
	client.query("select sum(B.fantasyPoints) as fantasyPoints from teamRoster as A left join(select playerName name,week, fantasyPoints FROM offenseStats union select teamName name,week, fantasyPoints FROM defenseStats) as B on (A.playerName = B.name and A.week = B.week) where hasPlayed = 1 and A.teamID = "+matchup["awayTeamID"].to_s+" and A.week = "+currentWeek.to_s).each do |row|
		awayScore = row["fantasyPoints"].to_f
	end
	
	#client.query("SELECT division FROM leaguestandings WHERE teamID="+matchup["homeTeamID"].to_s).each do |row|
	#	homeDivision = row["division"]
	#end
	#client.query("SELECT division FROM leaguestandings WHERE teamID="+matchup["awayTeamID"].to_s).each do |row|
	#	awayDivision = row["division"]
	#end
	
	if homeScore > awayScore
		#if homeDivision == awayDivision
		#	client.query("INSERT INTO leaguestandings (teamID, wins, losses, divisionWins, divisionLosses, pointsFor, pointsAgainst) VALUES('"+matchup["homeTeamID"].to_s+"', 1, 0, 1, 0, "+homeScore.to_s+", "+awayScore.to_s+") ON DUPLICATE KEY UPDATE wins=wins+1, divisionWins=divisionWins+1, pointsFor=pointsFor+"+homeScore.to_s+", pointsAgainst=pointsAgainst+"+awayScore.to_s)
		#	client.query("INSERT INTO leaguestandings (teamID, wins, losses, divisionWins, divisionLosses, pointsFor, pointsAgainst) VALUES('"+matchup["awayTeamID"].to_s+"', 0, 1, 0, 1, "+awayScore.to_s+", "+homeScore.to_s+") ON DUPLICATE KEY UPDATE losses=losses+1, divisionLosses=divisionLosses+1, pointsFor=pointsFor+"+awayScore.to_s+", pointsAgainst=pointsAgainst+"+homeScore.to_s)
		#else
			client.query("INSERT INTO leaguestandings (teamID, wins, losses, pointsFor, pointsAgainst) VALUES('"+matchup["homeTeamID"].to_s+"', 1, 0, "+homeScore.to_s+", "+awayScore.to_s+") ON DUPLICATE KEY UPDATE wins=wins+1, pointsFor=pointsFor+"+homeScore.to_s+", pointsAgainst=pointsAgainst+"+awayScore.to_s)
			client.query("INSERT INTO leaguestandings (teamID, wins, losses, pointsFor, pointsAgainst) VALUES('"+matchup["awayTeamID"].to_s+"', 0, 1, "+awayScore.to_s+", "+homeScore.to_s+") ON DUPLICATE KEY UPDATE losses=losses+1, pointsFor=pointsFor+"+awayScore.to_s+", pointsAgainst=pointsAgainst+"+homeScore.to_s)
		#end
	else
		#if homeDivision == awayDivision
		#	client.query("INSERT INTO leaguestandings (teamID, wins, losses, divisionWins, divisionLosses, pointsFor, pointsAgainst) VALUES('"+matchup["homeTeamID"].to_s+"', 0, 1, 0, 1, "+homeScore.to_s+", "+awayScore.to_s+") ON DUPLICATE KEY UPDATE losses=losses+1, divisionLosses=divisionLosses+1, pointsFor=pointsFor+"+homeScore.to_s+", pointsAgainst=pointsAgainst+"+awayScore.to_s)
		#	client.query("INSERT INTO leaguestandings (teamID, wins, losses, divisionWins, divisionLosses, pointsFor, pointsAgainst) VALUES('"+matchup["awayTeamID"].to_s+"', 1, 0, 1, 0, "+awayScore.to_s+", "+homeScore.to_s+") ON DUPLICATE KEY UPDATE wins=wins+1, divisionWins=divisionWins+1, pointsFor=pointsFor+"+awayScore.to_s+", pointsAgainst=pointsAgainst+"+homeScore.to_s)
		#else
			client.query("INSERT INTO leaguestandings (teamID, wins, losses, pointsFor, pointsAgainst) VALUES('"+matchup["homeTeamID"].to_s+"', 0, 1, "+homeScore.to_s+", "+awayScore.to_s+") ON DUPLICATE KEY UPDATE losses=losses+1, pointsFor=pointsFor+"+homeScore.to_s+", pointsAgainst=pointsAgainst+"+awayScore.to_s)
			client.query("INSERT INTO leaguestandings (teamID, wins, losses, pointsFor, pointsAgainst) VALUES('"+matchup["awayTeamID"].to_s+"', 1, 0, "+awayScore.to_s+", "+homeScore.to_s+") ON DUPLICATE KEY UPDATE wins=wins+1, pointsFor=pointsFor+"+awayScore.to_s+", pointsAgainst=pointsAgainst+"+homeScore.to_s)
		#end
	end
end

