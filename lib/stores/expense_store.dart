import 'package:get/get.dart';
import 'package:finance_manager/utils.dart';

class Expense {
  final String place;
  final String name;
  final double amount;
  final String category;
  final DateTime dateTime;

  Expense({
    required this.place,
    required this.name,
    required this.amount,
    required this.category,
    DateTime? dateTime,
  }) : this.dateTime = dateTime ?? DateTime.now();

  Map<String, dynamic> toJson() => {
    'place': place,
    'name': name,
    'amount': amount,
    'category': category,
    'dateTime': dateTime.millisecondsSinceEpoch,
  };

  factory Expense.fromJson(Map<String, dynamic> json) => Expense(
    place: json['place'],
    name: json['name'],
    amount: json['amount'],
    category: json['category'] ?? 'Uncategorized',
    dateTime:
        json['dateTime'] != null
            ? DateTime.fromMillisecondsSinceEpoch(json['dateTime'])
            : DateTime.now(),
  );
}

class ExpenseStore extends GetxController {
  static ExpenseStore get to => Get.find<ExpenseStore>();

  final RxList<Expense> expenses = <Expense>[].obs;
  final RxDouble grossTotal = 0.0.obs;
  final RxBool isLoading = false.obs;

  @override
  void onInit() {
    super.onInit();
    loadExpenses();
  }

  Future<void> loadExpenses() async {
    isLoading.value = true;
    try {
      final loadedExpenses = await getExpensesFromStorage();
      expenses.assignAll(loadedExpenses);
      _updateGrossTotal();
    } finally {
      isLoading.value = false;
    }
  }

  void _updateGrossTotal() {
    grossTotal.value = expenses.fold(
      0.0,
      (previousValue, element) => previousValue + element.amount,
    );
  }

  Future<void> addExpenseToStorage(Expense expense) async {
    isLoading.value = true;
    try {
      final List<Expense> expensesFromStorage =
          StorageUtils.readFromStorage<Expense>('expenses', Expense.fromJson);
      expensesFromStorage.add(expense);
      await StorageUtils.saveToStorage(
        'expenses',
        expensesFromStorage,
        (e) => e.toJson(),
      );
    } finally {
      isLoading.value = false;
    }
  }

  Future<List<Expense>> getExpensesFromStorage() async {
    return StorageUtils.readFromStorage<Expense>('expenses', Expense.fromJson);
  }

  Future<List<Expense>> removeExpenseFromStorage(Expense expense) async {
    isLoading.value = true;
    try {
      final List<Expense> expensesFromStorage =
          StorageUtils.readFromStorage<Expense>('expenses', Expense.fromJson);
      expensesFromStorage.removeWhere(
        (e) =>
            e.name == expense.name &&
            e.place == expense.place &&
            e.amount == expense.amount,
      );
      await StorageUtils.saveToStorage(
        'expenses',
        expensesFromStorage,
        (e) => e.toJson(),
      );
      return expensesFromStorage;
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> addExpense(Expense expense) async {
    expenses.add(expense);
    await addExpenseToStorage(expense);
    _updateGrossTotal();
  }

  Future<void> deleteExpense(Expense expense) async {
    expenses.remove(expense);
    await removeExpenseFromStorage(expense);
    _updateGrossTotal();
  }
}
