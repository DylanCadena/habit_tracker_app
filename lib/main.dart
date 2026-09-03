import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:confetti/confetti.dart';
import 'dart:math';
import 'providers/habit_provider.dart';
import 'models/habit.dart';
import 'package:google_fonts/google_fonts.dart';
import 'services/notification_service.dart';
import 'l10n/app_strings.dart';
import 'package:shared_preferences/shared_preferences.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  try {
    await NotificationService.instance.initialize();
  } catch (error) {
    debugPrint('Notification setup failed: $error');
  }
  runApp(
    ChangeNotifierProvider(
      create: (context) => HabitProvider(),
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Streakify',
      supportedLocales: const [Locale('es'), Locale('en')],
      localeResolutionCallback: (locale, supportedLocales) {
        return locale?.languageCode.toLowerCase() == 'es'
            ? const Locale('es')
            : const Locale('en');
      },
      theme: ThemeData.dark().copyWith(
        scaffoldBackgroundColor: const Color(0xFF121212),
        textTheme: GoogleFonts.quicksandTextTheme(
          Theme.of(context).textTheme,
        ).apply(bodyColor: Colors.white),
      ),
      home: const SplashScreen(),
    );
  }
}

// --- SPLASH SCREEN ---
class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    Future.delayed(const Duration(seconds: 2), () {
      if (!mounted) return;
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const HomeScreen()),
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Image.asset(
              'assets/logo_streakify.png',
              width: 180,
              height: 180,
              fit: BoxFit.contain,
            ),
            const SizedBox(height: 20),
            const Text(
              'Streakify',
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// --- HOME SCREEN ---
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  late ConfettiController _confettiController;
  bool _isEditMode = false;
  bool _isCreatingGroup = false;
  final Map<String, bool> _expandedGroups = {};

  final List<Color> _cardColors = [
    const Color(0xFFBA55D3),
    const Color(0xFF4FC3F7),
    const Color(0xFF2196F3),
    const Color(0xFF4CAF50),
    const Color(0xFFF44336),
    const Color(0xFFFF9800),
    const Color(0xFF26A69A),
    const Color(0xFFAB47BC),
    const Color(0xFFEC407A),
    const Color(0xFF5C6BC0),
    const Color(0xFF8BC34A),
    const Color.fromARGB(255, 192, 150, 26),
  ];

  // Lista de iconos disponibles para elegir
  final List<IconData> _availableIcons = [
    Icons.star_rounded,
    Icons.fitness_center,
    Icons.medical_services,
    Icons.book,
    Icons.water_drop,
    Icons.directions_run,
    Icons.eco,
    Icons.self_improvement,
    Icons.cleaning_services,
    Icons.monitor_heart,
    Icons.bedtime,
    Icons.restaurant,
    Icons.lightbulb,
    Icons.music_note,
    Icons.bookmark,
    Icons.directions_bike,
    Icons.pets,
    Icons.spa,
    Icons.check_circle,
    Icons.timer,
  ];

  @override
  void initState() {
    super.initState();
    _confettiController = ConfettiController(
      duration: const Duration(seconds: 2),
    );
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _requestNotificationPermissionIfNeeded();
    });
  }

  Future<void> _requestNotificationPermissionIfNeeded() async {
    try {
      final preferences = await SharedPreferences.getInstance();
      if (preferences.getBool('notification_permission_prompt_shown') == true ||
          !mounted) {
        return;
      }

      final strings = stringsOf(context);
      final allow = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: Text(strings.notificationPermissionTitle),
          content: Text(strings.notificationPermissionMessage),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: Text(strings.notificationPermissionLater),
            ),
            FilledButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: Text(strings.notificationPermissionAllow),
            ),
          ],
        ),
      );

      await preferences.setBool('notification_permission_prompt_shown', true);
      if (!mounted) return;

      if (allow != true) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(strings.notificationPermissionSettings)),
        );
        return;
      }

      final granted = await NotificationService.instance.requestPermissions();
      if (!mounted || granted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(strings.notificationPermissionSettings)),
      );
    } catch (error) {
      debugPrint('Notification permission flow failed: $error');
    }
  }

  @override
  void dispose() {
    _confettiController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final strings = stringsOf(context);
    final provider = context.watch<HabitProvider>();
    final completedHabits = provider.habits
        .where((habit) => habit.isCompleted)
        .length;
    final progress = provider.habits.isEmpty
        ? 0.0
        : completedHabits / provider.habits.length;
    final ungroupedHabits = provider.habits
        .where((habit) => habit.groupId.isEmpty)
        .toList();

    Widget buildDaySelector() {
      final today = DateTime.now();
      final weekdayLabels = strings.weekdays;

      return SizedBox(
        height: 78,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: List.generate(7, (index) {
            final date = today.add(Duration(days: index - 3));
            final isToday = index == 3;
            final label = weekdayLabels[date.weekday - 1];

            return SizedBox(
              width: 42,
              child: Container(
                decoration: BoxDecoration(
                  color: isToday
                      ? const Color(0xFF6655E8)
                      : const Color(0xFF24242A),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: isToday ? const Color(0xFF8D80FF) : Colors.white12,
                  ),
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      label,
                      style: GoogleFonts.quicksand(
                        color: isToday ? Colors.white70 : Colors.white38,
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${date.day}',
                      style: GoogleFonts.quicksand(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            );
          }),
        ),
      );
    }

    Widget buildHabitCard(dynamic habit, int index) {
      final cardColor = Color(habit.colorValue);
      final habitIcon = IconData(habit.iconCode, fontFamily: 'MaterialIcons');

      return Container(
        key: ValueKey(habit.id),
        margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
        decoration: BoxDecoration(
          color: cardColor.withValues(
            alpha: 0.95,
          ), // Color ligeramente translúcido
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: cardColor.withValues(alpha: 0.3),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
          border: _isEditMode
              ? Border.all(color: Colors.white, width: 2)
              : null,
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 15),
          child: Row(
            children: [
              if (_isEditMode)
                ReorderableDragStartListener(
                  index: index,
                  child: const Padding(
                    padding: EdgeInsets.only(right: 12.0),
                    child: Icon(
                      Icons.drag_indicator,
                      color: Colors.white70,
                      size: 28,
                    ),
                  ),
                ),

              Container(
                padding: const EdgeInsets.all(7),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.2),
                  shape: BoxShape.circle,
                ),
                child: Icon(habitIcon, color: Colors.white, size: 24),
              ),
              const SizedBox(width: 16),

              Expanded(
                child: GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTap: _isEditMode
                      ? () => _showAddOrEditDialog(context, habit: habit)
                      : null,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        habit.name,
                        style: GoogleFonts.quicksand(
                          color: Colors.white,
                          fontSize: 17,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 4),
                      if (_isEditMode)
                        Text(
                          strings.editHint,
                          style: GoogleFonts.quicksand(
                            color: Colors.white.withValues(alpha: 0.7),
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                          ),
                        )
                      else if (habit.isCompleted)
                        Text(
                          strings.completed,
                          style: GoogleFonts.quicksand(
                            color: Colors.white.withValues(alpha: 0.7),
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                    ],
                  ),
                ),
              ),

              if (_isEditMode)
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      tooltip: strings.changeColor,
                      icon: const Icon(
                        Icons.palette,
                        color: Colors.white,
                        size: 28,
                      ),
                      onPressed: () => _showColorPicker(context, habit),
                    ),
                    IconButton(
                      tooltip: strings.deleteHabit,
                      icon: const Icon(
                        Icons.delete_outline,
                        color: Colors.redAccent,
                        size: 28,
                      ),
                      onPressed: () => _confirmDeleteHabit(context, habit),
                    ),
                  ],
                )
              else
                GestureDetector(
                  onTap: () async {
                    final prov = context.read<HabitProvider>();
                    await prov.toggleHabit(habit.id);
                    if (prov.allCompleted) _confettiController.play();
                  },
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 300),
                    width: 46,
                    height: 46,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: habit.isCompleted
                          ? Colors.white
                          : Colors.black.withValues(alpha: 0.2),
                      boxShadow: habit.isCompleted
                          ? [
                              BoxShadow(
                                color: Colors.white.withValues(alpha: 0.5),
                                blurRadius: 8,
                              ),
                            ]
                          : [],
                    ),
                    child: Icon(
                      habit.isCompleted ? Icons.check : Icons.add,
                      color: habit.isCompleted ? cardColor : Colors.white,
                      size: 25,
                    ),
                  ),
                ),
            ],
          ),
        ),
      );
    }

    Widget buildHabitList(
      List<dynamic> habits,
      Future<void> Function(int, int) onReorder,
    ) {
      if (habits.isEmpty) return const SizedBox.shrink();

      if (!_isEditMode) {
        return Column(
          children: habits
              .asMap()
              .entries
              .map((entry) => buildHabitCard(entry.value, entry.key))
              .toList(),
        );
      }

      return ReorderableListView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        buildDefaultDragHandles: false,
        itemCount: habits.length,
        onReorder: onReorder,
        itemBuilder: (context, index) => buildHabitCard(habits[index], index),
      );
    }

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        title: Column(
          children: [
            const SizedBox(height: 10),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  strings.streak,
                  style: GoogleFonts.quicksand(
                    fontWeight: FontWeight.w600,
                    fontSize: 24,
                    color: Colors.white70,
                  ),
                ),
                Text(
                  '${provider.streak} ',
                  style: GoogleFonts.quicksand(
                    fontWeight: FontWeight.bold,
                    fontSize: 30,
                    color: Colors.white,
                  ),
                ),
                Image.asset('assets/fire.gif', width: 34, height: 34),
              ],
            ),
          ],
        ),
      ),
      body: Stack(
        children: [
          provider.habits.isEmpty
              ? Center(
                  child: Text(
                    strings.noHabits,
                    textAlign: TextAlign.center,
                    style: GoogleFonts.quicksand(
                      color: Colors.white54,
                      fontSize: 18,
                    ),
                  ),
                )
              : ListView(
                  padding: const EdgeInsets.only(bottom: 120, top: 10),
                  children: [
                    buildDaySelector(),
                    Padding(
                      padding: const EdgeInsets.fromLTRB(20, 20, 20, 10),
                      child: Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  strings.today,
                                  style: GoogleFonts.quicksand(
                                    color: Colors.white,
                                    fontSize: 24,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(height: 3),
                                Text(
                                  completedHabits == provider.habits.length
                                      ? strings.allCompleted
                                      : strings.habitsProgress(
                                          completedHabits,
                                          provider.habits.length,
                                        ),
                                  style: GoogleFonts.quicksand(
                                    color: Colors.white54,
                                    fontSize: 14,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          SizedBox(
                            width: 48,
                            height: 48,
                            child: Stack(
                              alignment: Alignment.center,
                              children: [
                                TweenAnimationBuilder<double>(
                                  tween: Tween<double>(end: progress),
                                  duration: const Duration(milliseconds: 550),
                                  curve: Curves.easeOutCubic,
                                  builder: (context, animatedProgress, child) {
                                    return CircularProgressIndicator(
                                      value: animatedProgress,
                                      strokeWidth: 5,
                                      backgroundColor: Colors.white12,
                                      valueColor: const AlwaysStoppedAnimation(
                                        Color(0xFF36D275),
                                      ),
                                    );
                                  },
                                ),
                                TweenAnimationBuilder<double>(
                                  tween: Tween<double>(end: progress * 100),
                                  duration: const Duration(milliseconds: 550),
                                  curve: Curves.easeOutCubic,
                                  builder: (context, animatedPercent, child) {
                                    return Text(
                                      '${animatedPercent.round()}%',
                                      style: GoogleFonts.quicksand(
                                        color: Colors.white,
                                        fontSize: 11,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    );
                                  },
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    buildHabitList(
                      ungroupedHabits,
                      (oldIndex, newIndex) =>
                          provider.reorderHabitsInGroup('', oldIndex, newIndex),
                    ),
                    ReorderableListView(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      buildDefaultDragHandles: false,
                      onReorder: provider.moveGroup,
                      children: provider.groups.map((group) {
                        final groupIndex = provider.groups.indexOf(group);
                        final groupHabits = provider.habits
                            .where((habit) => habit.groupId == group.id)
                            .toList();

                        if (groupHabits.isEmpty && !_isEditMode) {
                          return SizedBox(
                            key: ValueKey('group_${group.id}_empty'),
                            child: const SizedBox.shrink(),
                          );
                        }

                        final isExpanded = _expandedGroups[group.id] ?? true;

                        return Container(
                          key: ValueKey('group_${group.id}'),
                          margin: const EdgeInsets.symmetric(
                            horizontal: 20,
                            vertical: 8,
                          ),
                          decoration: BoxDecoration(
                            color: const Color(0xFF24242A),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Column(
                            children: [
                              InkWell(
                                borderRadius: BorderRadius.circular(20),
                                onTap: () => setState(() {
                                  _expandedGroups[group.id] = !isExpanded;
                                }),
                                child: Padding(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 20,
                                    vertical: 12,
                                  ),
                                  child: Row(
                                    children: [
                                      Icon(
                                        isExpanded
                                            ? Icons.keyboard_arrow_up
                                            : Icons.keyboard_arrow_down,
                                        color: Colors.white70,
                                      ),
                                      const SizedBox(width: 8),
                                      Expanded(
                                        child: Text(
                                          group.name,
                                          style: GoogleFonts.quicksand(
                                            fontSize: 22,
                                            fontWeight: FontWeight.bold,
                                            color: Colors.blueAccent,
                                          ),
                                        ),
                                      ),
                                      if (_isEditMode) ...[
                                        ReorderableDragStartListener(
                                          index: groupIndex,
                                          child: const Padding(
                                            padding: EdgeInsets.all(8),
                                            child: Icon(
                                              Icons.drag_indicator,
                                              color: Colors.white70,
                                            ),
                                          ),
                                        ),
                                        IconButton(
                                          tooltip: strings.editGroup,
                                          onPressed: () => _showEditGroupDialog(
                                            context,
                                            group,
                                          ),
                                          icon: const Icon(
                                            Icons.edit_outlined,
                                            color: Colors.white70,
                                          ),
                                        ),
                                        IconButton(
                                          tooltip: strings.deleteGroup,
                                          onPressed: () => _confirmDeleteGroup(
                                            context,
                                            group,
                                          ),
                                          icon: const Icon(
                                            Icons.delete_outline,
                                            color: Colors.redAccent,
                                          ),
                                        ),
                                      ],
                                    ],
                                  ),
                                ),
                              ),
                              AnimatedSize(
                                duration: const Duration(milliseconds: 280),
                                curve: Curves.easeInOutCubic,
                                alignment: Alignment.topCenter,
                                child: isExpanded
                                    ? Padding(
                                        padding: const EdgeInsets.only(
                                          bottom: 8,
                                        ),
                                        child: buildHabitList(
                                          groupHabits,
                                          (oldIndex, newIndex) =>
                                              provider.reorderHabitsInGroup(
                                                group.id,
                                                oldIndex,
                                                newIndex,
                                              ),
                                        ),
                                      )
                                    : const SizedBox.shrink(),
                              ),
                            ],
                          ),
                        );
                      }).toList(),
                    ),
                  ],
                ),

          Align(
            alignment: Alignment.topCenter,
            child: ConfettiWidget(
              confettiController: _confettiController,
              blastDirection: pi / 2,
              maxBlastForce: 5,
              minBlastForce: 2,
              emissionFrequency: 0.05,
              numberOfParticles: 50,
              gravity: 0.2,
            ),
          ),
        ],
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
      floatingActionButton: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24.0),
        child: Row(
          mainAxisAlignment: _isEditMode
              ? MainAxisAlignment.spaceBetween
              : MainAxisAlignment.end,
          children: [
            if (_isEditMode) ...[
              FloatingActionButton.extended(
                heroTag: 'editBtn',
                backgroundColor: Colors.greenAccent,
                foregroundColor: Colors.black,
                elevation: 4,
                onPressed: () => setState(() => _isEditMode = false),
                icon: const Icon(Icons.check_circle_outline),
                label: Text(
                  strings.saveChanges,
                  style: GoogleFonts.quicksand(fontWeight: FontWeight.bold),
                ),
              ),
              FloatingActionButton.extended(
                heroTag: 'groupBtn',
                backgroundColor: Colors.blueAccent,
                foregroundColor: Colors.white,
                elevation: 4,
                onPressed: _isCreatingGroup
                    ? null
                    : () => _showCreateGroupDialog(context, provider),
                icon: const Icon(Icons.folder_open),
                label: Text(
                  strings.newGroup,
                  style: GoogleFonts.quicksand(fontWeight: FontWeight.bold),
                ),
              ),
            ] else ...[
              FloatingActionButton(
                heroTag: 'editBtn',
                backgroundColor: const Color(0xFF2C2C2C),
                foregroundColor: Colors.white,
                elevation: 4,
                onPressed: () => setState(() => _isEditMode = true),
                child: const Icon(Icons.edit_rounded),
              ),
              const SizedBox(width: 16),
              FloatingActionButton(
                heroTag: 'addBtn',
                backgroundColor: Colors.white,
                foregroundColor: Colors.black,
                elevation: 4,
                onPressed: () => _showAddOrEditDialog(context),
                child: const Icon(Icons.add_rounded, size: 32),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Future<void> _showCreateGroupDialog(
    BuildContext context,
    HabitProvider provider,
  ) async {
    final strings = stringsOf(context);
    if (_isCreatingGroup) return;
    final controller = TextEditingController();
    final selectedHabitIds = <String>[];
    var showNameError = false;
    var controllerDisposed = false;

    try {
      final result = await showDialog<List<Object>>(
        context: context,
        builder: (dialogContext) => StatefulBuilder(
          builder: (dialogContext, setStateDialog) {
            final mediaQuery = MediaQuery.of(dialogContext);
            final availableHeight =
                mediaQuery.size.height - mediaQuery.viewInsets.bottom - 220;
            final dialogHeight = availableHeight.clamp(160.0, 360.0);
            final freeHabits = provider.habits
                .where((habit) => habit.groupId.isEmpty)
                .toList();
            final occupiedHabits = provider.habits
                .where((habit) => habit.groupId.isNotEmpty)
                .toList();

            Widget buildHabitOption(Habit habit) {
              final isSelected = selectedHabitIds.contains(habit.id);
              String currentGroupName = '';
              for (final group in provider.groups) {
                if (group.id == habit.groupId) {
                  currentGroupName = group.name;
                  break;
                }
              }

              return CheckboxListTile(
                activeColor: Colors.blueAccent,
                checkColor: Colors.white,
                title: Text(
                  habit.name,
                  style: GoogleFonts.quicksand(color: Colors.white),
                ),
                subtitle: currentGroupName.isEmpty
                    ? null
                    : Text(
                        '${strings.currentGroup} $currentGroupName',
                        style: const TextStyle(
                          color: Colors.orangeAccent,
                          fontSize: 12,
                        ),
                      ),
                value: isSelected,
                onChanged: (value) async {
                  if (value == true && habit.groupId.isNotEmpty) {
                    final confirm = await showDialog<bool>(
                      context: dialogContext,
                      builder: (confirmContext) => AlertDialog(
                        backgroundColor: Colors.grey[900],
                        title: Text(
                          strings.moveHabit,
                          style: TextStyle(color: Colors.white),
                        ),
                        content: Text(
                          strings.moveConfirmation(currentGroupName),
                          style: const TextStyle(color: Colors.white70),
                        ),
                        actions: [
                          TextButton(
                            onPressed: () =>
                                Navigator.pop(confirmContext, false),
                            child: Text(strings.cancel),
                          ),
                          TextButton(
                            onPressed: () =>
                                Navigator.pop(confirmContext, true),
                            child: Text(strings.move),
                          ),
                        ],
                      ),
                    );
                    if (confirm != true) return;
                  }

                  setStateDialog(() {
                    if (value == true) {
                      selectedHabitIds.add(habit.id);
                    } else {
                      selectedHabitIds.remove(habit.id);
                    }
                  });
                },
              );
            }

            return AlertDialog(
              backgroundColor: const Color(0xFF2C2C2C),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(24),
              ),
              title: Text(
                strings.createGroup,
                style: GoogleFonts.quicksand(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
              content: SizedBox(
                width: double.maxFinite,
                height: dialogHeight,
                child: Column(
                  children: [
                    TextField(
                      controller: controller,
                      style: GoogleFonts.quicksand(color: Colors.white),
                      decoration: InputDecoration(
                        hintText: strings.groupNameHint,
                        errorText: showNameError ? strings.emptyName : null,
                        hintStyle: GoogleFonts.quicksand(color: Colors.white38),
                        filled: true,
                        fillColor: Colors.black26,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(16),
                          borderSide: BorderSide.none,
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      strings.selectHabits,
                      style: GoogleFonts.quicksand(color: Colors.white70),
                    ),
                    const SizedBox(height: 8),
                    Expanded(
                      child: ListView(
                        children: [
                          if (freeHabits.isEmpty)
                            ListTile(
                              title: Text(
                                strings.noFreeHabits,
                                style: TextStyle(color: Colors.white54),
                              ),
                            ),
                          ...freeHabits.map(buildHabitOption),
                          if (occupiedHabits.isNotEmpty)
                            ExpansionTile(
                              collapsedIconColor: Colors.white70,
                              iconColor: Colors.white,
                              title: Text(
                                strings.habitsInOtherGroups(
                                  occupiedHabits.length,
                                ),
                                style: GoogleFonts.quicksand(
                                  color: Colors.white70,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              children: occupiedHabits
                                  .map(buildHabitOption)
                                  .toList(),
                            ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(dialogContext),
                  child: Text(
                    strings.cancel,
                    style: GoogleFonts.quicksand(color: Colors.white54),
                  ),
                ),
                ElevatedButton(
                  onPressed: () {
                    final name = controller.text.trim();
                    if (name.isEmpty) {
                      setStateDialog(() => showNameError = true);
                      return;
                    }
                    FocusScope.of(dialogContext).unfocus();
                    Navigator.pop(dialogContext, <Object>[
                      name,
                      List<String>.from(selectedHabitIds),
                    ]);
                  },
                  child: Text(strings.save),
                ),
              ],
            );
          },
        ),
      );
      if (result == null) return;
      setState(() => _isCreatingGroup = true);
      await Future<void>.delayed(Duration.zero);
      await provider.createGroup(
        result[0] as String,
        result[1] as List<String>,
      );
      await Future<void>.delayed(const Duration(milliseconds: 300));
      controller.dispose();
      controllerDisposed = true;
    } finally {
      if (!controllerDisposed) {
        await Future<void>.delayed(const Duration(milliseconds: 300));
        controller.dispose();
      }
      if (mounted) setState(() => _isCreatingGroup = false);
    }
  }

  Future<void> _showEditGroupDialog(
    BuildContext context,
    HabitGroup group,
  ) async {
    final strings = stringsOf(context);
    final provider = context.read<HabitProvider>();
    final controller = TextEditingController(text: group.name);
    final selectedHabitIds = provider.habits
        .where((habit) => habit.groupId == group.id)
        .map((habit) => habit.id)
        .toSet();
    var showNameError = false;

    try {
      await showDialog<void>(
        context: context,
        builder: (dialogContext) => StatefulBuilder(
          builder: (dialogContext, setDialogState) {
            final freeHabits = provider.habits
                .where(
                  (habit) => habit.groupId.isEmpty || habit.groupId == group.id,
                )
                .toList();
            final occupiedHabits = provider.habits
                .where(
                  (habit) =>
                      habit.groupId.isNotEmpty && habit.groupId != group.id,
                )
                .toList();

            Widget habitOption(Habit habit) {
              final selected = selectedHabitIds.contains(habit.id);
              return CheckboxListTile(
                activeColor: Colors.blueAccent,
                checkColor: Colors.white,
                title: Text(
                  habit.name,
                  style: GoogleFonts.quicksand(color: Colors.white),
                ),
                value: selected,
                onChanged: (value) async {
                  if (value == true && habit.groupId.isNotEmpty) {
                    final move = await showDialog<bool>(
                      context: dialogContext,
                      builder: (confirmContext) => AlertDialog(
                        backgroundColor: Colors.grey[900],
                        title: Text(
                          strings.moveHabit,
                          style: TextStyle(color: Colors.white),
                        ),
                        content: Text(
                          strings.moveConfirmation(group.name),
                          style: TextStyle(color: Colors.white70),
                        ),
                        actions: [
                          TextButton(
                            onPressed: () =>
                                Navigator.pop(confirmContext, false),
                            child: Text(strings.cancel),
                          ),
                          TextButton(
                            onPressed: () =>
                                Navigator.pop(confirmContext, true),
                            child: Text(strings.move),
                          ),
                        ],
                      ),
                    );
                    if (move != true) return;
                  }
                  setDialogState(() {
                    if (value == true) {
                      selectedHabitIds.add(habit.id);
                    } else {
                      selectedHabitIds.remove(habit.id);
                    }
                  });
                },
              );
            }

            final availableHeight =
                MediaQuery.of(dialogContext).size.height -
                MediaQuery.of(dialogContext).viewInsets.bottom -
                220;
            final dialogHeight = availableHeight.clamp(160.0, 360.0);

            return AlertDialog(
              backgroundColor: const Color(0xFF2C2C2C),
              title: Text(
                strings.editGroup,
                style: GoogleFonts.quicksand(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
              content: SizedBox(
                width: double.maxFinite,
                height: dialogHeight,
                child: Column(
                  children: [
                    TextField(
                      controller: controller,
                      style: const TextStyle(color: Colors.white),
                      decoration: InputDecoration(
                        hintText: strings.groupName,
                        errorText: showNameError ? strings.emptyName : null,
                        hintStyle: const TextStyle(color: Colors.white38),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Expanded(
                      child: ListView(
                        children: [
                          ...freeHabits.map(habitOption),
                          if (occupiedHabits.isNotEmpty)
                            ExpansionTile(
                              title: Text(
                                strings.habitsInOtherGroups(
                                  occupiedHabits.length,
                                ),
                                style: const TextStyle(color: Colors.white70),
                              ),
                              children: occupiedHabits
                                  .map(habitOption)
                                  .toList(),
                            ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(dialogContext),
                  child: Text(strings.cancel),
                ),
                FilledButton(
                  onPressed: () async {
                    final name = controller.text.trim();
                    if (name.isEmpty) {
                      setDialogState(() => showNameError = true);
                      return;
                    }
                    FocusScope.of(dialogContext).unfocus();
                    Navigator.pop(dialogContext);
                    await provider.updateGroupContents(
                      group.id,
                      name,
                      selectedHabitIds.toList(),
                    );
                  },
                  child: Text(strings.save),
                ),
              ],
            );
          },
        ),
      );
    } finally {
      await Future<void>.delayed(const Duration(milliseconds: 300));
      controller.dispose();
    }
  }

  Future<bool> _confirmDeletion(
    BuildContext context, {
    required String title,
    required String message,
  }) async {
    final strings = stringsOf(context);
    return await showDialog<bool>(
          context: context,
          builder: (dialogContext) => AlertDialog(
            backgroundColor: const Color(0xFF2C2C2C),
            title: Text(title, style: const TextStyle(color: Colors.white)),
            content: Text(
              message,
              style: const TextStyle(color: Colors.white70),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(dialogContext, false),
                child: Text(strings.cancel),
              ),
              FilledButton(
                style: FilledButton.styleFrom(
                  backgroundColor: Colors.redAccent,
                ),
                onPressed: () => Navigator.pop(dialogContext, true),
                child: Text(strings.delete),
              ),
            ],
          ),
        ) ??
        false;
  }

  Future<void> _confirmDeleteHabit(BuildContext context, dynamic habit) async {
    final strings = stringsOf(context);
    final habitProvider = context.read<HabitProvider>();
    final confirmed = await _confirmDeletion(
      context,
      title: strings.deleteHabit,
      message: strings.deleteConfirmationHabit(habit.name),
    );
    if (confirmed && mounted) {
      await habitProvider.deleteHabit(habit.id);
    }
  }

  Future<void> _confirmDeleteGroup(
    BuildContext context,
    HabitGroup group,
  ) async {
    final strings = stringsOf(context);
    final habitProvider = context.read<HabitProvider>();
    final confirmed = await _confirmDeletion(
      context,
      title: strings.deleteGroup,
      message: strings.deleteConfirmationGroup(group.name),
    );
    if (confirmed && mounted) {
      await habitProvider.deleteGroup(group.id);
    }
  }

  void _showColorPicker(BuildContext context, var habit) {
    final strings = stringsOf(context);
    // (Mantén el mismo código de _showColorPicker del paso anterior)
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF2C2C2C),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(
          strings.chooseColor,
          style: GoogleFonts.quicksand(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
        content: Wrap(
          spacing: 16,
          runSpacing: 16,
          alignment: WrapAlignment.center,
          children: _cardColors.map((color) {
            return GestureDetector(
              onTap: () {
                context.read<HabitProvider>().updateHabitColor(
                  habit.id,
                  color.toARGB32(),
                );
                Navigator.pop(context);
              },
              child: Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: color,
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: habit.colorValue == color.toARGB32()
                        ? Colors.white
                        : Colors.transparent,
                    width: 3,
                  ),
                ),
              ),
            );
          }).toList(),
        ),
      ),
    );
  }

  void _showAddOrEditDialog(BuildContext context, {var habit}) {
    final strings = stringsOf(context);
    final controller = TextEditingController(text: habit?.name ?? '');
    final isEditing = habit != null;
    int selectedIconCode = habit?.iconCode ?? Icons.star_rounded.codePoint;
    String selectedGroupId = habit?.groupId ?? '';

    showDialog(
      context: context,
      builder: (context) {
        // Usamos StatefulBuilder para poder actualizar la selección de iconos dentro del diálogo sin cerrar
        return StatefulBuilder(
          builder: (context, setStateDialog) {
            final dialogHeight = MediaQuery.sizeOf(context).height * 0.58;
            return AlertDialog(
              backgroundColor: const Color(0xFF2C2C2C),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(24),
              ),
              title: Text(
                isEditing ? strings.editHabit : strings.newHabit,
                style: GoogleFonts.quicksand(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
              content: SizedBox(
                width: double.maxFinite,
                height: dialogHeight,
                child: ListView(
                  keyboardDismissBehavior:
                      ScrollViewKeyboardDismissBehavior.onDrag,
                  children: [
                    TextField(
                      controller: controller,
                      style: GoogleFonts.quicksand(
                        color: Colors.white,
                        fontSize: 18,
                      ),
                      decoration: InputDecoration(
                        hintText: strings.habitNameHint,
                        hintStyle: GoogleFonts.quicksand(color: Colors.white38),
                        filled: true,
                        fillColor: Colors.black26,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(16),
                          borderSide: BorderSide.none,
                        ),
                      ),
                      autofocus: true,
                    ),
                    const SizedBox(height: 24),
                    Text(
                      strings.chooseIcon,
                      style: GoogleFonts.quicksand(color: Colors.white70),
                    ),
                    const SizedBox(height: 12),
                    GridView.count(
                      crossAxisCount: 4,
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      crossAxisSpacing: 10,
                      mainAxisSpacing: 10,
                      childAspectRatio: 1,
                      children: _availableIcons.map((iconData) {
                        final isSelected =
                            selectedIconCode == iconData.codePoint;
                        return GestureDetector(
                          onTap: () => setStateDialog(
                            () => selectedIconCode = iconData.codePoint,
                          ),
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 200),
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: isSelected
                                  ? Colors.blueAccent
                                  : Colors.black26,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Icon(
                              iconData,
                              color: isSelected ? Colors.white : Colors.white54,
                              size: 28,
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                    if (isEditing &&
                        context.read<HabitProvider>().groups.isNotEmpty) ...[
                      const SizedBox(height: 24),
                      Text(
                        strings.groupName,
                        style: GoogleFonts.quicksand(color: Colors.white70),
                      ),
                      const SizedBox(height: 8),
                      DropdownButtonFormField<String>(
                        initialValue: selectedGroupId,
                        dropdownColor: const Color(0xFF3A3A3A),
                        style: GoogleFonts.quicksand(color: Colors.white),
                        decoration: InputDecoration(
                          filled: true,
                          fillColor: Colors.black26,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(16),
                            borderSide: BorderSide.none,
                          ),
                        ),
                        items: [
                          DropdownMenuItem<String>(
                            value: '',
                            child: Text(strings.noGroup),
                          ),
                          ...context.read<HabitProvider>().groups.map(
                            (group) => DropdownMenuItem<String>(
                              value: group.id,
                              child: Text(group.name),
                            ),
                          ),
                        ],
                        onChanged: (value) {
                          if (value != null) {
                            setStateDialog(() => selectedGroupId = value);
                          }
                        },
                      ),
                    ],
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: Text(
                    strings.cancel,
                    style: GoogleFonts.quicksand(
                      color: Colors.white54,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.white,
                    foregroundColor: Colors.black,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 12,
                    ),
                  ),
                  onPressed: () async {
                    final habitProvider = context.read<HabitProvider>();
                    final navigator = Navigator.of(context);
                    if (controller.text.isNotEmpty) {
                      if (isEditing) {
                        await habitProvider.editHabit(
                          habit.id,
                          controller.text,
                          selectedIconCode,
                        );
                        if (selectedGroupId != habit.groupId) {
                          await habitProvider.updateHabitGroup(
                            habit.id,
                            selectedGroupId,
                          );
                        }
                      } else {
                        final randomColor =
                            _cardColors[Random().nextInt(_cardColors.length)]
                                .toARGB32();
                        await habitProvider.addHabit(
                          controller.text,
                          selectedIconCode,
                          colorValue: randomColor,
                        );
                      }
                      navigator.pop();
                    }
                  },
                  child: Text(
                    strings.save,
                    style: GoogleFonts.quicksand(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                ),
              ],
            );
          },
        );
      },
    );
  }
}
