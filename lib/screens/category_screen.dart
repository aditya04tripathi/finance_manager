import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:finance_manager/utils.dart';
import 'package:finance_manager/stores/category_store.dart';
import 'package:finance_manager/utils/icon_utils.dart';

class CategoryScreen extends StatefulWidget {
  const CategoryScreen({super.key});

  @override
  State<CategoryScreen> createState() => _CategoryScreenState();
}

class _CategoryScreenState extends State<CategoryScreen>
    with SingleTickerProviderStateMixin {
  final TextEditingController _nameController = TextEditingController();
  final CategoryStore _store = CategoryStore.to;
  final Rx<TabController?> _tabController = Rx<TabController?>(null);

  final RxString _selectedIcon = 'shopping_cart'.obs;
  final Rx<Color> _selectedColor = Colors.blue.obs;
  final RxBool _isDialogOpen = false.obs;

  final RxList<String> availableIcons =
      [
        'restaurant',
        'directions_car',
        'shopping_cart',
        'movie',
        'receipt',
        'house',
        'flight',
        'hotel',
        'medical_services',
        'fitness_center',
        'school',
        'person',
        'pets',
        'local_grocery_store',
        'local_hospital',
        'work',
        'spa',
        'sports',
      ].obs;

  final RxList<Color> availableColors =
      [
        Colors.red,
        Colors.pink,
        Colors.purple,
        Colors.deepPurple,
        Colors.indigo,
        Colors.blue,
        Colors.lightBlue,
        Colors.cyan,
        Colors.teal,
        Colors.green,
        Colors.lightGreen,
        Colors.lime,
        Colors.yellow,
        Colors.amber,
        Colors.orange,
        Colors.deepOrange,
        Colors.brown,
        Colors.grey,
        Colors.blueGrey,
      ].obs;

  @override
  void initState() {
    super.initState();
    _tabController.value = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _nameController.dispose();
    _tabController.value?.dispose();
    super.dispose();
  }

  void _showAddCategoryDialog() {
    _nameController.text = '';
    _selectedIcon.value = 'shopping_cart';
    _selectedColor.value = Colors.blue;
    _isDialogOpen.value = true;

    Get.dialog(
      AlertDialog(
        title: const Text("Add New Category"),
        content: _buildDialogContent(),
        actions: _buildDialogActions(),
      ),
    ).then((_) => _isDialogOpen.value = false);
  }

  Widget _buildDialogContent() {
    return SingleChildScrollView(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          TextField(
            textCapitalization: TextCapitalization.sentences,
            controller: _nameController,
            decoration: const InputDecoration(
              border: OutlineInputBorder(
                borderSide: BorderSide(color: Colors.grey, width: 1),
                borderRadius: BorderRadius.all(Radius.circular(16)),
              ),
              labelText: "Category Name",
              hintText: "e.g. Groceries",
              prefixIcon: Icon(Icons.category_rounded),
            ),
          ),
          const SizedBox(height: 8),
          const Text("Select an icon:"),
          const SizedBox(height: 8),
          Container(
            height: 60,
            width: double.maxFinite,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.grey),
            ),
            child: ListView.builder(
              padding: const EdgeInsets.all(8),
              scrollDirection: Axis.horizontal,
              itemCount: availableIcons.length,
              itemBuilder: (context, index) {
                final iconName = availableIcons[index];
                return Obx(
                  () => GestureDetector(
                    onTap: () => _selectedIcon.value = iconName,
                    child: Container(
                      width: 44,
                      height: 84,
                      margin: const EdgeInsets.only(right: 8),
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color:
                            _selectedIcon.value == iconName
                                ? _selectedColor.value
                                : Colors.grey.shade200,
                      ),
                      child: Icon(
                        getIconData(iconName),
                        color:
                            _selectedIcon.value == iconName
                                ? Colors.white
                                : Colors.black,
                        size: 24,
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: 8),
          const Text("Select a color:"),
          const SizedBox(height: 8),
          Container(
            height: 60,
            width: double.maxFinite,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.grey),
            ),
            child: ListView.builder(
              padding: const EdgeInsets.all(8),
              scrollDirection: Axis.horizontal,
              itemCount: availableColors.length,
              itemBuilder: (context, index) {
                final color = availableColors[index];
                return Obx(
                  () => GestureDetector(
                    onTap: () => _selectedColor.value = color,
                    child: Container(
                      width: 40,
                      height: 40,
                      margin: const EdgeInsets.only(right: 8),
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: color,
                        border:
                            _selectedColor.value == color
                                ? Border.all(color: Colors.white, width: 2)
                                : null,
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  IconData getIconData(String iconName) {
    return IconUtils.getIconData(iconName);
  }

  List<Widget> _buildDialogActions() {
    return [
      TextButton(
        onPressed: () {
          _nameController.clear();
          Get.back(closeOverlays: true);
        },
        child: const Text("Cancel"),
      ),
      Obx(
        () => ElevatedButton(
          onPressed: _store.isLoading.value ? null : () => _saveCategory(),
          style: ElevatedButton.styleFrom(
            backgroundColor: _selectedColor.value,
            foregroundColor: Colors.white,
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
                  : const Text("Add"),
        ),
      ),
    ];
  }

  Future<void> _saveCategory() async {
    if (_nameController.text.trim().isEmpty) {
      ValidationUtils.showErrorSnackbar('Category name cannot be empty');
      return;
    }

    final category = Category(
      name: _nameController.text.trim(),
      icon: _selectedIcon.value,
      color: _selectedColor.value,
    );

    await _store.addCategory(category);
    ValidationUtils.showSuccessSnackbar('Category Added');

    _nameController.clear();
    Get.back(closeOverlays: true);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Manage Categories"),
        centerTitle: true,
        actions: [
          IconButton(
            onPressed: () => _showAddCategoryDialog(),
            tooltip: "Add Category",
            icon: const Icon(Icons.add_rounded, color: Colors.blue),
          ),
        ],
      ),
      body: Obx(
        () =>
            _store.isLoading.value
                ? const Center(child: CircularProgressIndicator())
                : _store.categories.isEmpty
                ? const Center(
                  child: Text(
                    "No categories added yet!\nClick on the + icon at the top right to add one.",
                    textAlign: TextAlign.center,
                  ),
                )
                : ListView.builder(
                  shrinkWrap: true,
                  padding: const EdgeInsets.all(16),
                  itemCount: _store.categories.length,
                  itemBuilder: (context, index) {
                    final category = _store.categories[index];
                    return _buildCategoryCard(category);
                  },
                ),
      ),
    );
  }

  Widget _buildCategoryCard(Category category) {
    return Card(
      elevation: 0,
      margin: const EdgeInsets.only(bottom: 12),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: category.color.withOpacity(0.5)),
          color: category.color.withOpacity(0.1),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: category.color,
              ),
              child: Icon(
                getIconData(category.icon),
                color: Colors.white,
                size: 28,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Text(
                category.name,
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w500,
                  color: category.color.withOpacity(0.8),
                ),
              ),
            ),
            Obx(
              () => IconButton(
                icon: const Icon(Icons.delete_rounded),
                color: Colors.redAccent,
                onPressed:
                    _store.isLoading.value
                        ? null
                        : () {
                          Get.dialog(
                            AlertDialog(
                              title: const Text("Delete Category"),
                              content: Text(
                                "Are you sure you want to delete \"${category.name}\"?",
                              ),
                              actions: [
                                TextButton(
                                  onPressed: () => Get.back(),
                                  child: const Text("Cancel"),
                                ),
                                Obx(
                                  () => ElevatedButton(
                                    onPressed:
                                        _store.isLoading.value
                                            ? null
                                            : () async {
                                              await _store.removeCategory(
                                                category,
                                              );
                                              Get.back();
                                              ValidationUtils.showInfoSnackbar(
                                                'Category deleted',
                                              );
                                            },
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: Colors.red,
                                      foregroundColor: Colors.white,
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
                                            : const Text("Delete"),
                                  ),
                                ),
                              ],
                            ),
                            barrierDismissible: true,
                          );
                        },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
