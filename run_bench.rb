RUBY_DIR="/home/sam/Source/ruby"
require 'yaml'

COMMITS = 30
results = []

COMMITS.times do |i|
  puts `cd #{RUBY_DIR} && git checkout HEAD~#{i*10}`
  puts `cd #{RUBY_DIR} && make install`

  results << YAML.load(`ruby plot_mem.rb`) rescue nil
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

