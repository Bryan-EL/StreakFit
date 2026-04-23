"""
StreakFit — Calisthenics App v1
Run:   python app.py
Open:  http://localhost:5000
"""

from flask import Flask, render_template, jsonify, request, session
import json, os, datetime, hashlib, uuid, random, re

app = Flask(__name__)
app.secret_key = "streakfit_v1_xk92_secret"
DATA_DIR   = os.path.dirname(os.path.abspath(__file__))
USERS_FILE = os.path.join(DATA_DIR, "users.json")

# ─── ECONOMY ──────────────────────────────────────────────────────────
GEMS_PER_WORKOUT   = 10
WEEK_REWARD        = 50      # bonus gems for completing weekly goal
SHIELD_COST        = 150
SHIELD_MAX         = 2       # max 2 shields
BONUS_COST         = 40
REVIVE_COST        = 50
QUIZ_LIVES         = 2
QUIZ_DAILY_LIMIT   = 1       # 1 quiz per day only
AD_GEMS_REWARD     = 30      # gems earned from daily ad in store
AD_GEMS_LIMIT      = 1       # once per day

# ─── GEM PACKAGES ─────────────────────────────────────────────────────
GEM_PACKAGES = [
    {"id":"starter",  "gems":50,  "price":"Rp 15.000",  "usd":"$0.99",  "label":"Starter",  "popular":False},
    {"id":"boost",    "gems":150, "price":"Rp 39.000",  "usd":"$2.99",  "label":"Boost",    "popular":True},
    {"id":"power",    "gems":350, "price":"Rp 79.000",  "usd":"$6.99",  "label":"Power",    "popular":False},
    {"id":"champion", "gems":800, "price":"Rp 159.000", "usd":"$14.99", "label":"Champion", "popular":False},
]

# ─── TRAINING PROGRAMS ────────────────────────────────────────────────
TRAINING_PROGRAMS = [
    {
        "id":"jump_vertical","title":"Jump & Vertical","emoji":"🦘","cost":350,
        "color":"#c8f55a","tagline":"Add inches to your vertical leap",
        "description":"4-week progressive plyometric program targeting explosive power, calf strength, and fast-twitch muscle activation. No equipment needed.",
        "weeks":4,"level":"Intermediate",
        "workouts":[
            {"week":1,"focus":"Foundation","exercises":["Box Jump Simulation x10","Calf Raises x25","Squat Jumps x10","Wall Sit 45s","Ankle Hops x30"]},
            {"week":2,"focus":"Power Base","exercises":["Depth Drop Simulation x8","Single-leg Calf Raises x20","Jump Squats x12","Broad Jumps x8","Tuck Jumps x8"]},
            {"week":3,"focus":"Explosive Strength","exercises":["Bounding Lunges x10","Explosive Push-ups x10","Reactive Jump Squats x12","Sprint in Place 20s","Plyometric Lunges x10"]},
            {"week":4,"focus":"Max Effort","exercises":["Max Height Jump x5","Single-leg Squat Simulation x8","Fast Feet Drill 15s","Squat Hold + Explode x10","Calf Complex x30"]},
        ],
    },
    {
        "id":"handstand","title":"Handstand Progression","emoji":"🤸","cost":450,
        "color":"#5ab4ff","tagline":"Build your freestanding handstand",
        "description":"4-week systematic progression from wall handstand to freestanding balance. Builds shoulder strength, wrist stability, and body awareness.",
        "weeks":4,"level":"Advanced",
        "workouts":[
            {"week":1,"focus":"Wrist & Shoulder Prep","exercises":["Wrist Circles x20","Pike Push-ups x10","Wall Handstand Hold 20s","Shoulder Taps x15","Hollow Body Hold 30s"]},
            {"week":2,"focus":"Wall Work","exercises":["Wall Handstand Hold 30s","Chest-to-Wall Handstand 20s","Pike Shoulder Press x8","Hollow Body 30s","Handstand Shrugs x10"]},
            {"week":3,"focus":"Balance Training","exercises":["Wall Kick-up Practice x10","One-arm Wall Touch x8","Handstand Wall Walk x5","Pike Balance Hold 15s","Planche Lean 10s"]},
            {"week":4,"focus":"Freestanding Attempts","exercises":["Kick-up to Freestand x10","Tuck Handstand 5s","Pike to Handstand x8","Handstand Holds","Handstand Push-up Negatives x5"]},
        ],
    },
    {
        "id":"explosive_hiit","title":"Explosive HIIT","emoji":"⚡","cost":300,
        "color":"#f5a623","tagline":"Maximum calorie burn, zero equipment",
        "description":"3-week high-intensity interval training combining strength and cardio. 20-minute sessions designed to spike your heart rate and build lean muscle.",
        "weeks":3,"level":"Intermediate",
        "workouts":[
            {"week":1,"focus":"Base Conditioning","exercises":["Burpees x10","Mountain Climbers 30s","Jump Squats x12","High Knees 20s","Push-up to T-rotation x8"]},
            {"week":2,"focus":"Intensity Build","exercises":["Burpee Broad Jumps x8","Spiderman Push-ups x10","Jump Lunge x10","Bear Crawl 10m","Plank to Down-dog x10"]},
            {"week":3,"focus":"Peak Output","exercises":["Tuck Jump Burpees x8","Explosive Push-ups x12","Lateral Bounds x10","Plyometric Lunge x12","Hollow Rock 20s"]},
        ],
    },
    {
        "id":"mobility","title":"Mobility & Flexibility","emoji":"🧘","cost":250,
        "color":"#5dd87a","tagline":"Move better, recover faster",
        "description":"3-week daily mobility routine targeting hips, thoracic spine, shoulders, and hamstrings. Reduces injury risk and improves performance.",
        "weeks":3,"level":"Beginner",
        "workouts":[
            {"week":1,"focus":"Hip Opening","exercises":["Hip 90-90 Stretch 60s","Pigeon Pose 45s each","Deep Squat Hold 30s","Hip Flexor Lunge 45s","Supine Twist 30s each"]},
            {"week":2,"focus":"Thoracic Mobility","exercises":["Thread the Needle x10","Cat-Cow x15","Seated T-spine Rotation x10","Chest Opener 45s","Puppy Pose 45s"]},
            {"week":3,"focus":"Hamstrings & Posterior","exercises":["Standing Forward Fold 60s","Seated Hamstring Stretch 60s","Single-leg RDL Hold 30s","Inchworm x8","World's Greatest Stretch x5"]},
        ],
    },
    {
        "id":"pistol_squat","title":"Pistol Squat Mastery","emoji":"🎯","cost":400,
        "color":"#ff4455","tagline":"Master the ultimate leg challenge",
        "description":"3-week progressive program building the strength, balance, and flexibility needed for a full pistol squat.",
        "weeks":3,"level":"Advanced",
        "workouts":[
            {"week":1,"focus":"Single-leg Foundation","exercises":["Single-leg Balance 30s","Assisted Pistol x8","Bulgarian Split Squat x10","Single-leg Glute Bridge x15","Ankle Mobility x20"]},
            {"week":2,"focus":"Depth & Control","exercises":["Box Pistol Squat x8","Single-leg Eccentric Squat 5s x6","Shrimp Squat x8","Step-up Balance x10","Cossack Squat x10"]},
            {"week":3,"focus":"Full Range","exercises":["Assisted Pistol Full ROM x8","Dragon Squat x5","Slow Pistol Negative x6","Single-leg Jump x8","Pistol Hold 5s x5"]},
        ],
    },
]

# ─── INTENSITY ────────────────────────────────────────────────────────
INTENSITY_CONFIG = {
    "beginner":     {"sets_mult":0.75,"rest_mult":1.4, "label":"Beginner",    "gems_bonus":0,  "met":3.5},
    "intermediate": {"sets_mult":1.0, "rest_mult":1.0, "label":"Intermediate","gems_bonus":5,  "met":5.0},
    "advanced":     {"sets_mult":1.25,"rest_mult":0.75,"label":"Advanced",    "gems_bonus":10, "met":6.5},
    "athlete":      {"sets_mult":1.5, "rest_mult":0.6, "label":"Athlete",     "gems_bonus":20, "met":8.0},
}

