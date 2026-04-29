import 'package:flutter/foundation.dart';
import 'api.dart';

class AppState extends ChangeNotifier {
  Map<String, dynamic> data = {};
  bool loading = false;

  bool get loggedIn => data['email'] != null;
  bool get setup => data['setup'] == true;
  int get gems => (data['gems'] as int?) ?? 0;
  int get shields => (data['shields'] as int?) ?? 0;
  int get streak => (data['streak'] as int?) ?? 0;
  bool get isPro => data['pro'] == true;

  Future<void> load() async {
    // Don't notify at start — avoids triggering a rebuild mid-flight
    loading = true;
    final r = await Api.state();
    loading = false;
    if (r['error'] == null) data = r;
    notifyListeners(); // single notification after data is ready
  }

  void patch(Map<String, dynamic> d) {
    data = {...data, ...d};
    notifyListeners();
  }

  void clear() {
    data = {};
    notifyListeners();
  }
}
