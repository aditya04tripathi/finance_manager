import 'dart:io';
import 'package:finance_manager/screens/analyze_screen.dart';
import 'package:finance_manager/screens/category_screen.dart';
import 'package:finance_manager/screens/expense_screen.dart';
import 'package:finance_manager/stores/category_store.dart';
import 'package:finance_manager/stores/expense_store.dart';
import 'package:finance_manager/stores/settings_store.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  MobileAds.instance.initialize();
  await GetStorage.init();

  Get.put(ExpenseStore(), permanent: true);
  Get.put(CategoryStore(), permanent: true);
  Get.put(SettingsStore(), permanent: true);

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return GetMaterialApp(
      title: 'Penny Wise',
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
  BannerAd? _bannerAd;
  bool _isLoaded = false;
  final adUnitId =
      Platform.isAndroid
          ? 'ca-app-pub-5931956401636205/9610387398'
          : 'ca-app-pub-5931956401636205/8942742362';
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
  void initState() {
    super.initState();
    _loadAd();
  }

  @override
  void dispose() {
    _pageController.dispose();
    _bannerAd?.dispose();
    super.dispose();
  }

  void _loadAd() {
    _bannerAd = BannerAd(
      adUnitId: adUnitId,
      request: const AdRequest(),
      size: AdSize.fullBanner,
      listener: BannerAdListener(
        onAdLoaded: (ad) {
          setState(() => _isLoaded = true);
        },
        onAdFailedToLoad: (ad, err) {
          ad.dispose();
        },
        onAdOpened: (_) {},
        onAdClosed: (_) {},
        onAdImpression: (_) {},
      ),
    )..load();
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
        child: Stack(
          children: [
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              bottom: _isLoaded ? 60 : 0,
              child: PageView(
                controller: _pageController,
                onPageChanged: (index) => _currentIndex.value = index,
                children: _pages,
              ),
            ),
            if (_isLoaded && _bannerAd != null)
              Align(
                alignment: Alignment.bottomCenter,
                child: SizedBox(
                  width: _bannerAd!.size.width.toDouble(),
                  height: _bannerAd!.size.height.toDouble(),
                  child: AdWidget(ad: _bannerAd!),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
