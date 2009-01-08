require 'rubygems'
require 'pathname'
require Pathname.new(__FILE__).dirname.parent.join('lib', 'sabnzbd')

sab = SABnzbd.new(ENV['SAB_UN'] || "", ENV['SAB_PW'] || "") # If set, provide username and password

status = sab.status

puts "******************"
puts "* SABnzbd Status *"
puts "******************"

print status.paused? ? "Currently paused" : "Currently running"
puts " with #{status.queue_size} items in queue"
puts ""
puts "Queue Contents:"
status.jobs.each_with_index do |job, idx|
  percent = "%.2f%%" % [(1.0 - job.left / job.total)]
  puts "#{idx + 1}) #{job.filename} - Total size is #{"%.2f" % [job.total]}MB - #{percent} done"
end