# ─── QUIZ BANK (60 questions, easy + varied) ──────────────────────────
QUIZ_BANK = [
    # --- Muscle anatomy ---
    {"id":"q001","q":"Push-ups primarily work which muscle?","opts":["Biceps","Chest","Quads","Hamstrings"],"a":1,"exp":"Push-ups load the chest (pectoralis major), triceps, and front deltoids."},
    {"id":"q002","q":"Squats primarily train which muscle group?","opts":["Shoulders","Back","Legs & glutes","Arms"],"a":2,"exp":"Squats are a compound lower-body movement targeting quads, glutes, and hamstrings."},
    {"id":"q003","q":"The plank is mainly a __ exercise.","opts":["Strength","Cardio","Core stability","Flexibility"],"a":2,"exp":"The plank builds anti-rotation and anti-extension core stability."},
    {"id":"q004","q":"Diamond push-ups target which area more than regular push-ups?","opts":["Outer chest","Inner chest & triceps","Lower back","Biceps"],"a":1,"exp":"The narrow hand position loads the inner chest and triceps more heavily."},
    {"id":"q005","q":"Glute bridges primarily work the __","opts":["Quadriceps","Calves","Glutes & hamstrings","Chest"],"a":2,"exp":"Hip extension through glute bridges directly targets the gluteus maximus and hamstrings."},
    {"id":"q006","q":"Mountain climbers train mainly which muscles?","opts":["Arms & chest","Core & hip flexors","Lower back","Calves"],"a":1,"exp":"Mountain climbers challenge core stability and hip flexors dynamically."},
    {"id":"q007","q":"Pike push-ups primarily work the __","opts":["Chest","Triceps","Shoulders (deltoids)","Lats"],"a":2,"exp":"The inverted V position shifts load heavily onto the front deltoids."},
    {"id":"q008","q":"Superman holds train which area?","opts":["Abs","Posterior chain (back & glutes)","Chest","Biceps"],"a":1,"exp":"The prone lift engages erector spinae, glutes, and posterior shoulder muscles."},
    {"id":"q009","q":"Which muscle straightens the elbow?","opts":["Biceps","Triceps","Deltoid","Trapezius"],"a":1,"exp":"The triceps brachii is the primary elbow extensor."},
    {"id":"q010","q":"Which muscle bends the knee?","opts":["Quadriceps","Hamstrings","Calves","Hip flexors"],"a":1,"exp":"The hamstrings flex the knee joint."},
    # --- Exercise technique ---
    {"id":"q011","q":"In a correct squat your knees should track __","opts":["Inward","Straight forward regardless","Over the toes","Behind the heels"],"a":2,"exp":"Knees should track in line with the toes to protect the knee joint."},
    {"id":"q012","q":"During a push-up your body should form __","opts":["An arch","A rigid straight line","A V-shape","A C-curve"],"a":1,"exp":"A rigid plank from head to heel protects the lower back and maximises activation."},
    {"id":"q013","q":"Feet elevated in a push-up shifts load to the __","opts":["Lower chest","Upper chest","Triceps only","Biceps"],"a":1,"exp":"Decline push-ups (feet up) angle force toward the clavicular (upper) head of the pectoralis."},
    {"id":"q014","q":"In a lunge, your front shin should be __","opts":["Angled forward","Vertical (perpendicular to floor)","Angled backward","Parallel to the floor"],"a":1,"exp":"A vertical shin keeps the knee over the ankle and reduces joint stress."},
    {"id":"q015","q":"What does 'full range of motion' mean?","opts":["Moving as fast as possible","Moving through the complete joint range","Using the heaviest weight","Doing as many reps as possible"],"a":1,"exp":"Full ROM means the joint travels through its entire available movement, maximising muscle stretch and contraction."},
    {"id":"q016","q":"The 'eccentric' phase of a push-up is when you __","opts":["Push up","Lower down","Rest at the bottom","Jump up"],"a":1,"exp":"Eccentric = the muscle lengthens under load. Lowering is the eccentric phase of a push-up."},
    {"id":"q017","q":"Hollow body hold requires your lower back to be __","opts":["Arched off the floor","Flat/pressed into the floor","Slightly off the floor","Does not matter"],"a":1,"exp":"The lower back must stay flat. If it arches you've lost the hollow position."},
    {"id":"q018","q":"'Scapular depression' means __","opts":["Shoulder blades going up","Shoulder blades going down","Shoulder blades going apart","Shoulder blades rotating"],"a":1,"exp":"Depression = pressing the scapulae downward. Important for shoulder stability in overhead movements."},
    {"id":"q019","q":"A slow descent (eccentric) during exercise generally __","opts":["Reduces muscle gains","Increases time under tension","Has no effect","Causes injury"],"a":1,"exp":"Slower eccentrics increase time-under-tension, a key driver of muscle growth."},
    {"id":"q020","q":"To progress a push-up when it gets easy, you should __","opts":["Do fewer reps","Add a harder variation","Rest more","Reduce sets"],"a":1,"exp":"Progressive overload — moving to harder variations like archer or one-arm push-ups keeps driving adaptation."},
    # --- Recovery & rest ---
    {"id":"q021","q":"Muscle soreness 24–48 hrs after training is called __","opts":["Injury","DOMS","Cramp","Tendinitis"],"a":1,"exp":"DOMS = Delayed Onset Muscle Soreness — normal micro-damage from training that signals adaptation."},
    {"id":"q022","q":"Most adults need __ sleep for optimal muscle recovery.","opts":["4–5 hrs","5–6 hrs","7–9 hrs","10–12 hrs"],"a":2,"exp":"7–9 hrs is the recommended range. Growth hormone — critical for repair — peaks during deep sleep."},
    {"id":"q023","q":"Active recovery means __","opts":["Complete rest","Light activity like walking or stretching","Intense exercise","Sleeping all day"],"a":1,"exp":"Light movement increases blood flow and speeds up metabolite clearance without adding stress."},
    {"id":"q024","q":"Recommended rest between strength sets is __","opts":["10–20 sec","30–60 sec","1–3 min","5–10 min"],"a":2,"exp":"1–3 minutes allows partial ATP replenishment for near-maximal effort on the next set."},
    {"id":"q025","q":"Training the same muscle group every single day is generally __","opts":["Ideal for fastest gains","Risky — muscles need recovery time","Fine if you eat enough","Only OK for abs"],"a":1,"exp":"Most muscle groups need 48+ hrs to repair. Daily training the same muscle risks overtraining."},
    # --- Nutrition basics ---
    {"id":"q026","q":"1 gram of protein provides approximately __","opts":["2 kcal","4 kcal","7 kcal","9 kcal"],"a":1,"exp":"Protein and carbohydrates both provide ~4 kcal/g. Fat provides ~9 kcal/g."},
    {"id":"q027","q":"Which macronutrient fuels high-intensity exercise best?","opts":["Fat","Protein","Carbohydrates","Fibre"],"a":2,"exp":"Carbohydrates (stored as glycogen) are the primary fuel for anaerobic/high-intensity effort."},
    {"id":"q028","q":"Drinking water before and during exercise is important for __","opts":["Weight loss only","Performance and temperature regulation","Muscle building only","Nothing — it doesn't matter"],"a":1,"exp":"Dehydration of even 2% body weight can impair performance, focus and thermoregulation."},
    {"id":"q029","q":"Protein helps build and repair __","opts":["Bones only","Muscle tissue","Fat tissue","Organs only"],"a":1,"exp":"Dietary protein supplies amino acids needed to repair micro-tears and synthesise new muscle fibres."},
    {"id":"q030","q":"A caloric deficit means you're eating __","opts":["More calories than you burn","Fewer calories than you burn","Exactly as many as you burn","Only healthy foods"],"a":1,"exp":"Caloric deficit = intake < expenditure. Sustained deficit leads to fat loss over time."},
    # --- General fitness knowledge ---
    {"id":"q031","q":"'HIIT' stands for __","opts":["High Intensity Isometric Training","High Intensity Interval Training","Heavy Impact Incline Training","High Impact Integrated Training"],"a":1,"exp":"HIIT alternates intense effort bursts with short rest periods, boosting cardio and calorie burn efficiently."},
    {"id":"q032","q":"BMI stands for __","opts":["Body Mass Index","Bone Muscle Indicator","Basic Metabolic Index","Body Movement Intensity"],"a":0,"exp":"BMI = weight (kg) ÷ height² (m). A screening tool for weight categories, not a direct health measure."},
    {"id":"q033","q":"Flexibility training is best done __","opts":["Only before exercise","Only after exercise","Never — not needed","Both before (dynamic) and after (static)"],"a":3,"exp":"Dynamic stretching pre-workout primes joints; static stretching post-workout improves flexibility."},
    {"id":"q034","q":"How many days per week should beginners strength train?","opts":["1 day","2–3 days","5–6 days","Every day"],"a":1,"exp":"2–3 days gives beginners enough stimulus with adequate recovery between sessions."},
    {"id":"q035","q":"Consistency over time matters more than __","opts":["Sleep","One perfect workout","Nutrition","Hydration"],"a":1,"exp":"A sustainable routine across months and years outperforms any single elite session."},
    {"id":"q036","q":"Bodyweight training can build muscle. True or false?","opts":["True","False"],"a":0,"exp":"Progressive calisthenics — harder variations, more reps, slower tempo — provide sufficient stimulus for hypertrophy."},
    {"id":"q037","q":"Core strength primarily helps with __","opts":["Arm strength only","Spinal stability & force transfer","Leg speed","Lung capacity"],"a":1,"exp":"A strong core stabilises the spine, reduces injury risk, and improves force transfer in every movement."},
    {"id":"q038","q":"Which of these is NOT a benefit of regular exercise?","opts":["Better sleep","Improved mood","Instant permanent weight loss","Reduced disease risk"],"a":2,"exp":"Weight management requires sustained habit and diet. Exercise alone does not produce instant permanent loss."},
    {"id":"q039","q":"'Progressive overload' means __","opts":["Resting more over time","Gradually increasing training demand over time","Doing the same workout forever","Reducing weight to avoid injury"],"a":1,"exp":"Progressive overload — more reps, harder variations, less rest — is the fundamental principle of improvement."},
    {"id":"q040","q":"Which breathing pattern is correct during a push-up?","opts":["Hold breath the whole time","Inhale going down, exhale going up","Exhale going down, inhale going up","Breathing does not matter"],"a":1,"exp":"Inhale (eccentric/lowering), exhale (concentric/exertion). Exhaling during effort stabilises the core via the Valsalva effect."},
    # --- Warm-up / cool-down ---
    {"id":"q041","q":"Why warm up before exercise?","opts":["It burns more fat","Increases blood flow and reduces injury risk","It counts as the workout","Warms the room"],"a":1,"exp":"Warming up raises core temperature, increases synovial fluid and prepares the neuromuscular system."},
    {"id":"q042","q":"Static stretching (holding a stretch) should mainly be done __","opts":["Before intense exercise","After exercise when muscles are warm","During exercise","Never"],"a":1,"exp":"Post-workout static stretching is safer and more effective when tissues are warm and pliable."},
    {"id":"q043","q":"Dynamic warm-up includes __","opts":["Holding a stretch for 60 sec","Leg swings and arm circles","Sitting and resting","Weightlifting at full intensity"],"a":1,"exp":"Dynamic movements mimic the exercise pattern while progressively increasing range and speed."},
    # --- Mental / lifestyle ---
    {"id":"q044","q":"Building a habit takes approximately __","opts":["1–3 days","1 week","18–66+ days of consistent repetition","Exactly 21 days"],"a":2,"exp":"Research shows habit formation varies widely — 18 to 254 days depending on complexity and consistency."},
    {"id":"q045","q":"Stress can affect workout performance by __","opts":["Only improving it","Impairing recovery and motivation","Having no effect","Always causing injury"],"a":1,"exp":"Chronic stress elevates cortisol, which impairs recovery, sleep quality, and training motivation."},
    {"id":"q046","q":"Setting SMART fitness goals means goals are __","opts":["Simple, Mean, Active, Realistic, Timed","Specific, Measurable, Achievable, Relevant, Time-bound","Strong, Motivated, Accurate, Rapid, True","None of the above"],"a":1,"exp":"SMART goals dramatically increase follow-through by making progress trackable and expectations clear."},
    # --- Calorie & energy ---
    {"id":"q047","q":"Approximately how many kcal are in 1 kg of body fat?","opts":["1,000 kcal","3,500 kcal","7,700 kcal","15,000 kcal"],"a":2,"exp":"~7,700 kcal = 1 kg of fat. A 500 kcal/day deficit takes ~15 days to lose 1 kg of fat."},
    {"id":"q048","q":"TDEE stands for __","opts":["Total Daily Energy Expenditure","Timed Diet Exercise Effect","Target Dietary Energy Estimate","Total Dietary Enzyme Efficiency"],"a":0,"exp":"TDEE = all calories burned in a day: resting metabolism + activity + digestion."},
    {"id":"q049","q":"Which burns more calories per hour on average?","opts":["Walking","Running","Sitting","Sleeping"],"a":1,"exp":"Running burns roughly 2–3× more calories per hour than walking at the same body weight."},
    {"id":"q050","q":"Muscle tissue burns more calories at rest than fat tissue. True or false?","opts":["True","False"],"a":0,"exp":"Muscle is metabolically active tissue. More muscle = higher basal metabolic rate (BMR)."},
    # --- Safety ---
    {"id":"q051","q":"Pain during exercise is __","opts":["Always normal — push through it","A signal to stop and assess","Only a problem for beginners","Never experienced by fit people"],"a":1,"exp":"Sharp or joint pain signals something wrong. Muscle burn (effort) is different from pain (damage)."},
    {"id":"q052","q":"Proper posture during exercise __","opts":["Slows progress","Reduces injury risk and improves results","Has no effect","Makes it easier to cheat"],"a":1,"exp":"Correct alignment distributes forces safely and ensures the target muscle does the work."},
    {"id":"q053","q":"Before training with an injury you should __","opts":["Push through it always","Consult a professional first","Ignore the pain","Train only the injured area harder"],"a":1,"exp":"Training through injury can worsen damage. Medical clearance avoids turning a minor issue into a long-term problem."},
    # --- Fun / motivational ---
    {"id":"q054","q":"The best workout is __","opts":["The one everyone else does","The most intense one","The one you actually do consistently","Only weightlifting"],"a":2,"exp":"Adherence is the single biggest predictor of fitness results. The 'best' program is the one you stick to."},
    {"id":"q055","q":"How does exercise affect mood?","opts":["It only helps if you enjoy it","It releases endorphins that improve mood","It always makes you more tired","It has no effect on mood"],"a":1,"exp":"Exercise triggers endorphin, serotonin, and dopamine release — all proven mood enhancers."},
    {"id":"q056","q":"Floor-only (calisthenics) training can achieve __","opts":["Cardio fitness only","Strength, muscle, flexibility and cardio","Only flexibility","Nothing useful"],"a":1,"exp":"Calisthenics develops strength, hypertrophy, flexibility, coordination and cardiovascular fitness."},
    {"id":"q057","q":"Rest days are __","opts":["A sign of weakness","When muscle growth and repair actually happen","Wasted time","Only for beginners"],"a":1,"exp":"Adaptation and muscle repair happen during rest. Training provides the stimulus; rest delivers the gains."},
    {"id":"q058","q":"Tracking your workouts helps because __","opts":["It is required by law","It ensures progressive overload and keeps you accountable","It is only for professionals","It is a waste of time"],"a":1,"exp":"Logs show what's working, prevent plateaus and give a measurable sense of progress."},
    {"id":"q059","q":"Which is a compound (multi-joint) exercise?","opts":["Bicep curl","Calf raise","Push-up","Wrist curl"],"a":2,"exp":"Push-ups recruit shoulders, elbows and involve the entire torso — a compound movement."},
    {"id":"q060","q":"'Reps' means __","opts":["Rest periods","Individual repetitions of a movement","Sets of exercise","Rounds of a circuit"],"a":1,"exp":"Rep = repetition. One complete performance of a movement from start to finish."},
]

