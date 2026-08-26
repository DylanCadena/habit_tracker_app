class Habit {
  String id;
  String name;
  bool isCompleted;
  int orderIndex;
  int colorValue;
  int iconCode; // Nuevo campo para el icono

  Habit({
    required this.id,
    required this.name,
    this.isCompleted = false,
    this.orderIndex = 0,
    this.colorValue = 0xFFBA55D3,
    this.iconCode = 0xe5fc, // Código por defecto para Icons.star_rounded
  });

  Map<String, dynamic> toMap() => {
    'id': id,
    'name': name,
    'isCompleted': isCompleted ? 1 : 0,
    'orderIndex': orderIndex,
    'colorValue': colorValue,
    'iconCode': iconCode,
  };

  factory Habit.fromMap(Map<String, dynamic> map) => Habit(
    id: map['id'],
    name: map['name'],
    isCompleted: map['isCompleted'] == 1,
    orderIndex: map['orderIndex'] ?? 0,
    colorValue: map['colorValue'] ?? 0xFFBA55D3,
    iconCode: map['iconCode'] ?? 0xe5fc,
  );
}