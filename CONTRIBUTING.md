# Contributing to StreakFit

Thank you for taking the time to contribute! This document covers everything you need to get started.

---

## Table of Contents

- [Code of Conduct](#code-of-conduct)
- [How Can I Contribute?](#how-can-i-contribute)
- [Development Setup](#development-setup)
- [Project Conventions](#project-conventions)
- [Adding a Premium Program](#adding-a-premium-program)
- [Submitting a Pull Request](#submitting-a-pull-request)
- [Reporting Bugs](#reporting-bugs)
- [Suggesting Features](#suggesting-features)

---

## Code of Conduct

Be respectful, constructive, and inclusive. Harassment of any kind will not be tolerated.

---

## How Can I Contribute?

- Fix a bug — check [open issues](../../issues) labelled `bug`
- Add a workout or quiz question
- Add a new premium training program
- Improve the UI or accessibility
- Write tests
- Improve documentation

---

## Development Setup

```bash
git clone https://github.com/your-username/streakfit.git
cd streakfit
pip install flask
python app.py
```

The app runs at **http://localhost:5000**. Flask's debug mode is enabled by default so the server restarts on file save.

### Resetting test data

Log in and tap **Profile → Reset All Data**, or delete `users.json` to wipe all accounts.

---

## Project Conventions

### Backend (`app.py`)

- All constants are defined at the top of the file in the `# ─── ECONOMY` block. Change behaviour by editing those — not by scattering magic numbers through the code.
- Every route returns a JSON object. Errors use `{"error": "message"}` with an appropriate HTTP status code.
- User data is persisted to `users.json` via `load_users()` / `save_users()`. There is no ORM or migration system — keep the schema simple and backwards-compatible.
- Passwords are SHA-256 hashed. Never store or log plaintext passwords.

### Frontend (`templates/index.html`)

- Vanilla JS only — no framework, no bundler.
- All state lives in the `S` object (loaded from `/api/state`) and a handful of local variables.
- Navigation is screen-based: each `.screen` div is shown/hidden via `goTo(id)`.
- Styles use CSS custom properties defined in `:root`. Follow the existing naming pattern (`--bg`, `--fg`, `--accent`, etc.).
- Never use `localStorage` or `sessionStorage` — session state lives server-side.

### Adding Exercises

Exercises are defined in the `WORKOUTS` dict in `app.py`. Each entry needs:

```python
{
    "name": "Exercise Name",
    "sets": 3,
    "reps": "10-12",
    "rest": 60,          # seconds
    "emoji": "💪",
    "color": "#c8f55a",
    "bonus_ok": False,   # True = can appear in bonus sessions
    "desc": "Short description of the movement.",
    "cues": ["Cue 1", "Cue 2", "Cue 3", "Cue 4"],
}
```

Bonus variants live in `"{group}_bonus"` keys and should be lighter than the main set.

### Adding Quiz Questions

Questions live in `QUIZ_BANK` in `app.py`:

```python
{
    "id":  "q061",              # unique, sequential
    "q":   "Question text?",
    "opts": ["A", "B", "C", "D"],
    "a":   1,                   # 0-indexed correct answer
    "exp": "Explanation shown after answering.",
}
```

### Adding a Premium Program

Programs live in the `TRAINING_PROGRAMS` list in `app.py`. Each program needs:

```python
{
    "id": "unique_id",
    "title": "Program Name",
    "emoji": "🏋️",
    "cost": 350,
    "color": "#c8f55a",
    "tagline": "Short tagline for card display",
    "description": "Detailed description shown in modal.",
    "weeks": 4,
    "level": "Intermediate",  # Beginner, Intermediate, Advanced
    "workouts": [
        {
            "week": 1,
            "focus": "Week Theme",
            "exercises": [
                "Exercise Name x10",
                "Another Exercise 30s",
                "Third Exercise x12"
            ]
        },
        # ... more weeks
    ]
}
```

**Exercise string format:** `"Name xN"` for rep-based, `"Name Ns"` for time-based. The parser extracts the number automatically.

---

## Submitting a Pull Request

1. Fork the repo and create a branch from `main`:
   ```bash
   git checkout -b fix/my-bug-description
   ```
2. Make your changes. Keep commits focused — one logical change per commit.
3. Test manually by running the app and exercising the affected feature.
4. Update `CHANGELOG.md` under the `[Unreleased]` section.
5. Open a pull request against `main`. Fill in the PR template:
   - **What** does this change?
   - **Why** is it needed?
   - **How** was it tested?

---

## Reporting Bugs

Open an issue and include:

- Steps to reproduce
- Expected behaviour vs actual behaviour
- Browser and OS
- Any console errors (F12 → Console)

---

## Suggesting Features

Open an issue with the label `enhancement`. Describe:

- The problem you're trying to solve
- Your proposed solution
- Any alternatives you considered
