class InsightsService
  def alerts
    [
      *stale_oneones,
      *overloaded_developers,
      *overdue_commitments,
      *aging_prs,
      *unresolved_concerns
    ]
  end

  def patterns
    Setting.get("global", "daily_insights", default: []) || []
  end

  private

  def stale_oneones
    Developer.by_name.includes(:oneone_sessions).filter_map do |dev|
      last = dev.oneone_sessions.recent.first
      days = last ? (Date.current - last.session_date).to_i : nil
      if days.nil? && dev.created_at < 3.weeks.ago
        { type: "warning", icon: "ph-calendar-x", message: "#{dev.name} has never had a 1:1" }
      elsif days && days > 21
        { type: "warning", icon: "ph-calendar-x", message: "#{dev.name} hasn't had a 1:1 in #{days} days" }
      end
    end
  end

  def overloaded_developers
    Developer.by_name.includes(:delegations).filter_map do |dev|
      count = dev.delegations.active.count
      if count >= 5
        { type: "danger", icon: "ph-warning", message: "#{dev.name} has #{count} active delegations" }
      end
    end
  end

  def overdue_commitments
    grouped = Commitment.pending.where("due_date < ?", Date.current).group(:stakeholder).count
    grouped.filter_map do |stakeholder, count|
      name = stakeholder.presence || "No stakeholder"
      { type: "danger", icon: "ph-clock-countdown", message: "#{count} overdue commitment#{'s' if count > 1} to #{name}" }
    end
  end

  def aging_prs
    queue = begin
      GitHubService.new.pr_queue
    rescue
      return []
    end
    old = queue.select { |pr| pr[:created_at] < 3.days.ago }
    return [] if old.empty?
    [{ type: "warning", icon: "ph-git-pull-request", message: "#{old.size} PR#{'s' if old.size > 1} waiting for review > 3 days" }]
  end

  def unresolved_concerns
    Developer.by_name.includes(:developer_notes, :oneone_sessions).filter_map do |dev|
      recent_concerns = dev.developer_notes.where(note_type: "concern").where("created_at > ?", 1.month.ago)
      next if recent_concerns.empty?
      last_oneone = dev.oneone_sessions.recent.first
      if last_oneone.nil? || last_oneone.session_date < recent_concerns.minimum(:created_at).to_date
        { type: "warning", icon: "ph-flag", message: "#{dev.name} has #{recent_concerns.count} concern note#{'s' if recent_concerns.count > 1} with no follow-up 1:1" }
      end
    end
  end
end
