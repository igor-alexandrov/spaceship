set :application, 'spaceship.dev.jetrockets.ru'
set :deploy_to, "/srv/www/#{application}"

set :rails_env, "production"
set :user, "www"

server "spaceship.dev.jetrockets.ru", :app, :web, :db, :primary => true

# Getting current branch
def current_git_branch
  def red(str)
    "\e[31m#{str}\e[0m"
  end
  branch = `git symbolic-ref HEAD 2> /dev/null`.strip.gsub(/^refs\/heads\//, '')
  puts "  ---------- Deploying branch: #{red(branch)} ----------"
  branch
end

set :branch, current_git_branch

set :shell, '/bin/bash'

set :unicorn_binary, "bundle exec unicorn"
set :unicorn_config, "#{deploy_to}/current/config/unicorn.rb"
set :unicorn_pid, "#{deploy_to}/shared/pids/unicorn.pid"