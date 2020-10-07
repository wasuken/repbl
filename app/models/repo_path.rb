# coding: utf-8
class RepoPath < ApplicationRecord
  belongs_to :repo
  belongs_to :path
  def create(url, title)
    # Repo.create(url: url, title: title)
    # まだ実装してない
    # 予定ではこんなかんじ
    # dirをJSONに変換
    # j = gh_repo_to_json(url)
    # JSONをさらに解釈させて、Insertする。
    # まだ考えてない
  end
end
