import 'package:flutter/material.dart';

class NavBarItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool selected;
  final VoidCallback? onTap;
  final Color selectedColor;
  final Color unselectedColor;

  const NavBarItem({
    required this.icon,
    required this.label,
    required this.selected,
    required this.onTap,
    required this.selectedColor,
    required this.unselectedColor,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkResponse(
        onTap: onTap,
        radius: 30,
        containedInkWell: true,
        borderRadius: BorderRadius.circular(15),
        child: Padding(
          padding: const EdgeInsets.only(left: 13, right: 13, top: 5, bottom: 7),
          child: Column(
            children: [
              Icon(
                icon,
                size: icon == Icons.add_rounded ? 30 : 27,
                color: selected ? selectedColor : unselectedColor,
              ),
              Text(
                label,
                style: TextStyle(
                  color: selected ? selectedColor : unselectedColor,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}