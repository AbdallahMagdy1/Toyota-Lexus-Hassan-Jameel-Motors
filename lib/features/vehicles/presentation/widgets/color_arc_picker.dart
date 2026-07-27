import 'package:flutter/material.dart';

import '../../../../core/utils/responsive.dart';
import '../../../home/presentation/widgets/home_bits.dart';
import '../../domain/vehicle_models.dart';

/// All exterior colors laid out ALONG the slopey arc under the car — the
/// swatches themselves form the curve (no dashed track). Tapping a swatch
/// selects it: it grows, gets the brand ring, and the car image swaps.
final class ColorArcPicker extends StatelessWidget {
  const ColorArcPicker({
    super.key,
    required this.colors,
    required this.index,
    required this.onSelect,
  });

  final List<VehicleColor> colors;
  final int index;
  final ValueChanged<int> onSelect;

  /// Quadratic bezier point for t in [0..1] — gentle downward bow.
  Offset _arcPoint(double t, Size size) {
    final a = Offset(size.width * 0.05, 4);
    final c = Offset(size.width / 2, size.height * 1.25);
    final b = Offset(size.width * 0.95, 4);
    final u = 1 - t;
    return a * (u * u) + c * (2 * u * t) + b * (t * t);
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final n = colors.length;

    return SizedBox(
      height: context.rs(84),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final size = Size(constraints.maxWidth, context.rs(52));
          return Stack(
            clipBehavior: Clip.none,
            children: [
              for (var i = 0; i < n; i++)
                Builder(builder: (context) {
                  // Spread the swatches along the curve; a single color sits
                  // at the arc's center.
                  final t = n == 1 ? 0.5 : 0.08 + (0.84 * i / (n - 1));
                  final p = _arcPoint(t, size);
                  final selected = i == index;
                  final d = context.rs(selected ? 40 : 30);
                  return AnimatedPositioned(
                    duration: const Duration(milliseconds: 220),
                    curve: Curves.easeOut,
                    left: p.dx - d / 2,
                    top: p.dy,
                    child: GestureDetector(
                      onTap: () => onSelect(i),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 220),
                        curve: Curves.easeOutBack,
                        width: d,
                        height: d,
                        padding: EdgeInsets.all(selected ? 2.5 : 1.5),
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: scheme.surface,
                          border: Border.all(
                            color: selected
                                ? scheme.primary
                                : scheme.outline.withValues(alpha: 0.7),
                            width: selected ? 2.2 : 1,
                          ),
                          boxShadow: selected
                              ? [
                                  BoxShadow(
                                    color: Colors.black.withValues(alpha: 0.25),
                                    blurRadius: 10,
                                    offset: const Offset(0, 4),
                                  ),
                                ]
                              : null,
                        ),
                        child: ClipOval(
                          child: HomeImage(
                            url: colors[i].exteriorImage,
                            logicalWidth: 40,
                          ),
                        ),
                      ),
                    ),
                  );
                }),
            ],
          );
        },
      ),
    );
  }
}
