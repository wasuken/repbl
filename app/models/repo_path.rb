class RepoPath < ApplicationRecord
  belongs_to :repo
  belongs_to :path
end
