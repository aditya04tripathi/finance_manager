import 'package:finance_manager/screens/analyze_screen.dart';
import 'package:finance_manager/screens/category_screen.dart';
import 'package:finance_manager/screens/expense_screen.dart';
import 'package:finance_manager/stores/category_store.dart';
import 'package:finance_manager/stores/expense_store.dart';
import 'package:finance_manager/stores/settings_store.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';

main() async {
  await GetStorage.init();
  Get.put(ExpenseStore(), permanent: true);
  Get.put(CategoryStore(), permanent: true);
  Get.put(SettingsStore(), permanent: true);

  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  @override
  Widget build(BuildContext context) {
    return GetMaterialApp(
      title: 'Finance Manager',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.blue,
          brightness: Brightness.dark,
        ),
      ),
      home: const MainScreen(),
    );
  }
}

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  final PageController _pageController = PageController(
    initialPage: 0,
    keepPage: true,
  );

  final RxInt _currentIndex = 0.obs;

  final List<Widget> _pages = const [
    ExpenseScreen(),
    AnalyzeScreen(),
    CategoryScreen(),
  ];

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      bottomNavigationBar: Obx(
        () => BottomNavigationBar(
          currentIndex: _currentIndex.value,
          onTap: (index) {
            _currentIndex.value = index;
            _pageController.animateToPage(
              index,
              duration: const Duration(milliseconds: 200),
              curve: Curves.easeInOut,
            );
          },
          selectedItemColor: Colors.blue,
          unselectedItemColor: Colors.grey,
          items: const [
            BottomNavigationBarItem(
              icon: Icon(Icons.attach_money_rounded),
              label: "Expenses",
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.pie_chart_rounded),
              label: "Analyze",
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.category_rounded),
              label: "Categories",
            ),
          ],
        ),
      ),
      body: SafeArea(
        child: PageView(
          controller: _pageController,
          onPageChanged: (index) {
            _currentIndex.value = index;
          },
          children: _pages,
        ),
      ),
    );
  }
}
