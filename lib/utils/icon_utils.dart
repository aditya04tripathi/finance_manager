import 'package:flutter/material.dart';

/// Utility class to manage icons and convert between string names and IconData
class IconUtils {
  /// Get IconData from string icon name
  static IconData getIconData(String iconName) {
    switch (iconName) {
      case 'restaurant':
        return Icons.restaurant;
      case 'directions_car':
        return Icons.directions_car;
      case 'shopping_cart':
        return Icons.shopping_cart;
      case 'movie':
        return Icons.movie;
      case 'receipt':
        return Icons.receipt;
      case 'house':
        return Icons.house;
      case 'flight':
        return Icons.flight;
      case 'hotel':
        return Icons.hotel;
      case 'medical_services':
        return Icons.medical_services;
      case 'fitness_center':
        return Icons.fitness_center;
      case 'school':
        return Icons.school;
      case 'person':
        return Icons.person;
      case 'pets':
        return Icons.pets;
      case 'local_grocery_store':
        return Icons.local_grocery_store;
      case 'local_hospital':
        return Icons.local_hospital;
      case 'work':
        return Icons.work;
      case 'spa':
        return Icons.spa;
      case 'sports':
        return Icons.sports;
      default:
        return Icons.category;
    }
  }
}
