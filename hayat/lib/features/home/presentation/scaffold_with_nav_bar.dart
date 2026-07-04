import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../core/theme/app_theme.dart';

// GLOBAL KEY to allow children to control the Main Drawer
final GlobalKey<ScaffoldState> shellScaffoldKey = GlobalKey<ScaffoldState>();

class ScaffoldWithNavBar extends StatelessWidget {
  final Widget navigationShell;

  const ScaffoldWithNavBar({super.key, required this.navigationShell});

  @override
  Widget build(BuildContext context) {
    final currentIndex = (navigationShell as StatefulNavigationShell).currentIndex;
    
    return Scaffold(
      key: shellScaffoldKey,
      extendBody: true, // Let body extend behind the nav bar
      drawer: _buildPremiumDrawer(context),
      body: navigationShell,
      
      // Premium Curved Bottom Navigation Bar
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: const Color(0xFF121212),
          boxShadow: [
            BoxShadow(color: Colors.black.withOpacity(0.3), blurRadius: 20, offset: const Offset(0, -5)),
          ],
        ),
        child: SafeArea(
          child: Container(
            height: 70,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _NavItem(
                  icon: Icons.home_outlined,
                  selectedIcon: Icons.home,
                  label: 'Home',
                  isSelected: currentIndex == 0,
                  onTap: () => (navigationShell as StatefulNavigationShell).goBranch(0),
                ),
                _NavItem(
                  icon: Icons.history_outlined,
                  selectedIcon: Icons.history,
                  label: 'Activity',
                  isSelected: currentIndex == 1,
                  onTap: () => (navigationShell as StatefulNavigationShell).goBranch(1),
                ),
                // Center FAB Placeholder
                const SizedBox(width: 56),
                _NavItem(
                  icon: Icons.card_giftcard_outlined,
                  selectedIcon: Icons.card_giftcard,
                  label: 'Redeem',
                  isSelected: currentIndex == 2,
                  onTap: () => (navigationShell as StatefulNavigationShell).goBranch(2),
                ),
                _NavItem(
                  icon: Icons.person_outline,
                  selectedIcon: Icons.person,
                  label: 'Profile',
                  isSelected: currentIndex == 3,
                  onTap: () => (navigationShell as StatefulNavigationShell).goBranch(3),
                ),
              ],
            ),
          ),
        ),
      ),
      
      // Center Floating Action Button
      floatingActionButton: FloatingActionButton(
        onPressed: () => context.push('/chat'),
        backgroundColor: AppTheme.primaryRed,
        elevation: 8,
        child: const Icon(Icons.auto_awesome, color: Colors.white, size: 28),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
    );
  }

  Widget _buildPremiumDrawer(BuildContext context) {
    return Drawer(
      backgroundColor: const Color(0xFF0F0F0F),
      child: Column(
        children: [
          DrawerHeader(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [Color(0xFF2D0A14), Color(0xFF0F0F0F)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
            child: Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.bloodtype, size: 48, color: AppTheme.primaryRed),
                  const SizedBox(height: 12),
                  Text("HAYAT", style: GoogleFonts.outfit(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.white, letterSpacing: 2)),
                ],
              ),
            ),
          ),
          Expanded(
            child: ListView(
              padding: EdgeInsets.zero,
              children: [
                _DrawerItem(icon: Icons.favorite, label: "Hero Mode (Donor)", isSelected: true, onTap: () {}),
                _DrawerItem(icon: Icons.medical_services, label: "Patient Mode (Request)", isSelected: false, onTap: () {
                   context.push('/create-request');
                   Navigator.pop(context);
                }),
                const Divider(color: Colors.white10),
                _DrawerItem(icon: Icons.card_giftcard, label: "Redeem Rewards", onTap: () {
                  context.push('/redeem');
                  Navigator.pop(context);
                }),
                _DrawerItem(icon: Icons.settings, label: "Settings", onTap: () {
                  context.push('/settings');
                  Navigator.pop(context);
                }),
                _DrawerItem(icon: Icons.help_outline, label: "Help & Support", onTap: () {}),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(24.0),
            child: Text("v1.0.0", style: GoogleFonts.inter(color: Colors.white30, fontSize: 12)),
          ),
        ],
      ),
    );
  }
}

class _NavItem extends StatelessWidget {
  final IconData icon;
  final IconData selectedIcon;
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  const _NavItem({
    required this.icon,
    required this.selectedIcon,
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? AppTheme.primaryRed.withOpacity(0.15) : Colors.transparent,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              isSelected ? selectedIcon : icon,
              color: isSelected ? AppTheme.primaryRed : Colors.grey,
              size: 24,
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                color: isSelected ? AppTheme.primaryRed : Colors.grey,
                fontSize: 10,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _DrawerItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final bool isSelected;

  const _DrawerItem({required this.icon, required this.label, required this.onTap, this.isSelected = false});

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Icon(icon, color: isSelected ? AppTheme.primaryRed : Colors.white70),
      title: Text(label, style: TextStyle(color: isSelected ? Colors.white : Colors.white70, fontWeight: isSelected ? FontWeight.bold : FontWeight.normal)),
      tileColor: isSelected ? AppTheme.primaryRed.withOpacity(0.1) : null,
      onTap: onTap,
    );
  }
}
