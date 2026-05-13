# Manual smoke — Phase 1

Parity-checked against Vibe Island v1.0.33 behavior.

## Prereqs
- `claude` CLI installed (`npm install -g @anthropic-ai/claude-code`)
- iTerm2 installed
- `~/.claude/settings.json` backed up: `cp ~/.claude/settings.json /tmp/settings.before-smoke.json`

## Install
1. `bash scripts/build-app.sh release`
2. `rm -rf /Applications/VibeClone.app && cp -R build/VibeClone.app /Applications/`
3. Launch from Spotlight or `open /Applications/VibeClone.app`

## Verify install
4. `cat ~/.vibeclone/bin/vibeclone-bridge` — zsh script exists, contains `kMDItemCFBundleIdentifier == "app.vibeclone.macos"` + `mdfind` + 5-min orphan logic
5. `ls -la /tmp/vibeclone.sock` — mode `srw-------` (0600)
6. `python3 -c "import json; d=json.load(open('$HOME/.claude/settings.json')); print(sorted(d.get('hooks',{}).keys()))"` — prints `['Notification','PermissionRequest','PostToolUse','PreCompact','PreToolUse','SessionEnd','SessionStart','Stop','SubagentStart','SubagentStop','UserPromptSubmit']` (all 11)
7. `python3 -c "import json; d=json.load(open('$HOME/.claude/settings.json')); print(d['hooks']['PermissionRequest'][0]['hooks'][0])"` — confirms `"timeout": 86400` and command `"/bin/sh -c '[ -x \"$HOME/.vibeclone/bin/vibeclone-bridge\" ] && \"$HOME/.vibeclone/bin/vibeclone-bridge\" --source claude; exit 0'"`
8. Menu bar icon (bell) visible

## Permission flow
9. In iTerm2: `claude -p "use the Bash tool to echo hi"`
10. Popover opens within 200ms — claude · Bash · `echo hi` shown
11. Click **Jump** → iTerm2 window/tab activated
12. Click **Approve** → claude prints "hi"
13. `tail -1 ~/Library/Logs/VibeClone/history.jsonl` — JSON line with `"event":"PermissionRequest"`, `"decision":"approve"`

## Lifecycle events
14. Single `claude -p` run produces records for: `SessionStart`, `UserPromptSubmit`, `PreToolUse`, `PermissionRequest`, `PostToolUse`, `Stop` (verify via `cut -d'"' -f4 ~/Library/Logs/VibeClone/history.jsonl | sort -u`)

## Resilience
15. Quit VibeClone via popover power button. Run `claude -p "ls"` — claude proceeds (bridge exits 0 with `{}` body).
16. Relaunch VibeClone.
17. Manually `rm ~/.vibeclone/bin/vibeclone-bridge` — re-created within 30 s by HookInstaller heal timer.
18. Quit VibeClone. Move `.app` to trash. Run `claude -p "ls"`. Wait > 5 min. Run `claude -p "ls"` again. The launcher's orphan path runs, JXA strips all vibeclone hook entries from `~/.claude/settings.json` and removes `~/.vibeclone`.
19. Disable **Auto-heal hooks** toggle in popover. Manually strip a hook entry. Confirm it does NOT come back within 60s.

## Zero-telemetry check
20. While app is running: `lsof -i -P | grep VibeClone | grep -v LISTEN` — no outbound TCP connections.
21. `nettop -p $(pgrep VibeClone) -L 5` — zero network traffic during permission flow.
22. `find . -name '*.swift' -exec grep -l -i 'sentry\|analytics\|posthog\|amplitude\|telemetry' {} \;` — only `AppPreferences.swift` matches (`noTelemetry: Bool = true` declaration).

## Cleanup after test
- Quit VibeClone
- `rm -rf /Applications/VibeClone.app ~/.vibeclone /tmp/vibeclone.sock`
- `cp /tmp/settings.before-smoke.json ~/.claude/settings.json` (restore)

---

## Phase 2 additions

### Floating panel
23. After launch, floating panel visible at top center: pill shape when no pending requests.
24. On notch Macs: pill anchored just below camera notch. On non-notch: floating bar below menu bar.
25. Set `prefs.displayMode` via popover picker. "Menu only" hides panel; "Notch" / "Bar" show it.

### Pending expansion
26. Trigger `claude -p "use Bash to echo hi"`. Panel expands from pill to card showing source / tool / command + Approve / Deny / Jump within 200 ms.
27. Approve from panel → claude proceeds, panel collapses back to pill within 200 ms.
28. Two simultaneous requests → panel shows top request plus "+1 more" badge.

### Sounds
29. With `prefs.soundsEnabled = true`, PermissionRequest fires permission sound. Toggle off → silent.
30. Replace bundled sound: `cp ~/Music/myown.aiff ~/.vibeclone/custom-sounds/permission.aiff`. Next request plays the custom file.

### Markdown plan preview
31. When CC payload carries `tool_input.plan` (string > 20 chars), RequestRow's "Plan preview" disclosure renders markdown (bold / italic / code / headers).
32. Same plan text shows inline in NotchView expanded card with markdown styling.

### Hotkey
33. Press ⌃⇧V from any app. First time: System Settings → Privacy → Accessibility prompt. Grant. Subsequent presses focus VibeClone + refresh panel.

### Display mode switching
34. Toggle picker: panel switches notch ↔ bar ↔ hidden in < 200 ms.

### Zero-telemetry recheck (Phase 2)
35. With panel/sounds/hotkey active: `lsof -i -P | grep VibeClone | grep -v LISTEN` → still no outbound TCP. No Sentry, no analytics.

---

## Phase 3 additions — terminal fan-out

### Per-terminal jump (each requires the named terminal app installed and a claude session running inside it)

36. **Ghostty**: run `claude -p "echo hi"` inside Ghostty, click Jump → Ghostty window front.
37. **Warp**: same flow in Warp → Warp window front.
38. **VS Code integrated terminal**: open VS Code, open a folder, open its terminal, run `claude`. Click Jump → VS Code window front + that folder window focused.
39. **Cursor integrated terminal**: same as VS Code → Cursor window front.
40. **Alacritty**: run `claude` in Alacritty, click Jump → Alacritty window front (no tab targeting).
41. **kitty**: run `claude` in kitty. Confirm `~/.config/kitty/kitty.conf` has `allow_remote_control yes`. Click Jump → kitty focuses the right window.
42. **tmux inside iTerm2**: start tmux in iTerm2, create 3 windows, run `claude` in window 2. Click Jump → iTerm2 front + tmux active window switched to 2.

### Prober verification

43. `python3 -c "import os; print(os.getppid())"` from each terminal — note the ppid.
44. Trigger `claude -p` from inside each terminal. Inspect `~/Library/Logs/VibeClone/history.jsonl` for the PermissionRequest entry — `cwd` and `tty` fields should match the source terminal.

### Regression check (Phase 1 + 2 still work)

45. iTerm2 jump still lands correct tab (Phase 1 tty match).
46. Terminal.app jump still lands correct window.
47. Floating panel + sounds + markdown preview still work as before.