# ─── WORKOUT DATABASE ─────────────────────────────────────────────────
# All floor-only. Bonus workouts are lighter (marked bonus_ok:true), different exercises.
WORKOUTS = {
    "chest": [
        {"name":"Push-ups","sets":4,"reps":"12-15","rest":60,"emoji":"💪","color":"#c8f55a","bonus_ok":False,
         "desc":"Hands shoulder-width, lower chest to just above floor, push up explosively. Keep core and glutes locked.",
         "cues":["Shoulder-width grip","2-second descent","Chest grazes floor","Explode up — lock arms"]},
        {"name":"Wide Push-ups","sets":3,"reps":"10-12","rest":60,"emoji":"↔️","color":"#6dc87a","bonus_ok":False,
         "desc":"Hands wider than shoulders. Targets outer chest. Feel the stretch at the bottom of each rep.",
         "cues":["Past shoulder-width","Elbows flare out","Feel chest stretch","Squeeze at top"]},
        {"name":"Diamond Push-ups","sets":3,"reps":"8-10","rest":75,"emoji":"💎","color":"#5ab4ff","bonus_ok":False,
         "desc":"Diamond shape under chest. Heavy tricep and inner chest. Slow the descent.",
         "cues":["Diamond under chest","Elbows point back","Full range","3-sec descent"]},
        {"name":"Decline Push-ups","sets":3,"reps":"10-12","rest":60,"emoji":"📐","color":"#f5a623","bonus_ok":False,
         "desc":"Feet elevated on couch. Shifts load to upper chest and front deltoids.",
         "cues":["Feet elevated","Hips level","Hands below shoulders","Control down — press hard"]},
        {"name":"Slow Push-ups (3-1-1)","sets":3,"reps":"6-8","rest":90,"emoji":"🐢","color":"#ff4444","bonus_ok":False,
         "desc":"3 sec down, 1 sec pause, 1 sec up. Maximum time-under-tension. Harder than it sounds.",
         "cues":["3 sec descent","1-sec pause at bottom","1 sec press","Full body rigid"]},
    ],
    "chest_bonus": [
        {"name":"Knee Push-ups","sets":3,"reps":"15-20","rest":45,"emoji":"🤲","color":"#c8f55a","bonus_ok":True,
         "desc":"On knees instead of toes. Lighter variation — perfect for a quick bonus session.",
         "cues":["Knees on floor","Body straight from knee to head","Chest to floor","Controlled push up"]},
        {"name":"Wall Push-ups","sets":3,"reps":"20","rest":30,"emoji":"🧱","color":"#6dc87a","bonus_ok":True,
         "desc":"Standing, hands on wall. Very light — good pump without fatigue.",
         "cues":["Arms at shoulder height","Lean in slowly","Control the push back","Keep core tight"]},
        {"name":"Chest Squeeze (no equip)","sets":3,"reps":"15","rest":30,"emoji":"🤜","color":"#5ab4ff","bonus_ok":True,
         "desc":"Press palms together as hard as possible at chest height. Isometric chest squeeze.",
         "cues":["Press palms together hard","Hold 2 seconds","Release slowly","Feel the chest squeeze"]},
    ],
    "back": [
        {"name":"Superman Hold","sets":4,"reps":"15-20","rest":45,"emoji":"🦸","color":"#c8f55a","bonus_ok":False,
         "desc":"Lie face down. Lift arms, chest and legs simultaneously. Squeeze glutes hard.",
         "cues":["Fully flat on floor","Lift arms AND legs","Squeeze glutes","1-2 sec hold"]},
        {"name":"YTW Raises","sets":3,"reps":"10 each","rest":60,"emoji":"🔤","color":"#5ab4ff","bonus_ok":False,
         "desc":"Face down. Raise into Y, T then W shapes. Rear deltoids, lower traps, rotator cuff.",
         "cues":["Face down","Y — overhead 45°","T — arms sideways","W — elbows bent 90°"]},
        {"name":"Reverse Snow Angels","sets":3,"reps":"12-15","rest":60,"emoji":"🌨️","color":"#6dc87a","bonus_ok":False,
         "desc":"Face down, sweep arms overhead and back. Chest stays raised throughout.",
         "cues":["Chest off floor throughout","Sweep overhead","Return slowly","Glutes tight"]},
        {"name":"Hip Hinges","sets":3,"reps":"15-20","rest":45,"emoji":"🙇","color":"#f5a623","bonus_ok":False,
         "desc":"Hinge at hips, torso drops forward, hamstrings load. Drive hips forward to stand.",
         "cues":["Soft knee bend","Push hips BACK","Spine long","Drive hips forward"]},
        {"name":"Prone Cobra","sets":3,"reps":"12-15","rest":60,"emoji":"🐍","color":"#ff4444","bonus_ok":False,
         "desc":"Face down, lift chest using back muscles. Shoulders roll back and down.",
         "cues":["Hands under shoulders","Back muscles lift — not arms","Shoulders back","Hold 1 sec"]},
    ],
    "back_bonus": [
        {"name":"Superman Pulses","sets":3,"reps":"20","rest":30,"emoji":"✨","color":"#c8f55a","bonus_ok":True,
         "desc":"Same as superman but small pulses instead of holds. Light and effective.",
         "cues":["Face down","Small up-down pulses","Keep glutes squeezed","Controlled rhythm"]},
        {"name":"Lying Y-Raises","sets":3,"reps":"15","rest":30,"emoji":"🔤","color":"#5ab4ff","bonus_ok":True,
         "desc":"Lie face down, raise only in Y shape. Simple and light posterior chain work.",
         "cues":["Arms at 45° overhead","Lift from shoulder blades","Hold 1 sec","Lower slowly"]},
    ],
    "legs": [
        {"name":"Bodyweight Squats","sets":4,"reps":"15-20","rest":60,"emoji":"🦵","color":"#c8f55a","bonus_ok":False,
         "desc":"Hip crease below knee. Chest tall. Drive through full foot.",
         "cues":["Full depth","Chest tall","Knees over toes","Drive through full foot"]},
        {"name":"Reverse Lunges","sets":3,"reps":"12 each","rest":60,"emoji":"👟","color":"#5ab4ff","bonus_ok":False,
         "desc":"Step straight back. Back knee near floor. Front shin vertical.",
         "cues":["Step straight back","Back knee to floor","Front shin vertical","Drive through front heel"]},
        {"name":"Glute Bridges","sets":3,"reps":"15-20","rest":45,"emoji":"🌉","color":"#6dc87a","bonus_ok":False,
         "desc":"Drive hips up hard. Max glute squeeze at top. 2-sec hold. Lower slow.",
         "cues":["Drive hips up","Max glute squeeze","2-sec hold","Lower slowly"]},
        {"name":"Jump Squats","sets":3,"reps":"10-12","rest":75,"emoji":"⚡","color":"#f5a623","bonus_ok":False,
         "desc":"Full squat, explode upward. Land with bent knees.",
         "cues":["Full squat","Arm swing","Maximum height","Land soft"]},
        {"name":"Single-Leg RDL","sets":3,"reps":"10 each","rest":60,"emoji":"🦩","color":"#ff4444","bonus_ok":False,
         "desc":"Balance on one leg. Hinge at hips. Rear leg extends. Squeeze glute to return.",
         "cues":["Slight knee bend","Hips hinge — spine long","Rear leg extends","Squeeze glute to return"]},
    ],
    "legs_bonus": [
        {"name":"Calf Raises","sets":3,"reps":"25","rest":30,"emoji":"👣","color":"#c8f55a","bonus_ok":True,
         "desc":"Rise onto toes. Slow down. Simple and effective.",
         "cues":["Rise high onto toes","Hold 1 sec at top","Lower slowly","Full range"]},
        {"name":"Lateral Leg Raises","sets":3,"reps":"15 each","rest":30,"emoji":"↗️","color":"#6dc87a","bonus_ok":True,
         "desc":"Lie on side, raise top leg. Light glute med work.",
         "cues":["Lie on side","Raise leg to 45°","Hold 1 sec","Lower slowly"]},
        {"name":"Standing Hip Circles","sets":2,"reps":"10 each direction","rest":30,"emoji":"⭕","color":"#5ab4ff","bonus_ok":True,
         "desc":"Stand, draw large circles with your knee. Hip mobility and light activation.",
         "cues":["Balance on one leg","Large slow circles","Both directions","Controlled movement"]},
    ],
    "core": [
        {"name":"Plank","sets":3,"reps":"30-60 sec","rest":45,"emoji":"📏","color":"#c8f55a","bonus_ok":False,
         "desc":"Rigid line head to heel. Abs + glutes + quads all firing. Breathe.",
         "cues":["Elbows under shoulders","Rigid line head-heel","Abs+glutes+quads","Breathe steadily"]},
        {"name":"Hollow Body Hold","sets":3,"reps":"20-30 sec","rest":45,"emoji":"🚀","color":"#5ab4ff","bonus_ok":False,
         "desc":"Lower back GLUED to floor. Arms overhead, legs at 30°.",
         "cues":["Lower back flat","Arms overhead","Legs at 30°","Raise legs if back lifts"]},
        {"name":"Dead Bug","sets":3,"reps":"8-10 each","rest":45,"emoji":"🐛","color":"#6dc87a","bonus_ok":False,
         "desc":"Arms up, knees 90° in air. Extend opposite arm & leg. 3 seconds. Back flat.",
         "cues":["Back flat always","3 sec per rep","Opposite arm+leg","Never arch"]},
        {"name":"Mountain Climbers","sets":3,"reps":"20 each","rest":45,"emoji":"⛰️","color":"#f5a623","bonus_ok":False,
         "desc":"High plank. Drive knees to chest alternately. Hips LEVEL.",
         "cues":["Hips level","Drive knee to chest","Controlled","Shoulders over wrists"]},
        {"name":"Bicycle Crunches","sets":3,"reps":"15 each","rest":45,"emoji":"🚲","color":"#ff4444","bonus_ok":False,
         "desc":"Elbow past opposite knee. Extend other leg fully. Slow and controlled.",
         "cues":["Hands lightly behind head","Elbow past knee","Extend other leg fully","Slow — feel it"]},
    ],
    "core_bonus": [
        {"name":"Seated Knee Tucks","sets":3,"reps":"20","rest":30,"emoji":"🪑","color":"#c8f55a","bonus_ok":True,
         "desc":"Sit, lean back slightly, bring knees in and out. Easy core activation.",
         "cues":["Lean slightly back","Bring knees to chest","Extend out","Controlled motion"]},
        {"name":"Side Plank (each side)","sets":2,"reps":"20-30 sec each","rest":30,"emoji":"◀️","color":"#5ab4ff","bonus_ok":True,
         "desc":"Forearm side plank. Light lateral core work.",
         "cues":["Forearm on floor","Hip up — straight line","Breathe steadily","Hold the time"]},
    ],
    "shoulders": [
        {"name":"Pike Push-ups","sets":4,"reps":"8-12","rest":75,"emoji":"🔺","color":"#c8f55a","bonus_ok":False,
         "desc":"Inverted V. Lower head to floor between hands. Full arm extension at top.",
         "cues":["Hips high","Head to floor","Elbows slightly back","Full extension"]},
        {"name":"Wall Handstand Hold","sets":3,"reps":"20-30 sec","rest":90,"emoji":"🤸","color":"#5ab4ff","bonus_ok":False,
         "desc":"Kick up. Rigid hollow body. Push floor away. Eyes at floor.",
         "cues":["Hands ~30cm from wall","Hollow body","Push floor away","Eyes at floor"]},
        {"name":"Shoulder Taps","sets":3,"reps":"10 each","rest":45,"emoji":"👆","color":"#6dc87a","bonus_ok":False,
         "desc":"High plank. Tap opposite shoulder. Hips stay square.",
         "cues":["High plank feet wide","Hips square","Tap opposite shoulder","Controlled"]},
        {"name":"Pseudo Planche Lean","sets":3,"reps":"5×5 sec","rest":90,"emoji":"📐","color":"#f5a623","bonus_ok":False,
         "desc":"Push-up position, fingers out. Lean forward past hands. Extreme front delt.",
         "cues":["Fingers at 45°","Lean past hands","Round upper back","Hold 5 sec"]},
        {"name":"Pike Negatives","sets":3,"reps":"4-6","rest":90,"emoji":"⬇️","color":"#ff4444","bonus_ok":False,
         "desc":"Pike position. 6 seconds to lower. Don't press back up. Reset.",
         "cues":["6 seconds down","Count out loud","Head lightly touches","Reset"]},
    ],
    "shoulders_bonus": [
        {"name":"Arm Circles","sets":3,"reps":"15 each direction","rest":20,"emoji":"⭕","color":"#c8f55a","bonus_ok":True,
         "desc":"Large slow arm circles. Great shoulder mobility and light activation.",
         "cues":["Arms fully extended","Large circles","Both directions","Controlled"]},
        {"name":"Wall Shoulder Press","sets":3,"reps":"15","rest":30,"emoji":"🧱","color":"#6dc87a","bonus_ok":True,
         "desc":"Stand, slide arms up a wall. Light shoulder endurance.",
         "cues":["Arms on wall","Slide up slowly","Full extension","Slide back down"]},
    ],
    "full": [
        {"name":"Burpees","sets":3,"reps":"10-12","rest":75,"emoji":"💥","color":"#c8f55a","bonus_ok":False,
         "desc":"Squat → plank → push-up → jump up. Full body.",
         "cues":["Controlled squat down","Full push-up","Jump feet forward","Explosive jump"]},
        {"name":"Push-ups","sets":3,"reps":"12-15","rest":60,"emoji":"🤲","color":"#5ab4ff","bonus_ok":False,
         "desc":"Shoulder-width, chest to floor, push explosively.",
         "cues":["Shoulder-width","Chest to floor","Explode up","Core tight"]},
        {"name":"Bodyweight Squats","sets":3,"reps":"15-20","rest":60,"emoji":"🦵","color":"#6dc87a","bonus_ok":False,
         "desc":"Full depth. Chest proud. Knees track toes.",
         "cues":["Full depth","Chest proud","Knees don't cave","Drive through full foot"]},
        {"name":"Mountain Climbers","sets":3,"reps":"20 each","rest":45,"emoji":"⛰️","color":"#f5a623","bonus_ok":False,
         "desc":"High plank, drive knees alternately. Hips level.",
         "cues":["Hips level","Drive knee fully","Controlled","Shoulders over wrists"]},
        {"name":"Glute Bridges","sets":3,"reps":"15-20","rest":45,"emoji":"🌉","color":"#ff4444","bonus_ok":False,
         "desc":"Max glute squeeze at top. 2-sec hold. Lower slowly.",
         "cues":["Drive hips up","Max squeeze","2-sec hold","Lower slowly"]},
    ],
    "full_bonus": [
        {"name":"High Knees","sets":3,"reps":"20 each","rest":30,"emoji":"🏃","color":"#c8f55a","bonus_ok":True,
         "desc":"Light cardio. Drive knees above hip height alternately.",
         "cues":["Knees above hips","Arms pump","Light on feet","Steady rhythm"]},
        {"name":"Standing Oblique Crunches","sets":3,"reps":"15 each","rest":30,"emoji":"🔄","color":"#6dc87a","bonus_ok":True,
         "desc":"Stand, crunch elbow to same-side knee. Light core.",
         "cues":["Stand tall","Elbow to knee","Control the crunch","Alternate sides"]},
        {"name":"Jumping Jacks","sets":3,"reps":"25","rest":30,"emoji":"🌟","color":"#5ab4ff","bonus_ok":True,
         "desc":"Classic cardio. Arms and legs out together, back in.",
         "cues":["Jump feet out","Arms overhead","Jump back in","Steady pace"]},
    ],
}

