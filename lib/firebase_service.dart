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

    // Menu mặc định
    await storeRef.child('menu').set({
      'm1': {'name': 'Cà phê sữa đá', 'price': 25000, 'category': 'Cà phê'},
      'm2': {'name': 'Bạc xỉu', 'price': 30000, 'category': 'Cà phê'},
      'm3': {'name': 'Trà đào cam sả', 'price': 35000, 'category': 'Trà trái cây'},
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

  static Stream<DatabaseEvent> getTablesStream(String storeId) {
    return getStoreRef(storeId).child('tables').onValue;
  }

  static Stream<DatabaseEvent> getMenuStream(String storeId) {
    return getStoreRef(storeId).child('menu').onValue;
  }

  static Stream<DatabaseEvent> getShiftStream(String storeId) {
    return getStoreRef(storeId).child('active_shift').onValue;
  }

  // Tương thích các view cũ
  static DatabaseReference getTablesRef(String storeId) {
    return _db.child('stores/$storeId/tables');
  }

  static DatabaseReference getMenuRef(String storeId) {
    return _db.child('stores/$storeId/menu');
  }

  static DatabaseReference getShiftsRef(String storeId) {
    return _db.child('stores/$storeId/shifts');
  }

  static DatabaseReference getTableRef(String storeId, String tableId) {
    return _db.child('stores/$storeId/tables/$tableId');
  }
}