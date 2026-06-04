# SIGNPOST: Your Tech Lead OS

A local-first tech lead operating system built with Rails 8. Manages developer profiles, 1:1 sessions, delegations, commitments, PR reviews, and Slack thread triage — with vector search, Claude AI analysis, and GitHub integration.

## Requirements

- Ruby 3.4+
- PostgreSQL 18 with the `pgvector` extension. The easiest path is
  [Postgres.app 18](https://postgresapp.com/) which bundles pgvector.
  Homebrew users need `brew install pgvector` separately.
- puma-dev (for `https://signpost.test`) — install once via:

  ```bash
  brew install puma/puma/puma-dev
  sudo puma-dev -setup
  puma-dev -install
  ```

## Setup

### Quick install (one command)

```bash
git clone <repo-url> ~/Documents/src/signpost
cd ~/Documents/src/signpost
bin/rails setup:install
```

The `setup:install` task is idempotent and handles:

1. `bundle install` (if needed)
2. Creates the `signpost` Postgres role (SUPERUSER, needed for pgvector)
3. Generates `config/master.key` if missing, seeds credentials with a database password and Active Record encryption keys
4. `db:prepare` (create + migrate + seed)
5. Symlinks the app into `~/.puma-dev/signpost`

After it finishes, the app is available at `https://signpost.test`. Continue to step 6 to add API keys.

Individual tasks are also available:

| Task | Purpose |
|------|---------|
| `bin/rails setup:db_role` | Create the `signpost` Postgres role |
| `bin/rails setup:credentials` | Generate `master.key` + seed credentials |
| `bin/rails setup:puma_dev` | Symlink the app into `~/.puma-dev/signpost` |

### Manual setup (alternative)

If you prefer to run each step yourself:

#### 1. Clone and install dependencies

```bash
git clone <repo-url> ~/Documents/src/signpost
cd ~/Documents/src/signpost
bundle install
```

#### 2. Create the PostgreSQL role

```bash
psql postgres -c "CREATE ROLE signpost WITH LOGIN PASSWORD 'signpost_dev' CREATEDB SUPERUSER;"
```

Superuser is needed for the pgvector extension. Password is stored in Rails credentials.

#### 3. Set up Rails credentials

> The quick install (`setup:install`) auto-generates these keys with
> `SecureRandom`. This manual path uses Rails' own generator instead
> so you can review and control the values.

Generate Active Record encryption keys first:

```bash
bin/rails db:encryption:init
```

This prints three keys. Copy them, then open the credentials editor:

```bash
bin/rails credentials:edit
```

Add:

```yaml
database:
  password: signpost_dev

active_record_encryption:
  primary_key: <paste primary_key from db:encryption:init>
  deterministic_key: <paste deterministic_key>
  key_derivation_salt: <paste key_derivation_salt>
```

#### 4. Create and migrate database

```bash
bin/rails db:create
bin/rails db:migrate
bin/rails db:seed
```

Seeds create default noise filters and settings.

#### 5. Set up puma-dev

```bash
ln -sf ~/Documents/src/signpost ~/.puma-dev/signpost
```

App is now available at `https://signpost.test`.

### 6. Configure API keys (optional)

All API keys are entered via the settings page at `https://signpost.test/settings` (API Keys section). Below is how to obtain each token.

**GitHub PAT** — for PR queue, developer activity, and issue creation:
1. Go to [GitHub Settings → Developer settings → Personal access tokens](https://github.com/settings/tokens)
2. **Classic token** (recommended — works with org repos): click "Generate new token (classic)", select scopes `repo`, `read:user`, `read:org`
3. **Fine-grained token** (alternative): select your org as "Resource owner", choose specific repos, grant `Issues: read and write`, `Pull requests: read and write`, `Contents: read`
4. Paste the token into the **Github Pat** field in settings
5. Set your GitHub username and repos in the GitHub section of settings

**Slack tokens** — for thread capture and triage reactions:

1. Create a Slack App at [api.slack.com/apps](https://api.slack.com/apps)
2. **Socket Mode:** Settings → Socket Mode → Enable. Click "Generate Token", add scope `connections:write`. Copy the token (`xapp-...`) → paste into settings as **Slack App-Level Token**
3. **Bot scopes:** Features → OAuth & Permissions → **Bot Token Scopes**, add:
   - `channels:history`, `channels:read`, `reactions:read`, `users:read`
4. **User scopes:** Same page → **User Token Scopes**, add:
   - `reactions:write`, `chat:write` (so reactions show as you, not the bot)
5. **Events:** Features → Event Subscriptions → Enable → **Subscribe to bot events** (not "on behalf of users"), add:
   - `reaction_added`, `message.channels`, `app_mention`
6. **Install:** Click "Install to Workspace" at the top of the OAuth page. After installing, two tokens appear on the same page:
   - **Bot User OAuth Token** (`xoxb-...`) → paste into settings as **Slack Bot Token**
   - **User OAuth Token** (`xoxp-...`) → paste into settings as **Slack User Token**

**OpenAI** — for vector embeddings:
1. Get an API key at [platform.openai.com/api-keys](https://platform.openai.com/api-keys)
2. Paste into the **Openai Api Key** field in settings

**Anthropic** — for PR analysis, 1:1 prep, noise filtering, topic extraction:
1. Get an API key at [console.anthropic.com/settings/keys](https://console.anthropic.com/settings/keys)
2. Paste into the **Anthropic Api Key** field in settings

### 7. Connect Google Calendar (optional)

1. Open [Google Calendar Settings](https://calendar.google.com/calendar/r/settings)
2. Click your calendar under "Settings for my calendars"
3. Scroll to "Secret address in iCal format" and copy the URL
4. Add it via the settings page at `https://signpost.test/settings` (Calendar section), or via console:

```ruby
EncryptedSetting.set("credentials", "google_ical_url", "https://calendar.google.com/calendar/ical/your-email/private-token/basic.ics")
```

The dashboard will show today's schedule, auto-detect 1:1 meetings, match attendees to developer profiles, and alert you before upcoming 1:1s.

### 8. Start background workers

```bash
bin/workers
```

Runs both Solid Queue (`bin/jobs`) and the Slack Socket Mode listener (`bin/slack`) under foreman. Either process can also be started on its own. The Slack listener needs Slack bot and app tokens; without them it will exit. Solid Queue runs regardless and processes ingestion / analysis jobs.

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
