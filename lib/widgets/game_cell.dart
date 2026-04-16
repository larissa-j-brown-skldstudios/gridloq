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

    final xTile = isWinningCell
        ? const Color(0xFF4B3CBF)
        : const Color(0xFF2B235C);
    final oTile = isWinningCell
        ? const Color(0xFFC73E62)
        : const Color(0xFF5A2130);

    Color bgColor;
    if (isWinningCell) {
      bgColor = cell.owner == Player.x ? xTile : oTile;
    } else if (cell.isFrozen) {
      bgColor = const Color(0xFF123A56);
    } else if (cell.owner == Player.x) {
      bgColor = xTile;
    } else if (cell.owner == Player.o) {
      bgColor = oTile;
    } else {
      // Opaque so gold grid gutters read as lines, not a tint across empty cells.
      bgColor = const Color(0xFF0F0E17);
    }

    final borderColor = isLastMove
        ? Colors.white.withValues(alpha: 0.6)
        : isWinningCell
            ? Colors.amber.withValues(alpha: 0.6)
            : cell.owner != null
                ? Colors.white.withValues(alpha: 0.18)
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

    const color = Colors.white;

    return Stack(
      alignment: Alignment.center,
      children: [
        Text(
          cell.owner!.symbol,
          style: TextStyle(
            fontSize: isSmall ? 16 : 26,
            fontWeight: FontWeight.w900,
            foreground: Paint()
              ..style = PaintingStyle.stroke
              ..strokeWidth = isSmall ? 1.6 : 2.1
              ..color = const Color(0xFF000000),
          ),
        ),
        Text(
          cell.owner!.symbol,
          style: TextStyle(
            fontSize: isSmall ? 16 : 26,
            fontWeight: FontWeight.w900,
            color: color,
            shadows: const [
              Shadow(
                color: Color(0xCC000000),
                blurRadius: 1,
                offset: Offset(0, 1),
              ),
              Shadow(
                color: Color(0x99000000),
                blurRadius: 4,
              ),
            ],
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
