import 'package:flutter/material.dart';
import 'dart:math';

class SnailWidget extends StatefulWidget {
  final double forward;
  final double houseOffsetRatio;
  final Color color;
  final double eyeLengthRatio;
  final double eyeAngle;
  final double width;
  final double height;
  final Offset offset;

  SnailWidget(
      {this.forward = 0.2,
      this.houseOffsetRatio = 0.1,
      this.color,
      this.eyeLengthRatio = 1.5,
      this.width,
      this.height,
      this.offset,
      this.eyeAngle = 35});
  // You can ask Get to find a Controller that is being used by another page and redirect you to it.
  @override
  _SnailWidgetState createState() => _SnailWidgetState();
}

class _SnailWidgetState extends State<SnailWidget>
    with TickerProviderStateMixin {
  @override
  Widget build(context) {
    // Access the updated count variable
    return Container(
        width: widget.width,
        height: widget.height,
        child: CustomPaint(
            painter: SnailPainter(
          forward: widget.forward,
          houseOffsetRatio: widget.houseOffsetRatio,
          color: widget.color,
          eyeAngle: widget.eyeAngle,
          eyeLengthRatio: widget.eyeLengthRatio,
        )));
  }
}

class SnailPainter extends CustomPainter {
  final double forward;
  final double houseOffsetRatio;
  final Color color;
  final double eyeLengthRatio;
  final double eyeAngle;
  SnailPainter(
      {this.forward,
      this.houseOffsetRatio,
      this.color,
      this.eyeLengthRatio = 1,
      this.eyeAngle = 45});

  @override
  void paint(Canvas canvas, Size size) {
    // TODO: implement paint

    num centerX = size.width / 2;
    num centerY = size.height / 2;
    num radius = min(centerX, centerY);
    Offset center = Offset(centerX, centerY);
    Paint fillBrush = Paint()..color = color;
    Paint outBrush = Paint()
      ..color = Colors.black45
      ..strokeWidth = 30 * (radius / 300)
      ..style = PaintingStyle.stroke;

    Paint headBrush = Paint()
      ..color = color
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.fill;

    Paint headBruchOutline = Paint()
      ..color = Colors.black45
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3;

    Paint eyeBrush = Paint()
      ..color = color
      ..strokeCap = StrokeCap.round
      ..strokeWidth = 16 * (radius / 150)
      ..style = PaintingStyle.stroke;

// body fill
    canvas.drawRRect(
        RRect.fromRectAndRadius(
            Rect.fromCenter(
                center: center + Offset(0, radius * -forward),
                width: size.width / 4,
                height: size.height * 0.6),
            Radius.circular(16)),
        headBrush);
//body outline
    canvas.drawRRect(
        RRect.fromRectAndRadius(
            Rect.fromCenter(
                center: center + Offset(0, radius * -forward),
                width: size.width / 4,
                height: size.height * 0.6),
            Radius.circular(16)),
        headBruchOutline);

    // snailhouse

    canvas.drawCircle(center, radius * 0.7, fillBrush);

    // left eye handle

    double eyeLength = radius * 0.6 * eyeLengthRatio;
    print(eyeLength);

    Offset head =
        center + Offset(0, radius * -forward - size.height * 0.3 + 16);

    // left eye
    canvas.drawCircle(
        head +
            Offset(eyeLength * cos((-90 + -eyeAngle) * pi / 180),
                eyeLength * sin((-90 - eyeAngle) * pi / 180)),
        radius * 0.1,
        fillBrush);
    canvas.drawCircle(
        head +
            Offset(eyeLength * cos((-90 + -eyeAngle) * pi / 180),
                eyeLength * sin((-90 - eyeAngle) * pi / 180)),
        radius * 0.1,
        headBruchOutline);

    // left eye handle

    canvas.drawLine(
        head,
        head +
            Offset(eyeLength * cos((-90 + -eyeAngle) * pi / 180),
                eyeLength * sin((-90 - eyeAngle) * pi / 180)),
        eyeBrush);

    // left pupil
    canvas.drawCircle(
        head +
            Offset(eyeLength * cos((-90 + -eyeAngle) * pi / 180),
                eyeLength * sin((-90 - eyeAngle) * pi / 180)),
        radius * 0.005,
        outBrush);

    // right eye
    canvas.drawCircle(
        head +
            Offset(eyeLength * cos((-90 + eyeAngle) * pi / 180),
                eyeLength * sin((-90 + eyeAngle) * pi / 180)),
        radius * 0.1,
        fillBrush);
    canvas.drawCircle(
        head +
            Offset(eyeLength * cos((-90 + eyeAngle) * pi / 180),
                eyeLength * sin((-90 + eyeAngle) * pi / 180)),
        radius * 0.1,
        headBruchOutline);

    // right eye handle

    canvas.drawLine(
        head,
        head +
            Offset(eyeLength * cos((-90 + eyeAngle) * pi / 180),
                eyeLength * sin((-90 + eyeAngle) * pi / 180)),
        eyeBrush);

//right pupil

    canvas.drawCircle(
        head +
            Offset(eyeLength * cos((-90 + eyeAngle) * pi / 180),
                eyeLength * sin((-90 + eyeAngle) * pi / 180)),
        radius * 0.005,
        outBrush);

// house contour
    canvas.drawCircle(center, radius * 0.68, outBrush);
    canvas.drawCircle(center + Offset(0, radius * -houseOffsetRatio),
        radius * 0.45, outBrush);
    canvas.drawCircle(center + Offset(0, radius * -houseOffsetRatio),
        radius * 0.05, outBrush);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) {
    // TODO: implement shouldRepaint
    return true;
  }
}
