import 'package:firebase_database/firebase_database.dart';

class FirebaseService {
  static final DatabaseReference _db = FirebaseDatabase.instance.ref();

  // 1. Đăng ký gian hàng mới
  static Future<void> registerStore(String storeId, String storeName) async {
    final storeRef = _db.child('stores/$storeId');
    
    final snapshot = await storeRef.child('info').get();
    if (snapshot.exists) {
      throw Exception("Mã gian hàng này đã tồn tại! Vui lòng chọn mã khác.");
    }

    await storeRef.child('info').set({
      'storeName': storeName,
      'createdAt': ServerValue.timestamp,
    });

    // Cài đặt mặc định
    await storeRef.child('settings').set({
      'totalTables': 40,
      'regCode': '12345',
      'qrUrl': '',
    });

    // Menu mặc định
    await storeRef.child('menu').set({
      'm1': {'name': 'Cà phê sữa đá', 'price': 25000, 'category': 'Cà phê', 'soldOut': false},
      'm2': {'name': 'Bạc xỉu', 'price': 30000, 'category': 'Cà phê', 'soldOut': false},
      'm3': {'name': 'Trà đào cam sả', 'price': 35000, 'category': 'Trà trái cây', 'soldOut': false},
    });
  }

  // 2. Kiểm tra tồn tại store
  static Future<bool> checkStoreExists(String storeId) async {
    final snapshot = await _db.child('stores/$storeId/info').get();
    return snapshot.exists;
  }

  // 3. Các hàm lấy tham chiếu dữ liệu (DatabaseReference & Stream)
  static DatabaseReference getStoreRef(String storeId) {
    return _db.child('stores/$storeId');
  }

  static DatabaseReference getTablesRef(String storeId) {
    return _db.child('stores/$storeId/tables');
  }

  static DatabaseReference getTableRef(String storeId, String tableId) {
    return _db.child('stores/$storeId/tables/$tableId');
  }

  static DatabaseReference getMenuRef(String storeId) {
    return _db.child('stores/$storeId/menu');
  }

  static DatabaseReference getActiveShiftRef(String storeId) {
    return _db.child('stores/$storeId/active_shift');
  }

  static DatabaseReference getShiftLogsRef(String storeId) {
    return _db.child('stores/$storeId/shift_logs');
  }

  static DatabaseReference getTasksRef(String storeId) {
    return _db.child('stores/$storeId/tasks');
  }

  static DatabaseReference getDevicesRef(String storeId) {
    return _db.child('stores/$storeId/devices');
  }

  static DatabaseReference getSettingsRef(String storeId) {
    return _db.child('stores/$storeId/settings');
  }

  // Legacy compatibility
  static DatabaseReference getShiftsRef(String storeId) {
    return _db.child('stores/$storeId/shift_logs');
  }

  static Stream<DatabaseEvent> getTablesStream(String storeId) {
    return getTablesRef(storeId).onValue;
  }

  static Stream<DatabaseEvent> getMenuStream(String storeId) {
    return getMenuRef(storeId).onValue;
  }

  static Stream<DatabaseEvent> getShiftStream(String storeId) {
    return getActiveShiftRef(storeId).onValue;
  }
}
