import 'package:flutter/material.dart';
import '../../../core/constants/design_constants.dart';

enum RabtButtonType {
  primary,
  primarySector,
  secondary,
  ghost,
  quickAccept,
  quickDecline,
  voice,
  fab,
  iconRound,
  danger,
}

class RabtButton extends StatelessWidget {
  final RabtButtonType type;
  final VoidCallback? onPressed;
  final String? label;
  final Widget? icon;
  final String? sectorId;
  final bool isLoading;
  final bool enabled;

  const RabtButton({
    super.key,
    required this.type,
    this.onPressed,
    this.label,
    this.icon,
    this.sectorId,
    this.isLoading = false,
    this.enabled = true,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return _buildButton(theme);
  }

  Widget _buildButton(ThemeData theme) {
    final effectiveOnPressed = enabled && !isLoading ? onPressed : null;

    switch (type) {
      case RabtButtonType.primary:
        return ElevatedButton(
          onPressed: effectiveOnPressed,
          child: _buildContent(),
        );

      case RabtButtonType.primarySector:
        final sectorColor = sectorId != null
            ? Color(sectorColors[sectorId] ?? RabtDesignConstants.primaryLight)
            : theme.colorScheme.primary;
        return ElevatedButton(
          onPressed: effectiveOnPressed,
          style: ElevatedButton.styleFrom(backgroundColor: sectorColor),
          child: _buildContent(),
        );

      case RabtButtonType.secondary:
        return OutlinedButton(
          onPressed: effectiveOnPressed,
          child: _buildContent(),
        );

      case RabtButtonType.ghost:
        return TextButton(
          onPressed: effectiveOnPressed,
          child: _buildContent(),
        );

      case RabtButtonType.quickAccept:
        return ElevatedButton(
          onPressed: effectiveOnPressed,
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(RabtDesignConstants.successLight),
          ),
          child: _buildContent(),
        );

      case RabtButtonType.quickDecline:
        return ElevatedButton(
          onPressed: effectiveOnPressed,
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(RabtDesignConstants.dangerLight),
          ),
          child: _buildContent(),
        );

      case RabtButtonType.voice:
        return SizedBox(
          width: RabtDesignConstants.buttonHeightVoice,
          height: RabtDesignConstants.buttonHeightVoice,
          child: ElevatedButton(
            onPressed: effectiveOnPressed,
            style: ElevatedButton.styleFrom(
              shape: const CircleBorder(),
              padding: EdgeInsets.zero,
            ),
            child: icon ?? const Icon(Icons.mic, size: RabtDesignConstants.iconAction),
          ),
        );

      case RabtButtonType.fab:
        final sectorColor = sectorId != null
            ? Color(sectorColors[sectorId] ?? RabtDesignConstants.primaryLight)
            : theme.colorScheme.primary;
        return SizedBox(
          width: RabtDesignConstants.buttonFabSize,
          height: RabtDesignConstants.buttonFabSize,
          child: FloatingActionButton(
            onPressed: effectiveOnPressed,
            backgroundColor: sectorColor,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(RabtDesignConstants.radiusFab),
            ),
            child: icon ?? const Icon(Icons.add, size: RabtDesignConstants.iconNav),
          ),
        );

      case RabtButtonType.iconRound:
        return SizedBox(
          width: RabtDesignConstants.buttonIconRoundSize,
          height: RabtDesignConstants.buttonIconRoundSize,
          child: ElevatedButton(
            onPressed: effectiveOnPressed,
            style: ElevatedButton.styleFrom(
              backgroundColor: theme.colorScheme.surface,
              shape: const CircleBorder(),
              padding: EdgeInsets.zero,
            ),
            child: icon ?? const Icon(Icons.more_horiz, size: RabtDesignConstants.iconInternal),
          ),
        );

      case RabtButtonType.danger:
        return ElevatedButton(
          onPressed: effectiveOnPressed,
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(RabtDesignConstants.dangerLight),
          ),
          child: _buildContent(),
        );
    }
  }

  Widget _buildContent() {
    if (isLoading) {
      return const SizedBox(
        width: 20,
        height: 20,
        child: CircularProgressIndicator(
          strokeWidth: 2,
          valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
        ),
      );
    }
    if (icon != null && label != null) {
      return Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          icon!,
          const SizedBox(width: RabtDesignConstants.spaceXs),
          Text(label!),
        ],
      );
    }
    if (icon != null) return icon!;
    return Text(label ?? '');
  }

  static const sectorColors = RabtDesignConstants.sectorColors;
}
