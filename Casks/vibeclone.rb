cask "vibeclone" do
  version "0.1.0"
  sha256 :no_check

  url "https://github.com/anthropics/vibeclone/releases/download/v#{version}/VibeClone-#{version}.dmg"
  name "VibeClone"
  desc "Free, MIT-licensed monitor for AI coding agents (Claude, Codex, Gemini, etc.)"
  homepage "https://github.com/anthropics/vibeclone"

  depends_on macos: ">= :sonoma"

  app "VibeClone.app"

  zap trash: [
    "~/.vibeclone",
    "~/Library/Logs/VibeClone",
    "~/Library/Preferences/app.vibeclone.macos.plist",
  ]
end
