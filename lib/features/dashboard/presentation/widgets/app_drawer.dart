import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../theme/colors.dart';

class AppDrawer extends StatelessWidget {
  const AppDrawer({super.key});

  void _showAboutDialog(BuildContext context) {
    Navigator.pop(context); // Close drawer first
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(28),
          ),
          elevation: 0,
          backgroundColor: Colors.transparent,
          child: Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(28),
              boxShadow: [
                BoxShadow(
                  color: AppColors.primary.withOpacity(0.08),
                  blurRadius: 24,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 60,
                  height: 60,
                  decoration: BoxDecoration(
                    color: AppColors.primaryLight,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.baby_changing_station_rounded,
                    color: AppColors.primary,
                    size: 32,
                  ),
                ),
                const SizedBox(height: 20),
                Text(
                  'About Maatriva',
                  style: GoogleFonts.playfairDisplay(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Version 1.0.0 (Beta)',
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    color: AppColors.textSecondary.withOpacity(0.6),
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  'Maatriva is a premium, AI-powered smart baby monitoring ecosystem designed by pediatric specialists and IoT engineers. Our mission is to provide mothers and caregivers with clinical-grade, predictive health analytics and soothing automation to ensure every child sleeps safe and grows healthy.',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.inter(
                    fontSize: 13,
                    color: AppColors.textSecondary,
                    height: 1.5,
                  ),
                ),
                const SizedBox(height: 24),
                ElevatedButton(
                  onPressed: () => Navigator.pop(context),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    minimumSize: const Size(double.infinity, 44),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    elevation: 0,
                  ),
                  child: const Text('Close'),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Drawer(
      backgroundColor: AppColors.background,
      elevation: 0,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.only(
          topRight: Radius.circular(32),
          bottomRight: Radius.circular(32),
        ),
      ),
      child: Column(
        children: [
          // Drawer Header
          UserAccountsDrawerHeader(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [AppColors.primary, Color(0xFF8A59FA)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.only(
                topRight: Radius.circular(32),
              ),
            ),
            currentAccountPicture: Container(
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white, width: 2),
              ),
              child: const CircleAvatar(
                backgroundImage: NetworkImage(
                  "https://images.unsplash.com/photo-1544005313-94ddf0286df2?auto=format&fit=crop&q=80&w=120",
                ),
              ),
            ),
            accountName: Text(
              'Sarah Johnson',
              style: GoogleFonts.inter(
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
            accountEmail: Text(
              'sarah.johnson@maatriva.com',
              style: GoogleFonts.inter(
                color: Colors.white.withOpacity(0.8),
                fontSize: 12,
              ),
            ),
          ),

          // Drawer items
          Expanded(
            child: ListView(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  child: Text(
                    'QUICK ACTIONS',
                    style: GoogleFonts.inter(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textSecondary.withOpacity(0.5),
                      letterSpacing: 1.2,
                    ),
                  ),
                ),
                _buildDrawerTile(
                  context,
                  icon: Icons.smart_toy_outlined,
                  label: 'AI Assistant',
                  onTap: () {
                    Navigator.pop(context);
                    context.push('/ai-assistant');
                  },
                ),
                _buildDrawerTile(
                  context,
                  icon: Icons.favorite_border_rounded,
                  label: 'Predictive Health',
                  onTap: () {
                    Navigator.pop(context);
                    context.push('/predictive-health');
                  },
                ),
                _buildDrawerTile(
                  context,
                  icon: Icons.music_note_outlined,
                  label: 'Music Soother',
                  onTap: () {
                    Navigator.pop(context);
                    context.push('/music');
                  },
                ),
                _buildDrawerTile(
                  context,
                  icon: Icons.share_rounded,
                  label: 'Caregiver Access',
                  onTap: () {
                    Navigator.pop(context);
                    context.push('/caregiver-access');
                  },
                ),
                _buildDrawerTile(
                  context,
                  icon: Icons.shopping_bag_outlined,
                  label: 'Nursery Shop',
                  onTap: () {
                    Navigator.pop(context);
                    context.push('/shop');
                  },
                ),
                _buildDrawerTile(
                  context,
                  icon: Icons.videocam_outlined,
                  label: 'Live Camera Feed',
                  onTap: () {
                    Navigator.pop(context);
                    context.go('/?tab=1');
                  },
                ),
                const Divider(height: 32, color: AppColors.divider),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  child: Text(
                    'INFORMATION',
                    style: GoogleFonts.inter(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textSecondary.withOpacity(0.5),
                      letterSpacing: 1.2,
                    ),
                  ),
                ),
                _buildDrawerTile(
                  context,
                  icon: Icons.info_outline_rounded,
                  label: 'About Us',
                  onTap: () => _showAboutDialog(context),
                ),
              ],
            ),
          ),
          
          // Version footer
          Padding(
            padding: const EdgeInsets.only(bottom: 24),
            child: Text(
              'Maatriva Smart Baby Monitor v1.0.0',
              style: GoogleFonts.inter(
                fontSize: 10,
                color: AppColors.textSecondary.withOpacity(0.4),
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDrawerTile(
    BuildContext context, {
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return ListTile(
      leading: Icon(icon, color: AppColors.primary, size: 22),
      title: Text(
        label,
        style: GoogleFonts.inter(
          fontSize: 14,
          fontWeight: FontWeight.w600,
          color: AppColors.textPrimary,
        ),
      ),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      onTap: onTap,
      dense: true,
    );
  }
}
