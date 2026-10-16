import '../firebase_service.dart';
import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';
import '../firebase_service.dart';
import '../models/product_model.dart';
import '../models/order_item_model.dart';
import '../models/table_model.dart';

class PosScreen extends StatefulWidget {
  final String storeId;
  final int tableId;

  const PosScreen({super.key, required this.storeId, required this.tableId});

  @override
  State<PosScreen> createState() => _PosScreenState();
}

class _PosScreenState extends State<PosScreen> {
  List<ProductModel> _menuList = [];
  List<OrderItemModel> _currentBillItems = [];
  String _selectedCategory = 'Tất cả';
  List<String> _categories = ['Tất cả'];
  double _totalAmount = 0;
  String _tableStatus = 'white';

  @override
  void initState() {
    super.initState();
    _loadMenu();
    _listenTableData();
  }

  // Lấy Menu từ Firebase theo storeId
  void _loadMenu() {
    FirebaseService.getMenuRef(widget.storeId).onValue.listen((event) {
      if (event.snapshot.value != null && mounted) {
        Map<dynamic, dynamic> data = event.snapshot.value as Map<dynamic, dynamic>;
        List<ProductModel> loaded = [];
        Set<String> catSet = {'Tất cả'};

        data.forEach((key, value) {
          ProductModel item = ProductModel.fromMap(key.toString(), value as Map<dynamic, dynamic>);
          loaded.add(item);
          if (item.category.isNotEmpty) catSet.add(item.category);
        });

        setState(() {
          _menuList = loaded;
          _categories = catSet.toList();
        });
      }
    });
  }

  // Lắng nghe dữ liệu bàn hiện tại theo storeId
  void _listenTableData() {
    FirebaseService.getTableRef(widget.storeId, widget.tableId).onValue.listen((event) {
      if (mounted) {
        if (event.snapshot.value != null) {
          TableModel table = TableModel.fromMap(event.snapshot.value as Map<dynamic, dynamic>);
          double sum = 0;
          for (var item in table.items) {
            sum += item.price * item.qty;
          }
          setState(() {
            _currentBillItems = table.items;
            _totalAmount = sum;
            _tableStatus = table.status;
          });
        } else {
          setState(() {
            _currentBillItems = [];
            _totalAmount = 0;
            _tableStatus = 'white';
          });
        }
      }
    });
  }

