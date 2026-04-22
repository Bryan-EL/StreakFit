# Changelog

All notable changes to StreakFit are documented here.

The format follows [Keep a Changelog](https://keepachangelog.com/en/1.0.0/).

---

## [Unreleased]

---

## [1.0.0] — 2026-04-22

### Added

**Core app**
- Single-file Flask backend (`app.py`) with JSON flat-file user storage
- Mobile-first single-page frontend (`index.html`) — no build step, no dependencies beyond Flask
- 4-step onboarding: body stats → training days per week → muscle group focus → intensity level

**Workouts**
- 6 muscle groups: chest, back, legs, core, shoulders, full body
- 4 intensity levels: Beginner, Intermediate, Advanced, Athlete — each adjusts sets, rest periods, and gem rewards
- Rest timer with animated SVG ring and audio cues
- Bonus workout system: unlock a lighter extra session once per day with gems or a simulated ad
- Confirmation dialog when closing bonus modal after payment (gems non-refundable warning)

**Streak system**
- Day-based consecutive streak tracking — counts every day worked out in a row, independent of weekly plan
- `streak_broken` flag set on login when a day is missed; modal prompts user to use a shield, buy one, or accept streak loss
- Streak shields (max 2): protect a broken streak without incrementing the count
- `best_streak` record tracked separately

**Gems economy**
- Earn gems for completing workouts (base + intensity bonus), finishing weekly goal (50 gem bonus, once per week), and correct quiz answers
- Spend gems on streak shields (150 each), bonus workouts (40), and quiz revives (50)
- Simulated gem purchase packages (Starter / Boost / Power / Champion)

**Daily Quiz**
- 10 questions per day drawn from a 60-question bank, shuffled by date seed
- 2 shared lives across the session
- +5 gems per correct answer, +20 gem bonus for completing the full set
- Revive lives with gems or a simulated ad
- Progress bar shows questions answered vs total

**Progress screen**
- Streak, best streak, total sessions, weekly progress stats
- Weight trend graph (SVG, requires at least 2 data points)
- BMI calculator
- Total calories burned tracker
- Last 20 session history with group, intensity, sets, and gems earned

**Store**
- Gem packages with IDR and USD pricing display
- Streak shield purchase and status display

**Profile & Settings**
- Edit body metrics (weight, height, age, gender) at any time
- Change training days, intensity, and muscle groups
- Sound effects toggle (Web Audio API)
- Vibration / haptic feedback toggle
- Reset all data option

**Auth**
- Email + password signup and login
- SHA-256 password hashing
- Server-side session management
- Backwards-compatible login supporting both `pw` and `password` field names

### Fixed
- `done_today` now uses `last_workout_date` (consistent with `complete()`) instead of the week-slot key, preventing completed workouts from appearing undone
- Streak operator precedence bug: `last == yesterday or last is None and streak == 0` corrected to `last == yesterday or (last is None)`
- Bonus modal payment buttons are immediately disabled on tap to prevent double-spend
- Unescaped apostrophe in JS string causing `Unexpected identifier 't'` syntax error

---

[Unreleased]: https://github.com/your-username/streakfit/compare/v1.0.0...HEAD
[1.0.0]: https://github.com/your-username/streakfit/releases/tag/v1.0.0
