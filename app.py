"""
STREAK — Calisthenics App  v5
Run:  python app.py  |  Open: http://localhost:5000

v5 changes:
- Shield cost raised to 150 gems (expensive / discipline-first)
- Bonus workout: user picks muscle group, costs 40 gems OR watch ad
- Daily challenges are fitness QUIZZES (3 lives, can't fake)
- Body metrics tracking (weight, height, age, gender)
- Calorie burn estimation per workout + predicted weight change
- Weight-over-time graph data endpoint
- All exercise visuals replaced with reliable inline SVG illustrations
"""

from flask import Flask, render_template, jsonify, request, session
import json, os, datetime, hashlib, uuid, random, math

app = Flask(__name__)
app.secret_key = "streak_v5_secret_xk92"
USERS_FILE = os.path.join(os.path.dirname(__file__), "users.json")

# ─── ECONOMY ─────────────────────────────────────────────────────────────────
GEMS_PER_WORKOUT     = 10
SHIELD_COST          = 150   # expensive — builds discipline
SHIELD_MAX           = 3
BONUS_WORKOUT_COST   = 40    # gems to unlock bonus workout
CHALLENGE_DAILY_LIMIT = 3
CHALLENGE_LIVES      = 3
REVIVE_COST          = 50    # gems to revive after losing all lives

# ─── GEM PACKAGES ────────────────────────────────────────────────────────────
GEM_PACKAGES = [
    {"id":"starter",  "gems":50,   "price":"Rp 15.000",  "usd":"$0.99",  "label":"Starter",  "popular":False},
    {"id":"boost",    "gems":150,  "price":"Rp 39.000",  "usd":"$2.99",  "label":"Boost",    "popular":True},
    {"id":"power",    "gems":350,  "price":"Rp 79.000",  "usd":"$6.99",  "label":"Power",    "popular":False},
    {"id":"champion", "gems":800,  "price":"Rp 159.000", "usd":"$14.99", "label":"Champion", "popular":False},
]

# ─── INTENSITY ────────────────────────────────────────────────────────────────
INTENSITY_CONFIG = {
    "beginner":     {"sets_mult":0.75,"rest_mult":1.4, "label":"Beginner",    "gems_bonus":0,  "met":3.5},
    "intermediate": {"sets_mult":1.0, "rest_mult":1.0, "label":"Intermediate","gems_bonus":5,  "met":5.0},
    "advanced":     {"sets_mult":1.25,"rest_mult":0.75,"label":"Advanced",    "gems_bonus":10, "met":6.5},
    "athlete":      {"sets_mult":1.5, "rest_mult":0.6, "label":"Athlete",     "gems_bonus":20, "met":8.0},
}

