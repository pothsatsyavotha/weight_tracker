import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../models/range.dart';
import '../models/user_profile.dart';
import '../services/auth_service.dart';
import '../services/notification_service.dart';
import '../services/notion_service.dart'; // also exports WeightEntry
import '../theme/palette.dart';
import '../utils/bmi.dart';
import '../utils/format.dart';
import '../widgets/add_sheet.dart';
import '../widgets/bmi_card.dart';
import '../widgets/bouncy.dart';
import '../widgets/delta_chip.dart';
import '../widgets/empty_state.dart';
import '../widgets/error_box.dart';
import '../widgets/fade_slide_in.dart';
import '../widgets/pulse_loader.dart';
import '../widgets/range_selector.dart';
import '../widgets/stats_card.dart';
import 'admin_screen.dart';
import 'goal_screen.dart';

class WeightScreen extends StatefulWidget {
  final AuthService auth;
  const WeightScreen({super.key, required this.auth});

  @override
  State<WeightScreen> createState() => _WeightScreenState();
}

class _WeightScreenState extends State<WeightScreen> {
  final _service = NotionService();
  List<WeightEntry> _all = [];
  Range _range = Range.recent;
  bool _loading = true;
  String? _error;

  AuthService get _auth => widget.auth;
  String get _username => _auth.current!.username;
  UserProfile? get _profile => _auth.current?.profile;

