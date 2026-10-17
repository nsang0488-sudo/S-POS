import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';
import '../firebase_service.dart';

class TasksScreen extends StatefulWidget {
  final String storeId;

  const TasksScreen({super.key, required this.storeId});

  @override
  State<TasksScreen> createState() => _TasksScreenState();
}

class _TasksScreenState extends State<TasksScreen> {
  Map<dynamic, dynamic> _allDevices = {};
  Map<dynamic, dynamic> _allTasks = {};
  String? _selectedEmployeeKey;

  final TextEditingController _taskContentController = TextEditingController();
  int _selectedFrequency = 0;
  bool _isImportant = false;

  bool _isManagerView = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  void _loadData() {
    FirebaseService.getDevicesRef(widget.storeId).onValue.listen((event) {
      if (event.snapshot.value != null && mounted) {
        Map<dynamic, dynamic> devs = event.snapshot.value as Map<dynamic, dynamic>;
        setState(() {
          _allDevices = devs;
          if (_selectedEmployeeKey == null && devs.isNotEmpty) {
            _selectedEmployeeKey = devs.keys.first.toString();
          }
        });
      }
    });

    FirebaseService.getTasksRef(widget.storeId).onValue.listen((event) {
      if (event.snapshot.value != null && mounted) {
        setState(() {
          _allTasks = event.snapshot.value as Map<dynamic, dynamic>;
        });
      } else if (mounted) {
        setState(() {
          _allTasks = {};
        });
      }
    });
  }

  void _addTask() {
    String content = _taskContentController.text.trim();
    if (_selectedEmployeeKey == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Vui lòng chọn hoặc thêm nhân viên trước!')),
      );
      return;
    }

