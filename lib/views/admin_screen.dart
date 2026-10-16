import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';
import '../firebase_service.dart';
import '../models/product_model.dart';
import 'store_login_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AdminScreen extends StatefulWidget {
  final String storeId;

  const AdminScreen({super.key, required this.storeId});

  @override
  State<AdminScreen> createState() => _AdminScreenState();
}

class _AdminScreenState extends State<AdminScreen> {
  List<ProductModel> _menuList = [];
  final TextEditingController _tablesController = TextEditingController();
  
  // Doanh thu trong ngày
  double _totalRevenue = 0;
  double _cashRevenue = 0;
  double _transferRevenue = 0;

  @override
  void initState() {
    super.initState();
    _loadAdminData();
  }

  // Lấy dữ liệu menu, số bàn và doanh thu ca trong ngày của gian hàng
  void _loadAdminData() {
    // 1. Lắng nghe Menu
    FirebaseService.getMenuRef(widget.storeId).onValue.listen((event) {
      if (event.snapshot.value != null && mounted) {
        Map<dynamic, dynamic> data = event.snapshot.value as Map<dynamic, dynamic>;
        List<ProductModel> loaded = [];
        data.forEach((key, value) {
          loaded.add(ProductModel.fromMap(key.toString(), value as Map<dynamic, dynamic>));
        });
        setState(() {
          _menuList = loaded;
        });
      } else if (mounted) {
        setState(() => _menuList = []);
      }
    });

    // 2. Lắng nghe tổng số bàn
    FirebaseService.getStoreRef(widget.storeId).child('settings/totalTables').onValue.listen((event) {
      if (event.snapshot.value != null && mounted) {
        int val = int.tryParse(event.snapshot.value.toString()) ?? 40;
        setState(() {
          _tablesController.text = val.toString();
        });
      }
    });

    // 3. Lắng nghe doanh thu trong ngày từ node shifts
    FirebaseService.getShiftsRef(widget.storeId).onValue.listen((event) {
      if (event.snapshot.value != null && mounted) {
        Map<dynamic, dynamic> data = event.snapshot.value as Map<dynamic, dynamic>;
        double total = 0;
        double cash = 0;
        double transfer = 0;

        data.forEach((key, value) {
          Map<dynamic, dynamic> shift = value as Map<dynamic, dynamic>;
          double amount = (shift['total'] ?? 0).toDouble();
          String type = shift['type'] ?? 'cash';
          
          total += amount;
          if (type == 'cash') {
            cash += amount;
          } else {
            transfer += amount;
          }
        });

        setState(() {
          _totalRevenue = total;
          _cashRevenue = cash;
          _transferRevenue = transfer;
        });
      } else if (mounted) {
        setState(() {
          _totalRevenue = 0;
          _cashRevenue = 0;
          _transferRevenue = 0;
        });
      }
    });
  }

  // Cập nhật tổng số bàn
  void _updateTotalTables() {
    int? newTables = int.tryParse(_tablesController.text.trim());
    if (newTables == null || newTables <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Vui lòng nhập số lượng bàn hợp lệ!')),
      );
      return;
    }

    FirebaseService.getStoreRef(widget.storeId).child('settings').update({
      'totalTables': newTables,
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Đã cập nhật tổng số bàn thành: $newTables bàn!')),
    );
  }

