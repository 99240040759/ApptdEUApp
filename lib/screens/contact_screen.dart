import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../config/theme.dart';

class ContactScreen extends StatelessWidget {
  const ContactScreen({super.key});
  @override
  Widget build(BuildContext context) {
    return ListView(padding: const EdgeInsets.all(12), children: [
      const SizedBox(height: 4),
      // Office Bearers
      Text('Office Bearers', style: Theme.of(context).textTheme.titleLarge),
      const SizedBox(height: 8),
      ...AppConstants.officeBearers.map((b) => Card(child: ListTile(
        leading: CircleAvatar(backgroundColor: AppColors.primary.withAlpha(20),
          child: const Icon(Icons.person, color: AppColors.primary, size: 22)),
        title: Text(b['name']!, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
        subtitle: Text('${b['role']} • ${b['location']}', style: const TextStyle(fontSize: 12, color: AppColors.textMuted)),
        trailing: IconButton(
          icon: const Icon(Icons.phone, color: AppColors.teal, size: 20),
          onPressed: () => launchUrl(Uri.parse('tel:${b['phone']}')),
        ),
      ))),
      const SizedBox(height: 16),
      // Zonal Representatives
      Text('Zonal Representatives', style: Theme.of(context).textTheme.titleLarge),
      const SizedBox(height: 8),
      ...AppConstants.zonalReps.map((z) => Card(child: ListTile(
        leading: CircleAvatar(backgroundColor: AppColors.teal.withAlpha(20),
          child: const Icon(Icons.location_on, color: AppColors.teal, size: 22)),
        title: Text('${z['zone']} Zone', style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
        trailing: IconButton(
          icon: const Icon(Icons.phone, color: AppColors.teal, size: 20),
          onPressed: () => launchUrl(Uri.parse('tel:${z['phone']}')),
        ),
      ))),
      const SizedBox(height: 20),
    ]);
  }
}
