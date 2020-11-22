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
    end
  end
end