# ─── HELPERS ──────────────────────────────────────────────────────────
def load_users():
    if os.path.exists(USERS_FILE):
        try:
            with open(USERS_FILE) as f:
                return json.load(f)
        except Exception:
            pass
    return {}

def save_users(u):
    with open(USERS_FILE, "w") as f:
        json.dump(u, f, indent=2)

def hash_pw(pw):
    return hashlib.sha256(pw.encode()).hexdigest()

def cur_user():
    uid = session.get("uid")
    if not uid:
        return None, None
    users = load_users()
    return uid, users.get(uid)

def week_key():
    d = datetime.date.today()
    return (d - datetime.timedelta(days=d.weekday())).isoformat()

def today_str():
    return datetime.date.today().isoformat()

def apply_intensity(exs, intensity):
    cfg = INTENSITY_CONFIG.get(intensity, INTENSITY_CONFIG["intermediate"])
    return [{**e, "sets":max(1,round(e["sets"]*cfg["sets_mult"])),
             "rest":max(20,round(e["rest"]*cfg["rest_mult"]))} for e in exs]

def estimate_kcal(metrics, intensity, total_sets):
    """MET × weight × duration_hours"""
    w   = float(metrics.get("weight_kg") or 70)
    met = INTENSITY_CONFIG.get(intensity, INTENSITY_CONFIG["intermediate"])["met"]
    rest_mult = INTENSITY_CONFIG.get(intensity, INTENSITY_CONFIG["intermediate"])["rest_mult"]
    dur_min = total_sets * (0.7 + rest_mult)      # rough: 42s effort + rest per set
    return round(met * w * dur_min / 60)

