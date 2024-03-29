# Use this file to easily define all of your cron jobs.
#
# It's helpful, but not entirely necessary to understand cron before proceeding.
# http://en.wikipedia.org/wiki/Cron

# Example:
#
set :output, "~/Documents/fantasyncaaf/cron.log"
#
# every 2.hours do
#   command "/usr/bin/some_great_command"
#   runner "MyModel.some_method"
#   rake "some:great:rake:task"
# end
#
# every 4.days do
#   runner "AnotherModel.prune_old_records"
# end

# Learn more: http://github.com/javan/whenever

every 7.minutes do
	rake 'update_scores'
end

every 1.day, at: '3:00 am' do
	rake 'update_leaguestandings'
end

 every 1.day, at: '4:00 am' do
 	rake 'update_gametimes'
 end

# every 1.day, at: '5:00 am' do
#	 rake 'update_collegeteamroster'
# end