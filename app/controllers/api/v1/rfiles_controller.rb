class Api::V1::RfilesController < ApplicationController
  def show
    repo_id = params[:repoId]
    rfile_id = params[:rfileId]
    render json: Rfile.joins(:path)
             .joins("inner join repo_paths on repo_paths.path_id = paths.id")
             .where(repo_paths: {repo_id: repo_id})
             .where(rfiles: {id: rfile_id})
             .select("rfiles.contents as contents, rfiles.id as id")
             .first
  end
end