# ─── QUIZ CHALLENGES ─────────────────────────────────────────────────────────
# True/false + multiple choice fitness quizzes — cannot be faked
QUIZ_BANK = [
    # Anatomy
    {"id":"q01","question":"Which muscle group do push-ups primarily target?",
     "options":["Biceps","Chest (pectorals)","Quadriceps","Hamstrings"],"answer":1,"gems":15,
     "explanation":"Push-ups primarily work the pectoralis major (chest), along with the triceps and front deltoids."},
    {"id":"q02","question":"What does 'supinated grip' mean?",
     "options":["Palms facing away","Palms facing toward you","Neutral palms","Alternating grip"],"answer":1,"gems":15,
     "explanation":"Supinated = palms facing you (toward your body). This is the chin-up grip."},
    {"id":"q03","question":"The hollow body hold is a foundational exercise for which sport?",
     "options":["Swimming","Gymnastics","Tennis","Cycling"],"answer":1,"gems":15,
     "explanation":"Hollow body is a core gymnastics position — the base for virtually all gymnastic movements."},
    {"id":"q04","question":"Which muscle does the plank primarily NOT train?",
     "options":["Transverse abdominis","Erector spinae","Biceps femoris","Biceps brachii"],"answer":3,"gems":15,
     "explanation":"The biceps brachii (arm flexor) is not significantly recruited during a plank."},
    {"id":"q05","question":"What is the recommended rest between heavy strength sets?",
     "options":["15–30 seconds","1–2 minutes","5–10 minutes","No rest needed"],"answer":1,"gems":15,
     "explanation":"For strength training, 1–3 minutes rest allows ATP (energy) stores to partially replenish."},
    # Nutrition
    {"id":"q06","question":"Approximately how many calories does 1 gram of protein provide?",
     "options":["4 kcal","7 kcal","9 kcal","2 kcal"],"answer":0,"gems":15,
     "explanation":"Protein and carbohydrates both provide 4 kcal per gram. Fat provides 9 kcal per gram."},
    {"id":"q07","question":"Which macronutrient is the body's preferred fuel during high-intensity exercise?",
     "options":["Fat","Protein","Carbohydrates","Water"],"answer":2,"gems":15,
     "explanation":"Carbohydrates (as glycogen) are the primary fuel for high-intensity exercise. Fat fuels low-intensity work."},
    {"id":"q08","question":"What does 'TDEE' stand for in nutrition?",
     "options":["Total Daily Energy Expenditure","Timed Daily Exercise Effort","Targeted Diet & Exercise Estimation","Total Dietary Enzyme Efficiency"],"answer":0,"gems":15,
     "explanation":"TDEE = Total Daily Energy Expenditure — how many calories you burn in a full day including activity."},
    # Recovery
    {"id":"q09","question":"Muscle soreness 24–48 hours after training is called:",
     "options":["Acute muscle strain","DOMS (Delayed Onset Muscle Soreness)","Myofascial pain syndrome","Rhabdomyolysis"],"answer":1,"gems":15,
     "explanation":"DOMS is normal micro-damage from training. It peaks 24–72 hours post-workout and is a sign of adaptation."},
    {"id":"q10","question":"How much sleep do most adults need for optimal muscle recovery?",
     "options":["4–5 hours","5–6 hours","7–9 hours","10–12 hours"],"answer":2,"gems":15,
     "explanation":"7–9 hours is the recommended range. Growth hormone (key for muscle repair) is predominantly released during deep sleep."},
    # Form & Technique
    {"id":"q11","question":"In a correct squat, where should your knees track?",
     "options":["Straight forward regardless of feet","Over the middle toe / in line with toes","Inward to activate adductors","Behind the heel line"],"answer":1,"gems":15,
     "explanation":"Knees should track over the middle toe — in the same direction your foot is pointing."},
    {"id":"q12","question":"During a push-up, your body should form:",
     "options":["A slight arch at the lower back","A rigid straight line from head to heel","A pike shape with hips raised","A curve with chin tucked hard"],"answer":1,"gems":15,
     "explanation":"A rigid plank position from head to heel — no hip sag and no piking."},
    {"id":"q13","question":"Which cue correctly describes the dead bug exercise?",
     "options":["Arch your lower back as you extend","Lower back must stay flat on the floor","Breathe in short bursts for speed","Extend both arms and legs simultaneously"],"answer":1,"gems":15,
     "explanation":"Lower back must stay pressed flat into the floor throughout every single rep. If it lifts — you've gone too far."},
    {"id":"q14","question":"What does 'eccentric' mean in strength training?",
     "options":["The concentric (lifting) phase","The phase where the muscle lengthens under load","Exercising with maximum speed","A type of isometric hold"],"answer":1,"gems":15,
     "explanation":"Eccentric = muscle lengthening under load (e.g., lowering in a push-up). This phase causes most DOMS."},
    {"id":"q15","question":"What is the 'scapular retraction' cue?",
     "options":["Shrug your shoulders upward","Pull your shoulder blades together and down","Round your upper back","Flare your elbows out"],"answer":1,"gems":15,
     "explanation":"Scapular retraction = pulling shoulder blades toward each other and down. Critical for safe pulling movements."},
    {"id":"q16","question":"How long should you hold a static stretch for benefit?",
     "options":["5–10 seconds","15–20 seconds","30–60 seconds","2–3 minutes"],"answer":2,"gems":15,
     "explanation":"Research supports 30–60 seconds per position for meaningful flexibility improvement."},
    {"id":"q17","question":"Which push-up variation most targets the upper chest?",
     "options":["Wide push-up","Diamond push-up","Decline push-up","Archer push-up"],"answer":2,"gems":15,
     "explanation":"Decline push-ups (feet elevated) shift force toward the upper chest (clavicular head) and front deltoids."},
    {"id":"q18","question":"What is the primary benefit of the hollow body hold?",
     "options":["Hip flexor isolation","Full-body tension and core compression","Lower back strengthening","Shoulder mobility"],"answer":1,"gems":15,
     "explanation":"Hollow body trains the ability to generate and maintain full-body tension — the foundation of gymnastics strength."},
    {"id":"q19","question":"How many sets are generally recommended for strength gains per muscle group per session?",
     "options":["1–2 sets","3–5 sets","8–10 sets","12–15 sets"],"answer":1,"gems":15,
     "explanation":"3–5 working sets per muscle group per session is the well-supported range for strength and hypertrophy."},
    {"id":"q20","question":"True or False: You can target fat loss in a specific body area through exercise (spot reduction).",
     "options":["True — targeted exercises burn fat in that area","False — fat loss is systemic, not localized","True only for the abdominals","False only for the arms"],"answer":1,"gems":15,
     "explanation":"Spot reduction is a myth. Fat is mobilized from all over the body based on genetics and overall caloric deficit."},
]

