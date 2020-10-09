class ReposController < ApplicationController
  def index
  end
  def show
    @title = Repo.find(params[:id]).title
  end
end
