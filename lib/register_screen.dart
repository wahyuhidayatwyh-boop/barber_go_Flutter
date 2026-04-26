import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'notification_service.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  final goldColor = const Color(0xFFD4AF37);
  bool _isLoading = false;
  bool _obscurePassword = true;
  bool _obscureConfirm = true;

  // --- FUNGSI DAFTAR KE BACKEND LARAVEL ---
  Future<void> _handleRegister() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    // URL sesuai IP Laptop Anda yang baru
    const String apiUrl = 'http://192.168.11.192/api/register';

    try {
      final response = await http.post(
        Uri.parse(apiUrl),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
        body: jsonEncode({
          'name': _nameController.text,
          'email': _emailController.text,
          'phone': _phoneController.text,
          'password': _passwordController.text,
        }),
      ).timeout(const Duration(seconds: 15));

      final data = jsonDecode(response.body);

      if (response.statusCode == 201 || response.statusCode == 200) {
        // SUKSES
        await NotificationService.showNotification(
          id: 2,
          title: 'Registrasi Berhasil',
          body: 'Halo ${_nameController.text}, akun Anda siap digunakan!',
        );

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Registrasi Berhasil! Silakan Login'), 
              backgroundColor: Colors.green
            ),
          );
          Navigator.pop(context); // Kembali ke halaman Login
        }
      } else {
        // GAGAL: Tampilkan pesan error dari Laravel
        _showError(data['message'] ?? 'Gagal mendaftar. Periksa kembali data Anda.');
      }
    } catch (e) {
      _showError('Koneksi Gagal. Pastikan server aktif di IP: 192.168.11.192');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.redAccent),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF121212),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      extendBodyBehindAppBar: true,
      body: Stack(
        children: [
          // Background Header
          Container(
            height: MediaQuery.of(context).size.height * 0.35,
            decoration: const BoxDecoration(
              image: DecorationImage(
                image: NetworkImage('https://images.unsplash.com/photo-1585747860715-2ba37e788b70?q=80&w=1000'),
                fit: BoxFit.cover,
              ),
            ),
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [Colors.black.withOpacity(0.3), const Color(0xFF121212)],
                ),
              ),
            ),
          ),

          SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Column(
                children: [
                  const SizedBox(height: 10),
                  Icon(Icons.content_cut, color: goldColor, size: 48),
                  const Text(
                    'CUKURMEN',
                    style: TextStyle(
                      color: Colors.white, 
                      fontSize: 22, 
                      fontWeight: FontWeight.bold, 
                      letterSpacing: 4
                    ),
                  ),
                  const SizedBox(height: 30),

                  Container(
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: const Color(0xFF1E1E1E),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: Colors.white10),
                    ),
                    child: Form(
                      key: _formKey,
                      child: Column(
                        children: [
                          const Text(
                            'DAFTAR AKUN',
                            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white),
                          ),
                          const SizedBox(height: 25),
                          
                          _buildTextField(
                            controller: _nameController, 
                            label: 'Nama Lengkap', 
                            icon: Icons.person_outline,
                            validator: (v) => v!.isEmpty ? 'Nama wajib diisi' : null,
                          ),
                          const SizedBox(height: 16),
                          
                          _buildTextField(
                            controller: _emailController, 
                            label: 'Email', 
                            icon: Icons.email_outlined,
                            validator: (v) => !v!.contains('@') ? 'Email tidak valid' : null,
                          ),
                          const SizedBox(height: 16),
                          
                          _buildTextField(
                            controller: _phoneController, 
                            label: 'Nomor HP', 
                            icon: Icons.phone_android_outlined,
                            validator: (v) => v!.length < 10 ? 'Nomor HP tidak valid' : null,
                          ),
                          const SizedBox(height: 16),
                          
                          _buildTextField(
                            controller: _passwordController, 
                            label: 'Password', 
                            icon: Icons.lock_outline, 
                            isPassword: true,
                            obscureText: _obscurePassword,
                            toggleIcon: () => setState(() => _obscurePassword = !_obscurePassword),
                            validator: (v) => v!.length < 6 ? 'Minimal 6 karakter' : null,
                          ),
                          const SizedBox(height: 16),

                          _buildTextField(
                            controller: _confirmPasswordController, 
                            label: 'Konfirmasi Password', 
                            icon: Icons.lock_reset, 
                            isPassword: true,
                            obscureText: _obscureConfirm,
                            toggleIcon: () => setState(() => _obscureConfirm = !_obscureConfirm),
                            validator: (v) => v != _passwordController.text ? 'Password tidak sama' : null,
                          ),
                          
                          const SizedBox(height: 30),

                          SizedBox(
                            width: double.infinity,
                            height: 55,
                            child: ElevatedButton(
                              onPressed: _isLoading ? null : _handleRegister,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: goldColor,
                                foregroundColor: Colors.black,
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                              ),
                              child: _isLoading 
                                ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(color: Colors.black, strokeWidth: 2))
                                : const Text('DAFTAR SEKARANG', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 30),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    bool isPassword = false,
    bool obscureText = false,
    VoidCallback? toggleIcon,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      obscureText: isPassword ? obscureText : false,
      validator: validator,
      style: const TextStyle(color: Colors.white),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(color: Colors.white38, fontSize: 14),
        prefixIcon: Icon(icon, color: goldColor, size: 22),
        suffixIcon: isPassword ? IconButton(
          icon: Icon(obscureText ? Icons.visibility_off : Icons.visibility, color: Colors.white38, size: 20),
          onPressed: toggleIcon,
        ) : null,
        enabledBorder: const UnderlineInputBorder(borderSide: BorderSide(color: Colors.white10)),
        focusedBorder: UnderlineInputBorder(borderSide: BorderSide(color: goldColor)),
      ),
    );
  }
}
