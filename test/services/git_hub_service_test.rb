require "test_helper"
require "ostruct"

class GitHubServiceTest < ActiveSupport::TestCase
  setup do
    @mock_client = Object.new
    @service = GitHubService.new(client: @mock_client)
    Setting.set("global", "github_username", "testuser")
    Setting.set("global", "github_repos", ["org/repo"])
  end

  test "pr_queue returns PRs via search API" do
    user = OpenStruct.new(login: "author1")
    label = OpenStruct.new(name: "bug")
    pr = OpenStruct.new(
      number: 42, title: "Fix bug", user: user,
      repository_url: "https://api.github.com/repos/org/repo",
      created_at: 1.hour.ago, updated_at: 30.minutes.ago,
      draft: false, html_url: "https://github.com/org/repo/pull/42",
      labels: [label]
    )
    search_result = OpenStruct.new(items: [pr])

    @mock_client.define_singleton_method(:search_issues) { |query| search_result }

    result = @service.pr_queue
    assert_equal 1, result.size
    assert_equal 42, result.first[:number]
    assert_equal "org/repo", result.first[:repo]
  end

  test "pr_queue returns empty when no username" do
    Setting.where(scope: "global", key: "github_username").delete_all
    assert_equal [], @service.pr_queue
  end

  test "create_issue returns issue data" do
    issue = OpenStruct.new(number: 1, html_url: "https://github.com/org/repo/issues/1", title: "Bug")
    @mock_client.define_singleton_method(:create_issue) { |repo, title, body, opts = {}| issue }

    result = @service.create_issue("org/repo", title: "Bug", body: "Details")
    assert_equal 1, result[:number]
  end

  test "developer_activity parses push events" do
    commit = OpenStruct.new(message: "Fix typo\n\nDetails", sha: "abc123")
    payload = OpenStruct.new(commits: [commit])
    repo = OpenStruct.new(name: "org/repo")
    event = OpenStruct.new(type: "PushEvent", payload: payload, repo: repo, created_at: 1.day.ago)

    @mock_client.define_singleton_method(:user_events) { |handle| [event] }

    result = @service.developer_activity("alice")
    assert_equal 1, result.size
    assert_equal "commit", result.first[:type]
  end

  test "pr_comments returns formatted comments" do
    review_comment = OpenStruct.new(user: OpenStruct.new(login: "alice"), body: "Fix this", path: "app.rb", line: 10)
    issue_comment = OpenStruct.new(user: OpenStruct.new(login: "bob"), body: "Looks good")

    @mock_client.define_singleton_method(:pull_request_comments) { |repo, number| [review_comment] }
    @mock_client.define_singleton_method(:issue_comments) { |repo, number| [issue_comment] }

    result = @service.pr_comments("org/repo", 42)
    assert_equal 2, result.size
    assert_equal "alice", result.first[:user]
  end

  test "linked_issue returns issue data" do
    pr = OpenStruct.new(body: "Fixes #123")
    issue = OpenStruct.new(number: 123, title: "Bug report", body: "Details")

    @mock_client.define_singleton_method(:pull_request) { |repo, number| pr }
    @mock_client.define_singleton_method(:issue) { |repo, number| issue }

    result = @service.linked_issue("org/repo", 42)
    assert_equal 123, result[:number]
  end

  test "linked_issue returns nil when no issue referenced" do
    pr = OpenStruct.new(body: "Just a change")
    @mock_client.define_singleton_method(:pull_request) { |repo, number| pr }

    assert_nil @service.linked_issue("org/repo", 42)
  end
end
