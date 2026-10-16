import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';
import '../firebase_service.dart';
import '../models/table_model.dart';
import 'pos_screen.dart';
import 'store_login_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';

class TableScreen extends StatefulWidget {
  final String storeId;

  const TableScreen({super.key, required this.storeId});

  @override
  State<TableScreen> createState() => _TableScreenState();
}

class _TableScreenState extends State<TableScreen> {
  Map<String, TableModel> _tablesMap = {};
  int _totalTablesCount = 40; // Mặc định hiển thị 40 bàn, có thể thay đổi trong Admin

  @override
  void initState() {
    super.initState();
    _loadStoreSettingsAndTables();
  }

  // Lấy cấu hình số lượng bàn và lắng nghe dữ liệu các bàn từ Firebase theo storeId
  void _loadStoreSettingsAndTables() {
    // Đọc cấu hình tổng số bàn của gian hàng này
    FirebaseService.getStoreRef(widget.storeId).child('settings/totalTables').onValue.listen((event) {
      if (event.snapshot.value != null && mounted) {
        setState(() {
          _totalTablesCount = int.tryParse(event.snapshot.value.toString()) ?? 40;
        });
      }
    });

    // Lắng nghe trạng thái từng bàn trong gian hàng
    FirebaseService.getTablesRef(widget.storeId).onValue.listen((event) {
      if (mounted) {
        Map<String, TableModel> loadedTables = {};
        if (event.snapshot.value != null) {
          Map<dynamic, dynamic> data = event.snapshot.value as Map<dynamic, dynamic>;
          data.forEach((key, value) {
            loadedTables[key.toString()] = TableModel.fromMap(value as Map<dynamic, dynamic>);
          });
        }
        setState(() {
          _tablesMap = loadedTables;
        });
      }
    });
  }

  // Hàm đăng xuất đổi gian hàng
  void _logoutStore() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.remove('current_store_id');
    if (!mounted) return;
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (context) => const StoreLoginScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('S-POS: ${widget.storeId.toUpperCase()}'),
        backgroundColor: const Color(0xFF5D3FD3),
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            tooltip: 'Đổi gian hàng',
            onPressed: _logoutStore,
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(12.0),
        child: GridView.builder(
          itemCount: _totalTablesCount,
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 5, // Hiển thị 5 cột bàn trên màn hình
            crossAxisSpacing: 10,
            mainAxisSpacing: 10,
            childAspectRatio: 1.1,
          ),
          itemBuilder: (context, index) {
            int tableId = index + 1;
            TableModel? table = _tablesMap[tableId.toString()];

            // Xác định màu sắc theo trạng thái bàn:
            // Trắng/Xám: Bàn trống
            // Đỏ: Khách đang gọi món / chưa xong
            // Xanh lá: Đã làm xong hết món / phục vụ hoàn tất
            Color bgColor = Colors.white;
            Color borderColor = Colors.grey.shade300;
            Color textColor = Colors.black87;

            if (table != null) {
              if (table.status == 'red') {
                bgColor = const Color(0xFFFFEBEE);
                borderColor = Colors.red.shade300;
                textColor = Colors.red.shade900;
              } else if (table.status == 'green') {
                bgColor = const Color(0xFFE8F5E9);
                borderColor = Colors.green.shade300;
                textColor = Colors.green.shade900;
              }
            }

            // Tính tổng tiền của bàn
            double totalMoney = 0;
            if (table != null) {
              for (var item in table.items) {
                totalMoney += item.price * item.qty;
              }
            }

            return InkWell(
              onTap: () {
                // Chuyển sang màn hình POS chọn món của bàn này, truyền kèm storeId và tableId
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => PosScreen(
                      storeId: widget.storeId,
                      tableId: tableId,
                    ),
                  ),
                );
              },
              child: Container(
                decoration: BoxDecoration(
                  color: bgColor,
                  border: Border.all(color: borderColor, width: 2),
                  borderRadius: BorderRadius.circular(10),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.03),
                      blurRadius: 4,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      'BÀN $tableId',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                        color: textColor,
                      ),
                    ),
                    const SizedBox(height: 6),
                    if (table != null && totalMoney > 0)
                      Text(
                        '${totalMoney.toStringAsFixed(0)}đ',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          color: textColor,
                        ),
                      )
                    else
                      Text(
                        'Trống',
                        style: TextStyle(fontSize: 11, color: Colors.grey.shade600),
                      ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}