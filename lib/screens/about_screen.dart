import 'package:flutter/material.dart';
import '../app.dart';
import '../config/theme.dart';

class AboutScreen extends StatelessWidget {
  const AboutScreen({super.key});
  @override
  Widget build(BuildContext context) {
    return ListView(padding: const EdgeInsets.only(bottom: 24), children: [
      // Hero gradient
      Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 36),
        decoration: const BoxDecoration(
          gradient: LinearGradient(colors: [AppColors.primary, Color(0xFF991B1B)]),
        ),
        child: Column(children: [
          const Icon(Icons.groups_rounded, size: 52, color: Colors.white),
          const SizedBox(height: 10),
          const Text('About APPTD\nEmployees Union',
            style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800, color: Colors.white, height: 1.3),
            textAlign: TextAlign.center),
          const SizedBox(height: 8),
          Text('Protecting APSRTC employees across Andhra Pradesh',
            style: TextStyle(fontSize: 13, color: Colors.white.withAlpha(220)), textAlign: TextAlign.center),
        ]),
      ),
      const SizedBox(height: 12),
      _card(Icons.flag_rounded, AppColors.primaryButton, 'Our Mission',
        'To safeguard the rights, benefits, and working conditions of APSRTC employees across '
        'Andhra Pradesh. We strive to ensure every employee receives fair treatment, proper compensation, '
        'and a safe working environment.'),
      _card(Icons.history_edu_rounded, AppColors.teal, 'Our History',
        'The APPTD Employees Union was founded to protect and promote the welfare of APSRTC employees. '
        'Over the years, we have been at the forefront of advocating for better pay, improved working '
        'conditions, and enhanced employee benefits across all zones of Andhra Pradesh.'),
      // Values
      Card(margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6), child: Padding(
        padding: const EdgeInsets.all(16), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            Icon(Icons.verified_rounded, color: AppColors.orange, size: 22),
            const SizedBox(width: 8),
            const Text('What We Stand For', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
          ]),
          const SizedBox(height: 14),
          _value(Icons.gavel, 'Employee Rights', 'Fighting for fair treatment and legal protections.'),
          _value(Icons.monetization_on, 'Better Compensation', 'Working for better pay, DA rates, and benefits.'),
          _value(Icons.health_and_safety, 'Safe Workplaces', 'Promoting safe conditions across all zones.'),
          _value(Icons.campaign, 'Information Access', 'Keeping members informed on circulars, transfers, DA rates.'),
          _value(Icons.handshake, 'Collective Bargaining', 'Representing employees in negotiations.'),
        ]),
      )),
      // Contact CTA
      Padding(padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10), child: FilledButton.icon(
        onPressed: () => context.findAncestorStateOfType<MainShellState>()?.switchTab(4),
        icon: const Icon(Icons.contact_phone),
        label: const Text('Contact Us'),
        style: FilledButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 14)),
      )),
    ]);
  }

  Widget _card(IconData icon, Color color, String title, String body) {
    return Card(margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6), child: Padding(
      padding: const EdgeInsets.all(16), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Icon(icon, color: color, size: 22), const SizedBox(width: 8),
          Text(title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
        ]),
        const SizedBox(height: 10),
        Text(body, style: const TextStyle(fontSize: 14, height: 1.6, color: Colors.black87)),
      ]),
    ));
  }

  Widget _value(IconData icon, String title, String desc) {
    return Padding(padding: const EdgeInsets.only(bottom: 12), child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Container(
        padding: const EdgeInsets.all(7),
        decoration: BoxDecoration(color: AppColors.primary.withAlpha(20), borderRadius: BorderRadius.circular(8)),
        child: Icon(icon, size: 18, color: AppColors.primary),
      ),
      const SizedBox(width: 10),
      Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(title, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
        const SizedBox(height: 2),
        Text(desc, style: TextStyle(fontSize: 12, color: Colors.grey.shade700, height: 1.4)),
      ])),
    ]));
  }
}
