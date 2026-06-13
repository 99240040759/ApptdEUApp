import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../app.dart';
import '../config/theme.dart';

class CustomDrawer extends StatelessWidget {
  const CustomDrawer({super.key});
  @override
  Widget build(BuildContext context) {
    return Drawer(
      child: ListView(padding: EdgeInsets.zero, children: [
        DrawerHeader(
          decoration: const BoxDecoration(
            gradient: LinearGradient(colors: [AppColors.primary, Color(0xFF991B1B)]),
          ),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisAlignment: MainAxisAlignment.end, children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: Image.asset('assets/images/logo.jpg', height: 48, width: 48, fit: BoxFit.cover,
                errorBuilder: (_, _, _) => const Icon(Icons.groups, size: 48, color: Colors.white)),
            ),
            const SizedBox(height: 8),
            const Text('APPTD Employees Union',
              style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w700)),
            Text('Official Blog & Information Portal', style: TextStyle(color: Colors.white70, fontSize: 12)),
          ]),
        ),
        // Nav order matches website: Home, Union Affairs, Circulars, About Us, Contact
        _navTile(context, Icons.home_rounded, 'Home', 0),
        _navTile(context, Icons.groups_rounded, 'Union Affairs', 2),
        _navTile(context, Icons.description_rounded, 'Circulars', 1),
        _navTile(context, Icons.info_rounded, 'About Us', 3),
        _navTile(context, Icons.contact_phone_rounded, 'Contact', 4),
        const Divider(),
        // Dropdown sections match website Header.tsx menu names exactly
        _linkSection(context, 'PF', Icons.account_balance, AppConstants.pfLinks),
        _linkSection(context, 'CCS', Icons.gavel, AppConstants.ccsLinks),
        _linkSection(context, 'EHS', Icons.health_and_safety, AppConstants.ehsLinks),
        _linkSection(context, 'Apps', Icons.apps, AppConstants.appLinks),
        _linkSection(context, 'Forms', Icons.assignment, AppConstants.formsLinks),
        const Divider(),
        // Quick Links match website Sidebar.tsx exactly
        _quickLinksSection(),
        const Divider(),
        ListTile(
          leading: const Icon(Icons.admin_panel_settings, color: AppColors.primary),
          title: const Text('Admin Panel'),
          onTap: () { Navigator.pop(context); Navigator.pushNamed(context, '/admin'); },
        ),
        const SizedBox(height: 16),
      ]),
    );
  }

  Widget _navTile(BuildContext context, IconData icon, String label, int index) {
    return ListTile(
      leading: Icon(icon, color: AppColors.primary),
      title: Text(label, style: const TextStyle(fontWeight: FontWeight.w500)),
      onTap: () {
        Navigator.pop(context);
        context.findAncestorStateOfType<MainShellState>()?.switchTab(index);
      },
    );
  }

  Widget _linkSection(BuildContext context, String title, IconData icon, Map<String, String> links) {
    return ExpansionTile(
      leading: Icon(icon, color: AppColors.teal, size: 22),
      title: Text(title, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500)),
      childrenPadding: const EdgeInsets.only(left: 24),
      children: links.entries.map((e) => ListTile(
        dense: true, visualDensity: VisualDensity.compact,
        title: Text(e.key, style: const TextStyle(fontSize: 13)),
        trailing: const Icon(Icons.open_in_new, size: 14, color: AppColors.textMuted),
        onTap: () => launchUrl(Uri.parse(e.value), mode: LaunchMode.externalApplication),
      )).toList(),
    );
  }

  Widget _quickLinksSection() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        const Text('Quick Links', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.textMuted)),
        const SizedBox(height: 6),
        ...AppConstants.quickLinks.entries.map((e) => InkWell(
          onTap: () => launchUrl(Uri.parse(e.value), mode: LaunchMode.externalApplication),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 6),
            child: Row(children: [
              const Icon(Icons.link, size: 15, color: AppColors.quickLink),
              const SizedBox(width: 8),
              Expanded(child: Text(e.key, style: const TextStyle(color: AppColors.quickLink, fontSize: 13, decoration: TextDecoration.underline))),
            ]),
          ),
        )),
      ]),
    );
  }
}