def check_streak(user):
    """Legacy no-op kept for call-sites. Streak is now day-based."""
    return user

def refresh_streak(user):
    """
    Call on state load. Detects missed days and sets streak_broken flag
    so the frontend can prompt the user to spend a shield or accept the loss.
    Does NOT auto-consume shields — that happens via /api/streak/resolve.
    """
    last = user.get("last_workout_date")
    if not last:
        user["streak_at_risk"] = False
        user["streak_broken"]  = False
        return user
    today = datetime.date.today()
    yesterday = (today - datetime.timedelta(days=1)).isoformat()
    today_s   = today.isoformat()
    if last == today_s:
        user["streak_at_risk"] = False
        user["streak_broken"]  = False
    elif last == yesterday:
        user["streak_at_risk"] = True
        user["streak_broken"]  = False
    else:
        # Missed at least one full day — streak is broken until resolved
        user["streak_at_risk"] = False
        user["streak_broken"]  = True
    return user

def new_user(uid, email, name, pw, metrics=None):
    return {
        "id":uid,"email":email,"name":name,"pw":hash_pw(pw),
        "setup":False,"days_per_week":3,"muscle_groups":[],"intensity":"intermediate","plan":[],
        "streak":0,"best_streak":0,"streak_at_risk":False,"streak_broken":False,
        "gems":0,"shields":0,"purchased_programs":[],
        "total_sessions":0,"history":[],
        "week_done":{},"last_week":None,"week_reward_claimed":None,
        "quiz_done_date":None,        # date of last completed quiz
        "quiz_lives":QUIZ_LIVES,"quiz_lives_date":None,
        "bonus_date":None,
        "metrics": metrics or {"weight_kg":None,"height_cm":None,"age":None,"gender":"male"},
        "weight_log":[],
        "settings":{"sound":True,"vibration":True},
        "created":today_str(),
    }

# ─── AUTH ──────────────────────────────────────────────────────────────
@app.route("/api/auth/signup", methods=["POST"])
def signup():
    b = request.json or {}
    email  = (b.get("email") or "").strip().lower()
    pw     = b.get("pw") or ""
    name   = (b.get("name") or "").strip()
    weight = b.get("weight_kg")
    height = b.get("height_cm")
    age    = b.get("age")
    gender = b.get("gender","male")
    if not email or not pw or not name:
        return jsonify({"error":"Name, email and password are required"}), 400
    if len(pw) < 6:
        return jsonify({"error":"Password must be at least 6 characters"}), 400
    users = load_users()
    if any(u["email"]==email for u in users.values()):
        return jsonify({"error":"Email already registered"}), 409
    uid = str(uuid.uuid4())
    metrics = {
        "weight_kg": float(weight) if weight else None,
        "height_cm": float(height) if height else None,
        "age":       int(age)      if age    else None,
        "gender":    gender,
    }
    u = new_user(uid, email, name, pw, metrics)
    # Seed weight log if weight given
    if metrics["weight_kg"]:
        u["weight_log"].append({"date":today_str(),"weight_kg":metrics["weight_kg"],"kcal":0,"kg_change":0})
    users[uid] = u
    save_users(users)
    session["uid"] = uid
    return jsonify({"ok":True,"name":name})

@app.route("/api/auth/login", methods=["POST"])
def login():
    b = request.json or {}
    email = (b.get("email") or "").strip().lower()
    pw    = b.get("pw") or ""
    users = load_users()
    for uid, u in users.items():
        stored_pw = u.get("pw") or u.get("password") or ""
        if u["email"]==email and stored_pw==hash_pw(pw):
            session["uid"] = uid
            wk = week_key()
            if u.get("last_week") != wk:
                u = check_streak(u)
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
    uid, u = cur_user()
    if not u:
        return jsonify({"logged_in":False})
    return jsonify({"logged_in":True,"name":u["name"],"email":u["email"],"setup":u.get("setup",False)})

# ─── MAIN ─────────────────────────────────────────────────────────────
@app.route("/")
def index():
    return render_template("index.html")

@app.route("/api/state")
def state():
    uid, u = cur_user()
    if not u:
        return jsonify({"error":"Not logged in"}), 401
    users = load_users()
    wk = week_key()
    td = today_str()
    changed = False
    # Week rollover: just reset week_done tracker (streak is now day-based)
    if u.get("last_week") != wk:
        u["week_done"] = {}
        u["last_week"] = wk
        u["week_reward_claimed"] = None  # allow claim again this new week
        changed = True
    # Daily streak refresh
    u = refresh_streak(u)
    changed = True
    if u.get("quiz_lives_date") != td:
        u["quiz_lives"] = QUIZ_LIVES
        u["quiz_lives_date"] = td
        u["quiz_session"] = []       # reset daily quiz session
        u["quiz_done_date"] = None   # allow fresh quiz today
        changed = True
    if changed:
        users[uid] = u
        save_users(users)
    # Ensure streak_broken field is always present
    u.setdefault("streak_broken", False)
    safe = {k:v for k,v in u.items() if k not in ("pw",)}
    safe.update({
        "gems_per_workout":GEMS_PER_WORKOUT,"shield_cost":SHIELD_COST,
        "shield_max":SHIELD_MAX,"bonus_cost":BONUS_COST,
        "revive_cost":REVIVE_COST,"gem_packages":GEM_PACKAGES,
        "quiz_daily_limit":QUIZ_DAILY_LIMIT,"quiz_max_lives":QUIZ_LIVES,
        "training_programs":TRAINING_PROGRAMS,
        "ad_gems_reward":AD_GEMS_REWARD,
        "ad_gems_done": u.get("ad_gems_date") == td,
        "program_access": u.get("program_access", {}),
        "active_program": u.get("active_program"),
    })
    return jsonify(safe)

