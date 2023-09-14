#!/usr/bin/ruby -w

require 'uri'
require 'cgi'
require 'json'
require 'dbi'
#require 'nokogiri'
#require 'open-uri'

module ESPN
  SEASONS = {
    preseason: 1,
    regular_season: 2,
    postseason: 3
  }

  mlb_ignores = %w(
    florida-state u-of-south-florida georgetown fla.-southern northeastern boston-college
    miami-florida florida-intl canada hanshin yomiuri sacramento springfield corpus-christi
    round-rock carolina manatee-cc mexico cincinnati-(f) atlanta-(f) frisco toledo norfolk
    fort-myers tampa-bay-(f) nl-all-stars al-all-stars
  )

  nba_ignores = %w( west-all-stars east-all-stars )

  nhl_ignores = %w(
    hc-sparta frolunda hc-slovan ev-zug jokerit-helsinki hamburg-freezers adler-mannheim
    team-chara team-alfredsson
  )

  ncf_ignores = %w( paul-quinn san-diego-christian ferris-st notre-dame-college chaminade
    w-new-mexico n-new-mexico tx-a&m-commerce nw-oklahoma-st )

  IGNORED_TEAMS = (mlb_ignores + nhl_ignores + nba_ignores + ncf_ignores).inject({}) do |h, team|
    h.merge team => false
  end

  DATA_NAME_EXCEPTIONS = {
    'nets' => 'bkn',
    'supersonics' => 'okc',
    'hornets' => 'no',

    'marlins' => 'mia'
  }.merge(IGNORED_TEAMS)

  DATA_NAME_FIXES = {
    'nfl' => {
      'nwe' => 'ne',
      'kan' => 'kc',
      'was' => 'wsh',
      'nor' => 'no',
      'gnb' => 'gb',
      'sfo' => 'sf',
      'tam' => 'tb',
      'sdg' => 'sd'
    },
    'mlb' => {},
    'nba' => {},
    'nhl' => {},
    'ncf' => {},
    'ncb' => {}
  }

  # Example output:
  # {
  #   league: "nfl",
  #   game_date: #<Date: 2013-01-05 ((2456298j,0s,0n),+0s,2299161j)>,
  #   home_team: "sea",
  #   home_score: 48,
  #   away_team: "min",
  #   away_score: 27
  # }

  class << self

		def get_All_Rosters()
			teamIDs = Scores.get_teamIDs()
			roster = Scores.get_Roster(teamIDs)
			roster
		end
  
    def get_nfl_scores(year, week)
      markup = Scores.markup_from_year_and_week('nfl', year, week)
      scores = Scores.home_away_parse(markup)
      add_league_and_fixes(scores, 'nfl')
      scores
    end

    def get_mlb_scores(date)
      markup = Scores.markup_from_date('mlb', date)
      scores = Scores.home_away_parse(markup, date)
      scores.each { |report| report[:league] = 'mlb' }
      scores
    end

    def get_nba_scores(date)
      markup = Scores.markup_from_date('nba', date)
      scores = Scores.home_away_parse(markup)
      scores.each { |report| report[:league] = 'nba' }
      scores
    end

    def get_nhl_scores(date)
      markup = Scores.markup_from_date('nhl', date)
      scores = Scores.winner_loser_parse(markup, date)
      scores.each { |report| report[:league] = 'nhl' }
      scores
    end

    def get_ncf_scores(year, week)
      markup = Scores.markup_from_year_and_week('college-football', year, week, 80)
      scores = Scores.ncf_parse(markup)
      scores.each { |report| report[:league] = 'college-football' }
      scores
    end

    alias_method :get_college_football_scores, :get_ncf_scores

	def get_pac12_games(year, week)
	  markup = Scores.markup_from_year_week_conf('college-football', year, week, 9)
	  gameIDs = Scores.get_gameIDs(markup)
	  pac12Weekly = Scores.get_stats_boxscore(gameIDs, week)
	  pac12Weekly = Scores.get_stats_summary(gameIDs, week, pac12Weekly)
	  pac12Weekly
	end
	
	def get_pac12_game(year, week, gameID)
	  markup = Scores.markup_from_year_week_conf('college-football', year, week, 9)
	  #gameIDs = Scores.get_gameIDs(markup)
	  gameStats = Scores.get_stats_boxscore(gameID, week)
	  gameStats = Scores.get_stats_summary(gameID, week, gameStats)
	  gameStats
	end
	
	def get_mw_game(year, week, gameID)
	  markup = Scores.markup_from_year_week_conf('college-football', year, week, 17)
	  #gameIDs = Scores.get_gameIDs(markup)
	  gameStats = Scores.get_stats_boxscore(gameID, week)
	  gameStats = Scores.get_stats_summary(gameID, week, gameStats)
	  gameStats
	end
	
	def get_schedule(year, conf, week)
		seasonSchedule = []
		#for week in 1..13
			markup = Scores.markup_from_year_week_conf('college-football', year, week, conf)
			weekSchedule = Scores.get_gameTimes(markup, week)
			seasonSchedule << weekSchedule
		#end
		seasonSchedule
	end
	
    def get_ncb_scores(date, conference_id)
      markup = Scores.markup_from_date_and_conference('ncb', date, conference_id)
      scores = Scores.home_away_parse(markup, date)
      scores.each { |report| report.merge! league: 'mens-college-basketball', game_date: date }
      scores
    end

    alias_method :get_college_basketball_scores, :get_ncb_scores

    def add_league_and_fixes(scores, league)
      scores.each do |report|
        report[:league] = league
        [:home_team, :away_team].each do |sym|
          team = report[sym]
          report[sym] = DATA_NAME_FIXES[league][team] || team
        end
      end
    end
  end



  module Scores
    class << self

      # Get Markup

      def markup_from_year_and_week(league, year, week, group=nil)
        if group
          ESPN.get 'scores', league, "scoreboard/_/group/#{group}/year/#{year}/seasontype/2/week/#{week}"
        else
          ESPN.get 'scores', league, "scoreboard/_/year/#{year}/seasontype/2/week/#{week}"
        end
      end
	  
	  	def markup_from_year_week_conf(league, year, week, group)
        if group
          ESPN.get 'scores', league, "scoreboard/_/group/#{group}/year/#{year}/seasontype/2/week/#{week}"
        else
          ESPN.get 'scores', league, "scoreboard/_/year/#{year}/seasontype/2/week/#{week}"
        end
      end

      def markup_from_date(league, date)
        day = date.to_s.gsub(/[^\d]+/, '')
        ESPN.get 'scores', league, "scoreboard?date=#{ day }"
      end

      def markup_from_date_and_conference(league, date, conference_id)
        day = date.to_s.gsub(/[^\d]+/, '')
        ESPN.get league, 'scoreboard', '_', 'group', conference_id.to_s, 'date', day
      end
	  
      # parsing strategies

      def home_away_parse(doc, date=nil)
        scores = []
        games = []
        espn_regex = /window\.espn\.scoreboardData \t= (\{.*?\});/
        doc.xpath("//script").each do |script_section|
          if script_section.content =~ espn_regex
            espn_data = JSON.parse(espn_regex.match(script_section.content)[1])
            games = espn_data['events']
            break
          end
        end
        games.each do |game|
          # Game must be regular or postseason
          next unless game['season']['type'] == SEASONS[:regular_season] || game['season']['type'] == SEASONS[:postseason]

          # Game must not be suspended if it was supposed to start on the query date.
          # This prevents fetching scores for suspended games which are not yet completed.
          game_start = DateTime.parse(game['date']).to_time.utc + Time.zone_offset('EDT')
          next if date && game['competitions'][0]['wasSuspended'] && game_start.to_date == date

          score = {}
          competition = game['competitions'].first
          # Score must be final
          if competition['status']['type']['detail'] =~ /^Final/
            competition['competitors'].each do |competitor|
              if competitor['homeAway'] == 'home'
                score[:home_team] = competitor['team']['abbreviation'].downcase
                score[:home_score] = competitor['score'].to_i
              else
                score[:away_team] = competitor['team']['abbreviation'].downcase
                score[:away_score] = competitor['score'].to_i
              end
            end
            score[:game_date] = DateTime.parse(game['date'])
            scores << score
          end
        end
        scores
      end

      def ncf_parse(doc)
        scores = []
        games = []
        espn_regex = /window\.espn\.scoreboardData \t= (\{.*?\});/
        doc.xpath("//script").each do |script_section|
          if script_section.content =~ espn_regex
            espn_data = JSON.parse(espn_regex.match(script_section.content)[1])
            games = espn_data['events']
            break
          end
        end
        games.each do |game|
          score = { league: 'college-football' }
          competition = game['competitions'].first
          date = DateTime.parse(competition['startDate'])
          date = date.new_offset('-06:00')
          score[:game_date] = date.to_date
          # Score must be final
          if competition['status']['type']['detail'] =~ /^Final/
            competition['competitors'].each do |competitor|
              if competitor['homeAway'] == 'home'
                score[:home_team] = competitor['team']['id'].downcase
                score[:home_score] = competitor['score'].to_i
              else
                score[:away_team] = competitor['team']['id'].downcase
                score[:away_score] = competitor['score'].to_i
              end
            end
            scores << score
          end
        end
        scores
      end

	  	def get_teamIDs()
				teamIDs = []
				teamNames = []
				count = 0
				doc = ESPN.get 'scores', 'college-football', "teams"
				#doc.xpath("//li/h5").each do |team|
				espn_regex = /window\['__espnfitt__'\]=(\{.*?\});/
				doc.xpath("//script").each do |script_section|	
						if script_section.content =~ espn_regex
							espn_data = JSON.parse(espn_regex.match(script_section.content)[1])
							#espn_data['page']
							espn_data['page']['content']['leagueTeams']['columns'].each do |column|
								column['groups'].each do |conference|
									conference['tms'].each do |team|
										teamID = {}
										teamID[:teamID] = team['id']
										team['lk'].each do |metaData|
											if metaData['t'] == "roster"
												teamLink = metaData['u']
												teamLink = teamLink[18..-1] # get rid of /college-football/
												#puts teamLink
												teamID[:link] = teamLink
												teamIDs << teamID
											end
										end
									end
								end
							end
							#puts JSON.pretty_generate(espn_data)
							#if espn_data['l'] == "Roster"
						end
						#teamID[:teamName] = team.content
						#team.next.children.each do |info|
						#	if (info.content == "Roster")
						#		teamLink = info['href']
						#		teamLink = teamLink[5..-1] # get rid of /ncf/
						#		teamID[:link] = teamLink
						#		#puts teamLink
						#		#teamIDs << teamLink
						#		teamIDs << teamID
						#	end
						#end
						
					end
					#puts teamIDs
					#doc.xpath("//li/span").each do |team|
					#	team.children.each do |info|
					#		if (info.content == "Roster")
					#			teamLink = info['href']
					#			teamLink = teamLink[5..-1] # get rid of /ncf/
					#			teamIDs << teamLink
					#		end
					#	end
					#end
					teamIDs
				 end
	  
	  def get_gameIDs(doc)
        #scores = []
        games = []
		#uids = []
		uid = []
		count = 0
        espn_regex = /window\.espn\.scoreboardData \t= (\{.*?\});/
        doc.xpath("//script").each do |script_section|
          if script_section.content =~ espn_regex
            espn_data = JSON.parse(espn_regex.match(script_section.content)[1])
            games = espn_data['events']
            break
          end
        end
        games.each do |game|
          #uid = {}
		  uidLong = game['uid']
		  uidShort = uidLong[-9..-1]
		  uid[count] = uidShort
		  
		  
          # Score must be final
          #if competition['status']['type']['detail'] =~ /^Final/
          #  competition['competitors'].each do |competitor|
          #    if competitor['homeAway'] == 'home'
          #      score[:home_team] = competitor['team']['id'].downcase
          #      score[:home_score] = competitor['score'].to_i
          #      else
          #      score[:away_team] = competitor['team']['id'].downcase
          #      score[:away_score] = competitor['score'].to_i
          #    end
          #  end
          #  scores << score
          #end
		  #uids << uid
		  count += 1
        end
		
		uid  #returns list of game IDs
        #scores
      end
	  
	  def get_gameTimes(doc, week)
      weekSchedule = []
		  games = []
		  #espn_regex = /window\.espn\.scoreboardData \t= (\{.*?\});/  # OLD ESPN FORMAT
		  espn_regex = /window\[\'__espnfitt__\'\]=(\{.*?\});/
      doc.xpath("//script").each do |script_section|
        if script_section.content =~ espn_regex
          espn_data = JSON.parse(espn_regex.match(script_section.content)[1])
          games = espn_data['page']['content']['scoreboard']['evts']
          break
        end
      end
      games.each do |game|
		  
  		  # gameID for OLD ESPN FORMAT
  		  #uidLong = game['uid']
  		  #uidShort = uidLong[-9..-1]
  		  #uidShort = game['id']
		  
        #competition = game['competitions'].first
		  
		    dateTime = DateTime.parse(game['date'])
		    dateTime = dateTime.strftime('%Y-%m-%d %H:%M:%S') #formatting for MySQL
		  
		    teams = game['competitors']
		    teams.each do |team|
			    #displayName = team['team']['displayName']
			    #displayName.slice!(team['team']['shortDisplayName'])  #isolate school name. e.g. displayName = USC Trojans, shortDisplayName = Trojans
			    #displayName = displayName.strip
          #puts competition['status']['type']['name']
          if (team['isHome'])
          	homeAway = 'home'
          else
          	homeAway = 'away'
          end

          #if competition['status']['type']['name'] != "STATUS_CANCELED"
          if (game['status']['id'] == "1" || game['status']['id'] == "2" || game['status']['id'] == "3")  # 1 = scheduled, 2 = in progress, 3 = final
			      weekSchedule.push({:teamID => team['id'], :gameID => game['id'], :week => week, :team => team['location'], :gametime => dateTime, :homeAway => homeAway})
		      end
        end
		 
          #date = date.new_offset('-08:00') #convert from GMT to PST
          
		  
		end
		#puts weekSchedule
		weekSchedule  #returns list of game IDs
        #scores
      end
	  
	  def get_Roster(teamIDs)
	  roster = []
		teamIDs.each { |teamID|
			#puts teamID[:link]
			html = ESPN.get 'scores', 'college-football', teamID[:link]
			#html.xpath("//tr").each do |playerRow|
			espn_regex = /window\['__espnfitt__'\]=(\{.*?\});/
			html.xpath("//script").each do |script_section|
				#puts playerRow
				#statNum = 0
				if script_section.content =~ espn_regex
					espn_data = JSON.parse(espn_regex.match(script_section.content)[1])
					espn_data['page']['content']['roster']['groups'].each do |playerType|
						playerType['athletes'].each do |player|
							playerStats = {}
							playerStats[:playerName] = player['name']
							playerStats[:playerID] = player['id']
							playerStats[:position] = player['position']
							playerStats[:teamName] = player['college']
							playerStats[:teamID] = teamID[:teamID]
							roster << playerStats
							#puts playerStats
						end
					end
				end
				
#				playerStats[:teamName] = teamID[:teamName]
#				playerStats[:teamID] = teamID[:link].partition('=').last
#				#if playerRow['class'] == "oddrow" || playerRow['class'] == "evenrow"
#				if playerRow['class'] == "Table2__tr Table2__tr--sm Table2__even"
#					playerRow.children.each do |playerInfo|
#						#playerInfo.children.each do |i|
#							playerLink = playerInfo.child.child['href']
#							if playerLink =~ /id\/([^\/]+)/
#								playerStats[:playerID] = $~[1]
#							end
#						#end
#						if statNum == 1
#							playerStats[:playerName] = playerInfo.content
#						elsif statNum == 2
#							playerStats[:position] = playerInfo.content
#						end
#						statNum += 1
#					end
#				end
			end
		}
	  roster
	  end
	  
	  def get_kicker_scores(playerID, gameID)
		html = ESPN.get 'scores', 'college-football', "player/gamelog/_/id/#{playerID}"
		#puts playerID
		#puts gameID
		kickerStats = []
		getStats = 5
		html.xpath("//tr").each do |row|
			if row['class'] == "oddrow" || row['class'] == "evenrow"
				row.children.each do |tdrow|
					if (getStats < 5 && tdrow['class'] == "textright")
						#puts tdrow
						if (getStats == 0)
							kickerStats[0] = tdrow.content.partition('/').first.to_i
							getStats += 1
						elsif (getStats == 1 || getStats == 2)
							kickerStats[0] += tdrow.content.partition('/').first.to_i
							getStats += 1
						elsif (getStats == 3)
							kickerStats[1] = tdrow.content.partition('/').first.to_i
							getStats += 1
						elsif (getStats == 4)
							kickerStats[2] = tdrow.content.partition('/').first.to_i
							getStats += 1
						end
					end
					
					tdrow.children.each do |findGame| # find the right game, set getStats to 0 and only iterate through that game
						if findGame['href'].to_s.include?("#{gameID}")
							#puts findGame['href']
							#puts gameID
							getStats = 0
						end
					end
				end
			end
		end
		#puts kickerStats
		kickerStats
	  end
	  
	  def get_stats_boxscore(pages, week)
			#ESPN.get 'scores', league, "scoreboard/_/group/#{group}/year/#{year}/seasontype/2/week/#{week}"
			stats = []
		
			#REAL CODE
			pages.each { |page|
				html = ESPN.get 'scores', 'college-football', "boxscore?gameId=#{page}"
				awayTeamId = ""
				homeTeamId = ""
				
=begin old getTeamIDs					
				awayTeamIdRegex = /espn\.gamepackage\.awayTeamId = (\".*?\");/
				html.xpath("//script").each do |script_section|
					if script_section.content =~ awayTeamIdRegex
						awayTeamId = JSON.parse(awayTeamIdRegex.match(script_section.content)[1])
					end
				end
				homeTeamIdRegex = /espn\.gamepackage\.homeTeamId = (\".*?\");/
				html.xpath("//script").each do |script_section|
					if script_section.content =~ homeTeamIdRegex
						homeTeamId = JSON.parse(homeTeamIdRegex.match(script_section.content)[1])
					end
				end
=end

				# Variables for defense. team0 = away, team1 = home
				teamCount = 0
				teamNames = []
				finalScores = []
				finalScoreCount = 0
				defense = []
				team0Sacks = 0
				team1Sacks = 0
				team0DefensiveTDs = 0
				team1DefensiveTDs = 0
				team0Ints = 0
				team1Ints = 0
				team0IntYards = 0
				team1IntYards = 0
				team0KickRet = 0
				team1KickRet = 0
				team0PuntRet = 0
				team1PuntRet = 0
				team0FumRec = 0
				team1FumRec = 0
				team0YdsAllowed = 0
				team1YdsAllowed = 0
			
				#DEBUG
				#html = ESPN.get 'scores', 'college-football', "boxscore?gameId=#{pages[0]}"
				#html = ESPN.get 'scores', 'college-football', "boxscore?gameId=400935316"
			
				espn_regex = /window\['__espnfitt__'\]=(\{.*?\});/
				html.xpath("//script").each do |script_section|
					if script_section.content =~ espn_regex
						espn_data = JSON.parse(espn_regex.match(script_section.content)[1])
						
						#Get Team IDs and final scores
						espn_data['page']['content']['gamepackage']['gmStrp']['tms'].each do |teamInfo|
							if teamInfo['isHome']
								homeTeamId = teamInfo['id']
								finalScores[1] = teamInfo['score']
							elsif !teamInfo['isHome']
								awayTeamId = teamInfo['id']
								finalScores[0] = teamInfo['score']
							end
						end

						espn_data['page']['content']['gamepackage']['bxscr'].each do |team|
							teamName = team['tm']['nm']
							if team['tm']['hm']
								teamNames[1] = team['tm']['nm']
							elsif !team['tm']['hm']
								teamNames[0] = team['tm']['nm']
							end
							team['stats'].each do |teamstats|
								if teamstats['type'] == "passing"
									teamstats['athlts'].each do |player|
										stat = {}
										stat[:week] = week
										stat[:teamName] = teamName
										stat[:playerName] = player['athlt']['dspNm']
										stat[:playerID] = player['athlt']['id']
										# Passing stat order: ["completions/passingAttempts", "passingYards", "yardsPerPassAttempt", "passingTouchdowns", "interceptions", "adjQBR"]
										stat[:completedPasses] = player['stats'][0].partition('/').first
										stat[:passAttempts] = player['stats'][0].partition('/').last
										stat[:passingYards] = player['stats'][1]
										stat[:passingTDs] = player['stats'][3]
										stat[:passingInterceptions] = player['stats'][4]
										if stat != {} && (stat.has_key?(:completedPasses))
											stats << stat
		  							end
									end
								elsif teamstats['type'] == "rushing"
									if team['tm']['hm']
										team0YdsAllowed += teamstats['ttls'][1].to_i
									elsif !team['tm']['hm']
										team1YdsAllowed += teamstats['ttls'][1].to_i
									end
									teamstats['athlts'].each do |player|
										stat = {}
										stat[:week] = week
										stat[:playerName] = player['athlt']['dspNm']
										stat[:playerID] = player['athlt']['id']
										# Rushing stat order: ["rushingAttempts", "rushingYards", "yardsPerRushAttempt", "rushingTouchdowns", "longRushing"]
										stat[:rushingAttempts] = player['stats'][0]
										stat[:rushingYards] = player['stats'][1]
										stat[:rushingTDs] = player['stats'][3]
										if stat != {} && (stat.has_key?(:rushingAttempts))
											stats << stat
		  							end
									end
								elsif teamstats['type'] == "receiving"
									if team['tm']['hm']
										team0YdsAllowed += teamstats['ttls'][1].to_i
									elsif !team['tm']['hm']
										team1YdsAllowed += teamstats['ttls'][1].to_i
									end
									teamstats['athlts'].each do |player|
										stat = {}
										stat[:week] = week
										stat[:playerName] = player['athlt']['dspNm']
										stat[:playerID] = player['athlt']['id']
										# Receiving stat order: ["receptions", "receivingYards", "yardsPerReception", "receivingTouchdowns", "longReception"]
										stat[:receptions] = player['stats'][0]
										stat[:receivingYards] = player['stats'][1]
										stat[:receivingTDs] = player['stats'][3]
										if stat != {} && (stat.has_key?(:receptions))
											stats << stat
		  							end
									end
								elsif teamstats['type'] == "kicking"
									teamstats['athlts'].each do |player|
										stat = {}
										stat[:week] = week
										stat[:playerName] = player['athlt']['dspNm']
										stat[:playerID] = player['athlt']['id']
										# Kicking stat order: ["punts", "puntYards", "grossAvgPuntYards", "touchbacks", "puntsInside20", "longPunt"]
										stat[:fieldGoalAttempts] = player['stats'][0].partition('/').last
										stat[:fieldGoalsMade] = player['stats'][0].partition('/').first
										stat[:extraPointAttempts] = player['stats'][3].partition('/').last
										stat[:extraPoints] = player['stats'][3].partition('/').first
										if stat != {} && (stat.has_key?(:fieldGoalAttempts))
											stats << stat
		  							end
									end
								elsif teamstats['type'] == "fumbles"
									if team['tm']['hm']
										team1FumRec += teamstats['ttls'][2].to_i
									elsif !team['tm']['hm']
										team0FumRec += teamstats['ttls'][2].to_i
									end
									teamstats['athlts'].each do |player|
										stat = {}
										stat[:week] = week
										stat[:playerName] = player['athlt']['dspNm']
										stat[:playerID] = player['athlt']['id']
										# Fumbles stat order: ["fumbles", "fumblesLost", "fumblesRecovered"]
										stat[:fumblesLost] = player['stats'][1]
										if stat != {} && (stat.has_key?(:fumblesLost))
											stats << stat
		  							end
									end
								elsif teamstats['type'] == "defensive"
									if team['tm']['hm']
										team1Sacks += teamstats['ttls'][2].to_i
										team1DefensiveTDs += teamstats['ttls'][6].to_i
									elsif !team['tm']['hm']
										team0Sacks += teamstats['ttls'][2].to_i
										team0DefensiveTDs += teamstats['ttls'][6].to_i
									end
									if teamstats['ttls'][6].to_i > 0    # only iterate through the players if there are TDs
										teamstats['athlts'].each do |player|
											stat = {}
											stat[:week] = week
											stat[:playerName] = player['athlt']['dspNm']
											stat[:playerID] = player['athlt']['id']
											# Defensive stat order: ["totalTackles", "soloTackles", "sacks", "tacklesForLoss", "passesDefended", "hurries", "defensiveTouchdowns"]
											stat[:miscTDs] = player['stats'][6]
											if stat != {} && (stat.has_key?(:miscTDs))
												stats << stat
			  							end
										end
									end
								elsif teamstats['type'] == "interceptions"
									# Interceptions stat order: ["interceptions", "interceptionYards", "interceptionTouchdowns"]
									if team['tm']['hm']
										team1Ints += teamstats['ttls'][0].to_i
										team1IntYards += teamstats['ttls'][1].to_i
									elsif !team['tm']['hm']
										team0Ints += teamstats['ttls'][0].to_i
										team0IntYards += teamstats['ttls'][1].to_i
									end
								elsif teamstats['type'] == "kickReturns"
									# Kick returns stat order: ["kickReturns", "kickReturnYards", "yardsPerKickReturn", "longKickReturn", "kickReturnTouchdowns"]
									if team['tm']['hm']
										team1KickRet += teamstats['ttls'][1].to_i
									elsif !team['tm']['hm']
										team0KickRet += teamstats['ttls'][1].to_i
									end
								elsif teamstats['type'] == "puntReturns"
									# Kick returns stat order: ["puntReturns", "puntReturnYards", "yardsPerPuntReturn", "longPuntReturn", "puntReturnTouchdowns"]
									if team['tm']['hm']
										team1PuntRet += teamstats['ttls'][1].to_i
									elsif !team['tm']['hm']
										team0PuntRet += teamstats['ttls'][1].to_i
									end
								end
							end
						end
					end
				end
=begin old code for parsing html
		html.xpath("//tbody/tr").each do |player|
			stat = {}
			if player['class'] != "highlight"
				player.parent.parent.parent.parent.traverse{|tableNode|
					#if player.parent.parent.parent.child.child['class'] == "team-name"
					if tableNode['class'] == "team-name"
					#puts tableNode.content
					#if player.parent.parent.sibling.child.child['class'] == "table-caption"
					#temp = player.parent.parent.parent.child.child.content.split.reverse.drop(1).reverse
						temp = tableNode.content.split.reverse.drop(1).reverse
						if temp[temp.size-1].to_s == "Kick" || temp[temp.size-1].to_s == "Punt"
							temp = temp.reverse.drop(1).reverse
						end
						tempTeamName = ""
						temp.each_with_index do |concatenate,i|
							if (i == temp.size - 1)
								tempTeamName += concatenate
							else 
								tempTeamName += concatenate + " "
							end
						end
					  
						if !tempTeamName.eql?("")
							stat[:teamName] = tempTeamName
							if teamCount == 0 || (teamCount == 1 && !tempTeamName.eql?(teamNames[0]))
								
								teamNames[teamCount] = tempTeamName
								teamCount += 1
							end
						end

					#end
					
					player.children.each do |playerStat|
						#Defense team name and final score
						#if playerStat['class'] == "team-name"
						#teamNames[teamCount] = playerStat.content
						#teamCount += 1
						#puts teamNames
						if playerStat['class'] == "final-score"
							finalScores[finalScoreCount/2] = playerStat.content #not sure why /2 is needed
							finalScoreCount += 1
					   
					   
					   #Offense
						elsif playerStat['class'] == "name"
							stat[:playerName] = playerStat.content
							playerLink = playerStat.child['href']
							if playerLink =~ /id\/([^\/]+)/
								stat[:playerID] = $~[1]
							end
							playerStat.child.children.each do |findAbbr|
								if findAbbr['class'] == "abbr"
									stat[:playerAbbr] = findAbbr.content
									stat[:playerName].slice! findAbbr.content
								end
							end
							stat[:week] = week
						elsif playerStat['class'] == "c-att"
							#stat[:comp_att] = playerStat.content
							stat[:completedPasses] = playerStat.content.partition('/').first
							stat[:passAttempts] = playerStat.content.partition('/').last
						elsif playerStat['class'] == "yds" && tableNode.content.split.include?("Passing")
							stat[:passingYards] = playerStat.content
						elsif playerStat['class'] == "yds" && tableNode.content.split.include?("Rushing")
							stat[:rushingYards] = playerStat.content
							if (stat[:teamName] == teamNames[0])
								team1YdsAllowed += playerStat.content.to_i
							elsif (stat[:teamName] == teamNames[1])
								team0YdsAllowed += playerStat.content.to_i
							end
						elsif playerStat['class'] == "yds" && tableNode.content.split.include?("Receiving")
							stat[:receivingYards] = playerStat.content
							if (stat[:teamName] == teamNames[0])
								team1YdsAllowed += playerStat.content.to_i
							elsif (stat[:teamName] == teamNames[1])
								team0YdsAllowed += playerStat.content.to_i
							end
						elsif playerStat['class'] == "td" && tableNode.content.split.include?("Passing")
							stat[:passingTDs] = playerStat.content
						elsif playerStat['class'] == "td" && tableNode.content.split.include?("Rushing")
							stat[:rushingTDs] = playerStat.content
						elsif playerStat['class'] == "td" && tableNode.content.split.include?("Receiving")
							stat[:receivingTDs] = playerStat.content
						elsif playerStat['class'] == "int" && tableNode.content.split.include?("Passing")
							stat[:passingInterceptions] = playerStat.content
						elsif playerStat['class'] == "car"
							stat[:rushingAttempts] = playerStat.content
						elsif playerStat['class'] == "rec" && tableNode.content.split.include?("Receiving")
							stat[:receptions] = playerStat.content
						elsif playerStat['class'] == "lost" && tableNode.content.split.include?("Fumbles")
							stat[:fumblesLost] = playerStat.content
							if (stat[:teamName] == teamNames[0])
								team1FumRec += playerStat.content.to_i
							elsif (stat[:teamName] == teamNames[1])
								team0FumRec += playerStat.content.to_i
							end
					   
						#Defense
						#elsif playerStat['class'] == "td" && player.parent.parent.parent.child.child.content.split[1] == "Defense"
						elsif playerStat['class'] == "sacks" && (tableNode.content.split.include?("Defense") || tableNode.content.split.include?("Defensive"))
							if (stat[:teamName] == teamNames[0])
								team0Sacks += playerStat.content.to_f
							elsif (stat[:teamName] == teamNames[1])
								team1Sacks += playerStat.content.to_f
							end
						  
						elsif playerStat['class'] == "td" && (tableNode.content.split.include?("Defense") || tableNode.content.split.include?("Defensive"))
              if (stat[:teamName] == teamNames[0])
								team0DefensiveTDs += playerStat.content.to_i
							elsif (stat[:teamName] == teamNames[1])
								team1DefensiveTDs += playerStat.content.to_i
							end
							if playerStat.content.to_i != 0
								stat[:miscTDs] = playerStat.content
							end
					   
						elsif playerStat['class'] == "int" && tableNode.content.split.include?("Interceptions")
							if (stat[:teamName] == teamNames[0])
								team0Ints += playerStat.content.to_i
							elsif (stat[:teamName] == teamNames[1])
								team1Ints += playerStat.content.to_i
							end
						  
						elsif playerStat['class'] == "yds" && tableNode.content.split.include?("Interceptions")
							if (stat[:teamName] == teamNames[0])
								team0IntYards += playerStat.content.to_i
							elsif (stat[:teamName] == teamNames[1])
								team1IntYards += playerStat.content.to_i
							end				  

						elsif playerStat['class'] == "yds" && (tableNode.content.include?("Kick Returns"))
							if (stat[:teamName] == teamNames[0])
								team0KickRet += playerStat.content.to_i
							elsif (stat[:teamName] == teamNames[1])
								team1KickRet += playerStat.content.to_i
							end

						elsif playerStat['class'] == "yds" && (tableNode.content.include?("Punt Returns"))
							if (stat[:teamName] == teamNames[0])
								team0PuntRet += playerStat.content.to_i
							elsif (stat[:teamName] == teamNames[1])
								team1PuntRet += playerStat.content.to_i
							end
						  
						#Kicking
						elsif playerStat['class'] == "fg"
							#stat[:fieldgoals] = playerStat.content
							stat[:fieldGoalAttempts] = playerStat.content.partition('/').last
							stat[:fieldGoalsMade] = playerStat.content.partition('/').first
						elsif playerStat['class'] == "xp"
							stat[:extraPointAttempts] = playerStat.content.partition('/').last
							stat[:extraPoints] = playerStat.content.partition('/').first
						end
					end
				end
			}
		end
		  

		  # IF KICKER, GO TO KICKER PLAYER PAGE AND GET STATS
		  #if stat.has_key?(:fieldGoalAttempts)
			#kickerStats = get_kicker_scores(stat[:playerID], page) # returns an array of length 3 for 0-39, 40-49, 50+ yards
			#stat[:shortFGsMade] = kickerStats[0]
			#stat[:medFGsMade] = kickerStats[1]
			#stat[:longFGsMade] = kickerStats[2]
		  #end
		  
		  
		  if stat != {} && (stat.has_key?(:completedPasses) || stat.has_key?(:rushingAttempts) || stat.has_key?(:receptions) || stat.has_key?(:fieldGoalAttempts) || stat.has_key?(:fumblesLost) || stat.has_key?(:twoPointConversions) || stat.has_key?(:miscTDs))
				stats << stat
		  end
		end
=end		
		awayDefense = {:week => week, :teamID => awayTeamId, :teamName => teamNames[0], :pointsAllowed => finalScores[1], :yardsAllowed => team0YdsAllowed.to_s, :fumblesRecovered => team0FumRec.to_s, :sacks => team0Sacks.to_s, :TDs => team0DefensiveTDs.to_s, :interceptions => team0Ints.to_s, :interceptionYards => team0IntYards.to_s, :kickReturnYards => team0KickRet.to_s, :puntReturnYards => team0PuntRet.to_s}
		homeDefense = {:week => week, :teamID => homeTeamId, :teamName => teamNames[1], :pointsAllowed => finalScores[0], :yardsAllowed => team1YdsAllowed.to_s, :fumblesRecovered => team1FumRec.to_s, :sacks => team1Sacks.to_s, :TDs => team1DefensiveTDs.to_s, :interceptions => team1Ints.to_s, :interceptionYards => team1IntYards.to_s, :kickReturnYards => team1KickRet.to_s, :puntReturnYards => team1PuntRet.to_s}

		stats << awayDefense
		stats << homeDefense
		#defense.push(team0Defense)
		#defense.push(team1Defense)
		#puts teamNames
		#puts defense
		
		#REAL CODE
		}
		stats
	end
	  
	  def get_stats_summary(pages, week, stats)
		pages.each { |page|
			doc = ESPN.get 'scores', 'college-football', "game?gameId=#{page}"
			awayTeamId = ""
			homeTeamId = ""
			awayTeamDisplayName = ""
			homeTeamDisplayName = ""
			stat = {}
			
=begin old team IDs
			awayTeamIdRegex = /espn\.gamepackage\.awayTeamId = (\".*?\");/
			doc.xpath("//script").each do |script_section|
				if script_section.content =~ awayTeamIdRegex
					awayTeamId = JSON.parse(awayTeamIdRegex.match(script_section.content)[1])
				end
			end
			homeTeamIdRegex = /espn\.gamepackage\.homeTeamId = (\".*?\");/
			doc.xpath("//script").each do |script_section|
				if script_section.content =~ homeTeamIdRegex
					homeTeamId = JSON.parse(homeTeamIdRegex.match(script_section.content)[1])
				end
			end
			
			#puts awayTeamId
			#puts homeTeamId
=end
			#espn_regex = /espn\.gamepackage\.probability\.data = (\[.*?\]);/
			espn_regex = /window\['__espnfitt__'\]=(\{.*?\});/
			doc.xpath("//script").each do |script_section|
				#puts script_section
				if script_section.content =~ espn_regex
					espn_data = JSON.parse(espn_regex.match(script_section.content)[1])
					awayTeamId = espn_data['page']['content']['gamepackage']['shtChrt']['tms']['away']['id']
					awayTeamDisplayName = espn_data['page']['content']['gamepackage']['shtChrt']['tms']['away']['displayName']
					homeTeamId = espn_data['page']['content']['gamepackage']['shtChrt']['tms']['home']['id']
					homeTeamDisplayName = espn_data['page']['content']['gamepackage']['shtChrt']['tms']['home']['displayName']
					#puts espn_data.size
					#plays = espn_data[1]['play']
					
					unless espn_data.nil?
						homeSafeties = 0
						awaySafeties = 0
						homeBlockedKicks = 0
						awayBlockedKicks = 0
						home2ptReturnPAT = 0
						away2ptReturnPAT = 0
						homeSackYardage = 0
						awaySackYardage = 0
						twoPointConversions = {}
						longTouchdowns = {}
						longTouchdownsDefense = {}
						fieldGoals = {}

						espn_data['page']['content']['gamepackage']['allPlys'].each do |playGroup|
							unless playGroup['plays'].nil?
								playGroup['plays'].each do |play|
									if play['description'].to_s.downcase.include?("sack")
										tempText = play['description'].to_s.downcase
	                  sackYards = tempText[/(\w+)(?=\s*( yd| yard))/].to_i  # Get first instance of <xx> yards or yds (?= vs ?!)
	                  if playGroup['teamName'].to_s.eql?(homeTeamDisplayName)
	                  	awaySackYardage += sackYards
	                  else
	                  	homeSackYardage += sackYards
	                  end
									end
								end
							end
						end


						espn_data['page']['content']['gamepackage']['scrSumm']['scrPlayGrps'].each do |group|
						#espn_data.each do |group|
							group.each do |playStats|
								#if play[0].to_s.eql?("play")
									#puts play
									#stat = {}
									#playStats = play[1]
									#puts playStats
									#unless playStats['type'].nil?
										#if playStats['type']['id'].to_s.eql?("59")  #59 = FG Good
										if playStats['typeAbbreviation'] == "FG"
											fieldGoalString = playStats['text']
											#puts fieldGoalString
											fieldGoalHash = {}
											fieldGoalArray = []
											#fieldGoalTeamId = playStats['start']['team']['id']
											fieldGoalTeamId = playStats['teamId']
											fieldGoalHash[:link] = "team/roster/_/id/#{fieldGoalTeamId}"
											fieldGoalArray.push(fieldGoalHash)
											fieldGoalTeamRoster = get_Roster(fieldGoalArray)
											fieldGoalTeamRoster.each do |player|
												unless player[:playerName].nil?
													#playerAbbrNoWhitespace = (player[:playerName].to_s)[0] + "." + player[:playerName].to_s.split[1..-1].join(' ')
													#if fieldGoalString.delete(' ').include?(player[:playerName].to_s.delete(' ')) || fieldGoalString.delete(' ').include?(playerAbbrNoWhitespace)
													if fieldGoalString.include?(player[:playerName].to_s)
														if !fieldGoals.has_key?(player[:playerID].to_sym)  # If the player doesn't exist
															fieldGoals[player[:playerID].to_sym] = {}  # Create the key and Instantiate bonus categories
														end
														
														#if playStats['start']['yardsToEndzone'].to_i+17 <= 34  
														if fieldGoalString[/(\w+)(?=\s*( Yd| Yard| yd| yard))/].to_i <= 34  # These bonus categories must match in MySQL table
															if !fieldGoals[player[:playerID].to_sym].has_key?(:shortFGsMade)  # If the bonus category doesn't exist, insert a score of 1
																fieldGoals[player[:playerID].to_sym][:shortFGsMade] = 1
															else
																fieldGoals[player[:playerID].to_sym][:shortFGsMade] += 1
															end
														#elsif playStats['start']['yardsToEndzone'].to_i+17 <= 49
														elsif fieldGoalString[/(\w+)(?=\s*( Yd| Yard| yd| yard))/].to_i <= 49
															if !fieldGoals[player[:playerID].to_sym].has_key?(:medFGsMade)
																fieldGoals[player[:playerID].to_sym][:medFGsMade] = 1
															else
																fieldGoals[player[:playerID].to_sym][:medFGsMade] += 1
															end
														#elsif playStats['start']['yardsToEndzone'].to_i+17 <= 59
														elsif fieldGoalString[/(\w+)(?=\s*( Yd| Yard| yd| yard))/].to_i <= 59
															if !fieldGoals[player[:playerID].to_sym].has_key?(:longFGsMade)
																fieldGoals[player[:playerID].to_sym][:longFGsMade] = 1
															else
																fieldGoals[player[:playerID].to_sym][:longFGsMade] += 1
															end
														#elsif playStats['start']['yardsToEndzone'].to_i+17 >= 60
														elsif fieldGoalString[/(\w+)(?=\s*( Yd| Yard| yd| yard))/].to_i >= 60
															if !fieldGoals[player[:playerID].to_sym].has_key?(:extraLongFGsMade)
																fieldGoals[player[:playerID].to_sym][:extraLongFGsMade] = 1
															else
																fieldGoals[player[:playerID].to_sym][:extraLongFGsMade] += 1
															end
														end														
													end
												end
											end
											
										#elsif playStats['type']['id'].to_s.eql?("20")  #20 = Safety
										elsif playStats['typeAbbreviation'] == "SF"
											#puts playStats
											#safeties += 1
											#if playStats['start']['team']['id'].to_s.eql?(homeTeamId)
											if playStats['teamId'].to_s.eql?(homeTeamId)
												awaySafeties += 1 #flipped because the other team gets the points
											#elsif playStats['start']['team']['id'].to_s.eql?(awayTeamId)
											elsif playStats['teamId'].to_s.eql?(awayTeamId)
												homeSafeties += 1 #flipped because the other team gets the points
											end
=begin old sack yards										
										elsif playStats['type']['id'].to_s.eql?("7") || playStats['type']['id'].to_s.eql?("9") || playStats['type']['id'].to_s.eql?("29") #7 = Sack, 9 = Fumble Recovery (Own), 29 = Fumble Recovery (Opponent)
											if playStats['text'].to_s.downcase.include?("sack")
												tempText = playStats['text'].to_s.downcase
                        sackYards = tempText[/(\w+)(?=\s*( yd| yard))/].to_i  # Get first instance of <xx> yards or yds (?= vs ?!)
                        if playStats['start']['team']['id'].to_s.eql?(homeTeamId) 
													awaySackYardage += sackYards
												else
													homeSackYardage += sackYards
												end
											end
=end										
										
										#52 = Punt, 37 = Blocked Punt Touchdown, 67 = Passing Touchdown  68 = Rushing Touchdown, 32 = Kickoff Return TD, 34 = Punt Ret TD, 38 = Blocked FG TD, 39 = Fumble Ret TD, 36 = Interception Return TD
										#elsif (playStats['type']['id'].to_s.eql?("52") && (playStats['text'].to_s.downcase.include?("td") || playStats['text'].to_s.downcase.include?("touchdown"))) || playStats['type']['id'].to_s.eql?("37") || playStats['type']['id'].to_s.eql?("67") || playStats['type']['id'].to_s.eql?("68") || playStats['type']['id'].to_s.eql?("32") || playStats['type']['id'].to_s.eql?("34") || playStats['type']['id'].to_s.eql?("39") || playStats['type']['id'].to_s.eql?("39") || playStats['type']['id'].to_s.eql?("36")
										elsif playStats['typeAbbreviation'] == "TD"
=begin I believe the logic above should account for the sack yardage on fumble ret TD											
											# Account for potential sack yardage on fumble ret TD
											#if playStats['type']['id'].to_s.eql?("39")
												if playStats['text'].to_s.downcase.include?("sack")
													tempText = playStats['text'].to_s.downcase
                          sackYards = tempText[/(\w+)(?=\s*( yd| yard))/].to_i  # Get first instance of <xx> yards or yds (?= vs ?!)
													#if playStats['start']['team']['id'].to_s.eql?(homeTeamId)
													if playStats['teamId'].to_s.eql?(homeTeamId)
														awaySackYardage += sackYards
													else
														homeSackYardage += sackYards
													end
												end
											#end
=end
											
											patString = playStats['text'][/\(.*?\)/].to_s    #get string after TD between parentheses (should be PAT text)
											touchdownString = playStats['text'][/^([^\(])+/].to_s  #get string before the parentheses (should be TD text)
											
											if playStats['text'].include? "("	#filtering for only TDs hopefully
												#puts touchdownString
												
												if touchdownString.downcase.include?("yd") || touchdownString.downcase.include?("yard")
													tempText = touchdownString.downcase
                          touchdownYards = tempText[/(\w+)(?=\s*( yd| yard))(?!.*(\w+)(?=\s*( yd| yard)))/].to_i  # Get last instance of <xx> yards or yds (?= vs ?!)
													#puts touchdownYards
													touchdownTeamHash = {}
													touchdownTeamArray = []
													touchdownTeamId = playStats['teamId']
													#if playStats['type']['id'].to_s.eql?("67") || playStats['type']['id'].to_s.eql?("68")    # Offensive TDs
													#	touchdownTeamId = playStats['start']['team']['id']
													#else	# Defensive TDs
													#	if playStats['start']['team']['id'].to_s.eql?(homeTeamId) 
													#		touchdownTeamId = awayTeamId
													#	else
													#		touchdownTeamId = homeTeamId
													#	end
													#end
														touchdownTeamHash[:link] = "team/roster/_/id/#{touchdownTeamId}"
														touchdownTeamArray.push(touchdownTeamHash)
														touchdownTeamRoster = get_Roster(touchdownTeamArray)
														touchdownTeamRoster.each do |player|
															unless player[:playerName].nil?
																#playerAbbrNoWhitespace = (player[:playerName].to_s)[0] + "." + player[:playerName].to_s.split[1..-1].join(' ')
																#puts player[:playerName]
																#if touchdownString.delete(' ').include?(player[:playerName].to_s.delete(' ')) || touchdownString.delete(' ').include?(playerAbbrNoWhitespace)
																if touchdownString.include?(player[:playerName])
																	#puts player[:playerID]
																	if !longTouchdowns.has_key?(player[:playerID].to_sym) && touchdownYards >= 40  # If the player doesn't exist
																		longTouchdowns[player[:playerID].to_sym] = {}  # Create the key and Instantiate bonus categories
																	end
																	if touchdownYards >= 95  # These bonus categories must match in MySQL table
																		if !longTouchdowns[player[:playerID].to_sym].has_key?(:ninetyFiveYardTD)  # If the bonus category doesn't exist, insert a score of 1
																			longTouchdowns[player[:playerID].to_sym][:ninetyFiveYardTD] = 1
																		else
																			longTouchdowns[player[:playerID].to_sym][:ninetyFiveYardTD] += 1
																		end
																	elsif touchdownYards >= 80
																		if !longTouchdowns[player[:playerID].to_sym].has_key?(:eightyYardTD)
																			longTouchdowns[player[:playerID].to_sym][:eightyYardTD] = 1
																		else
																			longTouchdowns[player[:playerID].to_sym][:eightyYardTD] += 1
																		end
																	elsif touchdownYards >= 60
																		if !longTouchdowns[player[:playerID].to_sym].has_key?(:sixtyYardTD)
																			longTouchdowns[player[:playerID].to_sym][:sixtyYardTD] = 1
																		else
																			longTouchdowns[player[:playerID].to_sym][:sixtyYardTD] += 1
																		end
																	elsif touchdownYards >= 40
																		if !longTouchdowns[player[:playerID].to_sym].has_key?(:fourtyYardTD)
																			longTouchdowns[player[:playerID].to_sym][:fourtyYardTD] = 1
																		else
																			longTouchdowns[player[:playerID].to_sym][:fourtyYardTD] += 1
																		end
																	end
																	#puts longTouchdowns
																	#SPLIT HERE BASED ON touchdownYards
																end
															end
														end
													#else	# Defensive TDs
													#if !(playStats['type']['id'].to_s.eql?("67") || playStats['type']['id'].to_s.eql?("68"))    # Defensive TDs
													if playStats['text'].downcase.include?("return")   # Check for Defensive TDs
														touchdownTeamId = playStats['teamId']
														#if playStats['start']['team']['id'].to_s.eql?(homeTeamId) 
														#	touchdownTeamId = awayTeamId
														#else
														#	touchdownTeamId = homeTeamId
														#end
														
														if !longTouchdownsDefense.has_key?(touchdownTeamId.to_sym) && touchdownYards >= 40
															longTouchdownsDefense[touchdownTeamId.to_sym] = {}
														end
														if touchdownYards >= 95
															if !longTouchdownsDefense[touchdownTeamId.to_sym].has_key?(:ninetyFiveYardTD)
																longTouchdownsDefense[touchdownTeamId.to_sym][:ninetyFiveYardTD] = 1
															else
																longTouchdownsDefense[touchdownTeamId.to_sym][:ninetyFiveYardTD] += 1
															end
														elsif touchdownYards >= 80
															if !longTouchdownsDefense[touchdownTeamId.to_sym].has_key?(:eightyYardTD)
																longTouchdownsDefense[touchdownTeamId.to_sym][:eightyYardTD] = 1
															else
																longTouchdownsDefense[touchdownTeamId.to_sym][:eightyYardTD] += 1
															end
														elsif touchdownYards >= 60
															if !longTouchdownsDefense[touchdownTeamId.to_sym].has_key?(:sixtyYardTD)
																longTouchdownsDefense[touchdownTeamId.to_sym][:sixtyYardTD] = 1
															else
																longTouchdownsDefense[touchdownTeamId.to_sym][:sixtyYardTD] += 1
															end
														elsif touchdownYards >= 40
															if !longTouchdownsDefense[touchdownTeamId.to_sym].has_key?(:fourtyYardTD)
																longTouchdownsDefense[touchdownTeamId.to_sym][:fourtyYardTD] = 1
															else
																longTouchdownsDefense[touchdownTeamId.to_sym][:fourtyYardTD] += 1
															end
														end
													end											
												end
											end
											
											if patString.downcase.include?("conversion")
												conversionTeamHash = {}
												conversionTeamArray = []
												#conversionTeamId = playStats['start']['team']['id']
												conversionTeamId = playStats['teamId']
												conversionTeamHash[:link] = "team/roster/_/id/#{conversionTeamId}"
												conversionTeamArray.push(conversionTeamHash)
												conversionRoster = get_Roster(conversionTeamArray)
												#puts "patString: " + patString.delete(' ')
												conversionRoster.each do |player|   # iterate through player roster and look for either the player's full name or abbreviation in the PAT text
													#conversions = 0
													unless player[:playerName].nil?
														#playerAbbrNoWhitespace = (player[:playerName].to_s)[0] + "." + player[:playerName].to_s.split[1..-1].join(' ')
														#if patString.delete(' ').include?(player[:playerName].to_s.delete(' ')) || patString.delete(' ').include?(playerAbbrNoWhitespace)
														if patString.include?(player[:playerName])
															#stat[:week] = week
															#playerID = player[:playerID]
															#stat[:twoPointConversions]
															if !twoPointConversions.has_key?(player[:playerID].to_sym)
																twoPointConversions[player[:playerID].to_sym] = 1
															else
																twoPointConversions[player[:playerID].to_sym] += 1
															end
														end
													end
												end
											elsif patString.downcase.include?("block")  # blocked PAT
												#if playStats['start']['team']['id'].to_s.eql?(homeTeamId)
												if playStats['teamId'].to_s.eql?(homeTeamId)
													awayBlockedKicks += 1 #flipped because the other team gets the points
												#elsif playStats['start']['team']['id'].to_s.eql?(awayTeamId)
												elsif playStats['teamId'].to_s.eql?(awayTeamId)
													homeBlockedKicks += 1 #flipped because the other team gets the points
												end
											end
										# 17 = Blocked Punt, 18 = Blocked Field Goal, 37 = Blocked Punt TD, 38 = Blocked FG TD, See above for Blocked PAT
										#elsif playStats['type']['id'].to_s.eql?("17") || playStats['type']['id'].to_s.eql?("18") || playStats['type']['id'].to_s.eql?("37") || playStats['type']['id'].to_s.eql?("38")
										elsif playStats['text'].downcase.include?("block")
											#if playStats['start']['team']['id'].to_s.eql?(homeTeamId)
											if playStats['teamId'].to_s.eql?(homeTeamId)
												awayBlockedKicks += 1 #flipped because the other team gets the points
											#elsif playStats['start']['team']['id'].to_s.eql?(awayTeamId)
											elsif playStats['teamId'].to_s.eql?(awayTeamId)
												homeBlockedKicks += 1 #flipped because the other team gets the points
											end
=begin revisit defensive 2pt if it ever comes up
										elsif playStats['type']['id'].to_s.eql?("57")  #57 = defensive 2pt
											#if playStats['start']['team']['id'].to_s.eql?(homeTeamId)
											if playStats['teamId'].to_s.eql?(homeTeamId)
												away2ptReturnPAT += 1 #flipped because the other team gets the points
											#elsif playStats['start']['team']['id'].to_s.eql?(awayTeamId)
											elsif playStats['teamId'].to_s.eql?(awayTeamId)
												home2ptReturnPAT += 1 #flipped because the other team gets the points
											end
=end
										end
									#end  # unless playStats.nil?
								#end   
							end 
						end
						
						stats.push({:week => week, :teamID => awayTeamId, :safeties => awaySafeties})
						stats.push({:week => week, :teamID => homeTeamId, :safeties => homeSafeties})
						
						stats.push({:week => week, :teamID => awayTeamId, :sackYards => awaySackYardage})
						stats.push({:week => week, :teamID => homeTeamId, :sackYards => homeSackYardage})
						
						fieldGoals.each do |playerID, distanceCategories|
							distanceCategories.each do |distanceCategory, numFGs|
								stats.push({:week => week, :playerID => playerID.to_s, distanceCategory.to_sym => numFGs})
							end
						end
						
						longTouchdowns.each do |playerID, bonuses|
							bonuses.each do |bonusCategory, numBonus|
								stats.push({:week => week, :playerID => playerID.to_s, bonusCategory.to_sym => numBonus})
							end
						end
						
						longTouchdownsDefense.each do |teamID, bonuses|
							bonuses.each do |bonusCategory, numBonus|
								stats.push({:week => week, :teamID => teamID.to_s, bonusCategory.to_sym => numBonus})
							end
						end
						
						twoPointConversions.each do |playerID, numConversions|
							stats.push({:week => week, :playerID => playerID.to_s, :twoPointConversions => numConversions})
						end
						
						stats.push({:week => week, :teamID => awayTeamId, :blockedKicks => awayBlockedKicks})
						stats.push({:week => week, :teamID => homeTeamId, :blockedKicks => homeBlockedKicks})
						
						stats.push({:week => week, :teamID => awayTeamId, :returnsPAT => away2ptReturnPAT})
						stats.push({:week => week, :teamID => homeTeamId, :returnsPAT => home2ptReturnPAT})
					end  ### unless espn_data.nil?
					
					#break
				end
				#puts espn_data

			end
		}
		stats
	  end
	  
      def winner_loser_parse(doc, date)
        doc.css('.mod-scorebox-final').map do |game|
          game_info = { game_date: date }
          teams = game.css('td.team-name:not([colspan])').map { |td| parse_data_name_from(td) }
          game_info[:away_team], game_info[:home_team] = teams
          scores = game.css('.team-score').map { |td| td.at_css('span').content.to_i }
          game_info[:away_score], game_info[:home_score] = scores
          game_info
        end
      end

      # parsing helpers

      def parse_data_name_from(container)
        if container.at_css('a')
          link = container.at_css('a')['href']
          self.data_name_from(link)
        else
          if container.at_css('div')
            name = container.at_css('div text()').content
          elsif container.at_css('span')
            name = container.at_css('span text()').content
          else
            name = container.at_css('text()').content
          end
          ESPN::DATA_NAME_EXCEPTIONS[ ESPN.dasherize(name) ]
        end
      end

      def data_name_from(link)
        encoded_link = URI::encode(link.strip)
        query = URI::parse(encoded_link).query
        if query
          CGI::parse(query)['team'].first
        else
          link.split('/')[-2]
        end
      end

    end
  end
end
