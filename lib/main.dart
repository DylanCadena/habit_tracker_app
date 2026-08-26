import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:confetti/confetti.dart';
import 'dart:math';
import 'providers/habit_provider.dart';
import 'package:google_fonts/google_fonts.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
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
      title: 'Mis Hábitos',
      // Tema oscuro general
      theme: ThemeData.dark().copyWith(
        scaffoldBackgroundColor: const Color(0xFF121212), // Un negro más suave
        textTheme: GoogleFonts.quicksandTextTheme(Theme.of(context).textTheme).apply(bodyColor: Colors.white),
      ),
      home: const SplashScreen(), // Iniciamos con el Splash
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
    // Espera 2 segundos y navega a la pantalla principal
    Future.delayed(const Duration(seconds: 2), () {
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
            Icon(Icons.track_changes, size: 80, color: Colors.blueAccent),
            const SizedBox(height: 20),
            const Text(
              'Mis Hábitos',
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

// --- HOME SCREEN Y DISEÑO DE TARJETAS ---
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  late ConfettiController _confettiController;
  bool _isEditMode = false;

  final List<Color> _cardColors = [
    const Color(0xFFBA55D3), const Color(0xFF4FC3F7),
    const Color(0xFF2196F3), const Color(0xFF4CAF50),
    const Color(0xFFF44336), const Color(0xFFFF9800),
  ];

  // Lista de iconos disponibles para elegir
  final List<IconData> _availableIcons = [
    Icons.star_rounded, Icons.fitness_center, Icons.medical_services,
    Icons.book, Icons.water_drop, Icons.directions_run,
    Icons.apple, Icons.self_improvement, Icons.cleaning_services,
    Icons.monitor_heart, Icons.bedtime, Icons.restaurant,
  ];

  @override
  void initState() {
    super.initState();
    _confettiController = ConfettiController(duration: const Duration(seconds: 2));
  }

  @override
  void dispose() {
    _confettiController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<HabitProvider>();

    Widget buildHabitCard(dynamic habit, int index) {
      final cardColor = Color(habit.colorValue);
      final habitIcon = IconData(habit.iconCode, fontFamily: 'MaterialIcons');

      return Container(
        key: ValueKey('${habit.id}_${habit.name}_${habit.iconCode}_${habit.colorValue}'),
        margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
        decoration: BoxDecoration(
          color: cardColor.withOpacity(0.95), // Color ligeramente translúcido
          borderRadius: BorderRadius.circular(28), // Bordes más suaves
          boxShadow: [
            BoxShadow(
              color: cardColor.withOpacity(0.3),
              blurRadius: 12,
              offset: const Offset(0, 6),
            ),
          ],
          border: _isEditMode ? Border.all(color: Colors.white, width: 2) : null,
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 22),
          child: Row(
            children: [
              if (_isEditMode)
                ReorderableDragStartListener(
                  index: index,
                  child: const Padding(
                    padding: EdgeInsets.only(right: 12.0),
                    child: Icon(Icons.drag_indicator, color: Colors.white70, size: 28),
                  ),
                ),
                
              // Icono Dinámico del hábito
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  shape: BoxShape.circle,
                ),
                child: Icon(habitIcon, color: Colors.white, size: 28),
              ),
              const SizedBox(width: 16),

              Expanded(
                child: GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTap: _isEditMode ? () => _showAddOrEditDialog(context, habit: habit) : null,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        habit.name,
                        style: GoogleFonts.quicksand(
                          color: Colors.white,
                          fontSize: 20,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        _isEditMode 
                            ? 'Toca para editar' 
                            : (habit.isCompleted ? 'Completado' : 'Cada día'),
                        style: GoogleFonts.quicksand(
                          color: Colors.white.withOpacity(0.7),
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              if (_isEditMode)
                IconButton(
                  icon: const Icon(Icons.palette, color: Colors.white, size: 28),
                  onPressed: () => _showColorPicker(context, habit),
                )
              else
                GestureDetector(
                  onTap: habit.isCompleted ? null : () async {
                    final prov = context.read<HabitProvider>();
                    await prov.toggleHabit(habit.id);
                    if (prov.allCompleted) _confettiController.play();
                  },
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 300),
                    width: 52,
                    height: 52,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: habit.isCompleted ? Colors.white : Colors.black.withOpacity(0.2),
                      boxShadow: habit.isCompleted ? [
                        BoxShadow(color: Colors.white.withOpacity(0.5), blurRadius: 8)
                      ] : [],
                    ),
                    child: Icon(
                      habit.isCompleted ? Icons.check : Icons.add,
                      color: habit.isCompleted ? cardColor : Colors.white,
                      size: 28,
                    ),
                  ),
                ),
            ],
          ),
        ),
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
                  'Racha actual: ',
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
                    'No hay hábitos.\n¡Crea uno nuevo!', 
                    textAlign: TextAlign.center,
                    style: GoogleFonts.quicksand(color: Colors.white54, fontSize: 18),
                  ),
                )
              : (_isEditMode 
                  ? ReorderableListView.builder(
                      buildDefaultDragHandles: false,
                      padding: const EdgeInsets.only(bottom: 120, top: 10),
                      itemCount: provider.habits.length,
                      onReorder: (oldIndex, newIndex) {
                        context.read<HabitProvider>().reorderHabits(oldIndex, newIndex);
                      },
                      itemBuilder: (context, index) => buildHabitCard(provider.habits[index], index),
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.only(bottom: 120, top: 10),
                      itemCount: provider.habits.length,
                      itemBuilder: (context, index) => buildHabitCard(provider.habits[index], index),
                    )),
          
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
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            // BOTÓN DE MODO EDICIÓN / GUARDAR CAMBIOS
            _isEditMode
                ? FloatingActionButton.extended(
                    heroTag: 'editBtn',
                    backgroundColor: Colors.greenAccent,
                    foregroundColor: Colors.black,
                    elevation: 4,
                    onPressed: () {
                      setState(() {
                        _isEditMode = false;
                      });
                    },
                    icon: const Icon(Icons.check_circle_outline),
                    label: Text(
                      'Guardar cambios',
                      style: GoogleFonts.quicksand(fontWeight: FontWeight.bold),
                    ),
                  )
                : FloatingActionButton(
                    heroTag: 'editBtn',
                    backgroundColor: const Color(0xFF2C2C2C),
                    foregroundColor: Colors.white,
                    elevation: 4,
                    onPressed: () {
                      setState(() {
                        _isEditMode = true;
                      });
                    },
                    child: const Icon(Icons.edit_rounded),
                  ),
            
            // BOTÓN DE AÑADIR (Solo aparece si NO estás en modo edición)
            if (!_isEditMode)
              FloatingActionButton(
                heroTag: 'addBtn',
                backgroundColor: Colors.white,
                foregroundColor: Colors.black,
                elevation: 4,
                onPressed: () => _showAddOrEditDialog(context),
                child: const Icon(Icons.add_rounded, size: 32),
              ),
          ],
        ),
      ),
    );
  }

  // --- LOS MÉTODOS _showColorPicker y _showAddOrEditDialog VAN AQUÍ ABAJO ---
  
  void _showColorPicker(BuildContext context, var habit) {
    // (Mantén el mismo código de _showColorPicker del paso anterior)
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF2C2C2C),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text('Elegir Color', style: GoogleFonts.quicksand(color: Colors.white, fontWeight: FontWeight.bold)),
        content: Wrap(
          spacing: 16,
          runSpacing: 16,
          alignment: WrapAlignment.center,
          children: _cardColors.map((color) {
            return GestureDetector(
              onTap: () {
                context.read<HabitProvider>().updateHabitColor(habit.id, color.value);
                Navigator.pop(context); 
              },
              child: Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: color,
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: habit.colorValue == color.value ? Colors.white : Colors.transparent,
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
    final controller = TextEditingController(text: habit?.name ?? '');
    final isEditing = habit != null;
    int selectedIconCode = habit?.iconCode ?? Icons.star_rounded.codePoint;

    showDialog(
      context: context,
      builder: (context) {
        // Usamos StatefulBuilder para poder actualizar la selección de iconos dentro del diálogo sin cerrar
        return StatefulBuilder(
          builder: (context, setStateDialog) {
            return AlertDialog(
              backgroundColor: const Color(0xFF2C2C2C),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
              title: Text(
                isEditing ? 'Editar Hábito' : 'Nuevo Hábito', 
                style: GoogleFonts.quicksand(color: Colors.white, fontWeight: FontWeight.bold)
              ),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    TextField(
                      controller: controller,
                      style: GoogleFonts.quicksand(color: Colors.white, fontSize: 18),
                      decoration: InputDecoration(
                        hintText: 'Ej. Beber agua',
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
                    Text('Elige un icono:', style: GoogleFonts.quicksand(color: Colors.white70)),
                    const SizedBox(height: 12),
                    Wrap(
                      spacing: 12,
                      runSpacing: 12,
                      children: _availableIcons.map((iconData) {
                        final isSelected = selectedIconCode == iconData.codePoint;
                        return GestureDetector(
                          onTap: () {
                            setStateDialog(() {
                              selectedIconCode = iconData.codePoint;
                            });
                          },
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 200),
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: isSelected ? Colors.blueAccent : Colors.black26,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Icon(iconData, color: isSelected ? Colors.white : Colors.white54, size: 28),
                          ),
                        );
                      }).toList(),
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: Text('Cancelar', style: GoogleFonts.quicksand(color: Colors.white54, fontWeight: FontWeight.bold)),
                ),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.white,
                    foregroundColor: Colors.black,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                  ),
                  onPressed: () {
                    if (controller.text.isNotEmpty) {
                      if (isEditing) {
                        context.read<HabitProvider>().editHabit(habit.id, controller.text, selectedIconCode);
                      } else {
                        context.read<HabitProvider>().addHabit(controller.text, selectedIconCode);
                      }
                      Navigator.pop(context);
                    }
                  },
                  child: Text('Guardar', style: GoogleFonts.quicksand(fontWeight: FontWeight.bold, fontSize: 16)),
                ),
              ],
            );
          }
        );
      },
    );
  }
}