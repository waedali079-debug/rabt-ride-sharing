import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import '../../../core/constants/design_constants.dart';

class SectorCard extends StatelessWidget {
  final String sectorId;
  final String title;
  final String subtitle;
  final String iconPath;
  final VoidCallback onTap;
  final bool isSelected;

  const SectorCard({
    super.key,
    required this.sectorId,
    required this.title,
    required this.subtitle,
    required this.iconPath,
    required this.onTap,
    this.isSelected = false,
  });

  @override
  Widget build(BuildContext context) {
    final sectorColor = Color(RabtDesignConstants.sectorColors[sectorId] ?? RabtDesignConstants.primaryLight);
    final theme = Theme.of(context);

    return Card(
      elevation: isSelected ? 2 : 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20.0),
        side: isSelected
            ? BorderSide(color: sectorColor, width: 2.0)
            : BorderSide(color: theme.colorScheme.outline.withOpacity(0.1)),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20.0),
        child: Padding(
          padding: const EdgeInsets.all(RabtDesignConstants.spaceLg),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: RabtDesignConstants.iconSector,
                height: RabtDesignConstants.iconSector,
                decoration: BoxDecoration(
                  color: sectorColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(16.0),
                ),
                child: SvgPicture.asset(
                  iconPath,
                  colorFilter: ColorFilter.mode(sectorColor, BlendMode.srcIn),
                  width: RabtDesignConstants.iconNav,
                  height: RabtDesignConstants.iconNav,
                ),
              ),
              const SizedBox(height: RabtDesignConstants.spaceMd),
              Text(
                title,
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
                textAlign: TextAlign.center,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: RabtDesignConstants.spaceXs),
              Text(
                subtitle,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurface.withOpacity(0.6),
                ),
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
