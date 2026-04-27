import 'dart:async';
import 'dart:math' as dart_math;
import 'dart:typed_data';
import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:fl_chart/fl_chart.dart';
import 'api.dart';
import 'state.dart';

// ════════════════════════════════════════════════════════════════════
// THEME CONSTANTS
// ════════════════════════════════════════════════════════════════════
const bg = Color(0xFF0e0e12);
const s1 = Color(0xFF16161d);
const s2 = Color(0xFF1e1e26);
const accent = Color(0xFFc8f55a);
const gem = Color(0xFF5ab4ff);
const safe = Color(0xFF5dd87a);
const danger = Color(0xFFff4455);
const warn = Color(0xFFf5a623);
const fg = Color(0xFFe8e8f0);
const mid = Color(0xFF9090a8);
const dim = Color(0xFF585868);
const bd = Color(0xFF28282f);
const bd2 = Color(0xFF38383f);

TextStyle heading(double s, {Color c = fg}) =>
    GoogleFonts.bebasNeue(fontSize: s, color: c, letterSpacing: 1);

const lbl = TextStyle(
  fontSize: 9,
  color: dim,
  letterSpacing: 2,
  fontWeight: FontWeight.w500,
);

ThemeData get appTheme => ThemeData(
  brightness: Brightness.dark,
  scaffoldBackgroundColor: bg,
  colorScheme: const ColorScheme.dark(
    primary: accent,
    secondary: gem,
    surface: s1,
    error: danger,
  ),
  textTheme: GoogleFonts.dmSansTextTheme(ThemeData.dark().textTheme),
  inputDecorationTheme: InputDecorationTheme(
    filled: true,
    fillColor: s2,
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(8),
      borderSide: const BorderSide(color: bd),
    ),
    enabledBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(8),
      borderSide: const BorderSide(color: bd),
    ),
    focusedBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(8),
      borderSide: const BorderSide(color: accent, width: 1.5),
    ),
    hintStyle: const TextStyle(color: dim),
    labelStyle: const TextStyle(color: mid),
    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
  ),
  elevatedButtonTheme: ElevatedButtonThemeData(
    style: ElevatedButton.styleFrom(
      backgroundColor: accent,
      foregroundColor: bg,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
      textStyle: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14),
    ),
  ),
  outlinedButtonTheme: OutlinedButtonThemeData(
    style: OutlinedButton.styleFrom(
      foregroundColor: fg,
      side: const BorderSide(color: bd2),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
    ),
  ),
  cardTheme: CardThemeData(
    color: s1,
    elevation: 0,
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(12),
      side: const BorderSide(color: bd),
    ),
  ),
  dividerTheme: const DividerThemeData(color: bd, thickness: 1),
  useMaterial3: true,
);

// ════════════════════════════════════════════════════════════════════
// SOUND & HAPTICS
// ════════════════════════════════════════════════════════════════════
class SoundSettings {
  static bool soundEnabled = true;
  static bool vibrationEnabled = true;
  static AudioPlayer? _player;

  static void load(Map<String, dynamic> s) {
    soundEnabled = s['sound'] != false;
    vibrationEnabled = s['vibration'] != false;
  }

  static Future<void> tone(double freq, int ms, {double vol = 0.4}) async {
    if (!soundEnabled) return;
    try {
      _player ??= AudioPlayer();
      final bytes = _wav(freq, ms, vol);
      await _player!.stop();
      await _player!.play(BytesSource(bytes), volume: vol);
    } catch (_) {
      // silent fallback
    }
  }

  static Uint8List _wav(double freq, int ms, double vol) {
    const sr = 22050;
    final n = (sr * ms / 1000).round();
    final buf = Uint8List(44 + n * 2);
    final bd = ByteData.view(buf.buffer);
    void ws(int o, String s) {
      for (var i = 0; i < s.length; i++) buf[o + i] = s.codeUnitAt(i);
    }

    ws(0, 'RIFF');
    bd.setUint32(4, 36 + n * 2, Endian.little);
    ws(8, 'WAVE');
    ws(12, 'fmt ');
    bd.setUint32(16, 16, Endian.little);
    bd.setUint16(20, 1, Endian.little);
    bd.setUint16(22, 1, Endian.little);
    bd.setUint32(24, sr, Endian.little);
    bd.setUint32(28, sr * 2, Endian.little);
    bd.setUint16(32, 2, Endian.little);
    bd.setUint16(34, 16, Endian.little);
    ws(36, 'data');
    bd.setUint32(40, n * 2, Endian.little);
    for (var i = 0; i < n; i++) {
      final t = i / sr;
      final env = i > n * 0.7 ? (n - i) / (n * 0.3) : 1.0;
      final v = (32767 * vol * env * dart_math.sin(2 * dart_math.pi * freq * t))
          .round()
          .clamp(-32768, 32767);
      bd.setInt16(44 + i * 2, v, Endian.little);
    }
    return buf;
  }
}

void sndGem() {
  SoundSettings.tone(1200, 100);
  Future.delayed(
    const Duration(milliseconds: 110),
    () => SoundSettings.tone(1600, 130),
  );
}

void sndRight() {
  SoundSettings.tone(880, 100);
  Future.delayed(
    const Duration(milliseconds: 110),
    () => SoundSettings.tone(1100, 120),
  );
}

void sndWrong() {
  SoundSettings.tone(200, 280, vol: 0.3);
}

void sndStart() {
  SoundSettings.tone(660, 90);
  Future.delayed(
    const Duration(milliseconds: 110),
    () => SoundSettings.tone(880, 110),
  );
  Future.delayed(
    const Duration(milliseconds: 230),
    () => SoundSettings.tone(1100, 140),
  );
}

void sndTick() {
  SoundSettings.tone(800, 55, vol: 0.25);
}

void sndClick() {
  SoundSettings.tone(660, 75, vol: 0.3);
}

void haptic([bool heavy = false]) {
  if (!SoundSettings.vibrationEnabled) return;
  if (heavy)
    HapticFeedback.heavyImpact();
  else
    HapticFeedback.lightImpact();
}

// ════════════════════════════════════════════════════════════════════
// HELPERS
// ════════════════════════════════════════════════════════════════════
Color hexColor(String h) {
  try {
    return Color(int.parse(h.replaceAll('#', '0xFF')));
  } catch (_) {
    return accent;
  }
}

Widget pill(String t, Color c) => Container(
  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
  decoration: BoxDecoration(
    color: c.withValues(alpha: .12),
    borderRadius: BorderRadius.circular(4),
    border: Border.all(color: c.withValues(alpha: .3)),
  ),
  child: Text(
    t,
    style: TextStyle(
      fontSize: 9,
      color: c,
      letterSpacing: 1,
      fontWeight: FontWeight.w600,
    ),
  ),
);

Widget exRow(Map<String, dynamic> ex, {bool dim_ = false}) => Opacity(
  opacity: dim_ ? .45 : 1,
  child: Container(
    margin: const EdgeInsets.only(bottom: 8),
    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
    decoration: BoxDecoration(
      color: s1,
      borderRadius: BorderRadius.circular(8),
      border: Border.all(color: bd),
    ),
    child: Row(
      children: [
        Text(
          ex['emoji'] as String? ?? '🏋️',
          style: const TextStyle(fontSize: 20),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                ex['name'] as String? ?? '',
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                  color: fg,
                ),
              ),
              Text(
                '${ex['sets']} sets · ${ex['reps']} reps · ${ex['rest']}s rest',
                style: const TextStyle(fontSize: 10, color: dim),
              ),
            ],
          ),
        ),
        const Icon(Icons.chevron_right, color: dim, size: 16),
      ],
    ),
  ),
);

// Gem purchase dialog — distinct from workout confirm
Future<bool> showProgramPurchaseDialog(
  BuildContext ctx, {
  required String emoji,
  required String title,
  required int cost,
  required String tagline,
}) async {
  final ok = await showModalBottomSheet<bool>(
    context: ctx,
    backgroundColor: s1,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
    ),
    builder: (_) => Padding(
      padding: const EdgeInsets.fromLTRB(24, 12, 24, 32),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 36,
            height: 4,
            decoration: BoxDecoration(
              color: bd2,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 20),
          Text(emoji, style: const TextStyle(fontSize: 40)),
          const SizedBox(height: 10),
          Text(
            'Unlock $title',
            style: GoogleFonts.bebasNeue(
              fontSize: 26,
              color: fg,
              letterSpacing: 1,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 4),
          Text(
            tagline,
            style: const TextStyle(color: mid, fontSize: 12),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 6),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: gem.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(6),
              border: Border.all(color: gem.withValues(alpha: 0.3)),
            ),
            child: Text(
              '💎 $cost gems · 7-day full access',
              style: const TextStyle(
                color: gem,
                fontSize: 12,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(
              minimumSize: const Size(double.infinity, 50),
              backgroundColor: accent,
              foregroundColor: bg,
            ),
            child: const Text('Unlock Program →'),
          ),
          const SizedBox(height: 10),
          OutlinedButton(
            onPressed: () => Navigator.pop(ctx, false),
            style: OutlinedButton.styleFrom(
              minimumSize: const Size(double.infinity, 48),
            ),
            child: const Text('Cancel'),
          ),
        ],
      ),
    ),
  );
  return ok == true;
}

Future<bool> showGemPurchaseDialog(
  BuildContext ctx, {
  required dynamic gems,
  required dynamic usd,
  required dynamic label,
}) async {
  final ok = await showModalBottomSheet<bool>(
    context: ctx,
    backgroundColor: s1,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
    ),
    builder: (_) => Padding(
      padding: const EdgeInsets.fromLTRB(24, 12, 24, 32),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 36,
            height: 4,
            decoration: BoxDecoration(
              color: bd2,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 20),
          Container(
            width: 72,
            height: 72,
            decoration: BoxDecoration(
              color: gem.withValues(alpha: 0.15),
              shape: BoxShape.circle,
              border: Border.all(color: gem.withValues(alpha: 0.4), width: 2),
            ),
            child: const Center(
              child: Text('💎', style: TextStyle(fontSize: 34)),
            ),
          ),
          const SizedBox(height: 14),
          Text(
            '$gems Gems',
            style: GoogleFonts.bebasNeue(
              fontSize: 30,
              color: gem,
              letterSpacing: 1,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            '$usd · $label',
            style: const TextStyle(color: mid, fontSize: 13),
          ),
          const SizedBox(height: 4),
          const Text(
            'Simulated purchase. Real IAP required for production.',
            style: TextStyle(color: dim, fontSize: 10),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(
              minimumSize: const Size(double.infinity, 50),
              backgroundColor: gem,
              foregroundColor: Colors.white,
            ),
            child: Text('Buy $gems Gems — $usd'),
          ),
          const SizedBox(height: 10),
          OutlinedButton(
            onPressed: () => Navigator.pop(ctx, false),
            style: OutlinedButton.styleFrom(
              minimumSize: const Size(double.infinity, 48),
            ),
            child: const Text('Cancel'),
          ),
        ],
      ),
    ),
  );
  return ok == true;
}

// Workout start confirm — separate from gem purchase
Future<bool> confirm(
  BuildContext ctx, {
  required String emoji,
  required String title,
  required String desc,
}) async {
  final ok = await showModalBottomSheet<bool>(
    context: ctx,
    backgroundColor: s1,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
    ),
    builder: (_) => Padding(
      padding: const EdgeInsets.fromLTRB(24, 12, 24, 32),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 36,
            height: 4,
            decoration: BoxDecoration(
              color: bd2,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 20),
          Text(emoji, style: const TextStyle(fontSize: 40)),
          const SizedBox(height: 10),
          Text(
            title,
            style: GoogleFonts.bebasNeue(
              fontSize: 26,
              color: fg,
              letterSpacing: 1,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 6),
          Text(
            desc,
            style: const TextStyle(color: mid, fontSize: 13),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(
              minimumSize: const Size(double.infinity, 50),
            ),
            child: const Text("▶ Let's Go!"),
          ),
          const SizedBox(height: 10),
          OutlinedButton(
            onPressed: () => Navigator.pop(ctx, false),
            style: OutlinedButton.styleFrom(
              minimumSize: const Size(double.infinity, 48),
            ),
            child: const Text('Not yet'),
          ),
        ],
      ),
    ),
  );
  return ok == true;
}

// ════════════════════════════════════════════════════════════════════
// MAIN
// ════════════════════════════════════════════════════════════════════
void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Api.init();
  SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.light,
    ),
  );
  runApp(ChangeNotifierProvider(create: (_) => AppState(), child: const App()));
}

class App extends StatelessWidget {
  const App({super.key});
  @override
  Widget build(BuildContext ctx) => MaterialApp(
    title: 'StreakFit',
    debugShowCheckedModeBanner: false,
    theme: appTheme,
    home: const SplashScreen(),
    routes: {
      '/server': (_) => const ServerConfigScreen(),
      '/auth': (_) => const AuthScreen(),
      '/setup': (_) => const SetupScreen(),
      '/home': (_) => const HomeShell(),
      '/settings': (_) => const SettingsScreen(),
    },
  );
}

// ════════════════════════════════════════════════════════════════════
// SERVER CONFIG
// ════════════════════════════════════════════════════════════════════
class ServerConfigScreen extends StatefulWidget {
  const ServerConfigScreen({super.key});
  @override
  State<ServerConfigScreen> createState() => _ServerConfigState();
}

