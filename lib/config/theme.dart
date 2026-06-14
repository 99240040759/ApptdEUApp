import 'package:flutter/material.dart';

class AppColors {
  static const primary = Color(0xFFB91C1C);
  static const primaryButton = Color(0xFFDC2626);
  static const teal = Color(0xFF009999);
  static const tealDark = Color(0xFF007777);
  static const amber = Color(0xFFFFC107);
  static const orange = Color(0xFFFF9800);
  static const gold = Color(0xFFE6A800);
  static const darkBg = Color(0xFF111827);
  static const pageBg = Color(0xFFF9FAFB);
  static const cardBg = Color(0xFFFFFFFF);
  static const quickLink = Color(0xFF1D4ED8);
  static const audioPurple = Color(0xFF9333EA);
  static const textDark = Color(0xFF171717);
  static const textMuted = Color(0xFF6B7280);
}

class AppConstants {
  static const appName = 'APPTD Employees Union';
  static const categories = ['General', 'Employees', 'Circulars', 'News'];

  // ── Exact URLs from website Header.tsx ──
  static const pfLinks = {
    'Employee PF Details': 'http://apsrtcpf.in/',
    'EPFO Demand Letters Status': 'https://unifiedportal-mem.epfindia.gov.in/memberInterfacePohw/',
    'EPFO Member Login': 'https://unifiedportal-mem.epfindia.gov.in/memberinterface/',
    'EPFO Pension Status': 'https://mis.epfindia.gov.in/PensionPaymentEnquiry/pensionStatus.jsp',
    'PF Withdraw Application': 'http://apsrtcpf.in/data/EMPLOYEES%20PROVIDENT%20FUND%20ORGANISATION.pdf',
    'PF 10-D Application Form': 'https://drive.google.com/uc?export=download&id=1QEJZWUa76k8q9mr-kkXheEOphhsNnEHw',
    'PF Demand Consent Letter': 'https://drive.google.com/uc?export=download&id=1QCyMSrFkKwG0l9Xw_euL8MTXab7pxEm9',
  };

  static const ccsLinks = {
    'Employee CCS Details': 'https://apsrtc-ccs-ssp.smartcbs.net/',
    'CCS App Download': 'https://play.google.com/store/apps/details?id=com.ykit.apps.creditsocietymember.apsrtc&pcampaignid=web_share',
    'CCS EDL Loan Application': 'https://apsrtc-ccs-ssp.smartcbs.net/assets/EDLForm-CCS5E.pdf',
    'CCS STL Loan Application': 'https://apsrtc-ccs-ssp.smartcbs.net/assets/STLForm-CCS5.pdf',
    'CCS Festival Application': 'https://apsrtc-ccs-ssp.smartcbs.net/assets/FestivalLoanForm-CCS5F.pdf',
    'CCS Membership & Nominee': 'https://drive.google.com/uc?export=download&id=1CVtbSc4qCvvwgq56Jtzc9YLXLaHueqdO',
    'CCS FD-RD Claim': 'https://drive.google.com/uc?export=download&id=1CVtbSc4qCvvwgq56Jtzc9YLXLaHueqdO',
    'CCS Additional Thrift Form': 'https://drive.google.com/uc?export=download&id=1p_4hSbnfSulsnUzwPi-iwtkFLDcyrTk6',
    'CCS RD Form (CCS 28)': 'https://drive.google.com/uc?export=download&id=1HzNa25H0_Ul54ldYDttr8ivDMqC5fXHv',
    'CCS RET CMS Claim Form': 'https://drive.google.com/uc?export=download&id=1Yz6Qug9nMDkEQtC7MCr4nzwHzbIjWvzi',
    'CCS Surety Renewal (CCS 8)': 'https://drive.google.com/uc?export=download&id=1HGTzoBUEBFZMvap3WvAFNczw3TtpWBO0',
  };

  static const ehsLinks = {
    'EHS Card Login': 'https://www.ehs.ap.gov.in/EHSAP/loginAction.do?actionFlag=loginPage&theme=navyblue',
    'EHS App Download': 'https://play.google.com/store/apps/details?id=com.sritindiapvtltd.ehs_app&pcampaignid=web_share',
    'EHS Medical Reimbursement': 'https://drive.google.com/uc?export=download&id=1-5fLqhomxpKEHFV2kCW02WaEUDM3zbA3',
    'EHS Hospitals List': 'https://drive.google.com/uc?export=download&id=1R9g7NLDI_i1lATaphVi-pXI-faSryag7',
    'EHS Health Card View': 'https://www.ehs.ap.gov.in/EHSAP/healthCardAction.do?actionFlag=healthCardView&theme=navyblue',
  };

  static const appLinks = {
    'Nidhi App': 'https://play.google.com/store/apps/details?id=in.apcfss.in.herb.emp&pcampaignid=web_share',
    'APFRS App': 'https://play.google.com/store/apps/details?id=in.apcfss.apfrs&pcampaignid=web_share',
    'Bus Live Track App': 'https://play.google.com/store/apps/details?id=com.ionicframework.apsrtclivetrack555011&pcampaignid=web_share',
  };

