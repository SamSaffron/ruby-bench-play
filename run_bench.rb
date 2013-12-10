require 'csv'

RUBY_DIR="/home/sam/Source/ruby"
DISCOURSE_DIR = "/home/sam/Source/discourse"
INSTALL_DIR = "/home/sam/.rbenv/versions/ruby-head"
CURRENT_DIR = `pwd`.strip

# restore env, so rbenv works right
old_env = ENV['ORIGINAL_ENV'].dup

ENV.each do |k,v|
  ENV[k] = nil
end

old_env.gsub!('declare -x ','')
old_env.gsub!('"','')
old_env.split("\n").each do |row|
  k,v = row.split("=")
  ENV[k] = v
end

ENV["RAILS_ENV"] = "production"

def dump_results(results)
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
end


def run_ruby(cmd)
  p "running: #{cmd}"
  result = ""
  ENV["RBENV_VERSION"] = "ruby-head"
  IO.popen("#{cmd}") do |line|
    puts result << line.read
  end
  ENV.delete "RBENV_VERSION"

  result
end

def flatten_hash(hash,prefix="",result=nil)
  result ||= {}

  hash.each do |k,v|
    if Hash === v
      flatten_hash(v, "#{prefix}#{k}_", result)
    else
      result["#{prefix}#{k}"] = v
    end
  end

  result
end

require 'yaml'

def rebuild
  puts "REBUILDING FROM SCRATCH"
  `cd #{RUBY_DIR} && autoconf`
  `cd #{RUBY_DIR} && ./configure --prefix=#{INSTALL_DIR}`
  `rm -fr #{INSTALL_DIR}`
  puts `cd #{RUBY_DIR} && make clean`
  puts `cd #{RUBY_DIR} && make install`
  run_ruby "gem install bundler"
  `rbenv rehash`
  run_ruby "cd #{DISCOURSE_DIR} && bundle install"
  `rbenv rehash`
end

COMMITS = 1
results = []

COMMITS.times do |i|
  puts `cd #{RUBY_DIR} && git checkout HEAD~#{i*30}`
  puts `cd #{RUBY_DIR} && make install`
  unless $?.success?
    rebuild
  end

  failed = false
  2.times do
    result = run_ruby "ruby plot_mem.rb" rescue nil
    if $?.success?
      plot_mem = YAML.load(result)

      File.delete("bench.yml") if File.exists?("bench.yml")
      run_ruby "cd #{DISCOURSE_DIR} && ruby script/bench.rb -o #{CURRENT_DIR}/bench.yml"
      if File.exists?("bench.yml")
        results << flatten_hash(YAML.load_file("bench.yml")).merge(plot_mem)
      end
      break
    elsif !failed
      rebuild
      failed = true
    end
  end

  p results

  dump_results(results)
end



