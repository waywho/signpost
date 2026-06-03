class Settings::RepoPathsController < ApplicationController
  def show
    load_data
  end

  def update
    names = Array(params[:repo_names])
    paths = Array(params[:repo_local_paths])
    repo_map = names.zip(paths).reject { |n, p| n.blank? || p.blank? }.to_h
    Setting.set("global", "repo_paths", repo_map)
    load_data
    render :show
  end

  private

  def load_data
    @repo_paths = Setting.get("global", "repo_paths", default: {}) || {}
  end
end
