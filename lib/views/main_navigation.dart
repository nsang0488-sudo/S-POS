import 'package:flutter/material.dart';
import 'table_screen.dart';
import 'admin_screen.dart';

class MainNavigation extends StatefulWidget {
  final String storeId;

  const MainNavigation({super.key, required this.storeId});

  @override
  State<MainNavigation> createState() => _MainNavigationState();
}

class _MainNavigationState extends State<MainNavigation> {
  int _currentIndex = 0;

  @override
  Widget build(BuildContext context) {
    // Danh sách các màn hình chính bên trong gian hàng
    final List<Widget> screens = [
      TableScreen(storeId: widget.storeId), // Màn hình sơ đồ bàn của storeId
      AdminScreen(storeId: widget.storeId), // Màn hình quản lý menu, số bàn và doanh thu ca trong ngày
    ];

    return Scaffold(
      body: screens[_currentIndex],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        selectedItemColor: const Color(0xFF5D3FD3),
        unselectedItemColor: Colors.grey,
        onTap: (index) {
          setState(() {
            _currentIndex = index;
          });
        },
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.table_restaurant),
            label: 'Sơ Đồ Bàn',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.admin_panel_settings),
            label: 'Quản Lý & Doanh Thu',
          ),
        ],
      ),
    );
  }
}