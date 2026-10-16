import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';

// Import màn hình đăng nhập đầu tiên từ thư mục views
import 'views/store_login_screen.dart'; 

void main() async {
  // 1. Đảm bảo các widget được bind đầy đủ trước khi gọi async
  WidgetsFlutterBinding.ensureInitialized();

  // 2. Khởi tạo kết nối Firebase với các cấu hình từ file firebase_options.dart
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  // 3. Chạy ứng dụng
  runApp(const SPosApp());
}

class SPosApp extends StatelessWidget {
  const SPosApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'UYÊN COFFEE POS PRO',
      debugShowCheckedModeBanner: false, // Tắt nhãn Debug màu đỏ góc phải
      theme: ThemeData(
        primarySwatch: Colors.blue,
        useMaterial3: true,
      ),
      // Gọi màn hình khởi đầu của ứng dụng
      home: const StoreLoginScreen(), 
    );
  }
}