@app.route("/api/setup", methods=["POST"])
def setup():
    uid, u = cur_user()
    if not u:
        return jsonify({"error":"Not logged in"}), 401
    b = request.json or {}
    u["setup"]         = True
    u["days_per_week"] = b["days_per_week"]
    u["muscle_groups"] = b["muscle_groups"]
    u["intensity"]     = b.get("intensity","intermediate")
    g = b["muscle_groups"]
    u["plan"] = [g[i%len(g)] for i in range(b["days_per_week"])]
    users = load_users()
    users[uid] = u
    save_users(users)
    return jsonify({"ok":True})

@app.route("/api/profile", methods=["POST"])
def profile():
    uid, u = cur_user()
    if not u:
        return jsonify({"error":"Not logged in"}), 401
    b = request.json or {}
    if b.get("name"):      u["name"] = b["name"].strip()
    if b.get("days_per_week"): u["days_per_week"] = int(b["days_per_week"])
    if b.get("muscle_groups"): u["muscle_groups"] = b["muscle_groups"]
    if b.get("intensity"):     u["intensity"] = b["intensity"]
    g = u.get("muscle_groups",[])
    if g: u["plan"] = [g[i%len(g)] for i in range(u["days_per_week"])]
    users = load_users()
    users[uid] = u
    save_users(users)
    return jsonify({"ok":True})

@app.route("/api/settings", methods=["POST"])
def settings():
    uid, u = cur_user()
    if not u:
        return jsonify({"error":"Not logged in"}), 401
    b = request.json or {}
    u.setdefault("settings",{})
    if "sound"     in b: u["settings"]["sound"]     = bool(b["sound"])
    if "vibration" in b: u["settings"]["vibration"] = bool(b["vibration"])
    users = load_users()
    users[uid] = u
    save_users(users)
    return jsonify({"ok":True,"settings":u["settings"]})

@app.route("/api/metrics", methods=["POST"])
def metrics():
    uid, u = cur_user()
    if not u:
        return jsonify({"error":"Not logged in"}), 401
    b = request.json or {}
    m = u.get("metrics",{})
    if b.get("weight_kg"): m["weight_kg"] = float(b["weight_kg"])
    if b.get("height_cm"): m["height_cm"] = float(b["height_cm"])
    if b.get("age"):       m["age"]       = int(b["age"])
    if "gender" in b:      m["gender"]    = b["gender"]
    u["metrics"] = m
    td = today_str()
    wl = u.get("weight_log",[])
    if m.get("weight_kg"):
        ex = next((x for x in wl if x["date"]==td),None)
        if not ex:
            wl.append({"date":td,"weight_kg":m["weight_kg"],"kcal":0,"kg_change":0})
            u["weight_log"] = wl
        else:
            ex["weight_kg"] = m["weight_kg"]
    users = load_users()
    users[uid] = u
    save_users(users)
    return jsonify({"ok":True,"metrics":m})

@app.route("/api/weight_log")
def weight_log():
    uid, u = cur_user()
    if not u:
        return jsonify({"error":"Not logged in"}), 401
    return jsonify({"log":u.get("weight_log",[])[-60:],"metrics":u.get("metrics",{})})

@app.route("/api/workout/today")
def today_workout():
    uid, u = cur_user()
    if not u:
        return jsonify({"error":"Not logged in"}), 401
    dow    = datetime.date.today().weekday()
    intens = u.get("intensity","intermediate")
    td     = today_str()
    done_today = u.get("last_workout_date") == td
    reward     = GEMS_PER_WORKOUT + INTENSITY_CONFIG[intens]["gems_bonus"]
    bonus_done = u.get("bonus_date") == td

    # Build program_extras list — one entry per active program with valid access
    def _parse_ex(raw, prog, week, week_data):
        mx = re.search(r'x(\d+)', raw)
        reps = mx.group(1) if mx else "10-15"
        ts = re.search(r'(\d+)s', raw)
        if ts and not mx: reps = ts.group(1) + "s"
        name = re.sub(r'\s*x\d+|\s*\d+s.*$', '', raw).strip()
        return {"name":name,"sets":3,"reps":reps,"rest":60,"emoji":"🏋️",
                "color":prog["color"],
                "desc":f"Part of {prog['title']} — Week {week}: {week_data['focus']}.",
                "cues":["Focus on form","Controlled movement","Full range of motion","Breathe steadily"]}

    # Support both old single-object and new list format
    raw_ap = u.get("active_program")
    if isinstance(raw_ap, dict):
        active_list = [raw_ap]   # migrate old format on the fly
    elif isinstance(raw_ap, list):
        active_list = raw_ap
    else:
        active_list = []

    access = u.get("program_access", {})
    program_extras = []
    for ap in active_list:
        prog_id = ap.get("id")
        week    = ap.get("week", 1)
        prog = next((p for p in TRAINING_PROGRAMS if p["id"] == prog_id), None)
        if prog and access.get(prog_id, "") >= td:
            week_data = next((w for w in prog.get("workouts",[]) if w["week"] == week), None)
            if week_data:
                program_extras.append({
                    "exercises": apply_intensity([_parse_ex(e, prog, week, week_data) for e in week_data.get("exercises",[])], intens),
                    "program_id": prog_id,
                    "program_title": prog["title"],
                    "program_week": week,
                    "program_focus": week_data["focus"],
                    "program_emoji": prog["emoji"],
                    "program_color": prog["color"],
                })
    program_extra = program_extras[0] if len(program_extras) == 1 else None  # keep compat key

    # Always return the regular plan workout + optional program_extra
    plan = u.get("plan",[])
    if not plan:
        return jsonify({"error":"No plan"}), 400
    group = plan[dow % len(plan)]
    exs   = apply_intensity(WORKOUTS.get(group,[]), intens)
    return jsonify({
        "group":group,"exercises":exs,"done_today":done_today,"dow":dow,
        "intensity":intens,"days_done":len(u.get("week_done",{})),
        "days_per_week":u.get("days_per_week",3),"gems_reward":reward,
        "bonus_cost":BONUS_COST,"bonus_done":bonus_done,
        "is_program":False,
        "program_extra": program_extra,
        "program_extras": program_extras,
    })

@app.route("/api/workout/bonus_exercises")
def bonus_exercises():
    """Return lighter bonus exercises for a chosen muscle group."""
    uid, u = cur_user()
    if not u:
        return jsonify({"error":"Not logged in"}), 401
    group  = request.args.get("group","full")
    intens = u.get("intensity","intermediate")
    key    = group + "_bonus"
    exs    = WORKOUTS.get(key, WORKOUTS.get(group,[]))
    # Bonus: always beginner intensity (lighter)
    out = apply_intensity(exs, "beginner")
    return jsonify({"group":group,"exercises":out})