class _ServerConfigState extends State<ServerConfigScreen> {
  final _ctrl = TextEditingController();
  String _err = '';
  bool _testing = false;

  @override
  void initState() {
    super.initState();
    Api.getBase().then((v) => _ctrl.text = v);
  }

  Future<void> _save() async {
    final url = _ctrl.text.trim();
    if (url.isEmpty) {
      setState(() => _err = 'Enter a URL');
      return;
    }
    if (!url.startsWith('http')) {
      setState(() => _err = 'URL must start with http:// or https://');
      return;
    }
    setState(() {
      _testing = true;
      _err = '';
    });
    await Api.setBase(url);
    final r = await Api.me();
    if (!mounted) return;
    setState(() => _testing = false);
    if (r['error'] != null && r['error'].toString().contains('reach')) {
      setState(
        () => _err =
            'Could not reach server. Make sure Flask is running and the URL is correct.',
      );
      return;
    }
    Navigator.pushReplacementNamed(context, '/auth');
  }

  @override
  Widget build(BuildContext ctx) => Scaffold(
    backgroundColor: bg,
    body: SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(28),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 40),
            Text('STREAKFIT', style: heading(40, c: accent)),
            const SizedBox(height: 6),
            const Text(
              'Connect to your Flask server',
              style: TextStyle(color: mid, fontSize: 13),
            ),
            const SizedBox(height: 32),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: s1,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: bd),
              ),
              child: const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('SERVER URL', style: lbl),
                  SizedBox(height: 8),
                  Text(
                    '• Same WiFi as phone: http://192.168.x.x:5000\n• Android emulator: http://10.0.2.2:5000\n• Deployed (Railway/Render): https://your-app.railway.app',
                    style: TextStyle(color: mid, fontSize: 11, height: 1.6),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            TextField(
              controller: _ctrl,
              keyboardType: TextInputType.url,
              autocorrect: false,
              decoration: const InputDecoration(
                labelText: 'Backend URL',
                hintText: 'http://192.168.1.x:5000',
              ),
            ),
            if (_err.isNotEmpty) ...[
              const SizedBox(height: 10),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: danger.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: danger.withValues(alpha: 0.4)),
                ),
                child: Text(
                  _err,
                  style: const TextStyle(color: danger, fontSize: 12),
                ),
              ),
            ],
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: _testing ? null : _save,
              style: ElevatedButton.styleFrom(
                minimumSize: const Size(double.infinity, 50),
              ),
              child: _testing
                  ? const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: bg,
                          ),
                        ),
                        SizedBox(width: 10),
                        Text('Testing connection...'),
                      ],
                    )
                  : const Text('Connect & Continue →'),
            ),
          ],
        ),
      ),
    ),
  );
}

// ════════════════════════════════════════════════════════════════════
// SPLASH
// ════════════════════════════════════════════════════════════════════
class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});
  @override
  State<SplashScreen> createState() => _SplashState();
}

class _SplashState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    _boot();
  }

  Future<void> _boot() async {
    await Future.delayed(const Duration(milliseconds: 900));
    if (!mounted) return;

    final r = await Api.me();
    if (!mounted) return;

    // Server unreachable → show server config
    if (r['error'] != null && r['error'].toString().contains('reach')) {
      Navigator.pushReplacementNamed(context, '/server');
      return;
    }

    // Any error (401, not logged in, bad cookie) → go to login
    if (r['error'] != null || r['email'] == null) {
      await Api.clearSession(); // wipe stale cookie
      Navigator.pushReplacementNamed(context, '/auth');
      return;
    }

    // Logged in — load full state and route accordingly
    final s = context.read<AppState>();
    await s.load();
    if (!mounted) return;
    // Load sound/vibration prefs
    final settings = s.data['settings'];
    if (settings is Map) {
      SoundSettings.load(Map<String, dynamic>.from(settings));
    }

    if (s.setup) {
      Navigator.pushReplacementNamed(context, '/home');
    } else {
      Navigator.pushReplacementNamed(context, '/setup');
    }
  }

  @override
  Widget build(BuildContext ctx) => Scaffold(
    backgroundColor: bg,
    body: Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              color: accent.withValues(alpha: .12),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: accent.withValues(alpha: .3)),
            ),
            child: const Center(
              child: Text('💪', style: TextStyle(fontSize: 40)),
            ),
          ),
          const SizedBox(height: 18),
          Text('STREAKFIT', style: heading(36, c: accent)),
          const SizedBox(height: 6),
          const Text(
            'Zero-equipment calisthenics',
            style: TextStyle(color: dim, fontSize: 13),
          ),
          const SizedBox(height: 40),
          const SizedBox(
            width: 22,
            height: 22,
            child: CircularProgressIndicator(strokeWidth: 2, color: accent),
          ),
        ],
      ),
    ),
  );
}

// ════════════════════════════════════════════════════════════════════
// AUTH
// ════════════════════════════════════════════════════════════════════
class AuthScreen extends StatefulWidget {
  const AuthScreen({super.key});
  @override
  State<AuthScreen> createState() => _AuthState();
}

class _AuthState extends State<AuthScreen> with SingleTickerProviderStateMixin {
  late final _tabs = TabController(length: 2, vsync: this);
  final _le = TextEditingController(), _lp = TextEditingController();
  final _sn = TextEditingController(),
      _se = TextEditingController(),
      _sp = TextEditingController();
  String _lerr = '', _serr = '', _ehint = '';
  Color _ehc = dim;
  bool _busy = false, _ol = true, _os = true;

  bool _valEmail(String v) {
    final ok = RegExp(r'^[^\s@]+@[^\s@]+\.[^\s@]{2,}$').hasMatch(v);
    setState(() {
      if (v.isEmpty) {
        _ehint = 'e.g. name@gmail.com';
        _ehc = dim;
      } else if (ok) {
        _ehint = '✓ Looks good';
        _ehc = safe;
      } else {
        _ehint = 'Enter a valid email like name@gmail.com';
        _ehc = danger;
      }
    });
    return ok;
  }

  Future<void> _login() async {
    setState(() {
      _lerr = '';
      _busy = true;
    });
    final r = await Api.login(_le.text.trim(), _lp.text);
    if (!mounted) return;
    setState(() => _busy = false);
    if (r['error'] != null) {
      setState(() => _lerr = r['error']);
      return;
    }
    final s = context.read<AppState>();
    await s.load();
    if (!mounted) return;
    final settings2 = s.data['settings'];
    if (settings2 is Map)
      SoundSettings.load(Map<String, dynamic>.from(settings2));
    Navigator.pushReplacementNamed(context, s.setup ? '/home' : '/setup');
  }

  Future<void> _signup() async {
    setState(() => _serr = '');
    if (!_valEmail(_se.text.trim())) {
      setState(() => _serr = 'Enter a valid email.');
      return;
    }
    if (_sp.text.length < 6) {
      setState(() => _serr = 'Password must be 6+ characters.');
      return;
    }
    if (_sn.text.trim().isEmpty) {
      setState(() => _serr = 'Name is required.');
      return;
    }
    setState(() => _busy = true);
    final r = await Api.signup(_sn.text.trim(), _se.text.trim(), _sp.text);
    if (!mounted) return;
    setState(() => _busy = false);
    if (r['error'] != null) {
      setState(() => _serr = r['error']);
      return;
    }
    Navigator.pushReplacementNamed(context, '/setup');
  }

  @override
  Widget build(BuildContext ctx) => Scaffold(
    backgroundColor: bg,
    body: SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 32),
            Text('STREAKFIT', style: heading(40, c: accent)),
            const SizedBox(height: 6),
            const Text(
              'Zero-equipment calisthenics. Train anywhere.',
              style: TextStyle(color: mid),
            ),
            const SizedBox(height: 28),
            Container(
              decoration: BoxDecoration(
                color: s2,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: bd),
              ),
              child: TabBar(
                controller: _tabs,
                indicator: BoxDecoration(
                  color: accent,
                  borderRadius: BorderRadius.circular(6),
                ),
                indicatorSize: TabBarIndicatorSize.tab,
                labelColor: bg,
                unselectedLabelColor: mid,
                labelStyle: const TextStyle(fontWeight: FontWeight.w700),
                dividerColor: Colors.transparent,
                tabs: const [
                  Tab(text: 'Log In'),
                  Tab(text: 'Sign Up'),
                ],
              ),
            ),
            const SizedBox(height: 24),
            SizedBox(
              height: 380,
              child: TabBarView(
                controller: _tabs,
                children: [
                  // Login
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      TextField(
                        controller: _le,
                        keyboardType: TextInputType.emailAddress,
                        decoration: const InputDecoration(
                          labelText: 'Email',
                          hintText: 'you@example.com',
                        ),
                      ),
                      const SizedBox(height: 12),
                      TextField(
                        controller: _lp,
                        obscureText: _ol,
                        decoration: InputDecoration(
                          labelText: 'Password',
                          hintText: '••••••••',
                          suffixIcon: IconButton(
                            icon: Icon(
                              _ol ? Icons.visibility_off : Icons.visibility,
                              color: dim,
                              size: 18,
                            ),
                            onPressed: () => setState(() => _ol = !_ol),
                          ),
                        ),
                      ),
                      if (_lerr.isNotEmpty) ...[
                        const SizedBox(height: 8),
                        Text(
                          _lerr,
                          style: const TextStyle(color: danger, fontSize: 12),
                        ),
                      ],
                      const SizedBox(height: 20),
                      ElevatedButton(
                        onPressed: _busy ? null : _login,
                        child: _busy
                            ? const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: bg,
                                ),
                              )
                            : const Text('Log In →'),
                      ),
                    ],
                  ),
                  // Signup
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      TextField(
                        controller: _sn,
                        decoration: const InputDecoration(labelText: 'Name'),
                      ),
                      const SizedBox(height: 12),
                      TextField(
                        controller: _se,
                        keyboardType: TextInputType.emailAddress,
                        onChanged: _valEmail,
                        decoration: InputDecoration(
                          labelText: 'Email',
                          hintText: 'you@example.com',
                          helperText: _ehint.isEmpty
                              ? 'e.g. name@gmail.com'
                              : _ehint,
                          helperStyle: TextStyle(color: _ehc, fontSize: 10),
                        ),
                      ),
                      const SizedBox(height: 12),
                      TextField(
                        controller: _sp,
                        obscureText: _os,
                        decoration: InputDecoration(
                          labelText: 'Password',
                          hintText: 'Min 6 characters',
                          suffixIcon: IconButton(
                            icon: Icon(
                              _os ? Icons.visibility_off : Icons.visibility,
                              color: dim,
                              size: 18,
                            ),
                            onPressed: () => setState(() => _os = !_os),
                          ),
                        ),
                      ),
                      if (_serr.isNotEmpty) ...[
                        const SizedBox(height: 8),
                        Text(
                          _serr,
                          style: const TextStyle(color: danger, fontSize: 12),
                        ),
                      ],
                      const SizedBox(height: 20),
                      ElevatedButton(
                        onPressed: _busy ? null : _signup,
                        child: _busy
                            ? const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: bg,
                                ),
                              )
                            : const Text('Create Account →'),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    ),
  );
}

// ════════════════════════════════════════════════════════════════════
// SETUP (ONBOARDING)
// ════════════════════════════════════════════════════════════════════
class SetupScreen extends StatefulWidget {
  const SetupScreen({super.key});
  @override
  State<SetupScreen> createState() => _SetupState();
}

class _SetupState extends State<SetupScreen> {
  int _step = 0;
  final _wt = TextEditingController(),
      _ht = TextEditingController(),
      _age = TextEditingController();
  String _gender = 'male', _intensity = 'intermediate';
  int _days = 3;
  final _muscles = <String>{};
  bool _busy = false;

  String _setupErr = '';

  bool _validateStep() {
    switch (_step) {
      case 0:
        if (_wt.text.trim().isEmpty || double.tryParse(_wt.text) == null) {
          setState(() => _setupErr = 'Enter a valid weight in kg (e.g. 70).');
          return false;
        }
        if (_ht.text.trim().isEmpty || double.tryParse(_ht.text) == null) {
          setState(() => _setupErr = 'Enter a valid height in cm (e.g. 170).');
          return false;
        }
        if (_age.text.trim().isEmpty || int.tryParse(_age.text) == null) {
          setState(() => _setupErr = 'Enter a valid age (e.g. 25).');
          return false;
        }
        break;
      case 2:
        if (_muscles.isEmpty) {
          setState(
            () => _setupErr = 'Select at least one muscle group to target.',
          );
          return false;
        }
        break;
    }
    setState(() => _setupErr = '');
    return true;
  }

  Future<void> _submit() async {
    if (!_validateStep()) return;
    setState(() => _busy = true);
    final r = await Api.setup({
      'days_per_week': _days,
      'muscle_groups': _muscles.toList(),
      'intensity': _intensity,
      'weight_kg': double.tryParse(_wt.text),
      'height_cm': double.tryParse(_ht.text),
      'age': int.tryParse(_age.text),
      'gender': _gender,
    });
    if (!mounted) return;
    setState(() => _busy = false);
    if (r['error'] != null) return;
    await context.read<AppState>().load();
    if (mounted) Navigator.pushReplacementNamed(context, '/home');
  }

