desc "This task is called by the Heroku scheduler add-on"
task :update_scores do
  puts "Updating scores from ESPN..."
  bundle exec ruby "espn_scraper_main.rb"
end