# ─── WORKOUT DATABASE (zero equipment — floor only) ───────────────────────────
# Visuals are rendered as SVG illustrations inline in the frontend — no broken URLs
WORKOUTS = {
    "chest": [
        {"name":"Push-ups","sets":4,"reps":"12-15","rest":60,"emoji":"💪","color":"#c8f55a","duration_min":0.4,
         "desc":"Classic push-up. Hands shoulder-width, lower chest to just above floor, press explosively. Core, glutes, quads all locked tight.",
         "cues":["Shoulder-width hand placement","2-second controlled descent","Chest grazes the floor","Explode up — lock out arms"]},
        {"name":"Wide Push-ups","sets":3,"reps":"10-12","rest":60,"emoji":"↔️","color":"#6dc87a","duration_min":0.35,
         "desc":"Hands wider than shoulders targets outer chest fibres. Feel the stretch across your chest at the bottom of every rep.",
         "cues":["Hands wider than shoulder-width","Elbows track outward","Feel the stretch at bottom","Squeeze hard at top"]},
        {"name":"Diamond Push-ups","sets":3,"reps":"8-10","rest":75,"emoji":"💎","color":"#5ab4ff","duration_min":0.3,
         "desc":"Diamond shape under chest. Elbows point backward. Heavy tricep and inner chest. Slow the descent.",
         "cues":["Diamond shape under chest","Elbows point straight back","Full range of motion","3-second descent"]},
        {"name":"Decline Push-ups","sets":3,"reps":"10-12","rest":60,"emoji":"📐","color":"#f5a623","duration_min":0.35,
         "desc":"Feet elevated on couch or bed. Shifts load to upper chest and front deltoids. Keep hips level throughout.",
         "cues":["Feet elevated on stable surface","Hips stay level","Hands below shoulders","Control down — press hard"]},
        {"name":"Slow Push-ups (3-1-1)","sets":3,"reps":"6-8","rest":90,"emoji":"🐢","color":"#ff4444","duration_min":0.4,
         "desc":"3 sec down, 1 sec pause at bottom, 1 sec up. Time-under-tension maximised. Harder than it sounds.",
         "cues":["3 seconds on descent","1-second dead pause at bottom","1 second press up","Entire body rigid"]},
    ],
    "back": [
        {"name":"Superman Hold","sets":4,"reps":"15-20","rest":45,"emoji":"🦸","color":"#c8f55a","duration_min":0.4,
         "desc":"Lie face down. Lift arms, chest and legs simultaneously. Squeeze glutes hard. Hold 1–2 sec at top.",
         "cues":["Lie fully flat","Lift arms AND legs simultaneously","Squeeze glutes hard","1-2 sec hold — lower slow"]},
        {"name":"YTW Raises","sets":3,"reps":"10 each","rest":60,"emoji":"🔤","color":"#5ab4ff","duration_min":0.35,
         "desc":"Face down. Raise into Y, T then W shapes. Targets rear deltoids, lower traps, rotator cuff.",
         "cues":["Face down, forehead near floor","Y — arms overhead at 45°","T — arms straight sideways","W — elbows bent 90°"]},
        {"name":"Reverse Snow Angels","sets":3,"reps":"12-15","rest":60,"emoji":"🌨️","color":"#6dc87a","duration_min":0.3,
         "desc":"Face down, arms by sides. Sweep arms overhead and back like a snow angel. Chest and arms stay raised.",
         "cues":["Chest and arms off floor throughout","Sweep arms smoothly overhead","Return to start slowly","Glutes engaged"]},
        {"name":"Hip Hinges","sets":3,"reps":"15-20","rest":45,"emoji":"🙇","color":"#f5a623","duration_min":0.3,
         "desc":"Stand, soft knee bend. Hinge at hips pushing them backward, torso nearly parallel. Hamstrings load. Drive hips forward to stand.",
         "cues":["Soft knee bend — not a squat","Push hips BACK not down","Spine long and neutral","Drive hips forward to stand"]},
        {"name":"Prone Cobra","sets":3,"reps":"12-15","rest":60,"emoji":"🐍","color":"#ff4444","duration_min":0.3,
         "desc":"Face down, hands under shoulders. Press up lifting chest using back muscles, not arms. Squeeze lats.",
         "cues":["Hands under shoulders","Lift with back muscles — not arms","Shoulders back and down","Hold 1 second at top"]},
    ],
    "legs": [
        {"name":"Bodyweight Squats","sets":4,"reps":"15-20","rest":60,"emoji":"🦵","color":"#c8f55a","duration_min":0.45,
         "desc":"Feet shoulder-width. Sit back and down — hip crease below knee. Chest tall. Drive through full foot.",
         "cues":["Weight in full foot","Hip crease below knee","Knees track over toes","Tall chest throughout"]},
        {"name":"Reverse Lunges","sets":3,"reps":"12 each","rest":60,"emoji":"👟","color":"#5ab4ff","duration_min":0.4,
         "desc":"Step straight back. Lower back knee toward floor. Front shin stays vertical. Push through front heel.",
         "cues":["Step straight back","Back knee near floor","Front shin stays vertical","Drive through front heel"]},
        {"name":"Glute Bridges","sets":3,"reps":"15-20","rest":45,"emoji":"🌉","color":"#6dc87a","duration_min":0.4,
         "desc":"On back, feet flat. Drive hips up hard — maximum glute squeeze. 2-second hold at peak. Lower slow.",
         "cues":["Drive hips straight up","Maximum glute squeeze","2-second hold","Lower slowly"]},
        {"name":"Jump Squats","sets":3,"reps":"10-12","rest":75,"emoji":"⚡","color":"#f5a623","duration_min":0.35,
         "desc":"Full squat then explode upward as powerfully as possible. Arms swing. Land with bent knees.",
         "cues":["Full squat depth","Arm swing for power","Maximum height","Land soft — bend knees"]},
        {"name":"Single-Leg RDL","sets":3,"reps":"10 each","rest":60,"emoji":"🦩","color":"#ff4444","duration_min":0.4,
         "desc":"Balance one leg. Hinge at hips — rear leg extends as torso drops. Squeeze standing glute to return.",
         "cues":["Standing leg has slight bend","Hips hinge — don't round spine","Rear leg extends as torso drops","Squeeze glute to return"]},
    ],
    "core": [
        {"name":"Plank","sets":3,"reps":"30-60 sec","rest":45,"emoji":"📏","color":"#c8f55a","duration_min":0.35,
         "desc":"Forearms flat. Rigid line head to heel. Abs + glutes + quads all engaged. Breathe steadily.",
         "cues":["Elbows under shoulders","Rigid line: head → heel","Abs + glutes + quads","Keep breathing"]},
        {"name":"Hollow Body Hold","sets":3,"reps":"20-30 sec","rest":45,"emoji":"🚀","color":"#5ab4ff","duration_min":0.3,
         "desc":"Lower back GLUED to floor. Arms overhead, legs at 30°. If back lifts — raise legs higher.",
         "cues":["Lower back GLUED to floor","Arms reach overhead","Legs at 30°","If back lifts — raise legs"]},
        {"name":"Dead Bug","sets":3,"reps":"8-10 each","rest":45,"emoji":"🐛","color":"#6dc87a","duration_min":0.35,
         "desc":"Arms up, knees at 90° in air. Extend opposite arm and leg. 3 seconds. Back flat always.",
         "cues":["Back flat — always","3 seconds per rep","Opposite arm + leg","Never arch back"]},
        {"name":"Mountain Climbers","sets":3,"reps":"20 each","rest":45,"emoji":"⛰️","color":"#f5a623","duration_min":0.35,
         "desc":"High plank. Drive knees to chest alternately. Hips LEVEL. Controlled rhythm not a sprint.",
         "cues":["Hips LEVEL","Drive knee fully to chest","Controlled rhythm","Shoulders over wrists"]},
        {"name":"Bicycle Crunches","sets":3,"reps":"15 each","rest":45,"emoji":"🚲","color":"#ff4444","duration_min":0.35,
         "desc":"On back. Bring one knee to chest while rotating opposite elbow toward it. Full rotation — not just tilting.",
         "cues":["Hands lightly behind head","Full rotation — elbow past knee","Extend opposite leg fully","Slow and controlled"]},
    ],
    "shoulders": [
        {"name":"Pike Push-ups","sets":4,"reps":"8-12","rest":75,"emoji":"🔺","color":"#c8f55a","duration_min":0.4,
         "desc":"Inverted V position. Lower head toward floor between hands. Full arm extension at top.",
         "cues":["Hips high — inverted V","Head targets floor between hands","Elbows slightly back","Full arm extension"]},
        {"name":"Wall Handstand Hold","sets":3,"reps":"20-30 sec","rest":90,"emoji":"🤸","color":"#5ab4ff","duration_min":0.35,
         "desc":"Kick up to wall. Rigid hollow body upside down. Actively push floor away. Eyes at floor.",
         "cues":["Hands ~30cm from wall","Hollow body — no arch","Push floor away","Eyes at floor between hands"]},
        {"name":"Shoulder Taps","sets":3,"reps":"10 each","rest":45,"emoji":"👆","color":"#6dc87a","duration_min":0.3,
         "desc":"High plank. Tap opposite shoulder while keeping hips as still as possible. Anti-rotation core.",
         "cues":["High plank — feet wide","Hips stay square","Tap opposite shoulder","Controlled — don't rush"]},
        {"name":"Pseudo Planche Lean","sets":3,"reps":"5×5 sec","rest":90,"emoji":"📐","color":"#f5a623","duration_min":0.35,
         "desc":"Push-up position, fingers outward. Lean so shoulders go past hands. Round upper back slightly. Extreme front delt.",
         "cues":["Fingers at ~45°","Lean forward past hands","Round upper back","Hold 5 sec — breathe"]},
        {"name":"Pike Negatives","sets":3,"reps":"4-6","rest":90,"emoji":"⬇️","color":"#ff4444","duration_min":0.35,
         "desc":"Pike push-up position. Take 6 full seconds to lower. Do not press back up — reset. Eccentric strength.",
         "cues":["Take exactly 6 seconds down","Count out loud","Head touches floor lightly","Reset — don't press up"]},
    ],
    "full": [
        {"name":"Burpees","sets":3,"reps":"10-12","rest":75,"emoji":"💥","color":"#c8f55a","duration_min":0.45,
         "desc":"Stand → squat → plank → push-up → jump feet forward → jump up arms overhead. Every rep, full range.",
         "cues":["Controlled squat down","Full push-up — chest to floor","Jump feet forward","Explosive jump overhead"]},
        {"name":"Push-ups","sets":3,"reps":"12-15","rest":60,"emoji":"🤲","color":"#5ab4ff","duration_min":0.35,
         "desc":"Shoulder-width, chest to floor, explode up. Rigid body throughout.",
         "cues":["Shoulder-width grip","Chest to floor","Explode upward","Core tight — full body"]},
        {"name":"Bodyweight Squats","sets":3,"reps":"15-20","rest":60,"emoji":"🦵","color":"#6dc87a","duration_min":0.4,
         "desc":"Full depth every rep. Chest proud. Knees track toes. Drive through full foot.",
         "cues":["Full depth","Chest proud","Knees don't cave","Drive through full foot"]},
        {"name":"Mountain Climbers","sets":3,"reps":"20 each","rest":45,"emoji":"⛰️","color":"#f5a623","duration_min":0.35,
         "desc":"High plank, drive knees alternately. Hips level. Core endurance.",
         "cues":["Hips level","Drive knee fully","Controlled pace","Shoulders over wrists"]},
        {"name":"Glute Bridges","sets":3,"reps":"15-20","rest":45,"emoji":"🌉","color":"#ff4444","duration_min":0.35,
         "desc":"On back, feet flat. Max glute squeeze at top. 2-second hold. Lower slowly.",
         "cues":["Drive hips up","Max glute squeeze","2-second hold","Lower slowly"]},
    ],
}

