# coding: utf-8
require 'json'

class Api::V1::ReposController < ApplicationController
  include Zfs
  def index
    render json: Repo.select('id, url, title')
  end
  def show
    zfs = repos_to_zfs(params[:id])
    render json: zfs.to_h
  end
  def destroy
    if Token.find_by(token: params[:token])
      Repo.find(params[:id]).destroy
    else
      render json: {message: "Invalid Token."}, status: 400
    end
  end
  def create
    if Token.find_by(token: params[:token])
      repo = Repo.create(url: params[:url], title: params[:title])
      zfs_insert(remote_zip_to_zfs(params[:url], ".*.md$"), repo.id)
    else
      render json: {message: "Invalid Token."}, status: 400
    end
  end
  private
  def create_err_json(msg, er_code = 400)
    [
      er_code,
      { 'Content-Type' => 'application/json' },
      [{ error:  msg}.to_json]
    ]
  end
end
