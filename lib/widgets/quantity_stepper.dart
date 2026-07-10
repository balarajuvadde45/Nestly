import 'package:flutter/material.dart';
import '../core/theme/app_colors.dart';

class QuantityStepper extends StatelessWidget {
  final int quantity;
  final VoidCallback onIncrement;
  final VoidCallback onDecrement;
  final bool compact;
  final bool outlined;

  const QuantityStepper({
    super.key,
    required this.quantity,
    required this.onIncrement,
    required this.onDecrement,
    this.compact = false,
    this.outlined = false,
  });

  @override
  Widget build(BuildContext context) {
    final h = compact ? 30.0 : 36.0;
    final iconSize = compact ? 16.0 : 18.0;
    final fontSize = compact ? 13.0 : 14.0;

    if (quantity == 0) {
      return SizedBox(
        height: h,
        child: outlined
            ? OutlinedButton(
                onPressed: onIncrement,
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  side: const BorderSide(color: AppColors.primary),
                  foregroundColor: AppColors.primary,
                  minimumSize: Size(compact ? 72 : 88, h),
                ),
                child: Text('ADD',
                    style: TextStyle(
                        fontWeight: FontWeight.w700, fontSize: fontSize)),
              )
            : ElevatedButton(
                onPressed: onIncrement,
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  minimumSize: Size(compact ? 72 : 88, h),
                ),
                child: Text('ADD',
                    style: TextStyle(
                        fontWeight: FontWeight.w700, fontSize: fontSize)),
              ),
      );
    }

    return Container(
      height: h,
      decoration: BoxDecoration(
        color: outlined ? Colors.white : AppColors.primary,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.primary),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _btn(Icons.remove_rounded, onDecrement, iconSize, outlined),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8),
            child: Text(
              '$quantity',
              style: TextStyle(
                color: outlined ? AppColors.primary : Colors.white,
                fontWeight: FontWeight.w700,
                fontSize: fontSize,
              ),
            ),
          ),
          _btn(Icons.add_rounded, onIncrement, iconSize, outlined),
        ],
      ),
    );
  }

  Widget _btn(IconData icon, VoidCallback onTap, double size, bool outline) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
        child: Icon(
          icon,
          size: size,
          color: outline ? AppColors.primary : Colors.white,
        ),
      ),
    );
  }
}