  @override
  Widget build(BuildContext ctx) {
    return Scaffold(
      backgroundColor: bg,
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 16, 24, 0),
              child: Row(
                children: List.generate(
                  4,
                  (i) => Expanded(
                    child: Container(
                      height: 3,
                      margin: const EdgeInsets.symmetric(horizontal: 2),
                      decoration: BoxDecoration(
                        color: i <= _step ? accent : bd,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                ),
              ),
            ),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24),
                child: [
                  // Step 0: body stats
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('STEP 1 OF 4', style: lbl),
                      const SizedBox(height: 8),
                      Text('Your body\nstats', style: heading(34)),
                      const SizedBox(height: 6),
                      const Text(
                        'Optional — helps track calorie estimates.',
                        style: TextStyle(color: mid, fontSize: 12),
                      ),
                      const SizedBox(height: 20),
                      Row(
                        children: [
                          Expanded(
                            child: TextField(
                              controller: _wt,
                              keyboardType: TextInputType.number,
                              decoration: const InputDecoration(
                                labelText: 'Weight (kg)',
                                hintText: '70',
                              ),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: TextField(
                              controller: _ht,
                              keyboardType: TextInputType.number,
                              decoration: const InputDecoration(
                                labelText: 'Height (cm)',
                                hintText: '175',
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      Row(
                        children: [
                          Expanded(
                            child: TextField(
                              controller: _age,
                              keyboardType: TextInputType.number,
                              decoration: const InputDecoration(
                                labelText: 'Age',
                                hintText: '25',
                              ),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: DropdownButtonFormField<String>(
                              value: _gender,
                              decoration: const InputDecoration(
                                labelText: 'Gender',
                              ),
                              dropdownColor: s2,
                              style: const TextStyle(color: fg),
                              items: const [
                                DropdownMenuItem(
                                  value: 'male',
                                  child: Text('Male'),
                                ),
                                DropdownMenuItem(
                                  value: 'female',
                                  child: Text('Female'),
                                ),
                              ],
                              onChanged: (v) => setState(() => _gender = v!),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  // Step 1: days
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('STEP 2 OF 4', style: lbl),
                      const SizedBox(height: 8),
                      Text('Days per\nweek', style: heading(34)),
                      const SizedBox(height: 6),
                      const Text(
                        'How many days can you train?',
                        style: TextStyle(color: mid, fontSize: 12),
                      ),
                      const SizedBox(height: 20),
                      GridView.count(
                        crossAxisCount: 4,
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        crossAxisSpacing: 8,
                        mainAxisSpacing: 8,
                        childAspectRatio: 1.1,
                        children: List.generate(7, (i) {
                          final n = i + 1;
                          final sel = n == _days;
                          return GestureDetector(
                            onTap: () => setState(() => _days = n),
                            child: Container(
                              decoration: BoxDecoration(
                                color: sel ? accent : s1,
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(color: sel ? accent : bd),
                              ),
                              child: Center(
                                child: Text(
                                  '$n',
                                  style: heading(26, c: sel ? bg : fg),
                                ),
                              ),
                            ),
                          );
                        }),
                      ),
                    ],
                  ),
                  // Step 2: muscles
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('STEP 3 OF 4', style: lbl),
                      const SizedBox(height: 8),
                      Text('Focus\nareas', style: heading(34)),
                      const SizedBox(height: 6),
                      const Text(
                        'Which muscles do you want to target?',
                        style: TextStyle(color: mid, fontSize: 12),
                      ),
                      const SizedBox(height: 20),
                      Wrap(
                        spacing: 10,
                        runSpacing: 10,
                        children: [
                          for (final m in [
                            ('Chest', '💪'),
                            ('Back', '🔙'),
                            ('Legs', '🦵'),
                            ('Core', '🎯'),
                            ('Shoulders', '🏋️'),
                            ('Full body', '⚡'),
                          ])
                            GestureDetector(
                              onTap: () => setState(() {
                                final k = m.$1.toLowerCase();
                                _muscles.contains(k)
                                    ? _muscles.remove(k)
                                    : _muscles.add(k);
                              }),
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 14,
                                  vertical: 10,
                                ),
                                decoration: BoxDecoration(
                                  color: _muscles.contains(m.$1.toLowerCase())
                                      ? accent.withValues(alpha: .12)
                                      : s1,
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(
                                    color: _muscles.contains(m.$1.toLowerCase())
                                        ? accent
                                        : bd,
                                    width: _muscles.contains(m.$1.toLowerCase())
                                        ? 1.5
                                        : 1,
                                  ),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Text(
                                      m.$2,
                                      style: const TextStyle(fontSize: 16),
                                    ),
                                    const SizedBox(width: 8),
                                    Text(
                                      m.$1,
                                      style: TextStyle(
                                        color:
                                            _muscles.contains(
                                              m.$1.toLowerCase(),
                                            )
                                            ? accent
                                            : fg,
                                        fontWeight: FontWeight.w500,
                                        fontSize: 13,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                        ],
                      ),
                    ],
                  ),
                  // Step 3: intensity
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('STEP 4 OF 4', style: lbl),
                      const SizedBox(height: 8),
                      Text('Intensity\nlevel', style: heading(34)),
                      const SizedBox(height: 6),
                      const Text(
                        'Sets and rest times adapt to your choice.',
                        style: TextStyle(color: mid, fontSize: 12),
                      ),
                      const SizedBox(height: 20),
                      for (final t in [
                        (
                          'beginner',
                          'Beginner',
                          'New to training, take it easy.',
                        ),
                        (
                          'intermediate',
                          'Intermediate',
                          'Regularly active, ready to push.',
                        ),
                        (
                          'advanced',
                          'Advanced',
                          'Experienced, want a challenge.',
                        ),
                        ('athlete', 'Athlete', 'Elite — maximum effort.'),
                      ])
                        GestureDetector(
                          onTap: () => setState(() => _intensity = t.$1),
                          child: Container(
                            margin: const EdgeInsets.only(bottom: 10),
                            padding: const EdgeInsets.all(14),
                            decoration: BoxDecoration(
                              color: _intensity == t.$1
                                  ? accent.withValues(alpha: .08)
                                  : s1,
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(
                                color: _intensity == t.$1 ? accent : bd,
                                width: _intensity == t.$1 ? 1.5 : 1,
                              ),
                            ),
                            child: Row(
                              children: [
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        t.$2,
                                        style: TextStyle(
                                          color: _intensity == t.$1
                                              ? accent
                                              : fg,
                                          fontWeight: FontWeight.w600,
                                          fontSize: 14,
                                        ),
                                      ),
                                      Text(
                                        t.$3,
                                        style: const TextStyle(
                                          color: mid,
                                          fontSize: 11,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                if (_intensity == t.$1)
                                  const Icon(
                                    Icons.check_circle,
                                    color: accent,
                                    size: 18,
                                  ),
                              ],
                            ),
                          ),
                        ),
                    ],
                  ),
                ][_step],
              ),
            ),
            if (_setupErr.isNotEmpty)
              Padding(
                padding: const EdgeInsets.fromLTRB(24, 0, 24, 8),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 10,
                  ),
                  decoration: BoxDecoration(
                    color: danger.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: danger.withValues(alpha: 0.4)),
                  ),
                  child: Text(
                    _setupErr,
                    style: const TextStyle(color: danger, fontSize: 12),
                  ),
                ),
              ),
            if (_setupErr.isNotEmpty)
              Padding(
                padding: const EdgeInsets.fromLTRB(24, 0, 24, 8),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 10,
                  ),
                  decoration: BoxDecoration(
                    color: danger.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: danger.withValues(alpha: 0.4)),
                  ),
                  child: Text(
                    _setupErr,
                    style: const TextStyle(color: danger, fontSize: 12),
                  ),
                ),
              ),
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
              child: Row(
                children: [
                  if (_step > 0) ...[
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () => setState(() => _step--),
                        child: const Text('← Back'),
                      ),
                    ),
                    const SizedBox(width: 12),
                  ],
                  Expanded(
                    flex: 2,
                    child: ElevatedButton(
                      onPressed: _busy
                          ? null
                          : () {
                              if (!_validateStep()) return;
                              if (_step < 3)
                                setState(() => _step++);
                              else
                                _submit();
                            },
                      child: _busy
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: bg,
                              ),
                            )
                          : Text(_step < 3 ? 'Continue →' : 'Start Training →'),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ════════════════════════════════════════════════════════════════════
// HOME SHELL (bottom nav)
// ════════════════════════════════════════════════════════════════════
class HomeShell extends StatefulWidget {
  const HomeShell({super.key});
  @override
  State<HomeShell> createState() => _HomeShellState();
}

class _HomeShellState extends State<HomeShell> {
  int _tab = 0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback(
      (_) => context.read<AppState>().load(),
    );
  }

  @override
  Widget build(BuildContext ctx) {
    return Scaffold(
      backgroundColor: bg,
      body: Column(
        children: [
          // Topbar — matches original HTML: brand left, gems + settings right
          Selector<AppState, int>(
            selector: (_, s) => s.gems,
            builder: (ctx2, gems, _) => Container(
              color: const Color(0xFF070709),
              padding: EdgeInsets.fromLTRB(
                16,
                MediaQuery.of(ctx2).padding.top + 8,
                16,
                8,
              ),
              child: Row(
                children: [
                  Text('StreakFit', style: heading(22, c: accent)),
                  const Spacer(),
                  Row(
                    children: [
                      const Text('💎 ', style: TextStyle(fontSize: 13)),
                      Text(
                        '$gems',
                        style: const TextStyle(
                          color: gem,
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(width: 12),
                  GestureDetector(
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        fullscreenDialog: true,
                        builder: (_) => const SettingsScreen(),
                      ),
                    ),
                    child: const Text('⚙️', style: TextStyle(fontSize: 18)),
                  ),
                ],
              ),
            ),
          ),
          Container(height: 1, color: bd),
          Expanded(
            child: IndexedStack(
              index: _tab,
              children: [
                const TodayScreen(),
                const QuizScreen(),
                const ProgramsScreen(),
                const StoreScreen(),
                const ProfileScreen(),
              ],
            ),
          ),
        ],
      ),
      bottomNavigationBar: Container(
        decoration: const BoxDecoration(
          color: s1,
          border: Border(top: BorderSide(color: bd)),
        ),
        child: BottomNavigationBar(
          currentIndex: _tab,
          onTap: (i) => setState(() => _tab = i),
          backgroundColor: Colors.transparent,
          elevation: 0,
          selectedItemColor: accent,
          unselectedItemColor: dim,
          type: BottomNavigationBarType.fixed,
          items: const [
            BottomNavigationBarItem(
              icon: Text('⊞', style: TextStyle(fontSize: 20)),
              label: 'Today',
            ),
            BottomNavigationBarItem(
              icon: Text('🧠', style: TextStyle(fontSize: 20)),
              label: 'Quiz',
            ),
            BottomNavigationBarItem(
              icon: Text('🏋️', style: TextStyle(fontSize: 20)),
              label: 'Programs',
            ),
            BottomNavigationBarItem(
              icon: Text('💎', style: TextStyle(fontSize: 20)),
              label: 'Store',
            ),
            BottomNavigationBarItem(
              icon: Text('◉', style: TextStyle(fontSize: 20)),
              label: 'Profile',
            ),
          ],
        ),
      ),
    );
  }
}

// ════════════════════════════════════════════════════════════════════
// TODAY SCREEN
// ════════════════════════════════════════════════════════════════════
class TodayScreen extends StatefulWidget {
  const TodayScreen({super.key});
  @override
  State<TodayScreen> createState() => _TodayState();
}

class _TodayState extends State<TodayScreen> {
  // Week day names — Mon=0 to Sun=6, matches backend dow
  static const _dn = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];

  Widget _weekStrip(dynamic weekDone) {
    final done = <String, bool>{};
    if (weekDone is Map) {
      for (final k in weekDone.keys) done[k.toString()] = true;
    }
    // today's day index: Dart weekday 1=Mon..7=Sun → 0=Mon..6=Sun
    final todayIdx = (DateTime.now().weekday - 1).toString();
    return Row(
      children: List.generate(7, (i) {
        final key = i.toString();
        final isDone = done.containsKey(key);
        final isToday = key == todayIdx;
        return Expanded(
          child: Container(
            margin: const EdgeInsets.symmetric(horizontal: 2),
            padding: const EdgeInsets.symmetric(vertical: 7),
            decoration: BoxDecoration(
              color: isDone
                  ? accent.withValues(alpha: 0.10)
                  : Colors.transparent,
              borderRadius: BorderRadius.circular(6),
              border: Border.all(
                color: isDone
                    ? accent
                    : isToday
                    ? bd2
                    : bd,
                width: isDone
                    ? 2
                    : isToday
                    ? 1.5
                    : 1,
              ),
            ),
            child: Column(
              children: [
                Text(
                  _dn[i],
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 8,
                    letterSpacing: 0.3,
                    color: isDone
                        ? accent
                        : isToday
                        ? fg
                        : dim,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  isDone ? '✓' : '',
                  style: TextStyle(
                    fontSize: 7,
                    color: isDone ? accent : Colors.transparent,
                  ),
                ),
              ],
            ),
          ),
        );
      }),
    );
  }

  Widget _hudPill(String t, Color c) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
    decoration: BoxDecoration(
      color: s1,
      borderRadius: BorderRadius.circular(999),
      border: Border.all(color: bd),
    ),
    child: Text(
      t,
      style: TextStyle(color: c, fontSize: 11, fontWeight: FontWeight.w500),
    ),
  );
  Map<String, dynamic>? _td;
  bool _loading = true;

  String _lastAccessKey = '';

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Reload today workout whenever program_access changes in AppState
    // (fires after purchase/activation patches AppState)
    final data = context.read<AppState>().data;
    final access = data['program_access'];
    final refresh = data['_refresh']?.toString() ?? '';
    final key = (access?.toString() ?? '') + refresh;
    if (key != _lastAccessKey && _lastAccessKey.isNotEmpty) {
      _lastAccessKey = key;
      _load();
    } else {
      _lastAccessKey = key;
    }
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    final r = await Api.todayWorkout();
    if (mounted)
      setState(() {
        _td = r;
        _loading = false;
      });
  }

  Future<void> _start(
    List exs,
    String group, {
    bool program = false,
    String? title,
    int? week,
  }) async {
    final ok = await confirm(
      context,
      emoji: program ? '🏋️' : '💪',
      title: program ? (title ?? 'Program Workout') : 'Ready to train?',
      desc: program
          ? 'Week $week · ${exs.length} exercises'
          : '${exs.length} exercises · ${_td?['intensity'] ?? 'intermediate'}',
    );
    if (!ok || !mounted) return;
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => WorkoutScreen(
          exercises: List<Map<String, dynamic>>.from(exs),
          group: group,
          isBonus: false,
          isProgram: program,
        ),
      ),
    );
    _load();
  }

