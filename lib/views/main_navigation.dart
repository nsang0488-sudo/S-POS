import 'package:flutter/material.dart';
import 'table_screen.dart';
import 'admin_screen.dart';

class MainNavigation extends StatefulWidget {
  final String storeId;
  final String userRole;

  const MainNavigation({
    super.key,
    required this.storeId,
    this.userRole = 'owner',
  });

  @override
  State<MainNavigation> createState() => _MainNavigationState();
}

class _MainNavigationState extends State<MainNavigation> {
  int _currentIndex = 0;

  @override
  Widget build(BuildContext context) {
    bool isOwner = widget.userRole == 'owner';

    final List<Widget> screens = [
      TableScreen(storeId: widget.storeId),
      if (isOwner) AdminScreen(storeId: widget.storeId),
    ];

    return Scaffold(
      body: screens[_currentIndex < screens.length ? _currentIndex : 0],
      bottomNavigationBar: isOwner
          ? BottomNavigationBar(
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
            )
          : null,
    );
  }
}