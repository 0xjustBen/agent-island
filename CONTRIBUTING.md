# Contributing

Thanks for considering a contribution!

## Dev setup

- macOS 14+, Xcode 15.4+
- Run `swift test` before committing — must stay green

## Style

- Caveman-tight: no filler comments, no docstrings explaining what
  well-named functions already say
- Comments only when *why* is non-obvious (constraint, workaround, bug fix)
- Edit existing files; never create new ones unless required
- Match existing patterns in the file you're editing

## Hard rules

- **Zero telemetry.** No new dependency may phone home. No analytics,
  no Sentry / Crashlytics / Bugsnag / etc.
- **No supply-chain risk.** New dependencies need explicit discussion.
- New tests for new behavior.

## Issue / PR flow

1. Open an issue describing the change first (skip for trivial fixes).
2. Branch from `main`, name `feat/<thing>` or `fix/<thing>`.
3. PR with summary + test plan.

## Reporting bugs

Run `agentisland --doctor` and paste the output in the issue. Logs at
`~/Library/Logs/AgentIsland/`. Never paste anything containing API keys.
