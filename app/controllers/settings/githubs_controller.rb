class Settings::GithubsController < ApplicationController
  def show
    load_data
  end

  def update
    if params[:github_pat].present?
      EncryptedSetting.set("credentials", "github_pat", params[:github_pat])
    end
    if params[:github_username].present?
      Setting.set("global", "github_username", params[:github_username])
    end
    Setting.set("global", "github_repos", Array(params[:github_repos]).reject(&:blank?))
    load_data
    render :show
  end

  private

  def load_data
    @has_github_pat = EncryptedSetting.get("credentials", "github_pat").present?
    @github_username = Setting.get("global", "github_username")
    @selected_repos = Setting.get("global", "github_repos", default: []) || []
    github_service = GitHubService.new
    @github_configured = github_service.configured?
    @available_repos = @github_configured ? (github_service.list_repos rescue []) : []
  end
end
