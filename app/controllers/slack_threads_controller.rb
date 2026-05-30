class SlackThreadsController < ApplicationController
  def index
    @slack_threads = SlackThread.recent.includes(:slack_topics)

    if params[:status].present?
      @slack_threads = @slack_threads.where(status: params[:status]) unless params[:status] == "all"
    else
      @slack_threads = @slack_threads.where(status: :new_thread)
    end

    @slack_threads = @slack_threads.by_category(params[:category]) if params[:category].present?
    if params[:q].present?
      q = params[:q].strip
      @slack_threads = @slack_threads.where(
        "title ILIKE :q OR summary ILIKE :q OR :kw = ANY(keywords)",
        q: "%#{q}%", kw: q
      )
    end
    @categories = %w[architecture stakeholder team_decision incident other]
    @status_counts = SlackThread.group(:status).count
  end

  def show
    @slack_thread = SlackThread.find(params[:id])
    @topics = @slack_thread.slack_topics.by_urgency
    @messages = @slack_thread.slack_messages.chronological
    @analyses = @slack_thread.codebase_analyses.order(created_at: :desc)
    @repo_paths = Setting.get("global", "repo_paths", default: {}) || {}
    @developers = Developer.by_name
    @github_repos = Setting.get("global", "github_repos", default: []) || []
  end

  def new
    @slack_thread = SlackThread.new
  end

  def create
    attrs = slack_thread_params
    attrs[:keywords] = params[:keywords_raw].to_s.split(",").map(&:strip).reject(&:blank?)
    attrs[:participants] = params[:participants_raw].to_s.split(",").map(&:strip).reject(&:blank?)
    @slack_thread = SlackThread.new(attrs)
    @slack_thread.captured_at ||= Time.current
    if @slack_thread.save
      redirect_to @slack_thread, notice: "Thread logged."
    else
      render :new, status: :unprocessable_entity
    end
  end

  private

  def slack_thread_params
    params.require(:slack_thread).permit(
      :slack_channel_id, :slack_channel_name, :slack_thread_ts,
      :slack_url, :title, :category, :summary, :obsidian_path, :captured_at
    )
  end
end
