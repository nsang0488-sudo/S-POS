import 'package:flutter/material.dart';
import 'table_screen.dart';
import 'pos_screen.dart';
import 'tasks_screen.dart';
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
  int? _selectedTableId;

  void _onSelectTable(int tableId) {
    setState(() {
      _selectedTableId = tableId;
      _currentIndex = 1; // Switch to POS tab
    });
  }

  void _onClearSelectedTable() {
    setState(() {
      _selectedTableId = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    List<Widget> screens = [
      TableScreen(
        storeId: widget.storeId,
        onTableSelected: _onSelectTable,
      ),
      PosScreen(
        storeId: widget.storeId,
        tableId: _selectedTableId,
        onBackToTables: () {
          setState(() {
            _currentIndex = 0;
          });
        },
        onClearTable: _onClearSelectedTable,
      ),
      TasksScreen(storeId: widget.storeId),
      AdminScreen(storeId: widget.storeId),
    ];

    return Scaffold(
      body: IndexedStack(
        index: _currentIndex,
        children: screens,
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        selectedItemColor: const Color(0xFF5D3FD3),
        unselectedItemColor: Colors.grey,
        type: BottomNavigationBarType.fixed,
        onTap: (index) {
          if (index == 1 && _selectedTableId == null) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Vui lòng chọn bàn trước khi gọi món!'),
                duration: Duration(seconds: 2),
              ),
            );
            setState(() {
              _currentIndex = 0; // Redirect to Tables tab
            });
            return;
          }
          setState(() {
            _currentIndex = index;
          });
        },
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.table_restaurant),
            label: '🪑 BÀN',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.coffee),
            label: '☕ POS',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.assignment),
            label: '📋 VIỆC',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.settings),
            label: '⚙️ QUẢN LÝ',
          ),
        ],
      ),
    );
  }
}