@app.route("/api/workout/complete", methods=["POST"])
def complete():
    uid, u = cur_user()
    if not u:
        return jsonify({"error":"Not logged in"}), 401
    b         = request.json or {}
    dow       = datetime.date.today().weekday()
    is_bonus  = b.get("is_bonus",False)
    total_sets= b.get("sets",10)
    intens    = u.get("intensity","intermediate")
    kcal      = 0
    m         = u.get("metrics",{})
    if m.get("weight_kg"):
        kcal = estimate_kcal(m, intens, total_sets)
        kg_ch = -(kcal / 7700)
        td = today_str()
        wl = u.get("weight_log",[])
        ex = next((x for x in wl if x["date"]==td),None)
        if ex:
            ex["kcal"]         = round(ex.get("kcal",0) + kcal)
            ex["kg_change"]    = round(ex.get("kg_change",0) + kg_ch, 4)
            ex["predicted_kg"] = round(float(ex["weight_kg"]) + ex["kg_change"], 3)
        else:
            # Use previous day predicted_kg as today's base for running trend
            prev = wl[-1] if wl else None
            base = float(prev.get("predicted_kg") or prev.get("weight_kg") or m["weight_kg"]) if prev else float(m["weight_kg"])
            predicted = round(base + kg_ch, 3)
            wl.append({"date":td,"weight_kg":round(base,3),"kcal":kcal,
                        "kg_change":round(kg_ch,4),"predicted_kg":predicted})
        u["weight_log"] = wl

    gems_earned = 0
    td = today_str()
    already_done_today = u.get("last_workout_date") == td

    if is_bonus:
        gems_earned = GEMS_PER_WORKOUT
        u["gems"] = u.get("gems",0) + gems_earned
        u["total_sessions"] = u.get("total_sessions",0)+1
        u["bonus_date"] = td
    elif not already_done_today:
        # Mark week slot
        u.setdefault("week_done",{})[str(dow)] = True
        u["total_sessions"] = u.get("total_sessions",0)+1
        gems_earned = GEMS_PER_WORKOUT + INTENSITY_CONFIG[intens]["gems_bonus"]
        u["gems"] = u.get("gems",0) + gems_earned
        # ── Day-based streak ──────────────────────────────────────
        last = u.get("last_workout_date")
        yesterday = (datetime.date.today() - datetime.timedelta(days=1)).isoformat()
        if last == yesterday or (last is None):
            # consecutive day, or very first workout ever
            u["streak"] = u.get("streak",0) + 1
        else:
            # gap of 2+ days — reset to 1 (this workout counts as day 1)
            u["streak"] = 1
        u["best_streak"]     = max(u.get("best_streak",0), u["streak"])
        u["streak_at_risk"]  = False
        u["last_workout_date"] = td

    # ── Weekly goal reward (once per week, not for bonus workouts) ────
    week_bonus = 0
    wk = week_key()
    done_this_week = len(u.get("week_done", {}))
    goal = u.get("days_per_week", 3)
    if (not is_bonus
            and done_this_week >= goal
            and u.get("week_reward_claimed") != wk):
        u["week_reward_claimed"] = wk
        week_bonus = WEEK_REWARD
        u["gems"] = u.get("gems", 0) + week_bonus
        gems_earned += week_bonus

    u.setdefault("history",[]).append({
        "date": datetime.date.today().strftime("%b %d, %Y"),
        "group":b.get("group",""),"exercises":b.get("exercises",5),
        "sets":total_sets,"intensity":intens,"gems":gems_earned,"kcal":kcal,"bonus":is_bonus,
    })
    users = load_users()
    users[uid] = u
    save_users(users)
    return jsonify({
        "streak":u["streak"],"best_streak":u["best_streak"],
        "gems":u["gems"],"gems_earned":gems_earned,
        "shields":u.get("shields",0),
        "days_done":len(u.get("week_done",{})),
        "days_goal":u.get("days_per_week",3),
        "streak_at_risk":u.get("streak_at_risk",False),
        "kcal":kcal,
        "week_bonus":week_bonus,
    })

@app.route("/api/bonus_unlock", methods=["POST"])
def bonus_unlock():
    uid, u = cur_user()
    if not u:
        return jsonify({"error":"Not logged in"}), 401
    method = (request.json or {}).get("method","gems")
    if method == "gems":
        if u.get("gems",0) < BONUS_COST:
            return jsonify({"error":f"Need {BONUS_COST} gems. You have {u.get('gems',0)}"}), 400
        u["gems"] -= BONUS_COST
    users = load_users()
    users[uid] = u
    save_users(users)
    return jsonify({"ok":True,"gems":u.get("gems",0)})

# ─── QUIZ ──────────────────────────────────────────────────────────────
QUIZ_QUESTIONS_PER_DAY = 10

def get_daily_question_order(td):
    """Return 10 shuffled question IDs for today, seeded by date."""
    rng = random.Random(td)
    ids = [q["id"] for q in QUIZ_BANK]
    rng.shuffle(ids)
    return ids[:QUIZ_QUESTIONS_PER_DAY]

def get_question_by_id(qid):
    return next((q for q in QUIZ_BANK if q["id"] == qid), None)

@app.route("/api/quiz/today")
def quiz_today():
    uid, u = cur_user()
    if not u:
        return jsonify({"error":"Not logged in"}), 401
    td = today_str()
    # Reset session daily
    if u.get("quiz_lives_date") != td:
        u["quiz_lives"]     = QUIZ_LIVES
        u["quiz_lives_date"]= td
        u["quiz_session"]   = []     # answered question IDs today
        u["quiz_done_date"] = None
        users = load_users()
        users[uid] = u
        save_users(users)

    done      = u.get("quiz_done_date") == td
    lives     = u.get("quiz_lives", QUIZ_LIVES)
    answered  = u.get("quiz_session", [])
    order     = get_daily_question_order(td)
    # Next unanswered question
    remaining = [qid for qid in order if qid not in answered]
    total     = len(order)
    num_done  = len(answered)

    if done or not remaining:
        return jsonify({"done":True,"lives":lives,"max_lives":QUIZ_LIVES,
                        "revive_cost":REVIVE_COST,"total":total,"num_done":num_done,
                        "gems":u.get("gems",0)})

    q = dict(get_question_by_id(remaining[0]))
    q.pop("a", None)   # never leak the answer
    return jsonify({"quiz":q,"done":False,"lives":lives,"max_lives":QUIZ_LIVES,
                    "revive_cost":REVIVE_COST,"total":total,"num_done":num_done})

@app.route("/api/quiz/answer", methods=["POST"])
def quiz_answer():
    uid, u = cur_user()
    if not u:
        return jsonify({"error":"Not logged in"}), 401
    b      = request.json or {}
    answer = b.get("answer")
    td     = today_str()
    # Guard: session must be active today
    if u.get("quiz_lives_date") != td:
        u["quiz_lives"]     = QUIZ_LIVES
        u["quiz_lives_date"]= td
        u["quiz_session"]   = []
        u["quiz_done_date"] = None
    if u.get("quiz_done_date") == td:
        return jsonify({"error":"Already done today"}), 400
    lives = u.get("quiz_lives", QUIZ_LIVES)
    if lives <= 0:
        return jsonify({"error":"no_lives"}), 400

    order    = get_daily_question_order(td)
    answered = u.get("quiz_session", [])
    remaining= [qid for qid in order if qid not in answered]
    if not remaining:
        u["quiz_done_date"] = td
        users = load_users(); users[uid] = u; save_users(users)
        return jsonify({"error":"Already done today"}), 400

    q = get_question_by_id(remaining[0])
    correct = (answer == q["a"])
    gems_earned = 0

    if correct:
        answered.append(q["id"])
        u["quiz_session"] = answered
        gems_earned = 5   # small reward per correct answer
        u["gems"] = u.get("gems",0) + gems_earned
        # Session complete when all questions answered
        if len(answered) >= len(order):
            u["quiz_done_date"] = td
            # Bonus for finishing the whole set
            bonus = 20
            u["gems"] = u.get("gems",0) + bonus
            gems_earned += bonus
    else:
        u["quiz_lives"] = lives - 1
        if u["quiz_lives"] <= 0:
            u["quiz_done_date"] = td   # out of lives — session over

    users = load_users()
    users[uid] = u
    save_users(users)
    num_done  = len(u.get("quiz_session",[]))
    total     = len(order)
    session_done = u.get("quiz_done_date") == td
    return jsonify({
        "correct":correct,"lives":u["quiz_lives"],"gems_earned":gems_earned,
        "gems":u["gems"],"explanation":q["exp"],"correct_answer":q["a"],
        "num_done":num_done,"total":total,"session_done":session_done,
    })

@app.route("/api/quiz/revive", methods=["POST"])
def quiz_revive():
    uid, u = cur_user()
    if not u:
        return jsonify({"error":"Not logged in"}), 401
    method = (request.json or {}).get("method","gems")
    if method == "gems":
        if u.get("gems",0) < REVIVE_COST:
            return jsonify({"error":f"Need {REVIVE_COST} gems"}), 400
        u["gems"] -= REVIVE_COST
    u["quiz_lives"]      = QUIZ_LIVES
    u["quiz_lives_date"] = today_str()
    u["quiz_done_date"]  = None   # allow continuing after revive
    users = load_users()
    users[uid] = u
    save_users(users)
    return jsonify({"ok":True,"lives":QUIZ_LIVES,"gems":u.get("gems",0)})

# ─── STREAK RESOLVE ────────────────────────────────────────────────────
@app.route("/api/streak/resolve", methods=["POST"])
def streak_resolve():
    """
    Called when the user chooses what to do about a broken streak.
    method='shield' — spend one shield to preserve the streak (no increment).
    method='lose'   — accept the loss, streak resets to 0.
    method='buy_shield' — buy a shield first, then immediately use it.
    """
    uid, u = cur_user()
    if not u:
        return jsonify({"error":"Not logged in"}), 401
    method = (request.json or {}).get("method","lose")
    if not u.get("streak_broken"):
        return jsonify({"error":"No broken streak to resolve"}), 400
    if method == "shield":
        if u.get("shields",0) < 1:
            return jsonify({"error":"No shields available"}), 400
        u["shields"]       -= 1
        u["streak_broken"]  = False
        u["streak_at_risk"] = True   # still at risk today until they work out
        # streak number preserved, no increment
    elif method == "buy_shield":
        # Buy one shield (deduct gems) then immediately use it
        if u.get("shields",0) >= SHIELD_MAX:
            return jsonify({"error":f"Max {SHIELD_MAX} shields already owned"}), 400
        if u.get("gems",0) < SHIELD_COST:
            return jsonify({"error":f"Need {SHIELD_COST} gems. You have {u.get('gems',0)}"}), 400
        u["gems"]          -= SHIELD_COST
        # don't add to shields — use it immediately
        u["streak_broken"]  = False
        u["streak_at_risk"] = True
    else:  # 'lose'
        u["streak"]         = 0
        u["streak_broken"]  = False
        u["streak_at_risk"] = False
        u["last_workout_date"] = None
    users = load_users()
    users[uid] = u
    save_users(users)
    return jsonify({
        "ok":True,
        "streak":u["streak"],
        "shields":u.get("shields",0),
        "gems":u.get("gems",0),
        "streak_broken":False,
    })

