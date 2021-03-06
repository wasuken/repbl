require 'json'
class Api::V1::RfilesController < ApplicationController
  include Zfs
  def index
    query = params[:query]
    repo_id = params[:repo_id]
    if !((repo_id.empty?) || (query.empty?)) && Repo.find(repo_id)
      render json: search_repos_to_zfs(repo_id, query).to_h
    else
      render json: { message: "failed parameter query:#{query} or repo_id: #{repo_id}",
                     status: 400 }, status: 400
    end
  end
  def show
    repo_id = params[:repoId]
    rfile_id = params[:rfileId]
    rf = Rfile.joins(:path)
           .joins("inner join repo_paths on repo_paths.path_id = paths.id")
           .where(repo_paths: {repo_id: repo_id})
           .where(rfiles: {id: rfile_id})
           .select("rfiles.contents as contents, rfiles.id as id, paths.name as name")
           .first
    name = File.basename(rf.name).split('.')[0..-2].join('.')
    name = File.basename(rf.name) if name.empty?
    render json: {
             id: rf.id,
             path: rf.name,
             title: name,
             contents: rf.contents
           }
  end
end