  @override
  Widget build(BuildContext ctx) {
    if (_loading)
      return const Center(child: CircularProgressIndicator(color: accent));
    final td = _td ?? {};
    if (td['error'] != null || td['exercises'] == null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text('⚠️', style: TextStyle(fontSize: 32)),
            const SizedBox(height: 12),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Text(
                td['error']?.toString() ??
                    'Could not load workout. Make sure you are logged in.',
                style: const TextStyle(color: mid, fontSize: 13),
                textAlign: TextAlign.center,
              ),
            ),
            const SizedBox(height: 16),
            ElevatedButton(onPressed: _load, child: const Text('Retry')),
          ],
        ),
      );
    }
    final done = td['done_today'] == true;
    final exsRaw = td['exercises'];
    final exs = exsRaw is List
        ? List<Map<String, dynamic>>.from(exsRaw)
        : <Map<String, dynamic>>[];
    final extras = List<Map<String, dynamic>>.from(td['program_extras'] ?? []);
    final streak = ctx.watch<AppState>().streak;

    return RefreshIndicator(
      color: accent,
      backgroundColor: s1,
      onRefresh: _load,
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(done ? 'COMPLETED' : 'TODAY', style: lbl),
                  const SizedBox(height: 4),
                  Text(done ? 'Rest up 💤' : 'Your Plan', style: heading(28)),
                ],
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text('$streak', style: heading(52, c: accent)),
                  const Text(
                    'days 🔥',
                    style: TextStyle(fontSize: 9, color: dim),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              _hudPill('💎 ${ctx.watch<AppState>().gems}', gem),
              const SizedBox(width: 8),
              _hudPill('🛡️ ${ctx.watch<AppState>().shields} shields', mid),
            ],
          ),
          const SizedBox(height: 14),
          // ── Week strip — Mon to Sun, matches original HTML ────────
          _weekStrip(ctx.watch<AppState>().data['week_done']),
          const SizedBox(height: 14),
          // Week progress
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('THIS WEEK', style: lbl),
              Text(
                '${td['days_done'] ?? 0}/${td['days_per_week'] ?? 3}',
                style: const TextStyle(fontSize: 11, color: dim),
              ),
            ],
          ),
          const SizedBox(height: 6),
          ClipRRect(
            borderRadius: BorderRadius.circular(3),
            child: LinearProgressIndicator(
              value: (td['days_per_week'] ?? 3) > 0
                  ? (td['days_done'] ?? 0) / (td['days_per_week'] ?? 3)
                  : 0,
              backgroundColor: s2,
              color: accent,
              minHeight: 4,
            ),
          ),
          const SizedBox(height: 16),
          // Exercises
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text("Today's exercises", style: lbl),
              Row(
                children: [
                  pill((td['group'] ?? '').toString().toUpperCase(), accent),
                  const SizedBox(width: 6),
                  pill(td['intensity'] ?? 'intermediate', accent),
                ],
              ),
            ],
          ),
          const SizedBox(height: 10),
          ...exs.map((e) => exRow(e, dim_: done)),
          const SizedBox(height: 12),
          if (!done)
            Text(
              '+${td['gems_reward'] ?? 15} 💎 for completing today',
              style: const TextStyle(color: gem, fontSize: 11),
            ),
          const SizedBox(height: 10),
          if (exs.isEmpty)
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: s1,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: bd),
              ),
              child: const Text(
                'No exercises found. Check your plan in Profile → Settings.',
                style: TextStyle(color: mid, fontSize: 12),
              ),
            )
          else
            ElevatedButton(
              onPressed: done ? null : () => _start(exs, td['group'] ?? ''),
              style: ElevatedButton.styleFrom(
                minimumSize: const Size(double.infinity, 48),
                disabledBackgroundColor: s2,
                disabledForegroundColor: dim,
              ),
              child: Text(done ? '✓ Workout Done Today' : 'Start Workout →'),
            ),
          const SizedBox(height: 8),
          if (done)
            OutlinedButton(
              onPressed: _openBonus,
              style: OutlinedButton.styleFrom(
                minimumSize: const Size(double.infinity, 48),
                side: const BorderSide(color: gem),
              ),
              child: const Text(
                'Unlock Bonus Workout 💎',
                style: TextStyle(color: gem),
              ),
            ),
          // Program extras — always shown regardless of daily workout status
          if (extras.isNotEmpty) const SizedBox(height: 8),
          ...extras.map((pe) {
            final peExs = List<Map<String, dynamic>>.from(
              pe['exercises'] ?? [],
            );
            final c = hexColor(pe['program_color'] ?? '#c8f55a');
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Divider(height: 24),
                const Text('ACTIVE PROGRAM', style: lbl),
                const SizedBox(height: 6),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        '${pe['program_emoji']} ${pe['program_title']} — Wk ${pe['program_week']}: ${pe['program_focus']}',
                        style: const TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 13,
                        ),
                      ),
                    ),
                    GestureDetector(
                      onTap: () async {
                        await Api.deactivateProgram(pe['program_id']);
                        _load();
                      },
                      child: const Padding(
                        padding: EdgeInsets.all(4),
                        child: Text(
                          '✕',
                          style: TextStyle(color: dim, fontSize: 13),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                ...peExs.map((e) => exRow(e)),
                const SizedBox(height: 10),
                ElevatedButton(
                  onPressed: () => _start(
                    peExs,
                    pe['program_id'],
                    program: true,
                    title: pe['program_title'],
                    week: pe['program_week'],
                  ),
                  style: ElevatedButton.styleFrom(
                    minimumSize: const Size(double.infinity, 44),
                    backgroundColor: c,
                    foregroundColor: bg,
                  ),
                  child: const Text('▶ Start Program Workout →'),
                ),
              ],
            );
          }),
        ],
      ),
    );
  }

  Future<void> _openBonus() async {
    final groups = ['chest', 'back', 'legs', 'core', 'shoulders', 'full'];
    String? chosen;
    await showModalBottomSheet(
      context: context,
      backgroundColor: s1,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (_) => StatefulBuilder(
        builder: (ctx2, setS) => Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('Bonus Workout', style: heading(22)),
              const SizedBox(height: 6),
              const Text(
                '40 💎 · Extra session, different exercises',
                style: TextStyle(color: mid, fontSize: 12),
              ),
              const SizedBox(height: 16),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: groups.map((g) {
                  final sel = g == chosen;
                  return GestureDetector(
                    onTap: () => setS(() => chosen = g),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        color: sel ? gem.withValues(alpha: .12) : s2,
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(color: sel ? gem : bd),
                      ),
                      child: Text(
                        g[0].toUpperCase() + g.substring(1),
                        style: TextStyle(color: sel ? gem : fg, fontSize: 13),
                      ),
                    ),
                  );
                }).toList(),
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: chosen == null
                    ? null
                    : () async {
                        Navigator.pop(ctx2);
                        final ok2 = await confirm(
                          context,
                          emoji: '🔥',
                          title: 'Bonus Workout',
                          desc: 'Spend 40 💎 for a bonus session?',
                        );
                        if (!ok2 || !mounted) return;
                        final r = await Api.unlockBonus('gems');
                        if (r['error'] != null && mounted) {
                          ScaffoldMessenger.of(
                            context,
                          ).showSnackBar(SnackBar(content: Text(r['error'])));
                          return;
                        }
                        final er = await Api.bonusExercises(chosen!);
                        if (!mounted) return;
                        await Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => WorkoutScreen(
                              exercises: List<Map<String, dynamic>>.from(
                                er['exercises'] ?? [],
                              ),
                              group: chosen!,
                              isBonus: true,
                              isProgram: false,
                            ),
                          ),
                        );
                        _load();
                      },
                style: ElevatedButton.styleFrom(
                  minimumSize: const Size(double.infinity, 46),
                  backgroundColor: gem,
                  foregroundColor: Colors.white,
                ),
                child: const Text('Unlock with 💎 Gems'),
              ),
              const SizedBox(height: 8),
              OutlinedButton(
                onPressed: () => Navigator.pop(ctx2),
                style: OutlinedButton.styleFrom(
                  minimumSize: const Size(double.infinity, 46),
                ),
                child: const Text('Maybe Later'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ════════════════════════════════════════════════════════════════════
// WORKOUT SCREEN
// ════════════════════════════════════════════════════════════════════
class WorkoutScreen extends StatefulWidget {
  final List<Map<String, dynamic>> exercises;
  final String group;
  final bool isBonus, isProgram;
  const WorkoutScreen({
    super.key,
    required this.exercises,
    required this.group,
    required this.isBonus,
    required this.isProgram,
  });
  @override
  State<WorkoutScreen> createState() => _WorkoutState();
}

class _WorkoutState extends State<WorkoutScreen> {
  int _ei = 0, _si = 0, _totalSets = 0, _restSecs = 0;
  bool _resting = false, _finishing = false;
  Timer? _timer;

  Map<String, dynamic> get _ex =>
      (_ei < widget.exercises.length) ? widget.exercises[_ei] : {};
  int get _sets {
    final s = _ex['sets'];
    return s != null ? (s as num).toInt() : 3;
  }

  int get _rest {
    final r = _ex['rest'];
    return r != null ? (r as num).toInt() : 60;
  }

  void _startRest() {
    setState(() {
      _resting = true;
      _restSecs = _rest;
    });
    _timer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (!mounted) {
        t.cancel();
        return;
      }
      setState(() => _restSecs--);
      if (_restSecs <= 0) {
        t.cancel();
        haptic(true);
        sndStart();
        setState(() => _resting = false);
      }
    });
  }

  void _next() {
    haptic();
    sndClick();
    _totalSets++;
    if (_si + 1 < _sets) {
      setState(() => _si++);
      _startRest();
    } else if (_ei + 1 < widget.exercises.length) {
      setState(() {
        _ei++;
        _si = 0;
      });
      _startRest();
    } else
      _finish();
  }

  Future<void> _finish() async {
    if (_finishing) return;
    _timer?.cancel();
    setState(() => _finishing = true);
    sndStart(); // fanfare on workout complete
    haptic(true);
    await Future.delayed(const Duration(milliseconds: 400));
    final r = await Api.completeWorkout({
      'group': widget.group,
      'exercises': widget.exercises.length,
      'sets': _totalSets,
      'is_bonus': widget.isBonus,
      'is_program': widget.isProgram,
    });
    if (!mounted) return;
    // Update HUD immediately so streak/gems show new values
    if (r['error'] == null) {
      context.read<AppState>().patch({
        'streak': r['streak'] ?? 0,
        'best_streak': r['best_streak'] ?? 0,
        'gems': r['gems'] ?? 0,
        'shields': r['shields'] ?? 0,
      });
    }
    await showModalBottomSheet(
      context: context,
      isDismissible: false,
      backgroundColor: s1,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 36,
              height: 4,
              decoration: BoxDecoration(
                color: bd2,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 20),
            const Text('🏆', style: TextStyle(fontSize: 48)),
            const SizedBox(height: 10),
            Text('WORKOUT COMPLETE', style: heading(26, c: accent)),
            const SizedBox(height: 8),
            Text(
              '${widget.exercises.length} exercises · $_totalSets sets',
              style: const TextStyle(color: mid, fontSize: 13),
            ),
            const SizedBox(height: 12),
            Text('${r['streak'] ?? 0}', style: heading(64, c: warn)),
            const Text(
              'DAY STREAK 🔥',
              style: TextStyle(color: dim, fontSize: 13, letterSpacing: 1),
            ),
            const SizedBox(height: 14),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: gem.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: gem.withValues(alpha: 0.3)),
                  ),
                  child: Text(
                    '💎 +${r['gems_earned'] ?? 0}',
                    style: const TextStyle(
                      color: gem,
                      fontWeight: FontWeight.w600,
                      fontSize: 13,
                    ),
                  ),
                ),
                if ((r['kcal'] as int? ?? 0) > 0) ...[
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: warn.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: warn.withValues(alpha: 0.3)),
                    ),
                    child: Text(
                      '🔥 ~${r['kcal']} kcal',
                      style: const TextStyle(
                        color: warn,
                        fontWeight: FontWeight.w600,
                        fontSize: 13,
                      ),
                    ),
                  ),
                ],
              ],
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(context);
                Navigator.pop(context);
              },
              style: ElevatedButton.styleFrom(
                minimumSize: const Size(double.infinity, 48),
              ),
              child: const Text('Continue →'),
            ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext ctx) {
    // Guard: if exercises list is empty, show error instead of crashing
    if (widget.exercises.isEmpty) {
      return Scaffold(
        backgroundColor: bg,
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text(
                "No exercises found",
                style: TextStyle(color: mid, fontSize: 16),
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () => Navigator.pop(ctx),
                child: const Text("Go Back"),
              ),
            ],
          ),
        ),
      );
    }
    final ex = _ex;
    return Scaffold(
      backgroundColor: bg,
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
              child: Row(
                children: [
                  GestureDetector(
                    onTap: () async {
                      final ok = await showDialog<bool>(
                        context: ctx,
                        builder: (_) => AlertDialog(
                          backgroundColor: s1,
                          title: const Text('Exit workout?'),
                          content: const Text(
                            'Your progress will be lost.',
                            style: TextStyle(color: mid),
                          ),
                          actions: [
                            TextButton(
                              onPressed: () => Navigator.pop(ctx, false),
                              child: const Text(
                                'Keep going',
                                style: TextStyle(color: accent),
                              ),
                            ),
                            TextButton(
                              onPressed: () => Navigator.pop(ctx, true),
                              child: const Text(
                                'Exit',
                                style: TextStyle(color: danger),
                              ),
                            ),
                          ],
                        ),
                      );
                      if (ok == true && mounted) {
                        Navigator.pop(ctx);
                      }
                    },
                    child: const Icon(Icons.close, color: mid, size: 22),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '${_ei + 1} / ${widget.exercises.length}',
                          style: lbl,
                        ),
                        LinearProgressIndicator(
                          value: (_ei + 1) / widget.exercises.length,
                          backgroundColor: s2,
                          color: accent,
                          minHeight: 3,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 12),
                  Text(
                    '$_totalSets sets',
                    style: const TextStyle(color: dim, fontSize: 11),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 8),
            Expanded(child: _resting ? _restView() : _exView(ex)),
            if (!_resting)
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 20),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: List.generate(
                        _sets,
                        (i) => Container(
                          width: 10,
                          height: 10,
                          margin: const EdgeInsets.symmetric(horizontal: 3),
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: i < _si
                                ? accent
                                : i == _si
                                ? accent.withValues(alpha: .5)
                                : s2,
                            border: Border.all(color: i <= _si ? accent : bd),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'Set ${_si + 1} of $_sets',
                      style: const TextStyle(color: dim, fontSize: 11),
                    ),
                    const SizedBox(height: 12),
                    ElevatedButton(
                      onPressed: _next,
                      style: ElevatedButton.styleFrom(
                        minimumSize: const Size(double.infinity, 52),
                        textStyle: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      child: Text(
                        _si + 1 < _sets
                            ? 'Done Set →'
                            : _ei + 1 < widget.exercises.length
                            ? 'Next Exercise →'
                            : '🏁 Finish',
                      ),
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _exView(Map<String, dynamic> ex) => Padding(
    padding: const EdgeInsets.symmetric(horizontal: 16),
    child: Column(
      children: [
        Container(
          width: 100,
          height: 100,
          decoration: BoxDecoration(
            color: accent.withValues(alpha: .08),
            shape: BoxShape.circle,
            border: Border.all(color: accent.withValues(alpha: .25), width: 2),
          ),
          child: Center(
            child: Text(
              ex['emoji'] ?? '🏋️',
              style: const TextStyle(fontSize: 44),
            ),
          ),
        ),
        const SizedBox(height: 18),
        Text(ex['name'] ?? '', style: heading(30), textAlign: TextAlign.center),
        const SizedBox(height: 10),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 6),
          decoration: BoxDecoration(
            color: accent.withValues(alpha: .12),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Text(
            '${ex['reps']}',
            style: const TextStyle(
              color: accent,
              fontSize: 22,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
        const SizedBox(height: 14),
        if ((ex['desc'] ?? '').isNotEmpty)
          Text(
            ex['desc'],
            textAlign: TextAlign.center,
            style: const TextStyle(color: mid, fontSize: 12),
          ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 8,
          runSpacing: 6,
          alignment: WrapAlignment.center,
          children: [
            for (final c in List<String>.from(ex['cues'] ?? []))
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 5,
                ),
                decoration: BoxDecoration(
                  color: s2,
                  borderRadius: BorderRadius.circular(4),
                  border: Border.all(color: bd),
                ),
                child: Text(
                  c,
                  style: const TextStyle(color: dim, fontSize: 10),
                ),
              ),
          ],
        ),
      ],
    ),
  );

  Widget _restView() => Column(
    mainAxisAlignment: MainAxisAlignment.center,
    children: [
      const Text('REST', style: lbl),
      const SizedBox(height: 12),
      TweenAnimationBuilder<double>(
        key: ValueKey(_restSecs),
        tween: Tween(
          begin: _rest > 0 ? (_restSecs + 1) / _rest : 1.0,
          end: _rest > 0 ? _restSecs / _rest : 0.0,
        ),
        duration: const Duration(milliseconds: 950),
        curve: Curves.linear,
        builder: (_, value, __) => Stack(
          alignment: Alignment.center,
          children: [
            SizedBox(
              width: 160,
              height: 160,
              child: CircularProgressIndicator(
                value: value,
                strokeWidth: 6,
                backgroundColor: s2,
                color: _restSecs <= 3 ? danger : accent,
              ),
            ),
            Column(
              children: [
                Text(
                  '$_restSecs',
                  style: heading(64, c: _restSecs <= 3 ? danger : accent),
                ),
                const Text(
                  'seconds',
                  style: TextStyle(color: dim, fontSize: 12),
                ),
              ],
            ),
          ],
        ),
      ),
      const SizedBox(height: 28),
      OutlinedButton(
        onPressed: () {
          _timer?.cancel();
          setState(() => _resting = false);
        },
        child: const Text('Skip Rest →'),
      ),
    ],
  );
}

// ════════════════════════════════════════════════════════════════════
// QUIZ SCREEN
// ════════════════════════════════════════════════════════════════════
class QuizScreen extends StatefulWidget {
  const QuizScreen({super.key});
  @override
  State<QuizScreen> createState() => _QuizState();
}

class _QuizState extends State<QuizScreen> {
  Map<String, dynamic>? _data;
  bool _loading = true, _answered = false, _submitting = false;
  int? _sel;
  Map<String, dynamic>? _ar;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _answered = false;
      _sel = null;
      _ar = null;
    });
    final r = await Api.quizToday();
    if (mounted)
      setState(() {
        _data = r;
        _loading = false;
      });
  }

  Future<void> _submit() async {
    if (_sel == null || _answered || _submitting) return;
    setState(() => _submitting = true);
    final r = await Api.answerQuiz(_sel!);
    if (!mounted) return;
    setState(() {
      _submitting = false;
      _answered = true;
      _ar = r;
    });
    if (r['gems'] != null) context.read<AppState>().patch({'gems': r['gems']});
    if (r['session_done'] == true || (r['lives'] as int? ?? 1) <= 0) {
      await Future.delayed(const Duration(milliseconds: 1800));
      if (mounted) _load();
    }
  }

  @override
  Widget build(BuildContext ctx) {
    if (_loading)
      return const Center(child: CircularProgressIndicator(color: accent));
    final d = _data ?? {};
    if (d['error'] != null)
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(d['error'], style: const TextStyle(color: mid)),
            const SizedBox(height: 12),
            ElevatedButton(onPressed: _load, child: const Text('Retry')),
          ],
        ),
      );

    if (d['done'] == true) return _doneView(d);
    final lives = d['lives'] as int? ?? 0;
    if (lives <= 0) return _reviveView(d);

    final q = d['quiz'] as Map? ?? {};
    final opts = List<String>.from(q['opts'] ?? []);
    final correct = _ar?['correct_answer'] as int?;
    final maxLives = d['max_lives'] as int? ?? 2;
    final numDone = d['num_done'] as int? ?? 0;
    final total = d['total'] as int? ?? 10;

    return RefreshIndicator(
      color: accent,
      backgroundColor: s1,
      onRefresh: _load,
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('DAILY QUIZ', style: lbl),
                  const SizedBox(height: 4),
                  Text('Brain\nTraining', style: heading(28)),
                ],
              ),
              Row(
                children: List.generate(
                  maxLives,
                  (i) => Text(
                    i < lives ? '❤️' : '🖤',
                    style: const TextStyle(fontSize: 22),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('PROGRESS', style: lbl),
              Text(
                '$numDone / $total',
                style: const TextStyle(fontSize: 11, color: dim),
              ),
            ],
          ),
          const SizedBox(height: 6),
          ClipRRect(
            borderRadius: BorderRadius.circular(3),
            child: LinearProgressIndicator(
              value: total > 0 ? numDone / total : 0,
              backgroundColor: s2,
              color: accent,
              minHeight: 4,
            ),
          ),
          const SizedBox(height: 20),
          // Question card
          Container(
            decoration: BoxDecoration(
              color: s1,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: bd),
            ),
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Text(
                    q['q'] ?? '',
                    style: const TextStyle(
                      color: fg,
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      height: 1.4,
                    ),
                  ),
                ),
                const Divider(height: 1),
                ...opts.asMap().entries.map((e) {
                  final i = e.key;
                  final opt = e.value;
                  Color bg_ = s2, bd_ = bd, txt = fg;
                  IconData? ic;
                  if (_answered && _ar != null) {
                    if (i == correct) {
                      bg_ = safe.withValues(alpha: .1);
                      bd_ = safe;
                      txt = safe;
                      ic = Icons.check_circle;
                    } else if (i == _sel && _ar!['correct'] == false) {
                      bg_ = danger.withValues(alpha: .1);
                      bd_ = danger;
                      txt = danger;
                      ic = Icons.cancel;
                    }
                  } else if (_sel == i && !_answered) {
                    bg_ = accent.withValues(alpha: .1);
                    bd_ = accent;
                    txt = accent;
                  }
                  return GestureDetector(
                    onTap: _answered ? null : () => setState(() => _sel = i),
                    child: Container(
                      margin: const EdgeInsets.fromLTRB(12, 6, 12, 0),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 12,
                      ),
                      decoration: BoxDecoration(
                        color: bg_,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: bd_),
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: Text(
                              opt,
                              style: TextStyle(color: txt, fontSize: 13),
                            ),
                          ),
                          if (ic != null) Icon(ic, color: txt, size: 18),
                        ],
                      ),
                    ),
                  );
                }),
                // Confirm/cancel
                if (!_answered && _sel != null) ...[
                  const SizedBox(height: 12),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(12, 0, 12, 0),
                    child: Row(
                      children: [
                        Expanded(
                          child: ElevatedButton(
                            onPressed: _submitting ? null : _submit,
                            style: ElevatedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 12),
                            ),
                            child: _submitting
                                ? const SizedBox(
                                    width: 18,
                                    height: 18,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      color: bg,
                                    ),
                                  )
                                : const Text(
                                    'Submit →',
                                    style: TextStyle(fontSize: 13),
                                  ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        OutlinedButton(
                          onPressed: () => setState(() => _sel = null),
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 14,
                              vertical: 12,
                            ),
                          ),
                          child: const Text(
                            'Cancel',
                            style: TextStyle(fontSize: 13),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
                // Explanation
                if (_answered && _ar != null) ...[
                  const SizedBox(height: 8),
                  Container(
                    margin: const EdgeInsets.fromLTRB(12, 0, 12, 0),
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: (_ar!['correct'] == true ? safe : danger)
                          .withValues(alpha: .08),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: (_ar!['correct'] == true ? safe : danger)
                            .withValues(alpha: .3),
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _ar!['correct'] == true
                              ? '✓ Correct! +${_ar!['gems_earned']} gems'
                              : '✗ Wrong',
                          style: TextStyle(
                            color: _ar!['correct'] == true ? safe : danger,
                            fontWeight: FontWeight.w700,
                            fontSize: 13,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          _ar!['explanation'] ?? '',
                          style: const TextStyle(
                            color: mid,
                            fontSize: 12,
                            height: 1.5,
                          ),
                        ),
                      ],
                    ),
                  ),
                  if ((_ar!['session_done'] != true) &&
                      (_ar!['lives'] as int? ?? 1) > 0) ...[
                    const SizedBox(height: 10),
                    Padding(
                      padding: const EdgeInsets.fromLTRB(12, 0, 12, 0),
                      child: ElevatedButton(
                        onPressed: _load,
                        style: ElevatedButton.styleFrom(
                          minimumSize: const Size(double.infinity, 44),
                        ),
                        child: const Text('Next Question →'),
                      ),
                    ),
                  ],
                ],
                const SizedBox(height: 12),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _doneView(Map d) => Center(
    child: Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Text('🏆', style: TextStyle(fontSize: 56)),
          const SizedBox(height: 14),
          Text('Quiz Complete!', style: heading(28, c: accent)),
          const SizedBox(height: 8),
          Text(
            '${d['num_done']} of ${d['total']} correct',
            style: const TextStyle(color: mid, fontSize: 14),
          ),
          const SizedBox(height: 14),
          pill(
            '💎 +${(d['num_done'] ?? 0) * 5 + ((d['num_done'] ?? 0) >= (d['total'] ?? 10) ? 20 : 0)} gems today',
            gem,
          ),
          const SizedBox(height: 10),
          const Text(
            'Come back tomorrow!',
            style: TextStyle(color: dim, fontSize: 12),
          ),
        ],
      ),
    ),
  );

  Widget _reviveView(Map d) => Center(
    child: Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Text('💀', style: TextStyle(fontSize: 56)),
          const SizedBox(height: 14),
          Text('No lives left', style: heading(26)),
          const SizedBox(height: 8),
          const Text(
            'Revive with gems or an ad to continue.',
            textAlign: TextAlign.center,
            style: TextStyle(color: mid, fontSize: 13),
          ),
          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: () async {
              final r = await Api.reviveQuiz('gems');
              if (!mounted) return;
              if (r['ok'] == true) _load();
            },
            style: ElevatedButton.styleFrom(
              minimumSize: const Size(200, 46),
              backgroundColor: gem,
              foregroundColor: Colors.white,
            ),
            child: Text('💎 ${d['revive_cost'] ?? 50} Gems'),
          ),
          const SizedBox(height: 8),
          OutlinedButton(
            onPressed: () async {
              final r = await Api.reviveQuiz('ad');
              if (!mounted) return;
              if (r['ok'] == true) _load();
            },
            style: OutlinedButton.styleFrom(
              minimumSize: const Size(200, 46),
              side: const BorderSide(color: warn),
            ),
            child: const Text('📺 Watch Ad', style: TextStyle(color: warn)),
          ),
        ],
      ),
    ),
  );
}

