import 'dart:io';

import 'package:easy_image_viewer/easy_image_viewer.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_pdfview/flutter_pdfview.dart';
import 'package:get/get.dart';
import 'package:finance_manager/utils.dart';
import 'package:finance_manager/stores/expense_store.dart';
import 'package:finance_manager/stores/category_store.dart';
import 'package:finance_manager/utils/icon_utils.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';

class ExpenseScreen extends StatefulWidget {
  const ExpenseScreen({super.key});

  @override
  State<ExpenseScreen> createState() => _ExpenseScreenState();
}

class _ExpenseScreenState extends State<ExpenseScreen> {
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _amountController = TextEditingController();
  final TextEditingController _placeController = TextEditingController();
  final ExpenseStore _store = ExpenseStore.to;
  final CategoryStore _categoryStore = CategoryStore.to;
  final RxString _selectedFileath = ''.obs;

  final RxString _selectedCategory = 'Uncategorized'.obs;
  final RxBool _isDialogOpen = false.obs;
  final Rx<DateTime> _selectedDateTime = DateTime.now().obs;

  @override
  void dispose() {
    _nameController.dispose();
    _amountController.dispose();
    _placeController.dispose();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    if (_categoryStore.categories.isNotEmpty) {
      _selectedCategory.value = _categoryStore.categories.first.name;
    }

    ever(_categoryStore.categories, (_) {
      if (_categoryStore.categories.isNotEmpty &&
          !_categoryStore.categories.any(
            (c) => c.name == _selectedCategory.value,
          )) {
        _selectedCategory.value = _categoryStore.categories.first.name;
      }
    });
  }

  void _showAddExpenseDialog({Expense? expenseToEdit}) {
    _isDialogOpen.value = true;

    if (expenseToEdit != null) {
      _placeController.text = expenseToEdit.place;
      _nameController.text = expenseToEdit.name;
      _amountController.text = expenseToEdit.amount.toString();
      _selectedCategory.value = expenseToEdit.category;
      _selectedDateTime.value = expenseToEdit.dateTime;
    } else {
      _selectedCategory.value =
          _categoryStore.categories.isNotEmpty
              ? _categoryStore.categories.first.name
              : 'Uncategorized';
      _selectedDateTime.value = DateTime.now();
    }

    Get.dialog(
      AlertDialog(
        title: Text(
          expenseToEdit == null ? "What did you spend on?" : "Edit Expense",
        ),
        content: _buildDialogContent(),
        actions: _buildDialogActions(expenseToEdit),
      ),
      barrierDismissible: true,
    ).then((_) => _isDialogOpen.value = false);
  }

  Future<void> _showDatePicker() async {
    final DateTime? pickedDate = await showDatePicker(
      context: context,
      initialDate: _selectedDateTime.value,
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );

    if (pickedDate != null) {
      _selectedDateTime.value = DateTime(
        pickedDate.year,
        pickedDate.month,
        pickedDate.day,
        _selectedDateTime.value.hour,
        _selectedDateTime.value.minute,
      );
    }
  }

  Future<void> _showTimePicker() async {
    final TimeOfDay? pickedTime = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(_selectedDateTime.value),
    );

