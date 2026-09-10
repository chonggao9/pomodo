import 'dart:math';
import 'package:flutter/material.dart';
import '../core/theme/app_theme.dart';

class PomodoroDial extends StatelessWidget {
  final double progress; // 0.0 to 1.0
  final String formattedTime;
  final bool isRunning;
  final VoidCallback? onTap;

  const PomodoroDial({
    super.key,
    required this.progress,
    required this.formattedTime,
    this.isRunning = false,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final screenW = MediaQuery.of(context).size.width;
    final dialSize = min(screenW * 0.62, 240.0);

    return GestureDetector(
      onTap: onTap,
      child: Center(
        child: Container(
          width: dialSize,
          height: dialSize,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: Colors.white,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.06),
                blurRadius: 24,
                offset: const Offset(0, 12),
              ),
              BoxShadow(
                color: AppTheme.marsGreen.withOpacity(isRunning ? 0.12 : 0.03),
                blurRadius: 32,
                spreadRadius: isRunning ? 3 : 0,
              ),
            ],
          ),
          child: Stack(
            alignment: Alignment.center,
            children: [
              // 60 刻度与动态圆弧 CustomPaint
              CustomPaint(
                size: Size(dialSize, dialSize),
                painter: _DieterRamsDialPainter(
                  progress: progress,
                  accentColor: AppTheme.marsGreen,
                  tickColor: Colors.black.withOpacity(0.12),
                  majorTickColor: Colors.black.withOpacity(0.35),
                ),
              ),

              // 中心内容
              Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // 拟物状态指示小点
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 300),
                    width: 8,
                    height: 8,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: isRunning ? AppTheme.marsGreen : Colors.black26,
                      boxShadow: isRunning
                          ? [
                              BoxShadow(
                                color: AppTheme.marsGreen.withOpacity(0.5),
                                blurRadius: 8,
                                spreadRadius: 2,
                              )
                            ]
                          : [],
                    ),
                  ),
                  const SizedBox(height: 12),

                  // 倒计时数字
                  Text(
                    formattedTime,
                    style: const TextStyle(
                      fontSize: 48,
                      fontWeight: FontWeight.w700,
                      letterSpacing: -1.5,
                      color: AppTheme.textPrimary,
                      fontFeatures: [
                        FontFeature.tabularFigures(),
                      ],
                    ),
                  ),
                  const SizedBox(height: 6),

                  // 提示文本
                  Text(
                    isRunning ? '保持纯粹专注' : '点击或按开始',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      color: isRunning ? AppTheme.marsGreen : AppTheme.textMuted,
                      letterSpacing: 0.5,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _DieterRamsDialPainter extends CustomPainter {
  final double progress;
  final Color accentColor;
  final Color tickColor;
  final Color majorTickColor;

  _DieterRamsDialPainter({
    required this.progress,
    required this.accentColor,
    required this.tickColor,
    required this.majorTickColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = (size.width / 2) - 20;

    // 1. 绘制 60 格精密机械刻度
    final tickPaint = Paint()
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;

    for (int i = 0; i < 60; i++) {
      final angle = (i * 6) * pi / 180;
      final isMajor = i % 5 == 0;
      final tickLength = isMajor ? 10.0 : 5.0;
      final strokeWidth = isMajor ? 2.2 : 1.0;

      tickPaint.color = isMajor ? majorTickColor : tickColor;
      tickPaint.strokeWidth = strokeWidth;

      final startX = center.dx + (radius - tickLength) * cos(angle);
      final startY = center.dy + (radius - tickLength) * sin(angle);
      final endX = center.dx + radius * cos(angle);
      final endY = center.dy + radius * sin(angle);

      canvas.drawLine(Offset(startX, startY), Offset(endX, endY), tickPaint);
    }

    // 2. 绘制马尔斯绿动态倒计时圆弧 (从 -90度 顺时针旋转)
    final arcRect = Rect.fromCircle(center: center, radius: radius - 16);

    // 背景底轨
    final bgArcPaint = Paint()
      ..color = Colors.black.withOpacity(0.04)
      ..strokeWidth = 6.0
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;
    canvas.drawArc(arcRect, 0, 2 * pi, false, bgArcPaint);

    // 前景绿色进度
    if (progress > 0) {
      final sweepAngle = 2 * pi * progress.clamp(0.0, 1.0);
      final activeArcPaint = Paint()
        ..color = accentColor
        ..strokeWidth = 6.0
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round;

      canvas.drawArc(arcRect, -pi / 2, sweepAngle, false, activeArcPaint);
    }
  }

  @override
  bool shouldRepaint(covariant _DieterRamsDialPainter oldDelegate) {
    return oldDelegate.progress != progress ||
        oldDelegate.accentColor != accentColor;
  }
}
