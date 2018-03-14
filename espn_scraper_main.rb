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

def calculateScores(stats)
	stats.each do |statRow|
		score = 0
		statRow.each do |statName, statValue|
			#if statRow.has_key?(:passAttempts) || statRow.has_key?(:rushingAttempts) || statRow.has_key?(:receptions)
				if statName.to_s.eql?("passingYards")
					score += statValue.to_f/25.0
				elsif statName.to_s.eql?("passingTDs")
					score += statValue.to_f * 4
				elsif statName.to_s.eql?("passingInterceptions") || statName.to_s.eql?("fumblesLost")
					score -= statValue.to_f * 2
				elsif statName.to_s.eql?("rushingYards") || statName.to_s.eql?("receivingYards")
					score += statValue.to_f/10.0
				elsif statName.to_s.eql?("rushingTDs") || statName.to_s.eql?("receivingTDs")
					score += statValue.to_f * 6
				elsif statName.to_s.eql?("receptions") # Half PPR
					score += (statValue.to_f)*0.5
				elsif statName.to_s.eql?("fumblesLost")
					score -= statValue.to_f * 2
				
			#elsif statRow.has_key?(:fumblesRecovered)
				elsif statName.to_s.eql?("fumblesRecovered") || statName.to_s.eql?("interceptions")
					score += statValue.to_f * 2
				elsif statName.to_s.eql?("sacks")
					score += statValue.to_f * 1
				elsif statName.to_s.eql?("TDs")
					score += statValue.to_f * 6
				
			#elsif statRow.has_key?(:fieldGoalAttempts)
				elsif statName.to_s.eql?("extraPoints")
					score += statValue.to_f * 1
				end
			#end
		end
		statRow[:fantasyPoints] = score
	end
	stats
end

weeklyStats = calculateScores(weeklyStats)
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

client.query("truncate offensestats")
client.query("truncate defensestats")
client.query("truncate kickerstats")

weeklyStats.each do |statRow|
	week = statRow[:week]
	playerID = statRow[:playerID]
	teamName = statRow[:teamName]
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
	
	if (statRow.has_key?(:fieldGoalAttempts))
		tableName = "kickerStats"
	elsif (statRow.has_key?(:passAttempts) || statRow.has_key?(:rushingAttempts) || statRow.has_key?(:receptions))
		tableName = "offenseStats"
	elsif (statRow.has_key?(:fumblesRecovered))
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
				if (!insert.to_s.eql?("teamName"))
					if insert.to_s.eql?("fantasyPoints")
						if index == statNames.size - 1
							queryString += insert.to_s + "=" + insert.to_s + "+VALUES(" + insert.to_s + ")"
						else
							queryString += insert.to_s + "=" + insert.to_s + "+VALUES(" + insert.to_s + "), "
						end
					else
						if index == statNames.size - 1
							queryString += insert.to_s + "=VALUES(" + insert.to_s + ")"
						else
							queryString += insert.to_s + "=VALUES(" + insert.to_s + "), "
						end
					end
				end
			else
				if (!insert.to_s.eql?("playerID"))
					if insert.to_s.eql?("fantasyPoints")
						if index == statNames.size - 1
							queryString += insert.to_s + "=" + insert.to_s + "+VALUES(" + insert.to_s + ")"
						else
							queryString += insert.to_s + "=" + insert.to_s + "+VALUES(" + insert.to_s + "), "
						end
					else
						if index == statNames.size - 1
							queryString += insert.to_s + "=VALUES(" + insert.to_s + ")"
						else
							queryString += insert.to_s + "=VALUES(" + insert.to_s + "), "
						end
					end
				end
			end
		end
	end
	
	#puts queryString
	
	if (!week.to_s.eql?("") && !playerID.to_s.eql?("") && (tableName.eql?("offenseStats") || tableName.eql?("kickerStats")))
		client.query(queryString)
	elsif (!week.to_s.eql?("") && !teamName.to_s.eql?("") && tableName.eql?("defenseStats"))
		client.query(queryString)
	end
end



#result = client.query("select * from offenseStats")
#result.each do |row|
#	puts row
#end
#row = dbh.select_one("SELECT VERSION()")
#puts "Server version: " + row[0]