    if (pickedTime != null) {
      _selectedDateTime.value = DateTime(
        _selectedDateTime.value.year,
        _selectedDateTime.value.month,
        _selectedDateTime.value.day,
        pickedTime.hour,
        pickedTime.minute,
      );
    }
  }

  Widget _buildDialogContent() {
    return SingleChildScrollView(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          _buildTextField(
            controller: _placeController,
            labelText: "Place of Purchase",
            hintText: "e.g. Coles, Woolworths",
            prefixIcon: const Icon(Icons.store_rounded),
          ),
          const SizedBox(height: 16),
          _buildTextField(
            controller: _nameController,
            labelText: "Expense Name",
            hintText: "e.g. Groceries",
            prefixIcon: const Icon(Icons.description_rounded),
          ),
          const SizedBox(height: 16),
          _buildTextField(
            isNumber: true,
            controller: _amountController,
            labelText: "Expense Amount",
            hintText: "e.g. 10.99",
            prefixIcon: const Icon(Icons.attach_money_rounded),
          ),
          const SizedBox(height: 16),
          _buildDateTimePicker(),
          const SizedBox(height: 16),
          _buildCategoryDropdown(),
          const SizedBox(height: 16),
          _buildPhotoPicker(),
        ],
      ),
    );
  }

  Future<void> _showCameraOrMediaPicker({bool isCamera = true}) async {
    final ImagePicker imagePicker = ImagePicker();
    final XFile? pickedFile = await imagePicker.pickImage(
      source: isCamera ? ImageSource.camera : ImageSource.gallery,
      imageQuality: 100,
    );

    if (pickedFile != null) {
      final Directory appDir = await getApplicationDocumentsDirectory();
      final String fileName = pickedFile.name;
      final File newFile = File('${appDir.path}/$fileName');
      await newFile.writeAsBytes(await pickedFile.readAsBytes());
      _selectedFileath.value = newFile.path;
    } else {
      ValidationUtils.showErrorSnackbar("No image selected. Please try again.");
    }
  }

  Future<void> _showFilePicker() async {
    final FilePickerResult? result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['pdf'],
      allowMultiple: false,
    );

    if (result != null) {
      final String filePath = result.files.single.path!;
      final Directory appDir = await getApplicationDocumentsDirectory();
      final String fileName = result.files.single.name;
      final File newFile = File('${appDir.path}/$fileName');
      await newFile.writeAsBytes(await File(filePath).readAsBytes());
      _selectedFileath.value = newFile.path;
      debugPrint("File path: ${_selectedFileath.value}");
    } else {
      ValidationUtils.showErrorSnackbar("No file selected. Please try again.");
    }
  }

  Widget _buildPhotoPicker() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.blue,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
          ),
          onPressed: () {
            Get.bottomSheet(
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Theme.of(context).scaffoldBackgroundColor,
                  borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(16),
                    topRight: Radius.circular(16),
                  ),
                ),
                child: SafeArea(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      ListTile(
                        leading: const Icon(Icons.photo_library),
                        title: const Text('Choose from Gallery'),
                        onTap: () {
                          _showCameraOrMediaPicker(isCamera: false);
                        },
                      ),
                      ListTile(
                        leading: const Icon(Icons.camera_alt),
                        title: const Text('Take a Photo'),
                        onTap: () {
                          _showCameraOrMediaPicker();
                        },
                      ),
                      ListTile(
                        leading: const Icon(Icons.attach_file),
                        title: const Text('Select a PDF'),
                        onTap: () {
                          _showFilePicker();
                        },
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
          child: const Text(
            "Add Receipt",
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
          ),
        ),
        Obx(
          () => Row(
            children: [
              _selectedFileath.value.isNotEmpty
                  ? _selectedCategory.value.contains("pdf")
                      ? const Text(
                        "PDF file selected",
                        style: TextStyle(fontSize: 12, color: Colors.grey),
                      )
                      : const Text(
                        "Image file selected",
                        style: TextStyle(fontSize: 12, color: Colors.grey),
                      )
                  : const Text("No file selected"),
              _selectedFileath.value.isNotEmpty
                  ? IconButton(
                    onPressed: () {
                      _selectedFileath.value = '';
                      ValidationUtils.showSuccessSnackbar("Receipt removed");
                    },
                    icon: const Icon(Icons.delete_rounded, color: Colors.red),
                  )
                  : SizedBox(),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildDateTimePicker() {
    return Obx(() {
      final dateFormat = DateFormat('MMM dd, yyyy');
      final timeFormat = DateFormat('HH:mm');

      return Row(
        children: [
          Expanded(
            child: InkWell(
              onTap: _showDatePicker,
              child: InputDecorator(
                decoration: const InputDecoration(
                  prefixIcon: Icon(Icons.calendar_today),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.all(Radius.circular(16)),
                  ),
                  labelText: "Date",
                ),
                child: Text(dateFormat.format(_selectedDateTime.value)),
              ),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: InkWell(
              onTap: _showTimePicker,
              child: InputDecorator(
                decoration: const InputDecoration(
                  prefixIcon: Icon(Icons.access_time),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.all(Radius.circular(16)),
                  ),
                  labelText: "Time",
                ),
                child: Text(timeFormat.format(_selectedDateTime.value)),
              ),
            ),
          ),
        ],
      );
    });
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String labelText,
    required String hintText,
    required Widget prefixIcon,
    bool isNumber = false,
  }) {
    return TextField(
      textCapitalization: TextCapitalization.sentences,
      controller: controller,
      keyboardType:
          isNumber
              ? TextInputType.numberWithOptions(decimal: true)
              : TextInputType.text,

      decoration: InputDecoration(
        border: const OutlineInputBorder(
          borderRadius: BorderRadius.all(Radius.circular(16)),
        ),
        labelText: labelText,
        hintText: hintText,
        prefixIcon: prefixIcon,
      ),
    );
  }

  Widget _buildCategoryDropdown() {
    return Obx(() {
      List<String> categories =
          _categoryStore.categories.isEmpty
              ? ['Uncategorized']
              : _categoryStore.categories.map((c) => c.name).toList();
      if (!categories.contains(_selectedCategory.value)) {
        _selectedCategory.value = categories.first;
      }

      return DropdownButtonFormField<String>(
        decoration: const InputDecoration(
          border: OutlineInputBorder(
            borderRadius: BorderRadius.all(Radius.circular(16)),
          ),
          labelText: "Category",
        ),
        value: _selectedCategory.value,
        items:
            categories.map((String category) {
              final categoryObj = _categoryStore.categories.firstWhereOrNull(
                (c) => c.name == category,
              );

              return DropdownMenuItem<String>(
                value: category,
                child: Row(
                  children: [
                    if (categoryObj != null)
                      Icon(
                        IconUtils.getIconData(categoryObj.icon),
                        color: categoryObj.color,
                      ),
                    const SizedBox(width: 16),
                    Text(category),
                  ],
                ),
              );
            }).toList(),
        onChanged: (String? newValue) {
          if (newValue != null) {
            _selectedCategory.value = newValue;
          }
        },
      );
    });
  }

  List<Widget> _buildDialogActions([Expense? expenseToEdit]) {
    return [
      TextButton(onPressed: _clearAndClose, child: const Text("Cancel")),
      Obx(
        () => ElevatedButton(
          onPressed:
              _store.isLoading.value ? null : () => _saveExpense(expenseToEdit),
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.blue,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
          ),
          child:
              _store.isLoading.value
                  ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                  : Text(
                    expenseToEdit == null ? "Add" : "Update",
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
        ),
      ),
    ];
  }

  void _clearAndClose() {
    _clearControllers();
    Get.back(closeOverlays: true);
  }

  void _clearControllers() {
    _placeController.clear();
    _nameController.clear();
    _amountController.clear();
  }

  Future<void> _saveExpense([Expense? expenseToEdit]) async {
    if (!ValidationUtils.validateExpenseInputs(
      _nameController.text,
      _placeController.text,
      _amountController.text,
    )) {
      return;
    }

    final double amount = double.tryParse(_amountController.text) ?? 0.0;

    final expense = Expense(
      place: _placeController.text,
      name: _nameController.text,
      amount: amount,
      category: _selectedCategory.value,
      dateTime: _selectedDateTime.value,
      receiptFile: _selectedFileath.value,
    );

    if (expenseToEdit != null) {
      await _store.deleteExpense(expenseToEdit);
    }

    await _store.addExpense(expense);
    ValidationUtils.showSuccessSnackbar(
      expenseToEdit == null ? 'Added' : 'Updated',
    );

    _clearAndClose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Manage Expenses"),
        centerTitle: true,
        actions: [
          IconButton(
            onPressed: () => _showAddExpenseDialog(),
            tooltip: "Add Expense",
            icon: const Icon(Icons.add_rounded, color: Colors.blue),
          ),
        ],
      ),
      body: Obx(
        () =>
            _store.isLoading.value
                ? const Center(child: CircularProgressIndicator())
                : _store.expenses.isEmpty
                ? const Center(
                  child: Text(
                    "No expenses added yet!\nClick on the + icon at the top right to add one.",
                    textAlign: TextAlign.center,
                  ),
                )
                : ListView.builder(
                  shrinkWrap: true,
                  padding: const EdgeInsets.all(16),
                  itemCount: _store.expenses.length,
                  itemBuilder: (context, index) {
                    final expense = _store.expenses[index];
                    return _buildExpenseCard(expense);
                  },
                ),
      ),
    );
  }

  Widget _buildExpenseCard(Expense expense) {
    final categoryObj = _categoryStore.categories.firstWhereOrNull(
      (c) => c.name == expense.category,
    );

    final String dateTimeText = DateFormat(
      'MMM dd, yyyy • HH:mm',
    ).format(expense.dateTime);

    return GestureDetector(
      onTap: () {
        if (!expense.receiptFile!.contains("pdf")) {
          showImageViewer(
            context,
            Image.file(File(expense.receiptFile!), fit: BoxFit.cover).image,
            swipeDismissible: true,
            doubleTapZoomable: true,
            immersive: true,
            useSafeArea: true,
          );
        } else {
          Get.to(
            () => PDFView(
              filePath: expense.receiptFile!,
              enableSwipe: true,
              backgroundColor: Theme.of(context).scaffoldBackgroundColor,
              pageSnap: true,
            ),
          );
        }
      },
      child: Card(
        elevation: 0,
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(borderRadius: BorderRadius.circular(16)),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        if (categoryObj != null)
                          Padding(
                            padding: const EdgeInsets.only(right: 8.0),
                            child: Icon(
                              IconUtils.getIconData(categoryObj.icon),
                              size: 16,
                            ),
                          ),
                        Text(
                          expense.name,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    Text(
                      expense.place,
                      style: const TextStyle(fontSize: 12, color: Colors.grey),
                    ),
                    Padding(
                      padding: const EdgeInsets.only(top: 2.0),
                      child: Row(
                        children: [
                          const Icon(
                            Icons.access_time,
                            size: 12,
                            color: Colors.grey,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            dateTimeText,
                            style: const TextStyle(
                              fontSize: 12,
                              color: Colors.grey,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Text(
                          FormatUtils.formatCurrency(expense.amount),
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Colors.red,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          expense.category,
                          style: const TextStyle(
                            fontSize: 12,
                            color: Colors.blue,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 16),
              Row(
                children: [
                  IconButton(
                    onPressed:
                        () => _showAddExpenseDialog(expenseToEdit: expense),
                    icon: const Icon(Icons.edit_rounded),
                  ),
                  IconButton(
                    onPressed: () => _showDeleteDialog(expense),
                    icon: const Icon(Icons.delete_rounded, color: Colors.red),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showDeleteDialog(Expense expense) {
    Get.dialog(
      AlertDialog(
        title: const Text(
          "Delete Expense",
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        content: Text(
          "Are you sure you want to delete '${expense.name}'? This action cannot be undone.",
        ),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        actions: [
          TextButton(
            onPressed: () => Get.back(closeOverlays: true),
            child: const Text(
              "CANCEL",
              style: TextStyle(color: Colors.grey, fontWeight: FontWeight.bold),
            ),
          ),
          Obx(
            () => ElevatedButton(
              onPressed:
                  _store.isLoading.value
                      ? null
                      : () async {
                        await _store.deleteExpense(expense);
                        Get.back(closeOverlays: true);
                        ValidationUtils.showSuccessSnackbar('Expense Deleted');
                      },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
              child:
                  _store.isLoading.value
                      ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                      : const Text(
                        "DELETE",
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
            ),
          ),
        ],
      ),
      barrierDismissible: true,
    );
  }
}
