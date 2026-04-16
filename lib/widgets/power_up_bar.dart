import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/game_models.dart';
import '../state/game_store.dart';

class PowerUpBar extends StatelessWidget {
  const PowerUpBar({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<GameStore>(
      builder: (context, store, _) {
        if (store.gameOver || store.humanPlayer == null) {
          return const SizedBox.shrink();
        }

        final human = store.humanPlayer!;
        final opponent = human.opponent;
        final humanStored = store.storedPowerUps[human] ?? [];
        final opponentStored = store.storedPowerUps[opponent] ?? [];
        final canUseStored = store.isCurrentPlayerHuman &&
            (store.currentPhase == TurnPhase.powerUpDecision ||
                store.currentPhase == TurnPhase.tilePlacement);

        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: _buildPowerUpIntel(
            humanStored: humanStored,
            opponentStored: opponentStored,
            onHumanPowerUpTap: canUseStored
                ? (powerUp) => store.selectPowerUpToUse(powerUp)
                : null,
          ),
        );
      },
    );
  }

  Widget _buildPowerUpIntel({
    required List<PowerUp> humanStored,
    required List<PowerUp> opponentStored,
    void Function(PowerUp powerUp)? onHumanPowerUpTap,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.04),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'STORED POWERUPS',
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w700,
              letterSpacing: 1.5,
              color: Colors.white.withValues(alpha: 0.6),
            ),
          ),
          const SizedBox(height: 6),
          _buildInventoryRow(
            'YOU',
            humanStored,
            onPowerUpTap: onHumanPowerUpTap,
          ),
          const SizedBox(height: 4),
          _buildInventoryRow('OPPONENT', opponentStored),
        ],
      ),
    );
  }

  Widget _buildInventoryRow(
    String label,
    List<PowerUp> powerUps, {
    void Function(PowerUp powerUp)? onPowerUpTap,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 72,
          child: Text(
            label,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: Colors.white.withValues(alpha: 0.65),
              letterSpacing: 0.6,
            ),
          ),
        ),
        Expanded(
          child: powerUps.isEmpty
              ? Text(
                  'none',
                  style: TextStyle(
                    fontSize: 11,
                    color: Colors.white.withValues(alpha: 0.4),
                  ),
                )
              : Wrap(
                  spacing: 6,
                  runSpacing: 4,
                  children: powerUps
                      .map(
                        (powerUp) => _buildIntelChip(
                          powerUp,
                          onTap: onPowerUpTap != null
                              ? () => onPowerUpTap(powerUp)
                              : null,
                        ),
                      )
                      .toList(),
                ),
        ),
      ],
    );
  }

  Widget _buildIntelChip(PowerUp powerUp, {VoidCallback? onTap}) {
    final color = _colorForType(powerUp.type);
    return GestureDetector(
      onTap: onTap,
      child: Opacity(
        opacity: onTap != null ? 1 : 0.85,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.16),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: color.withValues(alpha: 0.35)),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(_iconForType(powerUp.type), size: 12, color: color),
              const SizedBox(width: 4),
              Text(
                powerUp.type.name.toUpperCase(),
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                  color: Colors.white.withValues(alpha: 0.85),
                  letterSpacing: 0.4,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Color _colorForType(PowerUpType type) {
    switch (type) {
      case PowerUpType.bomb:
        return const Color(0xFFEF4444);
      case PowerUpType.steal:
        return const Color(0xFFA855F7);
      case PowerUpType.freeze:
        return const Color(0xFF38BDF8);
      case PowerUpType.fire:
        return const Color(0xFFF97316);
      case PowerUpType.fortify:
        return const Color(0xFF22D3EE);
    }
  }

  IconData _iconForType(PowerUpType type) {
    switch (type) {
      case PowerUpType.bomb:
        return Icons.rocket_launch;
      case PowerUpType.steal:
        return Icons.pan_tool;
      case PowerUpType.freeze:
        return Icons.ac_unit;
      case PowerUpType.fire:
        return Icons.bolt;
      case PowerUpType.fortify:
        return Icons.shield;
    }
  }
}

class PowerUpDecisionBanner extends StatelessWidget {
  const PowerUpDecisionBanner({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<GameStore>(
      builder: (context, store, _) {
        if (store.gameOver || !store.isCurrentPlayerHuman) {
          return const SizedBox.shrink();
        }
        if (store.currentPowerUp == null) {
          return const SizedBox.shrink();
        }

        final showDecision = store.currentPhase == TurnPhase.powerUpDecision;
        final showAction = store.currentPhase == TurnPhase.powerUpAction;
        if (!showDecision && !showAction) {
          return const SizedBox.shrink();
        }

        return Padding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
          child: showDecision
              ? _buildCurrentPowerUp(context, store)
              : _buildActionHint(context, store),
        );
      },
    );
  }

  Widget _buildCurrentPowerUp(BuildContext context, GameStore store) {
    final pu = store.currentPowerUp!;
    final canUseNow = store.canUsePowerUpNow(pu);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: _colorForType(pu.type).withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: _colorForType(pu.type).withValues(alpha: 0.3),
        ),
      ),
      child: Row(
        children: [
          Icon(_iconForType(pu.type), color: _colorForType(pu.type), size: 20),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              canUseNow
                  ? '${pu.type.name.toUpperCase()} — Use or store?'
                  : '${pu.type.name.toUpperCase()} — No valid targets, store it',
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: Colors.white,
              ),
            ),
          ),
          TextButton(
            onPressed: canUseNow ? () => store.selectPowerUpToUse(pu) : null,
            child: const Text('USE', style: TextStyle(fontWeight: FontWeight.w700)),
          ),
          TextButton(
            onPressed: () => store.storePowerUpAndSkip(),
            child: Text(
              'STORE',
              style: TextStyle(
                fontWeight: FontWeight.w700,
                color: Colors.white.withValues(alpha: 0.5),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionHint(BuildContext context, GameStore store) {
    final pu = store.currentPowerUp!;
    String hint;
    switch (pu.type) {
      case PowerUpType.bomb:
        hint = 'Tap an opponent tile to destroy it';
      case PowerUpType.steal:
        hint = 'Tap an opponent tile to steal it';
      case PowerUpType.freeze:
        hint = 'Tap an empty tile to freeze it';
      case PowerUpType.fire:
        hint = 'Tap a frozen tile to melt it';
      case PowerUpType.fortify:
        hint = 'Tap your tile to protect it';
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: _colorForType(pu.type).withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Icon(_iconForType(pu.type), color: _colorForType(pu.type), size: 18),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              hint,
              style: TextStyle(
                fontSize: 13,
                color: Colors.white.withValues(alpha: 0.7),
              ),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.close, size: 18),
            onPressed: () => store.cancelPowerUpAction(),
            color: Colors.white.withValues(alpha: 0.4),
          ),
        ],
      ),
    );
  }

  Color _colorForType(PowerUpType type) {
    switch (type) {
      case PowerUpType.bomb:
        return const Color(0xFFEF4444);
      case PowerUpType.steal:
        return const Color(0xFFA855F7);
      case PowerUpType.freeze:
        return const Color(0xFF38BDF8);
      case PowerUpType.fire:
        return const Color(0xFFF97316);
      case PowerUpType.fortify:
        return const Color(0xFF22D3EE);
    }
  }

  IconData _iconForType(PowerUpType type) {
    switch (type) {
      case PowerUpType.bomb:
        return Icons.rocket_launch;
      case PowerUpType.steal:
        return Icons.pan_tool;
      case PowerUpType.freeze:
        return Icons.ac_unit;
      case PowerUpType.fire:
        return Icons.bolt;
      case PowerUpType.fortify:
        return Icons.shield;
    }
  }
}