# ─── CALORIE ESTIMATION ──────────────────────────────────────────────────────
def estimate_calories(user_metrics, intensity, total_sets, num_exercises):
    """
    Mifflin-St Jeor BMR × activity factor gives TDEE.
    For workout calorie burn we use MET × weight × duration.
    MET values per intensity: beginner=3.5, intermediate=5.0, advanced=6.5, athlete=8.0
    """
    weight_kg = user_metrics.get("weight_kg", 70)
    age       = user_metrics.get("age", 25)
    height_cm = user_metrics.get("height_cm", 170)
    gender    = user_metrics.get("gender", "male")
    met       = INTENSITY_CONFIG.get(intensity, INTENSITY_CONFIG["intermediate"])["met"]

    # Estimate workout duration in minutes (avg 40s per set + rest)
    avg_rest_sec = INTENSITY_CONFIG.get(intensity, {}).get("rest_mult", 1.0) * 60
    est_duration_min = total_sets * (0.67 + avg_rest_sec / 60)

    # Calories = MET × weight_kg × duration_hours
    kcal = met * weight_kg * (est_duration_min / 60)
    return round(kcal)

def predict_weight_change(kcal_burned, weight_kg):
    """1 kg fat ≈ 7700 kcal. Returns kg lost (negative = loss)."""
    kg_change = -(kcal_burned / 7700)
    return round(kg_change, 4)

