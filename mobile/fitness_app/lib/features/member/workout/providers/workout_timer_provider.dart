import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class WorkoutTimerState {
  final int elapsedSeconds;
  final bool isRunning;
  final DateTime? startedAt;

  const WorkoutTimerState({
    this.elapsedSeconds = 0,
    this.isRunning = false,
    this.startedAt,
  });

  String get formatted {
    final h = elapsedSeconds ~/ 3600;
    final m = (elapsedSeconds % 3600) ~/ 60;
    final s = elapsedSeconds % 60;
    return '${h.toString().padLeft(2, '0')}:${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';
  }
}

class WorkoutTimerNotifier extends StateNotifier<WorkoutTimerState> {
  Timer? _timer;

  WorkoutTimerNotifier() : super(const WorkoutTimerState());

  void start() {
    if (state.isRunning) return;
    _timer?.cancel();
    final started = DateTime.now();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      final elapsed = DateTime.now().difference(started).inSeconds;
      state = WorkoutTimerState(
        elapsedSeconds: elapsed,
        isRunning: true,
        startedAt: started,
      );
    });
  }

  void stop() {
    _timer?.cancel();
    state = WorkoutTimerState(elapsedSeconds: state.elapsedSeconds, isRunning: false);
  }

  void reset() {
    _timer?.cancel();
    state = const WorkoutTimerState();
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }
}

final workoutTimerProvider =
    StateNotifierProvider.autoDispose<WorkoutTimerNotifier, WorkoutTimerState>(
  (_) => WorkoutTimerNotifier(),
);