  /// Latest logged weight (entries are oldest-first), else the weight from the goal form.
  double? get _latest => _all.isNotEmpty ? _all.last.weight : _profile?.currentWeight;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final data = await _service.fetchAll(user: _username);
      if (mounted) {
        setState(() => _all = data);
        _syncReminder();
      }
    } catch (e) {
      if (mounted) setState(() => _error = e.toString());
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  /// Every morning: over the BMI limit → lose-weight reminder,
  /// otherwise → "keep it up". Also an instant alert when [notifyNow] and over.
  void _syncReminder({bool notifyNow = false}) {
    final n = NotificationService.instance;
    final p = _profile;
    final w = _latest;
    if (p == null || w == null) {
      n.cancelReminder();
      return;
    }
    final bmi = bmiOf(w, p.heightCm);
    final bmiText = bmi.toStringAsFixed(1);

    if (bmi >= kOverweightBmi) {
      final over = w - healthyMaxKg(p.heightCm);
      final text = 'BMI $bmiText: you are ${fmt(over)} kg above the healthy range. '
          'Let\'s work toward your goal today and log your weight.';
      n.scheduleMorning(title: 'Good morning! Time to lose weight', body: text);
      if (notifyNow) n.showNow(title: 'Weight alert', body: text);
    } else if (bmi < kUnderweightBmi) {
      n.scheduleMorning(
        title: 'Good morning!',
        body: 'BMI $bmiText is below the healthy range. '
            'Eat well and log your weight today.',
      );
    } else {
      n.scheduleMorning(
        title: 'Keep it up! 💪',
        body: 'BMI $bmiText is in the healthy range. '
            'Great job. Log your weight today and keep it up.',
      );
    }
  }

  Future<void> _openGoal() async {
    final saved = await Navigator.of(context).push<bool>(
      MaterialPageRoute(builder: (_) => GoalScreen(auth: _auth)),
    );
    if (saved == true) _syncReminder(notifyNow: true);
  }

  Future<void> _logout() async {
    await NotificationService.instance.cancelReminder();
    await _auth.logout();
  }

  List<WeightEntry> get _filtered {
    final days = _range.days;
    if (days == null) return _all;
    final today = DateTime.now();
    final cutoff = DateTime(today.year, today.month, today.day)
        .subtract(Duration(days: days - 1));
    return _all.where((e) => !e.date.isBefore(cutoff)).toList();
  }

  Future<(DateTime, double)?> _openSheet({WeightEntry? initial}) {
    return showModalBottomSheet<(DateTime, double)>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (_) => AddSheet(initial: initial),
    );
  }

  Future<void> _add() async {
    final result = await _openSheet();
    if (result == null) return;
    try {
      await _service.add(result.$1, result.$2, user: _username);
      await _load();
      _syncReminder(notifyNow: true);
      _snack('Saved ${fmt(result.$2)} kg', ok: true);
    } catch (e) {
      _snack(e.toString());
    }
  }

  Future<void> _edit(WeightEntry entry) async {
    final result = await _openSheet(initial: entry);
    if (result == null) return;
    try {
      await _service.update(entry.id, result.$1, result.$2);
      await _load();
      _syncReminder(notifyNow: true);
      _snack('Updated to ${fmt(result.$2)} kg', ok: true);
    } catch (e) {
      _snack(e.toString());
    }
  }

  Future<void> _delete(WeightEntry e) async {
    setState(() => _all = _all.where((x) => x.id != e.id).toList());
    try {
      await _service.delete(e.id);
      _syncReminder();
    } catch (err) {
      _snack(err.toString());
      _load();
    }
  }

  void _snack(String msg, {bool ok = false}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(
        behavior: SnackBarBehavior.floating,
        backgroundColor: ok ? kGreen : kInk,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        content: Row(children: [
          Icon(ok ? Icons.check_circle : Icons.info_outline,
              color: Colors.white),
          const SizedBox(width: 10),
          Expanded(child: Text(msg)),
        ]),
      ));
  }

  @override
  Widget build(BuildContext context) {
    final entries = _filtered;

    Widget content;
    if (_loading) {
      content = const SizedBox(
        key: ValueKey('loading'),
        height: 320,
        child: Center(child: PulseLoader()),
      );
    } else if (_error != null) {
      content = ErrorBox(
          key: const ValueKey('error'), message: _error!, onRetry: _load);
    } else if (entries.isEmpty) {
      content = const EmptyState(key: ValueKey('empty'));
    } else {
      content = StatsCard(key: ValueKey('stats-${_range.name}'), entries: entries);
    }

    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFFEAF1FF), Color(0xFFF6EFFF), Color(0xFFFFFFFF)],
        ),
      ),
      child: Scaffold(
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          scrolledUnderElevation: 0,
          centerTitle: true,
          leading: PopupMenuButton<String>(
            icon: const Icon(Icons.account_circle_outlined, color: kInk, size: 30),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            onSelected: (v) {
              switch (v) {
                case 'goal':
                  _openGoal();
                case 'admin':
                  Navigator.of(context).push(MaterialPageRoute(
                      builder: (_) => AdminScreen(auth: _auth)));
                case 'logout':
                  _logout();
              }
            },
            itemBuilder: (_) => [
              PopupMenuItem(
                enabled: false,
                child: Text('$_username · ${_auth.isAdmin ? 'Admin' : 'User'}',
                    style: const TextStyle(
                        fontWeight: FontWeight.w700, color: kInk)),
              ),
              const PopupMenuDivider(),
              const PopupMenuItem(
                value: 'goal',
                child: Row(children: [
                  Icon(Icons.flag_outlined, size: 20),
                  SizedBox(width: 10),
                  Text('Goal & BMI'),
                ]),
              ),
              if (_auth.isAdmin)
                const PopupMenuItem(
                  value: 'admin',
                  child: Row(children: [
                    Icon(Icons.admin_panel_settings_outlined, size: 20),
                    SizedBox(width: 10),
                    Text('Admin'),
                  ]),
                ),
              const PopupMenuItem(
                value: 'logout',
                child: Row(children: [
                  Icon(Icons.logout, size: 20),
                  SizedBox(width: 10),
                  Text('Log out'),
                ]),
              ),
            ],
          ),
          title: ShaderMask(
            shaderCallback: (r) => kMainGradient.createShader(r),
            child: const Text('Weight',
                style: TextStyle(
                    fontWeight: FontWeight.w800,
                    fontSize: 22,
                    color: Colors.white)),
          ),
          actions: [
            Padding(
              padding: const EdgeInsets.only(right: 16),
              child: Bouncy(
                onTap: _add,
                child: Container(
                  width: 38,
                  height: 38,
                  decoration: BoxDecoration(
                    gradient: kMainGradient,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                          color: kPurple.withValues(alpha: 0.35),
                          blurRadius: 12,
                          offset: const Offset(0, 4)),
                    ],
                  ),
                  child: const Icon(Icons.add, color: Colors.white),
                ),
              ),
            ),
          ],
        ),
        body: RefreshIndicator(
          color: kPurple,
          onRefresh: _load,
          child: ListView(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 40),
            children: [
              RangeSelector(
                value: _range,
                onChanged: (r) => setState(() => _range = r),
              ),
              const SizedBox(height: 20),
              if (!_loading && _error == null) ...[
                BmiCard(
                  profile: _profile,
                  latestWeight: _latest,
                  onEdit: _openGoal,
                ),
                const SizedBox(height: 20),
              ],
              AnimatedSwitcher(
                duration: const Duration(milliseconds: 450),
                switchInCurve: Curves.easeOutCubic,
                switchOutCurve: Curves.easeIn,
                transitionBuilder: (child, anim) => FadeTransition(
                  opacity: anim,
                  child: SlideTransition(
                    position: Tween(
                        begin: const Offset(0, 0.04), end: Offset.zero)
                        .animate(anim),
                    child: child,
                  ),
                ),
                child: content,
              ),
              const SizedBox(height: 20),
              Bouncy(
                onTap: _add,
                child: Container(
                  height: 56,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    gradient: kMainGradient,
                    borderRadius: BorderRadius.circular(28),
                    boxShadow: [
                      BoxShadow(
                          color: kBlue.withValues(alpha: 0.35),
                          blurRadius: 18,
                          offset: const Offset(0, 8)),
                    ],
                  ),
                  child: const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.add_circle_outline, color: Colors.white),
                      SizedBox(width: 8),
                      Text('Add Weight',
                          style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w700,
                              color: Colors.white)),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 28),
              const Text('History',
                  style: TextStyle(
                      fontSize: 22, fontWeight: FontWeight.w800, color: kInk)),
              const SizedBox(height: 12),
              for (int j = 0; j < entries.length; j++)
                _historyRow(entries, entries.length - 1 - j, j),
            ],
          ),
        ),
      ),
    );
  }

  /// [idx] = index in oldest-first list, [order] = display position (0 = newest).
  Widget _historyRow(List<WeightEntry> entries, int idx, int order) {
    final e = entries[idx];
    final prev = idx > 0 ? entries[idx - 1] : null;
    final delta = prev == null ? null : e.weight - prev.weight;
    final color = delta == null || delta == 0
        ? Colors.grey
        : (delta < 0 ? kGreen : kOrange);

    return FadeSlideIn(
      key: ValueKey('${e.id}-${_range.name}'),
      delay: Duration(milliseconds: 60 * math.min(order, 8)),
      child: Dismissible(
        key: ValueKey('dismiss-${e.id}'),
        direction: DismissDirection.endToStart,
        background: Container(
          margin: const EdgeInsets.only(bottom: 10),
          decoration: BoxDecoration(
            gradient: const LinearGradient(colors: [kOrange, Color(0xFFFF3D6E)]),
            borderRadius: BorderRadius.circular(20),
          ),
          alignment: Alignment.centerRight,
          padding: const EdgeInsets.only(right: 24),
          child: const Icon(Icons.delete_outline, color: Colors.white),
        ),
        onDismissed: (_) => _delete(e),
        child: Bouncy(
          onTap: () => _edit(e),
          child: Container(
            margin: const EdgeInsets.only(bottom: 10),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              border: Border(left: BorderSide(color: color, width: 5)),
              boxShadow: [
                BoxShadow(
                    color: kPurple.withValues(alpha: 0.07),
                    blurRadius: 14,
                    offset: const Offset(0, 5)),
              ],
            ),
            child: Row(
              children: [
                Expanded(
                  child: Text(DateFormat('d MMMM y').format(e.date),
                      style: const TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.w500,
                          color: kInk)),
                ),
                if (delta != null && delta != 0) ...[
                  DeltaChip(delta: delta, small: true),
                  const SizedBox(width: 10),
                ],
                Text('${fmt(e.weight)} kg',
                    style: const TextStyle(
                        fontSize: 17, fontWeight: FontWeight.w800, color: kInk)),
                const SizedBox(width: 8),
                Icon(Icons.edit_outlined, size: 16, color: Colors.grey.shade400),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
