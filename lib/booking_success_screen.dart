import 'package:flutter/material.dart';
import 'package:barcode_widget/barcode_widget.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';

class BookingSuccessScreen extends StatelessWidget {
  final Map<String, dynamic> bookingData;

  const BookingSuccessScreen({super.key, required this.bookingData});

  Future<void> _cancelBooking(BuildContext context) async {
    final bool? confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Batalkan Booking?'),
        content: const Text('Apakah Anda yakin ingin membatalkan pesanan ini secara permanen?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('TIDAK')),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('YA, BATALKAN', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirm == true) {
      try {
        final response = await http.delete(
          Uri.parse('http://192.168.11.192/api/bookings/${bookingData['id']}'),
        );
        if (response.statusCode == 200) {
          if (context.mounted) {
            Navigator.of(context).popUntil((route) => route.isFirst);
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Booking Berhasil Dibatalkan')),
            );
          }
        }
      } catch (e) {
        debugPrint('Error membatalkan: $e');
      }
    }
  }

  String _formatCurrency(dynamic amount) {
    if (amount == null) return "Rp 0";
    final formatter = NumberFormat.currency(locale: 'id', symbol: 'Rp ', decimalDigits: 0);
    return formatter.format(amount is String ? int.tryParse(amount) ?? 0 : amount);
  }

  @override
  Widget build(BuildContext context) {
    final goldColor = const Color(0xFFD4AF37);
    final onSurface = Theme.of(context).colorScheme.onSurface;

    return Scaffold(
      backgroundColor: Theme.of(context).brightness == Brightness.dark ? const Color(0xFF121212) : const Color(0xFFFDFBF7),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 40),
          child: Column(
            children: [
              const Icon(Icons.check_circle_rounded, color: Colors.green, size: 90),
              const SizedBox(height: 20),
              const Text('BOOKING BERHASIL', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              Text(
                'Tunjukkan QR Code di bawah ini ke kasir',
                textAlign: TextAlign.center,
                style: TextStyle(color: onSurface.withOpacity(0.6)),
              ),
              const SizedBox(height: 40),
              
              // Tiket Konfirmasi
              Container(
                padding: const EdgeInsets.all(25),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.surface,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 20)],
                ),
                child: Column(
                  children: [
                    // MENGGUNAKAN QR CODE (KOTAK)
                    BarcodeWidget(
                      barcode: Barcode.qrCode(), 
                      data: 'BGO-${bookingData['id'] ?? '000'}',
                      width: 150,
                      height: 150,
                      color: onSurface,
                    ),
                    const SizedBox(height: 25),
                    Text(
                      'BGO-${bookingData['id'] ?? '000'}',
                      style: const TextStyle(letterSpacing: 2, fontWeight: FontWeight.bold, fontSize: 18),
                    ),
                    const SizedBox(height: 20),
                    const Divider(),
                    const SizedBox(height: 15),
                    _buildInfoRow('Layanan', bookingData['service_name'] ?? '-'),
                    _buildInfoRow('Barber', bookingData['barber_name'] ?? '-'),
                    _buildInfoRow('Tanggal', bookingData['booking_date'] ?? '-'),
                    _buildInfoRow('Waktu', bookingData['booking_time'] ?? '-'),
                    _buildInfoRow('Total Bayar', _formatCurrency(bookingData['total_price'])),
                    _buildInfoRow('Pembayaran', 'Bayar di Tempat (Unpaid)', valueColor: Colors.redAccent),
                  ],
                ),
              ),
              
              const SizedBox(height: 50),
              
              SizedBox(
                width: double.infinity,
                height: 55,
                child: ElevatedButton(
                  onPressed: () => Navigator.of(context).popUntil((route) => route.isFirst),
                  style: ElevatedButton.styleFrom(backgroundColor: goldColor, foregroundColor: Colors.black),
                  child: const Text('KEMBALI KE BERANDA', style: TextStyle(fontWeight: FontWeight.bold)),
                ),
              ),
              const SizedBox(height: 15),
              TextButton(
                onPressed: () => _cancelBooking(context),
                child: const Text('BATALKAN BOOKING', style: TextStyle(color: Colors.redAccent, fontWeight: FontWeight.bold)),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value, {Color? valueColor}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(color: Colors.grey, fontSize: 14)),
          Flexible(
            child: Text(
              value, 
              textAlign: TextAlign.right,
              style: TextStyle(
                fontWeight: FontWeight.bold, 
                fontSize: 14,
                color: valueColor,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
