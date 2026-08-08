import 'dart:async';
import 'dart:convert';

import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

// ---------- Translations ----------
const Map<String, Map<String, String>> translations = {
  'en': {
    'title': 'Zikr Allah',
    'time': 'Time',
    'level': 'Level',
    'duration': 'Duration',
    'interval': 'Interval',
    'levels': 'Levels',
    'start': 'Start',
    'pause': 'Pause',
    'resume': 'Resume',
    'reset': 'Reset',
    'min': 'min',
    'sec': 'sec',
    'count': 'count',
    'complete': 'Completed ✓',
    'viewHistory': '📜 View past sessions',
    'historyTitle': 'Past Sessions',
    'clearHistory': 'Clear history',
    'noSessions': 'No sessions yet.',
    'doneBadge': 'Completed',
    'stoppedBadge': 'Stopped',
    'levelsWord': 'levels',
    'confirmClear': 'Delete all session history?',
    'cancel': 'Cancel',
    'delete': 'Delete',
  },
  'ur': {
    'title': 'ذکر اللہ',
    'time': 'وقت',
    'level': 'سطح',
    'duration': 'دورانیہ',
    'interval': 'وقفہ',
    'levels': 'سطحیں',
    'start': 'شروع',
    'pause': 'روکیں',
    'resume': 'جاری رکھیں',
    'reset': 'ری سیٹ',
    'min': 'منٹ',
    'sec': 'سیکنڈ',
    'count': 'تعداد',
    'complete': 'مکمل ✓',
    'viewHistory': '📜 پچھلے سیشنز دیکھیں',
    'historyTitle': 'پچھلے سیشنز',
    'clearHistory': 'ہسٹری صاف کریں',
    'noSessions': 'ابھی کوئی سیشن نہیں۔',
    'doneBadge': 'مکمل',
    'stoppedBadge': 'روکا گیا',
    'levelsWord': 'سطحیں',
    'confirmClear': 'تمام سیشن ہسٹری حذف کریں؟',
    'cancel': 'منسوخ',
    'delete': 'حذف کریں',
  },
};

// ---------- Palette ----------
class Palette {
  final Color bg;
  final Color dialogBg;
  final Color text;
  final Color label;
  final Color green;
  final Color greenSoft;
  final Color orange;
  final Color red;
  final Color border;
  final Color stepperBg;
  final Color stepperFg;

  const Palette({
    required this.bg,
    required this.dialogBg,
    required this.text,
    required this.label,
    required this.green,
    required this.greenSoft,
    required this.orange,
    required this.red,
    required this.border,
    required this.stepperBg,
    required this.stepperFg,
  });

  static const light = Palette(
    bg: Color(0xFFF5F6F8),
    dialogBg: Color(0xFFFFFFFF),
    text: Color(0xFF111111),
    label: Color(0xFF616161),
    green: Color(0xFF2E9E54),
    greenSoft: Color(0xFFE6F4EC),
    orange: Color(0xFFF57C00),
    red: Color(0xFFE53935),
    border: Color(0xFFE0E0E0),
    stepperBg: Color(0xFFE8E8E8),
    stepperFg: Color(0xFF111111),
  );

  static const dark = Palette(
    bg: Color(0xFF0D0D0D),
    dialogBg: Color(0xFF1A1D22),
    text: Color(0xFFFFFFFF),
    label: Color(0xFFB3B3B3),
    green: Color(0xFF3DDC63),
    greenSoft: Color(0xFF1F3326),
    orange: Color(0xFFFF9800),
    red: Color(0xFFE53935),
    border: Color(0xFF2A2A2A),
    stepperBg: Color(0xFFECECEC),
    stepperFg: Color(0xFF111111),
  );
}

// ---------- Session record ----------
class Session {
  final int ts;
  final int intervalMin;
  final int intervalSec;
  final int targetLevels;
  final int levelsDone;
  final int totalElapsed;
  final bool completed;