    if (content.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Vui lòng nhập nội dung công việc!')),
      );
      return;
    }

    int dueDate = 0;
    if (_selectedFrequency > 0) {
      DateTime now = DateTime.now();
      DateTime endOfDay = DateTime(now.year, now.month, now.day, 23, 59, 59);
      dueDate = endOfDay.millisecondsSinceEpoch + ((_selectedFrequency - 1) * 86400000);
    }

    FirebaseService.getTasksRef(widget.storeId).child(_selectedEmployeeKey!).push().set({
      'text': content,
      'important': _isImportant,
      'frequency': _selectedFrequency,
      'dueDate': dueDate,
      'done': false,
      'assignedAt': DateTime.now().toIso8601String(),
    });

    _taskContentController.clear();
    setState(() {
      _isImportant = false;
      _selectedFrequency = 0;
    });

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Đã phân việc thành công!')),
    );
  }

  void _deleteTask(String empKey, String taskId) {
    FirebaseService.getTasksRef(widget.storeId).child('$empKey/$taskId').remove();
  }

  void _openTransferModal() {
    if (_selectedEmployeeKey == null) return;
    String targetEmpKey = _selectedEmployeeKey!;
    String targetName = _allDevices[targetEmpKey]?['name'] ?? 'Nhân viên';

    String? sourceEmpKey;
    List<String> sourceKeys = _allDevices.keys
        .map((e) => e.toString())
        .where((k) => k != targetEmpKey)
        .toList();

    if (sourceKeys.isNotEmpty) sourceEmpKey = sourceKeys.first;

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: const Text('Nhận việc từ nhân viên khác'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Nhận công việc gán cho: $targetName', style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF5D3FD3))),
                  const SizedBox(height: 12),
                  const Text('Chọn nhân viên nguồn:', style: TextStyle(fontSize: 12)),
                  const SizedBox(height: 6),
                  DropdownButtonFormField<String>(
                    initialValue: sourceEmpKey,
                    decoration: const InputDecoration(border: OutlineInputBorder()),
                    items: sourceKeys.map((k) {
                      String name = _allDevices[k]?['name'] ?? 'NV';
                      return DropdownMenuItem<String>(value: k, child: Text(name));
                    }).toList(),
                    onChanged: (val) => setDialogState(() => sourceEmpKey = val),
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
                    if (sourceEmpKey == null) return;

                    DataSnapshot sourceSnap = await FirebaseService.getTasksRef(widget.storeId)
                        .child(sourceEmpKey!)
                        .get();

                    if (sourceSnap.value != null) {
                      Map<dynamic, dynamic> sourceTasks = sourceSnap.value as Map<dynamic, dynamic>;
                      for (var entry in sourceTasks.entries) {
                        await FirebaseService.getTasksRef(widget.storeId)
                            .child(targetEmpKey)
                            .push()
                            .set(entry.value);
                      }
                      await FirebaseService.getTasksRef(widget.storeId)
                          .child(sourceEmpKey!)
                          .remove();
                    }

                    if (!context.mounted) return;
                    Navigator.pop(context);
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Đã chuyển việc thành công!')),
                    );
                  },
                  child: const Text('XÁC NHẬN CHUYỂN'),
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
    Map<dynamic, dynamic> currentTasks = {};
    if (_selectedEmployeeKey != null && _allTasks[_selectedEmployeeKey] != null) {
      currentTasks = _allTasks[_selectedEmployeeKey] as Map<dynamic, dynamic>;
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('📋 QUẢN LÝ GIAO VIỆC'),
        backgroundColor: const Color(0xFF5D3FD3),
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: Icon(_isManagerView ? Icons.person : Icons.supervisor_account),
            tooltip: _isManagerView ? 'Chuyển sang xem góc nhìn Nhân Viên' : 'Chuyển sang xem Quản Lý',
            onPressed: () => setState(() => _isManagerView = !_isManagerView),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Select employee header
            Card(
              child: Padding(
                padding: const EdgeInsets.all(12.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('Chọn nhân viên:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                        if (_isManagerView)
                          ElevatedButton.icon(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF5D3FD3),
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                            ),
                            onPressed: _openTransferModal,
                            icon: const Icon(Icons.swap_horiz, size: 16),
                            label: const Text('NHẬN VIỆC TỪ...', style: TextStyle(fontSize: 11)),
                          ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    if (_allDevices.isEmpty)
                      const Text('Chưa có nhân viên nào đăng ký thiết bị.', style: TextStyle(color: Colors.grey))
                    else
                      DropdownButtonFormField<String>(
                        initialValue: _selectedEmployeeKey,
                        decoration: const InputDecoration(border: OutlineInputBorder()),
                        items: _allDevices.keys.map((k) {
                          String name = _allDevices[k]?['name'] ?? 'Nhân viên';
                          String role = _allDevices[k]?['role'] ?? 'Phục vụ';
                          return DropdownMenuItem<String>(
                            value: k.toString(),
                            child: Text('👤 $name ($role)'),
                          );
                        }).toList(),
                        onChanged: (val) => setState(() => _selectedEmployeeKey = val),
                      ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 16),

            if (_isManagerView) ...[
              // Add task section
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(12.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Thêm công việc mới', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                      const SizedBox(height: 10),
                      TextField(
                        controller: _taskContentController,
                        decoration: const InputDecoration(
                          hintText: 'Nhập tên việc cần làm...',
                          border: OutlineInputBorder(),
                        ),
                      ),
                      const SizedBox(height: 10),
                      DropdownButtonFormField<int>(
                        initialValue: _selectedFrequency,
                        decoration: const InputDecoration(border: OutlineInputBorder()),
                        items: const [
                          DropdownMenuItem(value: 0, child: Text('Tần suất: Một lần (Không lặp lại)')),
                          DropdownMenuItem(value: 1, child: Text('Tần suất: Hằng ngày')),
                          DropdownMenuItem(value: 2, child: Text('Tần suất: 2 ngày / lần')),
                          DropdownMenuItem(value: 7, child: Text('Tần suất: Hàng tuần')),
                        ],
                        onChanged: (val) => setState(() => _selectedFrequency = val ?? 0),
                      ),
                      const SizedBox(height: 10),
                      CheckboxListTile(
                        contentPadding: EdgeInsets.zero,
                        title: const Text(
                          'Việc quan trọng (Luôn đỏ)',
                          style: TextStyle(color: Color(0xFFDC3545), fontWeight: FontWeight.bold),
                        ),
                        value: _isImportant,
                        onChanged: (val) => setState(() => _isImportant = val ?? false),
                      ),
                      const SizedBox(height: 10),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF5D3FD3),
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 14),
                          ),
                          onPressed: _addTask,
                          child: const Text('PHÂN VIỆC', style: TextStyle(fontWeight: FontWeight.bold)),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],

            const SizedBox(height: 16),
            const Text('Danh sách công việc', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),

            if (currentTasks.isEmpty)
              const Padding(
                padding: EdgeInsets.all(20.0),
                child: Center(
                  child: Text('🎉 Không có việc nào cần xử lý lúc này.', style: TextStyle(color: Colors.grey)),
                ),
              )
            else
              ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: currentTasks.length,
                itemBuilder: (context, index) {
                  String taskId = currentTasks.keys.elementAt(index).toString();
                  Map<dynamic, dynamic> task = currentTasks[taskId] as Map<dynamic, dynamic>;

                  bool done = task['done'] ?? false;
                  bool important = task['important'] ?? false;
                  String text = task['text'] ?? '';
                  int dueDate = task['dueDate'] ?? 0;

                  bool isOverdue = dueDate > 0 && DateTime.now().millisecondsSinceEpoch > dueDate && !done;

                  Color textColor = Colors.black;
                  if (important || isOverdue) textColor = const Color(0xFFDC3545);
                  if (done) textColor = Colors.grey;

                  return Card(
                    child: ListTile(
                      leading: Checkbox(
                        value: done,
                        onChanged: (val) {
                          if (_selectedEmployeeKey == null) return;
                          FirebaseService.getTasksRef(widget.storeId)
                              .child('$_selectedEmployeeKey/$taskId')
                              .update({'done': val ?? false});
                        },
                      ),
                      title: Text(
                        '$text ${isOverdue ? "(Quá hạn)" : ""}',
                        style: TextStyle(
                          color: textColor,
                          fontWeight: (important || isOverdue) ? FontWeight.bold : FontWeight.normal,
                          decoration: done ? TextDecoration.lineThrough : null,
                        ),
                      ),
                      trailing: _isManagerView
                          ? IconButton(
                              icon: const Icon(Icons.delete, color: Colors.red),
                              onPressed: () => _deleteTask(_selectedEmployeeKey!, taskId),
                            )
                          : null,
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
