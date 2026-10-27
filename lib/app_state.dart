import 'dart:async';
import 'package:flutter/material.dart';

class AppState extends ChangeNotifier {
  // ==========================================
  // NAVIGATION STATE
  // ==========================================
  int _currentIndex = 0;
  int get currentIndex => _currentIndex;

  void changeTab(int index) {
    _currentIndex = index;
    notifyListeners();
  }

  // ==========================================
  // CALCULATOR HISTORY STATE
  // ==========================================
  final List<String> _calculatorHistory = [];
  List<String> get calculatorHistory => _calculatorHistory;

  void addCalculationToHistory(String equation) {
    _calculatorHistory.insert(0, equation); // Adds newest to the top
    notifyListeners();
  }

  void clearCalculatorHistory() {
    _calculatorHistory.clear();
    notifyListeners();
  }

  // ==========================================
  // TIMER STATE & LOGIC
  // ==========================================
  int hours = 0;
  int minutes = 0;
  int seconds = 0;
  int totalSeconds = 0;
  int remainingSeconds = 0;
  Timer? _timer;
  bool isRunning = false;
  bool isSettingTime = true;
  int activeRow = 2;

  void setActiveRow(int row) {
    activeRow = row;
    notifyListeners();
  }

  void pressKey(String val) {
    if (isRunning) return;
    int parsedVal = int.tryParse(val) ?? 0;

    if (activeRow == 0) {
      if (hours < 10) hours = hours * 10 + parsedVal;
      if (hours > 23) hours = 23;
    } else if (activeRow == 1) {
      if (minutes < 10) minutes = minutes * 10 + parsedVal;
      if (minutes > 59) minutes = 59;
    } else {
      if (seconds < 10) seconds = seconds * 10 + parsedVal;
      if (seconds > 59) seconds = 59;
    }

    totalSeconds = (hours * 3600) + (minutes * 60) + seconds;
    remainingSeconds = totalSeconds;
    notifyListeners();
  }

  void backspace() {
    if (isRunning) return;
    if (activeRow == 0) {
      hours = hours ~/ 10;
    } else if (activeRow == 1) {
      minutes = minutes ~/ 10;
    } else {
      seconds = seconds ~/ 10;
    }
    totalSeconds = (hours * 3600) + (minutes * 60) + seconds;
    remainingSeconds = totalSeconds;
    notifyListeners();
  }

  void toggleTimer() {
    if (totalSeconds == 0 && isSettingTime) return;
    isSettingTime = false;

    if (isRunning) {
      _timer?.cancel();
    } else {
      _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
        if (remainingSeconds > 0) {
          remainingSeconds--;
          notifyListeners();
        } else {
          _timer?.cancel();
          isRunning = false;
          notifyListeners();
        }
      });
    }
    isRunning = !isRunning;
    notifyListeners();
  }

  void resetTimer() {
    _timer?.cancel();
    isRunning = false;
    isSettingTime = true;
    remainingSeconds = totalSeconds;
    notifyListeners();
  }

  String get formattedTime {
    final h = (remainingSeconds ~/ 3600).toString().padLeft(1, '0');
    final m = ((remainingSeconds % 3600) ~/ 60).toString().padLeft(2, '0');
    final s = (remainingSeconds % 60).toString().padLeft(2, '0');
    return '$h : $m : $s';
  }

  // ==========================================
  // STOPWATCH STATE & LOGIC
  // ==========================================
  final Stopwatch _stopwatch = Stopwatch();
  Timer? _ticker;

  bool get isStopwatchRunning => _stopwatch.isRunning;

  void toggleStopwatch() {
    if (_stopwatch.isRunning) {
      _stopwatch.stop();
      _ticker?.cancel();
    } else {
      _stopwatch.start();
      _ticker = Timer.periodic(
          const Duration(milliseconds: 30), (_) => notifyListeners());
    }
    notifyListeners();
  }

  void resetStopwatch() {
    _stopwatch.stop();
    _stopwatch.reset();
    _ticker?.cancel();
    notifyListeners();
  }

  String get formattedStopwatch {
    final d = _stopwatch.elapsed;
    final m = d.inMinutes.toString().padLeft(2, '0');
    final s = (d.inSeconds % 60).toString().padLeft(2, '0');
    final ms = (d.inMilliseconds % 1000 ~/ 10).toString().padLeft(2, '0');
    return '$m : $s . $ms';
  }

  @override
  void dispose() {
    _timer?.cancel();
    _ticker?.cancel();
    super.dispose();
  }
}
