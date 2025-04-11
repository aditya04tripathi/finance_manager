import 'package:finance_manager/screens/settings_screen.dart';
import 'package:finance_manager/stores/settings_store.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:finance_manager/utils.dart';
import 'package:finance_manager/stores/expense_store.dart';
import 'package:finance_manager/stores/category_store.dart';
import 'package:finance_manager/utils/icon_utils.dart';
import 'package:fl_chart/fl_chart.dart';

class AnalyzeScreen extends StatefulWidget {
  const AnalyzeScreen({super.key});

  @override
  State<AnalyzeScreen> createState() => _AnalyzeScreenState();
}

class _AnalyzeScreenState extends State<AnalyzeScreen> {
  final ExpenseStore _expenseStore = ExpenseStore.to;
  final CategoryStore _categoryStore = CategoryStore.to;
  final SettingsStore _settingsStore = SettingsStore.to;
  final RxMap<String, double> categoryTotals = <String, double>{}.obs;
  final RxDouble totalSpending = 0.0.obs;
  final RxDouble averageExpense = 0.0.obs;
  final RxInt totalTransactions = 0.obs;
  final RxList<Color> categoryColors = <Color>[].obs;
  final RxBool isCalculating = false.obs;

  @override
  void initState() {
    super.initState();
    calculateStatistics();

    // React to expense changes
    ever(_expenseStore.expenses, (_) {
      calculateStatistics();
    });

    // React to category changes
    ever(_categoryStore.categories, (_) {
      // Only regenerate colors when categories change
      if (categoryTotals.isNotEmpty) {
        generateCategoryColors();
      }
    });
  }

  void calculateStatistics() {
    if (_expenseStore.expenses.isEmpty) return;

    isCalculating.value = true;

    try {
      categoryTotals.clear();
      totalSpending.value = 0;

      for (var expense in _expenseStore.expenses) {
        categoryTotals[expense.category] =
            (categoryTotals[expense.category] ?? 0) + expense.amount;
        totalSpending.value += expense.amount;
      }

      averageExpense.value =
          totalSpending.value / _expenseStore.expenses.length;
      totalTransactions.value = _expenseStore.expenses.length;

      generateCategoryColors();
    } finally {
      isCalculating.value = false;
    }
  }

  void generateCategoryColors() {
    final List<Color> newColors = [];

    // Use category colors from category store
    for (var category in categoryTotals.keys) {
      final categoryObj = _categoryStore.categories.firstWhereOrNull(
        (c) => c.name == category,
      );

      final Color color;
      if (categoryObj != null) {
        // Use the color from the category store
        color = categoryObj.color;
      } else {
        // Fallback - generate deterministic color based on category name
        // This ensures the same category always gets the same color
        final hash = category.hashCode;
        color = Color.fromARGB(
          255,
          (hash & 0xFF0000) >> 16,
          (hash & 0x00FF00) >> 8,
          hash & 0x0000FF,
        );
      }

      newColors.add(color);
    }

    categoryColors.assignAll(newColors);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Analyze Expenses"),
        centerTitle: true,
        actions: [
          IconButton(
            icon: Icon(Icons.settings_rounded),
            onPressed: () {
              Get.to(() => const SettingsScreen());
            },
          ),
        ],
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Obx(() {
            if (_expenseStore.isLoading.value || isCalculating.value) {
              return const Center(child: CircularProgressIndicator());
            }

            if (_expenseStore.expenses.isEmpty) {
              return const Center(
                child: Text(
                  "No expenses to analyze yet.\nAdd some expenses to see analytics.",
                  textAlign: TextAlign.center,
                ),
              );
            }

            return SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildStatisticsOverview(),
                  const SizedBox(height: 16),
                  _buildSectionTitle("Expense Breakdown"),
                  const SizedBox(height: 16),
                  _buildPieChart(),
                  const SizedBox(height: 16),
                  _buildSectionTitle("Spending by Category"),
                  const SizedBox(height: 16),
                  _buildCategoryList(),
                ],
              ),
            );
          }),
        ),
      ),
    );
  }

  Widget _buildStatisticsOverview() {
    return Card(
      elevation: 0,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              "Spending Overview",
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            Obx(
              () => Column(
                children: [
                  _buildStatCard(
                    "Budget this month",
                    "${FormatUtils.formatCurrency(_settingsStore.monthlyBudget - totalSpending.value)}/${FormatUtils.formatCurrency(_settingsStore.monthlyBudget)}",
                    Colors.white,
                  ),
                  const SizedBox(height: 8),
                  _buildStatCard(
                    "Total Spending",
                    FormatUtils.formatCurrency(totalSpending.value),
                    Colors.red,
                  ),
                  _buildStatCard(
                    "Transactions",
                    "${totalTransactions.value}",
                    Colors.blue,
                  ),
                  _buildStatCard(
                    "Average Expense",
                    FormatUtils.formatCurrency(averageExpense.value),
                    Colors.teal,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatCard(String title, String value, Color color) {
    return Row(
      mainAxisSize: MainAxisSize.max,
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          title,
          style: TextStyle(color: color, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 4),
        Text(value, style: TextStyle(color: color)),
      ],
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
    );
  }

  Widget _buildPieChart() {
    return Obx(
      () => SizedBox(
        height: 300,
        child: PieChart(
          PieChartData(
            sectionsSpace: 2,
            centerSpaceRadius: 40,
            sections: _getSections(),
            pieTouchData: PieTouchData(),
          ),
        ),
      ),
    );
  }

  List<PieChartSectionData> _getSections() {
    final result = <PieChartSectionData>[];
    int colorIndex = 0;

    for (var category in categoryTotals.keys) {
      final value = categoryTotals[category]!;
      final percent = (value / totalSpending.value * 100).toStringAsFixed(1);

      result.add(
        PieChartSectionData(
          color:
              categoryColors.length > colorIndex
                  ? categoryColors[colorIndex]
                  : Colors.grey,
          value: value,
          title: category,
          radius: 100,
          titleStyle: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.bold,
            color: Colors.black,
            background:
                Paint()
                  ..color = Colors.white
                  ..style = PaintingStyle.fill,
          ),
        ),
      );
      colorIndex++;
    }

    return result;
  }

  Widget _buildCategoryList() {
    return Obx(
      () => ListView.builder(
        physics: const NeverScrollableScrollPhysics(),
        shrinkWrap: true,
        itemCount: categoryTotals.length,
        itemBuilder: (context, index) {
          final category = categoryTotals.keys.elementAt(index);
          final amount = categoryTotals[category]!;
          final percent = (amount / totalSpending.value * 100).toStringAsFixed(
            1,
          );

          // Find the category in the store to get the icon
          final categoryObj = _categoryStore.categories.firstWhereOrNull(
            (c) => c.name == category,
          );

          return Container(
            margin: const EdgeInsets.only(bottom: 8),
            decoration: BoxDecoration(borderRadius: BorderRadius.circular(12)),
            child: Row(
              children: [
                if (categoryObj != null)
                  Icon(
                    IconUtils.getIconData(categoryObj.icon),
                    size: 16,
                    color:
                        categoryColors.length > index
                            ? categoryColors[index]
                            : Colors.grey,
                  ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    category,
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
                Text(FormatUtils.formatCurrency(amount)),
                const SizedBox(width: 12),
                Text(
                  "$percent%",
                  style: TextStyle(
                    color:
                        categoryColors.length > index
                            ? categoryColors[index]
                            : Colors.grey,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
