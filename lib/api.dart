import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class Api {
  static const _defaultBase = 'http://192.168.18.219:5000';
  static String _base = _defaultBase;
  static String _cookie = ''; // never null — avoids race conditions
  static bool _initialized = false;

  /// Call once at app start before any API requests
  static Future<void> init() async {
    if (_initialized) return;
    _initialized = true;
    final prefs = await SharedPreferences.getInstance();
    _base = prefs.getString('server_url') ?? _defaultBase;
    _cookie = prefs.getString('session') ?? '';
  }

  static Future<void> setBase(String url) async {
    _base = url;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('server_url', url);
  }

  static Future<String> getBase() async {
    await init();
    return _base;
  }

  static Map<String, String> get _headers => {
    'Content-Type': 'application/json',
    if (_cookie.isNotEmpty) 'Cookie': _cookie,
  };

  /// Extract and persist session cookie from response
  static Future<void> _saveCookie(http.Response r) async {
    // Try 'set-cookie' header (exact case)
    String? raw = r.headers['set-cookie'];
    // Some servers use different casing
    if (raw == null) {
      for (final key in r.headers.keys) {
        if (key.toLowerCase() == 'set-cookie') {
          raw = r.headers[key];
          break;
        }
      }
    }
    if (raw == null) return;
    // Extract session=VALUE (everything up to the first semicolon)
    final match = RegExp(r'session=[^;]+').firstMatch(raw);
    if (match == null) return;
    _cookie = match.group(0)!;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('session', _cookie);
  }

  static Future<Map<String, dynamic>> _parse(http.Response r) async {
    await _saveCookie(r);
    try {
      final body = jsonDecode(r.body);
      if (body is Map<String, dynamic>) return body;
      return {'error': 'Unexpected response format'};
    } catch (_) {
      return {'error': 'Bad response from server (${r.statusCode})'};
    }
  }

  static Future<Map<String, dynamic>> get(String path) async {
    await init();
    try {
      final res = await http
          .get(Uri.parse('$_base$path'), headers: _headers)
          .timeout(const Duration(seconds: 10));
      return _parse(res);
    } catch (e) {
      return {
        'error': 'Cannot reach server. Check your server URL in settings.',
      };
    }
  }

  static Future<Map<String, dynamic>> post(
    String path, [
    Map<String, dynamic>? body,
  ]) async {
    await init();
    try {
      final res = await http
          .post(
            Uri.parse('$_base$path'),
            headers: _headers,
            body: body != null ? jsonEncode(body) : null,
          )
          .timeout(const Duration(seconds: 10));
      return _parse(res);
    } catch (e) {
      return {
        'error': 'Cannot reach server. Check your server URL in settings.',
      };
    }
  }

  static Future<void> clearSession() async {
    _cookie = '';
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('session');
  }

  // ── Auth ──────────────────────────────────────────────────────────
  static Future<Map<String, dynamic>> login(String e, String p) =>
      post('/api/auth/login', {'email': e, 'pw': p});
  static Future<Map<String, dynamic>> signup(String n, String e, String p) =>
      post('/api/auth/signup', {'name': n, 'email': e, 'pw': p});
  static Future<Map<String, dynamic>> logout() => post('/api/auth/logout');
  static Future<Map<String, dynamic>> me() => get('/api/auth/me');

  // ── Core ─────────────────────────────────────────────────────────
  static Future<Map<String, dynamic>> state() => get('/api/state');
  static Future<Map<String, dynamic>> setup(Map<String, dynamic> d) =>
      post('/api/setup', d);
  static Future<Map<String, dynamic>> todayWorkout() =>
      get('/api/workout/today');
  static Future<Map<String, dynamic>> completeWorkout(Map<String, dynamic> d) =>
      post('/api/workout/complete', d);
  static Future<Map<String, dynamic>> bonusExercises(String g) =>
      get('/api/workout/bonus_exercises?group=$g');
  static Future<Map<String, dynamic>> unlockBonus(String m) =>
      post('/api/bonus_unlock', {'method': m});
  static Future<Map<String, dynamic>> resolveStreak(String m) =>
      post('/api/streak/resolve', {'method': m});

  // ── Quiz ─────────────────────────────────────────────────────────
  static Future<Map<String, dynamic>> quizToday() => get('/api/quiz/today');
  static Future<Map<String, dynamic>> answerQuiz(int a) =>
      post('/api/quiz/answer', {'answer': a});
  static Future<Map<String, dynamic>> reviveQuiz(String m) =>
      post('/api/quiz/revive', {'method': m});

  // ── Store ─────────────────────────────────────────────────────────
  static Future<Map<String, dynamic>> buyShield() =>
      post('/api/gems/buy_shield');
  static Future<Map<String, dynamic>> watchAd() => post('/api/store/watch_ad');

  // ── Programs ──────────────────────────────────────────────────────
  static Future<Map<String, dynamic>> purchaseProgram(String id) =>
      post('/api/programs/purchase', {'program_id': id});
  static Future<Map<String, dynamic>> activateProgram(String id, int w) =>
      post('/api/programs/activate', {'program_id': id, 'week': w});
  static Future<Map<String, dynamic>> deactivateProgram([String? id]) =>
      post('/api/programs/activate', id != null ? {'program_id': id} : {});

  // ── Profile ───────────────────────────────────────────────────────
  static Future<Map<String, dynamic>> saveSettings(Map<String, dynamic> d) =>
      post('/api/settings', d);
  static Future<Map<String, dynamic>> saveMetrics(Map<String, dynamic> d) =>
      post('/api/metrics', d);
  static Future<Map<String, dynamic>> saveProfile(Map<String, dynamic> d) =>
      post('/api/profile', d);
  static Future<Map<String, dynamic>> weightLog() => get('/api/weight_log');
  static Future<Map<String, dynamic>> logWeight(double kg) =>
      post('/api/weight_log', {'weight_kg': kg});
  static Future<Map<String, dynamic>> reset() => post('/api/reset');
}