# ─── STORE ────────────────────────────────────────────────────────────
@app.route("/api/gems/buy_shield", methods=["POST"])
def buy_shield():
    uid, u = cur_user()
    if not u:
        return jsonify({"error":"Not logged in"}), 401
    if u.get("shields",0) >= SHIELD_MAX:
        return jsonify({"error":f"Max {SHIELD_MAX} shields"}), 400
    if u.get("gems",0) < SHIELD_COST:
        return jsonify({"error":f"Need {SHIELD_COST} gems. You have {u.get('gems',0)}"}), 400
    u["gems"]    -= SHIELD_COST
    u["shields"] = u.get("shields",0)+1
    users = load_users()
    users[uid] = u
    save_users(users)
    return jsonify({"ok":True,"gems":u["gems"],"shields":u["shields"]})

@app.route("/api/gems/use_shield", methods=["POST"])
def use_shield():
    uid, u = cur_user()
    if not u:
        return jsonify({"error":"Not logged in"}), 401
    if u.get("shields",0) < 1:
        return jsonify({"error":"No shields"}), 400
    u["shields"] -= 1
    u["streak_at_risk"] = False
    # Streak is preserved but NOT incremented — shield just protects it
    users = load_users()
    users[uid] = u
    save_users(users)
    return jsonify({"ok":True,"streak":u["streak"],"shields":u["shields"]})

@app.route("/api/gems/purchase", methods=["POST"])
def purchase():
    uid, u = cur_user()
    if not u:
        return jsonify({"error":"Not logged in"}), 401
    pkg = next((p for p in GEM_PACKAGES if p["id"]==(request.json or {}).get("package_id")),None)
    if not pkg:
        return jsonify({"error":"Invalid package"}), 400
    u["gems"] = u.get("gems",0) + pkg["gems"]
    users = load_users()
    users[uid] = u
    save_users(users)
    return jsonify({"ok":True,"gems":u["gems"],"gems_added":pkg["gems"],"package":pkg["label"]})

PROGRAM_ACCESS_DAYS = 7   # 1-week access per purchase

@app.route("/api/programs/purchase", methods=["POST"])
def purchase_program():
    uid, u = cur_user()
    if not u:
        return jsonify({"error":"Not logged in"}), 401
    prog_id = (request.json or {}).get("program_id","")
    prog = next((p for p in TRAINING_PROGRAMS if p["id"]==prog_id), None)
    if not prog:
        return jsonify({"error":"Program not found"}), 404
    # Check if already active (not yet expired)
    now = datetime.date.today().isoformat()
    access = u.get("program_access", {})
    if access.get(prog_id, "") >= now:
        return jsonify({"error":"Program still active — wait until it expires to re-purchase"}), 400
    if u.get("gems",0) < prog["cost"]:
        return jsonify({"error":f"Need {prog['cost']} gems. You have {u.get('gems',0)}"}), 400
    u["gems"] -= prog["cost"]
    expiry = (datetime.date.today() + datetime.timedelta(days=PROGRAM_ACCESS_DAYS - 1)).isoformat()
    access[prog_id] = expiry
    u["program_access"] = access
    users = load_users()
    users[uid] = u
    save_users(users)
    days_remaining = PROGRAM_ACCESS_DAYS
    return jsonify({"ok":True,"gems":u["gems"],"program_id":prog_id,
                    "expiry":expiry,"days_remaining":days_remaining})

@app.route("/api/programs/activate", methods=["POST"])
def activate_program():
    """Set or clear the user's active program for the Today tab."""
    uid, u = cur_user()
    if not u:
        return jsonify({"error":"Not logged in"}), 401
    b = request.json or {}
    prog_id = b.get("program_id")
    week    = b.get("week")
    if prog_id is None:
        # Clear all
        u["active_program"] = []
        users = load_users(); users[uid] = u; save_users(users)
        return jsonify({"ok":True,"active_program":[]})
    # Deactivate a specific program by id (prog_id passed but week is None or missing)
    if week is None:
        raw_ap = u.get("active_program", [])
        if isinstance(raw_ap, list):
            u["active_program"] = [x for x in raw_ap if x.get("id") != prog_id]
        else:
            u["active_program"] = []
        users = load_users(); users[uid] = u; save_users(users)
        return jsonify({"ok":True,"active_program":u["active_program"]})
    # Validate access
    now    = datetime.date.today().isoformat()
    access = u.get("program_access", {})
    if access.get(prog_id, "") < now:
        return jsonify({"error":"No active access to this program"}), 403
    prog = next((p for p in TRAINING_PROGRAMS if p["id"] == prog_id), None)
    if not prog:
        return jsonify({"error":"Program not found"}), 404
    valid_weeks = [w["week"] for w in prog.get("workouts",[])]
    if week not in valid_weeks:
        return jsonify({"error":"Invalid week"}), 400
    # Migrate old single-object format to list
    raw_ap = u.get("active_program")
    if isinstance(raw_ap, dict):
        u["active_program"] = [raw_ap]
    elif not isinstance(raw_ap, list):
        u["active_program"] = []
    # Update or add entry for this program
    ap_list = u["active_program"]
    existing = next((x for x in ap_list if x["id"] == prog_id), None)
    if existing:
        existing["week"] = week
    else:
        ap_list.append({"id": prog_id, "week": week})
    users = load_users(); users[uid] = u; save_users(users)
    return jsonify({"ok":True,"active_program":u["active_program"]})

@app.route("/api/programs/workout")
def program_workout():
    """Return a runnable workout for a specific program week."""
    uid, u = cur_user()
    if not u:
        return jsonify({"error":"Not logged in"}), 401
    prog_id = request.args.get("program_id","")
    week    = int(request.args.get("week", 1))
    # Verify active access
    now    = datetime.date.today().isoformat()
    access = u.get("program_access", {})
    if access.get(prog_id, "") < now:
        return jsonify({"error":"No active access to this program"}), 403
    prog = next((p for p in TRAINING_PROGRAMS if p["id"] == prog_id), None)
    if not prog:
        return jsonify({"error":"Program not found"}), 404
    week_data = next((w for w in prog.get("workouts",[]) if w["week"] == week), None)
    if not week_data:
        return jsonify({"error":"Week not found"}), 404
    intens = u.get("intensity","intermediate")
    # Convert plain-string exercises into proper workout objects
    def parse_ex(raw):
        """Parse 'Exercise Name xN' or 'Exercise Name Ns' into a workout dict."""
        # Extract reps/time from end  e.g. "x10", "x8", "30s", "45s each"
        m = re.search(r'x(\d+)', raw)
        reps = m.group(1) if m else "10-15"
        ts = re.search(r'(\d+)s', raw)
        if ts and not m:
            reps = ts.group(1) + "s"
        name = re.sub(r'\s*x\d+|\s*\d+s.*$', '', raw).strip()
        return {
            "name": name,
            "sets": 3,
            "reps": reps,
            "rest": 60,
            "emoji": "🏋️",
            "color": prog["color"],
            "desc": f"Part of {prog['title']} — Week {week}: {week_data['focus']}.",
            "cues": ["Focus on form", "Controlled movement", "Full range of motion", "Breathe steadily"],
        }
    raw_exs = [parse_ex(e) for e in week_data.get("exercises",[])]
    exs = apply_intensity(raw_exs, intens)
    return jsonify({
        "group": prog_id,
        "program_title": prog["title"],
        "week": week,
        "focus": week_data["focus"],
        "exercises": exs,
        "intensity": intens,
        "color": prog["color"],
        "emoji": prog["emoji"],
    })

@app.route("/api/store/watch_ad", methods=["POST"])
def store_watch_ad():
    uid, u = cur_user()
    if not u:
        return jsonify({"error":"Not logged in"}), 401
    td = today_str()
    if u.get("ad_gems_date") == td:
        return jsonify({"error":"already_done"}), 400
    u["ad_gems_date"] = td
    u["gems"] = u.get("gems",0) + AD_GEMS_REWARD
    users = load_users()
    users[uid] = u
    save_users(users)
    return jsonify({"ok":True,"gems":u["gems"],"gems_earned":AD_GEMS_REWARD})

@app.route("/api/reset", methods=["POST"])
def reset():
    uid, u = cur_user()
    if not u:
        return jsonify({"error":"Not logged in"}), 401
    users = load_users()
    users[uid].update({
        "setup":False,"days_per_week":3,"muscle_groups":[],"intensity":"intermediate","plan":[],
        "streak":0,"best_streak":0,"streak_at_risk":False,"gems":0,"shields":0,
        "total_sessions":0,"history":[],"week_done":{},"last_week":None,
        "quiz_done_date":None,"quiz_lives":QUIZ_LIVES,"quiz_lives_date":None,"bonus_date":None,"week_reward_claimed":None,"ad_gems_date":None,"purchased_programs":[],"program_access":{},"active_program":None,
        "weight_log":[],"metrics":{"weight_kg":None,"height_cm":None,"age":None,"gender":"male"},
    })
    save_users(users)
    return jsonify({"ok":True})

if __name__ == "__main__":
    print("\n🏋️  StreakFit Calisthenics App v1")
    print("━"*38)
    print("▶  http://localhost:5000")
    print("━"*38+"\n")
    app.run(debug=True, port=5000)