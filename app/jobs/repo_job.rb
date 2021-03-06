require 'github_api'

class RepoJob < ApplicationJob
  include Zfs
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
      repo = Repo.find_by(url: url)
      Repo.update(title: title || repo.title)
      repo_update(url, ".*.md$")
    when :delete
      Repo.find_by(url: url).destroy
    when :check
      user, repo_name = url.gsub(/https?:\/\//, '').split('/').drop(1).take(2)
      repo = Repo.find_by(url: url)
      g = Github.new

      latest_commit_date = g.repos.commits.list(user, repo_name).body.first.commit.committer.date

      if DateTime.parse(latest_commit_date) > repo.updated_at
        puts "[#{url}] updating, because old."
        self.perform(:update, url, repo.title || repo_name)
      else
        puts 'latest.'
      end
    end
  end
end
