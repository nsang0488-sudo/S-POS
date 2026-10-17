import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';
import 'dart:math';
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
  final TextEditingController _qrUrlController = TextEditingController();

  Map<dynamic, dynamic> _activeShift = {};
  Map<dynamic, dynamic> _shiftLogs = {};
  Map<dynamic, dynamic> _devices = {};
  String _regCode = '-----';

  @override
  void initState() {
    super.initState();
    _loadAdminData();
  }

  void _loadAdminData() {
    // Menu
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

    // Settings (tables, regCode, qrUrl)
    FirebaseService.getSettingsRef(widget.storeId).onValue.listen((event) {
      if (event.snapshot.value != null && mounted) {
        Map<dynamic, dynamic> settings = event.snapshot.value as Map<dynamic, dynamic>;
        setState(() {
          _tablesController.text = (settings['totalTables'] ?? 40).toString();
          _regCode = (settings['regCode'] ?? '-----').toString();
          _qrUrlController.text = (settings['qrUrl'] ?? '').toString();
        });
      }
    });

    // Active Shift
    FirebaseService.getActiveShiftRef(widget.storeId).onValue.listen((event) {
      if (event.snapshot.value != null && mounted) {
        setState(() {
          _activeShift = event.snapshot.value as Map<dynamic, dynamic>;
        });
      } else if (mounted) {
        setState(() {
          _activeShift = {};
        });
      }
    });

    // Shift Logs
    FirebaseService.getShiftLogsRef(widget.storeId).onValue.listen((event) {
      if (event.snapshot.value != null && mounted) {
        setState(() {
          _shiftLogs = event.snapshot.value as Map<dynamic, dynamic>;
        });
      } else if (mounted) {
        setState(() {
          _shiftLogs = {};
        });
      }
    });

    // Devices
    FirebaseService.getDevicesRef(widget.storeId).onValue.listen((event) {
      if (event.snapshot.value != null && mounted) {
        setState(() {
          _devices = event.snapshot.value as Map<dynamic, dynamic>;
        });
      } else if (mounted) {
        setState(() {
          _devices = {};
        });
      }
    });
  }

  void _startShift() {
    FirebaseService.getActiveShiftRef(widget.storeId).set({
      'start': DateTime.now().toIso8601String(),
      'revenue': 0,
      'revenueCash': 0,
      'revenueTransfer': 0,
    });
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Đã mở ca mới thành công!')),
    );
  }

  void _endShift() {
    if (_activeShift.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Không có ca nào đang mở!')),
      );
      return;
    }

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Xác nhận CHỐT CA?'),
          content: const Text('Toàn bộ bàn sẽ được dọn trống và ca làm việc sẽ được lưu vào lịch sử.'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Hủy'),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFDC3545),
                foregroundColor: Colors.white,
              ),
              onPressed: () async {
                Map<String, dynamic> logData = {
                  'start': _activeShift['start'] ?? '',
                  'end': DateTime.now().toIso8601String(),
                  'date': DateTime.now().toIso8601String().split('T')[0],
                  'revenue': _activeShift['revenue'] ?? 0,
                  'revenueCash': _activeShift['revenueCash'] ?? 0,
                  'revenueTransfer': _activeShift['revenueTransfer'] ?? 0,
                  'timestamp': ServerValue.timestamp,
                };

                await FirebaseService.getShiftLogsRef(widget.storeId).push().set(logData);
                await FirebaseService.getActiveShiftRef(widget.storeId).remove();
                await FirebaseService.getTablesRef(widget.storeId).remove();

                if (!context.mounted) return;
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Đã chốt ca thành công!')),
                );
              },
              child: const Text('CHỐT CA'),
            ),
          ],
        );
      },
    );
  }

  void _generateNewRegCode() {
    String newCode = (10000 + Random().nextInt(90000)).toString();
    FirebaseService.getSettingsRef(widget.storeId).update({'regCode': newCode});
  }

  void _updateDeviceRole(String devKey, String newRole) {
    FirebaseService.getDevicesRef(widget.storeId).child(devKey).update({'role': newRole});
  }

  void _deleteDevice(String devKey) {
    FirebaseService.getDevicesRef(widget.storeId).child(devKey).remove();
  }

  void _saveQR() {
    FirebaseService.getSettingsRef(widget.storeId).update({'qrUrl': _qrUrlController.text.trim()});
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Đã lưu cài đặt QR!')),
    );
  }

  void _updateTotalTables() {
    int? val = int.tryParse(_tablesController.text.trim());
    if (val != null && val > 0) {
      FirebaseService.getSettingsRef(widget.storeId).update({'totalTables': val});
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Đã lưu tổng số bàn: $val bàn')),
      );
    }
  }

  void _showAddProductDialog() {
    final TextEditingController nameController = TextEditingController();
    final TextEditingController priceController = TextEditingController();
    final TextEditingController catController = TextEditingController(text: 'Cà phê');

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Thêm Món Mới'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameController,
                decoration: const InputDecoration(labelText: 'Tên món'),
              ),
              TextField(
                controller: priceController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(labelText: 'Giá (VD: 25000)'),
              ),
              TextField(
                controller: catController,
                decoration: const InputDecoration(labelText: 'Nhóm món'),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Hủy'),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF5D3FD3),
                foregroundColor: Colors.white,
              ),
              onPressed: () {
                String name = nameController.text.trim();
                double? price = double.tryParse(priceController.text.trim());
                String cat = catController.text.trim();

                if (name.isNotEmpty && price != null) {
                  FirebaseService.getMenuRef(widget.storeId).push().set({
                    'name': name,
                    'price': price,
                    'category': cat.isEmpty ? 'Khác' : cat,
                    'soldOut': false,
                  });
                  Navigator.pop(context);
                }
              },
              child: const Text('THÊM MÓN'),
            ),
          ],
        );
      },
    );
  }

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
    bool isShiftActive = _activeShift.isNotEmpty;
    double revenue = (_activeShift['revenue'] ?? 0).toDouble();
    double revenueCash = (_activeShift['revenueCash'] ?? 0).toDouble();
    double revenueTransfer = (_activeShift['revenueTransfer'] ?? 0).toDouble();

    Map<dynamic, dynamic> activeHistory = {};
    if (isShiftActive && _activeShift['history'] != null) {
      activeHistory = _activeShift['history'] as Map<dynamic, dynamic>;
    }

    return Scaffold(
      appBar: AppBar(
        title: Text('⚙️ QUẢN LÝ GIAN HÀNG (${widget.storeId.toUpperCase()})'),
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
            // CA HIỆN TẠI & DOANH THU CA
            Card(
              child: Padding(
                padding: const EdgeInsets.all(12.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('📦 Trạng Thái Ca Đang Mở', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                    const SizedBox(height: 8),
                    if (!isShiftActive)
                      const Text('Chưa mở ca', style: TextStyle(color: Colors.grey))
                    else ...[
                      Text('Thời gian mở: ${_activeShift['start'] ?? ''}', style: const TextStyle(fontSize: 12)),
                      const SizedBox(height: 6),
                      Row(
                        children: [
                          Text('💵 TM: ${revenueCash.toStringAsFixed(0)}đ', style: const TextStyle(color: Colors.green, fontWeight: FontWeight.bold)),
                          const SizedBox(width: 16),
                          Text('💳 CK: ${revenueTransfer.toStringAsFixed(0)}đ', style: const TextStyle(color: Color(0xFF5D3FD3), fontWeight: FontWeight.bold)),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Text('Tổng ca: ${revenue.toStringAsFixed(0)}đ', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFFDC3545))),
                    ],
                    const SizedBox(height: 12),
                    if (!isShiftActive)
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF28A745),
                            foregroundColor: Colors.white,
                          ),
                          onPressed: _startShift,
                          child: const Text('MỞ CA MỚI', style: TextStyle(fontWeight: FontWeight.bold)),
                        ),
                      )
                    else
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFFDC3545),
                            foregroundColor: Colors.white,
                          ),
                          onPressed: _endShift,
                          child: const Text('CHỐT CA (ĐÓNG CA)', style: TextStyle(fontWeight: FontWeight.bold)),
                        ),
                      ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 16),

            // BILL TRONG CA HIỆN TẠI
            if (activeHistory.isNotEmpty) ...[
              const Text('🧾 Bill Trong Ca Hiện Tại', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: activeHistory.length,
                itemBuilder: (context, index) {
                  String billKey = activeHistory.keys.elementAt(index).toString();
                  Map<dynamic, dynamic> bill = activeHistory[billKey] as Map<dynamic, dynamic>;

                  int table = bill['table'] ?? 0;
                  double total = (bill['total'] ?? 0).toDouble();
                  String method = bill['method'] ?? 'cash';

                  return Card(
                    child: ListTile(
                      title: Text('Bàn $table - Total: ${total.toStringAsFixed(0)}đ'),
                      subtitle: Text('Hình thức: ${method == 'transfer' ? '💳 CK' : '💵 TM'}'),
                      trailing: IconButton(
                        icon: const Icon(Icons.delete, color: Colors.red),
                        onPressed: () async {
                          double curRev = (_activeShift['revenue'] ?? 0).toDouble();
                          double curCash = (_activeShift['revenueCash'] ?? 0).toDouble();
                          double curTransfer = (_activeShift['revenueTransfer'] ?? 0).toDouble();

                          Map<String, dynamic> updates = {};
                          updates['stores/${widget.storeId}/active_shift/revenue'] = curRev - total;
                          if (method == 'cash') {
                            updates['stores/${widget.storeId}/active_shift/revenueCash'] = curCash - total;
                          } else {
                            updates['stores/${widget.storeId}/active_shift/revenueTransfer'] = curTransfer - total;
                          }
                          updates['stores/${widget.storeId}/active_shift/history/$billKey'] = null;

                          await FirebaseDatabase.instance.ref().update(updates);
                        },
                      ),
                    ),
                  );
                },
              ),
              const SizedBox(height: 16),
            ],

            // LỊCH SỬ CA ĐÃ CHỐT
            Card(
              child: Padding(
                padding: const EdgeInsets.all(12.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('📜 Lịch Sử Ca Đã Chốt', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                    const SizedBox(height: 8),
                    if (_shiftLogs.isEmpty)
                      const Text('Chưa có ca nào được chốt.', style: TextStyle(color: Colors.grey))
                    else
                      ListView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: _shiftLogs.length,
                        itemBuilder: (context, index) {
                          String logKey = _shiftLogs.keys.elementAt(index).toString();
                          Map<dynamic, dynamic> log = _shiftLogs[logKey] as Map<dynamic, dynamic>;

                          String date = log['date'] ?? '';
                          double rev = (log['revenue'] ?? 0).toDouble();
                          double cash = (log['revenueCash'] ?? 0).toDouble();
                          double transfer = (log['revenueTransfer'] ?? 0).toDouble();

                          return ListTile(
                            contentPadding: EdgeInsets.zero,
                            title: Text('📅 $date - ${rev.toStringAsFixed(0)}đ', style: const TextStyle(fontWeight: FontWeight.bold)),
                            subtitle: Text('TM: ${cash.toStringAsFixed(0)}đ | CK: ${transfer.toStringAsFixed(0)}đ'),
                            trailing: IconButton(
                              icon: const Icon(Icons.delete, color: Colors.red),
                              onPressed: () {
                                FirebaseService.getShiftLogsRef(widget.storeId).child(logKey).remove();
                              },
                            ),
                          );
                        },
                      ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 16),

            // MÃ ĐĂNG KÝ & THIẾT BỊ NHÂN VIÊN (QR CONNECTIONS)
            Card(
              child: Padding(
                padding: const EdgeInsets.all(12.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('📱 Thiết Bị & Kết Nối Nhân Viên (QR / Code)', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                    const SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('Mã đăng ký:', style: TextStyle(fontSize: 12, color: Colors.grey)),
                            Text(_regCode, style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Color(0xFF5D3FD3))),
                          ],
                        ),
                        ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFFCCA352),
                            foregroundColor: Colors.white,
                          ),
                          onPressed: _generateNewRegCode,
                          child: const Text('MÃ MỚI'),
                        ),
                      ],
                    ),
                    const Divider(height: 20),
                    const Text('Danh sách thiết bị kết nối:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                    const SizedBox(height: 8),
                    if (_devices.isEmpty)
                      const Text('Chưa có thiết bị nào đăng ký.', style: TextStyle(color: Colors.grey))
                    else
                      ListView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: _devices.length,
                        itemBuilder: (context, index) {
                          String devKey = _devices.keys.elementAt(index).toString();
                          Map<dynamic, dynamic> dev = _devices[devKey] as Map<dynamic, dynamic>;

                          String name = dev['name'] ?? 'Chưa tên';
                          String role = dev['role'] ?? 'Phục vụ';

                          return ListTile(
                            contentPadding: EdgeInsets.zero,
                            title: Text('👤 $name', style: const TextStyle(fontWeight: FontWeight.bold)),
                            subtitle: DropdownButton<String>(
                              value: role,
                              items: const [
                                DropdownMenuItem(value: 'Phục vụ', child: Text('Phục vụ')),
                                DropdownMenuItem(value: 'Thu ngân', child: Text('Thu ngân')),
                                DropdownMenuItem(value: 'Quản lý', child: Text('Quản lý')),
                              ],
                              onChanged: (newRole) {
                                if (newRole != null) _updateDeviceRole(devKey, newRole);
                              },
                            ),
                            trailing: IconButton(
                              icon: const Icon(Icons.delete, color: Colors.red),
                              onPressed: () => _deleteDevice(devKey),
                            ),
                          );
                        },
                      ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 16),

            // SETTINGS & MENU MANAGEMENT
            Card(
              child: Padding(
                padding: const EdgeInsets.all(12.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('🖼️ Cài Đặt QR Chuyển Khoản & Số Bàn', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                    const SizedBox(height: 10),
                    TextField(
                      controller: _qrUrlController,
                      decoration: const InputDecoration(
                        labelText: 'Link ảnh QR chuyển khoản',
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 8),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF2C3E50),
                          foregroundColor: Colors.white,
                        ),
                        onPressed: _saveQR,
                        child: const Text('LƯU QR'),
                      ),
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: _tablesController,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(
                        labelText: 'Tổng số bàn hiển thị',
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 8),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF5D3FD3),
                          foregroundColor: Colors.white,
                        ),
                        onPressed: _updateTotalTables,
                        child: const Text('LƯU SỐ BÀN'),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 16),

            // MENU MANAGEMENT
            Card(
              child: Padding(
                padding: const EdgeInsets.all(12.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('📝 Quản Lý Menu Món', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                        ElevatedButton.icon(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF5D3FD3),
                            foregroundColor: Colors.white,
                          ),
                          onPressed: _showAddProductDialog,
                          icon: const Icon(Icons.add, size: 16),
                          label: const Text('THÊM MÓN'),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    ListView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: _menuList.length,
                      itemBuilder: (context, index) {
                        ProductModel item = _menuList[index];
                        return ListTile(
                          contentPadding: EdgeInsets.zero,
                          title: Text(item.name, style: TextStyle(fontWeight: FontWeight.bold, decoration: item.soldOut ? TextDecoration.lineThrough : null)),
                          subtitle: Text('Nhóm: ${item.category} | ${item.price.toStringAsFixed(0)}đ'),
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              TextButton(
                                onPressed: () {
                                  FirebaseService.getMenuRef(widget.storeId).child(item.id).update({'soldOut': !item.soldOut});
                                },
                                child: Text(item.soldOut ? 'Mở lại' : 'Báo hết', style: TextStyle(color: item.soldOut ? Colors.green : Colors.orange)),
                              ),
                              IconButton(
                                icon: const Icon(Icons.delete, color: Colors.red),
                                onPressed: () {
                                  FirebaseService.getMenuRef(widget.storeId).child(item.id).remove();
                                },
                              ),
                            ],
                          ),
                        );
                      },
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
