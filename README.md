# StreakFit

> Zero-equipment calisthenics tracker. Train anywhere, anytime.

StreakFit is a mobile fitness app built with Flutter and a Python/Flask backend. It tracks daily workout streaks, offers structured calisthenics programs, a fitness quiz, an AI coach, and a gem-based economy — all stored in Supabase PostgreSQL.

---

## Features

- **Daily Workouts** — personalised exercise plans based on your body stats, intensity, and muscle group preferences
- **Streak System** — Mon–Sun week strip showing completed days, streak counter, best streak tracking
- **Calisthenics Programs** — purchasable multi-week programs with weekly progression and blur/lock for unpurchased content
- **Quiz** — daily 10-question fitness quiz with lives system and gem rewards
- **Bonus Workouts** — unlock extra sessions with gems or by watching an ad
- **Store** — gem packages, streak shields, and ad rewards
- **AI Coach** — chat with an LLM (Llama 3.3 70B via Groq) about fitness and health. Pro subscription required (1000 💎 for 30 days)
- **Streak Shields** — protect your streak from being broken on missed days
- **Sound Effects** — real WAV tone audio cues generated in-app via `audioplayers`
- **Settings** — sound, vibration toggles, body metrics, training preferences

---

## Tech Stack

| Layer | Technology |
|---|---|
| Mobile app | Flutter (Dart) |
| Backend | Python 3 + Flask |
| Database | Supabase (PostgreSQL) |
| AI Coach | Groq API — `llama-3.3-70b-versatile` |
| Auth | Custom session-based (Flask) |
| DB driver | psycopg2 with connection pooling |

---

## Project Structure

```
streakfit/
├── app.py                  # Flask backend — all API endpoints
├── .env                    # Environment variables (never commit)
├── .env.example            # Safe template for env vars
├── requirements.txt        # Python dependencies
└── streakfit_app/
    ├── lib/
    │   ├── main.dart       # All screens and UI (~5400 lines)
    │   ├── api.dart        # API client — all HTTP calls
    │   └── state.dart      # AppState (ChangeNotifier)
    ├── android/            # Android build files
    ├── ios/                # iOS build files
    └── pubspec.yaml        # Flutter dependencies
```

---

## Getting Started

### Prerequisites

- Python 3.10+
- Flutter SDK 3.11+
- A [Supabase](https://supabase.com) project
- A [Groq](https://console.groq.com) API key (free)

### 1. Supabase Setup

Run this SQL in your Supabase SQL Editor:

```sql
CREATE TABLE users (
    email         TEXT PRIMARY KEY,
    password_hash TEXT NOT NULL DEFAULT '',
    data          JSONB NOT NULL DEFAULT '{}'
);

CREATE VIEW user_details_view AS
SELECT
    email,
    data->>'name'               AS name,
    (data->>'streak')::int      AS streak,
    (data->>'best_streak')::int AS best_streak,
    (data->>'gems')::int        AS gems,
    (data->>'shields')::int     AS shields,
    (data->>'total_sessions')::int AS total_sessions,
    data->>'intensity'          AS intensity,
    data->>'last_workout_date'  AS last_workout_date,
    data->>'created'            AS created_at,
    data->'metrics'->>'weight_kg' AS weight_kg,
    data->'metrics'->>'height_cm' AS height_cm,
    (data->'metrics'->>'age')::int AS age,
    data->'metrics'->>'gender'  AS gender,
    jsonb_array_length(COALESCE(data->'history','[]'::jsonb)) AS total_workouts,
    (data->>'setup')::boolean   AS setup_completed,
    (data->>'days_per_week')::int AS days_per_week
FROM users;
```

### 2. Backend Setup

```bash
pip install flask psycopg2-binary python-dotenv requests
```

Create a `.env` file in the same folder as `app.py`:

```
DB_HOST=aws-0-ap-southeast-1.pooler.supabase.com
DB_PORT=6543
DB_NAME=postgres
DB_USER=postgres.your_project_ref
DB_PASSWORD=your_supabase_password
GROQ_API_KEY=gsk_your_groq_key_here
```

> **Never commit `.env` to Git.** It's already in `.gitignore`.

Run the backend:

```bash
python app.py
```

Flask will start on `0.0.0.0:5000`. Find your PC's local IP with `ipconfig` (Windows) or `ifconfig` (Mac/Linux).

### 3. Flutter Setup

```bash
cd streakfit_app
flutter pub get
```

Open `lib/api.dart` and set your PC's local IP:

```dart
static const _defaultBase = 'http://192.168.x.x:5000';
```

Run the app:

```bash
flutter run
```

> Your phone and PC must be on the **same WiFi network**.

---

## Environment Variables

| Variable | Description |
|---|---|
| `DB_HOST` | Supabase pooler host |
| `DB_PORT` | Supabase pooler port (use `6543`) |
| `DB_NAME` | Database name (`postgres`) |
| `DB_USER` | Supabase user (`postgres.your_ref`) |
| `DB_PASSWORD` | Supabase database password |
| `GROQ_API_KEY` | Groq API key for AI Coach |

---

## Flutter Dependencies

| Package | Purpose |
|---|---|
| `provider` | State management |
| `http` | API calls to Flask |
| `shared_preferences` | Persist server URL |
| `google_fonts` | Bebas Neue + DM Sans |
| `fl_chart` | Weight log chart |
| `audioplayers` | Real WAV sound effects |
| `cupertino_icons` | iOS-style icons |

---

## API Endpoints

| Method | Endpoint | Description |
|---|---|---|
| POST | `/api/auth/signup` | Create account |
| POST | `/api/auth/login` | Login |
| GET | `/api/auth/me` | Check session |
| POST | `/api/auth/logout` | Logout |
| POST | `/api/setup` | Save onboarding data |
| GET | `/api/state` | Full user state |
| GET | `/api/workout/today` | Today's exercises |
| POST | `/api/workout/complete` | Mark workout done |
| GET | `/api/quiz/today` | Daily quiz questions |
| POST | `/api/quiz/answer` | Submit answer |
| POST | `/api/programs/purchase` | Buy a program (gems) |
| POST | `/api/programs/activate` | Set active week |
| POST | `/api/store/watch_ad` | Earn gems via ad |
| POST | `/api/gems/buy_shield` | Buy streak shield |
| POST | `/api/bonus_unlock` | Unlock bonus workout |
| POST | `/api/coach` | AI Coach (Pro only) |
| POST | `/api/pro/subscribe` | Subscribe to Pro |
| GET | `/api/pro/status` | Check Pro status |
| POST | `/api/settings` | Save sound/vibration prefs |

---

## Economy

| Action | Reward / Cost |
|---|---|
| Complete daily workout | +15 💎 |
| Complete bonus workout | +15 💎 |
| Correct quiz answer | +5 💎 |
| Watch ad | +30 💎 |
| Buy streak shield | −150 💎 |
| Unlock a program | −varies 💎 |
| Pro subscription | −1000 💎 / 30 days |

---

## Notes

- The app uses **session-based auth** (Flask cookies). Sessions persist across restarts via `shared_preferences`.
- The database uses a **single JSONB `data` column** per user for flexibility — no schema migrations needed when adding new features.
- The backend uses **psycopg2 connection pooling** (min 1, max 5 connections) to avoid the 300–800ms cold-connect penalty on every request.
- The AI Coach is **strictly limited** to fitness and health topics via system prompt. It returns a `402` error if the user is not a Pro subscriber.
- Sound effects are **generated in-memory** as sine-wave WAV bytes using `audioplayers` — no audio asset files needed.