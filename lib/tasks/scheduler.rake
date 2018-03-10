desc "This task is called by the Heroku scheduler add-on"
task :update_scores do
  puts "Updating scores from ESPN..."
  ruby "espn_scraper_main.rb"
end