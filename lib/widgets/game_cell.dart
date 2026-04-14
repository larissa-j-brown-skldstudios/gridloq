import 'package:flutter/material.dart';
import '../models/game_models.dart';

class GameCell extends StatelessWidget {
  final int index;
  final CellValue cell;
  final bool isLastMove;
  final bool isWinningCell;
  final int gridSize;
  final VoidCallback onTap;

  const GameCell({
    super.key,
    required this.index,
    required this.cell,
    required this.isLastMove,
    required this.isWinningCell,
    required this.gridSize,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isSmall = gridSize >= 10;

    Color bgColor;
    if (isWinningCell) {
      bgColor = (cell.owner == Player.x
              ? const Color(0xFF6C63FF)
              : const Color(0xFFFF6584))
          .withValues(alpha: 0.6);
    } else if (cell.isFrozen) {
      bgColor = const Color(0xFF38BDF8).withValues(alpha: 0.25);
    } else if (cell.owner == Player.x) {
      bgColor = const Color(0xFF6C63FF).withValues(alpha: 0.3);
    } else if (cell.owner == Player.o) {
      bgColor = const Color(0xFFFF6584).withValues(alpha: 0.3);
    } else {
      bgColor = Colors.white.withValues(alpha: 0.04);
    }

    final borderColor = isLastMove
        ? Colors.white.withValues(alpha: 0.6)
        : isWinningCell
            ? Colors.amber.withValues(alpha: 0.6)
            : cell.isProtected
                ? const Color(0xFF22D3EE).withValues(alpha: 0.5)
                : Colors.white.withValues(alpha: 0.06);

    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(isSmall ? 4 : 8),
          border: Border.all(color: borderColor, width: isLastMove ? 2 : 1),
        ),
        child: Center(
          child: _buildContent(isSmall),
        ),
      ),
    );
  }

  Widget _buildContent(bool isSmall) {
    if (cell.isFrozen && cell.owner == null) {
      return Icon(
        Icons.ac_unit,
        size: isSmall ? 12 : 20,
        color: const Color(0xFF38BDF8).withValues(alpha: 0.7),
      );
    }

    if (cell.owner == null) return const SizedBox.shrink();

    final color = cell.owner == Player.x
        ? const Color(0xFF6C63FF)
        : const Color(0xFFFF6584);

    return Stack(
      alignment: Alignment.center,
      children: [
        Text(
          cell.owner!.symbol,
          style: TextStyle(
            fontSize: isSmall ? 14 : 24,
            fontWeight: FontWeight.w900,
            color: color,
          ),
        ),
        if (cell.isProtected)
          Positioned(
            top: 0,
            right: 0,
            child: Icon(
              Icons.shield,
              size: isSmall ? 8 : 12,
              color: const Color(0xFF22D3EE),
            ),
          ),
      ],
    );
  }
}