# ─── HELPERS ─────────────────────────────────────────────────────────────────
def load_users():
    if os.path.exists(USERS_FILE):
        try:
            with open(USERS_FILE) as f:
                return json.load(f)
        except Exception:
            pass
    return {}

def save_users(users):
    with open(USERS_FILE, "w") as f:
        json.dump(users, f, indent=2)

def hash_pw(pw):
    return hashlib.sha256(pw.encode()).hexdigest()

def current_user():
    uid = session.get("user_id")
    if not uid:
        return None, None
    users = load_users()
    return uid, users.get(uid)

def get_week_key():
    today = datetime.date.today()
    return (today - datetime.timedelta(days=today.weekday())).isoformat()

def today_key():
    return datetime.date.today().isoformat()

def apply_intensity(exercises, intensity):
    cfg = INTENSITY_CONFIG.get(intensity, INTENSITY_CONFIG["intermediate"])
    result = []
    for ex in exercises:
        e = dict(ex)
        e["sets"] = max(1, round(ex["sets"] * cfg["sets_mult"]))
        e["rest"]  = max(20, round(ex["rest"]  * cfg["rest_mult"]))
        result.append(e)
    return result

def pick_daily_quizzes(seed_date=None):
    d = seed_date or today_key()
    rng = random.Random(d)
    return rng.sample(QUIZ_BANK, 3)

def default_user_data(uid, email, name, password):
    return {
        "id":uid,"email":email,"name":name,"password":password,
        "setup":False,
        "days_per_week":3,"muscle_groups":[],"intensity":"intermediate","plan":[],
        "streak":0,"best_streak":0,"streak_at_risk":False,
        "gems":0,"shields":0,
        "total_sessions":0,"history":[],
        "week_done":{},"last_week":None,
        # challenges
        "quiz_completed_today":[],"quiz_date":None,
        "quiz_lives":CHALLENGE_LIVES,"quiz_lives_date":None,
        # bonus
        "bonus_workout_date":None,"bonus_workouts_today":0,
        # body metrics
        "metrics":{"weight_kg":None,"height_cm":None,"age":None,"gender":"male"},
        "weight_log":[],   # [{date, weight_kg, kcal_burned, predicted_kg}]
        "created_at":datetime.date.today().isoformat(),
    }

def check_streak_continuity(user):
    completed = len(user.get("week_done", {}))
    goal      = user.get("days_per_week", 3)
    if completed < goal and user.get("streak", 0) > 0:
        user["streak"] = 0
        user["streak_at_risk"] = False
    return user

# ─── AUTH ─────────────────────────────────────────────────────────────────────
@app.route("/api/auth/signup", methods=["POST"])
def signup():
    body  = request.json or {}
    email = (body.get("email") or "").strip().lower()
    pw    = body.get("password") or ""
    name  = (body.get("name") or "").strip()
    if not email or not pw or not name:
        return jsonify({"error":"All fields are required"}), 400
    if len(pw) < 6:
        return jsonify({"error":"Password must be at least 6 characters"}), 400
    users = load_users()
    if any(u["email"] == email for u in users.values()):
        return jsonify({"error":"Email already registered"}), 409
    uid = str(uuid.uuid4())
    users[uid] = default_user_data(uid, email, name, hash_pw(pw))
    save_users(users)
    session["user_id"] = uid
    return jsonify({"ok":True,"name":name})

@app.route("/api/auth/login", methods=["POST"])
def login():
    body  = request.json or {}
    email = (body.get("email") or "").strip().lower()
    pw    = body.get("password") or ""
    users = load_users()
    for uid, u in users.items():
        if u["email"] == email and u["password"] == hash_pw(pw):
            session["user_id"] = uid
            wk = get_week_key()
            if u.get("last_week") != wk:
                u = check_streak_continuity(u)
                u["week_done"] = {}
                u["last_week"] = wk
                users[uid] = u
                save_users(users)
            return jsonify({"ok":True,"name":u["name"],"setup":u.get("setup",False)})
    return jsonify({"error":"Invalid email or password"}), 401

@app.route("/api/auth/logout", methods=["POST"])
def logout():
    session.clear()
    return jsonify({"ok":True})

