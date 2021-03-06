$:.push File.expand_path("../lib", __FILE__)
require 'espn_scraper/version'

Gem::Specification.new do |s|
  s.name        = 'espn_scraper'
  s.version     = ESPN::VERSION
  s.date        = '2018-03-08'
  s.licenses    = %w[ MIT ]
  s.summary     = 'ESPN Scraper'
  s.description = 'a simple scraping api for espn stats and data'
  s.authors     = %w[ cauchychoi ]
  s.email       = 'cauchy.choi@gmail.com'
  s.homepage    = 'http://github.com/cauchychoi/fantasyncaaf'
  
  s.add_dependency 'httparty'
  s.add_dependency 'nokogiri'
  
  s.files       = `git ls-files`.split("\n")
  s.test_files  = `git ls-files -- test`.split("\n")
end
