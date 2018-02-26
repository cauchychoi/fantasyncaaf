#!/usr/bin/ruby -w

require 'espn_scraper'
#require 'rubygems'
#gem 'dbi'
#require 'dbi'
require 'mysql2'

puts ESPN.responding?
#puts ESPN.get_teams_in('ncf')
#ESPN.get_ncf_scores(2017, 11)
puts ESPN.get_pac12_games(2017, 12)
#dbh = DBI.connect("DBI:Mysql:localhost:id3779293_ncaafstats", "id3779293_jcl", "jeffcauchylonny")

#client = Mysql2::Client.new(:host => "localhost", :username => "root")
#client = Mysql2::Client.new(:host => "databases.000webhost.com", :username => "id3779293_jcl", :password => "jeffcauchylonny", :database => "id3779293_ncaafstats")
#result = client.query("select * from teamRoster")
#result.each do |row|
#	puts row.class
#end
#row = dbh.select_one("SELECT VERSION()")
#puts "Server version: " + row[0]