@app.route("/api/auth/me")
def me():
    uid, user = current_user()
    if not user:
        return jsonify({"logged_in":False})
    return jsonify({"logged_in":True,"name":user["name"],"email":user["email"],"setup":user.get("setup",False)})

# ─── MAIN ROUTES ──────────────────────────────────────────────────────────────
@app.route("/")
def index():
    return render_template("index.html")

@app.route("/api/state")
def get_state():
    uid, user = current_user()
    if not user:
        return jsonify({"error":"Not logged in"}), 401
    users = load_users()
    wk = get_week_key()
    if user.get("last_week") != wk:
        user = check_streak_continuity(user)
        user["week_done"] = {}
        user["last_week"] = wk
        users[uid] = user
        save_users(users)
    # Reset quiz lives daily
    td = today_key()
    if user.get("quiz_lives_date") != td:
        user["quiz_lives"] = CHALLENGE_LIVES
        user["quiz_lives_date"] = td
        users[uid] = user
        save_users(users)
    safe = {k:v for k,v in user.items() if k != "password"}
    safe.update({
        "gems_per_workout":GEMS_PER_WORKOUT,"shield_cost":SHIELD_COST,"shield_max":SHIELD_MAX,
        "bonus_workout_cost":BONUS_WORKOUT_COST,"challenge_limit":CHALLENGE_DAILY_LIMIT,
        "gem_packages":GEM_PACKAGES,"revive_cost":REVIVE_COST,
    })
    return jsonify(safe)

@app.route("/api/setup", methods=["POST"])
def setup():
    uid, user = current_user()
    if not user:
        return jsonify({"error":"Not logged in"}), 401
    body = request.json or {}
    user["setup"]         = True
    user["days_per_week"] = body["days_per_week"]
    user["muscle_groups"] = body["muscle_groups"]
    user["intensity"]     = body.get("intensity","intermediate")
    groups = body["muscle_groups"]
    user["plan"] = [groups[i % len(groups)] for i in range(body["days_per_week"])]
    users = load_users()
    users[uid] = user
    save_users(users)
    return jsonify({"ok":True})

@app.route("/api/profile", methods=["POST"])
def update_profile():
    uid, user = current_user()
    if not user:
        return jsonify({"error":"Not logged in"}), 401
    body = request.json or {}
    if "name" in body and body["name"].strip():
        user["name"] = body["name"].strip()
    if "days_per_week" in body:
        user["days_per_week"] = int(body["days_per_week"])
    if "muscle_groups" in body and body["muscle_groups"]:
        user["muscle_groups"] = body["muscle_groups"]
    if "intensity" in body:
        user["intensity"] = body["intensity"]
    groups = user.get("muscle_groups", [])
    if groups:
        user["plan"] = [groups[i % len(groups)] for i in range(user["days_per_week"])]
    users = load_users()
    users[uid] = user
    save_users(users)
    return jsonify({"ok":True})

@app.route("/api/metrics", methods=["POST"])
def update_metrics():
    uid, user = current_user()
    if not user:
        return jsonify({"error":"Not logged in"}), 401
    body = request.json or {}
    m = user.get("metrics", {})
    if "weight_kg" in body and body["weight_kg"]:
        m["weight_kg"] = float(body["weight_kg"])
    if "height_cm" in body and body["height_cm"]:
        m["height_cm"] = float(body["height_cm"])
    if "age" in body and body["age"]:
        m["age"] = int(body["age"])
    if "gender" in body:
        m["gender"] = body["gender"]
    user["metrics"] = m
    # Log current weight
    if m.get("weight_kg"):
        td = today_key()
        wl = user.get("weight_log", [])
        existing = next((x for x in wl if x["date"] == td), None)
        if not existing:
            wl.append({"date":td,"weight_kg":m["weight_kg"],"kcal_burned":0,"predicted_kg":m["weight_kg"]})
            user["weight_log"] = wl
    users = load_users()
    users[uid] = user
    save_users(users)
    return jsonify({"ok":True,"metrics":m})

@app.route("/api/progress/weight_log")
def weight_log():
    uid, user = current_user()
    if not user:
        return jsonify({"error":"Not logged in"}), 401
    log = user.get("weight_log", [])
    # Last 30 entries
    return jsonify({"log":log[-30:],"metrics":user.get("metrics",{})})

@app.route("/api/workout/today")
def get_today_workout():
    uid, user = current_user()
    if not user:
        return jsonify({"error":"Not logged in"}), 401
    dow   = datetime.date.today().weekday()
    plan  = user.get("plan", [])
    if not plan:
        return jsonify({"error":"No plan"}), 400
    group     = plan[dow % len(plan)]
    intensity = user.get("intensity","intermediate")
    exercises = apply_intensity(WORKOUTS.get(group,[]), intensity)
    already_done = str(dow) in user.get("week_done",{})
    gems_reward  = GEMS_PER_WORKOUT + INTENSITY_CONFIG[intensity]["gems_bonus"]
    td = today_key()
    bonus_done = user.get("bonus_workouts_today",0) if user.get("bonus_workout_date")==td else 0
    return jsonify({
        "group":group,"exercises":exercises,"already_done":already_done,"dow":dow,
        "intensity":intensity,"days_done":len(user.get("week_done",{})),
        "days_per_week":user.get("days_per_week",3),"gems_reward":gems_reward,
        "bonus_cost":BONUS_WORKOUT_COST,"bonus_done":bonus_done,
    })

