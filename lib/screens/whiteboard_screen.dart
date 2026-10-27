import 'dart:typed_data';
import 'dart:collection';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:hive/hive.dart';
import 'package:image/image.dart' as img;
import '../models.dart';

class WhiteboardScreen extends StatefulWidget {
  const WhiteboardScreen({super.key});
  @override
  State<WhiteboardScreen> createState() => _WhiteboardScreenState();
}

class _WhiteboardScreenState extends State<WhiteboardScreen> {
  List<DrawnLine> lines = [];
  List<DrawnLine> undoneLines = [];
  DrawnLine? currentLine;

  bool isEraser = false;
  bool isToolbarVisible = true;
  bool isFillToolActive = false;

  Color selectedColor = Colors.black;
  double strokeWidth = 3.0;

  final GlobalKey _canvasKey = GlobalKey();
  Uint8List? _backgroundImageBytes;

  final List<Color> colors = [
    Colors.black,
    Colors.red,
    Colors.blue,
    Colors.green,
    Colors.orange,
    Colors.purple,
    Colors.yellow,
    Colors.pink
  ];

  @override
  void initState() {
    super.initState();
    _loadWhiteboard();
  }

  void _loadWhiteboard() {
    final box = Hive.box<WhiteboardStroke>('whiteboard');
    for (var stroke in box.values) {
      lines.add(DrawnLine(
          stroke.points, Color(stroke.colorValue), stroke.strokeWidth));
    }

    final bgBox = Hive.box('whiteboard_bg');
    _backgroundImageBytes = bgBox.get('image');

    setState(() {});
  }

  void _saveWhiteboard() {
    final box = Hive.box<WhiteboardStroke>('whiteboard');
    box.clear();
    for (var line in lines) {
      box.add(WhiteboardStroke(
        points: line.path,
        colorValue: line.color.toARGB32(), // FIX: .value is deprecated
        strokeWidth: line.width,
      ));
    }

    final bgBox = Hive.box('whiteboard_bg');
    if (_backgroundImageBytes != null) {
      bgBox.put('image', _backgroundImageBytes);
    } else {
      bgBox.delete('image');
    }
  }

  // ==========================================
  // CORRECTED FLOOD FILL ALGORITHM FOR IMAGE 4.x
  // ==========================================
  Future<void> _performFloodFill(Offset localPosition) async {
    if (_canvasKey.currentContext == null) return;

    RenderRepaintBoundary boundary =
        _canvasKey.currentContext!.findRenderObject() as RenderRepaintBoundary;
    ui.Image image = await boundary.toImage(pixelRatio: 1.0);
    ByteData? byteData = await image.toByteData(format: ui.ImageByteFormat.png);
    if (byteData == null) return;

    Uint8List pngBytes = byteData.buffer.asUint8List();
    img.Image? decodedImage = img.decodeImage(pngBytes);
    if (decodedImage == null) return;

    int startX = localPosition.dx.toInt();
    int startY = localPosition.dy.toInt();

    if (startX < 0 ||
        startX >= decodedImage.width ||
        startY < 0 ||
        startY >= decodedImage.height) return;

    // Get target pixel components directly (Image 4.x API)
    final targetPixel = decodedImage.getPixel(startX, startY);
    final targetR = targetPixel.r;
    final targetG = targetPixel.g;
    final targetB = targetPixel.b;
    final targetA = targetPixel.a;

    // New color components
    final int r = (selectedColor.toARGB32() >> 16) & 0xFF;
    final int g = (selectedColor.toARGB32() >> 8) & 0xFF;
    final int b = selectedColor.toARGB32() & 0xFF;
    final int a = 255;

    // Prevent infinite loop if clicking the same color
    if (targetR == r && targetG == g && targetB == b && targetA == a) return;

    _floodFillAlgorithm(decodedImage, startX, startY, targetR, targetG, targetB,
        targetA, r, g, b, a);

    List<int> filledBytes = img.encodePng(decodedImage);
    setState(() {
      _backgroundImageBytes = Uint8List.fromList(filledBytes);
      lines.clear();
      undoneLines.clear();
      isFillToolActive = false;
      _saveWhiteboard();
    });
  }

