import 'package:finance_manager/stores/settings_store.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';

class StorageUtils {
  static final storage = GetStorage();

  // Generic function to save data to storage
  static Future<void> saveToStorage<T>(
    String key,
    List<T> items,
    Function toJsonConverter,
  ) async {
    await storage.write(
      key,
      items.map((item) => toJsonConverter(item)).toList(),
    );
  }

  // Generic function to read data from storage
  static List<T> readFromStorage<T>(String key, Function fromJsonConverter) {
    final List<dynamic> rawList = storage.read<List>(key) ?? [];
    final List<Map<String, dynamic>> dataList =
        rawList
            .map<Map<String, dynamic>>((e) => Map<String, dynamic>.from(e))
            .toList();
    return dataList.map<T>((data) => fromJsonConverter(data)).toList();
  }
}

class ValidationUtils {
  // Validate expense inputs
  static bool validateExpenseInputs(String name, String place, String amount) {
    if (name.isEmpty || amount.isEmpty || place.isEmpty) {
      Get.snackbar("Error", "Please fill in all fields");
      return false;
    }

    final double parsedAmount = double.tryParse(amount) ?? 0.0;
    if (parsedAmount <= 0) {
      Get.snackbar("Error", "Please enter a valid amount");
      return false;
    }

    return true;
  }

  static void showSuccessSnackbar(String action) {
    Get.snackbar("Success", "$action expense successfully");
  }

  static void showInfoSnackbar(String message) {
    Get.snackbar(
      "Information",
      message,
      backgroundColor: Colors.blue,
      colorText: Colors.white,
    );
  }

  static void showErrorSnackbar(String action) {
    Get.snackbar(
      "Error",
      "$action expense failed",
      backgroundColor: Colors.red,
      colorText: Colors.white,
    );
  }
}

class FormatUtils {
  static String formatCurrency(double amount) {
    final settingsStore = SettingsStore.to;
    final currencySymbol = settingsStore.getCurrencySymbol(
      settingsStore.selectedCurrency,
    );
    return "$currencySymbol${amount.toStringAsFixed(2)}";
  }
}
