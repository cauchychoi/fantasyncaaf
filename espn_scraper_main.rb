#!/usr/bin/ruby -w

#scheduler: bundle exec rake update_scores

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

def calculateScores(stats, client)
	scores = []

	stats.each do |statRow|
		#puts statRow
		score = 0
		fieldGoalAttempts = 0
		extraPointAttempts = 0
		statRow.each do |statName, statValue|
			if statName.to_s.eql?("passingYards")
				score += statValue.to_f * 0.04
			elsif statName.to_s.eql?("passingTDs")
				score += statValue.to_f * 6
			elsif statName.to_s.eql?("passingInterceptions") || statName.to_s.eql?("fumblesLost")
				score -= statValue.to_f * 3
			elsif statName.to_s.eql?("rushingYards") || statName.to_s.eql?("receivingYards")
				score += statValue.to_f/10.0
			elsif statName.to_s.eql?("rushingTDs") || statName.to_s.eql?("receivingTDs") || statName.to_s.eql?("miscTDs")
				score += statValue.to_f * 6
			elsif statName.to_s.eql?("receptions") # Half PPR
				score += (statValue.to_f)*0.5
				client.query("SELECT position FROM collegeteamroster WHERE playerID="+statRow[:playerID].to_s).each do |result|  
					if result["position"].to_s.eql?("TE")
						score += (statValue.to_f)*0.5 # Bump TE up to full PPR
					#else
					#	score += (statValue.to_f)*0.5
					end
				end
			elsif statName.to_s.eql?("twoPointConversions")
				score += statValue.to_f * 2
			elsif statName.to_s.eql?("fourtyYardTD")
				score += statValue.to_f
			elsif statName.to_s.eql?("sixtyYardTD")
				score += statValue.to_f * 2
			elsif statName.to_s.eql?("eightyYardTD")
				score += statValue.to_f * 4
			elsif statName.to_s.eql?("ninetyFiveYardTD")
				score += statValue.to_f * 6
				
				
			elsif statName.to_s.eql?("interceptions")
				score += statValue.to_f * 2
			elsif statName.to_s.eql?("fumblesRecovered")
				score += statValue.to_f * 3
			elsif statName.to_s.eql?("sacks")
				score += statValue.to_f
			elsif statName.to_s.eql?("sackYards")
				score += statValue.to_f / 10.0
			elsif statName.to_s.eql?("TDs") || statName.to_s.eql?("safeties")
				score += statValue.to_f * 6
			elsif statName.to_s.eql?("interceptionYards")
				score += statValue.to_f / 10.0
			elsif statName.to_s.eql?("kickReturnYards") || statName.to_s.eql?("puntReturnYards")
				score += statValue.to_f / 25.0
			#elsif statName.to_s.eql?("yardsAllowed")
			#	if statValue.to_f < 100
			#		score += 5
			#	elsif statValue.to_f < 200
			#		score += 3
			#	elsif statValue.to_f < 300
			#		score += 2
			#	elsif statValue.to_f < 350
			#		score += 0
			#	elsif statValue.to_f < 400
			#		score -= 1
			#	elsif statValue.to_f < 450
			#		score -= 3
			#	elsif statValue.to_f < 500
			#		score -= 5
			#	elsif statValue.to_f < 550
			#		score -= 6
			#	else
			#		score -= 7
			#	end
			elsif statName.to_s.eql?("pointsAllowed")
				if statValue.to_f < 1
					score += 12
				elsif statValue.to_f < 7
					score += 10
				elsif statValue.to_f < 14
					score += 8
				elsif statValue.to_f < 21
					score += 6
				elsif statValue.to_f < 28
					score += 4
				elsif statValue.to_f < 35
					score += 2
				elsif statValue.to_f < 42
					score += 0
				elsif statValue.to_f < 49
					score -= 2
				elsif statValue.to_f < 56
					score -= 4
				else
					score -= 6
				end
			elsif statName.to_s.eql?("returnsPAT") || statName.to_s.eql?("blockedKicks")
				score += statValue.to_f * 2
			elsif statName.to_s.eql?("onePtSafetiesPAT")
				score += statValue.to_f

			elsif statName.to_s.eql?("extraPointAttempts")
				extraPointAttempts = statValue.to_f
			elsif statName.to_s.eql?("extraPoints")
				score += statValue.to_f * 1
				score -= extraPointAttempts - statValue.to_f
			elsif statName.to_s.eql?("fieldGoalAttempts")
				fieldGoalAttempts = statValue.to_f
			elsif statName.to_s.eql?("fieldGoalsMade")
				score -= fieldGoalAttempts - statValue.to_f
			elsif statName.to_s.eql?("shortFGsMade")
				score += statValue.to_f * 3
			elsif statName.to_s.eql?("medFGsMade")
				score += statValue.to_f * 6
			elsif statName.to_s.eql?("longFGsMade")
				score += statValue.to_f * 9
			elsif statName.to_s.eql?("extraLongFGsMade")
				score += statValue.to_f * 15
			end
		end
		#statRow[:fantasyPoints] = score
		if statRow.has_key?(:playerID)
			if !scores.find{|player| player[:week] == statRow[:week] and player[:playerID] == statRow[:playerID]}.nil?  # if scores already has week and playerID
				scores.find{|player| player[:week] == statRow[:week] and player[:playerID] == statRow[:playerID]}[:fantasyPoints] += score
			else
				scores.push({:week => statRow[:week], :playerID => statRow[:playerID], :fantasyPoints => score})
			end
		elsif statRow.has_key?(:teamID)
			if !scores.find{|player| player[:week] == statRow[:week] and player[:teamID] == statRow[:teamID]}.nil?  # if scores already has week and teamID
				scores.find{|player| player[:week] == statRow[:week] and player[:teamID] == statRow[:teamID]}[:fantasyPoints] += score
			else
				scores.push({:week => statRow[:week], :teamID => statRow[:teamID], :fantasyPoints => score})
			end

		end
	end
	scores
