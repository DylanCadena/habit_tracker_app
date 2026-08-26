import 'package:flutter/material.dart';
import '../models/habit.dart';
import '../data/database_helper.dart';

class HabitProvider with ChangeNotifier {
  List<Habit> _habits = [];
  int _streak = 0;
  
  List<Habit> get habits => _habits;
  int get streak => _streak;
  bool get allCompleted => _habits.isNotEmpty && _habits.every((h) => h.isCompleted);

  HabitProvider() {
    loadData();
  }

  Future<void> loadData() async {
    _habits = await DatabaseHelper.instance.readAllHabits();
    final stats = await DatabaseHelper.instance.getStats();
    
    _streak = stats['streak'] as int;
    final String lastDate = stats['lastDate'] as String;
    final String lastStreakDate = stats['lastStreakDate'] as String;
    
    final today = DateTime.now().toIso8601String().split('T')[0];

    // LÓGICA CORREGIDA: Solo evaluamos la racha cuando cambia el día
    if (lastDate != today && lastDate.isNotEmpty) {
      if (allCompleted) {
        _streak++; // Cumplió todo ayer, suma la racha
      } else {
        _streak = 0; // Le faltó algún hábito ayer, se pierde la racha
      }
      
      // Reiniciamos las casillas para el nuevo día
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

Future<void> addHabit(String name, int iconCode) async {
    final newHabit = Habit(
      id: DateTime.now().toString(), 
      name: name,
      orderIndex: _habits.length,
      iconCode: iconCode, 
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
        // Ya no sumamos racha aquí. Solo marcamos como completado.
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
  // Nueva función para actualizar solo el color
  Future<void> updateHabitColor(String id, int newColor) async {
    final index = _habits.indexWhere((h) => h.id == id);
    if (index != -1) {
      _habits[index].colorValue = newColor;
      await DatabaseHelper.instance.updateHabit(_habits[index]);
      notifyListeners();
    }
  }
}