  Session({
    required this.ts,
    required this.intervalMin,
    required this.intervalSec,
    required this.targetLevels,
    required this.levelsDone,
    required this.totalElapsed,
    required this.completed,
  });

  Map<String, dynamic> toJson() => {
        'ts': ts,
        'intervalMin': intervalMin,
        'intervalSec': intervalSec,
        'targetLevels': targetLevels,
        'levelsDone': levelsDone,
        'totalElapsed': totalElapsed,
        'completed': completed,
      };

  factory Session.fromJson(Map<String, dynamic> j) => Session(
        ts: (j['ts'] as num?)?.toInt() ?? 0,
        intervalMin: (j['intervalMin'] as num?)?.toInt() ?? 0,
        intervalSec: (j['intervalSec'] as num?)?.toInt() ?? 0,
        targetLevels: (j['targetLevels'] as num?)?.toInt() ?? 1,
        levelsDone: (j['levelsDone'] as num?)?.toInt() ?? 0,
        totalElapsed: (j['totalElapsed'] as num?)?.toInt() ?? 0,
        completed: j['completed'] == true,
      );
}

// ---------- Helpers ----------
String two(int n) => n.toString().padLeft(2, '0');

/// Always hh:mm:ss, like the reference design (e.g. 00:45:04).
String formatHMS(int totalSeconds) {
  final s = totalSeconds < 0 ? 0 : totalSeconds;
  return '${two(s ~/ 3600)}:${two((s % 3600) ~/ 60)}:${two(s % 60)}';
}

/// Compact form used in the history list (mm:ss, or h:mm:ss above an hour).
String formatClock(int totalSeconds) {
  final s = totalSeconds < 0 ? 0 : totalSeconds;
  final h = s ~/ 3600;
  final m = (s % 3600) ~/ 60;
  final sec = s % 60;
  return h > 0 ? '$h:${two(m)}:${two(sec)}' : '${two(m)}:${two(sec)}';
}

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final prefs = await SharedPreferences.getInstance();
  runApp(ZikrApp(prefs: prefs));
}

class ZikrApp extends StatefulWidget {
  final SharedPreferences prefs;
  const ZikrApp({super.key, required this.prefs});

  @override
  State<ZikrApp> createState() => _ZikrAppState();
}

class _ZikrAppState extends State<ZikrApp> {
  late String lang;
  late bool darkMode;

  @override
  void initState() {
    super.initState();
    final saved = widget.prefs.getString('lang');
    lang = translations.containsKey(saved) ? saved! : 'en';
    darkMode = widget.prefs.getBool('dark') ?? true;
  }

  void _setLang(String value) {
    setState(() => lang = translations.containsKey(value) ? value : 'en');
    widget.prefs.setString('lang', lang);
  }

  void _toggleTheme() {
    setState(() => darkMode = !darkMode);
    widget.prefs.setBool('dark', darkMode);
  }

  @override
  Widget build(BuildContext context) {
    final palette = darkMode ? Palette.dark : Palette.light;
    return MaterialApp(
      title: translations[lang]!['title']!,
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        brightness: darkMode ? Brightness.dark : Brightness.light,
        scaffoldBackgroundColor: palette.bg,
        colorScheme: ColorScheme.fromSeed(
          seedColor: palette.green,
          brightness: darkMode ? Brightness.dark : Brightness.light,
        ),
        useMaterial3: true,
      ),
      home: Directionality(
        textDirection: lang == 'ur' ? TextDirection.rtl : TextDirection.ltr,
        child: TimerPage(
          prefs: widget.prefs,
          lang: lang,
          darkMode: darkMode,
          onLangChanged: _setLang,
          onThemeToggle: _toggleTheme,
        ),
      ),
    );
  }
}

class TimerPage extends StatefulWidget {
  final SharedPreferences prefs;
  final String lang;
  final bool darkMode;
  final ValueChanged<String> onLangChanged;
  final VoidCallback onThemeToggle;

  const TimerPage({
    super.key,
    required this.prefs,
    required this.lang,
    required this.darkMode,
    required this.onLangChanged,
    required this.onThemeToggle,
  });

