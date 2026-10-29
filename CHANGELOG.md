# Changelog

Versions follow `MAJOR.MINOR.PATCH`. Everything before 1.0.0 is pre-launch.
Bump MINOR for new features, PATCH for fixes, in `project.yml` (`MARKETING_VERSION`).
The build number counts up on every CI run.

## 0.5.2
- The lock screen rest timer now disappears the moment it hits zero, even with the phone locked. It only shows while you're resting.
- Fixed: tapping the collapse arrow on some exercise cards opened the video instead. The video thumbnail's hidden overflow was catching the tap.
- Swipe a set left to delete it. A long swipe deletes right away.
- Lateral raises (cable and dumbbell) default to 45 seconds of rest.

## 0.5.1
- Form videos re-picked as short demos (exercise-library clips and Shorts) instead of long tutorials.
- Videos start muted and loop like a GIF. Tap the speaker in the player for sound.
- "Pick a different video" in the player: searches YouTube for videos under 4 minutes inside the app. Open one and tap "Use this video" to make it that exercise's demo. Reset goes back to the default.

## 0.5.0
- New widgets:
  - This week (medium): a big count of this week's workouts, a dot for each day, and your last workout with how long ago it was.
  - Week overview (large): progress ring, streak, last workout, latest record, and Up next with a Start button.
  - Small: Up next with Start, Streak, Lift trend, and Move up with a one-tap "Load" that sets next session's weight.
  - Lock screen: a week ring, an inline line above the clock, Last workout, and Up next.
- Widget buttons open the app and start the workout or apply the new weight right away.
- Widgets roll over at midnight and on Mondays without opening the app.

## 0.4.0
- Supersets: curls with pushdowns and calves with abs are paired by default (toggle in Settings). Finish a set of the first exercise and the app sends you straight to the second, then rests once for the pair. Pair or unpair any exercise from its ⋯ menu.
- Faster logging: the keyboard bar has −/+ weight buttons (5 lb dumbbells, 10 lb machines), −/+1 rep, and Same as last.
- Notes on each exercise (seat height, pin, grip), added from the ⋯ menu and shown every time.
- Personal records: heaviest weight and most reps at a weight, shown when you finish and marked in History.
- Form videos: a picked YouTube tutorial for every exercise, played in the app. If a video won't play there, it falls back to an in-app search.
- Automatic backups: an "Export Ironlog Backup" action in Shortcuts for a daily automation that saves to iCloud Drive. Setup steps are in Settings.
- New app icon with dark and tinted versions.
- Safer saving: if saved data ever can't be read, it's set aside instead of being replaced.

## 0.3.0
- Glacier redesign with proper light and dark modes, plus an Appearance override in Settings.
- Train tab: Up next card with time estimate and gear status, this-week strip, routine switcher, lineup.
- Workout: focus card for the current exercise, set table with last time's numbers, collapsed rows for the rest, progress bar, new rest timer bar.
- New Progress tab: weekly stats, streak, top-weight trend chart, recent workouts.
- Move-up prompts after 6 sessions at the same weight.
- In-app clip player: bundled clips loop in the exercise card.
- Weekly workout goal setting.

## 0.2.0
- Real workout logging: sets, weight and reps, history.
- Per-exercise presets for sets, rep range and rest, editable per exercise.
- Mid-workout equipment changes that keep logged sets.
- Rest timer with lock screen Live Activity and an end-of-rest notification.
- Import from the web version, backup export.
- Optional Apple Health logging through a Shortcut.

## 0.1.0
- Test build: routine picker, equipment toggles, widget, signing checks.
