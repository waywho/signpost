require "test_helper"

class Delegations::IssuesControllerTest < ActionDispatch::IntegrationTest
  setup do
    @delegation = create(:delegation, summary: "Fix the bug")
  end

  test "create creates GitHub issue and redirects" do
    mock = Object.new
    mock.define_singleton_method(:create_issue) { |*_args, **_kwargs|
      { number: 42, url: "https://github.com/org/repo/issues/42", title: "Fix the bug" }
    }
    original_new = GitHubService.method(:new)
    GitHubService.define_singleton_method(:new) { |**_| mock }

    post delegation_issue_path(@delegation), params: { repo: "org/repo" }
    assert_redirected_to delegation_path(@delegation)
    assert_equal "https://github.com/org/repo/issues/42", @delegation.reload.github_issue_url
  ensure
    GitHubService.define_singleton_method(:new, original_new)
  end

  test "create without repo shows alert" do
    post delegation_issue_path(@delegation), params: { repo: "" }
    assert_redirected_to delegation_path(@delegation)
    assert_equal "Select a repo.", flash[:alert]
  end
end
