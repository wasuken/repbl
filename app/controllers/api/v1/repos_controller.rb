# coding: utf-8
class Api::V1::ReposController < ApplicationController
  include ReposHelper
  def index
    render json: Repo.select('url, title')
  end
  def destroy
    repo = Repo.find(params[:id])

  end
  def create
    # TODO: JOBにやらせる。
    # TODO: いろいろやらせるので、別の場所でやらせる。
    # いまはこれだけ。
    repo = Repo.create(url: params[:url], title: params[:title])
    # ZIP File -> JSON
    zfs_insert(remote_zip_to_zfs(params[:url], "*.md$"), repo.id)
  end
end
