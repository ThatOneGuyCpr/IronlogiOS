# Ironlog for iOS

SwiftUI workout logger for iPhone, with a widget and an Apple Watch app. The project is defined in `project.yml` (XcodeGen), so there's no `.xcodeproj` in the repo. GitHub Actions builds it on a Mac.

## Getting a build

1. Push to `main`, or open **Actions → Build IPA → Run workflow**.
2. When the run finishes (about 5 to 10 minutes), open it and download **Ironlog-IPA** from Artifacts.
3. Unzip it. There are two files:
   - `Ironlog.ipa`: iPhone app, widget and Watch app
   - `Ironlog-phone-only.ipa`: the same build without the Watch app, in case SideStore rejects the Watch part
4. Install with SideStore.

If a build fails, download **build-logs** from the run and send over `ios.log` or `watch.log`.

## Layout

- `App/`: iPhone app
- `Widget/`: home screen and lock screen widget
- `Watch/`: Apple Watch app (built separately and copied into `Ironlog.app/Watch`)
- `Shared/`: exercise library, routines, and the store shared with the widget