  void _floodFillAlgorithm(
      img.Image image,
      int startX,
      int startY,
      num targetR,
      num targetG,
      num targetB,
      num targetA,
      num newR,
      num newG,
      num newB,
      num newA) {
    final queue = Queue<List<int>>();
    queue.add([startX, startY]);

    while (queue.isNotEmpty) {
      final point = queue.removeFirst();
      final px = point[0];
      final py = point[1];

      if (px < 0 || px >= image.width || py < 0 || py >= image.height) continue;

      final currentPixel = image.getPixel(px, py);
      // Compare RGBA channels directly
      if (currentPixel.r != targetR ||
          currentPixel.g != targetG ||
          currentPixel.b != targetB ||
          currentPixel.a != targetA) {
        continue;
      }

      // Set pixel using the correct method
      image.setPixelRgba(px, py, newR, newG, newB, newA);

      queue.add([px + 1, py]);
      queue.add([px - 1, py]);
      queue.add([px, py + 1]);
      queue.add([px, py - 1]);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: Row(
          children: [
            // SIDEBAR TOOLBAR
            AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              width: isToolbarVisible ? 60 : 0,
              decoration: const BoxDecoration(
                color: Colors.black,
                border:
                    Border(right: BorderSide(color: Colors.white24, width: 1)),
              ),
              child: ClipRect(
                child: OverflowBox(
                  minWidth: 60.0,
                  maxWidth: 60.0,
                  child: Column(
                    children: [
                      const SizedBox(height: 10),
                      IconButton(
                        icon: const Icon(Icons.arrow_back,
                            color: Colors.blue, size: 30),
                        onPressed: () => Navigator.pop(context),
                      ),
                      const SizedBox(height: 20),
                      IconButton(
                        icon: Icon(Icons.edit,
                            color: (!isEraser && !isFillToolActive)
                                ? Colors.blue
                                : Colors.white),
                        onPressed: () => setState(() {
                          isFillToolActive = false;
                          isEraser = false;
                        }),
                      ),
                      IconButton(
                        icon: Icon(Icons.cleaning_services,
                            color: isEraser ? Colors.blue : Colors.white),
                        onPressed: () => setState(() {
                          isEraser = true;
                          isFillToolActive = false;
                        }),
                      ),
                      IconButton(
                        icon: Icon(Icons.format_color_fill,
                            color:
                                isFillToolActive ? Colors.blue : Colors.white),
                        onPressed: () {
                          setState(() {
                            isFillToolActive = true;
                            isEraser = false;
                          });
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                                content: Text(
                                    'Tap anywhere on the canvas to fill.')),
                          );
                        },
                      ),
                      IconButton(
                        icon: const Icon(Icons.circle, color: Colors.white),
                        onPressed: () => _showSizeSlider(context),
                      ),
                      IconButton(
                        icon: const Icon(Icons.palette, color: Colors.white),
                        onPressed: () => _showColorPicker(context),
                      ),
                      const SizedBox(height: 20),
                      IconButton(
                        icon: const Icon(Icons.undo, color: Colors.white),
                        onPressed: () {
                          if (lines.isNotEmpty) {
                            setState(() {
                              undoneLines.add(lines.removeLast());
                              _saveWhiteboard();
                            });
                          }
                        },
                      ),
                      IconButton(
                        icon: const Icon(Icons.redo, color: Colors.white),
                        onPressed: () {
                          if (undoneLines.isNotEmpty) {
                            setState(() {
                              lines.add(undoneLines.removeLast());
                              _saveWhiteboard();
                            });
                          }
                        },
                      ),
                      const Spacer(),
                      IconButton(
                        icon:
                            const Icon(Icons.chevron_left, color: Colors.white),
                        onPressed: () =>
                            setState(() => isToolbarVisible = false),
                      ),
                      const SizedBox(height: 10),
                    ],
                  ),
                ),
              ),
            ),

            // CANVAS AREA
            Expanded(
              child: Stack(
                children: [
                  Container(
                    margin: const EdgeInsets.all(20),
                    child: ClipRect(
                      child: RepaintBoundary(
                        key: _canvasKey,
                        child: Container(
                          color: Colors.white,
                          child: GestureDetector(
                            onTapUp: isFillToolActive
                                ? (details) =>
                                    _performFloodFill(details.localPosition)
                                : null,
                            onPanStart: isFillToolActive
                                ? null
                                : (details) {
                                    setState(() {
                                      undoneLines.clear();
                                      Color drawColor = isEraser
                                          ? Colors.white
                                          : selectedColor;
                                      double drawSize =
                                          isEraser ? 25.0 : strokeWidth;
                                      currentLine = DrawnLine(
                                          [details.localPosition],
                                          drawColor,
                                          drawSize);
                                      lines.add(currentLine!);
                                    });
                                  },
                            onPanUpdate: isFillToolActive
                                ? null
                                : (details) {
                                    setState(() {
                                      currentLine?.path
                                          .add(details.localPosition);
                                    });
                                  },
                            onPanEnd: isFillToolActive
                                ? null
                                : (details) {
                                    setState(() {
                                      currentLine = null;
                                      _saveWhiteboard();
                                    });
                                  },
                            child: Stack(
                              children: [
                                if (_backgroundImageBytes != null)
                                  Positioned.fill(
                                    child: Image.memory(_backgroundImageBytes!,
                                        fit: BoxFit.fill),
                                  ),
                                CustomPaint(
                                  painter: DrawingPainter(lines),
                                  size: Size.infinite,
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                  if (!isToolbarVisible)
                    Positioned(
                      left: 0,
                      top: 0,
                      bottom: 0,
                      child: Center(
                        child: Container(
                          decoration: const BoxDecoration(
                            color: Colors.black54,
                            borderRadius: BorderRadius.only(
                              topRight: Radius.circular(10),
                              bottomRight: Radius.circular(10),
                            ),
                          ),
                          child: IconButton(
                            icon: const Icon(Icons.chevron_right,
                                color: Colors.white),
                            onPressed: () =>
                                setState(() => isToolbarVisible = true),
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showColorPicker(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.grey[900],
      builder: (context) {
        return Container(
          padding: const EdgeInsets.all(20),
          height: 120,
          child: Column(
            children: [
              const Text('Select Pen Color',
                  style: TextStyle(
                      color: Colors.white, fontWeight: FontWeight.bold)),
              const SizedBox(height: 10),
              Expanded(
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  itemCount: colors.length,
                  itemBuilder: (context, index) {
                    return GestureDetector(
                      onTap: () {
                        setState(() {
                          selectedColor = colors[index];
                          isEraser = false;
                        });
                        Navigator.pop(context);
                      },
                      child: Container(
                        margin: const EdgeInsets.symmetric(horizontal: 8),
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          color: colors[index],
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.white, width: 2),
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
  }

  void _showSizeSlider(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.black,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 20),
          height: 160,
          child: Column(
            children: [
              const Text(
                'Brush Size',
                style: TextStyle(
                    color: Colors.blue,
                    fontWeight: FontWeight.bold,
                    fontSize: 18),
              ),
              const SizedBox(height: 10),
              StatefulBuilder(
                builder: (context, setModalState) {
                  return Row(
                    children: [
                      const Text('1', style: TextStyle(color: Colors.white)),
                      Expanded(
                        child: Slider(
                          value: strokeWidth,
                          min: 1.0,
                          max: 30.0,
                          activeColor: Colors.blue,
                          inactiveColor: Colors.grey[800],
                          onChanged: (val) {
                            setModalState(() => strokeWidth = val);
                            setState(() => strokeWidth = val);
                          },
                        ),
                      ),
                      const Text('30', style: TextStyle(color: Colors.white)),
                    ],
                  );
                },
              ),
              Text(
                '${strokeWidth.toStringAsFixed(0)} px',
                style: const TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.bold),
              ),
            ],
          ),
        );
      },
    );
  }
}

class DrawnLine {
  final List<Offset> path;
  final Color color;
  final double width;
  DrawnLine(this.path, this.color, this.width);
}

class DrawingPainter extends CustomPainter {
  final List<DrawnLine> lines;
  DrawingPainter(this.lines);

  @override
  void paint(Canvas canvas, Size size) {
    for (var line in lines) {
      final paint = Paint()
        ..color = line.color
        ..strokeCap = StrokeCap.round
        ..strokeWidth = line.width
        ..style = PaintingStyle.stroke;
      final path = Path();
      if (line.path.isNotEmpty) {
        path.moveTo(line.path.first.dx, line.path.first.dy);
        for (var i = 1; i < line.path.length; i++) {
          path.lineTo(line.path[i].dx, line.path[i].dy);
        }
        canvas.drawPath(path, paint);
      }
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