  // Thêm món vào bàn và đẩy lên Firebase
  void _addOptionAndConfirm(ProductModel product, String tempType, String note) {
    if (product.soldOut) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Món này đã báo hết, không thể gọi!')),
      );
      return;
    }

    String fullName = '${product.name} ($tempType)${note.isNotEmpty ? ": $note" : ""}';
    List<OrderItemModel> updatedList = List.from(_currentBillItems);
    updatedList.insert(
      0,
      OrderItemModel(fName: fullName, price: product.price, qty: 1, done: false),
    );

    FirebaseService.getTableRef(widget.storeId, widget.tableId).update({
      'items': updatedList.map((e) => e.toMap()).toList(),
      'status': _tableStatus == 'green' ? 'green' : 'white',
      'startTime': DateTime.now().toIso8601String(),
    });
  }

  // Bảng chọn Nóng/Đá và Ghi chú
  void _showAddDialog(ProductModel product) {
    String curType = 'Đá';
    TextEditingController noteController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: Text(product.name, textAlign: TextAlign.center),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: curType == 'Nóng' ? const Color(0xFF5D3FD3) : Colors.grey[200],
                            foregroundColor: curType == 'Nóng' ? Colors.white : Colors.black,
                          ),
                          onPressed: () => setDialogState(() => curType = 'Nóng'),
                          child: const Text('NÓNG'),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: curType == 'Đá' ? const Color(0xFF5D3FD3) : Colors.grey[200],
                            foregroundColor: curType == 'Đá' ? Colors.white : Colors.black,
                          ),
                          onPressed: () => setDialogState(() => curType = 'Đá'),
                          child: const Text('ĐÁ'),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: noteController,
                    decoration: const InputDecoration(
                      hintText: 'Ghi chú...',
                      border: OutlineInputBorder(),
                    ),
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
                    Navigator.pop(context);
                    _addOptionAndConfirm(product, curType, noteController.text.trim());
                  },
                  child: const Text('THÊM VÀO ĐƠN'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  // Xác nhận đơn (Đổi bàn sang màu đỏ)
  void _handleConfirm() {
    FirebaseService.getTableRef(widget.storeId, widget.tableId).update({'status': 'red'});
    Navigator.pop(context);
  }

  // Xong hết (Đổi bàn sang màu xanh)
  void _handleDoneAll() {
    List<OrderItemModel> updatedList = List.from(_currentBillItems);
    for (var item in updatedList) {
      item.done = true;
    }
    FirebaseService.getTableRef(widget.storeId, widget.tableId).update({
      'items': updatedList.map((e) => e.toMap()).toList(),
      'status': 'green',
    });
    Navigator.pop(context);
  }

  // Xử lý Thanh toán và lưu doanh thu vào ca làm việc
  void _handlePayment() {
    if (_totalAmount <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Bàn này chưa có món nào để thanh toán!')),
      );
      return;
    }

    showDialog(
      context: context,
      builder: (context) {
        bool isTransfer = false;
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: Text('THANH TOÁN - BÀN ${widget.tableId}'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text('Tổng tiền: ${_totalAmount.toStringAsFixed(0)}đ', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.purple)),
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      ChoiceChip(
                        label: const Text('Tiền mặt'),
                        selected: !isTransfer,
                        onSelected: (val) => setDialogState(() => isTransfer = false),
                      ),
                      const SizedBox(width: 12),
                      ChoiceChip(
                        label: const Text('Chuyển khoản QR'),
                        selected: isTransfer,
                        onSelected: (val) => setDialogState(() => isTransfer = true),
                      ),
                    ],
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Hủy'),
                ),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.green, foregroundColor: Colors.white),
                  onPressed: () async {
                    // 1. Lưu doanh thu vào node shifts của gian hàng để thống kê cuối ngày
                    DatabaseReference shiftRef = FirebaseService.getShiftsRef(widget.storeId).push();
                    await shiftRef.set({
                      'timestamp': ServerValue.timestamp,
                      'total': _totalAmount,
                      'type': isTransfer ? 'transfer' : 'cash',
                      'tableId': widget.tableId,
                    });

                    // 2. Xóa bàn (trả bàn về trạng thái trống)
                    await FirebaseService.getTableRef(widget.storeId, widget.tableId).remove();

                    if (!context.mounted) return;
                    Navigator.pop(context); // Đóng popup thanh toán
                    Navigator.pop(context); // Trở về màn hình sơ đồ bàn
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Thanh toán thành công!')),
                    );
                  },
                  child: const Text('XÁC NHẬN THU TIỀN'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    List<ProductModel> filteredMenu = _selectedCategory == 'Tất cả'
        ? _menuList
        : _menuList.where((e) => e.category == _selectedCategory).toList();

    return Scaffold(
      appBar: AppBar(
        title: Text('BÀN ${widget.tableId} - Gọi Món'),
        backgroundColor: const Color(0xFF5D3FD3),
        foregroundColor: Colors.white,
      ),
      body: Row(
        children: [
          // BÊN TRÁI: DANH MỤC & LƯỚI MENU MÓN ĂN
          Expanded(
            flex: 6,
            child: Container(
              color: const Color(0xFFF4F6F8),
              child: Row(
                children: [
                  // Sidebar danh mục
                  Container(
                    width: 90,
                    color: Colors.white,
                    child: ListView.builder(
                      itemCount: _categories.length,
                      itemBuilder: (context, index) {
                        String cat = _categories[index];
                        bool isSelected = cat == _selectedCategory;
                        return InkWell(
                          onTap: () => setState(() => _selectedCategory = cat),
                          child: Container(
                            padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 4),
                            decoration: BoxDecoration(
                              color: isSelected ? const Color(0xFF5D3FD3) : Colors.white,
                              border: const Border(bottom: BorderSide(color: Colors.black12)),
                            ),
                            child: Text(
                              cat,
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                                color: isSelected ? Colors.white : Colors.black87,
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                  // Danh sách món
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: GridView.builder(
                        itemCount: filteredMenu.length,
                        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 2,
                          crossAxisSpacing: 8,
                          mainAxisSpacing: 8,
                          childAspectRatio: 1.1,
                        ),
                        itemBuilder: (context, index) {
                          ProductModel product = filteredMenu[index];
                          return InkWell(
                            onTap: () => _showAddDialog(product),
                            child: Container(
                              decoration: BoxDecoration(
                                color: product.soldOut ? Colors.grey[300] : Colors.white,
                                border: Border.all(color: Colors.black12),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Text(
                                    product.name,
                                    textAlign: TextAlign.center,
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 12,
                                      color: product.soldOut ? Colors.grey[600] : Colors.black,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  if (product.soldOut)
                                    const Text('HẾT MÓN', style: TextStyle(color: Colors.red, fontSize: 10, fontWeight: FontWeight.bold))
                                  else
                                    Text(
                                      '${(product.price / 1000).toStringAsFixed(0)}k',
                                      style: const TextStyle(color: Color(0xFF5D3FD3), fontWeight: FontWeight.bold, fontSize: 13),
                                    ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          // BÊN PHẢI: GIỎ HÀNG CỦA BÀN & NÚT THAO TÁC
          Expanded(
            flex: 4,
            child: Container(
              color: Colors.white,
              child: Column(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    color: const Color(0xFF2C3E50),
                    width: double.infinity,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('BÀN ${widget.tableId}', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                        const SizedBox(height: 4),
                        Text(
                          '${_totalAmount.toStringAsFixed(0)}đ',
                          style: const TextStyle(color: Color(0xFFCCA352), fontSize: 20, fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                  ),
                  Expanded(
                    child: ListView.builder(
                      itemCount: _currentBillItems.length,
                      itemBuilder: (context, index) {
                        OrderItemModel item = _currentBillItems[index];
                        return Container(
                          padding: const EdgeInsets.all(10),
                          decoration: const BoxDecoration(
                            border: Border(bottom: BorderSide(color: Colors.black12, style: BorderStyle.solid)),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Expanded(
                                child: Text(
                                  '${item.qty}x ${item.fName}',
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                    color: item.done ? Colors.black : Colors.red,
                                  ),
                                ),
                              ),
                              Text('${(item.price * item.qty).toStringAsFixed(0)}đ', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                            ],
                          ),
                        );
                      },
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: Column(
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: ElevatedButton(
                                style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFDC3545), foregroundColor: Colors.white),
                                onPressed: _handleConfirm,
                                child: const Text('XÁC NHẬN', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                              ),
                            ),
                            const SizedBox(width: 6),
                            Expanded(
                              child: ElevatedButton(
                                style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF28A745), foregroundColor: Colors.white),
                                onPressed: _handleDoneAll,
                                child: const Text('XONG HẾT', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 6),
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF2C3E50), foregroundColor: Colors.white, padding: const EdgeInsets.symmetric(vertical: 14)),
                            onPressed: _handlePayment,
                            child: const Text('THANH TOÁN', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}