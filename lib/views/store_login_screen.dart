import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'main_navigation.dart'; // Màn hình chính sau khi đăng nhập thành công

class StoreLoginScreen extends StatefulWidget {
  const StoreLoginScreen({super.key});

  @override
  State<StoreLoginScreen> createState() => _StoreLoginScreenState();
}

class _StoreLoginScreenState extends State<StoreLoginScreen> {
  // Controller xử lý dữ liệu nhập vào
  final _storeIdController = TextEditingController();
  final _phoneController = TextEditingController();
  final _passwordController = TextEditingController();
  
  bool _isStaffLogin = false; // Phân biệt chế độ Chủ quán hay Nhân viên
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _checkSavedDevice(); // Kiểm tra xem thiết bị đã nhớ đăng nhập từ trước chưa
  }

  // Kiểm tra thiết bị đã lưu thông tin chưa để vào thẳng app
  Future<void> _checkSavedDevice() async {
    final prefs = await SharedPreferences.getInstance();
    final savedStoreId = prefs.getString('saved_store_id');
    
    if (savedStoreId != null && savedStoreId.isNotEmpty) {
      // Nếu đã lưu thiết bị, chuyển thẳng vào màn hình chính với savedStoreId
      if (mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => MainNavigation(storeId: savedStoreId),
          ),
        );
      }
    }
  }

  // Hàm xử lý đăng nhập / đăng ký
  Future<void> _handleLogin() async {
    final storeId = _storeIdController.text.trim();
    
    if (storeId.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Vui lòng nhập mã gian hàng (Store ID)!')),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      // Lưu lại thiết bị để lần sau tự động đăng nhập
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('saved_store_id', storeId);

      // Chuyển vào màn hình quản lý chính của app
      if (mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => MainNavigation(storeId: storeId),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Lỗi đăng nhập: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  void dispose() {
    _storeIdController.dispose();
    _phoneController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Container(
            constraints: const BoxConstraints(maxWidth: 400),
            padding: const EdgeInsets.all(32.0),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 20,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Tiêu đề ứng dụng
                const Text(
                  'UYÊN COFFEE POS',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Colors.brown,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  _isStaffLogin ? 'Đăng nhập nhân viên / Máy trạm' : 'Hệ thống Quản lý & Bán hàng',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                ),
                const SizedBox(height: 32),

                // Ô nhập mã gian hàng (Store ID)
                TextField(
                  controller: _storeIdController,
                  decoration: InputDecoration(
                    labelText: 'Mã cửa hàng (Store ID)',
                    hintText: 'Ví dụ: uyen_coffee_01',
                    prefixIcon: const Icon(Icons.store, color: Colors.brown),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                // Nếu là nhân viên đăng nhập bằng thông tin (SĐT + Mật khẩu)
                if (_isStaffLogin) ...[
                  TextField(
                    controller: _phoneController,
                    keyboardType: TextInputType.phone,
                    decoration: InputDecoration(
                      labelText: 'Số điện thoại',
                      prefixIcon: const Icon(Icons.phone, color: Colors.brown),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: _passwordController,
                    obscureText: true,
                    decoration: InputDecoration(
                      labelText: 'Mật khẩu',
                      prefixIcon: const Icon(Icons.lock, color: Colors.brown),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                ],

                // Nút hành động chính
                ElevatedButton(
                  onPressed: _isLoading ? null : _handleLogin,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.brown,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: _isLoading
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 2,
                          ),
                        )
                      : Text(
                          _isStaffLogin ? 'VÀO LÀM VIỆC' : 'TIẾP TỤC / ĐĂNG NHẬP',
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                ),
                const SizedBox(height: 16),

                // Nút chuyển đổi giữa Chủ quán / Máy trạm và Nhân viên
                TextButton(
                  onPressed: () {
                    setState(() {
                      _isStaffLogin = !_isStaffLogin;
                    });
                  },
                  child: Text(
                    _isStaffLogin
                        ? '← Quay lại đăng nhập Chủ quán / Tạo cửa hàng'
                        : 'Nhân viên mới? Đăng nhập bằng thông tin / Quét QR',
                    style: const TextStyle(color: Colors.brown),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}