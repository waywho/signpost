# Tech Lead OS

A local-first tech lead operating system built with Rails 8. Manages developer profiles, 1:1 sessions, delegations, commitments, PR reviews, and Slack thread triage — with vector search, Claude AI analysis, and GitHub integration.

## Requirements

- Ruby 3.4+
- PostgreSQL 18 (via Postgres.app) with pgvector extension
- puma-dev (for `https://techos.test`)

## Setup

### 1. Clone and install dependencies

```bash
git clone <repo-url> ~/Documents/src/techos-rails
cd ~/Documents/src/techos-rails
bundle install
```

### 2. Create the PostgreSQL role

```bash
psql postgres -c "CREATE ROLE techos_rails WITH LOGIN PASSWORD 'techos_rails_dev' CREATEDB SUPERUSER;"
```

Superuser is needed for the pgvector extension. Password is stored in Rails credentials.

### 3. Set up Rails credentials

```bash
bin/rails credentials:edit
```

Add:

```yaml
database:
  password: techos_rails_dev

active_record_encryption:
  primary_key: <generate with bin/rails db:encryption:init>
  deterministic_key: <generate>
  key_derivation_salt: <generate>
```

### 4. Create and migrate database

```bash
bin/rails db:create
bin/rails db:migrate
bin/rails db:seed
```

Seeds create default noise filters and settings.

### 5. Set up puma-dev

```bash
ln -sf ~/Documents/src/techos-rails ~/.puma-dev/techos
```

App is now available at `https://techos.test`.

### 6. Configure API keys (optional)

Via the settings page at `https://techos.test/settings`, or via Rails console:

```ruby
EncryptedSetting.set("credentials", "openai_api_key", "sk-...")        # For vector embeddings
EncryptedSetting.set("credentials", "anthropic_api_key", "sk-ant-...")  # For PR analysis, 1:1 prep, noise filtering
EncryptedSetting.set("credentials", "github_pat", "ghp_...")            # For PR queue, developer activity, issue creation
EncryptedSetting.set("credentials", "slack_bot_token", "xoxb-...")      # For Slack triage (acknowledge reactions)
EncryptedSetting.set("credentials", "slack_app_token", "xapp-...")      # For Socket Mode (real-time capture)

Setting.set("global", "github_username", "your-handle")
Setting.set("global", "github_repos", ["org/repo1", "org/repo2"])       # For issue creation
```

### 7. Connect Google Calendar (optional)

1. Open [Google Calendar Settings](https://calendar.google.com/calendar/r/settings)
2. Click your calendar under "Settings for my calendars"
3. Scroll to "Secret address in iCal format" and copy the URL
4. Add it via the settings page at `https://techos.test/settings` (Calendar section), or via console:

```ruby
EncryptedSetting.set("credentials", "google_ical_url", "https://calendar.google.com/calendar/ical/your-email/private-token/basic.ics")
```

The dashboard will show today's schedule, auto-detect 1:1 meetings, match attendees to developer profiles, and alert you before upcoming 1:1s.

### 8. Start Slack Socket Mode listener (optional)

```bash
bin/slack
```

Requires Slack bot and app tokens. Listens for brain emoji reactions, @mentions, and watched channel activity.

## Usage

### Daily workflow

1. **Start your day** at the dashboard (`/`) — check your PR queue, overdue commitments, active delegations, and team pulse.
2. **Triage Slack** at `/slack_threads` — new threads auto-captured via Socket Mode appear in the "New" tab. For each thread:
   - Claude extracts distinct topics with urgency and action recommendations
   - **Acknowledge** (posts 👍 to Slack, marks triaged)
   - **Delegate** (creates a Delegation, redirects to assign a developer)
   - **Dismiss** (archives — no action needed)
   - Delegate individual topics within a thread independently
3. **Review PRs** at `/pr_reviews` — your GitHub PR queue appears at the top (live from GitHub). Click "Review" to pre-fill a review log. Click "Analyze with Claude" on a logged review for a full structured analysis: critical flags, severity-categorized issues with file:line references, inline tips, pre-submit checklist, and a Claude Code terminal command for deeper local review.
4. **Manage your team** at `/developers` — sidebar layout with per-developer profiles. Add observations (good/growth/concern/context) inline. Click "Prep 1:1" before meetings — Claude generates talking points from recent notes, last 1:1, delegations, and GitHub activity.
5. **Track commitments** at `/commitments` — overdue items flagged red, due-soon in orange. One-click mark done.
6. **End your day** on the dashboard — fill in EOD notes and tomorrow's priorities in the daily log.

### Slack capture

Threads are auto-captured when:
- You react with the 🧠 emoji (configurable)
- You are @mentioned
- You participate in a thread
- A watched channel is set to "full stream" mode

Configure watched channels and capture mode (socket/poll/both) at `/settings`.

### Semantic search

Search at `/search` finds related content across three levels:
- **Threads** — matches on thread summaries
- **Topics** — matches on extracted issue descriptions
- **Messages** — matches on individual message content

Results ranked by cosine similarity with configurable threshold.

### Creating GitHub issues

From any delegation show page, click "Create GitHub Issue" to push it to a watched repo. The delegation summary becomes the issue title, handoff message becomes the body.

## Running tests

```bash
bin/rails test
```

Tests use factory_bot (not fixtures).

## Architecture

| Component | Description |
|-----------|-------------|
| **Models** | Developer, OneoneSession, DeveloperNote, Delegation, Commitment, PrReview, SlackThread, SlackMessage, SlackTopic, DailyLog, WatchedChannel, NoiseFilter, Setting, EncryptedSetting |
| **Services** | EmbeddingService (OpenAI), NoiseFilterService (Claude), SlackCaptureService, ThreadAnalysisService, SlackSearchService, ThreadCompressionService, GitHubService (Octokit), ClaudeService, PrAnalysisService, OneOnePrepService, SlackService, SlackSocketListener |
| **Jobs** | SlackCaptureJob, ThreadAnalysisJob, ThreadReanalysisJob, SlackPollJob, SlackCatchUpJob, ThreadCompressionJob, GitHubActivitySyncJob |
| **Search** | pgvector with HNSW indexes, 3-level semantic search (thread/topic/message) |

## Pages

| Path | Description |
|------|-------------|
| `/` | Dashboard — daily briefing with team, delegations, commitments, PR reviews, daily log |
| `/developers` | Developer profiles with sidebar, notes, 1:1 sessions, skills, GitHub activity |
| `/delegations` | Delegation tracking with status filtering and urgency color-coding |
| `/commitments` | Commitment tracking with due date warnings and inline mark-done |
| `/pr_reviews` | PR review history with live GitHub queue and Claude analysis copilot |
| `/slack_threads` | Slack triage inbox with topics, urgency, and actions (acknowledge/delegate/dismiss) |
| `/search` | Semantic search across threads, topics, and messages |
| `/settings` | API keys, GitHub/Slack config, watched channels, noise filters |
| `/status` | System health checks (database, pgvector, Solid Queue) |

## Stack

- Ruby 3.4 / Rails 8.1
- PostgreSQL 18 + pgvector
- css-zero (no build step)
- Phosphor Icons (CDN)
- Stimulus + Turbo
- Solid Queue (background jobs)
- puma-dev (local HTTPS)
