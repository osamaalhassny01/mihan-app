import 'package:flutter/material.dart';
import '../../config/app_theme.dart';
import 'customer_home_view.dart';
import 'customer_requests_view.dart';
import 'customer_profile_view.dart';

class CustomerMainView extends StatefulWidget {
  const CustomerMainView({super.key});

  @override
  State<CustomerMainView> createState() => _CustomerMainViewState();
}

class _CustomerMainViewState extends State<CustomerMainView> {
  int _currentIndex = 0;

  final List<Widget> _pages = const [
    CustomerHomeView(),
    CustomerRequestsView(),
    CustomerProfileView(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _pages[_currentIndex],
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(22)),
          boxShadow: [
            BoxShadow(
              color: AppTheme.primaryDark.withValues(alpha: 0.08),
              blurRadius: 16,
              offset: const Offset(0, -4),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: const BorderRadius.vertical(top: Radius.circular(22)),
          child: BottomNavigationBar(
            currentIndex: _currentIndex,
            onTap: (index) => setState(() => _currentIndex = index),
            selectedItemColor: AppTheme.primary,
            unselectedItemColor: AppTheme.textSecondary,
            selectedLabelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
            unselectedLabelStyle: const TextStyle(fontSize: 11),
            backgroundColor: Colors.white,
            elevation: 0,
            items: const [
              BottomNavigationBarItem(
                icon: Icon(Icons.home_outlined),
                activeIcon: Icon(Icons.home_rounded),
                label: 'الرئيسية',
              ),
              BottomNavigationBarItem(
                icon: Icon(Icons.receipt_long_outlined),
                activeIcon: Icon(Icons.receipt_long_rounded),
                label: 'طلباتي',
              ),
              BottomNavigationBarItem(
                icon: Icon(Icons.person_outline_rounded),
                activeIcon: Icon(Icons.person_rounded),
                label: 'حسابي',
              ),
            ],
          ),
        ),
      ),
    );
  }
}