  @override
  State<TimerPage> createState() => _TimerPageState();
}

class _TimerPageState extends State<TimerPage> {
  // Configuration
  int intervalMin = 3;
  int intervalSec = 13;
  int targetLevels = 14;

  // State
  bool timerRunning = false;
  bool completed = false;
  int totalElapsed = 0;
  int elapsedInLevel = 0;
  int currentLevel = 0; // 0 = not started yet
  Timer? ticker;

  Map<String, String> get dict => translations[widget.lang]!;
  Palette get palette => widget.darkMode ? Palette.dark : Palette.light;

  int get secondsPerLevel => intervalMin * 60 + intervalSec;

  @override
  void initState() {
    super.initState();
    intervalMin = widget.prefs.getInt('intervalMin') ?? 3;
    intervalSec = widget.prefs.getInt('intervalSec') ?? 13;
    targetLevels = widget.prefs.getInt('targetLevels') ?? 14;
    if (intervalMin < 0) intervalMin = 0;
    if (intervalSec < 0 || intervalSec > 59) intervalSec = 0;
    if (targetLevels < 1) targetLevels = 1;
  }

  @override
  void dispose() {
    ticker?.cancel();
    super.dispose();
  }

  void _savePrefs() {
    widget.prefs.setInt('intervalMin', intervalMin);
    widget.prefs.setInt('intervalSec', intervalSec);
    widget.prefs.setInt('targetLevels', targetLevels);
  }

  // ---------- Session log ----------
  List<Session> _loadSessions() {
    try {
      final raw = widget.prefs.getString('zikrSessions');
      if (raw == null) return [];
      final list = jsonDecode(raw) as List;
      return list
          .map((e) => Session.fromJson(e as Map<String, dynamic>))
          .toList();
    } catch (_) {
      return [];
    }
  }

  Future<void> _saveSessions(List<Session> sessions) {
    return widget.prefs.setString(
      'zikrSessions',
      jsonEncode(sessions.map((s) => s.toJson()).toList()),
    );
  }

  void _logSession() {
    final sessions = _loadSessions()
      ..add(Session(
        ts: DateTime.now().millisecondsSinceEpoch,
        intervalMin: intervalMin,
        intervalSec: intervalSec,
        targetLevels: targetLevels,
        levelsDone:
            completed ? targetLevels : (currentLevel - 1).clamp(0, targetLevels),
        totalElapsed: totalElapsed,
        completed: completed,
      ));
    _saveSessions(sessions);
  }

  // ---------- Audio ----------
  Future<void> _playBeep(int count) async {
    for (var i = 0; i < count; i++) {
      final player = AudioPlayer();
      player.onPlayerComplete.listen((_) => player.dispose());
      try {
        await player.play(AssetSource('beep.wav'), volume: 0.6);
      } catch (_) {
        // audio unavailable — ignore
      }
      if (i < count - 1) {
        await Future.delayed(const Duration(milliseconds: 300));
      }
    }
  }

  // ---------- Timer control ----------
  void _startTimer() {
    if (timerRunning || secondsPerLevel == 0) return;
    setState(() {
      if (completed) {
        // restart a finished session
        totalElapsed = 0;
        elapsedInLevel = 0;
        currentLevel = 0;
        completed = false;
      }
      timerRunning = true;
      if (currentLevel == 0) currentLevel = 1;
    });
    ticker = Timer.periodic(const Duration(seconds: 1), (_) => _tick());
  }

  void _tick() {
    setState(() {
      totalElapsed++;
      elapsedInLevel++;
      if (elapsedInLevel >= secondsPerLevel) {
        if (currentLevel >= targetLevels) {
          _finishTimer();
          return;
        }
        currentLevel++;
        elapsedInLevel = 0;
        _playBeep(1);
      }
    });
  }

  void _finishTimer() {
    ticker?.cancel();
    timerRunning = false;
    completed = true;
    elapsedInLevel = secondsPerLevel;
    _playBeep(2);
    _logSession();
  }

