#!/usr/bin/ruby -w

require 'mysql2'

currentWeekNum = 1

client = Mysql2::Client.new(:host => "us-cdbr-iron-east-05.cleardb.net", :username => "b4078336a46f7e", :password => "10f5241c", :database => "heroku_28ca4c386152c4f")
puts "Connection successful"

matchupSchedules = client.query("SELECT * FROM matchupschedule WHERE week="+currentWeekNum)

matchupSchedules.each do |matchup|
	homeScore = client.query("select sum(B.fantasyPoints) from teamRoster as A left join(select playerName name,week, fantasyPoints FROM offenseStats union select teamName name,week, fantasyPoints FROM defenseStats) as B on (A.playerName = B.name and A.week = B.week) where hasPlayed = 1 and A.teamID = "+matchup["homeTeamID"]+" and A.week = "+currentWeekNum)
	awayScore = client.query("select sum(B.fantasyPoints) from teamRoster as A left join(select playerName name,week, fantasyPoints FROM offenseStats union select teamName name,week, fantasyPoints FROM defenseStats) as B on (A.playerName = B.name and A.week = B.week) where hasPlayed = 1 and A.teamID = "+matchup["awayTeamID"]+" and A.week = "+currentWeekNum)
	
	#homeScore = client.query("SELECT pointsScored FROM leaguescores WHERE week="+currentWeekNum+" AND teamID="+matchup["homeTeamID"])
	#awayScore = client.query("SELECT pointsScored FROM leaguescores WHERE week="+currentWeekNum+" AND teamID="+matchup["awayTeamID"])
	
	homeDivision = client.query("SELECT division FROM leaguestandings WHERE teamID="+matchup["homeTeamID"]
	awayDivision = client.query("SELECT division FROM leaguestandings WHERE teamID="+matchup["awayTeamID"]
	
	if homeScore > awayScore
		if homeDivision == awayDivision
			client.query("INSERT INTO leaguestandings (teamID, wins, losses, divisionWins, divisionLosses, pointsFor, pointsAgainst) VALUES('"+matchup["homeTeamID"]+"', 1, 0, 1, 0, "+homeScore+", "+awayScore+") ON DUPLICATE KEY UPDATE wins=wins+1, divisionWins=divisionWins+1, pointsFor=pointsFor+"+homeScore+", pointsAgainst=pointsAgainst+"+awayScore)
			client.query("INSERT INTO leaguestandings (teamID, wins, losses, divisionWins, divisionLosses, pointsFor, pointsAgainst) VALUES('"+matchup["awayTeamID"]+"', 0, 1, 0, 1, "+awayScore+", "+homeScore+") ON DUPLICATE KEY UPDATE losses=losses+1, divisionLosses=divisionLosses+1, pointsFor=pointsFor+"+awayScore+", pointsAgainst=pointsAgainst+"+homeScore)
		else
			client.query("INSERT INTO leaguestandings (teamID, wins, losses, pointsFor, pointsAgainst) VALUES('"+matchup["homeTeamID"]+"', 1, 0, "+homeScore+", "+awayScore+") ON DUPLICATE KEY UPDATE wins=wins+1, pointsFor=pointsFor+"+homeScore+", pointsAgainst=pointsAgainst+"+awayScore)
			client.query("INSERT INTO leaguestandings (teamID, wins, losses, pointsFor, pointsAgainst) VALUES('"+matchup["awayTeamID"]+"', 0, 1, "+awayScore+", "+homeScore+") ON DUPLICATE KEY UPDATE losses=losses+1, pointsFor=pointsFor+"+awayScore+", pointsAgainst=pointsAgainst+"+homeScore)
		end
	else
		if homeDivision == awayDivision
			client.query("INSERT INTO leaguestandings (teamID, wins, losses, divisionWins, divisionLosses, pointsFor, pointsAgainst) VALUES('"+matchup["homeTeamID"]+"', 0, 1, "+homeScore+", "+awayScore+") ON DUPLICATE KEY UPDATE losses=losses+1, divisionLosses=divisionLosses+1, pointsFor=pointsFor+"+homeScore+", pointsAgainst=pointsAgainst+"+awayScore)
			client.query("INSERT INTO leaguestandings (teamID, wins, losses, divisionWins, divisionLosses, pointsFor, pointsAgainst) VALUES('"+matchup["awayTeamID"]+"', 1, 0, "+awayScore+", "+homeScore+") ON DUPLICATE KEY UPDATE wins=wins+1, divisionWins=divisionWins+1, pointsFor=pointsFor+"+awayScore+", pointsAgainst=pointsAgainst+"+homeScore)
		else
			client.query("INSERT INTO leaguestandings (teamID, wins, losses, pointsFor, pointsAgainst) VALUES('"+matchup["homeTeamID"]+"', 0, 1, "+homeScore+", "+awayScore+") ON DUPLICATE KEY UPDATE losses=losses+1, pointsFor=pointsFor+"+homeScore+", pointsAgainst=pointsAgainst+"+awayScore)
			client.query("INSERT INTO leaguestandings (teamID, wins, losses, pointsFor, pointsAgainst) VALUES('"+matchup["awayTeamID"]+"', 1, 0, "+awayScore+", "+homeScore+") ON DUPLICATE KEY UPDATE wins=wins+1, pointsFor=pointsFor+"+awayScore+", pointsAgainst=pointsAgainst+"+homeScore)
		end
	end
end

