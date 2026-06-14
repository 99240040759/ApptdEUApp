import 'package:flutter/material.dart';
import 'config/theme.dart';
import 'screens/home_screen.dart';
import 'screens/blog_detail_screen.dart';
import 'screens/circulars_screen.dart';
import 'screens/union_affairs_screen.dart';
import 'screens/about_screen.dart';
import 'screens/contact_screen.dart';
import 'screens/admin/login_screen.dart';
import 'screens/admin/dashboard_screen.dart';
import 'widgets/custom_drawer.dart';
import 'services/updater_service.dart';

class ApptdApp extends StatelessWidget {
  const ApptdApp({super.key});
  static final navigatorKey = GlobalKey<NavigatorState>();
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: AppConstants.appName,
      debugShowCheckedModeBanner: false,
      navigatorKey: navigatorKey,
      theme: AppTheme.lightTheme,
      home: const MainShell(),
      routes: {
        '/admin': (_) => const LoginScreen(),
        '/admin/dashboard': (_) => const DashboardScreen(),
      },
      onGenerateRoute: (settings) {
        if (settings.name?.startsWith('/blog/') == true) {
          final slug = settings.name!.replaceFirst('/blog/', '');
          return MaterialPageRoute(builder: (_) => BlogDetailScreen(slug: slug));
        }
        return null;
      },
    );
  }
}

class MainShell extends StatefulWidget {
  const MainShell({super.key});
  @override
  State<MainShell> createState() => MainShellState();
}

class MainShellState extends State<MainShell> {
  int currentIndex = 0;
  void switchTab(int i) => setState(() => currentIndex = i);

  @override
  void initState() {
    super.initState();
    // Check for update once on launch — after first frame so UI is fully ready
    WidgetsBinding.instance.addPostFrameCallback((_) {
      UpdaterService().checkForUpdate(context);
    });
  }

  static const _pages = <Widget>[
    HomeScreen(), CircularsScreen(), UnionAffairsScreen(), AboutScreen(), ContactScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Row(children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: Image.asset('assets/images/logo.jpg', height: 34, width: 34, fit: BoxFit.cover),
          ),
          const SizedBox(width: 10),
          Expanded(child: Text(AppConstants.appName,
            style: TextStyle(fontFamily: 'Inter', fontSize: 15, fontWeight: FontWeight.w700, color: Colors.white),
            overflow: TextOverflow.ellipsis)),
        ]),
      ),
      drawer: const CustomDrawer(),
      body: IndexedStack(index: currentIndex, children: _pages),
      bottomNavigationBar: NavigationBar(
        selectedIndex: currentIndex,
        onDestinationSelected: switchTab,
        height: 64,
        labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
        indicatorColor: AppColors.primary.withAlpha(30),
        destinations: const [
          NavigationDestination(icon: Icon(Icons.home_outlined), selectedIcon: Icon(Icons.home_rounded, color: AppColors.primary), label: 'Home'),
          NavigationDestination(icon: Icon(Icons.description_outlined), selectedIcon: Icon(Icons.description_rounded, color: AppColors.primary), label: 'Circulars'),
          NavigationDestination(icon: Icon(Icons.groups_outlined), selectedIcon: Icon(Icons.groups_rounded, color: AppColors.primary), label: 'Union'),
          NavigationDestination(icon: Icon(Icons.info_outline), selectedIcon: Icon(Icons.info_rounded, color: AppColors.primary), label: 'About'),
          NavigationDestination(icon: Icon(Icons.contact_phone_outlined), selectedIcon: Icon(Icons.contact_phone_rounded, color: AppColors.primary), label: 'Contact'),
        ],
      ),
    );
  }
}
