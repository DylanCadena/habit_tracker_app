import 'package:flutter/material.dart';
import '../models/habit.dart';
import '../data/database_helper.dart';
import '../services/notification_service.dart';

class HabitProvider with ChangeNotifier {
  List<Habit> _habits = [];
  int _streak = 0;
  String _lastStreakDate = '';
  late final Future<void> _initialization;

  List<Habit> get habits => _habits;
  int get streak => _streak;
  bool get allCompleted =>
      _habits.isNotEmpty && _habits.every((h) => h.isCompleted);

  HabitProvider() {
    _initialization = loadData();
  }

  Future<void> loadData() async {
    _habits = await DatabaseHelper.instance.readAllHabits();
    _groups = await DatabaseHelper.instance.readAllGroups();
    final stats = await DatabaseHelper.instance.getStats();

    _streak = stats['streak'] as int;
    final String lastDate = stats['lastDate'] as String;
    _lastStreakDate = stats['lastStreakDate'] as String;

    final today = DateTime.now().toIso8601String().split('T')[0];

    if (_lastStreakDate.isNotEmpty) {
      final streakDate = DateTime.tryParse(_lastStreakDate);
      final todayDate = DateTime.parse(today);
      final daysSinceStreak = streakDate == null
          ? null
          : todayDate.difference(streakDate).inDays;
      if (daysSinceStreak == null || daysSinceStreak > 1) {
        _streak = 0;
        _lastStreakDate = '';
        await DatabaseHelper.instance.updateStats(_streak, today, '');
      }
    }

    await _refreshDay(lastDate, today);
    await _syncNotifications();

    notifyListeners();
  }

  Future<void> _syncNotifications() async {
    final pendingCount = _habits.where((habit) => !habit.isCompleted).length;
    try {
      await NotificationService.instance.syncForPendingHabits(pendingCount);
    } catch (error) {
      debugPrint('Notification sync failed: $error');
    }
  }

  Future<void> _refreshDay(String lastDate, String today) async {
    if (lastDate == today) return;

    for (var habit in _habits) {
      habit.isCompleted = false;
    }
    await DatabaseHelper.instance.updateAllHabitsStatus(false);
    await DatabaseHelper.instance.updateStats(_streak, today, _lastStreakDate);
  }

  Future<void> _waitForInitialization() => _initialization;

  Future<void> addHabit(String name, int iconCode, {int? colorValue}) async {
    await _waitForInitialization();
    final trimmedName = name.trim();
    if (trimmedName.isEmpty) return;

    final newHabit = Habit(
      id: DateTime.now().toString(),
      name: trimmedName,
      orderIndex: _habits.length,
      iconCode: iconCode,
      colorValue: colorValue ?? 0xFFBA55D3,
    );
    _habits.add(newHabit);

    notifyListeners();

    try {
      await DatabaseHelper.instance.insertHabit(newHabit);
      await _syncNotifications();
    } catch (e) {
      debugPrint("Error guardando en DB: $e");
    }
  }

  Future<void> editHabit(String id, String newName, int iconCode) async {
    await _waitForInitialization();
    final trimmedName = newName.trim();
    if (trimmedName.isEmpty) return;

    final index = _habits.indexWhere((h) => h.id == id);
    if (index != -1) {
      _habits[index].name = trimmedName;
      _habits[index].iconCode = iconCode;

      notifyListeners();

      try {
        await DatabaseHelper.instance.updateHabit(_habits[index]);
        await _syncNotifications();
      } catch (e) {
        debugPrint("Error actualizando en DB: $e");
      }
    }
  }

  Future<void> toggleHabit(String id) async {
    await _waitForInitialization();
    final today = DateTime.now().toIso8601String().split('T')[0];
    final stats = await DatabaseHelper.instance.getStats();
    final lastDate = stats['lastDate'] as String;
    if (lastDate != today) {
      await _refreshDay(lastDate, today);
    }

    final index = _habits.indexWhere((h) => h.id == id);
    if (index != -1) {
      final wasCompleted = _habits[index].isCompleted;
      _habits[index].isCompleted = !wasCompleted;
      await DatabaseHelper.instance.updateHabit(_habits[index]);

      if (!wasCompleted) {
        if (allCompleted && _lastStreakDate != today) {
          _streak++;
          _lastStreakDate = today;
        }
      } else if (_lastStreakDate == today && !allCompleted) {
        _streak = (_streak - 1).clamp(0, _streak);
        final yesterday = DateTime.parse(
          today,
        ).subtract(const Duration(days: 1));
        _lastStreakDate = _streak == 0
            ? ''
            : yesterday.toIso8601String().split('T')[0];
      }

      await DatabaseHelper.instance.updateStats(
        _streak,
        today,
        _lastStreakDate,
      );
      await _syncNotifications();
      notifyListeners();
    }
  }

  Future<void> reorderHabits(int oldIndex, int newIndex) async {
    await _waitForInitialization();
    if (newIndex > oldIndex) newIndex -= 1;
    final item = _habits.removeAt(oldIndex);
    _habits.insert(newIndex, item);

    for (int i = 0; i < _habits.length; i++) {
      _habits[i].orderIndex = i;
    }
    await DatabaseHelper.instance.updateHabitOrder(_habits);
    notifyListeners();
  }