  // Thêm món mới vào menu
  void _showAddProductDialog() {
    final TextEditingController nameController = TextEditingController();
    final TextEditingController priceController = TextEditingController();
    final TextEditingController catController = TextEditingController(text: 'Cà phê');

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Thêm Món Mới Vào Menu'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameController,
                decoration: const InputDecoration(labelText: 'Tên món (VD: Cà phê đen)'),
              ),
              TextField(
                controller: priceController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(labelText: 'Giá tiền (VD: 20000)'),
              ),
              TextField(
                controller: catController,
                decoration: const InputDecoration(labelText: 'Danh mục (VD: Cà phê, Trà sữa...)'),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Hủy'),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF5D3FD3), foregroundColor: Colors.white),
              onPressed: () {
                String name = nameController.text.trim();
                double? price = double.tryParse(priceController.text.trim());
                String cat = catController.text.trim();

                if (name.isEmpty || price == null) {
                  return;
                }

                DatabaseReference newRef = FirebaseService.getMenuRef(widget.storeId).push();
                newRef.set({
                  'name': name,
                  'price': price,
                  'category': cat.isEmpty ? 'Khác' : cat,
                  'soldOut': false,
                });

                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Đã thêm món mới thành công!')),
                );
              },
              child: const Text('THÊM MÓN'),
            ),
          ],
        );
      },
    );
  }

  // Đổi trạng thái Báo hết / Mở lại món
  void _toggleSoldOut(ProductModel product) {
    FirebaseService.getMenuRef(widget.storeId).child(product.id).update({
      'soldOut': !product.soldOut,
    });
  }

  // Xóa món khỏi menu
  void _deleteProduct(ProductModel product) {
    FirebaseService.getMenuRef(widget.storeId).child(product.id).remove();
  }

  // Đăng xuất đổi gian hàng
  void _logoutStore() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.remove('saved_store_id');
    await prefs.remove('saved_user_role');
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
        title: Text('Quản Lý Gian Hàng: ${widget.storeId.toUpperCase()}'),
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
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // PHẦN 1: BÁO CÁO DOANH THU TRONG NGÀY
            const Text('BÁO CÁO DOANH THU TRONG NGÀY', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF5D3FD3))),
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(color: Colors.blue.shade50, borderRadius: BorderRadius.circular(8), border: Border.all(color: Colors.blue.shade200)),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Tổng Doanh Thu', style: TextStyle(color: Colors.blue, fontWeight: FontWeight.bold)),
                        const SizedBox(height: 6),
                        Text('${_totalRevenue.toStringAsFixed(0)}đ', style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(color: Colors.green.shade50, borderRadius: BorderRadius.circular(8), border: Border.all(color: Colors.green.shade200)),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Tiền Mặt', style: TextStyle(color: Colors.green, fontWeight: FontWeight.bold)),
                        const SizedBox(height: 6),
                        Text('${_cashRevenue.toStringAsFixed(0)}đ', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(color: Colors.purple.shade50, borderRadius: BorderRadius.circular(8), border: Border.all(color: Colors.purple.shade200)),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Chuyển Khoản QR', style: TextStyle(color: Colors.purple, fontWeight: FontWeight.bold)),
                        const SizedBox(height: 6),
                        Text('${_transferRevenue.toStringAsFixed(0)}đ', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                      ],
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 24),
            const Divider(),
            const SizedBox(height: 16),

            // PHẦN 2: CẤU HÌNH SỐ LƯỢNG BÀN
            const Text('CẤU HÌNH SỐ LƯỢNG BÀN', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF5D3FD3))),
            const SizedBox(height: 10),
            Row(
              children: [
                SizedBox(
                  width: 200,
                  child: TextField(
                    controller: _tablesController,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      labelText: 'Tổng số bàn hiển thị',
                      border: OutlineInputBorder(),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF5D3FD3), foregroundColor: Colors.white, padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20)),
                  onPressed: _updateTotalTables,
                  child: const Text('LƯU SỐ BÀN', style: TextStyle(fontWeight: FontWeight.bold)),
                ),
              ],
            ),

            const SizedBox(height: 24),
            const Divider(),
            const SizedBox(height: 16),

            // PHẦN 3: QUẢN LÝ MENU MÓN ĂN
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('QUẢN LÝ MENU MÓN ĂN', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF5D3FD3))),
                ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF5D3FD3), foregroundColor: Colors.white),
                  onPressed: _showAddProductDialog,
                  icon: const Icon(Icons.add),
                  label: const Text('Thêm Món Mới'),
                ),
              ],
            ),
            const SizedBox(height: 10),
            ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: _menuList.length,
              itemBuilder: (context, index) {
                ProductModel product = _menuList[index];
                return Card(
                  margin: const EdgeInsets.symmetric(vertical: 4),
                  child: ListTile(
                    title: Text(product.name, style: TextStyle(fontWeight: FontWeight.bold, decoration: product.soldOut ? TextDecoration.lineThrough : null)),
                    subtitle: Text('Danh mục: ${product.category} | Giá: ${product.price.toStringAsFixed(0)}đ'),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: product.soldOut ? Colors.green : Colors.orange,
                            foregroundColor: Colors.white,
                          ),
                          onPressed: () => _toggleSoldOut(product),
                          child: Text(product.soldOut ? 'Mở lại' : 'Báo Hết'),
                        ),
                        const SizedBox(width: 8),
                        IconButton(
                          icon: const Icon(Icons.delete, color: Colors.red),
                          onPressed: () => _deleteProduct(product),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}