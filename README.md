# Wallora

Native SwiftUI wallpaper + widget app (iOS 17+). No Mac or paid developer account needed:
GitHub builds an unsigned IPA, Sideloadly (Windows) signs it with your free Apple ID.

## 1. Put this on GitHub
1. Create a **public** repo (public = free macOS build minutes).
2. Upload everything in this folder, including the hidden `.github/workflows/build.yml`.
   Easiest: install **GitHub Desktop**, add this folder, publish. (The web uploader often skips dot-folders.)

## 2. Build
Repo → **Actions** → "Build unsigned IPA" → it runs on every push (or press *Run workflow*).
Takes ~5–8 min. Open the finished run → **Artifacts** → download `Wallora-ipa` → unzip → `Wallora.ipa`.

## 3. Install from Windows
1. Install **iTunes** and **iCloud** from apple.com (not the Microsoft Store versions).
2. Install **Sideloadly** (sideloadly.io). Plug in your iPhone, tap *Trust*.
3. Drag `Wallora.ipa` into Sideloadly, enter your Apple ID, click **Start**.
4. iPhone: Settings → Privacy & Security → **Developer Mode** on (restart).
   Settings → General → VPN & Device Management → trust your Apple ID.

Free Apple ID limits: the app expires every **7 days** (re-run Sideloadly, or use its auto-refresh while the PC is on),
and the widget extension counts as an extra app ID against Apple's weekly cap (10).

## If the build fails
Open the failed run, copy the red error lines, and send them to Claude to fix.

## Not included (needs a paid program or more work)
- Weather widget (WeatherKit requires the paid Developer Program)
- Live battery widget (iOS gives widgets no reliable battery access; use Apple's built-in one)
- Calendar-events widget (needs EventKit permission flow, not yet written)
- Color-based search (dominant color extraction exists; the search UI doesn't yet)
