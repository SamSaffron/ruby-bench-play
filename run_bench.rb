RUBY_DIR="/home/sam/Source/ruby"
DISCOURSE_DIR = "/home/sam/Source/discourse"
INSTALL_DIR = "/home/sam/.rbenv/versions/ruby-head"

require 'yaml'

def rebuild
  puts "REBUILDING FROM SCRATCH"
  `rm -fr #{INSTALL_DIR}`
  puts `cd #{RUBY_DIR} && make clean`
  puts `cd #{RUBY_DIR} && make install`
  puts `gem install bundler`
  puts `cd #{DISCOURSE_DIR} && bundle`
end

COMMITS = 10
results = []

COMMITS.times do |i|
  puts `cd #{RUBY_DIR} && git checkout HEAD~#{i*40}`
  puts `cd #{RUBY_DIR} && make install`


  result = `ruby plot_mem.rb` rescue nil
  if $?.success?
    results << YAML.load(result)
  else
    rebuild
    result = `ruby plot_mem.rb` rescue nil
    if $?.success?
      results << YAML.load(result)
    end
  end
end

require 'csv'

col_map = {}
processed = []

results.each do |row|
  new_row = []
  row.each do |k,v|
    col_num = col_map.fetch(k){ col_map[k] = col_map.length }
    new_row[col_num] = v
  end
  processed << new_row
end

processed.unshift col_map.sort{|a,b| a[1] <=> b[1]}.map{|a| a[0]}

CSV.open("result.csv", "wb") do |csv|
  processed.each do |row|
    csv << row
  end
end

