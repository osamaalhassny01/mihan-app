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
        decoration: const BoxDecoration(
          border: Border(top: BorderSide(color: AppTheme.border)),
        ),
        child: BottomNavigationBar(
          currentIndex: _currentIndex,
          onTap: (index) => setState(() => _currentIndex = index),
          selectedItemColor: AppTheme.secondary,
          unselectedItemColor: AppTheme.textSecondary,
          backgroundColor: Colors.white,
          elevation: 0,
          items: const [
            BottomNavigationBarItem(
              icon: Icon(Icons.home_outlined),
              activeIcon: Icon(Icons.home),
              label: 'الرئيسية',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.assignment_outlined),
              activeIcon: Icon(Icons.assignment),
              label: 'طلباتي',
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
