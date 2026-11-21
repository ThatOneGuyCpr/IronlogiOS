# Changelog

Versions follow `MAJOR.MINOR.PATCH`. Everything before 1.0.0 is pre-launch.
Bump MINOR for new features, PATCH for fixes, in `project.yml` (`MARKETING_VERSION`).
Releases show only the version number.

## 0.9.1
- The theme picker restyles itself as you tap through themes (background, title and type) and stays on the one you picked.
- Nothing hides under a theme's tab bar anymore: Discard workout, Erase all data and the bottom of every list scroll clear of it, and the rest timer sits above it.
- History is themed: workout rows, plus the workout detail screen with its sets, volume and minutes up top, records and every set.
- The record banner during a workout uses the theme's type and frame.
- Settings headers and footers read on every theme, and 1-Bit's lists sit on plain white instead of the dither.
- The icon picker always marks the icon you're actually using, even right after a theme switches it.

## 0.9.0
- Themes. Settings › Look › Theme restyles the whole app (type, shapes, textures, colors, the tab bar, even a few words) plus the widgets and the lock screen timer:
  - Glacier: the original, with its color, background and number settings.
  - 8-Bit: console RPG menus, pixel type, an XP bar for the week.
  - Broadsheet: a newspaper front page with a masthead and serif headlines.
  - Terminal: green on black, command prompts, monospace everything.
  - Swiss: poster grid, huge type, black rules and one red.
  - Aero: Windows 7 glass windows on an aurora wallpaper, with a taskbar for tabs.
  - 1-Bit: a classic Mac desktop with striped title bars and checkbox days.
  - Main Event: an 80s fight poster with chrome lettering. Done days are W's, today is LIVE.
  - Broadcast: TV sports graphics, a lower-third headline and a line score for the week.
  - Vice City: sunset missions, wanted stars for the week, and Mission Passed when you finish.
- Each theme can switch the app icon to match (on by default) and keeps its own color unless you pick another.
- Six new icons: Cartridge, Press, Prompt, Poster and Vice City to match the themes, plus Neon.
- 1-Bit's icon sits inside the icon mask now, and Aero's is a glass orb on an aurora.
- Blueprint is gone. If you were using it, you're back on the main icon.

## 0.8.0
- Plans. Tap the plan button next to the date on Train (or Settings › Plan) to pick a program or build your own:
  - Library: Upper / Lower (4 days), Full Body (2 or 3), Push / Pull / Legs (3 or 6), Power + Size (4, heavy A days), Arm focus (5), Lower body focus (3 or 4), Back and shoulders (4), Minimal (2). Filter by Balanced, Muscle focus, Strength or Short on time.
  - Each program shows your week, sets per muscle per week against the 10–20 growth range, and how that compares with your current plan.
  - Build your own: 2 to 6 days, set days or "whenever I can," and Grow / Keep / Light for each muscle (up to 3 on Grow). Grow adds a set to that muscle's exercises, Light takes one off.
- New workouts behind the plans: Full Body A/B/C, Push, Pull and Legs (A and B), and an Arms & Shoulders day.
- With set days, off days show a rest-day screen with your next workout and sets done so far this week, plus a Train anyway button. The week strip shrinks off days to a dot.
- Exercises for muscles on Grow are tagged Focus in the lineup.
- Widgets follow the plan: at 3 days or fewer the medium widget shows one slot per workout; at 2 days, a tile each. Rest days say so. Rings split into one segment per workout.
- Five new icons: Plate and Blueprint, plus Skeuo, 1-Bit and Aero.
- Your current setup carries over as Upper / Lower, 4 days, no set days.

## 0.7.1
- New equipment: Preacher bench, with a dumbbell preacher curl. It's first in line for biceps on Upper A and second on Upper B, and it starts out open.
- Counts read right when there's one: "1 set," "1 exercise," "1 machine taken."

## 0.7.0
- Rest timer style in Settings › Workout screen: the bar, or a big ring with +15s and Skip on either side.
- Compact mode: tighter set rows and cards, with the form video behind a play button in the card header.
- Motion: the set check bounces, the progress bar slides, the week count rolls, and the finish screen pops its icon.
- Unlock icons by training (off by default): 8-Bit after your first workout, Pocket at 5, Arcade at 10, Level Up at 25, Main Event at 50, Loot with your first record, Title Belt at 10 records, Grit with a 4-week streak. New unlocks show on the finish screen with a Use it button.
- Confetti stays off when Reduce Motion is on.

## 0.6.0
- Pick a color in Settings › Look: Glacier, Ember, Gold, Volt, Grape, Mint, Rose or Mono. It changes the app, the widgets and the lock screen rest timer.
- 13 app icons in Settings › App icon: video game (8-Bit, Pocket, Arcade, Loot, Level Up), 80s wrestling (Main Event, Title Belt, Grit), minimal (Studio, Graphite) and fitness (Ember, Blackout). Each has dark and tinted versions. After you switch, Ironlog offers the matching color.
- Background: Sky, Plain, or True black for dark mode.
- Numbers: Standard, Rounded or Condensed for weights, the rest timer and stats.
- Records get celebrated: beat your heaviest weight (or your most reps at it) mid-workout and you get confetti, a banner and a buzz. The finish screen animates its stats and throws confetti when you set a record. Turn it off with Celebrate records.

## 0.5.3
- This week strip shows what you trained each day: an up arrow for upper days and a down arrow for lower, plus the letter (↑A, ↓B).
- Releases and Settings show just the version number.

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
