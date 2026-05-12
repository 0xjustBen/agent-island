import Foundation
import VibeCloneCore

public enum LauncherWriter {

    public static let bundleId = "app.vibeclone.macos"
    public static let appBundleName = "VibeClone.app"

    public static func write(paths: Paths) throws {
        try paths.ensureAll()
        let script = template(home: paths.home.path)
        try script.write(to: paths.launcher, atomically: true, encoding: .utf8)
        try FileManager.default.setAttributes([.posixPermissions: 0o755],
                                              ofItemAtPath: paths.launcher.path)
    }

    public static func template(home: String) -> String {
        return """
        #!/bin/zsh
        # vibeclone-bridge launcher (auto-generated, do not edit)
        H=/Contents/Helpers/vibeclone-bridge
        B="/Applications/\(appBundleName)${H}"
        [ -x "$B" ] && exec "$B" "$@"
        for P in "/Applications/\(appBundleName)" "$HOME/Applications/\(appBundleName)"; do
          B="${P}${H}"; [ -x "$B" ] && exec "$B" "$@"
        done
        C=~/.vibeclone/bin/.bridge-cache
        [ -f "$C" ] && read -r P < "$C" && B="${P}${H}" && [ -x "$B" ] && exec "$B" "$@"
        P="$(/usr/bin/mdfind 'kMDItemCFBundleIdentifier == "\(bundleId)"' 2>/dev/null | /usr/bin/head -1)"
        B="${P}${H}"
        [ -x "$B" ] && { echo "$P" > "$C"; exec "$B" "$@"; }
        # orphan self-cleanup: 5-min grace
        O=~/.vibeclone/.orphaned
        if [ -f "$O" ]; then
          read -r T < "$O"
          if [ $(( $(/bin/date +%s) - T )) -ge 300 ]; then
            /usr/bin/osascript -l JavaScript <<'JSEOF' 2>/dev/null
        \(jxaCleanupBody())
        JSEOF
            rm -rf ~/.vibeclone /tmp/vibeclone.sock /tmp/vibeclone-diagnostic.log
          fi
        else
          /bin/date +%s > "$O"
        fi
        exit 0
        """
    }

    /// JXA body that strips entries containing the substring `vibeclone-bridge`
    /// from `~/.claude/settings.json` `hooks` array. Mirrors Vibe Island's JXA shape.
    private static func jxaCleanupBody() -> String {
        return #"""
        ObjC.import('Foundation')
        var h=ObjC.unwrap($.NSHomeDirectory()),m='vibeclone-bridge'
        function rd(p){var d=$.NSData.alloc.initWithContentsOfFile(p);if(!d||!d.length)return null;return ObjC.unwrap($.NSString.alloc.initWithDataEncoding(d,$.NSUTF8StringEncoding))}
        function wr(p,s){var o=$.NSString.alloc.initWithUTF8String(s);o.writeToFileAtomicallyEncodingError(p,true,$.NSUTF8StringEncoding,null)}
        function strip(s){var r='',q=false,e=false;for(var i=0;i<s.length;i++){var c=s[i];if(e){r+=c;e=false;continue}if(c=='\\'&&q){r+=c;e=true;continue}if(c=='"'){q=!q;r+=c;continue}if(!q&&c=='/'&&s[i+1]=='/'){while(i<s.length&&s[i]!='\n')i++;r+='\n';continue}r+=c}return r}
        function clean(p){var s=rd(p);if(!s)return;var j;try{j=JSON.parse(strip(s))}catch(e){return}var ch=false;if(j.hooks){for(var ev in j.hooks){var a=j.hooks[ev];if(!Array.isArray(a))continue;var f=a.filter(function(e){if(Array.isArray(e.hooks)){e.hooks=e.hooks.filter(function(x){return(x.command||'').indexOf(m)===-1});if(!e.hooks.length)return false}return(e.command||e.bash||'').indexOf(m)===-1});if(f.length!==a.length)ch=true;if(!f.length)delete j.hooks[ev];else j.hooks[ev]=f}if(!Object.keys(j.hooks).length)delete j.hooks}if(ch)wr(p,JSON.stringify(j,null,2)+'\n')}
        clean(h+'/.claude/settings.json')
        """#
    }
}
