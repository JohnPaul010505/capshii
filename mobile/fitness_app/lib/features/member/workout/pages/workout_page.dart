import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared/services/supabase_client.dart';
import '../../../../app/theme.dart';
import '../providers/workout_timer_provider.dart';
import '../../../shared/widgets/pressable.dart';
import '../../../shared/widgets/animations.dart';

final exercisesProvider = FutureProvider.autoDispose<List<Map<String, dynamic>>>((ref) async {
  final userId = SupabaseClientService().client.auth.currentUser!.id;
  final today = DateTime.now().toIso8601String().split('T')[0];
  final response = await SupabaseClientService()
      .client
      .from('workout_logs')
      .select()
      .eq('member_id', userId)
      .gte('logged_at', '${today}T00:00:00')
      .lt('logged_at', '${today}T23:59:59')
      .order('logged_at', ascending: false);
  return (response as List).cast<Map<String, dynamic>>();
});

class WorkoutPage extends ConsumerStatefulWidget {
  const WorkoutPage({super.key});

  @override
  ConsumerState<WorkoutPage> createState() => _WorkoutPageState();
}

class _WorkoutPageState extends ConsumerState<WorkoutPage> {
  final _exerciseController = TextEditingController();
  final _setsController = TextEditingController();
  final _repsController = TextEditingController();
  final _weightController = TextEditingController();
  bool _showAddForm = false;
  bool _saving = false;

