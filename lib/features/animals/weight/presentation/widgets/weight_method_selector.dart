import 'package:flutter/material.dart';

import '../../data/animal_weight_method.dart';

class WeightMethodSelector extends StatelessWidget {
  const WeightMethodSelector({
    super.key,
    required this.selected,
    required this.onSelected,
    this.tapeEnabled = true,
    this.enabled = true,
  });

  final AnimalWeightMethod? selected;
  final ValueChanged<AnimalWeightMethod> onSelected;
  final bool tapeEnabled;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        if (tapeEnabled)
          _Tile(
            title: 'Tape measurement',
            subtitle: 'Heart girth + body length',
            icon: Icons.straighten,
            selected: selected == AnimalWeightMethod.tape,
            onTap: enabled ? () => onSelected(AnimalWeightMethod.tape) : null,
          ),
        _Tile(
          title: 'Scale weight',
          subtitle: 'Enter kg from scale',
          icon: Icons.scale,
          selected: selected == AnimalWeightMethod.scale,
          onTap: enabled ? () => onSelected(AnimalWeightMethod.scale) : null,
        ),
        _Tile(
          title: 'AI camera weight',
          subtitle: 'Photo estimate + confidence',
          icon: Icons.camera_enhance_outlined,
          selected: selected == AnimalWeightMethod.aiCamera,
          onTap: enabled ? () => onSelected(AnimalWeightMethod.aiCamera) : null,
        ),
      ],
    );
  }
}

class _Tile extends StatelessWidget {
  const _Tile({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.selected,
    this.onTap,
  });

  final String title;
  final String subtitle;
  final IconData icon;
  final bool selected;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      color: selected
          ? Theme.of(context).colorScheme.primaryContainer
          : null,
      child: ListTile(
        leading: Icon(icon),
        title: Text(title),
        subtitle: Text(subtitle),
        trailing: selected ? const Icon(Icons.check_circle) : null,
        onTap: onTap,
      ),
    );
  }
}
