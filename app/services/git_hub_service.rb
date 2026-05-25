class GitHubService
  def initialize(client: nil)
    @client = client || Octokit::Client.new(
      access_token: EncryptedSetting.get("credentials", "github_pat"),
      auto_paginate: true
    )
  end

  def configured?
    EncryptedSetting.get("credentials", "github_pat").present?
  end

  def list_repos
    repos = @client.repos(nil, sort: :pushed, affiliation: "owner,collaborator,organization_member").map do |r|
      { full_name: r.full_name, private: r.private, pushed_at: r.pushed_at }
    end
    repos.uniq { |r| r[:full_name] }.sort_by { |r| r[:full_name].downcase }
  rescue Octokit::Error => e
    Rails.logger.error("GitHubService list_repos error: #{e.message}")
    []
  end

  def pr_queue
    username = Setting.get("global", "github_username")
    return [] unless username

    results = @client.search_issues("is:pr is:open review-requested:#{username}")
    results.items.map do |pr|
      repo = pr.repository_url.sub("https://api.github.com/repos/", "")
      {
        repo: repo,
        number: pr.number,
        title: pr.title,
        author: pr.user.login,
        created_at: pr.created_at,
        updated_at: pr.updated_at,
        draft: pr.draft,
        url: pr.html_url,
        labels: pr.labels.map(&:name)
      }
    end.sort_by { |pr| pr[:created_at] }
  rescue Octokit::Error => e
    Rails.logger.error("GitHubService pr_queue error: #{e.message}")
    []
  end

  def developer_activity(github_handle, days: 30)
    events = @client.user_events(github_handle)
    cutoff = days.days.ago

    events.select { |e| e.created_at > cutoff }.filter_map do |event|
      parse_event(event)
    end.flatten.compact
  rescue Octokit::Error => e
    Rails.logger.error("GitHubService activity error for #{github_handle}: #{e.message}")
    []
  end

  def create_issue(repo, title:, body:, labels: [])
    options = {}
    options[:labels] = labels if labels.present?
    issue = @client.create_issue(repo, title, body, options)
    { number: issue.number, url: issue.html_url, title: issue.title }
  end

  def pr_detail(repo, number)
    pr = @client.pull_request(repo, number)
    {
      number: pr.number,
      title: pr.title,
      author: pr.user.login,
      body: pr.body,
      additions: pr.additions,
      deletions: pr.deletions,
      changed_files: pr.changed_files
    }
  rescue Octokit::Error => e
    Rails.logger.error("GitHubService pr_detail error: #{e.message}")
    { number: number, title: "", author: "", body: "", additions: 0, deletions: 0, changed_files: 0 }
  end

  def pr_diff(repo, number)
    @client.get("repos/#{repo}/pulls/#{number}", accept: "application/vnd.github.v3.diff").to_s
  rescue Octokit::Error => e
    Rails.logger.error("GitHubService pr_diff error: #{e.message}")
    ""
  end

  def pr_comments(repo, number)
    review_comments = @client.pull_request_comments(repo, number).map do |c|
      { user: c.user.login, body: c.body, path: c.path, line: c.line }
    end
    issue_comments = @client.issue_comments(repo, number).map do |c|
      { user: c.user.login, body: c.body }
    end
    (review_comments + issue_comments).first(10)
  rescue Octokit::Error => e
    Rails.logger.error("GitHubService pr_comments error: #{e.message}")
    []
  end

  def linked_issue(repo, number)
    pr = @client.pull_request(repo, number)
    body = pr.body.to_s
    issue_match = body.match(/#(\d+)/)
    return nil unless issue_match

    issue_number = issue_match[1].to_i
    issue = @client.issue(repo, issue_number)
    { number: issue.number, title: issue.title, body: issue.body }
  rescue Octokit::Error
    nil
  end

  private

  def parse_event(event)
    case event.type
    when "PushEvent"
      event.payload.commits&.map do |commit|
        {
          type: "commit",
          repo: event.repo.name,
          title: commit.message.lines.first&.strip,
          url: "https://github.com/#{event.repo.name}/commit/#{commit.sha}",
          occurred_at: event.created_at
        }
      end
    when "PullRequestEvent"
      action = event.payload.action
      type = case action
             when "opened" then "pr_opened"
             when "closed" then event.payload.pull_request.merged ? "pr_merged" : nil
             end
      return unless type
      {
        type: type,
        repo: event.repo.name,
        title: event.payload.pull_request.title,
        url: event.payload.pull_request.html_url,
        occurred_at: event.created_at
      }
    when "PullRequestReviewEvent"
      {
        type: "pr_review",
        repo: event.repo.name,
        title: event.payload.pull_request.title,
        url: event.payload.review.html_url,
        occurred_at: event.created_at
      }
    end
  end
end