  Future<void> _addExercise(String name, int sets, int reps, double? weight) async {
    setState(() => _saving = true);
    try {
      final userId = SupabaseClientService().client.auth.currentUser!.id;
      await SupabaseClientService().client.from('workout_logs').insert({
        'member_id': userId,
        'exercise_name': name,
        'sets': sets,
        'reps': reps,
        'weight_kg': weight,
        'logged_at': DateTime.now().toUtc().toIso8601String(),
      });
      _exerciseController.clear();
      _setsController.clear();
      _repsController.clear();
      _weightController.clear();
      setState(() => _showAddForm = false);
      ref.invalidate(exercisesProvider);
    } catch (e) {
      if (mounted) {
        showCupertinoDialog(
          context: context,
          builder: (_) => CupertinoAlertDialog(
            title: const Text('Error'),
            content: Text(e.toString()),
            actions: [CupertinoDialogAction(child: const Text('OK'), onPressed: () => Navigator.pop(context))],
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  void dispose() {
    _exerciseController.dispose();
    _setsController.dispose();
    _repsController.dispose();
    _weightController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final timerState = ref.watch(workoutTimerProvider);
    final exercisesAsync = ref.watch(exercisesProvider);
    final isRunning = timerState.isRunning;

    return Scaffold(
      backgroundColor: const Color(0xFF000000),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.symmetric(horizontal: 14),
          physics: const ClampingScrollPhysics(),
          children: [
            const SizedBox(height: 14),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('WORKOUT LOG', style: TextStyle(
                  fontSize: 21, fontWeight: FontWeight.w800, color: Color(0xFFFFFFFF),
                )),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: isRunning ? const Color(0xFF30D158).withAlpha(25) : const Color(0xFF636366).withAlpha(25),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: isRunning ? const Color(0xFF30D158).withAlpha(40) : const Color(0xFF636366).withAlpha(40),
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 6, height: 6,
                        decoration: BoxDecoration(
                          color: isRunning ? const Color(0xFF30D158) : const Color(0xFF636366),
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 5),
                      Text(
                        isRunning ? 'Live' : 'Ready',
                        style: TextStyle(
                          fontSize: 10, fontWeight: FontWeight.w600,
                          color: isRunning ? const Color(0xFF30D158) : const Color(0xFF636366),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Stack(
              alignment: Alignment.center,
              children: [
                AnimatedContainer(
                  duration: const Duration(milliseconds: 400),
                  curve: Curves.easeInOut,
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 28),
                  decoration: BoxDecoration(
                    color: const Color(0xFF1C1C1E),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: const Color(0xFF38383A).withAlpha(100)),
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          AnimatedPulseDot(color: isRunning ? const Color(0xFF64D2FF) : const Color(0xFF8E8E93), size: 6),
                          const SizedBox(width: 6),
                          Text(
                            isRunning ? 'SESSION ACTIVE' : 'SESSION DURATION',
                            style: TextStyle(
                              fontSize: 10,
                              color: isRunning ? const Color(0xFF64D2FF) : const Color(0xFF8E8E93),
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      AnimatedDefaultTextStyle(
                        duration: const Duration(milliseconds: 300),
                        style: TextStyle(
                          fontSize: 44, fontWeight: FontWeight.w700,
                          fontFamily: 'monospace',
                          color: isRunning ? const Color(0xFF64D2FF) : const Color(0xFFFFFFFF),
                        ),
                        child: Text(timerState.formatted),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        isRunning ? 'Tap Finish when done' : 'Tap Start to begin',
                        style: TextStyle(fontSize: 10, color: isRunning ? const Color(0xFF64D2FF).withAlpha(150) : const Color(0xFF8E8E93)),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            ElevatedButton.icon(
              onPressed: () {
                final notifier = ref.read(workoutTimerProvider.notifier);
                if (isRunning) {
                  notifier.stop();
                } else {
                  notifier.reset();
                  notifier.start();
                }
              },
              icon: Icon(isRunning ? CupertinoIcons.stop : CupertinoIcons.play_arrow, size: 18),
              label: Text(isRunning ? 'Finish Session' : 'Start Session'),
              style: ElevatedButton.styleFrom(
                backgroundColor: isRunning ? const Color(0xFFFF453A) : const Color(0xFF0A84FF),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              ),
            ),
            const SizedBox(height: 16),
            Text('EXERCISES', style: Theme.of(context).textTheme.labelLarge?.copyWith(color: const Color(0xFF8E8E93), letterSpacing: 0)),
            const SizedBox(height: 8),
            exercisesAsync.when(
              data: (exercises) => Column(
                children: [
                  ...exercises.asMap().entries.map((entry) => StaggeredFadeIn(
                    index: entry.key,
                    child: _ExerciseCard(
                      name: entry.value['exercise_name'] as String? ?? 'Exercise',
                      reps: entry.value['reps'] as int?,
                      sets: entry.value['sets'] as int?,
                      weight: entry.value['weight_kg'] as double?,
                    ),
                  )),
                  if (exercises.isEmpty)
                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: 20),
                      child: Text('No exercises logged today', style: TextStyle(color: Color(0xFF636366), fontSize: 12)),
                    ),
                ],
              ),
              loading: () => const Center(child: Padding(
                padding: EdgeInsets.all(20),
                child: CircularProgressIndicator(color: Color(0xFFD6A5FF)),
              )),
              error: (e, _) => Padding(
                padding: const EdgeInsets.symmetric(vertical: 20),
                child: Text('Error: $e', style: const TextStyle(color: Color(0xFF636366), fontSize: 12)),
              ),
            ),
            if (_showAddForm) _buildAddForm(),
            PressableCard(
              onTap: () => setState(() => _showAddForm = !_showAddForm),
              padding: const EdgeInsets.symmetric(vertical: 12),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    _showAddForm ? CupertinoIcons.minus : CupertinoIcons.add,
                    color: const Color(0xFF636366), size: 14,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    _showAddForm ? 'Cancel' : 'Add Exercise',
                    style: const TextStyle(color: Color(0xFF636366), fontSize: 13),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  Widget _buildAddForm() {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 250),
      curve: Curves.easeInOut,
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFF1C1C1E),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFF38383A).withAlpha(100)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(CupertinoIcons.plus_circle, color: Color(0xFFD6A5FF), size: 14),
              const SizedBox(width: 5),
              const Text('New Exercise', style: TextStyle(
                fontSize: 13, fontWeight: FontWeight.w700, color: Color(0xFFFFFFFF),
              )),
            ],
          ),
          const SizedBox(height: 10),
          Semantics(
            label: 'Exercise name, required',
            child: TextField(
              controller: _exerciseController,
              decoration: const InputDecoration(
                labelText: 'Exercise name *',
                helperText: 'e.g. Bench Press',
                filled: true,
              ),
              style: const TextStyle(fontSize: 13, color: Color(0xFFFFFFFF)),
              textInputAction: TextInputAction.next,
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: Semantics(
                  label: 'Sets',
                  child: TextField(
                    controller: _setsController,
                    decoration: const InputDecoration(labelText: 'Sets', filled: true),
                    keyboardType: TextInputType.number,
                    style: const TextStyle(fontSize: 13, color: Color(0xFFFFFFFF)),
                    textInputAction: TextInputAction.next,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Semantics(
                  label: 'Reps',
                  child: TextField(
                    controller: _repsController,
                    decoration: const InputDecoration(labelText: 'Reps', filled: true),
                    keyboardType: TextInputType.number,
                    style: const TextStyle(fontSize: 13, color: Color(0xFFFFFFFF)),
                    textInputAction: TextInputAction.next,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Semantics(
                  label: 'Weight in kilograms',
                  child: TextField(
                    controller: _weightController,
                    decoration: const InputDecoration(labelText: 'Weight (kg)', filled: true),
                    keyboardType: TextInputType.number,
                    style: const TextStyle(fontSize: 13, color: Color(0xFFFFFFFF)),
                    textInputAction: TextInputAction.done,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          ElevatedButton(
            onPressed: _saving ? null : () {
              final name = _exerciseController.text.trim();
              if (name.isEmpty) {
                showCupertinoDialog(
                  context: context,
                  builder: (_) => CupertinoAlertDialog(
                    title: const Text('Error'),
                    content: const Text('Please enter an exercise name'),
                    actions: [CupertinoDialogAction(child: const Text('OK'), onPressed: () => Navigator.pop(context))],
                  ),
                );
                return;
              }
              final sets = int.tryParse(_setsController.text);
              final reps = int.tryParse(_repsController.text);
              final weight = double.tryParse(_weightController.text);
              _addExercise(name, sets ?? 3, reps ?? 10, weight);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF0A84FF),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
            ),
            child: _saving
                ? const CupertinoActivityIndicator(color: Colors.white, radius: 10)
                : const Text('Add Exercise'),
          ),
        ],
      ),
    );
  }
}

class _ExerciseCard extends StatelessWidget {
  final String name;
  final int? reps;
  final int? sets;
  final double? weight;

  const _ExerciseCard({required this.name, this.reps, this.sets, this.weight});

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: 'Exercise: $name${sets != null ? ', $sets sets' : ''}${reps != null ? ', $reps reps' : ''}${weight != null ? ', $weight kg' : ''}',
      child: PressableCard(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        margin: const EdgeInsets.only(bottom: 7),
        child: Row(
          children: [
            Container(
              width: 34, height: 34,
              decoration: BoxDecoration(
                color: const Color(0xFFBF5AF2).withAlpha(25),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(CupertinoIcons.person, color: Color(0xFFD6A5FF), size: 16),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(name, style: const TextStyle(
                    fontSize: 13, fontWeight: FontWeight.w600, color: Color(0xFFFFFFFF),
                  )),
                  if (reps != null || weight != null)
                    Text(
                      '${reps != null ? '${reps} reps' : ''}${reps != null && weight != null ? ' · ' : ''}${weight != null ? '$weight kg' : ''}',
                      style: const TextStyle(fontSize: 10, color: Color(0xFF8E8E93)),
                    ),
                ],
              ),
            ),
            if (sets != null) ...[
              Text('$sets', style: const TextStyle(
                fontSize: 20, fontWeight: FontWeight.w800, color: Color(0xFFD6A5FF),
              )),
              const SizedBox(width: 3),
              const Text('SETS', style: TextStyle(
                fontSize: 8, fontWeight: FontWeight.w600, color: Color(0xFF636366),
              )),
            ],
          ],
        ),
      ),
    );
  }
}
