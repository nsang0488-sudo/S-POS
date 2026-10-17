import 'package:flutter/material.dart';
import '../firebase_service.dart';
import '../models/table_model.dart';
import 'store_login_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';

class TableScreen extends StatefulWidget {
  final String storeId;
  final Function(int tableId)? onTableSelected;

  const TableScreen({
    super.key,
    required this.storeId,
    this.onTableSelected,
  });

  @override
  State<TableScreen> createState() => _TableScreenState();
}

class _TableScreenState extends State<TableScreen> {
  Map<String, TableModel> _tablesMap = {};
  int _totalTablesCount = 40;

  @override
  void initState() {
    super.initState();
    _loadStoreSettingsAndTables();
  }

  void _loadStoreSettingsAndTables() {
    FirebaseService.getSettingsRef(widget.storeId).child('totalTables').onValue.listen((event) {
      if (event.snapshot.value != null && mounted) {
        setState(() {
          _totalTablesCount = int.tryParse(event.snapshot.value.toString()) ?? 40;
        });
      }
    });

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

  void _openServeModal(int tableId, bool currentNeedsServing) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text('Báo Bưng Nước Bàn $tableId', textAlign: TextAlign.center),
          content: Row(
            children: [
              Expanded(
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFDC3545),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                  onPressed: () {
                    FirebaseService.getTableRef(widget.storeId, tableId.toString()).update({
                      'needsServing': true,
                    });
                    Navigator.pop(context);
                  },
                  child: const Text('RA MÓN', style: TextStyle(fontWeight: FontWeight.bold)),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.white,
                    foregroundColor: Colors.black,
                    side: const BorderSide(color: Colors.grey),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                  onPressed: () {
                    FirebaseService.getTableRef(widget.storeId, tableId.toString()).update({
                      'needsServing': false,
                    });
                    Navigator.pop(context);
                  },
                  child: const Text('TRỐNG', style: TextStyle(fontWeight: FontWeight.bold)),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Hủy'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('UYÊN COFFEE POS PRO (${widget.storeId.toUpperCase()})'),
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
        padding: const EdgeInsets.all(10.0),
        child: GridView.builder(
          itemCount: _totalTablesCount,
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 4,
            crossAxisSpacing: 10,
            mainAxisSpacing: 10,
            childAspectRatio: 0.95,
          ),
          itemBuilder: (context, index) {
            int tableId = index + 1;
            TableModel? table = _tablesMap[tableId.toString()];

            Color bgColor = Colors.white;
            Color borderColor = const Color(0xFF2C3E50);
            Color textColor = const Color(0xFF2C3E50);

            if (table != null) {
              if (table.status == 'red') {
                bgColor = const Color(0xFFFFB8C0);
                borderColor = const Color(0xFFDC3545);
              } else if (table.status == 'green') {
                bgColor = const Color(0xFFB8E6C1);
                borderColor = const Color(0xFF28A745);
              }
            }

            double totalMoney = 0;
            if (table != null) {
              for (var item in table.items) {
                totalMoney += item.price * item.qty;
              }
            }

            if (totalMoney == 0 && table != null && table.status != 'white') {
              FirebaseService.getTableRef(widget.storeId, tableId.toString()).update({
                'status': 'white',
                'items': null,
                'startTime': null,
              });
            }

            String timeText = '';
            if (table?.startTime != null) {
              DateTime? dt = DateTime.tryParse(table!.startTime!);
              if (dt != null) {
                int mins = DateTime.now().difference(dt).inMinutes;
                if (mins >= 0) timeText = ' - ${mins}p';
              }
            }

            bool needsServing = table?.needsServing ?? false;

            return InkWell(
              onTap: () {
                if (widget.onTableSelected != null) {
                  widget.onTableSelected!(tableId);
                }
              },
              child: Container(
                decoration: BoxDecoration(
                  color: bgColor,
                  border: Border.all(color: borderColor, width: 2),
                  borderRadius: BorderRadius.circular(8),
                ),
                padding: const EdgeInsets.all(4),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('🖨️', style: TextStyle(fontSize: 14)),
                    Text(
                      'Bàn $tableId',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 13,
                        color: textColor,
                      ),
                    ),
                    if (totalMoney > 0)
                      Text(
                        '${totalMoney.toStringAsFixed(0)}đ',
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFFDC3545),
                        ),
                      )
                    else
                      Text(
                        'Trống$timeText',
                        style: TextStyle(fontSize: 10, color: Colors.grey.shade700),
                      ),
                    InkWell(
                      onTap: () => _openServeModal(tableId, needsServing),
                      child: Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(vertical: 3),
                        margin: const EdgeInsets.only(top: 2),
                        decoration: BoxDecoration(
                          color: needsServing ? const Color(0xFFDC3545) : Colors.white.withValues(alpha: 0.6),
                          borderRadius: BorderRadius.circular(4),
                          border: Border.all(
                            color: needsServing ? Colors.transparent : Colors.grey.shade400,
                          ),
                        ),
                        child: Text(
                          needsServing ? 'CẦN BƯNG NƯỚC' : 'TRỐNG',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 9,
                            fontWeight: FontWeight.bold,
                            color: needsServing ? Colors.white : Colors.grey.shade700,
                          ),
                        ),
                      ),
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