  static const formsLinks = {
    'Tuition Fee Reimbursement': 'https://drive.google.com/uc?export=download&id=1QRDOtGFW3fX-5JQZ4s8S-BKrecSYpE_B',
    'Transfer Application': 'https://drive.google.com/uc?export=download&id=1Vb1ywvb20edIBzZ1-bI6qCewHp0smRn5',
    'Transfer (Region to Region)': 'https://drive.google.com/uc?export=download&id=1fTSYBtU-aqqDTXnbcbpAwoDGxgFKdHvA',
    'Deputation Circular': 'https://drive.google.com/uc?export=download&id=1KZUJC4nSqkKqxG2ubBK3oZ-eHDVvSw7k',
    'Leave Application (>3 Days)': 'https://drive.google.com/uc?export=download&id=1gKfNuw8ik15yKiWWkKEVUeOLjfRHyVgL',
    'EOL Leave Application': 'https://drive.google.com/uc?export=download&id=1gLja27nJB5aOJf2Pub0_SCG4Wts7fbAH',
    'Commute Leave Application': 'https://drive.google.com/uc?export=download&id=1gHcb21dETQl0jfZMougw_c3WMeIzqxSM',
    'Family Bus Pass': 'https://drive.google.com/uc?export=download&id=1g9yU_YkHG8uQJ4UI6R6ojijnrW5AB-C6',
    'Passport Identity Cert.': 'https://drive.google.com/uc?export=download&id=1gNt20_94OVLCl30BhpHknT8ClYCuk7qd',
    'Govt Sick Application': 'https://drive.google.com/uc?export=download&id=14CQ0FuT2Lkh0nv5ayWNV2whegzOWQykb',
  };

  // Exact from website Sidebar.tsx
  static const quickLinks = {
    'APSRTC Official Site': 'https://www.apsrtc.ap.gov.in/',
    'Employee Login (PF Trust)': 'http://apsrtcpf.in/',
    'EPFO Member Login': 'https://unifiedportal-mem.epfindia.gov.in/memberinterface/',
    'Leave Application': 'https://drive.google.com/uc?export=download&id=1gKfNuw8ik15yKiWWkKEVUeOLjfRHyVgL',
  };

  // Exact from website contact/page.tsx
  static const officeBearers = [
    {'name': 'Palisetti Damodararao', 'role': 'State President', 'phone': '9989397989', 'location': 'Vijayawada'},
    {'name': 'G.V. Narasaiah', 'role': 'General Secretary', 'phone': '9441195580', 'location': 'Vijayawada'},
    {'name': 'P Subramanyamraju', 'role': 'Working President', 'phone': '9440765005', 'location': 'Vijayawada'},
    {'name': 'K Nageswararao', 'role': 'Chief Vice President', 'phone': '7382887911', 'location': 'Vijayawada'},
    {'name': 'M. Srinivasa Rao', 'role': 'Treasurer', 'phone': '9440022222', 'location': 'Guntur'},
  ];

  // Exact from website contact/page.tsx — fixed phone numbers
  static const zonalReps = [
    {'zone': 'Vizianagaram', 'phone': '9490000001'},
    {'zone': 'Vijayawada', 'phone': '9490000002'},
    {'zone': 'Nellore', 'phone': '9490000003'},
    {'zone': 'Kadapa', 'phone': '9490000004'},
    {'zone': 'Kurnool', 'phone': '9490000005'},
  ];
}

class AppTheme {
  static ThemeData get lightTheme {
    final base = ThemeData.light(useMaterial3: true);
    const inter = 'Inter';
    final textTheme = base.textTheme.apply(fontFamily: inter);
    return base.copyWith(
      colorScheme: ColorScheme.fromSeed(
        seedColor: AppColors.primary,
        primary: AppColors.primary,
        secondary: AppColors.teal,
        tertiary: AppColors.audioPurple,
        surface: AppColors.cardBg,
      ),
      scaffoldBackgroundColor: AppColors.pageBg,
      appBarTheme: const AppBarTheme(
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        elevation: 0, centerTitle: false,
        iconTheme: IconThemeData(color: Colors.white),
        titleTextStyle: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w600),
      ),
      cardTheme: CardThemeData(
        color: AppColors.cardBg, elevation: 2,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        surfaceTintColor: Colors.transparent,
        shadowColor: Colors.black.withAlpha(30),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primaryButton, foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          textStyle: const TextStyle(fontWeight: FontWeight.w600),
        ),
      ),
      textTheme: textTheme.copyWith(
        headlineLarge: textTheme.headlineLarge?.copyWith(color: AppColors.textDark, fontWeight: FontWeight.w700),
        titleLarge: textTheme.titleLarge?.copyWith(color: AppColors.textDark, fontWeight: FontWeight.w600),
        bodyMedium: textTheme.bodyMedium?.copyWith(color: AppColors.textDark),
      ),
      dividerColor: Colors.grey.shade300,
    );
  }
}
