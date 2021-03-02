# coding: utf-8
require 'json'

class Api::V1::ReposController < ApplicationController
  include Zfs
  def index
    render json: Repo.select('id, url, title')
  end
  def recommended
    repo_id = params[:repo_id]
    rfile_id = params[:rfile_id]
    unless (rfile_id && Rfile.exists?(id: rfile_id))
      render json: {message: "Not found id in Parameters."}, status: 400
      return
    end
    rfile = Rfile
              .joins(:path)
              .select('paths.name as name, rfiles.id as rid')
              .where('rid = ?', rfile_id)
              .first
    q = rfile.name.split('/')[-1].split('.')[0].gsub(/-[0-9]+$/, '')
    recs = Rfile.joins(:path)
             .joins("inner join repo_paths on repo_paths.path_id = paths.id")
             .where(repo_paths: {repo_id: repo_id})
             .where('rfiles.id <> ?', rfile_id)
             .where('paths.name like ?', "%#{q}%")
             .select("rfiles.contents as contents, rfiles.id as id, paths.name as name")
             .take(6)
    render json: recs.map{ |rec|
      {
        id: rec.id,
        contents: rec.contents[0..29],
        name: File.basename(rec.name)
      }
    }
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
