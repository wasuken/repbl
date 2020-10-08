# coding: utf-8
require 'json'


class Api::V1::ReposController < ApplicationController
  include ReposHelper
  def index
    render json: Repo.select('id, url, title')
  end
  def show
    zfs = repos_to_zfs(params[:id])
    render json: zfs.to_h
  end
  def destroy
    Repo.find(params[:id]).destroy
  end
  def create
    # TODO: JOBにやらせる。-> JOBにやらせるまでもないのでは...?
    repo = Repo.create(url: params[:url], title: params[:title])
    zfs_insert(remote_zip_to_zfs(params[:url], ".*.md$"), repo.id)
  end
end
