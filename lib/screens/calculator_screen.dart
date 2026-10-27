import 'package:flutter/material.dart';
import 'package:math_expressions/math_expressions.dart';
import 'package:provider/provider.dart';
import '../app_state.dart';

class CalculatorScreen extends StatefulWidget {
  const CalculatorScreen({super.key});
  @override
  State<CalculatorScreen> createState() => _CalculatorScreenState();
}

class _CalculatorScreenState extends State<CalculatorScreen> {
  String input = "";
  String result = "";

  // NEW: Tracks if the user just pressed "="
  bool isCalculated = false;

  void buttonPressed(String btn) {
    setState(() {
      // 1. CLEAR BUTTON
      if (btn == "C") {
        input = "";
        result = "";
        isCalculated = false;
      }
      // 2. BACKSPACE BUTTON
      else if (btn == "<") {
        if (isCalculated) {
          // If they just calculated, backspace clears everything
          input = "";
          result = "";
          isCalculated = false;
        } else if (input.isNotEmpty) {
          input = input.substring(0, input.length - 1);
        }
      }
      // 3. EQUALS BUTTON
      else if (btn == "=") {
        // Prevent double calculating if they spam the "=" button
        if (input.isEmpty || isCalculated) return;

        try {
          String finalInput = input.replaceAll('×', '*').replaceAll('÷', '/');
          GrammarParser p = GrammarParser();
          Expression exp = p.parse(finalInput);
          ContextModel cm = ContextModel();
          double eval = exp.evaluate(EvaluationType.REAL, cm);

          result = eval.toString().endsWith('.0')
              ? eval.toInt().toString()
              : eval.toString();

          // SAVE TO HISTORY
          context.read<AppState>().addCalculationToHistory('$input = $result');

          // Mark that the calculation is finished
          isCalculated = true;
        } catch (e) {
          result = "Error";
          isCalculated = true;
        }
      }
      // 4. NUMBERS & OPERATORS
      else {
        // If they just calculated...
        if (isCalculated) {
          if (["+", "-", "×", "÷", "%"].contains(btn)) {
            // If they press an operator, start the new input with the old result
            input = result;
          } else {
            // If they press a number, start fresh
            input = "";
            result = "";
          }
          isCalculated = false;
        }

        // Existing logic for appending operators/numbers
        if (["+", "-", "×", "÷", "%"].contains(btn)) {
          if (input.isNotEmpty &&
              !["+", "-", "×", "÷", "%"].contains(input[input.length - 1])) {
            input += btn;
          }
        } else {
          input += btn;
        }
      }
    });
  }

  Widget buildButton(String text,
      {Color color = Colors.black, Color textColor = Colors.white}) {
    return Expanded(
      child: Padding(
        padding: const EdgeInsets.all(4.0),
        child: ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: color,
            side: const BorderSide(color: Colors.blue, width: 2),
            padding: const EdgeInsets.symmetric(vertical: 20),
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(0)),
          ),
          onPressed: () => buttonPressed(text),
          child: Text(text,
              style: TextStyle(
                  color: textColor, fontSize: 26, fontWeight: FontWeight.bold)),
        ),
      ),
    );
  }

  // Build the History Bottom Sheet
  void _showHistoryBottomSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.black,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        side: BorderSide(color: Colors.blue, width: 2),
      ),
      builder: (context) {
        return Consumer<AppState>(
          builder: (context, appState, child) {
            final history = appState.calculatorHistory;

            return Container(
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('History',
                          style: TextStyle(
                              color: Colors.blue,
                              fontSize: 22,
                              fontWeight: FontWeight.bold)),
                      if (history.isNotEmpty)
                        TextButton(
                          onPressed: () => appState.clearCalculatorHistory(),
                          child: const Text('Clear',
                              style: TextStyle(color: Colors.red)),
                        ),
                    ],
                  ),
                  const Divider(color: Colors.white24),
                  Expanded(
                    child: history.isEmpty
                        ? const Center(
                            child: Text("No history yet.",
                                style: TextStyle(color: Colors.grey)))
                        : ListView.builder(
                            itemCount: history.length,
                            itemBuilder: (context, index) {
                              return Padding(
                                padding:
                                    const EdgeInsets.symmetric(vertical: 8.0),
                                child: Align(
                                  alignment: Alignment.centerRight,
                                  child: Text(
                                    history[index],
                                    style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 20,
                                        fontWeight: FontWeight.w500),
                                  ),
                                ),
                              );
                            },
                          ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: Column(
          children: [
            // Custom AppBar
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
              child: Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.arrow_back,
                        color: Colors.blue, size: 30),
                    onPressed: () => Navigator.pop(context),
                  ),
                  const Spacer(),
                  GestureDetector(
                    onTap: () => _showHistoryBottomSheet(context),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 30, vertical: 8),
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.blue, width: 2),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: const Text('History',
                          style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold)),
                    ),
                  ),
                  const Spacer(),
                  const SizedBox(width: 50), // Balance layout
                ],
              ),
            ),

            // Display Area
            Expanded(
              flex: 2,
              child: Container(
                alignment: Alignment.bottomRight,
                padding: const EdgeInsets.all(20),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.end,
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(input.isEmpty ? "0" : input,
                        style: const TextStyle(
                            color: Colors.white,
                            fontSize: 60,
                            fontWeight: FontWeight.bold)),
                    const SizedBox(height: 10),
                    Text(result,
                        style: const TextStyle(
                            color: Colors.blue,
                            fontSize: 40,
                            fontWeight: FontWeight.bold)),
                  ],
                ),
              ),
            ),

            // Keypad Area
            Expanded(
              flex: 5,
              child: Container(
                padding: const EdgeInsets.all(10),
                decoration: const BoxDecoration(
                  border: Border(top: BorderSide(color: Colors.blue, width: 4)),
                ),
                child: SingleChildScrollView(
                  child: Column(
                    children: [
                      Row(children: [
                        buildButton("C"),
                        buildButton("<"),
                        buildButton("%"),
                        buildButton("÷")
                      ]),
                      Row(children: [
                        buildButton("1"),
                        buildButton("2"),
                        buildButton("3"),
                        buildButton("×")
                      ]),
                      Row(children: [
                        buildButton("4"),
                        buildButton("5"),
                        buildButton("6"),
                        buildButton("+")
                      ]),
                      Row(children: [
                        buildButton("7"),
                        buildButton("8"),
                        buildButton("9"),
                        buildButton("-")
                      ]),
                      Row(children: [
                        buildButton("00"),
                        buildButton("0"),
                        buildButton("."),
                        buildButton("=",
                            color: Colors.blue, textColor: Colors.white)
                      ]),
                    ],
                  ),
                ),
              ),
            )
          ],
        ),
      ),
    );
  }
}
