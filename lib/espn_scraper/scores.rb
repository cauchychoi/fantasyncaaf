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
	  Scores.get_stats(gameIDs, week)
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
		  #score = { league: 'college-football' }
          #competition = game['competitions'].first
          #date = DateTime.parse(competition['startDate'])
          #date = date.new_offset('-06:00')
          #score[:game_date] = date.to_date
		  
		  
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
		
		uid
        #scores
      end
	  
	  def get_stats(pages, week)
		#ESPN.get 'scores', league, "scoreboard/_/group/#{group}/year/#{year}/seasontype/2/week/#{week}"
		stats = []
		
		#REAL CODE
		#pages.each { |page|
		#html = ESPN.get 'scores', 'college-football', "boxscore?gameId=#{page}"
		
		#DEBUG
		html = ESPN.get 'scores', 'college-football', "boxscore?gameId=#{pages[0]}"
		#html = ESPN.get 'scores', 'college-football', "boxscore?gameId=400935316"
		
		html.xpath("//tbody/tr").each do |player|
		  stat = {}
		  if player['class'] != "highlight"
		    if player.parent.parent.parent.child.child['class'] == "team-name"
		    #if player.parent.parent.sibling.child.child['class'] == "table-caption"
		      stat[:teamName] = player.parent.parent.parent.child.child.content.split[0]
		    end
		  
			player.children.each do |playerStat|
			   #Offense
			   if playerStat['class'] == "name"
			      stat[:playerName] = playerStat.content
				  stat[:week] = week
			   elsif playerStat['class'] == "c-att"
				  #stat[:comp_att] = playerStat.content
				  stat[:completedPasses] = playerStat.content.partition('/').first
				  stat[:passAttempts] = playerStat.content.partition('/').last
			   elsif playerStat['class'] == "yds" && player.parent.parent.parent.child.child.content.split[1] == "Passing"
			      stat[:passingYards] = playerStat.content
			   elsif playerStat['class'] == "yds" && player.parent.parent.parent.child.child.content.split[1] == "Rushing"
			      stat[:rushingYards] = playerStat.content
			   elsif playerStat['class'] == "yds" && player.parent.parent.parent.child.child.content.split[1] == "Receiving"
				  stat[:receivingYards] = playerStat.content
			   elsif playerStat['class'] == "td" && player.parent.parent.parent.child.child.content.split[1] == "Passing"
				  stat[:passingTDs] = playerStat.content
			   elsif playerStat['class'] == "td" && player.parent.parent.parent.child.child.content.split[1] == "Rushing"
			      stat[:rushingTDs] = playerStat.content
			   elsif playerStat['class'] == "td" && player.parent.parent.parent.child.child.content.split[1] == "Receiving"
			      stat[:receivingTDs] = playerStat.content
			   elsif playerStat['class'] == "int"
				  stat[:passingInterceptions] = playerStat.content
			   elsif playerStat['class'] == "car"
				  stat[:rushingAttempts] = playerStat.content
			   elsif playerStat['class'] == "rec" && player.parent.parent.parent.child.child.content.split[1] == "Receiving"
				  stat[:receptions] = playerStat.content
			   elsif playerStat['class'] == "lost" && player.parent.parent.parent.child.child.content.split[1] == "Fumbles"
				  stat[:fumblesLost] = playerStat.content
			   
			   #Defense
			   #elsif playerStat['class'] == "td" && player.parent.parent.parent.child.child.content.split[1] == "Defense"
			     
			   
			   #Kicking
			   elsif playerStat['class'] == "fg"
			      #stat[:fieldgoals] = playerStat.content
				  stat[:fieldGoalAttempts] = playerStat.content.partition('/').last
				  stat[:fieldGoalsMade] = playerStat.content.partition('/').first
			   elsif playerStat['class'] == "xp"
			      stat[:extraPoints] = playerStat.content
			   end
			end
		  end

		  if stat != {}
			stats << stat
		  end
		end
		#REAL CODE
		#}
		puts stats
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
