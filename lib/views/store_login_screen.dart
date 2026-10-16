import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'main_navigation.dart';

enum AuthMode { ownerLogin, ownerRegister, staffLogin, staffRegisterWithQR }

class StoreLoginScreen extends StatefulWidget {
  const StoreLoginScreen({super.key});

  @override
  State<StoreLoginScreen> createState() => _StoreLoginScreenState();
}

class _StoreLoginScreenState extends State<StoreLoginScreen> {
  AuthMode _authMode = AuthMode.ownerLogin;

  // Controllers cho Owner/Workstation
  final _phoneController = TextEditingController();
  final _passwordController = TextEditingController();
  final _storeNameController = TextEditingController();
  final _addressController = TextEditingController();
  final _emailController = TextEditingController();

  // Controllers cho Staff
  final _staffNameController = TextEditingController();
  final _qrStoreCodeController = TextEditingController();

  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _checkSavedDevice();
  }

  Future<void> _checkSavedDevice() async {
    final prefs = await SharedPreferences.getInstance();
    final savedStoreId = prefs.getString('saved_store_id');
    final savedUserRole = prefs.getString('saved_user_role');

    if (savedStoreId != null && savedStoreId.isNotEmpty) {
      if (mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => MainNavigation(
              storeId: savedStoreId,
              userRole: savedUserRole ?? 'owner',
            ),
          ),
        );
      }
    }
  }

  Future<void> _saveSessionAndNavigate(String storeId, String role) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('saved_store_id', storeId);
    await prefs.setString('saved_user_role', role);

    if (mounted) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (context) => MainNavigation(
            storeId: storeId,
            userRole: role,
          ),
        ),
      );
    }
  }

  void _handleForgotPassword() {
    final emailController = TextEditingController();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Quên mật khẩu'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Nhập email đăng ký của gian hàng để nhận mã OTP khôi phục mật khẩu:'),
            const SizedBox(height: 12),
            TextField(
              controller: emailController,
              keyboardType: TextInputType.emailAddress,
              decoration: const InputDecoration(
                labelText: 'Email',
                prefixIcon: Icon(Icons.email),
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
              backgroundColor: Colors.brown,
              foregroundColor: Colors.white,
            ),
            onPressed: () {
              final email = emailController.text.trim();
              if (email.isEmpty || !email.contains('@')) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Vui lòng nhập email hợp lệ!')),
                );
                return;
              }
              Navigator.pop(context);
              _showOtpVerificationDialog(email);
            },
            child: const Text('GỬI OTP'),
          ),
        ],
      ),
    );
  }

  void _showOtpVerificationDialog(String email) {
    final otpController = TextEditingController();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Xác thực OTP'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Mã OTP đã được gửi tới $email. Vui lòng kiểm tra hộp thư.'),
            const SizedBox(height: 12),
            TextField(
              controller: otpController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'Mã OTP (6 chữ số)',
                prefixIcon: Icon(Icons.security),
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
              backgroundColor: Colors.brown,
              foregroundColor: Colors.white,
            ),
            onPressed: () {
              if (otpController.text.trim().length < 4) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Mã OTP không hợp lệ!')),
                );
                return;
              }
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Mã OTP chính xác. Mật khẩu tạm thời đã gửi qua email!')),
              );
            },
            child: const Text('XÁC NHẬN'),
          ),
        ],
      ),
    );
  }

  void _simulateQRScan() {
    final qrController = TextEditingController(text: _qrStoreCodeController.text);
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Quét mã QR gian hàng'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.qr_code_scanner, size: 80, color: Colors.brown),
            const SizedBox(height: 12),
            const Text(
              'Quét QR trong phần Quản lý kết nối từ máy chủ / tài khoản chủ quán, hoặc nhập mã QR tay:',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 13),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: qrController,
              decoration: const InputDecoration(
                labelText: 'Mã QR / Cửa hàng',
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
              backgroundColor: Colors.brown,
              foregroundColor: Colors.white,
            ),
            onPressed: () {
              if (qrController.text.trim().isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Vui lòng quét hoặc nhập mã QR!')),
                );
                return;
              }
              setState(() {
                _qrStoreCodeController.text = qrController.text.trim();
              });
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('Đã nhận diện mã gian hàng: ${qrController.text.trim()}')),
              );
            },
            child: const Text('XÁC NHẬN MÃ QR'),
          ),
        ],
      ),
    );
  }

  Future<void> _handleSubmit() async {
    final phone = _phoneController.text.trim();
    final password = _passwordController.text.trim();

    if (_authMode == AuthMode.ownerLogin) {
      if (phone.isEmpty || password.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Vui lòng nhập số điện thoại và mật khẩu!')),
        );
        return;
      }
      setState(() => _isLoading = true);
      await Future.delayed(const Duration(milliseconds: 500));
      // Dùng SĐT làm storeId mặc định nếu chưa gán cụ thể
      final storeId = 'store_$phone';
      await _saveSessionAndNavigate(storeId, 'owner');
    } else if (_authMode == AuthMode.ownerRegister) {
      final storeName = _storeNameController.text.trim();
      final address = _addressController.text.trim();
      final email = _emailController.text.trim();

      if (phone.isEmpty || password.isEmpty || storeName.isEmpty || address.isEmpty || email.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Vui lòng điền đầy đủ tất cả các thông tin!')),
        );
        return;
      }
      setState(() => _isLoading = true);
      await Future.delayed(const Duration(milliseconds: 500));
      final storeId = 'store_$phone';
      await _saveSessionAndNavigate(storeId, 'owner');
    } else if (_authMode == AuthMode.staffLogin) {
      if (phone.isEmpty || password.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Vui lòng nhập SĐT và mật khẩu nhân viên!')),
        );
        return;
      }
      setState(() => _isLoading = true);
      await Future.delayed(const Duration(milliseconds: 500));
      final storeId = 'store_demo';
      await _saveSessionAndNavigate(storeId, 'staff');
    } else if (_authMode == AuthMode.staffRegisterWithQR) {
      final staffName = _staffNameController.text.trim();
      final qrCode = _qrStoreCodeController.text.trim();

      if (qrCode.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Vui lòng quét QR kết nối gian hàng trước!')),
        );
        return;
      }
      if (staffName.isEmpty || phone.isEmpty || password.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Vui lòng nhập Tên, SĐT và Mật khẩu nhân viên!')),
        );
        return;
      }
      setState(() => _isLoading = true);
      await Future.delayed(const Duration(milliseconds: 500));
      await _saveSessionAndNavigate(qrCode, 'staff');
    }
  }

  @override
  void dispose() {
    _phoneController.dispose();
    _passwordController.dispose();
    _storeNameController.dispose();
    _addressController.dispose();
    _emailController.dispose();
    _staffNameController.dispose();
    _qrStoreCodeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    bool isStaff = (_authMode == AuthMode.staffLogin || _authMode == AuthMode.staffRegisterWithQR);

    return Scaffold(
      backgroundColor: Colors.grey[100],
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Container(
            constraints: const BoxConstraints(maxWidth: 420),
            padding: const EdgeInsets.all(28.0),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.05),
                  blurRadius: 20,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Text(
                  'UYÊN COFFEE POS',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Colors.brown,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  isStaff ? 'Đăng nhập dành cho Nhân viên Order' : 'Đăng nhập Chủ quán & Máy trạm',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 13, color: Colors.grey[600]),
                ),
                const SizedBox(height: 20),

                // Chọn vai trò: Chủ quán / Máy trạm <-> Nhân viên Order
                SegmentedButton<bool>(
                  segments: const [
                    ButtonSegment<bool>(
                      value: false,
                      label: Text('Chủ quán / Trạm'),
                      icon: Icon(Icons.store),
                    ),
                    ButtonSegment<bool>(
                      value: true,
                      label: Text('Nhân viên'),
                      icon: Icon(Icons.person),
                    ),
                  ],
                  selected: {isStaff},
                  onSelectionChanged: (Set<bool> newSelection) {
                    setState(() {
                      if (newSelection.first) {
                        _authMode = AuthMode.staffLogin;
                      } else {
                        _authMode = AuthMode.ownerLogin;
                      }
                    });
                  },
                ),
                const SizedBox(height: 20),

                // Form theo từng chế độ
                if (_authMode == AuthMode.ownerLogin) ...[
                  TextField(
                    controller: _phoneController,
                    keyboardType: TextInputType.phone,
                    decoration: InputDecoration(
                      labelText: 'Số điện thoại',
                      prefixIcon: const Icon(Icons.phone, color: Colors.brown),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
                  const SizedBox(height: 14),
                  TextField(
                    controller: _passwordController,
                    obscureText: true,
                    decoration: InputDecoration(
                      labelText: 'Mật khẩu',
                      prefixIcon: const Icon(Icons.lock, color: Colors.brown),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
                  Align(
                    alignment: Alignment.centerRight,
                    child: TextButton(
                      onPressed: _handleForgotPassword,
                      child: const Text('Quên mật khẩu?', style: TextStyle(color: Colors.brown)),
                    ),
                  ),
                ] else if (_authMode == AuthMode.ownerRegister) ...[
                  TextField(
                    controller: _phoneController,
                    keyboardType: TextInputType.phone,
                    decoration: InputDecoration(
                      labelText: 'Số điện thoại',
                      prefixIcon: const Icon(Icons.phone, color: Colors.brown),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _passwordController,
                    obscureText: true,
                    decoration: InputDecoration(
                      labelText: 'Mật khẩu',
                      prefixIcon: const Icon(Icons.lock, color: Colors.brown),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _storeNameController,
                    decoration: InputDecoration(
                      labelText: 'Tên cửa hàng',
                      prefixIcon: const Icon(Icons.storefront, color: Colors.brown),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _addressController,
                    decoration: InputDecoration(
                      labelText: 'Địa chỉ cửa hàng',
                      prefixIcon: const Icon(Icons.location_on, color: Colors.brown),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _emailController,
                    keyboardType: TextInputType.emailAddress,
                    decoration: InputDecoration(
                      labelText: 'Email liên hệ',
                      prefixIcon: const Icon(Icons.email, color: Colors.brown),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
                  const SizedBox(height: 16),
                ] else if (_authMode == AuthMode.staffLogin) ...[
                  TextField(
                    controller: _phoneController,
                    keyboardType: TextInputType.phone,
                    decoration: InputDecoration(
                      labelText: 'Số điện thoại nhân viên',
                      prefixIcon: const Icon(Icons.phone, color: Colors.brown),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
                  const SizedBox(height: 14),
                  TextField(
                    controller: _passwordController,
                    obscureText: true,
                    decoration: InputDecoration(
                      labelText: 'Mật khẩu',
                      prefixIcon: const Icon(Icons.lock, color: Colors.brown),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
                  const SizedBox(height: 16),
                ] else if (_authMode == AuthMode.staffRegisterWithQR) ...[
                  OutlinedButton.icon(
                    onPressed: _simulateQRScan,
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      side: const BorderSide(color: Colors.brown),
                    ),
                    icon: const Icon(Icons.qr_code_scanner, color: Colors.brown),
                    label: Text(
                      _qrStoreCodeController.text.isEmpty
                          ? 'Scan mã QR từ Chủ quán / Máy chủ'
                          : 'Đã kết nối mã: ${_qrStoreCodeController.text}',
                      style: const TextStyle(color: Colors.brown, fontWeight: FontWeight.bold),
                    ),
                  ),
                  const SizedBox(height: 14),
                  TextField(
                    controller: _staffNameController,
                    decoration: InputDecoration(
                      labelText: 'Tên nhân viên',
                      prefixIcon: const Icon(Icons.person, color: Colors.brown),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _phoneController,
                    keyboardType: TextInputType.phone,
                    decoration: InputDecoration(
                      labelText: 'Số điện thoại',
                      prefixIcon: const Icon(Icons.phone, color: Colors.brown),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _passwordController,
                    obscureText: true,
                    decoration: InputDecoration(
                      labelText: 'Mật khẩu',
                      prefixIcon: const Icon(Icons.lock, color: Colors.brown),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
                  const SizedBox(height: 16),
                ],

                // Nút hành động chính
                ElevatedButton(
                  onPressed: _isLoading ? null : _handleSubmit,
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
                          child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                        )
                      : Text(
                          _getButtonTitle(),
                          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                        ),
                ),
                const SizedBox(height: 12),

                // Các tùy chọn phụ (Chuyển chế độ Đăng nhập / Đăng ký)
                if (_authMode == AuthMode.ownerLogin) ...[
                  TextButton(
                    onPressed: () => setState(() => _authMode = AuthMode.ownerRegister),
                    child: const Text('Chưa có tài khoản? Đăng ký gian hàng mới', style: TextStyle(color: Colors.brown)),
                  ),
                ] else if (_authMode == AuthMode.ownerRegister) ...[
                  TextButton(
                    onPressed: () => setState(() => _authMode = AuthMode.ownerLogin),
                    child: const Text('Đã có tài khoản gian hàng? Đăng nhập ngay', style: TextStyle(color: Colors.brown)),
                  ),
                ] else if (_authMode == AuthMode.staffLogin) ...[
                  TextButton(
                    onPressed: () => setState(() => _authMode = AuthMode.staffRegisterWithQR),
                    child: const Text('Nhân viên mới? Scan QR kết nối gian hàng', style: TextStyle(color: Colors.brown)),
                  ),
                ] else if (_authMode == AuthMode.staffRegisterWithQR) ...[
                  TextButton(
                    onPressed: () => setState(() => _authMode = AuthMode.staffLogin),
                    child: const Text('Đã từng tham gia cửa hàng? Đăng nhập nhân viên', style: TextStyle(color: Colors.brown)),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  String _getButtonTitle() {
    switch (_authMode) {
      case AuthMode.ownerLogin:
        return 'ĐĂNG NHẬP CHỦ QUÁN';
      case AuthMode.ownerRegister:
        return 'ĐĂNG KÝ GIAN HÀNG';
      case AuthMode.staffLogin:
        return 'ĐĂNG NHẬP NHÂN VIÊN';
      case AuthMode.staffRegisterWithQR:
        return 'HOÀN TẤT ĐĂNG KÝ NHÂN VIÊN';
    }
  }
}