@app.route("/api/workout/complete", methods=["POST"])
def complete_workout():
    uid, user = current_user()
    if not user:
        return jsonify({"error":"Not logged in"}), 401
    dow       = datetime.date.today().weekday()
    week_done = user.get("week_done",{})
    body      = request.json or {}
    is_bonus  = body.get("is_bonus", False)
    total_sets = body.get("sets", 10)
    num_ex     = body.get("exercises", 5)
    intensity  = user.get("intensity","intermediate")
    gems_earned = 0

    # Calorie calculation
    metrics = user.get("metrics",{})
    kcal = 0
    if metrics.get("weight_kg"):
        kcal = estimate_calories(metrics, intensity, total_sets, num_ex)
        kg_change = predict_weight_change(kcal, metrics["weight_kg"])
        # Update weight log
        td = today_key()
        wl = user.get("weight_log",[])
        entry = next((x for x in wl if x["date"]==td), None)
        if entry:
            entry["kcal_burned"] = entry.get("kcal_burned",0) + kcal
            cur_w = entry.get("weight_kg", metrics["weight_kg"])
            entry["predicted_kg"] = round(cur_w + kg_change, 2)
        else:
            base_w = metrics["weight_kg"]
            wl.append({"date":td,"weight_kg":base_w,"kcal_burned":kcal,
                        "predicted_kg":round(base_w+kg_change,2)})
        user["weight_log"] = wl

    if is_bonus:
        gems_earned = GEMS_PER_WORKOUT + INTENSITY_CONFIG[intensity]["gems_bonus"]
        user["gems"] = user.get("gems",0) + gems_earned
        user["total_sessions"] = user.get("total_sessions",0) + 1
        td = today_key()
        user["bonus_workout_date"] = td
        user["bonus_workouts_today"] = user.get("bonus_workouts_today",0)+1
    elif str(dow) not in week_done:
        week_done[str(dow)] = True
        user["week_done"]      = week_done
        user["total_sessions"] = user.get("total_sessions",0)+1
        gems_earned = GEMS_PER_WORKOUT + INTENSITY_CONFIG[intensity]["gems_bonus"]
        user["gems"] = user.get("gems",0) + gems_earned
        days_done = len(week_done)
        goal      = user.get("days_per_week",3)
        if days_done >= goal:
            user["streak"]      = user.get("streak",0)+1
            user["best_streak"] = max(user.get("best_streak",0), user["streak"])
            user["streak_at_risk"] = False
        else:
            user["streak_at_risk"] = True

    user.setdefault("history",[]).append({
        "date":datetime.date.today().strftime("%b %d, %Y"),
        "group":body.get("group",""),"exercises":num_ex,"sets":total_sets,
        "intensity":intensity,"gems":gems_earned,"kcal":kcal,"bonus":is_bonus,
    })
    users = load_users()
    users[uid] = user
    save_users(users)
    return jsonify({
        "streak":user["streak"],"best_streak":user["best_streak"],
        "gems":user["gems"],"gems_earned":gems_earned,"shields":user.get("shields",0),
        "days_done":len(user["week_done"]),"days_goal":user.get("days_per_week",3),
        "streak_at_risk":user.get("streak_at_risk",False),"kcal":kcal,
    })

@app.route("/api/workout/bonus_unlock", methods=["POST"])
def bonus_unlock():
    uid, user = current_user()
    if not user:
        return jsonify({"error":"Not logged in"}), 401
    body = request.json or {}
    method = body.get("method","gems")  # "gems" or "ad"
    if method == "gems":
        if user.get("gems",0) < BONUS_WORKOUT_COST:
            return jsonify({"error":f"Need {BONUS_WORKOUT_COST} gems. You have {user.get('gems',0)}"}), 400
        user["gems"] -= BONUS_WORKOUT_COST
    # "ad" method: trust client that ad was shown (in prod, verify with ad network token)
    users = load_users()
    users[uid] = user
    save_users(users)
    return jsonify({"ok":True,"gems":user.get("gems",0)})

# ─── QUIZZES ──────────────────────────────────────────────────────────────────
@app.route("/api/quiz/today")
def get_quizzes():
    uid, user = current_user()
    if not user:
        return jsonify({"error":"Not logged in"}), 401
    td = today_key()
    if user.get("quiz_date") != td:
        user["quiz_completed_today"] = []
        user["quiz_date"] = td
        users = load_users()
        users[uid] = user
        save_users(users)
    if user.get("quiz_lives_date") != td:
        user["quiz_lives"] = CHALLENGE_LIVES
        user["quiz_lives_date"] = td
        users = load_users()
        users[uid] = user
        save_users(users)
    quizzes = pick_daily_quizzes(td)
    completed = user.get("quiz_completed_today",[])
    lives = user.get("quiz_lives", CHALLENGE_LIVES)
    for q in quizzes:
        q["completed"] = q["id"] in completed
        q["options_only"] = q["options"]  # don't send answer
        q.pop("answer", None)
    return jsonify({
        "quizzes":quizzes,"completed_count":len(completed),
        "limit":CHALLENGE_DAILY_LIMIT,"lives":lives,"max_lives":CHALLENGE_LIVES,
    })

