import 'dart:async';
import 'dart:convert';

import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

// ---------- Translations ----------
const Map<String, Map<String, String>> translations = {
  'en': {
    'title': 'Zikr Timer',
    'level': 'Level',
    'start': 'Start',
    'pause': 'Pause',
    'resume': 'Resume',
    'reset': 'Reset',
    'settings': 'SETTINGS',
    'intervalLabel': 'Interval per level',
    'levelsLabel': 'Number of levels',
    'min': 'min',
    'sec': 'sec',
    'count': 'count',
    'elapsed': 'Elapsed',
    'remaining': 'Remaining',
    'total': 'Total duration',
    'complete': 'Completed ✓',
    'dark': '🌙 Dark',
    'light': '☀️ Light',
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
    'title': 'ذکر ٹائمر',
    'level': 'سطح',
    'start': 'شروع',
    'pause': 'روکیں',
    'resume': 'جاری رکھیں',
    'reset': 'ری سیٹ',
    'settings': 'ترتیبات',
    'intervalLabel': 'ہر سطح کا وقفہ',
    'levelsLabel': 'سطحوں کی تعداد',
    'min': 'منٹ',
    'sec': 'سیکنڈ',
    'count': 'تعداد',
    'elapsed': 'گزرا وقت',
    'remaining': 'باقی وقت',
    'total': 'کل دورانیہ',
    'complete': 'مکمل ✓',
    'dark': '🌙 ڈارک',
    'light': '☀️ لائٹ',
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

// ---------- Palette (mirrors the CSS variables of the original PWA) ----------
class Palette {
  final Color bg;
  final Color containerBg;
  final Color text;
  final Color label;
  final Color accent;
  final Color accentSoft;
  final Color track;
  final Color duration;
  final Color border;

  const Palette({
    required this.bg,
    required this.containerBg,
    required this.text,
    required this.label,
    required this.accent,
    required this.accentSoft,
    required this.track,
    required this.duration,
    required this.border,
  });

  static const light = Palette(
    bg: Color(0xFFEEF1F4),
    containerBg: Color(0xFFFFFFFF),
    text: Color(0xFF1A1A1A),
    label: Color(0xFF667085),
    accent: Color(0xFF2E9E54),
    accentSoft: Color(0xFFE6F4EC),
    track: Color(0xFFE6E8EB),
    duration: Color(0xFF2E9E54),
    border: Color(0xFFE2E5E9),
  );

  static const dark = Palette(
    bg: Color(0xFF14161A),
    containerBg: Color(0xFF1E2127),
    text: Color(0xFFF0F2F5),
    label: Color(0xFF9AA3AF),
    accent: Color(0xFF4CAF50),
    accentSoft: Color(0xFF1F3326),
    track: Color(0xFF2C313A),
    duration: Color(0xFF5BD07E),
    border: Color(0xFF2C313A),
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
    darkMode = widget.prefs.getBool('dark') ?? false;
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
          seedColor: palette.accent,
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
        levelsDone: completed ? targetLevels : (currentLevel - 1).clamp(0, targetLevels),
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
  void _togglePlay() {
    if (timerRunning) {
      _pauseTimer();
    } else {
      _startTimer();
    }
  }

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
              backgroundColor: palette.containerBg,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(18)),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 460, maxHeight: 560),
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
    final badgeColor = s.completed ? palette.accent : palette.label;
    final badgeBg = s.completed
        ? palette.accentSoft
        : palette.label.withValues(alpha: 0.18);
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
          backgroundColor: palette.containerBg,
          content: Text(dict['confirmClear']!,
              style: TextStyle(color: palette.text)),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: Text(dict['cancel']!,
                  style: TextStyle(color: palette.label)),
            ),
            TextButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: Text(dict['delete']!,
                  style: const TextStyle(color: Color(0xFFE2554C))),
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
    final remInLevel =
        (secondsPerLevel - elapsedInLevel).clamp(0, secondsPerLevel);
    final levelProgress =
        secondsPerLevel == 0 ? 0.0 : elapsedInLevel / secondsPerLevel;

    return Scaffold(
      backgroundColor: palette.bg,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Container(
              constraints: const BoxConstraints(maxWidth: 440),
              padding: const EdgeInsets.fromLTRB(20, 18, 20, 26),
              decoration: BoxDecoration(
                color: palette.containerBg,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black
                        .withValues(alpha: widget.darkMode ? 0.5 : 0.08),
                    blurRadius: 30,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _topBar(),
                  const SizedBox(height: 6),
                  _header(),
                  const SizedBox(height: 14),
                  _ring(levelProgress, remInLevel, lvl),
                  const SizedBox(height: 14),
                  _stats(total),
                  const SizedBox(height: 18),
                  _controls(),
                  const SizedBox(height: 22),
                  _settings(total),
                  const SizedBox(height: 22),
                  Divider(height: 1, color: palette.border),
                  const SizedBox(height: 16),
                  TextButton(
                    onPressed: _openHistory,
                    child: Text(
                      dict['viewHistory']!,
                      style: TextStyle(
                          color: palette.accent,
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
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          decoration: BoxDecoration(
            color: palette.bg,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: palette.border),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              value: widget.lang,
              dropdownColor: palette.containerBg,
              style: TextStyle(fontSize: 14, color: palette.text),
              items: const [
                DropdownMenuItem(value: 'en', child: Text('English')),
                DropdownMenuItem(value: 'ur', child: Text('اردو')),
              ],
              onChanged: (v) {
                if (v != null) widget.onLangChanged(v);
              },
            ),
          ),
        ),
        OutlinedButton(
          onPressed: widget.onThemeToggle,
          style: OutlinedButton.styleFrom(
            foregroundColor: palette.text,
            backgroundColor: palette.bg,
            side: BorderSide(color: palette.border),
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
          ),
          child: Text(widget.darkMode ? dict['light']! : dict['dark']!,
              style: const TextStyle(fontSize: 14)),
        ),
      ],
    );
  }

  Widget _header() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        ClipOval(
          child: Image.asset('assets/icon-192.png',
              width: 46, height: 46, fit: BoxFit.cover),
        ),
        const SizedBox(width: 12),
        Text(dict['title']!,
            style: TextStyle(
                fontSize: 22, fontWeight: FontWeight.w700, color: palette.text)),
      ],
    );
  }

  Widget _ring(double levelProgress, int remInLevel, int lvl) {
    final isRtl = widget.lang == 'ur';
    return SizedBox(
      width: 240,
      height: 240,
      child: Stack(
        alignment: Alignment.center,
        children: [
          Transform.flip(
            flipX: isRtl,
            child: SizedBox(
              width: 222,
              height: 222,
              child: TweenAnimationBuilder<double>(
                tween: Tween(end: completed ? 1.0 : levelProgress),
                duration: const Duration(milliseconds: 400),
                builder: (context, value, _) => CircularProgressIndicator(
                  value: value.clamp(0.0, 1.0),
                  strokeWidth: 14,
                  strokeCap: StrokeCap.round,
                  color: palette.accent,
                  backgroundColor: palette.track,
                ),
              ),
            ),
          ),
          Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                formatClock(completed ? 0 : remInLevel),
                style: TextStyle(
                  fontSize: 46,
                  fontWeight: FontWeight.w700,
                  color: palette.text,
                  fontFeatures: const [FontFeature.tabularFigures()],
                  height: 1,
                ),
              ),
              const SizedBox(height: 10),
              completed
                  ? Text(dict['complete']!,
                      style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                          color: palette.accent))
                  : Text.rich(
                      TextSpan(children: [
                        TextSpan(
                            text: '${dict['level']!} ',
                            style: TextStyle(
                                fontWeight: FontWeight.w500,
                                color: palette.label)),
                        TextSpan(text: '$lvl / $targetLevels'),
                      ]),
                      style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                          color: palette.label),
                    ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _stats(int total) {
    Widget stat(String value, String caption) {
      return Expanded(
        child: Container(
          constraints: const BoxConstraints(maxWidth: 150),
          padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 6),
          decoration: BoxDecoration(
            color: palette.bg,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: palette.border),
          ),
          child: Column(
            children: [
              Text(value,
                  style: TextStyle(
                    fontSize: 19,
                    fontWeight: FontWeight.w700,
                    color: palette.text,
                    fontFeatures: const [FontFeature.tabularFigures()],
                  )),
              const SizedBox(height: 2),
              Text(caption,
                  style: TextStyle(fontSize: 12, color: palette.label)),
            ],
          ),
        ),
      );
    }

    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        stat(formatClock(totalElapsed), dict['elapsed']!),
        const SizedBox(width: 14),
        stat(formatClock((total - totalElapsed).clamp(0, total)),
            dict['remaining']!),
      ],
    );
  }

  Widget _controls() {
    final String primaryLabel;
    if (timerRunning) {
      primaryLabel = '⏸ ${dict['pause']!}';
    } else if (!completed && totalElapsed > 0) {
      primaryLabel = '▶ ${dict['resume']!}';
    } else {
      primaryLabel = '▶ ${dict['start']!}';
    }
    final resetDisabled = timerRunning || (totalElapsed == 0 && !completed);

    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        FilledButton(
          onPressed: _togglePlay,
          style: FilledButton.styleFrom(
            backgroundColor: palette.accent,
            foregroundColor: Colors.white,
            minimumSize: const Size(150, 52),
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
            textStyle:
                const TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
          ),
          child: Text(primaryLabel),
        ),
        const SizedBox(width: 12),
        OutlinedButton(
          onPressed: resetDisabled ? null : _resetTimer,
          style: OutlinedButton.styleFrom(
            foregroundColor: palette.label,
            side: BorderSide(color: palette.border),
            minimumSize: const Size(0, 50),
            padding: const EdgeInsets.symmetric(horizontal: 20),
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
            textStyle:
                const TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
          ),
          child: Text('⟳ ${dict['reset']!}'),
        ),
      ],
    );
  }

  Widget _settings(int total) {
    return Opacity(
      opacity: timerRunning ? 0.45 : 1.0,
      child: Column(
        children: [
          Divider(height: 1, color: palette.border),
          const SizedBox(height: 16),
          Align(
            alignment: AlignmentDirectional.centerStart,
            child: Text(
              dict['settings']!,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                letterSpacing: 0.8,
                color: palette.label,
              ),
            ),
          ),
          const SizedBox(height: 14),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Flexible(
                child: Text(dict['intervalLabel']!,
                    style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: palette.text)),
              ),
              Row(
                children: [
                  _stepper('min', intervalMin, dict['min']!),
                  const SizedBox(width: 16),
                  _stepper('sec', intervalSec, dict['sec']!),
                ],
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Flexible(
                child: Text(dict['levelsLabel']!,
                    style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: palette.text)),
              ),
              _stepper('lev', targetLevels, dict['count']!),
            ],
          ),
          const SizedBox(height: 18),
          Text(
            '${dict['total']!}  ${formatClock(total)}',
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w600,
              color: palette.duration,
              fontFeatures: const [FontFeature.tabularFigures()],
            ),
          ),
        ],
      ),
    );
  }

  Widget _stepper(String type, int value, String unit) {
    Widget btn(String label, int amount) {
      return SizedBox(
        width: 38,
        height: 38,
        child: OutlinedButton(
          onPressed: timerRunning ? null : () => _changeVal(type, amount),
          style: OutlinedButton.styleFrom(
            foregroundColor: palette.accent,
            backgroundColor: palette.bg,
            side: BorderSide(color: palette.border),
            shape: const CircleBorder(),
            padding: EdgeInsets.zero,
          ),
          child: Text(label,
              style:
                  const TextStyle(fontSize: 20, fontWeight: FontWeight.w700)),
        ),
      );
    }

    return Column(
      children: [
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            btn('−', -1),
            SizedBox(
              width: 44,
              child: Text(
                two(value),
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w700,
                  color: palette.text,
                  fontFeatures: const [FontFeature.tabularFigures()],
                ),
              ),
            ),
            btn('+', 1),
          ],
        ),
        const SizedBox(height: 4),
        Text(unit, style: TextStyle(fontSize: 12, color: palette.label)),
      ],
    );
  }
}
