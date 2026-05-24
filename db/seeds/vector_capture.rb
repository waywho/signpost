NoiseFilter.find_or_create_by!(category: "deploy_notification") { |f| f.description = "Automated deploy/release notifications" }
NoiseFilter.find_or_create_by!(category: "pr_bot") { |f| f.description = "PR/CI bot messages (Dependabot, Renovate, etc.)" }
NoiseFilter.find_or_create_by!(category: "standup_update") { |f| f.description = "Daily standup/status update posts" }
NoiseFilter.find_or_create_by!(category: "ooo_notification") { |f| f.description = "Out-of-office and vacation notices" }

Setting.set("global", "slack_capture_mode", "both")
Setting.set("global", "poll_interval_minutes", 15)
Setting.set("global", "compression_after_months", 6)
Setting.set("global", "search_default_threshold", 0.75)
Setting.set("global", "slack_brain_emoji", "brain")
Setting.set("global", "reanalysis_message_threshold", 3)
Setting.set("global", "reanalysis_quiet_minutes", 30)
