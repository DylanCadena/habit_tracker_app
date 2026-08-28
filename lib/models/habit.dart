class HabitGroup {
  String id;
  String name;
  int orderIndex;

  HabitGroup({required this.id, required this.name, this.orderIndex = 0});

  Map<String, dynamic> toMap() => {
    'id': id,
    'name': name,
    'orderIndex': orderIndex,
  };

  factory HabitGroup.fromMap(Map<String, dynamic> map) => HabitGroup(
    id: map['id'],
    name: map['name'],
    orderIndex: map['orderIndex'] ?? 0,
  );
}

class Habit {
  String id;
  String name;
  bool isCompleted;
  int orderIndex;
  int colorValue;
  int iconCode;
  String groupId; // NUEVO: Para saber en qué grupo está

  Habit({
    required this.id,
    required this.name,
    this.isCompleted = false,
    this.orderIndex = 0,
    this.colorValue = 0xFFBA55D3,
    this.iconCode = 0xe5fc,
    this.groupId = '', // Vacío significa que no tiene grupo
  });

  Map<String, dynamic> toMap() => {
    'id': id,
    'name': name,
    'isCompleted': isCompleted ? 1 : 0,
    'orderIndex': orderIndex,
    'colorValue': colorValue,
    'iconCode': iconCode,
    'groupId': groupId,
  };

  factory Habit.fromMap(Map<String, dynamic> map) => Habit(
    id: map['id'],
    name: map['name'],
    isCompleted: map['isCompleted'] == 1,
    orderIndex: map['orderIndex'] ?? 0,
    colorValue: map['colorValue'] ?? 0xFFBA55D3,
    iconCode: map['iconCode'] ?? 0xe5fc,
    groupId: map['groupId'] ?? '',
  );
}