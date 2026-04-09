import 'package:flutter/material.dart';
import 'dart:async';

void main() => runApp(const MyApp());

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      home: CalmFadeScreen(),
      debugShowCheckedModeBanner: false,
    );
  }
}

class FluidPoint {
  Offset offset;
  DateTime time;

  FluidPoint(this.offset) : time = DateTime.now();
}

class CalmFadeScreen extends StatefulWidget {
  const CalmFadeScreen({super.key});

  @override
  State<CalmFadeScreen> createState() => _CalmFadeScreenState();
}

class _CalmFadeScreenState extends State<CalmFadeScreen> {
  List<FluidPoint?> points = [];

  @override
  void initState() {
    super.initState();
    // ~16 мс = 60 FPS(1000 ms / 60 = 16)  — стандартная частота обновления кадров для плавной анимации
    Timer.periodic(const Duration(milliseconds: 16), (timer) {
      setState(() {
        points.removeWhere((p) {
          // null — разделитель между линиями или объектами. Его нельзя удалять
          if (p == null) return false;
          // вычисление возраста точки = разница между сейчас и моментом создания точки
          final age = DateTime.now().difference(p.time).inMilliseconds;
          // точки старше 12 секунд удаляются
          return age > 12000;
        });
      });
    });
  }

  void _addPoint(Offset pos) {
    points.add(FluidPoint(pos));
    if (points.length > 1500) points.removeAt(0);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: GestureDetector(
        onPanUpdate: (details) {
          final pos = details.localPosition;
          /* новая точка появляется:
          - если это начало линии
          - или если расстояние до предыдущей точки > 1.5 пикселя
          Это обеспечивает плавность и производительность
           */
          final lastPoint = points.isNotEmpty ? points.last : null;
          if (lastPoint == null || (lastPoint.offset - pos).distance > 1.5) {
            _addPoint(pos);
          }
        },
        onPanEnd: (_) => points.add(null),
        child: CustomPaint(
          painter: CalmFadePainter(points),
          size: Size.infinite,
        ),
      ),
    );
  }
}

class CalmFadePainter extends CustomPainter {
  final List<FluidPoint?> points;

  CalmFadePainter(this.points);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..strokeCap = StrokeCap
          .round // закругленные концы линии
      ..style = PaintingStyle.stroke; // рисуется только линия
    // перебор соседних точек парами (i и i + 1);
    // i < points.length - 1 -> цикл ограничен, чтобы не обратиться к несуществующему элементу
    for (int i = 0; i < points.length - 1; i++) {
      final p1 = points[i]; // текущая точка
      final p2 = points[i + 1]; // следущая точка
      // проверка на разделитель линии - если есть, то пропуск соединения линий.
      if (p1 == null || p2 == null) continue;

      final age = DateTime.now().difference(p1.time).inMilliseconds;
      double opacity = 1 - (age / 6000);
      if (opacity < 0) opacity = 0;

      final hue = (i * 3) % 360;
      final color = HSVColor.fromAHSV(opacity, hue.toDouble(), 1, 1).toColor();

      // мягкое и плавное свечение
      final glowPaint = Paint()
        ..color = Colors.white
            .withValues(alpha: opacity * 0.3) // полупрозрачное свечение
        ..strokeWidth =
            30 // толщина линии
        ..strokeCap = StrokeCap
            .round // концы линии закругленные
        ..style = PaintingStyle.stroke; // только контур линии
      // рисует линию между двумя точками
      canvas.drawLine(p1.offset, p2.offset, glowPaint);

      // основная линия
      paint
        ..color =
            color // цвет радуги
        ..strokeWidth = 18; // толщина линии
      // рисует основную линию поверх свечения
      canvas.drawLine(p1.offset, p2.offset, paint);
    }

    // мягкий кончик пера
    if (points.isNotEmpty && points.last != null) {
      final tip = points.last!;
      final tipPaint = Paint()
        ..color = Colors.white.withValues(alpha: 0.6)
        ..style = PaintingStyle.fill;
      canvas.drawCircle(tip.offset, 16, tipPaint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
