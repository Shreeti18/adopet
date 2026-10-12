
import 'package:flutter/material.dart';
import 'package:pet_app/theme/color.dart';

class FavoriteBox extends StatelessWidget {
  const FavoriteBox({
    Key? key,
    this.bgColor = AppColor.red,
    this.onTap,
    this.isFavorited = false,
    this.borderColor = Colors.transparent,
    this.radius = 50,
    this.size = 20,
  }) : super(key: key);

  final Color? bgColor;
  final GestureTapCallback? onTap;
  final bool isFavorited;
  final Color borderColor;
  final double radius;
  final double size;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        curve: Curves.fastOutSlowIn,
        padding: const EdgeInsets.all(5),
        decoration: BoxDecoration(
          color: isFavorited ? bgColor : AppColor.primary,
          borderRadius: BorderRadius.circular(radius),
          border: Border.all(color: borderColor),
          boxShadow: [
            BoxShadow(
              color: AppColor.shadowColor.withOpacity(0.1),
              spreadRadius: 1,
              blurRadius: 1,
              offset: const Offset(0, 1),
            ),
          ],
        ),
        child: Icon(
          isFavorited ? Icons.favorite : Icons.favorite_border,
          color: Colors.white,
          size: size,
        ),
      ),
    );
  }
}
