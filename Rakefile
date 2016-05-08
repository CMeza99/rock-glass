# Adapted from https://github.com/mfenner/jekyll-travis

require 'rake'
require 'date'
require 'yaml'

CONFIG = YAML.load(File.read('_config.yml'))

# Default task
task :default => ['site:watch']

desc "Display usage"
task :help do
  puts " $ rake create:post title=\"Post Title\" [date=\"YYYY-MM-DD\"] [tags=[tag1, tag2]] [category=\"category\"]"
  puts " $ rake create:page [title=\"Page Title\"] [folder=\"directory\"]"
  puts " $ rake watch"
end

# Load rake scripts
Dir['_rake/*.rake'].each { |r| load r }
