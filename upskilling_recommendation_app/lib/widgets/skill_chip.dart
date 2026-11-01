import 'package:flutter/material';
import 'models/skill.dart';

class SkillChip extends StatelessWidget {
  final Skill skill;
  final bool isSelected;
  final VoidCallback? onSelected;
  final bool showRemove;
  final VoidCallback? onRemoved;

  const SkillChip({
    required this.skill,
    required this.isSelected,
    this.onSelected,
    this.showRemove = false,
    this.onRemoved,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bgColor = isSelected
        ? (isDark ? Color(0xFF3B82F6) : Color(0xFFFFB84D))
        : (isDark ? Color(0xFF64748B) : Color(0xFFF1F5F9));
    final textColor = isSelected ? Colors.white : Colors.black87;

    return ChoiceChip(
      label: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(skill.name),
          if (skill.proficiencyLevel == 'beginner')
            const Padding(
              padding: EdgeInsets.only(left: 4),
              child: Text(
                'Beginner',
                style: TextStyle(fontSize: 10, fontWeight: FontWeight.normal),
              ),
            ),
        ],
      ),
      selected: isSelected,
      selectedColor: bgColor,
      checkmarkColor: Colors.white,
      labelStyle: TextStyle(
        color: textColor,
        fontSize: 13,
        fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
      ),
      backgroundColor: bgColor,
      onSelected: (selected) => onSelected?.call(),
      deleteIcon: showRemove
          ? Icon(
              Icons.close,
              size: 16,
              color: Theme.of(context).colorScheme.onSurface,
            )
          : null,
      onDeleted: onRemoved != null && showRemove ? onRemoved : null,
    );
  }
}