  void _pauseTimer() {
    if (!timerRunning) return;
    ticker?.cancel();
    setState(() => timerRunning = false);
  }

  void _resetTimer() {
    if (timerRunning) return;
    ticker?.cancel();
    // Log a session that was stopped before completing
    if (totalElapsed > 0 && !completed) _logSession();
    setState(() {
      totalElapsed = 0;
      elapsedInLevel = 0;
      currentLevel = 0;
      completed = false;
    });
  }

  // ---------- Settings steppers ----------
  void _changeVal(String type, int amount) {
    if (timerRunning) return;
    setState(() {
      if (type == 'min') {
        intervalMin = (intervalMin + amount).clamp(0, 999);
      } else if (type == 'sec') {
        intervalSec += amount;
        if (intervalSec > 59) intervalSec = 0;
        if (intervalSec < 0) intervalSec = 59;
      } else if (type == 'lev') {
        targetLevels = (targetLevels + amount).clamp(1, 999);
      }
      // Editing settings starts a fresh session
      if (totalElapsed == 0) {
        currentLevel = 0;
        elapsedInLevel = 0;
        completed = false;
      }
    });
    _savePrefs();
  }

  // ---------- History ----------
  String _formatDate(int ts) {
    final d = DateTime.fromMillisecondsSinceEpoch(ts);
    return '${two(d.day)}/${two(d.month)}/${d.year}  ${two(d.hour)}:${two(d.minute)}';
  }