@app.route("/api/quiz/answer", methods=["POST"])
def answer_quiz():
    uid, user = current_user()
    if not user:
        return jsonify({"error":"Not logged in"}), 401
    body = request.json or {}
    qid     = body.get("quiz_id")
    answer  = body.get("answer")  # index
    td      = today_key()
    if user.get("quiz_lives_date") != td:
        user["quiz_lives"] = CHALLENGE_LIVES
        user["quiz_lives_date"] = td
    if user.get("quiz_date") != td:
        user["quiz_completed_today"] = []
        user["quiz_date"] = td
    lives     = user.get("quiz_lives", CHALLENGE_LIVES)
    completed = user.get("quiz_completed_today",[])
    if lives <= 0:
        return jsonify({"error":"No lives remaining. Watch an ad or use gems to revive.","lives":0}), 400
    if len(completed) >= CHALLENGE_DAILY_LIMIT:
        return jsonify({"error":"Daily quiz limit reached"}), 400
    quiz = next((q for q in QUIZ_BANK if q["id"]==qid), None)
    if not quiz:
        return jsonify({"error":"Quiz not found"}), 404
    if qid in completed:
        return jsonify({"error":"Already completed"}), 400
    correct = (answer == quiz["answer"])
    gems_earned = 0
    if correct:
        completed.append(qid)
        user["quiz_completed_today"] = completed
        gems_earned = quiz["gems"]
        user["gems"] = user.get("gems",0) + gems_earned
    else:
        user["quiz_lives"] = lives - 1
    users = load_users()
    users[uid] = user
    save_users(users)
    return jsonify({
        "correct":correct,"lives":user["quiz_lives"],"gems_earned":gems_earned,
        "gems":user.get("gems",0),"explanation":quiz["explanation"],
        "correct_answer":quiz["answer"],
    })

@app.route("/api/quiz/revive", methods=["POST"])
def revive_quiz():
    uid, user = current_user()
    if not user:
        return jsonify({"error":"Not logged in"}), 401
    body   = request.json or {}
    method = body.get("method","gems")
    if method == "gems":
        if user.get("gems",0) < REVIVE_COST:
            return jsonify({"error":f"Need {REVIVE_COST} gems. You have {user.get('gems',0)}"}), 400
        user["gems"] -= REVIVE_COST
    user["quiz_lives"]      = CHALLENGE_LIVES
    user["quiz_lives_date"] = today_key()
    users = load_users()
    users[uid] = user
    save_users(users)
    return jsonify({"ok":True,"lives":CHALLENGE_LIVES,"gems":user.get("gems",0)})

# ─── GEMS & STORE ────────────────────────────────────────────────────────────
@app.route("/api/gems/buy_shield", methods=["POST"])
def buy_shield():
    uid, user = current_user()
    if not user:
        return jsonify({"error":"Not logged in"}), 401
    if user.get("shields",0) >= SHIELD_MAX:
        return jsonify({"error":f"Max {SHIELD_MAX} shields allowed"}), 400
    if user.get("gems",0) < SHIELD_COST:
        return jsonify({"error":f"Need {SHIELD_COST} gems. You have {user.get('gems',0)}"}), 400
    user["gems"]    -= SHIELD_COST
    user["shields"] = user.get("shields",0)+1
    users = load_users()
    users[uid] = user
    save_users(users)
    return jsonify({"ok":True,"gems":user["gems"],"shields":user["shields"]})

@app.route("/api/gems/use_shield", methods=["POST"])
def use_shield():
    uid, user = current_user()
    if not user:
        return jsonify({"error":"Not logged in"}), 401
    if user.get("shields",0) < 1:
        return jsonify({"error":"No shields available"}), 400
    user["shields"] -= 1
    user["streak_at_risk"] = False
    user["streak"]      = user.get("streak",0)+1
    user["best_streak"] = max(user.get("best_streak",0), user["streak"])
    users = load_users()
    users[uid] = user
    save_users(users)
    return jsonify({"ok":True,"streak":user["streak"],"shields":user["shields"]})

@app.route("/api/gems/purchase", methods=["POST"])
def purchase_gems():
    uid, user = current_user()
    if not user:
        return jsonify({"error":"Not logged in"}), 401
    body    = request.json or {}
    pkg     = next((p for p in GEM_PACKAGES if p["id"]==body.get("package_id")), None)
    if not pkg:
        return jsonify({"error":"Invalid package"}), 400
    user["gems"] = user.get("gems",0) + pkg["gems"]
    users = load_users()
    users[uid] = user
    save_users(users)
    return jsonify({"ok":True,"gems":user["gems"],"gems_added":pkg["gems"],"package":pkg["label"]})

@app.route("/api/reset", methods=["POST"])
def reset_user():
    uid, user = current_user()
    if not user:
        return jsonify({"error":"Not logged in"}), 401
    users = load_users()
    users[uid].update({
        "setup":False,"days_per_week":3,"muscle_groups":[],"intensity":"intermediate","plan":[],
        "streak":0,"best_streak":0,"streak_at_risk":False,"gems":0,"shields":0,
        "total_sessions":0,"history":[],"week_done":{},"last_week":None,
        "quiz_completed_today":[],"quiz_date":None,"quiz_lives":CHALLENGE_LIVES,"quiz_lives_date":None,
        "bonus_workout_date":None,"bonus_workouts_today":0,
        "weight_log":[],"metrics":{"weight_kg":None,"height_cm":None,"age":None,"gender":"male"},
    })
    save_users(users)
    return jsonify({"ok":True})

if __name__ == "__main__":
    print("\n🏋️  STREAK — Calisthenics App  v5")
    print("━"*40)
    print("▶  Open: http://localhost:5000")
    print("━"*40+"\n")
    app.run(debug=True, port=5000)