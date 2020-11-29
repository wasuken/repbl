class Api::V1::RfilesController < ApplicationController
  def index
    query = params[:query]
    repo_id = params[:repo_id]
    if !((repo_id.empty?) || (query.empty?)) && Repo.find(repo_id)
      records = Rfile
                  .joins(:path)
                  .joins("inner join repo_paths on repo_paths.path_id = paths.id")
                  .where(repo_paths: {repo_id: repo_id})
                  .where('paths.name like ?', "%#{query}%")
                  .select('paths.name, repo_paths.repo_id, repo_paths.path_id as path_id, paths.name as name')

      rst = records.map do |r|
        { id: r.id, path_id: r.path_id, path: r.name }
      end

      render json: rst
    else
      render json: { message: "failed parameter query:#{query} or repo_id: #{repo_id}",
                     status: 400 }, status: 400
    end
  end
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
