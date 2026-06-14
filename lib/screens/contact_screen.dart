import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../config/theme.dart';

class ContactScreen extends StatelessWidget {
  const ContactScreen({super.key});

  String _initials(String name) {
    final parts = name.trim().split(' ').where((p) => p.isNotEmpty).toList();
    if (parts.length >= 2) return '${parts.first[0]}${parts[1][0]}'.toUpperCase();
    return parts.isNotEmpty ? parts.first[0].toUpperCase() : '?';
  }

  static const _avatarColors = [
    Color(0xFFB91C1C), Color(0xFF1D4ED8), Color(0xFF047857),
    Color(0xFF7C3AED), Color(0xFFD97706),
  ];

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(0, 0, 0, 24),
      children: [
        // ── Office Bearers Header ──
        _sectionHeader(context, 'Office Bearers', Icons.groups_rounded, AppColors.primary),
        const SizedBox(height: 4),
        ...AppConstants.officeBearers.asMap().entries.map((e) =>
          _bearerCard(context, e.value, e.key)),
        const SizedBox(height: 8),
        // ── Zonal Reps Header ──
        _sectionHeader(context, 'Zonal Representatives', Icons.map_rounded, AppColors.teal),
        const SizedBox(height: 4),
        ...AppConstants.zonalReps.asMap().entries.map((e) =>
          _zoneCard(context, e.value, e.key)),
        const SizedBox(height: 16),
      ],
    );
  }

  Widget _sectionHeader(BuildContext context, String title, IconData icon, Color color) {
    return Container(
      margin: const EdgeInsets.fromLTRB(12, 16, 12, 0),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [color, color.withAlpha(200)],
          begin: Alignment.centerLeft, end: Alignment.centerRight,
        ),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(children: [
        Icon(icon, color: Colors.white, size: 20),
        const SizedBox(width: 10),
        Text(title, style: TextStyle(fontFamily: 'Inter', 
          color: Colors.white, fontSize: 15, fontWeight: FontWeight.w700)),
      ]),
    );
  }

  Widget _bearerCard(BuildContext context, Map<String, String> bearer, int index) {
    final color = _avatarColors[index % _avatarColors.length];
    final initials = _initials(bearer['name']!);
    return Card(
      margin: const EdgeInsets.fromLTRB(12, 8, 12, 0),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
          // Initials avatar
          Container(
            width: 48, height: 48,
            decoration: BoxDecoration(
              gradient: RadialGradient(colors: [color.withAlpha(220), color]),
              shape: BoxShape.circle,
            ),
            child: Center(child: Text(initials, style: TextStyle(fontFamily: 'Inter', 
              color: Colors.white, fontSize: 17, fontWeight: FontWeight.w700))),
          ),
          const SizedBox(width: 14),
          // Info
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(bearer['name']!, style: TextStyle(fontFamily: 'Inter', 
              fontSize: 14, fontWeight: FontWeight.w700, color: AppColors.textDark)),
            const SizedBox(height: 3),
            Row(children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: color.withAlpha(20),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: color.withAlpha(60)),
                ),
                child: Text(bearer['role']!, style: TextStyle(
                  fontSize: 11, fontWeight: FontWeight.w600, color: color)),
              ),
            ]),
            const SizedBox(height: 4),
            Row(children: [
              Icon(Icons.location_on_rounded, size: 13, color: AppColors.textMuted),
              const SizedBox(width: 3),
              Text(bearer['location']!, style: const TextStyle(fontSize: 12, color: AppColors.textMuted)),
            ]),
            const SizedBox(height: 10),
            // Action buttons
            Row(children: [
              _actionBtn(
                icon: Icons.call_rounded,
                label: 'Call',
                color: const Color(0xFF16A34A),
                onTap: () => launchUrl(Uri.parse('tel:${bearer['phone']}')),
              ),
              const SizedBox(width: 8),
              _actionBtn(
                icon: Icons.chat_rounded,
                label: 'WhatsApp',
                color: const Color(0xFF25D366),
                onTap: () => launchUrl(Uri.parse(
                  'https://wa.me/91${bearer['phone']}')),
              ),
            ]),
          ])),
        ]),
      ),
    );
  }

  Widget _zoneCard(BuildContext context, Map<String, String> zone, int index) {
    final color = _avatarColors[(index + 2) % _avatarColors.length];
    return Card(
      margin: const EdgeInsets.fromLTRB(12, 8, 12, 0),
      child: ListTile(
        contentPadding: const EdgeInsets.fromLTRB(14, 8, 8, 8),
        leading: Container(
          width: 44, height: 44,
          decoration: BoxDecoration(
            color: color.withAlpha(18),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: color.withAlpha(50)),
          ),
          child: Icon(Icons.location_city_rounded, color: color, size: 22),
        ),
        title: Text('${zone['zone']} Zone',
          style: TextStyle(fontFamily: 'Inter', fontSize: 14, fontWeight: FontWeight.w700)),
        subtitle: const Text('Zonal Representative',
          style: TextStyle(fontSize: 12, color: AppColors.textMuted)),
        trailing: Row(mainAxisSize: MainAxisSize.min, children: [
          _iconBtn(Icons.call_rounded, const Color(0xFF16A34A),
            () => launchUrl(Uri.parse('tel:${zone['phone']}'))),
          _iconBtn(Icons.chat_rounded, const Color(0xFF25D366),
            () => launchUrl(Uri.parse('https://wa.me/91${zone['phone']}'))),
        ]),
      ),
    );
  }

  Widget _actionBtn({required IconData icon, required String label, required Color color, required VoidCallback onTap}) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: color.withAlpha(18),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: color.withAlpha(80)),
        ),
        child: Row(mainAxisSize: MainAxisSize.min, children: [
          Icon(icon, size: 14, color: color),
          const SizedBox(width: 5),
          Text(label, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: color)),
        ]),
      ),
    );
  }

  Widget _iconBtn(IconData icon, Color color, VoidCallback onTap) {
    return IconButton(
      icon: Icon(icon, color: color, size: 22),
      onPressed: onTap,
      visualDensity: VisualDensity.compact,
      tooltip: icon == Icons.call_rounded ? 'Call' : 'WhatsApp',
    );
  }
}
