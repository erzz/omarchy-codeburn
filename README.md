# omarchy-codeburn

> Lightweight, real-time AI spend and token usage tracker for the [Omarchy](https://omarchy.org/) status bar.

`omarchy-codeburn` is an Omarchy shell bar-widget plugin powered by [CodeBurn](https://github.com/getagentseal/codeburn). It gives you instant visibility into your AI assistant spend, active provider accounts (OpenCode, Anthropic, OpenAI, etc.), token throughput, and model consumption directly from your desktop panel.

<a href="https://www.buymeacoffee.com/erzz"><img src="https://img.buymeacoffee.com/button-api/?text=Buy me a coffee&emoji=&slug=erzz&button_colour=5F7FFF&font_colour=ffffff&font_family=Arial&outline_colour=000000&coffee_colour=FFDD00" /></a>

---

## Features

- **Concise Bar Badge**: Displays daily spend at a glance (e.g. `󰈸 $7.85`) with automatic 5-minute background caching and refresh.
- **Rich Analytics Popup**:
  - **Today Overview**: Total cost, API call count, active sessions, and cache hit rate percentage.
  - **Token Throughput Strip**: Real-time input, output, and cache read tokens.
  - **Provider Spend Breakdown**: Granular cost tracking by provider (OpenCode, OpenAI, Anthropic, Fireworks, etc.).
  - **Top Models Breakdown**: Token spend per model with proportional visual burn distribution meters.
  - **Activity Breakdown**: Spend and turn counts grouped by activity (Exploration, Coding, Debugging, etc.).
- **Zero Configuration Required**: Uses `npx --yes codeburn status --format menubar-json` out of the box or automatically leverages a locally installed `codeburn` binary if available.
- **Unobtrusive Recovery UX**: When offline or if usage logs are uninitialized, displays a graceful recovery hint rather than intrusive error dialogs.
- **Full Keyboard Navigation**: Supports standard Omarchy shortcuts (`R` to refresh, `Esc` to close, `Tab` / Arrow keys for navigation).

---

## Prerequisites

- **[Omarchy Linux](https://omarchy.org/)** with `omarchy-shell` (Quickshell).
- **Node.js** with `npx` (or `bun`) available in your environment `PATH`.

*(No global packages need to be installed manually; `npx` executes CodeBurn on demand.)*

---

## Installation

Add and enable the plugin directly using the Omarchy CLI:

```bash
omarchy plugin add https://github.com/erzz/omarchy-codeburn --enable
```

To position the widget in a specific location on the status bar (e.g., right next to `omarchy.agents`):

```bash
# Move or place next to existing widgets
omarchy bar move codeburn --after omarchy.agents
```

---

## Usage & Controls

- **Left-Click**: Toggle the CodeBurn details popup.
- **Right-Click**: Instantly trigger a live background data refresh.
- **Keyboard Shortcuts** (while popup is open):
  - `R` — Refresh data immediately
  - `Esc` — Close popup
  - `Tab` / `Shift+Tab` — Switch between adjacent Omarchy panels

---

## Updating

Update to the latest version at any time with:

```bash
omarchy plugin update codeburn
```

---

## Uninstallation

To remove the plugin from your system:

```bash
omarchy plugin remove codeburn --yes
```

---

## Configuration

You can customize the polling interval directly in `~/.config/omarchy/shell.json` under your widget layout settings:

```json
{
  "id": "codeburn",
  "refreshIntervalSec": 300
}
```

---

## Attribution & Acknowledgments

This plugin interfaces with **[CodeBurn](https://github.com/getagentseal/codeburn)**, an open-source CLI for inspecting and optimizing LLM and AI coding assistant usage.

---

## License

[MIT](LICENSE) © 2026 Sean Erswell-Liljefelt