  Future<void> _openHistory() async {
    await showDialog<void>(
      context: context,
      builder: (context) => Directionality(
        textDirection:
            widget.lang == 'ur' ? TextDirection.rtl : TextDirection.ltr,
        child: StatefulBuilder(
          builder: (context, setModalState) {
            final sessions = _loadSessions()
              ..sort((a, b) => b.ts.compareTo(a.ts));
            return Dialog(
              backgroundColor: palette.dialogBg,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(18)),
              child: ConstrainedBox(
                constraints:
                    const BoxConstraints(maxWidth: 460, maxHeight: 560),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Padding(
                      padding: const EdgeInsets.fromLTRB(18, 16, 18, 16),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(dict['historyTitle']!,
                              style: TextStyle(
                                  fontSize: 17,
                                  fontWeight: FontWeight.w700,
                                  color: palette.text)),
                          IconButton(
                            icon: Icon(Icons.close, color: palette.label),
                            onPressed: () => Navigator.of(context).pop(),
                          ),
                        ],
                      ),
                    ),
                    Divider(height: 1, color: palette.border),
                    Flexible(
                      child: sessions.isEmpty
                          ? Padding(
                              padding: const EdgeInsets.all(28),
                              child: Text(dict['noSessions']!,
                                  style: TextStyle(
                                      fontSize: 15, color: palette.label)),
                            )
                          : ListView.separated(
                              shrinkWrap: true,
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 14, vertical: 8),
                              itemCount: sessions.length,
                              separatorBuilder: (_, __) =>
                                  Divider(height: 1, color: palette.border),
                              itemBuilder: (context, i) {
                                final s = sessions[i];
                                return _sessionTile(s, () async {
                                  final all = _loadSessions()
                                    ..removeWhere((x) => x.ts == s.ts);
                                  await _saveSessions(all);
                                  setModalState(() {});
                                });
                              },
                            ),
                    ),
                    Divider(height: 1, color: palette.border),
                    Padding(
                      padding: const EdgeInsets.fromLTRB(18, 12, 18, 12),
                      child: Align(
                        alignment: AlignmentDirectional.centerEnd,
                        child: OutlinedButton(
                          onPressed: () async {
                            final ok = await _confirmClear();
                            if (ok) {
                              await _saveSessions([]);
                              setModalState(() {});
                            }
                          },
                          style: OutlinedButton.styleFrom(
                            foregroundColor: palette.label,
                            side: BorderSide(color: palette.border),
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(30)),
                          ),
                          child: Text(dict['clearHistory']!),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _sessionTile(Session s, VoidCallback onDelete) {
    final badgeColor = s.completed ? palette.green : palette.label;
    final badgeBg =
        s.completed ? palette.greenSoft : palette.label.withValues(alpha: 0.18);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 6),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(_formatDate(s.ts),
                    style: TextStyle(fontSize: 13, color: palette.label)),
                const SizedBox(height: 2),
                Text(
                  '${two(s.intervalMin)}:${two(s.intervalSec)} × ${s.targetLevels}',
                  style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: palette.text),
                ),
                const SizedBox(height: 4),
                Wrap(
                  crossAxisAlignment: WrapCrossAlignment.center,
                  spacing: 8,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: badgeBg,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        s.completed
                            ? dict['doneBadge']!
                            : dict['stoppedBadge']!,
                        style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            color: badgeColor),
                      ),
                    ),
                    Text(
                      '${s.levelsDone}/${s.targetLevels} ${dict['levelsWord']!}  ·  ${formatClock(s.totalElapsed)}',
                      style: TextStyle(fontSize: 13, color: palette.label),
                    ),
                  ],
                ),
              ],
            ),
          ),
          IconButton(
            icon: Icon(Icons.delete_outline, size: 20, color: palette.label),
            onPressed: onDelete,
          ),
        ],
      ),
    );
  }

  Future<bool> _confirmClear() async {
    final result = await showDialog<bool>(
      context: context,
      builder: (context) => Directionality(
        textDirection:
            widget.lang == 'ur' ? TextDirection.rtl : TextDirection.ltr,
        child: AlertDialog(
          backgroundColor: palette.dialogBg,
          content: Text(dict['confirmClear']!,
              style: TextStyle(color: palette.text)),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child:
                  Text(dict['cancel']!, style: TextStyle(color: palette.label)),
            ),
            TextButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: Text(dict['delete']!,
                  style: TextStyle(color: palette.red)),
            ),
          ],
        ),
      ),
    );
    return result ?? false;
  }

  // ---------- Build ----------
  @override
  Widget build(BuildContext context) {
    final total = secondsPerLevel * targetLevels;
    final lvl = currentLevel == 0 ? 1 : currentLevel.clamp(1, targetLevels);

    return Scaffold(
      backgroundColor: palette.bg,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 440),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _topBar(),
                  const SizedBox(height: 10),
                  Text(
                    dict['title']!,
                    style: TextStyle(
                      fontSize: 40,
                      fontWeight: FontWeight.w800,
                      color: palette.text,
                    ),
                  ),
                  const SizedBox(height: 26),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      _labeledValue(
                          dict['time']!, formatHMS(totalElapsed), palette.green,
                          big: true),
                      _labeledValue(dict['level']!, two(lvl), palette.green,
                          big: true),
                    ],
                  ),
                  if (completed) ...[
                    const SizedBox(height: 10),
                    Text(dict['complete']!,
                        style: TextStyle(
                            fontSize: 17,
                            fontWeight: FontWeight.w700,
                            color: palette.green)),
                  ],
                  const SizedBox(height: 22),
                  _labeledValue(
                      dict['duration']!, formatHMS(total), palette.orange,
                      big: true),
                  const SizedBox(height: 26),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Column(
                        children: [
                          Text(dict['interval']!,
                              style: TextStyle(
                                  fontSize: 17, color: palette.label)),
                          const SizedBox(height: 10),
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              _stepper('min', intervalMin, dict['min']!),
                              const SizedBox(width: 26),
                              _stepper('sec', intervalSec, dict['sec']!),
                            ],
                          ),
                        ],
                      ),
                      Column(
                        children: [
                          Text(dict['levels']!,
                              style: TextStyle(
                                  fontSize: 17, color: palette.label)),
                          const SizedBox(height: 10),
                          _stepper('lev', targetLevels, dict['count']!),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 30),
                  _controls(),
                  const SizedBox(height: 22),
                  TextButton(
                    onPressed: _openHistory,
                    child: Text(
                      dict['viewHistory']!,
                      style: TextStyle(
                          color: palette.label,
                          fontSize: 14,
                          fontWeight: FontWeight.w600),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _topBar() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        DropdownButtonHideUnderline(
          child: DropdownButton<String>(
            value: widget.lang,
            dropdownColor: palette.dialogBg,
            style: TextStyle(fontSize: 14, color: palette.label),
            iconEnabledColor: palette.label,
            items: const [
              DropdownMenuItem(value: 'en', child: Text('English')),
              DropdownMenuItem(value: 'ur', child: Text('اردو')),
            ],
            onChanged: (v) {
              if (v != null) widget.onLangChanged(v);
            },
          ),
        ),
        IconButton(
          onPressed: widget.onThemeToggle,
          icon: Icon(
            widget.darkMode ? Icons.light_mode : Icons.dark_mode,
            color: palette.label,
            size: 22,
          ),
        ),
      ],
    );
  }

  Widget _labeledValue(String label, String value, Color color,
      {bool big = false}) {
    return Column(
      children: [
        Text(label,
            style: TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.w500,
                color: palette.label)),
        const SizedBox(height: 4),
        Text(
          value,
          style: TextStyle(
            fontSize: big ? 40 : 30,
            fontWeight: FontWeight.w700,
            color: color,
            fontFeatures: const [FontFeature.tabularFigures()],
            height: 1.1,
          ),
        ),
      ],
    );
  }

  Widget _stepper(String type, int value, String unit) {
    Widget btn(String label, int amount) {
      return SizedBox(
        width: 64,
        height: 50,
        child: FilledButton(
          onPressed: timerRunning ? null : () => _changeVal(type, amount),
          style: FilledButton.styleFrom(
            backgroundColor: palette.stepperBg,
            foregroundColor: palette.stepperFg,
            disabledBackgroundColor: palette.stepperBg.withValues(alpha: 0.4),
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            padding: EdgeInsets.zero,
          ),
          child: Text(label,
              style:
                  const TextStyle(fontSize: 24, fontWeight: FontWeight.w800)),
        ),
      );
    }

    return Column(
      children: [
        Text(
          two(value),
          style: TextStyle(
            fontSize: 34,
            fontWeight: FontWeight.w700,
            color: palette.orange,
            fontFeatures: const [FontFeature.tabularFigures()],
          ),
        ),
        const SizedBox(height: 12),
        btn('+', 1),
        const SizedBox(height: 12),
        btn('−', -1),
        const SizedBox(height: 10),
        Text(unit,
            style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: palette.label)),
      ],
    );
  }

  Widget _controls() {
    Widget actionButton(String label, Color color, VoidCallback? onPressed) {
      return Expanded(
        child: SizedBox(
          height: 54,
          child: FilledButton(
            onPressed: onPressed,
            style: FilledButton.styleFrom(
              backgroundColor: color,
              foregroundColor: Colors.white,
              disabledBackgroundColor: color.withValues(alpha: 0.35),
              disabledForegroundColor: Colors.white70,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10)),
              padding: EdgeInsets.zero,
            ),
            child: Text(label,
                style:
                    const TextStyle(fontSize: 19, fontWeight: FontWeight.w700)),
          ),
        ),
      );
    }

    final startLabel = (!completed && !timerRunning && totalElapsed > 0)
        ? dict['resume']!
        : dict['start']!;
    final canStart = !timerRunning && secondsPerLevel > 0;
    final canReset = !timerRunning && (totalElapsed > 0 || completed);

    return Row(
      children: [
        actionButton(
            startLabel, const Color(0xFF43A047), canStart ? _startTimer : null),
        const SizedBox(width: 14),
        actionButton(dict['pause']!, const Color(0xFFFB8C00),
            timerRunning ? _pauseTimer : null),
        const SizedBox(width: 14),
        actionButton(
            dict['reset']!, palette.red, canReset ? _resetTimer : null),
      ],
    );
  }
}
