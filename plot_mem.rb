RUBY_DIR="/home/sam/Source/ruby"
DISCOURSE_DIR = "/home/sam/Source/discourse"

commit = `cd #{RUBY_DIR} && git rev-parse HEAD`.strip
date = `cd #{RUBY_DIR} && git show -s --format="%ci" #{commit}`.strip

start = Time.now
require 'objspace'
require "#{DISCOURSE_DIR}/config/environment"

# preload stuff
I18n.t(:posts)

# load up all models and schema
(ActiveRecord::Base.connection.tables - %w[schema_migrations]).each do |table|
table.classify.constantize.first rescue nil
end

# router warm up
Rails.application.routes.recognize_path('abc') rescue nil

results = {
  version: "#{RUBY_VERSION} p#{RUBY_PATCHLEVEL}",
  bootup: Time.now - start,
  rss_kb: `ps -o rss -p #{$$}`.chomp.split("\n").last.to_i
}

if RUBY_PATCHLEVEL == -1
  results[:commit] = commit
  results[:date] = date
end

GC.start

start = Time.now
GC.start
results[:gc_time] = Time.now - start
stats = ObjectSpace.count_objects
results[:total_objects] = stats[:TOTAL] - stats[:FREE]

s = ObjectSpace.each_object(String).map do |o|
  ObjectSpace.memsize_of(o) + 40 # rvalue size on x64
end

results[:total_strings] = s.count
results[:total_string_size_bytes] = s.sum

puts results.to_yaml


