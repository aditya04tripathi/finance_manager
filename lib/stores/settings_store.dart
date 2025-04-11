import 'package:finance_manager/utils/currency_data.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';

class SettingsStore extends GetxController {
  static SettingsStore get to => Get.find<SettingsStore>();

  final GetStorage _storage = GetStorage();
  final String _budgetKey = 'monthlyBudget';
  final String _currencyKey = 'selectedCurrency';
  final String _resetDateKey = 'lastResetDate';

  final RxDouble _monthlyBudget = 0.0.obs;
  final RxString _selectedCurrency = 'USD'.obs;
  Rx<DateTime?> _lastResetDate = Rx<DateTime?>(null);

  double get monthlyBudget => _monthlyBudget.value;
  String get selectedCurrency => _selectedCurrency.value;

  @override
  void onInit() {
    super.onInit();
    _loadSettings();
    _checkForMonthlyReset();
  }

  void _loadSettings() {
    _monthlyBudget.value = _storage.read(_budgetKey) ?? 0.0;
    _selectedCurrency.value = _storage.read(_currencyKey) ?? 'USD';

    final lastResetMillis = _storage.read(_resetDateKey);
    _lastResetDate.value =
        lastResetMillis != null
            ? DateTime.fromMillisecondsSinceEpoch(lastResetMillis)
            : null;
  }

  Future<void> setMonthlyBudget(double amount) async {
    _monthlyBudget.value = amount;
    await _storage.write(_budgetKey, amount);
  }

  Future<void> setCurrency(String currencyCode) async {
    _selectedCurrency.value = currencyCode;
    await _storage.write(_currencyKey, currencyCode);
  }

  String getCurrencySymbol([String? currencyCode]) {
    final code = currencyCode ?? _selectedCurrency.value;

    return currencies[code]?.symbol ?? '\$';
  }

  Future<void> _checkForMonthlyReset() async {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final firstDayOfMonth = DateTime(now.year, now.month, 1);

    if (_lastResetDate.value == null ||
        _lastResetDate.value!.isBefore(firstDayOfMonth)) {
      if (today.day == 1) {
        await _storage.write(_resetDateKey, today.millisecondsSinceEpoch);
        _lastResetDate.value = today;
      }
    }
  }
}
