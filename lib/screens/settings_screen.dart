import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:qrapp/services/settings_service.dart';
import 'package:qrapp/services/history_service.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  bool _autoFocus = true;
  bool _vibrate = true;
  bool _beep = false;
  bool _autoCopy = true;
  bool _saveHistory = true;
  String _defaultCamera = 'Rear';
  String _flashlightMode = 'Manual';
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _initSettings();
  }

  Future<void> _initSettings() async {
    final settings = await SettingsService.loadSettings();
    final cameraSettings = await SettingsService.loadCameraSettings();
    setState(() {
      _autoFocus = settings['autoFocus']!;
      _vibrate = settings['vibrate']!;
      _beep = settings['beep']!;
      _autoCopy = settings['autoCopy']!;
      _saveHistory = settings['saveHistory']!;
      _defaultCamera = cameraSettings['defaultCamera']!;
      _flashlightMode = cameraSettings['flashlightMode']!;
      _isLoading = false;
    });
  }

  Future<void> _updateSetting(String key, bool value) async {
    await SettingsService.saveSetting(key, value);
    setState(() {
      switch (key) {
        case 'autoFocus': _autoFocus = value; break;
        case 'vibrate': _vibrate = value; break;
        case 'beep': _beep = value; break;
        case 'autoCopy': _autoCopy = value; break;
        case 'saveHistory': _saveHistory = value; break;
      }
    });
  }

  Future<void> _updateCameraSetting(String key, String value) async {
    await SettingsService.saveCameraSetting(key, value);
    setState(() {
      switch (key) {
        case 'defaultCamera': _defaultCamera = value; break;
        case 'flashlightMode': _flashlightMode = value; break;
      }
    });
  }

  void _showSelectionModal(String title, String currentValue, List<String> options, String settingKey) {
    const primaryColor = Color(0xFF13EC49);
    const surfaceColor = Color(0xFF1C3022);
    const bgColor = Color(0xFF102215);

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        padding: const EdgeInsets.all(20),
        decoration: const BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey.withOpacity(0.3),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 20),
            Text(
              title,
              style: GoogleFonts.inter(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            ...options.map((option) => Container(
              margin: const EdgeInsets.only(bottom: 8),
              decoration: BoxDecoration(
                color: surfaceColor,
                borderRadius: BorderRadius.circular(12),
                border: currentValue == option 
                    ? Border.all(color: primaryColor, width: 2)
                    : null,
              ),
              child: ListTile(
                title: Text(
                  option,
                  style: GoogleFonts.inter(color: Colors.white),
                ),
                trailing: currentValue == option
                    ? const Icon(Icons.check_circle, color: primaryColor)
                    : null,
                onTap: () {
                  _updateCameraSetting(settingKey, option);
                  Navigator.pop(context);
                },
              ),
            )),
            const SizedBox(height: 10),
          ],
        ),
      ),
    );
  }

  void _showClearHistoryDialog() {
    const primaryColor = Color(0xFF13EC49);
    const bgColor = Color(0xFF102215);

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: bgColor,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(
          'Clear History',
          style: GoogleFonts.inter(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        content: Text(
          'Are you sure you want to delete all scan history? This action cannot be undone.',
          style: GoogleFonts.inter(color: Colors.grey),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'Cancel',
              style: GoogleFonts.inter(color: Colors.grey),
            ),
          ),
          TextButton(
            onPressed: () async {
              await HistoryService.clearHistory();
              Navigator.pop(context);
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('History cleared successfully!'),
                    backgroundColor: primaryColor,
                  ),
                );
              }
            },
            child: Text(
              'Delete',
              style: GoogleFonts.inter(color: Colors.red, fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _launchUrl(String urlString) async {
    final Uri url = Uri.parse(urlString);
    if (!await launchUrl(url, mode: LaunchMode.externalApplication)) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Could not open link'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    const primaryColor = Color(0xFF13EC49);
    const bgColor = Color(0xFF102215);
    const surfaceColor = Color(0xFF1C3022);

    if (_isLoading) {
      return const Scaffold(
        backgroundColor: bgColor,
        body: Center(child: CircularProgressIndicator(color: primaryColor)),
      );
    }

    return Scaffold(
      backgroundColor: bgColor,
      appBar: AppBar(
        backgroundColor: bgColor.withOpacity(0.9),
        elevation: 0,
        leadingWidth: 100,
        leading: InkWell(
          onTap: () => Navigator.pop(context),
          child: const Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.chevron_left, color: primaryColor, size: 28),
              Text(
                "Back",
                style: TextStyle(color: primaryColor, fontSize: 16, fontWeight: FontWeight.w500),
              ),
            ],
          ),
        ),
        title: Text(
          "Settings",
          style: GoogleFonts.inter(
            color: Colors.white,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 8),
            Text(
              "Scanner",
              style: GoogleFonts.inter(
                color: Colors.white,
                fontSize: 32,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 24),

            _buildSectionHeader("Scanner Preferences"),
            _buildIosGroup(surfaceColor, [
              _buildSwitchItem(
                icon: Icons.center_focus_strong,
                label: "Auto-Focus",
                value: _autoFocus,
                onChanged: (v) => _updateSetting('autoFocus', v),
                iconBg: Colors.blue.withOpacity(0.2),
                iconColor: Colors.blue,
              ),
              _buildSwitchItem(
                icon: Icons.vibration,
                label: "Vibrate on Scan",
                value: _vibrate,
                onChanged: (v) => _updateSetting('vibrate', v),
                iconBg: Colors.orange.withOpacity(0.2),
                iconColor: Colors.orange,
              ),
              _buildSwitchItem(
                icon: Icons.volume_up,
                label: "Beep on Scan",
                value: _beep,
                onChanged: (v) => _updateSetting('beep', v),
                iconBg: Colors.red.withOpacity(0.2),
                iconColor: Colors.red,
              ),
              _buildSwitchItem(
                icon: Icons.content_copy,
                label: "Auto-Copy to Clipboard",
                value: _autoCopy,
                onChanged: (v) => _updateSetting('autoCopy', v),
                iconBg: Colors.purple.withOpacity(0.2),
                iconColor: Colors.purple,
              ),
            ]),

            _buildSectionHeader("Camera & Hardware"),
            _buildIosGroup(surfaceColor, [
              _buildNavigationItem(
                icon: Icons.cameraswitch,
                label: "Default Camera",
                trailingText: _defaultCamera,
                iconBg: Colors.grey.withOpacity(0.2),
                iconColor: Colors.grey,
                onTap: () => _showSelectionModal(
                  "Default Camera",
                  _defaultCamera,
                  ["Rear", "Front"],
                  "defaultCamera",
                ),
              ),
              _buildNavigationItem(
                icon: Icons.flash_on,
                label: "Flashlight Mode",
                trailingText: _flashlightMode,
                iconBg: Colors.yellow.withOpacity(0.2),
                iconColor: Colors.yellow.shade700,
                onTap: () => _showSelectionModal(
                  "Flashlight Mode",
                  _flashlightMode,
                  ["Off", "Manual", "Auto"],
                  "flashlightMode",
                ),
              ),
            ]),

            _buildSectionHeader("History & Data"),
            _buildIosGroup(surfaceColor, [
              _buildSwitchItem(
                icon: Icons.history,
                label: "Save Scan History",
                value: _saveHistory,
                onChanged: (v) => _updateSetting('saveHistory', v),
                iconBg: primaryColor.withOpacity(0.2),
                iconColor: primaryColor,
              ),
              _buildButtonItem(
                icon: Icons.ios_share,
                label: "Export CSV",
                textColor: Colors.blue,
                iconBg: Colors.blue.withOpacity(0.2),
                iconColor: Colors.blue,
                onTap: () async {
                  try {
                    await HistoryService.exportToCsv();
                    if (mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('History exported successfully!'),
                          backgroundColor: Color(0xFF13EC49),
                        ),
                      );
                    }
                  } catch (e) {
                    if (mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(e.toString().contains('No history') 
                              ? 'No history to export' 
                              : 'Export failed'),
                          backgroundColor: Colors.red,
                        ),
                      );
                    }
                  }
                },
              ),
              _buildButtonItem(
                icon: Icons.delete_forever,
                label: "Clear History",
                textColor: Colors.red,
                iconBg: Colors.red.withOpacity(0.2),
                iconColor: Colors.red,
                onTap: () => _showClearHistoryDialog(),
              ),
            ]),

            _buildSectionHeader("Support"),
            _buildIosGroup(surfaceColor, [
              _buildNavigationItem(
                label: "Privacy Policy",
                onTap: () => _launchUrl('https://example.com/privacy-policy'),
              ),
              _buildNavigationItem(
                label: "Rate App",
                onTap: () => _launchUrl('https://play.google.com/store/apps/details?id=com.qr.fastqr'),
              ),
              _buildNavigationItem(
                label: "Help Center",
                trailing: const Icon(Icons.open_in_new, size: 18, color: Colors.grey),
                onTap: () => _launchUrl('https://example.com/help'),
              ),
            ]),

            const SizedBox(height: 32),
            Center(
              child: Column(
                children: [
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: surfaceColor,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.white.withOpacity(0.05)),
                    ),
                    child: const Icon(Icons.qr_code_scanner, color: primaryColor),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    "QuickScan Pro",
                    style: GoogleFonts.inter(
                      color: Colors.grey,
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  Text(
                    "Version 1.0.4 (Build 2023)",
                    style: GoogleFonts.inter(
                      color: Colors.grey.withOpacity(0.5),
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 48),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(left: 4, bottom: 8),
      child: Text(
        title.toUpperCase(),
        style: GoogleFonts.inter(
          color: Colors.grey,
          fontSize: 12,
          fontWeight: FontWeight.bold,
          letterSpacing: 1,
        ),
      ),
    );
  }

  Widget _buildIosGroup(Color backgroundColor, List<Widget> children) {
    return Container(
      margin: const EdgeInsets.only(bottom: 24),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: children,
      ),
    );
  }

  Widget _buildSwitchItem({
    required IconData icon,
    required String label,
    required bool value,
    required ValueChanged<bool> onChanged,
    required Color iconBg,
    required Color iconColor,
  }) {
    return _buildItemWrapper(
      child: Row(
        children: [
          _buildLeadingIcon(icon, iconBg, iconColor),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              label,
              style: GoogleFonts.inter(color: Colors.white, fontSize: 16),
            ),
          ),
          CupertinoSwitch(
            value: value,
            activeColor: const Color(0xFF13EC49),
            onChanged: onChanged,
          ),
        ],
      ),
    );
  }

  Widget _buildNavigationItem({
    IconData? icon,
    required String label,
    String? trailingText,
    Widget? trailing,
    Color? iconBg,
    Color? iconColor,
    VoidCallback? onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: _buildItemWrapper(
        child: Row(
          children: [
            if (icon != null) ...[
              _buildLeadingIcon(icon, iconBg!, iconColor!),
              const SizedBox(width: 12),
            ],
            Expanded(
              child: Text(
                label,
                style: GoogleFonts.inter(color: Colors.white, fontSize: 16),
              ),
            ),
            if (trailingText != null)
              Text(
                trailingText,
                style: GoogleFonts.inter(color: Colors.grey, fontSize: 14),
              ),
            const SizedBox(width: 8),
            trailing ?? const Icon(Icons.chevron_right, color: Colors.grey),
          ],
        ),
      ),
    );
  }

  Widget _buildButtonItem({
    required IconData icon,
    required String label,
    required Color textColor,
    required Color iconBg,
    required Color iconColor,
    VoidCallback? onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: _buildItemWrapper(
        child: Row(
          children: [
            _buildLeadingIcon(icon, iconBg, iconColor),
            const SizedBox(width: 12),
            Text(
              label,
              style: GoogleFonts.inter(
                color: textColor,
                fontSize: 16,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildItemWrapper({required Widget child}) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(color: Colors.white.withOpacity(0.05)),
        ),
      ),
      child: child,
    );
  }

  Widget _buildLeadingIcon(IconData icon, Color bg, Color color) {
    return Container(
      width: 32,
      height: 32,
      decoration: BoxDecoration(
        color: bg,
        shape: BoxShape.circle,
      ),
      child: Icon(icon, color: color, size: 20),
    );
  }
}
