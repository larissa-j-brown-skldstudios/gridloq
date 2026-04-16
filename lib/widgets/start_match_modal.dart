import 'package:flutter/material.dart';
import '../models/game_models.dart';

/// Lobby-style “VS” moment before the board (inspired by casual word-game UIs; original art only).
class StartMatchModal extends StatelessWidget {
  const StartMatchModal({
    super.key,
    required this.humanPlayer,
    required this.boardLabel,
    required this.onLetsPlay,
    required this.onBack,
  });

  final Player humanPlayer;
  final String boardLabel;
  final VoidCallback onLetsPlay;
  final VoidCallback onBack;

  static const _orange = Color(0xFFE67E22);
  static const _skyBlue = Color(0xFF2D9CDB);
  static const _navy = Color(0xFF1A2B4A);
  static const _avatarBg = Color(0xFFFFD54F);

  @override
  Widget build(BuildContext context) {
    final humanLabel = 'You · ${humanPlayer.symbol}';
    const computerLabel = 'Computer';

    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
              color: _navy,
              child: Column(
                children: [
                  const Text(
                    'Starting your first game!',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    boardLabel,
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.7),
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      letterSpacing: 0.5,
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(
              height: 220,
              child: LayoutBuilder(
                builder: (context, constraints) {
                  final w = constraints.maxWidth;
                  final h = constraints.maxHeight;
                  return Stack(
                    children: [
                      CustomPaint(
                        size: Size(w, h),
                        painter: _VsBackgroundPainter(
                          orange: _orange,
                          skyBlue: _skyBlue,
                        ),
                      ),
                      Positioned(
                        left: 24,
                        top: 0,
                        bottom: 0,
                        child: Align(
                          alignment: Alignment.centerLeft,
                          child: _PlayerColumn(
                            avatarBg: _avatarBg,
                            name: humanLabel,
                            alignRight: false,
                          ),
                        ),
                      ),
                      Positioned(
                        right: 24,
                        top: 0,
                        bottom: 0,
                        child: Align(
                          alignment: Alignment.centerRight,
                          child: _PlayerColumn(
                            avatarBg: _avatarBg,
                            name: computerLabel,
                            alignRight: true,
                          ),
                        ),
                      ),
                      Center(
                        child: Container(
                          width: 56,
                          height: 56,
                          decoration: BoxDecoration(
                            color: Colors.white,
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.2),
                                blurRadius: 8,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          alignment: Alignment.center,
                          child: const Text(
                            'VS',
                            style: TextStyle(
                              color: _skyBlue,
                              fontSize: 18,
                              fontWeight: FontWeight.w900,
                              letterSpacing: 0.5,
                            ),
                          ),
                        ),
                      ),
                    ],
                  );
                },
              ),
            ),
            Container(
              width: double.infinity,
              color: _navy,
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 20),
              child: Column(
                children: [
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton(
                      onPressed: onLetsPlay,
                      style: FilledButton.styleFrom(
                        backgroundColor: Colors.white,
                        foregroundColor: Colors.black87,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                      child: const Text(
                        "Let's Play",
                        style: TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                  ),
                  TextButton(
                    onPressed: onBack,
                    child: Text(
                      'Change settings',
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.85),
                        fontWeight: FontWeight.w600,
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
}

class _VsBackgroundPainter extends CustomPainter {
  _VsBackgroundPainter({
    required this.orange,
    required this.skyBlue,
  });

  final Color orange;
  final Color skyBlue;

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;

    // Diagonal seam: top-right → bottom-left (orange | blue)
    final orangePath = Path()
      ..moveTo(0, 0)
      ..lineTo(w, 0)
      ..lineTo(w * 0.35, h)
      ..lineTo(0, h)
      ..close();

    final bluePath = Path()
      ..moveTo(w, 0)
      ..lineTo(w, h)
      ..lineTo(0, h)
      ..lineTo(w * 0.35, h)
      ..close();

    canvas.drawPath(orangePath, Paint()..color = orange);
    canvas.drawPath(bluePath, Paint()..color = skyBlue);
  }

  @override
  bool shouldRepaint(covariant _VsBackgroundPainter oldDelegate) =>
      oldDelegate.orange != orange || oldDelegate.skyBlue != skyBlue;
}

class _PlayerColumn extends StatelessWidget {
  const _PlayerColumn({
    required this.avatarBg,
    required this.name,
    required this.alignRight,
  });

  final Color avatarBg;
  final String name;
  final bool alignRight;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment:
          alignRight ? CrossAxisAlignment.end : CrossAxisAlignment.start,
      children: [
        Container(
          width: 64,
          height: 64,
          decoration: BoxDecoration(
            color: avatarBg,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.black26, width: 2),
          ),
          child: const Icon(Icons.person, size: 40, color: Color(0xFF5D4037)),
        ),
        const SizedBox(height: 10),
        ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 120),
          child: Text(
            name,
            textAlign: alignRight ? TextAlign.right : TextAlign.left,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 14,
              fontWeight: FontWeight.w700,
              height: 1.2,
              shadows: [
                Shadow(
                  color: Colors.black26,
                  blurRadius: 4,
                  offset: Offset(0, 1),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
