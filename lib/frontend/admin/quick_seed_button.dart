import 'package:flutter/material.dart';
import '../../utils/seed_data.dart';

class QuickSeedButton extends StatefulWidget {
  const QuickSeedButton({super.key, required this.userId});

  final String userId;

  @override
  State<QuickSeedButton> createState() => _QuickSeedButtonState();
}

class _QuickSeedButtonState extends State<QuickSeedButton> {
  bool _isLoading = false;

  Future<void> _seedData() async {
    setState(() => _isLoading = true);

    try {
      await SeedData.seedAll(widget.userId);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Da them 24 san pham mau vao Firebase'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Loi tao du lieu mau: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return ElevatedButton.icon(
      onPressed: _isLoading ? null : _seedData,
      icon: _isLoading
          ? const SizedBox(
              width: 18,
              height: 18,
              child: CircularProgressIndicator(strokeWidth: 2),
            )
          : const Icon(Icons.add_shopping_cart),
      label: const Text('Them 24 san pham'),
      style: ElevatedButton.styleFrom(
        backgroundColor: Colors.orange,
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
      ),
    );
  }
}
