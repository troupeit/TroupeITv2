namespace :memcached do
  desc "Flushes memcached local instance"
  task flush: :environment do
    run("cd #{current_path} && rake memcached:flush")
  end
end