end


#for i in 1..1  # week
#client.query("delete from offensestats where week=#{i}")
#client.query("delete from defensestats where week=#{i}")
#client.query("delete from kickerstats where week=#{i}")

#weeklyStats = ESPN.get_pac12_game(2018, ARGV[0], Array(ARGV[1]))  # REAL THING
weeklyStats = ESPN.get_mw_game(2018, ARGV[0], Array(ARGV[1]))  # 8/25 test
#weeklyStats = ESPN.get_pac12_games(2017, i)  # TODO: parameters should be year, week, gameID
fantasyPoints = calculateScores(weeklyStats, client)
#puts weeklyStats
#puts fantasyPoints

weeklyStats.each do |statRow|
	week = statRow[:week]
	playerID = statRow[:playerID]
	teamID = statRow[:teamID]
	#puts statRow
	queryString = ""
	statNames = []
	statValues = []
	statCount = 0

	statRow.each do |statName, statValue|
		if (statValue.is_a? String)
			statValue = statValue.gsub("'", %q(\\\'))
		end
		
		statNames[statCount] = statName
		statValues[statCount] = statValue
		statCount += 1
		
		#if (statRow.has_key?(:fieldGoalAttempts) && !statName.to_s.eql?("week") && !statName.to_s.eql?("playerID") && !week.to_s.eql?("") && !playerID.to_s.eql?(""))
		#	client.query("INSERT INTO kickerStats (week, playerID, #{statName}) VALUES(#{week}, #{playerID}, '#{statValue}') ON DUPLICATE KEY UPDATE #{statName}=VALUES(#{statName})")
		#elsif ((statRow.has_key?(:passAttempts) || statRow.has_key?(:rushingAttempts) || statRow.has_key?(:receptions)) && !statName.to_s.eql?("week") && !statName.to_s.eql?("playerID") && !week.to_s.eql?("") && !playerID.to_s.eql?(""))
		#	client.query("INSERT INTO offenseStats (week, playerID, #{statName}) VALUES(#{week}, #{playerID}, '#{statValue}') ON DUPLICATE KEY UPDATE #{statName}=VALUES(#{statName})") 
		#elsif (!statName.to_s.eql?("teamName") && !statName.to_s.eql?("week") && statRow.has_key?(:fumblesRecovered) && !week.to_s.eql?("") && !teamName.to_s.eql?(""))
		#	client.query("INSERT INTO defenseStats (week, teamName, #{statName}) VALUES(#{week}, '#{teamName}', '#{statValue}') ON DUPLICATE KEY UPDATE #{statName}=VALUES(#{statName})")
		#end
	end
	
	#if (statRow.has_key?(:fieldGoalAttempts))
	#	tableName = "kickerStats"
	if (statRow.has_key?(:passAttempts) || statRow.has_key?(:rushingAttempts) || statRow.has_key?(:receptions) || statRow.has_key?(:fumblesLost) || statRow.has_key?(:twoPointConversions) || statRow.has_key?(:fieldGoalAttempts) || statRow.has_key?(:fourtyYardTD) || statRow.has_key?(:sixtyYardTD) || statRow.has_key?(:eightyYardTD) || statRow.has_key?(:ninetyFiveYardTD) || statRow.has_key?(:miscTDs) || statRow.has_key?(:shortFGsMade) || statRow.has_key?(:medFGsMade) || statRow.has_key?(:longFGsMade) || statRow.has_key?(:extraLongFGsMade)) 
		tableName = "offenseStats"
	elsif (statRow.has_key?(:fumblesRecovered) || statRow.has_key?(:safeties) || statRow.has_key?(:blockedKicks) || statRow.has_key?(:returnsPAT) || statRow.has_key?(:sackYards))
		tableName = "defenseStats"
	end
	
	queryString = "INSERT INTO #{tableName} ("
	statNames.each_with_index do |insert, index|
		if index == statNames.size - 1
			queryString += insert.to_s + ") VALUES("
		else 
			queryString += insert.to_s + ", "
		end
	end
	
	statValues.each_with_index do |insert, index|
		if index == statValues.size - 1
			queryString += "'" + insert.to_s + "') ON DUPLICATE KEY UPDATE "
		else
			queryString += "'" + insert.to_s + "', "
		end
	end
	
	statNames.each_with_index do |insert, index|
		if (!insert.to_s.eql?("week"))
			if (tableName.eql?("defenseStats"))
				if (!insert.to_s.eql?("teamID"))
					#if insert.to_s.eql?("fantasyPoints")
					#	if index == statNames.size - 1
					#		queryString += insert.to_s + "=" + insert.to_s + "+VALUES(" + insert.to_s + ")"
					#	else
					#		queryString += insert.to_s + "=" + insert.to_s + "+VALUES(" + insert.to_s + "), "
					#	end
					#else
					
						if index == statNames.size - 1
							queryString += insert.to_s + "=VALUES(" + insert.to_s + ")"
						else
							queryString += insert.to_s + "=VALUES(" + insert.to_s + "), "
						end
					#end
				end
			else
				if (!insert.to_s.eql?("playerID"))
					#if insert.to_s.eql?("fantasyPoints")
					#	if index == statNames.size - 1
					#		queryString += insert.to_s + "=" + insert.to_s + "+VALUES(" + insert.to_s + ")"
					#	else
					#		queryString += insert.to_s + "=" + insert.to_s + "+VALUES(" + insert.to_s + "), "
					#	end
					#else
						if index == statNames.size - 1
							queryString += insert.to_s + "=VALUES(" + insert.to_s + ")"
						else
							queryString += insert.to_s + "=VALUES(" + insert.to_s + "), "
						end
					#end
				end
			end
		end
	end
	
	#puts queryString

	if (!week.to_s.eql?("") && !playerID.to_s.eql?("") && tableName.eql?("offenseStats"))
		#puts queryString
		client.query(queryString)
	elsif (!week.to_s.eql?("") && !teamID.to_s.eql?("") && tableName.eql?("defenseStats"))
		#puts queryString
		client.query(queryString)
	end
end

#Insert fantasy points - assumes order is week, playerID/teamID, fantasyPoints
offenseQuery = "INSERT INTO offensestats (week, playerID, fantasyPoints) VALUES"
defenseQuery = "INSERT INTO defensestats (week, teamID, fantasyPoints) VALUES"
offenseFirst = true
defenseFirst = true
fantasyPoints.each do |player|
	if player.has_key?(:playerID)
		if offenseFirst
			offenseQuery += "(" + player[:week].to_s + "," + player[:playerID].to_s + "," + '%.2f' % player[:fantasyPoints] + ")"
			offenseFirst = false
		else
			offenseQuery += ",(" + player[:week].to_s + "," + player[:playerID].to_s + "," + '%.2f' % player[:fantasyPoints] + ")"
		end
	elsif player.has_key?(:teamID)
		if defenseFirst
			defenseQuery += "(" + player[:week].to_s + "," + player[:teamID].to_s + "," + '%.2f' % player[:fantasyPoints] + ")"
			defenseFirst = false
		else
			defenseQuery += ",(" + player[:week].to_s + "," + player[:teamID].to_s + "," + '%.2f' % player[:fantasyPoints] + ")"
		end
	end
end
offenseQuery += " ON DUPLICATE KEY UPDATE week=VALUES(week), playerID=VALUES(playerID), fantasyPoints=VALUES(fantasyPoints)"
defenseQuery += " ON DUPLICATE KEY UPDATE week=VALUES(week), teamID=VALUES(teamID), fantasyPoints=VALUES(fantasyPoints)"

client.query(offenseQuery)
client.query(defenseQuery)

#end

#result = client.query("select * from offenseStats")
#result.each do |row|
#	puts row
#end
#row = dbh.select_one("SELECT VERSION()")
#puts "Server version: " + row[0]

