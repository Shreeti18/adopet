
import 'package:flutter/material.dart';
import 'package:pet_app/screens/home.dart';
import 'package:pet_app/screens/pets_screen.dart';
import 'package:pet_app/screens/settings_screen.dart';
import 'package:pet_app/theme/color.dart';
import 'package:pet_app/utils/constant.dart';
import 'package:pet_app/widgets/bottombar_item.dart';

class RootApp extends StatefulWidget {
  const RootApp({super.key});

  @override
  State<RootApp> createState() => _RootAppState();
}

class _RootAppState extends State<RootApp>
    with TickerProviderStateMixin {
  int _activeTab = 0;

  late final List<Widget> _pages = [
    HomePage(),
    const PetsScreen(),
    const SettingsScreen(),
  ];

  final List<Map<String, String>> _barItems = [
    {
      'icon': 'assets/icons/home-border.svg',
      'active_icon': 'assets/icons/home.svg',
    },
    {
      'icon': 'assets/icons/pet-border.svg',
      'active_icon': 'assets/icons/pet.svg',
    },
    {
      'icon': 'assets/icons/setting-border.svg',
      'active_icon': 'assets/icons/setting.svg',
    },
  ];

  late final AnimationController _controller =
      AnimationController(
    duration: const Duration(milliseconds: ANIMATED_BODY_MS),
    vsync: this,
  );

  late final Animation<double> _animation = CurvedAnimation(
    parent: _controller,
    curve: Curves.fastOutSlowIn,
  );

  @override
  void initState() {
    super.initState();
    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _onPageChanged(int index) {
    if (index == _activeTab) return;

    _controller.reset();

    setState(() {
      _activeTab = index;
    });

    _controller.forward();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColor.appBgColor,
      body: IndexedStack(
        index: _activeTab,
        children: List.generate(
          _pages.length,
          (index) => FadeTransition(
            opacity: _animation,
            child: _pages[index],
          ),
        ),
      ),
      floatingActionButton: _buildBottomBar(),
      floatingActionButtonLocation:
          FloatingActionButtonLocation.miniCenterDocked,
    );
  }

  Widget _buildBottomBar() {
    return Container(
      height: 55,
      width: double.infinity,
      margin: const EdgeInsets.symmetric(horizontal: 25),
      decoration: BoxDecoration(
        color: AppColor.bottomBarColor,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: AppColor.shadowColor.withOpacity(0.1),
            blurRadius: 1,
            spreadRadius: 1,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: List.generate(
          _barItems.length,
          (index) => BottomBarItem(
            _activeTab == index
                ? _barItems[index]['active_icon']!
                : _barItems[index]['icon']!,
            isActive: _activeTab == index,
            activeColor: AppColor.primary,
            onTap: () => _onPageChanged(index),
          ),
        ),
      ),
    );
  }
}
