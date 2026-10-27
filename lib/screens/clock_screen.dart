import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../app_state.dart';

class ClockScreen extends StatefulWidget {
  const ClockScreen({super.key});

  @override
  State<ClockScreen> createState() => _ClockScreenState();
}

class _ClockScreenState extends State<ClockScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
              child: Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.arrow_back,
                        color: Colors.blue, size: 30),
                    onPressed: () => Navigator.pop(context),
                  ),
                  Expanded(
                    child: TabBar(
                      controller: _tabController,
                      indicatorColor: Colors.blue,
                      labelColor: Colors.blue,
                      unselectedLabelColor: Colors.white,
                      tabs: const [
                        Tab(text: 'TIMER'),
                        Tab(text: 'STOPWATCH'),
                      ],
                    ),
                  ),
                  const SizedBox(width: 50),
                ],
              ),
            ),
            Expanded(
              child: TabBarView(
                controller: _tabController,
                children: const [
                  TimerWidget(),
                  StopwatchWidget(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ==========================================
// 1. TIMER WIDGET
// ==========================================
class TimerWidget extends StatelessWidget {
  const TimerWidget({super.key});

  Widget _buildKey(String label, VoidCallback onTap, {Color? color}) {
    return Expanded(
      child: Padding(
        padding: const EdgeInsets.all(4.0),
        child: InkWell(
          onTap: onTap,
          child: Container(
            height: 60,
            decoration: BoxDecoration(
              color: Colors.black,
              border: Border.all(color: Colors.blue, width: 2),
            ),
            alignment: Alignment.center,
            // UPDATED: Shows Backspace Icon if label is "<"
            child: label == "<"
                ? const Icon(Icons.backspace_outlined,
                    color: Colors.white, size: 28)
                : Text(label,
                    style: TextStyle(
                        color: color ?? Colors.white,
                        fontSize: 24,
                        fontWeight: FontWeight.bold)),
          ),
        ),
      ),
    );
  }

  Widget _buildTimeRow(
      BuildContext context, String label, int value, int rowIndex) {
    final appState = context.read<AppState>();
    bool isActive = appState.activeRow == rowIndex;

    return GestureDetector(
      onTap: () => appState.setActiveRow(rowIndex),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 15),
        color:
            isActive ? Colors.blue.withValues(alpha: 0.2) : Colors.transparent,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(label,
                style: TextStyle(
                    color: isActive ? Colors.white : Colors.blue,
                    fontSize: 20,
                    fontWeight: FontWeight.bold)),
            Text('$value ${label.toLowerCase()}',
                style: const TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.bold)),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // Listen to AppState for changes
    final appState = context.watch<AppState>();

    if (!appState.isSettingTime) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 300,
              height: 300,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: Colors.blue, width: 4),
              ),
              child: Center(
                child: Text(
                  appState.remainingSeconds == 0
                      ? 'Times Up!'
                      : appState.formattedTime,
                  style: const TextStyle(
                      color: Colors.white,
                      fontSize: 40,
                      fontWeight: FontWeight.bold),
                ),
              ),
            ),
            const SizedBox(height: 50),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                IconButton(
                  iconSize: 60,
                  icon: Icon(
                      appState.isRunning
                          ? Icons.pause_circle_filled
                          : Icons.play_circle_fill,
                      color: Colors.blue),
                  onPressed: appState.toggleTimer,
                ),
                const SizedBox(width: 20),
                IconButton(
                  iconSize: 60,
                  icon: const Icon(Icons.stop_circle, color: Colors.white),
                  onPressed: appState.resetTimer,
                ),
              ],
            )
          ],
        ),
      );
    }

    return Column(
      children: [
        _buildTimeRow(context, 'Hr', appState.hours, 0),
        _buildTimeRow(context, 'Min', appState.minutes, 1),
        _buildTimeRow(context, 'Sec', appState.seconds, 2),
        Expanded(
          child: Container(
            margin: const EdgeInsets.all(10),
            decoration:
                BoxDecoration(border: Border.all(color: Colors.blue, width: 3)),
            child: Column(
              children: [
                Row(children: [
                  _buildKey("1", () => appState.pressKey("1")),
                  _buildKey("2", () => appState.pressKey("2")),
                  _buildKey("3", () => appState.pressKey("3")),
                  _buildKey("<", appState.backspace)
                ]),
                Row(children: [
                  _buildKey("4", () => appState.pressKey("4")),
                  _buildKey("5", () => appState.pressKey("5")),
                  _buildKey("6", () => appState.pressKey("6")),
                  _buildKey("", () {})
                ]),
                Row(children: [
                  _buildKey("7", () => appState.pressKey("7")),
                  _buildKey("8", () => appState.pressKey("8")),
                  _buildKey("9", () => appState.pressKey("9")),
                  _buildKey("", () {})
                ]),
                Row(children: [
                  _buildKey("0", () => appState.pressKey("0")),
                  _buildKey(".", () {}),
                  _buildKey("", () {}),
                  _buildKey("START", appState.toggleTimer, color: Colors.blue)
                ]),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

// ==========================================
// 2. STOPWATCH WIDGET
// ==========================================
class StopwatchWidget extends StatelessWidget {
  const StopwatchWidget({super.key});

  @override
  Widget build(BuildContext context) {
    final appState = context.watch<AppState>();

    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 300,
            height: 300,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: Colors.blue, width: 4),
            ),
            child: Center(
              child: Text(
                appState.formattedStopwatch,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 50,
                  fontWeight: FontWeight.bold,
                  fontFeatures: [FontFeature.tabularFigures()],
                ),
              ),
            ),
          ),
          const SizedBox(height: 50),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              IconButton(
                iconSize: 60,
                icon: Icon(
                    appState.isStopwatchRunning
                        ? Icons.pause_circle_filled
                        : Icons.play_circle_fill,
                    color: Colors.blue),
                onPressed: appState.toggleStopwatch,
              ),
              const SizedBox(width: 20),
              IconButton(
                iconSize: 60,
                icon: const Icon(Icons.stop_circle, color: Colors.white),
                onPressed: appState.resetStopwatch,
              ),
            ],
          )
        ],
      ),
    );
  }
}
