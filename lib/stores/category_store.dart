import 'package:get/get.dart';
import 'package:finance_manager/utils.dart';
import 'package:flutter/material.dart';

class Category {
  final String name;
  final String icon;
  final Color color;

  Category({required this.name, required this.icon, required this.color});

  Map<String, dynamic> toJson() => {
    'name': name,
    'icon': icon,
    'color': color.value,
  };

  factory Category.fromJson(Map<String, dynamic> json) => Category(
    name: json['name'],
    icon: json['icon'],
    color: Color(json['color'] ?? Colors.blue.value),
  );
}

class CategoryStore extends GetxController {
  static CategoryStore get to => Get.find<CategoryStore>();

  final RxList<Category> categories = <Category>[].obs;
  final RxBool isLoading = false.obs;

  @override
  void onInit() {
    super.onInit();
    loadCategories();
  }

  Future<void> loadCategories() async {
    isLoading.value = true;
    try {
      final loadedCategories = await getCategoriesFromStorage();
      if (loadedCategories.isEmpty) {
        final defaultCategories = [
          Category(name: 'Food', icon: 'restaurant', color: Colors.red),
          Category(
            name: 'Transport',
            icon: 'directions_car',
            color: Colors.blue,
          ),
          Category(
            name: 'Shopping',
            icon: 'shopping_cart',
            color: Colors.green,
          ),
          Category(name: 'Entertainment', icon: 'movie', color: Colors.purple),
          Category(name: 'Bills', icon: 'receipt', color: Colors.orange),
        ];

        await StorageUtils.saveToStorage(
          'categories',
          defaultCategories,
          (c) => c.toJson(),
        );
        categories.assignAll(defaultCategories);
      } else {
        categories.assignAll(loadedCategories);
      }
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> addCategoryToStorage(Category category) async {
    isLoading.value = true;
    try {
      final List<Category> categoriesFromStorage =
          StorageUtils.readFromStorage<Category>(
            'categories',
            Category.fromJson,
          );
      categoriesFromStorage.add(category);
      await StorageUtils.saveToStorage(
        'categories',
        categoriesFromStorage,
        (c) => c.toJson(),
      );
    } finally {
      isLoading.value = false;
    }
  }

  Future<List<Category>> getCategoriesFromStorage() async {
    return StorageUtils.readFromStorage<Category>(
      'categories',
      Category.fromJson,
    );
  }

  Future<List<Category>> removeCategoryFromStorage(Category category) async {
    isLoading.value = true;
    try {
      final List<Category> categoriesFromStorage =
          StorageUtils.readFromStorage<Category>(
            'categories',
            Category.fromJson,
          );
      categoriesFromStorage.removeWhere(
        (c) => c.name == category.name && c.icon == category.icon,
      );
      await StorageUtils.saveToStorage(
        'categories',
        categoriesFromStorage,
        (c) => c.toJson(),
      );
      return categoriesFromStorage;
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> addCategory(Category category) async {
    categories.add(category);
    await addCategoryToStorage(category);
  }

  Future<void> deleteCategory(Category category) async {
    categories.remove(category);
    await removeCategoryFromStorage(category);
  }

  Future<void> removeCategory(Category category) async {
    await deleteCategory(category);
  }
}