// ════════════════════════════════════════════════════════════════════
// PROGRAMS SCREEN
// ════════════════════════════════════════════════════════════════════
class ProgramsScreen extends StatefulWidget {
  const ProgramsScreen({super.key});
  @override
  State<ProgramsScreen> createState() => _ProgramsState();
}

class _ProgramsState extends State<ProgramsScreen> {
  String? _expanded;

  @override
  Widget build(BuildContext ctx) {
    final st = ctx.watch<AppState>().data;
    final progs = List<Map<String, dynamic>>.from(
      st['training_programs'] ?? [],
    );
    final access = Map<String, dynamic>.from(st['program_access'] ?? {});
    final today = DateTime.now().toIso8601String().substring(0, 10);
    final gems = st['gems'] as int? ?? 0;

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        const Text('PREMIUM', style: lbl),
        const SizedBox(height: 4),
        Text('Programs', style: heading(28)),
        const SizedBox(height: 8),
        const Text(
          'Structured training plans. Each purchase = 7 days full access.',
          style: TextStyle(color: mid, fontSize: 12, height: 1.5),
        ),
        const SizedBox(height: 16),
        ...progs.map((p) {
          final id = p['id'] as String;
          final exp = access[id] as String? ?? '';
          final active = exp.isNotEmpty && exp.compareTo(today) >= 0;
          final daysLeft = active
              ? DateTime.parse(exp).difference(DateTime.now()).inDays + 1
              : 0;
          final col = hexColor(p['color'] ?? '#c8f55a');
          final works = List<Map<String, dynamic>>.from(p['workouts'] ?? []);
          final isOpen = _expanded == id;
          final apList = st['active_program'];
          return Container(
            margin: const EdgeInsets.only(bottom: 10),
            decoration: BoxDecoration(
              color: s1,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: active ? col.withValues(alpha: .5) : bd,
              ),
            ),
            child: Column(
              children: [
                if (active)
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: col.withValues(alpha: .1),
                      borderRadius: const BorderRadius.vertical(
                        top: Radius.circular(12),
                      ),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.check_circle, color: col, size: 14),
                        const SizedBox(width: 6),
                        Text(
                          'Active — ${daysLeft}d left',
                          style: TextStyle(
                            color: col,
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                Padding(
                  padding: const EdgeInsets.all(14),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            width: 46,
                            height: 46,
                            decoration: BoxDecoration(
                              color: col.withValues(alpha: .1),
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(
                                color: col.withValues(alpha: .3),
                              ),
                            ),
                            child: Center(
                              child: Text(
                                p['emoji'] ?? '🏋️',
                                style: const TextStyle(fontSize: 22),
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  p['level'] ?? '',
                                  style: TextStyle(
                                    color: col,
                                    fontSize: 9,
                                    letterSpacing: 1,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                Text(p['title'] ?? '', style: heading(18)),
                                Text(
                                  p['tagline'] ?? '',
                                  style: const TextStyle(
                                    color: mid,
                                    fontSize: 10,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      Row(
                        children: [
                          pill('📅 ${p['weeks']} weeks', dim),
                          const SizedBox(width: 8),
                          pill('⏱️ 7-day access', gem),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(
                            child: OutlinedButton(
                              onPressed: () => setState(
                                () => _expanded = isOpen ? null : id,
                              ),
                              child: Text(isOpen ? 'Hide ▲' : 'View Details ▼'),
                            ),
                          ),
                          if (!active) ...[
                            const SizedBox(width: 8),
                            ElevatedButton(
                              onPressed: () async {
                                if (gems < (p['cost'] as int)) {
                                  ScaffoldMessenger.of(ctx).showSnackBar(
                                    SnackBar(
                                      content: Text(
                                        'Need ${p['cost']} 💎 — you have $gems',
                                      ),
                                    ),
                                  );
                                  return;
                                }
                                final ok = await showProgramPurchaseDialog(
                                  ctx,
                                  emoji: p['emoji'] as String? ?? '🏋️',
                                  title: p['title'] as String? ?? '',
                                  cost: p['cost'] as int? ?? 0,
                                  tagline: p['tagline'] as String? ?? '',
                                );
                                if (!ok || !ctx.mounted) return;
                                final r = await Api.purchaseProgram(id);
                                if (!ctx.mounted) return;
                                if (r['error'] != null) {
                                  ScaffoldMessenger.of(ctx).showSnackBar(
                                    SnackBar(content: Text(r['error'])),
                                  );
                                  return;
                                }
                                // Instantly update program_access + gems
                                if (r['expiry'] != null) {
                                  final newAcc = Map<String, dynamic>.from(
                                    ctx
                                            .read<AppState>()
                                            .data['program_access'] ??
                                        {},
                                  );
                                  newAcc[id] = r['expiry'];
                                  // Patch with a refresh token so TodayScreen reloads
                                  ctx.read<AppState>().patch({
                                    'program_access': newAcc,
                                    'gems':
                                        r['gems'] ?? ctx.read<AppState>().gems,
                                    '_refresh':
                                        DateTime.now().millisecondsSinceEpoch,
                                  });
                                } else {
                                  ctx.read<AppState>().load();
                                }
                              },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: gem,
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 14,
                                  vertical: 12,
                                ),
                              ),
                              child: Text(
                                '💎 ${p['cost']}',
                                style: const TextStyle(fontSize: 13),
                              ),
                            ),
                          ],
                        ],
                      ),
                    ],
                  ),
                ),
                if (isOpen) ...[
                  const Divider(height: 1),
                  Padding(
                    padding: const EdgeInsets.all(14),
                    child: Column(
                      children: works.map((w) {
                        final wNum = w['week'] as int;
                        final isThisActive =
                            apList is List &&
                            apList.any(
                              (x) => x['id'] == id && x['week'] == wNum,
                            );
                        final exs = List<String>.from(w['exercises'] ?? []);
                        return Container(
                          margin: const EdgeInsets.only(bottom: 8),
                          decoration: BoxDecoration(
                            color: bg,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                              color: isThisActive ? col : bd,
                              width: isThisActive ? 1.5 : 1,
                            ),
                          ),
                          child: Column(
                            children: [
                              Padding(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 14,
                                  vertical: 12,
                                ),
                                child: Row(
                                  children: [
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            'Week $wNum${isThisActive ? ' ✓' : ''}',
                                            style: TextStyle(
                                              color: isThisActive ? col : fg,
                                              fontWeight: FontWeight.w600,
                                              fontSize: 13,
                                            ),
                                          ),
                                          Text(
                                            w['focus'] ?? '',
                                            style: const TextStyle(
                                              color: dim,
                                              fontSize: 10,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const Divider(height: 1),
                              Padding(
                                padding: const EdgeInsets.fromLTRB(
                                  14,
                                  10,
                                  14,
                                  14,
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    ...exs.map(
                                      (e) => Padding(
                                        padding: const EdgeInsets.symmetric(
                                          vertical: 3,
                                        ),
                                        child: Row(
                                          children: [
                                            const Text(
                                              '• ',
                                              style: TextStyle(
                                                color: dim,
                                                fontSize: 10,
                                              ),
                                            ),
                                            Expanded(
                                              child: Text(
                                                e,
                                                style: const TextStyle(
                                                  color: mid,
                                                  fontSize: 11,
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                    const SizedBox(height: 10),
                                    if (active)
                                      ElevatedButton(
                                        onPressed: isThisActive
                                            ? null
                                            : () async {
                                                final r =
                                                    await Api.activateProgram(
                                                      id,
                                                      wNum,
                                                    );
                                                if (!ctx.mounted) return;
                                                if (r['error'] != null) {
                                                  ScaffoldMessenger.of(
                                                    ctx,
                                                  ).showSnackBar(
                                                    SnackBar(
                                                      content: Text(r['error']),
                                                    ),
                                                  );
                                                  return;
                                                }
                                                // Instantly patch active_program
                                                if (r['active_program'] !=
                                                    null) {
                                                  ctx.read<AppState>().patch({
                                                    'active_program':
                                                        r['active_program'],
                                                  });
                                                } else {
                                                  ctx.read<AppState>().load();
                                                }
                                                sndGem();
                                                if (ctx.mounted)
                                                  ScaffoldMessenger.of(
                                                    ctx,
                                                  ).showSnackBar(
                                                    SnackBar(
                                                      content: Text(
                                                        '🏠 Week $wNum set! Check your Today tab.',
                                                      ),
                                                      backgroundColor: s1,
                                                    ),
                                                  );
                                              },
                                        style: ElevatedButton.styleFrom(
                                          minimumSize: const Size(
                                            double.infinity,
                                            40,
                                          ),
                                          backgroundColor: isThisActive
                                              ? s2
                                              : col,
                                          foregroundColor: isThisActive
                                              ? mid
                                              : bg,
                                          disabledBackgroundColor: s2,
                                          disabledForegroundColor: mid,
                                        ),
                                        child: Text(
                                          isThisActive
                                              ? '✓ Currently Active'
                                              : 'Set Week $wNum as Today →',
                                          style: const TextStyle(fontSize: 12),
                                        ),
                                      ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        );
                      }).toList(),
                    ),
                  ),
                ],
              ],
            ),
          );
        }),
      ],
    );
  }
}

// ════════════════════════════════════════════════════════════════════
// STORE SCREEN
// ════════════════════════════════════════════════════════════════════
class StoreScreen extends StatefulWidget {
  const StoreScreen({super.key});
  @override
  State<StoreScreen> createState() => _StoreState();
}

class _StoreState extends State<StoreScreen>
    with SingleTickerProviderStateMixin {
  late final _tabs = TabController(length: 2, vsync: this);
  bool _buyingShield = false, _claimingAd = false, _adClaimed = false;

  @override
  Widget build(BuildContext ctx) {
    final st = ctx.watch<AppState>().data;
    final gems = st['gems'] as int? ?? 0;
    final shields = st['shields'] as int? ?? 0;
    final pkgs = List<Map<String, dynamic>>.from(st['gem_packages'] ?? []);
    final adDone = st['ad_gems_done'] == true || _adClaimed;

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Store', style: heading(28)),
              pill('💎 $gems', gem),
            ],
          ),
        ),
        const SizedBox(height: 12),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Container(
            decoration: BoxDecoration(
              color: s2,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: bd),
            ),
            child: TabBar(
              controller: _tabs,
              indicator: BoxDecoration(
                color: accent,
                borderRadius: BorderRadius.circular(6),
              ),
              indicatorSize: TabBarIndicatorSize.tab,
              labelColor: bg,
              unselectedLabelColor: mid,
              labelStyle: const TextStyle(
                fontWeight: FontWeight.w700,
                fontSize: 13,
              ),
              dividerColor: Colors.transparent,
              tabs: const [
                Tab(text: '💎 Gems'),
                Tab(text: '📺 Free'),
              ],
            ),
          ),
        ),
        Expanded(
          child: TabBarView(
            controller: _tabs,
            children: [
              // Gems tab
              ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  const Text(
                    'Gems buy Streak Shields, bonus workouts, and premium Programs.',
                    style: TextStyle(color: mid, fontSize: 12, height: 1.5),
                  ),
                  const SizedBox(height: 16),
                  const Text('BUY GEMS', style: lbl),
                  const SizedBox(height: 10),
                  GridView.count(
                    crossAxisCount: 2,
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    crossAxisSpacing: 10,
                    mainAxisSpacing: 10,
                    childAspectRatio: 1.3,
                    children: pkgs.map((pkg) {
                      final pop = pkg['popular'] == true;
                      return GestureDetector(
                        onTap: () async {
                          final ok = await showGemPurchaseDialog(
                            ctx,
                            gems: pkg['gems'],
                            usd: pkg['usd'],
                            label: pkg['label'],
                          );
                          if (!ok || !ctx.mounted) return;
                          final r = await Api.post('/api/gems/purchase', {
                            'package_id': pkg['id'],
                          });
                          if (!ctx.mounted) return;
                          if (r['gems'] != null) {
                            ctx.read<AppState>().patch({'gems': r['gems']});
                            sndGem();
                          } else if (r['error'] != null) {
                            ScaffoldMessenger.of(ctx).showSnackBar(
                              SnackBar(content: Text(r['error'].toString())),
                            );
                          }
                        },
                        child: Container(
                          decoration: BoxDecoration(
                            color: s1,
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(
                              color: pop ? gem : bd,
                              width: pop ? 1.5 : 1,
                            ),
                          ),
                          child: Stack(
                            children: [
                              if (pop)
                                Positioned(
                                  top: 0,
                                  right: 0,
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 8,
                                      vertical: 4,
                                    ),
                                    decoration: const BoxDecoration(
                                      color: gem,
                                      borderRadius: BorderRadius.only(
                                        topRight: Radius.circular(8),
                                        bottomLeft: Radius.circular(6),
                                      ),
                                    ),
                                    child: const Text(
                                      'Popular',
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontSize: 9,
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                  ),
                                ),
                              Center(
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Text(
                                      pkg['label'] ?? '',
                                      style: const TextStyle(
                                        color: dim,
                                        fontSize: 9,
                                        letterSpacing: 1.5,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      '💎 ${pkg['gems']}',
                                      style: heading(22, c: gem),
                                    ),
                                    Text(
                                      pkg['usd'] ?? '',
                                      style: const TextStyle(
                                        color: fg,
                                        fontWeight: FontWeight.w600,
                                        fontSize: 14,
                                      ),
                                    ),
                                    Text(
                                      pkg['price'] ?? '',
                                      style: const TextStyle(
                                        color: dim,
                                        fontSize: 10,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 20),
                  const Divider(),
                  const SizedBox(height: 16),
                  const Text('STREAK SHIELD', style: lbl),
                  const SizedBox(height: 10),
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: s1,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: bd),
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Streak Shield',
                                style: TextStyle(
                                  fontWeight: FontWeight.w600,
                                  fontSize: 14,
                                ),
                              ),
                              const Text(
                                'Protects streak if you miss a day',
                                style: TextStyle(color: mid, fontSize: 11),
                              ),
                              const SizedBox(height: 8),
                              Row(
                                children: List.generate(
                                  2,
                                  (i) => Padding(
                                    padding: const EdgeInsets.only(right: 6),
                                    child: Text(
                                      i < shields ? '🛡️' : '○',
                                      style: TextStyle(
                                        fontSize: 22,
                                        color: i < shields ? null : bd2,
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        ElevatedButton(
                          onPressed: _buyingShield
                              ? null
                              : () async {
                                  final ok = await confirm(
                                    ctx,
                                    emoji: '🛡️',
                                    title: 'Buy Streak Shield?',
                                    desc: 'Costs 150 💎',
                                  );
                                  if (!ok || !ctx.mounted) return;
                                  setState(() => _buyingShield = true);
                                  final r = await Api.buyShield();
                                  if (!ctx.mounted) return;
                                  setState(() => _buyingShield = false);
                                  if (r['error'] != null) {
                                    ScaffoldMessenger.of(ctx).showSnackBar(
                                      SnackBar(content: Text(r['error'])),
                                    );
                                    return;
                                  }
                                  ctx.read<AppState>().patch({
                                    'gems': r['gems'],
                                    'shields': r['shields'],
                                  });
                                },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: gem,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(
                              horizontal: 14,
                              vertical: 12,
                            ),
                          ),
                          child: _buyingShield
                              ? const SizedBox(
                                  width: 18,
                                  height: 18,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: Colors.white,
                                  ),
                                )
                              : const Text(
                                  'Buy 🛡️\n150 💎',
                                  textAlign: TextAlign.center,
                                  style: TextStyle(fontSize: 11),
                                ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              // Free tab
              ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  const Text(
                    'Watch one short ad per day to earn 30 free gems.',
                    style: TextStyle(color: mid, fontSize: 12, height: 1.5),
                  ),
                  const SizedBox(height: 20),
                  Container(
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: s1,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: adDone ? dim : bd),
                    ),
                    child: Column(
                      children: [
                        const Text('📺', style: TextStyle(fontSize: 48)),
                        const SizedBox(height: 10),
                        Text('Daily Ad Reward', style: heading(22)),
                        const SizedBox(height: 4),
                        Text('💎 30', style: heading(32, c: gem)),
                        const SizedBox(height: 8),
                        Text(
                          adDone
                              ? 'Already claimed today. Come back tomorrow!'
                              : 'Watch a short ad and earn gems instantly.',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: adDone ? dim : mid,
                            fontSize: 11,
                          ),
                        ),
                        const SizedBox(height: 20),
                        if (!adDone)
                          ElevatedButton(
                            onPressed: _claimingAd
                                ? null
                                : () async {
                                    setState(() => _claimingAd = true);
                                    await Future.delayed(
                                      const Duration(seconds: 2),
                                    );
                                    if (!ctx.mounted) return;
                                    final r = await Api.watchAd();
                                    if (!ctx.mounted) return;
                                    setState(() {
                                      _claimingAd = false;
                                      if (r['error'] == null) _adClaimed = true;
                                    });
                                    if (r['gems'] != null)
                                      ctx.read<AppState>().patch({
                                        'gems': r['gems'],
                                      });
                                    ScaffoldMessenger.of(ctx).showSnackBar(
                                      SnackBar(
                                        content: Text(
                                          r['error'] != null
                                              ? r['error']
                                              : '+30 💎 earned!',
                                        ),
                                        backgroundColor: s1,
                                      ),
                                    );
                                  },
                            style: ElevatedButton.styleFrom(
                              minimumSize: const Size(double.infinity, 48),
                              backgroundColor: warn,
                              foregroundColor: Colors.white,
                            ),
                            child: _claimingAd
                                ? const SizedBox(
                                    width: 20,
                                    height: 20,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      color: Colors.white,
                                    ),
                                  )
                                : const Text('📺 Watch Ad & Earn Gems'),
                          )
                        else
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            decoration: BoxDecoration(
                              color: s2,
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: bd),
                            ),
                            child: const Text(
                              '✓ Claimed today!',
                              textAlign: TextAlign.center,
                              style: TextStyle(color: dim, fontSize: 13),
                            ),
                          ),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }
}

// ════════════════════════════════════════════════════════════════════
// PROFILE SCREEN
// ════════════════════════════════════════════════════════════════════
// ════════════════════════════════════════════════════════════════════
// SETTINGS SCREEN (opened from ⚙️ button — matches old HTML s-settings)
// ════════════════════════════════════════════════════════════════════
class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});
  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  bool _sound = SoundSettings.soundEnabled;
  bool _vib = SoundSettings.vibrationEnabled;

  Future<void> _toggle(String key, bool val) async {
    setState(() {
      if (key == 'sound') {
        _sound = val;
        SoundSettings.soundEnabled = val;
      }
      if (key == 'vib') {
        _vib = val;
        SoundSettings.vibrationEnabled = val;
      }
    });
    await Api.saveSettings({'sound': _sound, 'vibration': _vib});
  }

  @override
  Widget build(BuildContext ctx) => Scaffold(
    backgroundColor: bg,
    body: SafeArea(
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // ← Back button like old HTML
          Align(
            alignment: Alignment.centerLeft,
            child: GestureDetector(
              onTap: () => Navigator.pop(ctx),
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 13,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: s1,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: bd),
                ),
                child: const Text(
                  '← Back',
                  style: TextStyle(
                    fontSize: 10,
                    color: mid,
                    letterSpacing: 0.5,
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 12),
          const Text('Preferences', style: lbl),
          const SizedBox(height: 4),
          Text('Settings', style: heading(32)),
          const SizedBox(height: 24),

          // Audio & Feedback section
          _prefSec('Audio & Feedback', [
            _toggleRow(
              'Sound effects',
              'Workout and UI audio cues',
              _sound,
              (v) => _toggle('sound', v),
            ),
            _toggleRow(
              'Vibration',
              'Haptic feedback on mobile',
              _vib,
              (v) => _toggle('vib', v),
            ),
          ]),
          const SizedBox(height: 16),

          // About section
          _prefSec('About', [
            _prefRow('Version', 'v2.0.0'),
            _prefRow('Exercises', 'Floor-only, zero equipment'),
            _prefRow('Shield max', '2 shields'),
            _prefRow('Quiz', '10 questions/day · 2 lives'),
          ]),
        ],
      ),
    ),
  );

  Widget _prefSec(String title, List<Widget> children) => Container(
    margin: const EdgeInsets.only(bottom: 8),
    decoration: BoxDecoration(
      color: s1,
      borderRadius: BorderRadius.circular(10),
      border: Border.all(color: bd),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(14, 12, 14, 6),
          child: Text(
            title.toUpperCase(),
            style: const TextStyle(
              fontSize: 9,
              color: dim,
              letterSpacing: 2,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        const Divider(height: 1),
        ...children,
      ],
    ),
  );

  Widget _toggleRow(
    String label,
    String sub,
    bool val,
    Function(bool) onChanged,
  ) => Padding(
    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
    child: Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: const TextStyle(
                  color: fg,
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 2),
              Text(sub, style: const TextStyle(color: dim, fontSize: 11)),
            ],
          ),
        ),
        Switch(value: val, activeColor: accent, onChanged: onChanged),
      ],
    ),
  );

  Widget _prefRow(String label, String val) => Padding(
    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
    child: Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: const TextStyle(color: fg, fontSize: 13)),
        Text(val, style: const TextStyle(color: mid, fontSize: 12)),
      ],
    ),
  );
}

// ════════════════════════════════════════════════════════════════════
// PROFILE SCREEN
// ════════════════════════════════════════════════════════════════════
class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});
  @override
  State<ProfileScreen> createState() => _ProfileState();
}

class _ProfileState extends State<ProfileScreen>
    with SingleTickerProviderStateMixin {
  int _totalKcal(Map d) => (d['history'] as List? ?? []).fold<int>(
    0,
    (s, h) => s + ((h['kcal'] as int?) ?? 0),
  );

  late final _tabs = TabController(length: 2, vsync: this);
  List<Map<String, dynamic>> _log = [];
  bool _loadingLog = false;
  final _wt = TextEditingController(),
      _ht = TextEditingController(),
      _age = TextEditingController(),
      _newWt = TextEditingController();
  String _gender = 'male', _intensity = 'intermediate';
  int _days = 3;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _tabs.addListener(() {
      if (_tabs.index == 0 && _log.isEmpty) _loadLog();
    });
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadLog();
      _prefill();
    });
  }

  void _prefill() {
    final d = context.read<AppState>().data;
    final m = d['metrics'] as Map? ?? {};
    _wt.text = '${m['weight_kg'] ?? ''}';
    _ht.text = '${m['height_cm'] ?? ''}';
    _age.text = '${m['age'] ?? ''}';
    _gender = m['gender'] as String? ?? 'male';
    _intensity = d['intensity'] as String? ?? 'intermediate';
    _days = d['days_per_week'] as int? ?? 3;
  }

  Future<void> _loadLog() async {
    setState(() => _loadingLog = true);
    final r = await Api.weightLog();
    if (mounted)
      setState(() {
        _log = List<Map<String, dynamic>>.from(r['log'] ?? []);
        _loadingLog = false;
      });
  }

  @override
  Widget build(BuildContext ctx) {
    final d = ctx.read<AppState>().data;
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
          child: Row(
            children: [
              CircleAvatar(
                radius: 22,
                backgroundColor: accent.withValues(alpha: .15),
                child: Text(
                  (d['name'] as String? ?? '?').isNotEmpty
                      ? (d['name'] as String)[0].toUpperCase()
                      : '?',
                  style: heading(20, c: accent),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      d['name'] ?? 'Athlete',
                      style: const TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 15,
                      ),
                    ),
                    Text(
                      d['email'] ?? '',
                      style: const TextStyle(color: dim, fontSize: 11),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Container(
            decoration: BoxDecoration(
              color: s2,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: bd),
            ),
            child: TabBar(
              controller: _tabs,
              indicator: BoxDecoration(
                color: accent,
                borderRadius: BorderRadius.circular(6),
              ),
              indicatorSize: TabBarIndicatorSize.tab,
              labelColor: bg,
              unselectedLabelColor: mid,
              labelStyle: const TextStyle(
                fontWeight: FontWeight.w700,
                fontSize: 13,
              ),
              dividerColor: Colors.transparent,
              tabs: const [
                Tab(text: '◈ Progress'),
                Tab(text: '⚙ Settings'),
              ],
            ),
          ),
        ),
        Expanded(
          child: TabBarView(
            controller: _tabs,
            children: [_progressTab(d), _settingsTab(ctx, d)],
          ),
        ),
      ],
    );
  }

  Widget _progressTab(Map d) => ListView(
    padding: const EdgeInsets.all(16),
    children: [
      GridView.count(
        crossAxisCount: 2,
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        crossAxisSpacing: 10,
        mainAxisSpacing: 10,
        childAspectRatio: 1.6,
        children: [
          _stat('🔥 ${d['streak'] ?? 0}', 'Day Streak', warn),
          _stat('⭐ ${d['best_streak'] ?? 0}', 'Best Streak', accent),
          _stat('💪 ${d['total_sessions'] ?? 0}', 'Sessions', safe),
          _stat('🔥 ${_totalKcal(d)} kcal', 'Total Burned', warn),
        ],
      ),
      const SizedBox(height: 20),
      const Text('WEIGHT TREND', style: lbl),
      const SizedBox(height: 10),
      if (_loadingLog)
        const Center(
          child: CircularProgressIndicator(color: accent, strokeWidth: 2),
        )
      else if (_log.isEmpty)
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: s1,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: bd),
          ),
          child: const Column(
            children: [
              Text('📊', style: TextStyle(fontSize: 32)),
              SizedBox(height: 8),
              Text(
                'No weight data yet',
                style: TextStyle(color: mid, fontSize: 13),
              ),
              SizedBox(height: 4),
              Text(
                'Log your weight below and complete workouts to see your trend.',
                textAlign: TextAlign.center,
                style: TextStyle(color: dim, fontSize: 11, height: 1.5),
              ),
            ],
          ),
        )
      else
        _chart(),
      const SizedBox(height: 16),
      const Text('LOG WEIGHT', style: lbl),
      const SizedBox(height: 8),
      Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: s1,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: bd),
        ),
        child: Row(
          children: [
            Expanded(
              child: TextField(
                controller: _newWt,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'Weight (kg)',
                  hintText: '70.5',
                  contentPadding: EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 10,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 10),
            ElevatedButton(
              onPressed: () async {
                final v = double.tryParse(_newWt.text);
                if (v == null) return;
                await Api.logWeight(v);
                _newWt.clear();
                _loadLog();
              },
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
              ),
              child: const Text('Log'),
            ),
          ],
        ),
      ),
      const SizedBox(height: 20),
      const Text('RECENT SESSIONS', style: lbl),
      const SizedBox(height: 10),
      ...(List<Map<String, dynamic>>.from(d['history'] ?? []).reversed
          .take(8)
          .map(
            (h) => Container(
              margin: const EdgeInsets.only(bottom: 8),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: s1,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: bd),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Text(
                              (h['group'] as String? ?? 'workout')
                                  .toUpperCase(),
                              style: const TextStyle(
                                fontWeight: FontWeight.w500,
                                fontSize: 11,
                              ),
                            ),
                            if (h['bonus'] == true) ...[
                              const SizedBox(width: 5),
                              const Text(
                                '[BONUS]',
                                style: TextStyle(fontSize: 8, color: warn),
                              ),
                            ],
                          ],
                        ),
                        Text(
                          '${h['date'] ?? ''} · ${h['intensity'] ?? ''}${(h['kcal'] as int? ?? 0) > 0 ? ' · 🔥${h['kcal']}kcal' : ''}',
                          style: const TextStyle(color: mid, fontSize: 10),
                        ),
                      ],
                    ),
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 7,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          border: Border.all(color: bd),
                          borderRadius: BorderRadius.circular(99),
                        ),
                        child: Text(
                          '${h['exercises'] ?? 0}ex · ${h['sets'] ?? 0}sets',
                          style: const TextStyle(color: fg, fontSize: 9),
                        ),
                      ),
                      const SizedBox(height: 3),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 7,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: gem.withValues(alpha: 0.1),
                          border: Border.all(color: gem.withValues(alpha: 0.3)),
                          borderRadius: BorderRadius.circular(99),
                        ),
                        child: Text(
                          '+${h['gems'] ?? 0} 💎',
                          style: const TextStyle(color: gem, fontSize: 9),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          )),
    ],
  );

  Widget _chart() {
    final spots = <FlSpot>[];
    for (var i = 0; i < _log.length; i++) {
      final v = (_log[i]['predicted_kg'] ?? _log[i]['weight_kg']) as num?;
      if (v != null) spots.add(FlSpot(i.toDouble(), v.toDouble()));
    }
    if (spots.isEmpty) return const SizedBox.shrink();
    final minY = spots.map((s) => s.y).reduce((a, b) => a < b ? a : b) - 0.5;
    final maxY = spots.map((s) => s.y).reduce((a, b) => a > b ? a : b) + 0.5;
    return Container(
      height: 150,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: s1,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: bd),
      ),
      child: LineChart(
        LineChartData(
          minY: minY,
          maxY: maxY,
          gridData: FlGridData(
            show: true,
            drawVerticalLine: false,
            getDrawingHorizontalLine: (_) => FlLine(color: bd, strokeWidth: 1),
          ),
          borderData: FlBorderData(show: false),
          titlesData: FlTitlesData(
            leftTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 36,
                getTitlesWidget: (v, _) => Text(
                  v.toStringAsFixed(1),
                  style: const TextStyle(color: dim, fontSize: 9),
                ),
              ),
            ),
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: spots.length <= 7,
                getTitlesWidget: (v, _) {
                  final i = v.toInt();
                  if (i < 0 || i >= _log.length) return const SizedBox.shrink();
                  final dt = _log[i]['date'] as String? ?? '';
                  return Text(
                    dt.length >= 10 ? dt.substring(5) : dt,
                    style: const TextStyle(color: dim, fontSize: 8),
                  );
                },
              ),
            ),
            topTitles: const AxisTitles(
              sideTitles: SideTitles(showTitles: false),
            ),
            rightTitles: const AxisTitles(
              sideTitles: SideTitles(showTitles: false),
            ),
          ),
          lineBarsData: [
            LineChartBarData(
              spots: spots,
              isCurved: true,
              color: accent,
              barWidth: 2,
              dotData: FlDotData(
                show: spots.length <= 10,
                getDotPainter: (_, __, ___, ____) => FlDotCirclePainter(
                  radius: 3,
                  color: accent,
                  strokeColor: bg,
                  strokeWidth: 1,
                ),
              ),
              belowBarData: BarAreaData(
                show: true,
                color: accent.withValues(alpha: .08),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _settingsTab(BuildContext ctx, Map d) => ListView(
    padding: const EdgeInsets.all(16),
    children: [
      const Text('BODY METRICS', style: lbl),
      const SizedBox(height: 10),
      Row(
        children: [
          Expanded(
            child: TextField(
              controller: _wt,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'Weight (kg)',
                hintText: '70',
              ),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: TextField(
              controller: _ht,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'Height (cm)',
                hintText: '175',
              ),
            ),
          ),
        ],
      ),
      const SizedBox(height: 10),
      Row(
        children: [
          Expanded(
            child: TextField(
              controller: _age,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'Age',
                hintText: '25',
              ),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: DropdownButtonFormField<String>(
              value: _gender,
              decoration: const InputDecoration(labelText: 'Gender'),
              dropdownColor: s2,
              style: const TextStyle(color: fg),
              items: const [
                DropdownMenuItem(value: 'male', child: Text('Male')),
                DropdownMenuItem(value: 'female', child: Text('Female')),
              ],
              onChanged: (v) => setState(() => _gender = v!),
            ),
          ),
        ],
      ),
      const SizedBox(height: 12),
      ElevatedButton(
        onPressed: _saving
            ? null
            : () async {
                setState(() => _saving = true);
                await Api.saveMetrics({
                  'weight_kg': double.tryParse(_wt.text),
                  'height_cm': double.tryParse(_ht.text),
                  'age': int.tryParse(_age.text),
                  'gender': _gender,
                });
                if (!ctx.mounted) return;
                setState(() => _saving = false);
                ctx.read<AppState>().load();
                ScaffoldMessenger.of(ctx).showSnackBar(
                  const SnackBar(
                    content: Text('✓ Metrics saved!'),
                    backgroundColor: s1,
                  ),
                );
              },
        style: ElevatedButton.styleFrom(
          minimumSize: const Size(double.infinity, 44),
        ),
        child: _saving
            ? const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(strokeWidth: 2, color: bg),
              )
            : const Text('Save Metrics →'),
      ),
      const SizedBox(height: 20),
      const Divider(),
      const SizedBox(height: 16),
      const Text('TRAINING PREFERENCES', style: lbl),
      const SizedBox(height: 10),
      const Text('Days per week', style: TextStyle(fontSize: 12, color: mid)),
      const SizedBox(height: 8),
      Row(
        children: List.generate(7, (i) {
          final n = i + 1;
          final sel = n == _days;
          return Expanded(
            child: GestureDetector(
              onTap: () => setState(() => _days = n),
              child: Container(
                margin: const EdgeInsets.symmetric(horizontal: 2),
                padding: const EdgeInsets.symmetric(vertical: 8),
                decoration: BoxDecoration(
                  color: sel ? accent : s2,
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(color: sel ? accent : bd),
                ),
                child: Text(
                  '$n',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: sel ? bg : mid,
                    fontWeight: FontWeight.w700,
                    fontSize: 13,
                  ),
                ),
              ),
            ),
          );
        }),
      ),
      const SizedBox(height: 14),
      const Text('Intensity', style: TextStyle(fontSize: 12, color: mid)),
      const SizedBox(height: 8),
      ...([
        ('beginner', 'Beginner'),
        ('intermediate', 'Intermediate'),
        ('advanced', 'Advanced'),
        ('athlete', 'Athlete'),
      ].map(
        (t) => GestureDetector(
          onTap: () => setState(() => _intensity = t.$1),
          child: Container(
            margin: const EdgeInsets.only(bottom: 6),
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: _intensity == t.$1 ? accent.withValues(alpha: .1) : s1,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: _intensity == t.$1 ? accent : bd,
                width: _intensity == t.$1 ? 1.5 : 1,
              ),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    t.$2,
                    style: TextStyle(
                      color: _intensity == t.$1 ? accent : fg,
                      fontWeight: FontWeight.w500,
                      fontSize: 13,
                    ),
                  ),
                ),
                if (_intensity == t.$1)
                  const Icon(Icons.check, color: accent, size: 16),
              ],
            ),
          ),
        ),
      )),
      const SizedBox(height: 12),
      ElevatedButton(
        onPressed: () async {
          await Api.saveProfile({
            'days_per_week': _days,
            'intensity': _intensity,
          });
          if (!ctx.mounted) return;
          ctx.read<AppState>().load();
          ScaffoldMessenger.of(ctx).showSnackBar(
            const SnackBar(content: Text('✓ Saved!'), backgroundColor: s1),
          );
        },
        style: ElevatedButton.styleFrom(
          minimumSize: const Size(double.infinity, 44),
        ),
        child: const Text('Save Preferences →'),
      ),
      const SizedBox(height: 20),
      const Divider(),
      const SizedBox(height: 16),
      const SizedBox(height: 20),
      const Divider(),
      const SizedBox(height: 16),
      ElevatedButton(
        onPressed: () => Navigator.push(
          ctx,
          MaterialPageRoute(
            fullscreenDialog: true,
            builder: (_) => const SettingsScreen(),
          ),
        ),
        style: ElevatedButton.styleFrom(
          minimumSize: const Size(double.infinity, 44),
          backgroundColor: s2,
          foregroundColor: fg,
        ),
        child: const Text('⚙️  Open Settings'),
      ),
      const SizedBox(height: 8),
      OutlinedButton(
        onPressed: () async {
          await Api.logout();
          await Api.clearSession();
          if (!ctx.mounted) return;
          ctx.read<AppState>().clear();
          Navigator.pushReplacementNamed(ctx, '/auth');
        },
        style: OutlinedButton.styleFrom(
          minimumSize: const Size(double.infinity, 44),
        ),
        child: const Text('Log Out'),
      ),
      const SizedBox(height: 8),
      OutlinedButton(
        onPressed: () async {
          final ok = await showDialog<bool>(
            context: ctx,
            builder: (_) => AlertDialog(
              backgroundColor: s1,
              title: const Text('Reset account?'),
              content: const Text(
                'Erases all progress, streaks, gems. Cannot be undone.',
                style: TextStyle(color: mid),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(ctx, false),
                  child: const Text('Cancel', style: TextStyle(color: accent)),
                ),
                TextButton(
                  onPressed: () => Navigator.pop(ctx, true),
                  child: const Text('Reset', style: TextStyle(color: danger)),
                ),
              ],
            ),
          );
          if (ok != true || !ctx.mounted) return;
          await Api.reset();
          if (!ctx.mounted) return;
          ctx.read<AppState>().clear();
          Navigator.pushReplacementNamed(ctx, '/setup');
        },
        style: OutlinedButton.styleFrom(
          minimumSize: const Size(double.infinity, 44),
          side: const BorderSide(color: danger),
        ),
        child: const Text('Reset Account', style: TextStyle(color: danger)),
      ),
    ],
  );

  Widget _stat(String val, String lbl_, Color c) => Container(
    padding: const EdgeInsets.all(12),
    decoration: BoxDecoration(
      color: s1,
      borderRadius: BorderRadius.circular(10),
      border: Border.all(color: bd),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(val, style: heading(24, c: c)),
        const SizedBox(height: 2),
        Text(
          lbl_,
          style: const TextStyle(color: dim, fontSize: 10, letterSpacing: 0.5),
        ),
      ],
    ),
  );
}
