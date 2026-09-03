import 'package:flutter/widgets.dart';

class AppStrings {
  AppStrings(this.locale);

  final Locale locale;
  bool get isSpanish => locale.languageCode.toLowerCase() == 'es';

  String get streak => isSpanish ? 'Racha actual: ' : 'Current streak: ';
  String get noHabits => isSpanish
      ? 'No hay hábitos.\n¡Crea uno nuevo!'
      : 'No habits yet.\nCreate a new one!';
  String get completed => isSpanish ? 'Completado' : 'Completed';
  String get editHint => isSpanish ? 'Toca para editar' : 'Tap to edit';
  String get allCompleted => isSpanish ? 'Todo completado' : 'All completed';
  String habitsProgress(int completed, int total) => isSpanish
      ? '$completed de $total hábitos'
      : '$completed of $total habits';
  String get today => isSpanish ? 'Hoy' : 'Today';
  List<String> get weekdays => isSpanish
      ? ['lun', 'mar', 'mié', 'jue', 'vie', 'sáb', 'dom']
      : ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
  String get changeColor => isSpanish ? 'Cambiar color' : 'Change color';
  String get deleteHabit => isSpanish ? 'Eliminar hábito' : 'Delete habit';
  String get editGroup => isSpanish ? 'Editar grupo' : 'Edit group';
  String get deleteGroup => isSpanish ? 'Eliminar grupo' : 'Delete group';
  String get saveChanges => isSpanish ? 'Guardar cambios' : 'Save changes';
  String get newGroup => isSpanish ? 'Nuevo Grupo' : 'New Group';
  String get moveHabit => isSpanish ? 'Mover hábito' : 'Move habit';
  String get cancel => isSpanish ? 'Cancelar' : 'Cancel';
  String get move => isSpanish ? 'Mover' : 'Move';
  String get save => isSpanish ? 'Guardar' : 'Save';
  String get notificationPermissionTitle => isSpanish
      ? 'Activar recordatorios'
      : 'Enable reminders';
  String get notificationPermissionMessage => isSpanish
      ? 'Permite las notificaciones para recibir recordatorios de tus hábitos pendientes.'
      : 'Allow notifications to receive reminders about your pending habits.';
  String get notificationPermissionLater => isSpanish ? 'Ahora no' : 'Not now';
  String get notificationPermissionAllow => isSpanish ? 'Activar' : 'Allow';
  String get notificationPermissionSettings => isSpanish
      ? 'Puedes activar las notificaciones en Ajustes.'
      : 'You can enable notifications in Settings.';
  String get createGroup => isSpanish ? 'Crear Grupo' : 'Create Group';
  String get selectHabits =>
      isSpanish ? 'Selecciona los hábitos:' : 'Select habits:';
  String get groupNameHint =>
      isSpanish ? 'Nombre (Ej. Mañana, Salud)' : 'Name (e.g. Morning, Health)';
  String get noFreeHabits =>
      isSpanish ? 'No hay hábitos libres' : 'No ungrouped habits';
  String habitsInOtherGroups(int count) => isSpanish
      ? 'Hábitos en otros grupos ($count)'
      : 'Habits in other groups ($count)';
  String get groupName => isSpanish ? 'Nombre del grupo' : 'Group name';
  String get delete => isSpanish ? 'Eliminar' : 'Delete';
  String get currentGroup => isSpanish ? 'Actualmente en:' : 'Currently in:';
  String get emptyName => isSpanish ? 'Escribe un nombre' : 'Enter a name';
  String get editHabit => isSpanish ? 'Editar Hábito' : 'Edit Habit';
  String get newHabit => isSpanish ? 'Nuevo Hábito' : 'New Habit';
  String get habitNameHint => isSpanish ? 'Ej. Beber agua' : 'e.g. Drink water';
  String get chooseIcon => isSpanish ? 'Elige un icono:' : 'Choose an icon:';
  String get noGroup => isSpanish ? 'Sin grupo' : 'No group';
  String get chooseColor => isSpanish ? 'Elegir Color' : 'Choose Color';
  String deleteConfirmationHabit(String name) => isSpanish
      ? '¿Quieres eliminar "$name"? Esta acción no se puede deshacer.'
      : 'Delete "$name"? This action cannot be undone.';
  String deleteConfirmationGroup(String name) => isSpanish
      ? '¿Eliminar "$name"? Sus hábitos quedarán sin grupo.'
      : 'Delete "$name"? Its habits will be left ungrouped.';
  String moveConfirmation(String group) => isSpanish
      ? 'Este hábito ya pertenece a "$group". ¿Quieres moverlo al nuevo grupo?'
      : 'This habit already belongs to "$group". Move it to the new group?';
}

AppStrings stringsOf(BuildContext context) =>
    AppStrings(Localizations.localeOf(context));
