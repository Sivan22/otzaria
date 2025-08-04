import 'package:flutter/material.dart';

class MoreScreen extends StatelessWidget {
  const MoreScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('עוד'),
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.end, // מיושר לימין
          children: [
            _buildToolItem(
              context,
              icon: Icons.calendar_today,
              title: 'לוח שנה',
              subtitle: 'לוח שנה עברי ולועזי',
              onTap: () => _showComingSoon(context, 'לוח שנה'),
            ),
            const SizedBox(height: 16),
            _buildToolItem(
              context,
              icon: Icons.straighten,
              title: 'ממיר מידות',
              subtitle: 'המרת מידות ומשקולות',
              onTap: () => _showComingSoon(context, 'ממיר מידות ומשקולות'),
            ),
            const SizedBox(height: 16),
            _buildToolItem(
              context,
              icon: Icons.calculate,
              title: 'גימטריות',
              subtitle: 'חישובי גימטריה',
              onTap: () => _showComingSoon(context, 'גימטריות'),
            ),
          ],
        ),
      ),
    );
  }

  /// כרטיס קטן מיושר לימין
  Widget _buildToolItem(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return Align(
      alignment: Alignment.centerRight, // מצמיד לימין
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          width: 110, // רוחב צר - כמו הסרגל הצדדי
          padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 8),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surfaceContainerHighest,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.grey.shade300),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 32, color: Theme.of(context).primaryColor),
              const SizedBox(height: 8),
              Text(
                title,
                style:
                    const TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 2),
              Text(
                subtitle,
                style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showComingSoon(BuildContext context, String feature) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: Text(feature),
        content: const Text('בקרוב...'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('אישור'),
          ),
        ],
      ),
    );
  }
}
