# Place it in /home/appuser/reddit/config/deploy/production.rb

rails_env = "production"
environment rails_env

app_dir = "/home/appuser/reddit"

bind  "unix://#{app_dir}/puma.sock"
pidfile "#{app_dir}/puma.pid"
state_path "#{app_dir}/puma.state"
directory "#{app_dir}/"

stdout_redirect "#{app_dir}/log/puma.stdout.log", "#{app_dir}/log/puma.stderr.log", true

workers 2
threads 1,2

port 9292

activate_control_app "unix://#{app_dir}/pumactl.sock"

prune_bundler
