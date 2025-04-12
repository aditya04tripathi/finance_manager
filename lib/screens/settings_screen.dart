import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import '../stores/settings_store.dart';
import '../utils/currency_data.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final _budgetController = TextEditingController();
  final _selectedCurrency = 'USD'.obs;
  final SettingsStore settingsStore = Get.find<SettingsStore>();

  @override
  void initState() {
    super.initState();
    _budgetController.text = settingsStore.monthlyBudget.toString();
    _selectedCurrency.value = settingsStore.selectedCurrency;
  }

  @override
  void dispose() {
    _budgetController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TextField(
              controller: _budgetController,
              textCapitalization: TextCapitalization.sentences,
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
              inputFormatters: [
                FilteringTextInputFormatter.allow(RegExp(r'^\d+\.?\d{0,2}')),
              ],
              decoration: const InputDecoration(
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.all(Radius.circular(16)),
                ),
                labelText: 'Set monthly budget',
                hintText: 'Enter amount',
                prefixIcon: Icon(Icons.attach_money),
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Your budget will automatically reset on the 1st of each month.',
              style: TextStyle(fontSize: 12, color: Colors.grey),
              textAlign: TextAlign.right,
            ),
            const SizedBox(height: 8),

            const Text(
              'Currency',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Obx(
              () => DropdownButtonFormField<String>(
                decoration: const InputDecoration(
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.all(Radius.circular(16)),
                  ),
                ),
                value: _selectedCurrency.value,
                items:
                    currencies.entries.map((currency) {
                      return DropdownMenuItem<String>(
                        value: currency.key,
                        child: Text(
                          '${currency.value.symbol} - ${currency.value.name}',
                        ),
                      );
                    }).toList(),
                onChanged: (value) {
                  if (value != null) {
                    _selectedCurrency.value = value;
                  }
                },
              ),
            ),
            const SizedBox(height: 16),

            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  double budget =
                      double.tryParse(_budgetController.text) ?? 0.0;
                  settingsStore.setMonthlyBudget(budget);
                  settingsStore.setCurrency(_selectedCurrency.value);

                  Get.snackbar(
                    "Success",
                    "Settings saved successfully!",
                    backgroundColor: Colors.green,
                    colorText: Colors.white,
                  );
                },
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
                child: const Text('Save Settings'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
