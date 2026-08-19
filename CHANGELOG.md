# Changelog

All notable changes to the CodeBurn Omarchy shell plugin will be documented in this file.

## [1.0.0] - 2026-08-19

### Added
- Initial release of the CodeBurn status bar widget for Omarchy.
- Concise bar badge displaying real-time daily AI spend (`󰈸 $X.XX`).
- Detailed interactive popup panel with today's overview (Cost, Calls, Sessions, Cache Hit rate).
- Secondary token throughput breakdown (Input, Output, Cache read).
- Real-time provider spend breakdown (OpenCode, etc.).
- Top model consumption listing with proportional visual burn distribution meters.
- Task activity breakdown (Exploration, Coding, Conversation, Debugging).
- Resilient non-blocking background polling with auto-discovery of local `codeburn` CLI or `npx --yes codeburn`.
- Unobtrusive error handling and recovery troubleshooting guidance.
- Full keyboard navigation and shortcuts (`R` to refresh, `Esc` to close).
