import 'package:flutter/material.dart';
import '../../config/app_theme.dart';
import 'provider_dashboard_view.dart';
import 'provider_requests_view.dart';
import 'provider_availability_view.dart';
import 'provider_finance_view.dart';
import 'provider_profile_view.dart';

class ProviderMainView extends StatefulWidget {
  const ProviderMainView({super.key});

  @override
  State<ProviderMainView> createState() => _ProviderMainViewState();
}

class _ProviderMainViewState extends State<ProviderMainView> {
  int _currentIndex = 0;

  final List<Widget> _pages = const [
    ProviderDashboardView(),
    ProviderRequestsView(),
    ProviderAvailabilityView(),
    ProviderFinanceView(),
    ProviderProfileView(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _currentIndex,
        children: _pages,
      ),
      bottomNavigationBar: Container(
        decoration: const BoxDecoration(
          border: Border(top: BorderSide(color: AppTheme.border)),
        ),
        child: BottomNavigationBar(
          currentIndex: _currentIndex,
          onTap: (index) => setState(() => _currentIndex = index),
          selectedItemColor: AppTheme.secondary,
          unselectedItemColor: AppTheme.textSecondary,
          backgroundColor: Colors.white,
          type: BottomNavigationBarType.fixed,
          elevation: 0,
          items: const [
            BottomNavigationBarItem(
              icon: Icon(Icons.dashboard_outlined),
              activeIcon: Icon(Icons.dashboard),
              label: 'الرئيسية',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.handyman_outlined),
              activeIcon: Icon(Icons.handyman),
              label: 'الطلبات',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.location_on_outlined),
              activeIcon: Icon(Icons.location_on),
              label: 'التغطية والتوافر',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.account_balance_wallet_outlined),
              activeIcon: Icon(Icons.account_balance_wallet),
              label: 'المستحقات',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.person_outline),
              activeIcon: Icon(Icons.person),
              label: 'حسابي',
            ),
          ],
        ),
      ),
    );
  }
}
