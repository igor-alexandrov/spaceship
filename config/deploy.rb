#############################################################
# New Relic
# require 'new_relic/recipes'# require 'new_relic/recipes'

#############################################################
# RVM bootstrap
# $:.unshift(File.expand_path("~/.rvm/lib"))
require 'rvm/capistrano'
set :rvm_ruby_string, '1.9.3-p327'
set :rvm_type, :user

#############################################################
# Bundler bootstrap
require 'bundler/capistrano'

#############################################################
# Capistrano Colors
require 'capistrano_colors'

#############################################################
# Multistage
require 'capistrano/ext/multistage'
set :default_stage, "production"
set :stages, %w(production staging)

#############################################################
# Settings
default_run_options[:pty] = true
ssh_options[:forward_agent] = true
set :use_sudo, false
set :group_writable, false
set :scm_verbose, true

#############################################################
# Git
set :scm, :git
set :repository, "git@github.com:igor-alexandrov/spaceship.git"
set :deploy_via, :remote_cache

set :shared_children, shared_children << 'tmp/sockets'

namespace :deploy do
  desc "Application-specific code after update_code"
  after "deploy:update_code" do
    run %{
      rm -f #{release_path}/config/database.yml &&
      ln -s #{shared_path}/config/database.yml #{release_path}/config/database.yml
    }
    
    run %{
      rm -rf #{release_path}/public/system &&
      ln -fs #{shared_path}/system #{release_path}/public/system
    }
    
    run %{
      chgrp -R www #{release_path} && 
      chmod -R o-rwx #{release_path}
    }
  end
  
  task :start, :roles => :app, :except => { :no_release => true } do 
    run "cd #{current_path} && #{try_sudo} #{unicorn_binary} -c #{unicorn_config} -E #{rails_env} -D"
  end
  task :stop, :roles => :app, :except => { :no_release => true } do 
    run "#{try_sudo} kill `cat #{unicorn_pid}`"
  end
  task :graceful_stop, :roles => :app, :except => { :no_release => true } do
    run "#{try_sudo} kill -s QUIT `cat #{unicorn_pid}`"
  end
  task :reload, :roles => :app, :except => { :no_release => true } do
    run "#{try_sudo} kill -s USR2 `cat #{unicorn_pid}`"
  end
  task :restart, :roles => :app, :except => { :no_release => true } do
    run "if [ -f #{unicorn_pid} ] && [ -e /proc/$(cat #{unicorn_pid}) ]; then #{try_sudo} kill -USR2 `cat #{unicorn_pid}`; else cd #{current_path} && #{try_sudo} #{unicorn_binary} -c #{unicorn_config} -E #{rails_env} -D; fi"
  end
end

after "deploy:restart", "deploy:cleanup"

#############################################################
namespace :remote do  
  desc "Run a task on a remote server."  
  # run like: cap staging rake:invoke task=a_certain_task  
  task :rake do  
    run %{
      cd #{deploy_to}/current; /usr/bin/env bundle exec rake #{ENV['task']} RAILS_ENV=#{rails_env}
    }
  end  
end

after 'deploy:update_code'

namespace :maintenance do
  task :start, :roles => :web do
    run "touch #{current_path}/public/maintenance.txt"
  end
  
  task :stop, :roles => :web do
    run "rm -f #{current_path}/public/maintenance.txt"
  end  
end

#############################################################
# Console

namespace :remote do
  task :console, :roles => :app do
    hostname = find_servers_for_task(current_task).first
    exec "ssh -l #{user} #{application} -t '#{deploy_to}/#{current_dir}/script/rails c #{rails_env}'"
  end
end
