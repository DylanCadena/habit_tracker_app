import 'package:flutter/material.dart';
import '../models/habit.dart';
import '../data/database_helper.dart';

class HabitProvider with ChangeNotifier {
  List<Habit> _habits = [];
  int _streak = 0;
  String _lastStreakDate = '';

  List<Habit> get habits => _habits;
  int get streak => _streak;
  bool get allCompleted =>
      _habits.isNotEmpty && _habits.every((h) => h.isCompleted);

  HabitProvider() {
    loadData();
  }

  Future<void> loadData() async {
    _habits = await DatabaseHelper.instance.readAllHabits();
    _groups = await DatabaseHelper.instance.readAllGroups();
    final stats = await DatabaseHelper.instance.getStats();

    _streak = stats['streak'] as int;
    final String lastDate = stats['lastDate'] as String;
    final String lastStreakDate = stats['lastStreakDate'] as String;
    _lastStreakDate = lastStreakDate;

    final today = DateTime.now().toIso8601String().split('T')[0];

    // Un nuevo día reinicia las casillas, pero la racha se actualiza al completar el día.
    if (lastDate != today && lastDate.isNotEmpty) {
      for (var habit in _habits) {
        habit.isCompleted = false;
      }
      await DatabaseHelper.instance.updateAllHabitsStatus(false);
      await DatabaseHelper.instance.updateStats(_streak, today, lastStreakDate);
    } else if (lastDate.isEmpty) {
      await DatabaseHelper.instance.updateStats(_streak, today, lastStreakDate);
    }

    notifyListeners();
  }

  Future<void> addHabit(String name, int iconCode, {int? colorValue}) async {
    final newHabit = Habit(
      id: DateTime.now().toString(),
      name: name,
      orderIndex: _habits.length,
      iconCode: iconCode,
      colorValue: colorValue ?? 0xFFBA55D3,
    );
    _habits.add(newHabit);

    // 1. Primero actualizamos la pantalla INMEDIATAMENTE
    notifyListeners();

    // 2. Luego intentamos guardarlo en la base de datos
    try {
      await DatabaseHelper.instance.insertHabit(newHabit);
    } catch (e) {
      debugPrint("Error guardando en DB: $e");
    }
  }

  Future<void> editHabit(String id, String newName, int iconCode) async {
    final index = _habits.indexWhere((h) => h.id == id);
    if (index != -1) {
      _habits[index].name = newName;
      _habits[index].iconCode = iconCode;

      // Actualizamos la pantalla al instante
      notifyListeners();

      try {
        await DatabaseHelper.instance.updateHabit(_habits[index]);
      } catch (e) {
        debugPrint("Error actualizando en DB: $e");
      }
    }
  }

  Future<void> toggleHabit(String id) async {
    final index = _habits.indexWhere((h) => h.id == id);
    if (index != -1) {
      if (!_habits[index].isCompleted) {
        _habits[index].isCompleted = true;
        await DatabaseHelper.instance.updateHabit(_habits[index]);
        final today = DateTime.now().toIso8601String().split('T')[0];
        if (allCompleted && _lastStreakDate != today) {
          _streak++;
          _lastStreakDate = today;
          await DatabaseHelper.instance.updateStats(_streak, today, today);
        }
        notifyListeners();
      }
    }
  }

  Future<void> reorderHabits(int oldIndex, int newIndex) async {
    if (newIndex > oldIndex) newIndex -= 1;
    final item = _habits.removeAt(oldIndex);
    _habits.insert(newIndex, item);

    for (int i = 0; i < _habits.length; i++) {
      _habits[i].orderIndex = i;
      await DatabaseHelper.instance.updateHabit(_habits[i]);
    }
    notifyListeners();
  }

  Future<void> reorderHabitsInGroup(
    String groupId,
    int oldIndex,
    int newIndex,
  ) async {
    final groupHabits = _habits
        .where((habit) => habit.groupId == groupId)
        .toList();
    if (oldIndex < 0 || oldIndex >= groupHabits.length) return;
    if (newIndex > oldIndex) newIndex -= 1;
    if (newIndex < 0 || newIndex >= groupHabits.length) return;

    final habit = groupHabits.removeAt(oldIndex);
    groupHabits.insert(newIndex, habit);
    var groupPosition = 0;
    for (final item in _habits) {
      if (item.groupId == groupId) {
        item.orderIndex = groupPosition++;
      }
    }

    final positions = <int>[];
    for (var index = 0; index < _habits.length; index++) {
      if (_habits[index].groupId == groupId) positions.add(index);
    }
    for (var index = 0; index < positions.length; index++) {
      _habits[positions[index]] = groupHabits[index];
    }
    for (final item in _habits) {
      await DatabaseHelper.instance.updateHabit(item);
    }
    notifyListeners();
  }

  Future<void> moveGroup(int oldIndex, int newIndex) async {
    if (oldIndex < 0 || oldIndex >= _groups.length) return;
    if (newIndex < 0 || newIndex >= _groups.length) return;

    final group = _groups.removeAt(oldIndex);
    _groups.insert(newIndex, group);
    for (var index = 0; index < _groups.length; index++) {
      _groups[index].orderIndex = index;
      await DatabaseHelper.instance.updateGroup(_groups[index]);
    }
    notifyListeners();
  }

  // Nueva función para actualizar solo el color
  Future<void> updateHabitColor(String id, int newColor) async {
    final index = _habits.indexWhere((h) => h.id == id);
    if (index != -1) {
      _habits[index].colorValue = newColor;
      await DatabaseHelper.instance.updateHabit(_habits[index]);
      notifyListeners();
    }
  }

  List<HabitGroup> _groups = [];
  List<HabitGroup> get groups => _groups;

  // Función para crear grupo y asignar hábitos
  Future<bool> createGroup(String name, List<String> selectedHabitIds) async {
    final newGroup = HabitGroup(
      id: DateTime.now().toString(),
      name: name,
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
      return true;
    } catch (e) {
      debugPrint("Error guardando grupo: $e");
      return false;
    }
  }

  // 3. Función para cambiar de grupo un hábito individual (si decides hacerlo desde edición)
  Future<void> updateHabitGroup(String habitId, String newGroupId) async {
    final index = _habits.indexWhere((h) => h.id == habitId);
    if (index != -1) {
      _habits[index].groupId = newGroupId;
      notifyListeners();
      await DatabaseHelper.instance.updateHabit(_habits[index]);
    }
  }
}