  Future<void> reorderHabitsInGroup(
    String groupId,
    int oldIndex,
    int newIndex,
  ) async {
    await _waitForInitialization();
    final groupHabits = _habits
        .where((habit) => habit.groupId == groupId)
        .toList();
    if (oldIndex < 0 || oldIndex >= groupHabits.length) return;
    if (newIndex > oldIndex) newIndex -= 1;
    if (newIndex < 0 || newIndex > groupHabits.length - 1) return;

    final habit = groupHabits.removeAt(oldIndex);
    groupHabits.insert(newIndex, habit);

    final positions = <int>[];
    for (var index = 0; index < _habits.length; index++) {
      if (_habits[index].groupId == groupId) positions.add(index);
    }
    for (var index = 0; index < positions.length; index++) {
      _habits[positions[index]] = groupHabits[index];
    }
    for (var index = 0; index < _habits.length; index++) {
      _habits[index].orderIndex = index;
    }
    await DatabaseHelper.instance.updateHabitOrder(_habits);
    notifyListeners();
  }

  Future<void> moveGroup(int oldIndex, int newIndex) async {
    await _waitForInitialization();
    if (oldIndex < 0 || oldIndex >= _groups.length) return;
    if (newIndex > oldIndex) newIndex -= 1;
    if (newIndex < 0 || newIndex > _groups.length - 1) return;

    final group = _groups.removeAt(oldIndex);
    _groups.insert(newIndex, group);
    for (var index = 0; index < _groups.length; index++) {
      _groups[index].orderIndex = index;
    }
    await DatabaseHelper.instance.updateGroupOrder(_groups);
    notifyListeners();
  }

  Future<void> deleteHabit(String id) async {
    await _waitForInitialization();
    final index = _habits.indexWhere((habit) => habit.id == id);
    if (index == -1) return;

    _habits.removeAt(index);
    await DatabaseHelper.instance.deleteHabit(id);
    await _syncNotifications();
    notifyListeners();
  }

  Future<void> deleteGroup(String id) async {
    await _waitForInitialization();
    final groupIndex = _groups.indexWhere((group) => group.id == id);
    if (groupIndex == -1) return;

    for (final habit in _habits.where((habit) => habit.groupId == id)) {
      habit.groupId = '';
      await DatabaseHelper.instance.updateHabit(habit);
    }
    _groups.removeAt(groupIndex);
    await DatabaseHelper.instance.deleteGroup(id);
    notifyListeners();
  }

  Future<void> updateHabitColor(String id, int newColor) async {
    await _waitForInitialization();
    final index = _habits.indexWhere((h) => h.id == id);
    if (index != -1) {
      _habits[index].colorValue = newColor;
      await DatabaseHelper.instance.updateHabit(_habits[index]);
      notifyListeners();
    }
  }

  List<HabitGroup> _groups = [];
  List<HabitGroup> get groups => _groups;

  Future<bool> createGroup(String name, List<String> selectedHabitIds) async {
    await _waitForInitialization();
    final trimmedName = name.trim();
    if (trimmedName.isEmpty) return false;

    final newGroup = HabitGroup(
      id: DateTime.now().toString(),
      name: trimmedName,
      orderIndex: _groups.length,
    );

    try {
      await DatabaseHelper.instance.insertGroup(newGroup);
      for (var habitId in selectedHabitIds) {
        final index = _habits.indexWhere((h) => h.id == habitId);
        if (index != -1) {
          _habits[index].groupId = newGroup.id;
          await DatabaseHelper.instance.updateHabit(_habits[index]);
        }
      }

      _groups.add(newGroup);
      notifyListeners();
      return true;
    } catch (e) {
      debugPrint("Error guardando grupo: $e");
      return false;
    }
  }

  Future<void> updateGroupContents(
    String groupId,
    String name,
    List<String> selectedHabitIds,
  ) async {
    await _waitForInitialization();
    final trimmedName = name.trim();
    if (trimmedName.isEmpty) return;
    final groupIndex = _groups.indexWhere((group) => group.id == groupId);
    if (groupIndex == -1) return;

    final selectedIds = selectedHabitIds.toSet();
    for (final habit in _habits) {
      if (selectedIds.contains(habit.id)) {
        habit.groupId = groupId;
      } else if (habit.groupId == groupId) {
        habit.groupId = '';
      }
      await DatabaseHelper.instance.updateHabit(habit);
    }

    _groups[groupIndex].name = trimmedName;
    await DatabaseHelper.instance.updateGroup(_groups[groupIndex]);
    notifyListeners();
  }

  Future<void> updateHabitGroup(String habitId, String newGroupId) async {
    await _waitForInitialization();
    final index = _habits.indexWhere((h) => h.id == habitId);
    if (index != -1) {
      _habits[index].groupId = newGroupId;
      notifyListeners();
      await DatabaseHelper.instance.updateHabit(_habits[index]);
    }
  }
}
