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
#mysql://b4078336a46f7e:10f5241c@us-cdbr-iron-east-05.cleardb.net/heroku_28ca4c386152c4f?reconnect=true
#DB_HOST = us-cdbr-iron-east-05.cleardb.net
#DB_DATABASE = heroku_28ca4c386152c4f
#DB_USERNAME = b4078336a46f7e
#DB_PASSWORD = 10f5241c

client = Mysql2::Client.new(:host => "us-cdbr-iron-east-05.cleardb.net", :username => "b4078336a46f7e", :password => "10f5241c", :database => "heroku_28ca4c386152c4f")
result = client.query("select * from teamRoster")
result.each do |row|
	puts row.class
end
row = dbh.select_one("SELECT VERSION()")
puts "Server version: " + row[0]