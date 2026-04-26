import 'package:flutter/material.dart';

class ProductDetailScreen extends StatelessWidget {
  final String name;
  final String price;
  final String imageUrl;
  final String description;
  final int stock;

  const ProductDetailScreen({
    super.key,
    required this.name,
    required this.price,
    required this.imageUrl,
    required this.description,
    required this.stock,
  });

  @override
  Widget build(BuildContext context) {
    final goldColor = const Color(0xFFD4AF37);
    final onSurface = Theme.of(context).colorScheme.onSurface;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: onSurface),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Detail Produk',
          style: TextStyle(color: onSurface, fontWeight: FontWeight.bold),
        ),
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Product Image
            Container(
              height: 300,
              width: double.infinity,
              decoration: BoxDecoration(
                image: DecorationImage(
                  image: NetworkImage(imageUrl),
                  fit: BoxFit.cover,
                ),
              ),
            ),
            
            Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Name and Price
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Text(
                          name,
                          style: TextStyle(
                            color: onSurface,
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      Text(
                        price,
                        style: TextStyle(
                          color: goldColor,
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  
                  // Stock Info
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: goldColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: goldColor.withOpacity(0.3)),
                    ),
                    child: Text(
                      'Stok: $stock Item',
                      style: TextStyle(
                        color: goldColor,
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                      ),
                    ),
                  ),
                  
                  const SizedBox(height: 24),
                  
                  // Description Label
                  Text(
                    'Deskripsi Produk',
                    style: TextStyle(
                      color: onSurface,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 12),
                  
                  // Description Content
                  Text(
                    description,
                    style: TextStyle(
                      color: onSurface.withOpacity(0.7),
                      fontSize: 15,
                      height: 1.6,
                    ),
                  ),
                  
                  const SizedBox(height: 40),
                  
                  // Note: No Order Button as per request (Read-only)
                  Center(
                    child: Text(
                      '*Informasi produk hanya untuk dilihat',
                      style: TextStyle(
                        color: onSurface.withOpacity(0.4),
                        fontSize: 12,
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
