namespace :repo do
  desc "insert repo"
  task :insert, [:url, :title] => :environment do |task, args|
    RepoJob.perform_now(:insert, args.url, args.title)
  end
  desc "update repo"
  task :update, [:url, :title] => :environment do |task, args|
    RepoJob.perform_now(:update, args.url, args.title)
  end
  desc "delete repo"
  task :delete, [:url] => :environment do |task, args|
    RepoJob.perform_now(:delete, args.url)
  end
  task :check, [:url] => :environment do |task, args|
    RepoJob.perform_now(:check, args.url)
  end
end
