# Tech Lead OS — Project Conventions

## Styling

Use **css-zero** — no Tailwind, no build step. All styles served via Propshaft.

### Components (installed)

Always use these instead of raw HTML:

| Component | Class | Usage |
|-----------|-------|-------|
| **Button** | `btn`, `btn--primary`, `btn--secondary`, `btn--borderless`, `btn--negative`, `btn--positive`, `btn--icon` | Primary for submit/action, negative for delete, borderless for cancel/dismiss |
| **Badge** | `badge`, `badge--primary`, `badge--secondary`, `badge--positive`, `badge--negative` | Urgency, status, category tags |
| **Card** | `card` | Content containers |
| **Alert** | `alert`, `alert--positive`, `alert--negative` | Error/success messages |
| **Input** | `input` | All form inputs, selects, textareas. Use `rows="auto"` for auto-sizing textareas |
| **Avatar** | `avatar` | Developer avatars. Use `<span role="img">` for initials. Set size via `--avatar-size` |
| **Separator** | `separator` | Horizontal dividers between sections |
| **Tabs** | `tabs`, `tabs__list`, `tabs__button` | JS-switched content panels (uses css-zero tabs_controller) |
| **Group** | `group` | Input + button combos |
| **Flash** | `flash`, `flash__content` | Toast notifications |
| **Layouts** | `sidebar-layout`, `header-layout`, `centered-layout`, `container` | Page layouts |
| **Sidebar** | `sidebar-menu`, `sidebar-menu__button`, `sidebar-menu__group-label` | Navigation sidebars |

### Utility Classes (css-zero built-in)

Flex/grid: `.flex`, `.flex-col`, `.flex-wrap`, `.inline-flex`, `.items-center`, `.items-start`, `.justify-between`, `.justify-center`, `.flex-1`, `.gap`, `.gap-half`

Text: `.font-bold`, `.font-medium`, `.font-semibold`, `.text-sm`, `.text-xs`, `.text-2xl`, `.text-center`, `.capitalize`, `.overflow-ellipsis`

### Spacing Utility Classes (project-defined in application.css)

```
.mbe-1 through .mbe-6  — margin-block-end (1=4px, 2=8px, 3=12px, 4=16px, 6=24px)
.mbs-1, .mbs-2, .mbs-4, .mbs-6  — margin-block-start
.p-2, .p-3, .p-4  — padding
.px-3  — padding-inline
.py-1, .py-2  — padding-block
.mis-2  — margin-inline-start
```

Use these instead of inline `style="margin-block-end: var(--size-4)"`.

### CSS Variables (from css-zero)

Colors: `--color-primary`, `--color-text-subtle`, `--color-positive`, `--color-negative`, `--color-border`, `--color-surface`, `--color-secondary`, `--color-bg`

Sizes: `--size-1` through `--size-16` (4px increments up to --size-4, then larger steps)

Typography: `--text-xs`, `--text-sm`, `--text-base`, `--text-lg`, `--text-xl`, `--text-2xl`, `--text-4xl`

### Icons

Use **Phosphor Icons** (CDN). Class format: `ph ph-icon-name`. Example: `<i class="ph ph-brain"></i>`.

Browse icons at https://phosphoricons.com.

## Testing

- Use **factory_bot** (not fixtures). Factories in `test/factories.rb`.
- Mock external API calls (OpenAI, Anthropic, Slack, GitHub) in tests — never hit real APIs.
- Service tests go in `test/services/`.

## Services

All external API integrations are wrapped in services under `app/services/`:

| Service | Purpose |
|---------|---------|
| `ClaudeService` | Anthropic API wrapper |
| `EmbeddingService` | OpenAI embeddings |
| `GitHubService` | Octokit wrapper |
| `SlackService` | Slack Web API (reactions) |
| `SlackCaptureService` | Thread capture pipeline |
| `ThreadAnalysisService` | Claude topic extraction |
| `SlackSearchService` | pgvector semantic search |
| `CalendarService` | iCal feed parsing |
| `InsightsService` | Alerts + pattern detection |
| `PrAnalysisService` | Claude PR review copilot |
| `OneOnePrepService` | Claude 1:1 prep briefing |
| `TicketDraftService` | Claude issue drafting |
| `AssigneeSuggestionService` | Developer ranking |
| `ActionQueueService` | Action item processing |
| `NoiseFilterService` | Claude noise classification |
| `SlackSocketListener` | Socket Mode WebSocket |

All services accept dependency injection for testing:
```ruby
MyService.new(claude_service: mock_claude, github_service: mock_github)
```

## Settings

- **Secrets** (API keys): `EncryptedSetting` model (Active Record Encryption)
- **Config** (preferences): `Setting` model (JSONB values)
- Both use `scope` + `key` composite keys
- Manageable via `/settings` UI or Rails console
