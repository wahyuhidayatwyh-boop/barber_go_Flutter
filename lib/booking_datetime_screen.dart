import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart'; // Tambahkan ini
import 'booking_success_screen.dart';

class BookingDatetimeScreen extends StatefulWidget {
  final String selectedService;
  final String selectedBarber;
  final String price;

  const BookingDatetimeScreen({
    super.key,
    required this.selectedService,
    required this.selectedBarber,
    required this.price,
  });

  @override
  State<BookingDatetimeScreen> createState() => _BookingDatetimeScreenState();
}

class _BookingDatetimeScreenState extends State<BookingDatetimeScreen> {
  DateTime _selectedDate = DateTime.now();
  String? _selectedTime;
  List<String> _occupiedSlots = [];
  bool _isLoadingSlots = false;
  bool _isSubmitting = false;

  final List<String> _timeSlots = [
    "09:00", "10:00", "11:00", "12:00", 
    "13:00", "14:00", "15:00", "16:00", 
    "17:00", "18:00", "19:00", "20:00"
  ];

  @override
  void initState() {
    super.initState();
    _fetchOccupiedSlots();
  }

  Future<void> _fetchOccupiedSlots() async {
    setState(() => _isLoadingSlots = true);
    final dateStr = DateFormat('yyyy-MM-dd').format(_selectedDate);
    final url = 'http://192.168.11.192/api/occupied-slots?date=$dateStr&barber=${widget.selectedBarber}';

    try {
      final response = await http.get(Uri.parse(url)).timeout(const Duration(seconds: 10));
      if (response.statusCode == 200) {
        setState(() {
          _occupiedSlots = List<String>.from(jsonDecode(response.body));
          _selectedTime = null;
          _isLoadingSlots = false;
        });
      }
    } catch (e) {
      debugPrint("Error Fetch Slots: $e");
      setState(() => _isLoadingSlots = false);
    }
  }

  Future<void> _submitBooking() async {
    setState(() => _isSubmitting = true);
    
    // AMBIL ID USER DARI SHAREDPREFERENCES
    final prefs = await SharedPreferences.getInstance();
    final int? userId = prefs.getInt('userId');

    if (userId == null) {
      setState(() => _isSubmitting = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Sesi login berakhir, silakan login ulang")),
        );
      }
      return;
    }

    // --- BAGIAN PERBAIKAN HARGA ---
    // Membersihkan format "Rp 30.000" menjadi angka 30000 agar database tidak error
    final String cleanPriceStr = widget.price.replaceAll('Rp ', '').replaceAll('.', '').trim();
    final int cleanPrice = int.tryParse(cleanPriceStr) ?? 0;
    // ------------------------------

    const url = 'http://192.168.11.192/api/bookings';
    
    final Map<String, dynamic> bookingPayload = {
      "service_name": widget.selectedService,
      "barber_name": widget.selectedBarber,
      "booking_date": DateFormat('yyyy-MM-dd').format(_selectedDate),
      "booking_time": _selectedTime,
      "user_id": userId, // GUNAKAN ID ASLI DARI LOGIN
      "total_price": cleanPrice, // TAMBAHKAN HARGA KE PAYLOAD
    };

    try {
      final response = await http.post(
        Uri.parse(url),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode(bookingPayload),
      ).timeout(const Duration(seconds: 15));

      setState(() => _isSubmitting = false);

      if (response.statusCode == 200 || response.statusCode == 201) {
        final responseData = jsonDecode(response.body);
        if (!mounted) return;
        
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => BookingSuccessScreen(
              bookingData: responseData['data'] ?? bookingPayload,
            ),
          ),
        );
      } else {
        if (!mounted) return;
        final errorData = jsonDecode(response.body);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Error: ${errorData['message'] ?? response.statusCode}")),
        );
      }
    } catch (e) {
      setState(() => _isSubmitting = false);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Koneksi Error: $e")),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final goldColor = const Color(0xFFD4AF37);
    final onSurface = Theme.of(context).colorScheme.onSurface;

    return Scaffold(
      appBar: AppBar(title: const Text("Pilih Jadwal")),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text("Pilih Tanggal", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 10),
            CalendarDatePicker(
              initialDate: _selectedDate,
              firstDate: DateTime.now(),
              lastDate: DateTime.now().add(const Duration(days: 14)),
              onDateChanged: (date) {
                setState(() => _selectedDate = date);
                _fetchOccupiedSlots();
              },
            ),
            const SizedBox(height: 30),
            const Text("Pilih Jam", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 15),
            _isLoadingSlots 
              ? const Center(child: CircularProgressIndicator())
              : GridView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 4, childAspectRatio: 2.2, mainAxisSpacing: 10, crossAxisSpacing: 10
                  ),
                  itemCount: _timeSlots.length,
                  itemBuilder: (context, index) {
                    final time = _timeSlots[index];
                    final isOccupied = _occupiedSlots.contains(time);
                    final isSelected = _selectedTime == time;

                    return GestureDetector(
                      onTap: isOccupied ? null : () => setState(() => _selectedTime = time),
                      child: Container(
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          color: isSelected ? goldColor : (isOccupied ? Colors.grey[800] : Colors.transparent),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: isOccupied ? Colors.transparent : goldColor),
                        ),
                        child: Text(
                          time,
                          style: TextStyle(
                            color: isSelected ? Colors.black : (isOccupied ? Colors.grey : onSurface),
                            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                            decoration: isOccupied ? TextDecoration.lineThrough : null,
                          ),
                        ),
                      ),
                    );
                  },
                ),
            const SizedBox(height: 40),
            SizedBox(
              width: double.infinity,
              height: 55,
              child: ElevatedButton(
                onPressed: (_selectedTime == null || _isSubmitting) ? null : _submitBooking,
                style: ElevatedButton.styleFrom(
                  backgroundColor: goldColor,
                  foregroundColor: Colors.black,
                  disabledBackgroundColor: Colors.grey[800],
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                child: _isSubmitting 
                  ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(color: Colors.black, strokeWidth: 2))
                  : const Text("KONFIRMASI SEKARANG", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
