import 'package:flutter/material.dart';

class AppIcons {
  static const List<IconData> availableIcons = [
    Icons.category_rounded,
    Icons.home_rounded,
    Icons.restaurant_rounded,
    Icons.directions_bus_rounded,
    Icons.favorite_rounded,
    Icons.person_rounded,
    Icons.payments_rounded,
    Icons.work_rounded,
    Icons.store_rounded,
    Icons.shopping_bag_rounded,
    Icons.fitness_center_rounded,
    Icons.movie_rounded,
    Icons.school_rounded,
    Icons.flight_rounded,
    Icons.medical_services_rounded,
    Icons.build_rounded,
    Icons.pets_rounded,
    Icons.coffee_rounded,
    Icons.fastfood_rounded,
    Icons.local_grocery_store_rounded,
  ];

  static IconData getIconFromCode(int codePoint) {
    return availableIcons.firstWhere(
      (icon) => icon.codePoint == codePoint,
      orElse: () => Icons.category_rounded,
    );
  }
}
