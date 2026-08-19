# Changelog

All notable changes to the CodeBurn Omarchy shell plugin will be documented in this file.

## [1.1.0] - 2026-08-19

### Added
- **Selectable Reporting Periods**: Switch reporting ranges directly inside the popup across **Today**, **7 Days**, **30 Days**, **Month**, **6 Months**, and **Lifetime**.
- **Keyboard Period Navigation**: Cycle periods using `←` / `→` arrows, `[` / `]`, or jump instantly using number keys `1`–`6`.
- **Fast Status Querying**: Added `--no-optimize --no-timeline` flags to background queries for lower latency and reduced JSON payload.
- **Session Persistence**: Retains selected period across popup toggles for the duration of the shell session.
- **Dynamic Bar Tooltip**: Shows active reporting period name alongside spend, calls, and session statistics.
- **IPC Handlers**: Added `setPeriod`, `nextPeriod`, and `prevPeriod` methods for scriptable shell control.

## [1.0.0] - 2026-08-19

### Added
- Initial release of the CodeBurn status bar widget for Omarchy.
- Concise bar badge displaying real-time daily AI spend (`󰈸 $X.XX`).
- Detailed interactive popup panel with overview metrics (Cost, Calls, Sessions, Cache Hit rate).
- Secondary token throughput breakdown (Input, Output, Cache read).
- Real-time provider spend breakdown (OpenCode, Anthropic, OpenAI, etc.).
- Top model consumption listing with proportional visual burn distribution meters.
- Task activity breakdown (Exploration, Coding, Conversation, Debugging).
- Resilient non-blocking background polling with auto-discovery of local `codeburn` CLI or `npx --yes codeburn`.
- Unobtrusive error handling and recovery troubleshooting guidance.
- Full keyboard navigation and shortcuts (`R` to refresh, `Esc` to close).
