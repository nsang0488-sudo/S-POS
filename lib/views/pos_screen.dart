import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';
import '../firebase_service.dart';
import '../models/product_model.dart';
import '../models/order_item_model.dart';
import '../models/table_model.dart';

class PosScreen extends StatefulWidget {
  final String storeId;
  final int? tableId;
  final VoidCallback? onBackToTables;
  final VoidCallback? onClearTable;

  const PosScreen({
    super.key,
    required this.storeId,
    this.tableId,
    this.onBackToTables,
    this.onClearTable,
  });

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

  Map<dynamic, dynamic> _currentShiftData = {};
  Map<String, TableModel> _allTablesData = {};
  String _qrUrl = '';

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  @override
  void didUpdateWidget(covariant PosScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.tableId != widget.tableId && widget.tableId != null) {
      _listenTableData();
    }
  }

  void _loadData() {
    // Menu
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

    // Active Shift
    FirebaseService.getActiveShiftRef(widget.storeId).onValue.listen((event) {
      if (event.snapshot.value != null && mounted) {
        setState(() {
          _currentShiftData = event.snapshot.value as Map<dynamic, dynamic>;
        });
      } else if (mounted) {
        setState(() {
          _currentShiftData = {};
        });
      }
    });

    // All Tables (for move / merge)
    FirebaseService.getTablesRef(widget.storeId).onValue.listen((event) {
      if (event.snapshot.value != null && mounted) {
        Map<dynamic, dynamic> data = event.snapshot.value as Map<dynamic, dynamic>;
        Map<String, TableModel> map = {};
        data.forEach((k, v) {
          map[k.toString()] = TableModel.fromMap(v as Map<dynamic, dynamic>);
        });
        setState(() {
          _allTablesData = map;
        });
      }
    });

    // Settings / QR
    FirebaseService.getSettingsRef(widget.storeId).child('qrUrl').onValue.listen((event) {
      if (event.snapshot.value != null && mounted) {
        setState(() {
          _qrUrl = event.snapshot.value.toString();
        });
      }
    });

    if (widget.tableId != null) {
      _listenTableData();
    }
  }

  void _listenTableData() {
    if (widget.tableId == null) return;
    FirebaseService.getTableRef(widget.storeId, widget.tableId.toString()).onValue.listen((event) {
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

  void _addOptionAndConfirm(ProductModel product, String tempType, String note) {
    if (widget.tableId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Vui lòng chọn bàn trước!')),
      );
      return;
    }

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

    FirebaseService.getTableRef(widget.storeId, widget.tableId.toString()).update({
      'items': updatedList.map((e) => e.toMap()).toList(),
      'status': _tableStatus == 'green' ? 'green' : 'white',
      'startTime': DateTime.now().toIso8601String(),
    });
  }

  void _showAddDialog(ProductModel product) {
    if (widget.tableId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Vui lòng chọn bàn trước!')),
      );
      return;
    }

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
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF5D3FD3),
                    foregroundColor: Colors.white,
                  ),
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

  void _handleConfirm() {
    if (widget.tableId == null) return;
    FirebaseService.getTableRef(widget.storeId, widget.tableId.toString()).update({'status': 'red'});
    if (widget.onBackToTables != null) widget.onBackToTables!();
  }

  void _handleDoneAll() {
    if (widget.tableId == null) return;
    List<OrderItemModel> updatedList = List.from(_currentBillItems);
    for (var item in updatedList) {
      item.done = true;
    }
    FirebaseService.getTableRef(widget.storeId, widget.tableId.toString()).update({
      'items': updatedList.map((e) => e.toMap()).toList(),
      'status': 'green',
    });
    if (widget.onBackToTables != null) widget.onBackToTables!();
  }

  void _openQtyEditDialog(int index) {
    OrderItemModel item = _currentBillItems[index];
    int qtyVal = item.qty;

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: const Text('Sửa món', textAlign: TextAlign.center),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    item.fName,
                    style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF5D3FD3), fontSize: 16),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 20),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      OutlinedButton(
                        onPressed: () {
                          if (qtyVal > 1) setDialogState(() => qtyVal--);
                        },
                        child: const Text('-', style: TextStyle(fontSize: 24)),
                      ),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 20),
                        child: Text('$qtyVal', style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold)),
                      ),
                      OutlinedButton(
                        onPressed: () => setDialogState(() => qtyVal++),
                        child: const Text('+', style: TextStyle(fontSize: 24)),
                      ),
                    ],
                  ),
                ],
              ),
              actionsAlignment: MainAxisAlignment.center,
              actions: [
                Column(
                  children: [
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF5D3FD3),
                          foregroundColor: Colors.white,
                        ),
                        onPressed: () {
                          List<OrderItemModel> updatedList = List.from(_currentBillItems);
                          updatedList[index].qty = qtyVal;
                          updatedList[index].done = true;
                          FirebaseService.getTableRef(widget.storeId, widget.tableId.toString()).update({
                            'items': updatedList.map((e) => e.toMap()).toList(),
                          });
                          Navigator.pop(context);
                        },
                        child: const Text('XONG', style: TextStyle(fontWeight: FontWeight.bold)),
                      ),
                    ),
                    const SizedBox(height: 8),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFFDC3545),
                          foregroundColor: Colors.white,
                        ),
                        onPressed: () {
                          List<OrderItemModel> updatedList = List.from(_currentBillItems);
                          updatedList.removeAt(index);
                          if (updatedList.isEmpty) {
                            FirebaseService.getTableRef(widget.storeId, widget.tableId.toString()).remove();
                          } else {
                            FirebaseService.getTableRef(widget.storeId, widget.tableId.toString()).update({
                              'items': updatedList.map((e) => e.toMap()).toList(),
                            });
                          }
                          Navigator.pop(context);
                        },
                        child: const Text('XÓA MÓN', style: TextStyle(fontWeight: FontWeight.bold)),
                      ),
                    ),
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text('Đóng'),
                    ),
                  ],
                ),
              ],
            );
          },
        );
      },
    );
  }

  void _openMoveTableDialog() {
    if (widget.tableId == null) return;
    int sourceTable = widget.tableId!;
    int targetTable = sourceTable == 1 ? 2 : 1;
    String moveMode = 'move'; // 'move' or 'merge'

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: const Text('Chuyển / Gộp bàn'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Thao tác cho Bàn $sourceTable:'),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: moveMode == 'move' ? const Color(0xFF5D3FD3) : Colors.grey[200],
                            foregroundColor: moveMode == 'move' ? Colors.white : Colors.black,
                          ),
                          onPressed: () => setDialogState(() => moveMode = 'move'),
                          child: const Text('CHUYỂN BÀN'),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: moveMode == 'merge' ? const Color(0xFF5D3FD3) : Colors.grey[200],
                            foregroundColor: moveMode == 'merge' ? Colors.white : Colors.black,
                          ),
                          onPressed: () => setDialogState(() => moveMode = 'merge'),
                          child: const Text('GỘP BÀN'),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  DropdownButtonFormField<int>(
                    initialValue: targetTable,
                    decoration: const InputDecoration(
                      labelText: 'Đến bàn:',
                      border: OutlineInputBorder(),
                    ),
                    items: List.generate(40, (index) => index + 1)
                        .where((i) => i != sourceTable)
                        .map((i) => DropdownMenuItem<int>(
                              value: i,
                              child: Text('Bàn $i'),
                            ))
                        .toList(),
                    onChanged: (val) {
                      if (val != null) setDialogState(() => targetTable = val);
                    },
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
                  onPressed: () async {
                    if (moveMode == 'move') {
                      DataSnapshot sourceSnap = await FirebaseService.getTableRef(
                        widget.storeId,
                        sourceTable.toString(),
                      ).get();

                      if (sourceSnap.value != null) {
                        await FirebaseService.getTableRef(
                          widget.storeId,
                          targetTable.toString(),
                        ).set(sourceSnap.value);
                        await FirebaseService.getTableRef(
                          widget.storeId,
                          sourceTable.toString(),
                        ).remove();
                      }
                    } else {
                      // Merge
                      List<OrderItemModel> sourceItems = _currentBillItems;
                      TableModel? targetModel = _allTablesData[targetTable.toString()];
                      List<OrderItemModel> targetItems = targetModel?.items ?? [];

                      List<OrderItemModel> merged = [...targetItems, ...sourceItems];
                      String status = (_tableStatus == 'red' || targetModel?.status == 'red')
                          ? 'red'
                          : 'white';

                      await FirebaseService.getTableRef(widget.storeId, targetTable.toString()).set({
                        'items': merged.map((e) => e.toMap()).toList(),
                        'startTime': DateTime.now().toIso8601String(),
                        'status': status,
                      });
                      await FirebaseService.getTableRef(widget.storeId, sourceTable.toString()).remove();
                    }

                    if (!context.mounted) return;
                    Navigator.pop(context);
                    if (widget.onBackToTables != null) widget.onBackToTables!();
                  },
                  child: const Text('XÁC NHẬN'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  void _handlePayment() {
    if (widget.tableId == null || _totalAmount <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Bàn này chưa có món nào để thanh toán!')),
      );
      return;
    }

    TextEditingController cashInController = TextEditingController();
    double cashChange = 0;

    showDialog(
      context: context,
      builder: (context) {
        bool isTransfer = false;
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: const Text('Thanh toán', textAlign: TextAlign.center),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'Tổng: ${_totalAmount.toStringAsFixed(0)}đ',
                      style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Color(0xFFDC3545)),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: !isTransfer ? const Color(0xFF5D3FD3) : Colors.grey[200],
                              foregroundColor: !isTransfer ? Colors.white : Colors.black,
                            ),
                            onPressed: () => setDialogState(() => isTransfer = false),
                            child: const Text('TIỀN MẶT'),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: isTransfer ? const Color(0xFF5D3FD3) : Colors.grey[200],
                              foregroundColor: isTransfer ? Colors.white : Colors.black,
                            ),
                            onPressed: () => setDialogState(() => isTransfer = true),
                            child: const Text('CHUYỂN KHOẢN'),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    if (!isTransfer) ...[
                      TextField(
                        controller: cashInController,
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(
                          labelText: 'Khách đưa...',
                          border: OutlineInputBorder(),
                        ),
                        onChanged: (val) {
                          double cashIn = double.tryParse(val) ?? 0;
                          setDialogState(() {
                            cashChange = cashIn - _totalAmount;
                          });
                        },
                      ),
                      const SizedBox(height: 12),
                      Text(
                        'Thối: ${cashChange > 0 ? cashChange.toStringAsFixed(0) : 0}đ',
                        style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF28A745)),
                      ),
                    ] else ...[
                      if (_qrUrl.isNotEmpty)
                        Padding(
                          padding: const EdgeInsets.all(8.0),
                          child: Image.network(
                            _qrUrl,
                            height: 180,
                            errorBuilder: (_, __, ___) => const Text('Không tải được ảnh QR'),
                          ),
                        )
                      else
                        const Text('Chưa cài đặt Link QR chuyển khoản'),
                    ],
                  ],
                ),
              ),
              actions: [
                Column(
                  children: [
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF2C3E50),
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                        ),
                        onPressed: () async {
                          double curRev = (_currentShiftData['revenue'] ?? 0).toDouble();
                          double curCash = (_currentShiftData['revenueCash'] ?? 0).toDouble();
                          double curTransfer = (_currentShiftData['revenueTransfer'] ?? 0).toDouble();

                          double newRev = curRev + _totalAmount;
                          double newCash = isTransfer ? curCash : (curCash + _totalAmount);
                          double newTransfer = isTransfer ? (curTransfer + _totalAmount) : curTransfer;

                          String billKey = DateTime.now().millisecondsSinceEpoch.toString();

                          Map<String, dynamic> billData = {
                            'table': widget.tableId,
                            'total': _totalAmount,
                            'method': isTransfer ? 'transfer' : 'cash',
                            'time': DateTime.now().toIso8601String(),
                            'items': _currentBillItems.map((e) => e.toMap()).toList(),
                          };

                          Map<String, dynamic> updates = {};
                          updates['stores/${widget.storeId}/active_shift/revenue'] = newRev;
                          updates['stores/${widget.storeId}/active_shift/revenueCash'] = newCash;
                          updates['stores/${widget.storeId}/active_shift/revenueTransfer'] = newTransfer;
                          updates['stores/${widget.storeId}/active_shift/history/$billKey'] = billData;
                          updates['stores/${widget.storeId}/tables/${widget.tableId}'] = null;

                          await FirebaseDatabase.instance.ref().update(updates);

                          if (!context.mounted) return;
                          Navigator.pop(context);
                          if (widget.onClearTable != null) widget.onClearTable!();
                          if (widget.onBackToTables != null) widget.onBackToTables!();
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Thanh toán hoàn tất!')),
                          );
                        },
                        child: const Text('HOÀN TẤT', style: TextStyle(fontWeight: FontWeight.bold)),
                      ),
                    ),
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text('Hủy'),
                    ),
                  ],
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
    if (widget.tableId == null) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('GỌI MÓN (POS)'),
          backgroundColor: const Color(0xFF5D3FD3),
          foregroundColor: Colors.white,
        ),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.table_restaurant, size: 64, color: Colors.grey),
              const SizedBox(height: 16),
              const Text(
                'Chưa chọn bàn nào để gọi món!',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF5D3FD3),
                  foregroundColor: Colors.white,
                ),
                onPressed: widget.onBackToTables,
                child: const Text('CHỌN BÀN NGAY'),
              ),
            ],
          ),
        ),
      );
    }

    List<ProductModel> filteredMenu = _selectedCategory == 'Tất cả'
        ? _menuList
        : _menuList.where((e) => e.category == _selectedCategory).toList();

    return Scaffold(
      appBar: AppBar(
        title: Text('UYÊN COFFEE POS PRO (${widget.storeId.toUpperCase()})'),
        backgroundColor: const Color(0xFF5D3FD3),
        foregroundColor: Colors.white,
        actions: [
          TextButton.icon(
            style: TextButton.styleFrom(foregroundColor: Colors.white),
            onPressed: widget.onBackToTables,
            icon: const Icon(Icons.arrow_back),
            label: const Text('ĐỔI BÀN'),
          ),
        ],
      ),
      body: Row(
        children: [
          // BÊN TRÁI: DANH MỤC & MENU MÓN
          Expanded(
            flex: 55,
            child: Container(
              color: const Color(0xFFF4F6F8),
              child: Row(
                children: [
                  // Sidebar danh mục
                  Container(
                    width: 80,
                    color: Colors.white,
                    child: ListView.builder(
                      itemCount: _categories.length,
                      itemBuilder: (context, index) {
                        String cat = _categories[index];
                        bool isSelected = cat == _selectedCategory;
                        return InkWell(
                          onTap: () => setState(() => _selectedCategory = cat),
                          child: Container(
                            padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 4),
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
                                color: isSelected ? Colors.white : const Color(0xFF2C3E50),
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                  // Lưới món ăn
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
                                color: product.soldOut ? const Color(0xFFE9ECEF) : Colors.white,
                                border: Border.all(color: const Color(0xFF1C2833)),
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
                                      color: product.soldOut ? Colors.grey : Colors.black,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  if (product.soldOut)
                                    const Text('HẾT MÓN', style: TextStyle(color: Colors.red, fontSize: 11, fontWeight: FontWeight.bold))
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

          // BÊN PHẢI: BILL MÓN TRÊN CÙNG & CÁC NÚT ĐIỀU KHIỂN
          Expanded(
            flex: 45,
            child: Container(
              color: Colors.white,
              child: Column(
                children: [
                  // Thanh thông tin bàn & tổng tiền trên cùng
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                    color: const Color(0xFF2C3E50),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'BÀN ${widget.tableId}',
                              style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14),
                            ),
                            Text(
                              '${_totalAmount.toStringAsFixed(0)}đ',
                              style: const TextStyle(color: Color(0xFFCCA352), fontSize: 18, fontWeight: FontWeight.bold),
                            ),
                          ],
                        ),
                        ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.white.withValues(alpha: 0.2),
                            foregroundColor: Colors.white,
                            side: const BorderSide(color: Colors.white38),
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          ),
                          onPressed: _openMoveTableDialog,
                          child: const Text('CHUYỂN / GỘP', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold)),
                        ),
                      ],
                    ),
                  ),

                  // Danh sách các món trong bill của bàn
                  Expanded(
                    child: ListView.builder(
                      itemCount: _currentBillItems.length,
                      itemBuilder: (context, index) {
                        OrderItemModel item = _currentBillItems[index];
                        return InkWell(
                          onTap: () => _openQtyEditDialog(index),
                          child: Container(
                            padding: const EdgeInsets.all(10),
                            decoration: const BoxDecoration(
                              border: Border(bottom: BorderSide(color: Colors.black12)),
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
                                      color: item.done ? Colors.black : const Color(0xFFDC3545),
                                    ),
                                  ),
                                ),
                                Text(
                                  '${(item.price * item.qty).toStringAsFixed(0)}đ',
                                  style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                  ),

                  // Control Buttons
                  Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: Column(
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: ElevatedButton(
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: const Color(0xFFDC3545),
                                  foregroundColor: Colors.white,
                                  padding: const EdgeInsets.symmetric(vertical: 12),
                                ),
                                onPressed: _handleConfirm,
                                child: const Text('XÁC NHẬN', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: ElevatedButton(
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: const Color(0xFF28A745),
                                  foregroundColor: Colors.white,
                                  padding: const EdgeInsets.symmetric(vertical: 12),
                                ),
                                onPressed: _handleDoneAll,
                                child: const Text('XONG HẾT', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF2C3E50),
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 14),
                            ),
                            onPressed: _handlePayment,
                            child: const Text('THANH TOÁN', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
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
