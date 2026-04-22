# StreakFit 🏋️

> Zero-equipment calisthenics trainer with streaks, gems, quizzes, and progress tracking — runs entirely in the browser, backed by a single Python file.

![Python](https://img.shields.io/badge/Python-3.8+-blue?logo=python&logoColor=white)
![Flask](https://img.shields.io/badge/Flask-2.x-black?logo=flask)
![License](https://img.shields.io/badge/License-MIT-green)
![PRs Welcome](https://img.shields.io/badge/PRs-welcome-brightgreen)

---

## Table of Contents

- [Overview](#overview)
- [Features](#features)
- [Screenshots](#screenshots)
- [Getting Started](#getting-started)
- [Project Structure](#project-structure)
- [Configuration](#configuration)
- [API Reference](#api-reference)
- [Contributing](#contributing)
- [License](#license)

---

## Overview

StreakFit is a mobile-first progressive web app that helps you build a consistent calisthenics habit. It requires zero equipment — all exercises are floor-only. The app runs as a local Flask server with a single-page HTML frontend; no database, no npm, no build step.

---

## Features

| Category | Details |
|---|---|
| **Workouts** | 6 muscle groups (chest, back, legs, core, shoulders, full body) · 4 intensity levels · rest timer with ring animation |
| **Streaks** | Day-based consecutive streak tracking independent of your weekly plan · shield protection system |
| **Gems** | Earn gems by completing workouts, weekly goals, and quiz sessions · spend on shields and bonus workouts |
| **Quiz** | 10 randomised fitness questions per day · 2 lives · revive with gems or an ad |
| **Progress** | Weight trend graph · calorie estimates · session history · BMI tracker |
| **Store** | Buy gem packages · purchase streak shields (max 2) |
| **Onboarding** | 4-step setup: body stats → training days → muscle focus → intensity |

---

## Getting Started

### Prerequisites

- Python 3.8 or higher
- pip

### Installation

```bash
# 1. Clone the repository
git clone https://github.com/your-username/streakfit.git
cd streakfit

# 2. Install dependencies
pip install flask

# 3. Run the app
python app.py
```

Then open **http://localhost:5000** in your browser.

> The app stores all user data in `users.json` in the project root. This file is created automatically on first signup.

### Running in Production

For a public deployment, replace the dev server with Gunicorn and set a strong secret key via environment variable:

```bash
pip install gunicorn
export SECRET_KEY="your-strong-random-key"
gunicorn -w 4 -b 0.0.0.0:8000 app:app
```

Then update `app.secret_key` in `app.py` to read from `os.environ.get("SECRET_KEY", "fallback")`.

---

## Project Structure

```
streakfit/
├── app.py              # Flask backend — all routes, business logic, data layer
├── users.json          # Auto-generated user database (JSON flat file)
├── templates/
│   └── index.html      # Single-page frontend (HTML + CSS + vanilla JS)
├── README.md
├── CONTRIBUTING.md
├── CHANGELOG.md
├── LICENSE
└── .gitignore
```

---

## Configuration

All tuneable constants live at the top of `app.py`:

| Constant | Default | Description |
|---|---|---|
| `GEMS_PER_WORKOUT` | `10` | Base gems earned per completed workout |
| `WEEK_REWARD` | `50` | Bonus gems for hitting your weekly goal |
| `SHIELD_COST` | `150` | Gems to buy one streak shield |
| `SHIELD_MAX` | `2` | Maximum shields a user can hold |
| `BONUS_COST` | `40` | Gems to unlock a bonus workout |
| `REVIVE_COST` | `50` | Gems to revive quiz lives |
| `QUIZ_LIVES` | `2` | Lives per daily quiz session |
| `QUIZ_QUESTIONS_PER_DAY` | `10` | Questions served per daily session |

---

## API Reference

All endpoints return JSON. Authentication uses server-side sessions (cookie-based).

### Auth

| Method | Endpoint | Description |
|---|---|---|
| `POST` | `/api/auth/signup` | Create account |
| `POST` | `/api/auth/login` | Log in |
| `POST` | `/api/auth/logout` | Log out |
| `GET` | `/api/auth/me` | Check session |

### Core

| Method | Endpoint | Description |
|---|---|---|
| `GET` | `/api/state` | Full user state (gems, streak, settings…) |
| `POST` | `/api/setup` | Save onboarding choices |
| `POST` | `/api/profile` | Update workout preferences |
| `POST` | `/api/metrics` | Update body stats |
| `GET` | `/api/weight_log` | Weight history + metrics |

### Workouts

| Method | Endpoint | Description |
|---|---|---|
| `GET` | `/api/workout/today` | Today's exercises |
| `GET` | `/api/workout/bonus_exercises` | Bonus workout exercises |
| `POST` | `/api/workout/complete` | Mark workout done, award gems |
| `POST` | `/api/bonus_unlock` | Spend gems/ad to unlock bonus |

### Quiz

| Method | Endpoint | Description |
|---|---|---|
| `GET` | `/api/quiz/today` | Current question + session state |
| `POST` | `/api/quiz/answer` | Submit answer |
| `POST` | `/api/quiz/revive` | Restore lives |

### Streak & Store

| Method | Endpoint | Description |
|---|---|---|
| `POST` | `/api/streak/resolve` | Handle broken streak (shield/lose) |
| `POST` | `/api/gems/buy_shield` | Purchase a shield |
| `POST` | `/api/gems/use_shield` | Manually use a shield |
| `POST` | `/api/gems/purchase` | Buy a gem package |
| `POST` | `/api/reset` | Reset all user data |

---

## License

Distributed under the MIT License. See [`LICENSE`](LICENSE) for details.
