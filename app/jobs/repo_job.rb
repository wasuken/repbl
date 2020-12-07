require 'github_api'

class RepoJob < ApplicationJob
  include ReposHelper
  queue_as :default

  def insert(url, title)
    repo = Repo.create(url: url, title: title)
    zfs_insert(remote_zip_to_zfs(url, ".*.md$"), repo.id)
  end
  def perform(type, *args)
    url, title = args
    case type
    when :insert
      insert(url, title)
    when :update
      Repo.find_by(url: url).destroy
      insert(url, title)
    when :delete
      Repo.find_by(url: url).destroy
    when :check
      user, repo_name = url.gsub(/https?:\/\//, '').split('/').drop(1).take(2)
      repo = Repo.find_by(url: url)
      g = Github.new

      latest_commit_date = g.repos.commits.list(user, repo_name).body.first.commit.committer.date

      if DateTime.parse(latest_commit_date) > repo.updated_at
        puts 'updating, because old.'
        self.perform(:update, url)
      else
        puts 'latest.'
      end
    end
  end
end
