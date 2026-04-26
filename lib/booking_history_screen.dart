import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

class BookingHistoryScreen extends StatefulWidget {
  const BookingHistoryScreen({super.key});

  @override
  State<BookingHistoryScreen> createState() => _BookingHistoryScreenState();
}

class _BookingHistoryScreenState extends State<BookingHistoryScreen> {
  List<dynamic> _historyList = [];
  bool _isLoading = true;
  final Color goldColor = const Color(0xFFD4AF37);

  @override
  void initState() {
    super.initState();
    _fetchHistory();
  }

  Future<void> _fetchHistory() async {
    final prefs = await SharedPreferences.getInstance();
    final userId = prefs.getInt('userId'); // Ambil User ID dari session

    if (userId == null) {
      setState(() => _isLoading = false);
      return;
    }

    final String apiUrl = 'http://192.168.11.192/api/booking-history?user_id=$userId';
    try {
      final response = await http.get(Uri.parse(apiUrl));
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        setState(() {
          _historyList = data['data'] ?? [];
          _isLoading = false;
        });
      } else {
        setState(() => _isLoading = false);
      }
    } catch (e) {
      debugPrint("Error riwayat: $e");
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final onSurface = Theme.of(context).colorScheme.onSurface;

    return Scaffold(
      backgroundColor: Theme.of(context).brightness == Brightness.dark ? const Color(0xFF121212) : const Color(0xFFFDFBF7),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: onSurface),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text('Riwayat Booking', style: TextStyle(color: onSurface, fontWeight: FontWeight.bold)),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: Color(0xFFD4AF37)))
          : _historyList.isEmpty
              ? _buildEmptyState(onSurface)
              : RefreshIndicator(
                  onRefresh: _fetchHistory,
                  child: ListView.builder(
                    padding: const EdgeInsets.all(20),
                    itemCount: _historyList.length,
                    itemBuilder: (context, index) {
                      final item = _historyList[index];
                      return _buildHistoryCard(item, onSurface);
                    },
                  ),
                ),
    );
  }

  Widget _buildEmptyState(Color onSurface) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.event_note_outlined, size: 80, color: goldColor.withOpacity(0.3)),
          const SizedBox(height: 16),
          Text('Belum ada riwayat', style: TextStyle(color: onSurface.withOpacity(0.5), fontSize: 16)),
        ],
      ),
    );
  }

  Widget _buildHistoryCard(dynamic item, Color onSurface) {
    // Tentukan warna berdasarkan status
    Color statusColor = Colors.orange;
    String statusText = item['status'] ?? 'Menunggu';
    
    if (statusText == 'completed') {
      statusColor = Colors.green;
      statusText = 'Selesai';
    } else if (statusText == 'cancelled') {
      statusColor = Colors.redAccent;
      statusText = 'Dibatalkan';
    } else {
      statusText = 'Menunggu';
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 15),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: Colors.white.withOpacity(0.05)),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10)],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(color: goldColor.withOpacity(0.1), shape: BoxShape.circle),
                child: Icon(Icons.history, color: goldColor, size: 20),
              ),
              const SizedBox(width: 15),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(item['service_name'] ?? 'Layanan', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                  const SizedBox(height: 4),
                  Text("${item['booking_date']} | ${item['booking_time']}", style: TextStyle(color: onSurface.withOpacity(0.5), fontSize: 12)),
                  Text("Barber: ${item['barber_name']}", style: TextStyle(color: onSurface.withOpacity(0.4), fontSize: 11)),
                ],
              ),
            ],
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              const Text('Kode:', style: TextStyle(color: Colors.grey, fontSize: 10)),
              Text('BGO-${item['id']}', style: TextStyle(color: goldColor, fontWeight: FontWeight.bold, fontSize: 12)),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(color: statusColor.withOpacity(0.1), borderRadius: BorderRadius.circular(5)),
                child: Text(statusText, style: TextStyle(color: statusColor, fontSize: 10, fontWeight: FontWeight.bold)),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
