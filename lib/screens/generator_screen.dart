import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:share_plus/share_plus.dart';
import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:io';
import 'dart:ui' as ui;
import 'package:flutter/rendering.dart';
import 'package:qrapp/services/saved_service.dart';
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

// Recent generated item model
class RecentGeneratedItem {
  final String data;
  final String type;
  final String? label;
  final int colorValue;
  final int patternIndex;
  final DateTime createdAt;

  RecentGeneratedItem({
    required this.data,
    required this.type,
    this.label,
    required this.colorValue,
    required this.patternIndex,
    required this.createdAt,
  });

  Map<String, dynamic> toJson() => {
    'data': data,
    'type': type,
    'label': label,
    'colorValue': colorValue,
    'patternIndex': patternIndex,
    'createdAt': createdAt.toIso8601String(),
  };

  factory RecentGeneratedItem.fromJson(Map<String, dynamic> json) => RecentGeneratedItem(
    data: json['data'],
    type: json['type'],
    label: json['label'],
    colorValue: json['colorValue'],
    patternIndex: json['patternIndex'],
    createdAt: DateTime.parse(json['createdAt']),
  );
}

class GeneratorScreen extends StatefulWidget {
  const GeneratorScreen({super.key});

  @override
  State<GeneratorScreen> createState() => _GeneratorScreenState();
}

const primaryColor = Color(0xFF13EC49);
const backgroundColor = Color(0xFF000000);
const surfaceColor = Color(0xFF171717);

class _GeneratorScreenState extends State<GeneratorScreen> {
  final TextEditingController _contentController = TextEditingController();
  final TextEditingController _labelController = TextEditingController();
  final GlobalKey _qrKey = GlobalKey();
  
  String _selectedType = 'Website';
  Color _selectedColor = primaryColor;
  int _selectedPattern = 0; // 0: Square, 1: Rounded, 2: Circle, 3: Diamond
  String? _generatedData;
  List<RecentGeneratedItem> _recentItems = [];

  final List<Map<String, dynamic>> _types = [
    {'name': 'Website', 'icon': Icons.language, 'hint': 'https://example.com'},
    {'name': 'Text', 'icon': Icons.description, 'hint': 'Enter your text here'},
    {'name': 'Wi-Fi', 'icon': Icons.wifi, 'hint': 'Network name'},
    {'name': 'Contact', 'icon': Icons.person, 'hint': 'Full name'},
    {'name': 'Email', 'icon': Icons.email, 'hint': 'email@example.com'},
    {'name': 'Phone', 'icon': Icons.phone, 'hint': '+1234567890'},
    {'name': 'Social', 'icon': Icons.share, 'hint': 'Select platform'},
    {'name': 'Image', 'icon': Icons.image, 'hint': 'https://example.com/image.jpg'},
    {'name': 'Video', 'icon': Icons.play_circle, 'hint': 'https://youtube.com/watch?v=...'},
    {'name': 'MP3', 'icon': Icons.audiotrack, 'hint': 'https://example.com/audio.mp3'},
    {'name': 'PDF', 'icon': Icons.picture_as_pdf, 'hint': 'https://example.com/document.pdf'},
    {'name': 'Apps', 'icon': Icons.apps, 'hint': 'Select store'},
  ];

  final List<Color> _colors = [
    Colors.black,
    const Color(0xFF13EC49),
    Colors.blue,
    Colors.purple,
    Colors.orange,
    Colors.red,
    const Color(0xFF00BCD4), // Cyan
    const Color(0xFFE91E63), // Pink
  ];

  final List<Map<String, dynamic>> _patterns = [
    {'name': 'Classic', 'icon': Icons.grid_4x4, 'eyeShape': QrEyeShape.square, 'dataShape': QrDataModuleShape.square, 'isCrazy': false},
    {'name': 'Rounded', 'icon': Icons.apps_rounded, 'eyeShape': QrEyeShape.circle, 'dataShape': QrDataModuleShape.square, 'isCrazy': false},
    {'name': 'Dots', 'icon': Icons.blur_circular, 'eyeShape': QrEyeShape.circle, 'dataShape': QrDataModuleShape.circle, 'isCrazy': true},
    {'name': 'Soft', 'icon': Icons.rounded_corner, 'eyeShape': QrEyeShape.square, 'dataShape': QrDataModuleShape.circle, 'isCrazy': true},
  ];

  final List<List<Color>> _gradients = [
    [Colors.black, Colors.black], // Solid
    [const Color(0xFF13EC49), const Color(0xFF00BCD4)], // Neon Green to Cyan
    [const Color(0xFF7B1FA2), const Color(0xFFE91E63)], // Purple to Pink
    [const Color(0xFFFF5722), const Color(0xFFFFC107)], // Deep Orange to Amber
    [const Color(0xFF2196F3), const Color(0xFF00BCD4)], // Blue to Light Blue
    [const Color(0xFF673AB7), const Color(0xFF3F51B5)], // Deep Purple to Indigo
  ];

  int _selectedGradientIndex = 0;
  bool _showLogo = true;

  // WiFi specific fields
  final TextEditingController _wifiPasswordController = TextEditingController();
  String _wifiEncryption = 'WPA';

  // Contact specific fields
  final TextEditingController _contactPhoneController = TextEditingController();
  final TextEditingController _contactEmailController = TextEditingController();

  // Social Media specific fields
  String _selectedSocialPlatform = 'Instagram';
  final List<Map<String, dynamic>> _socialPlatforms = [
    {'name': 'Instagram', 'icon': Icons.camera_alt, 'prefix': 'https://instagram.com/'},
    {'name': 'Twitter/X', 'icon': Icons.alternate_email, 'prefix': 'https://x.com/'},
    {'name': 'Facebook', 'icon': Icons.facebook, 'prefix': 'https://facebook.com/'},
    {'name': 'TikTok', 'icon': Icons.music_note, 'prefix': 'https://tiktok.com/@'},
    {'name': 'LinkedIn', 'icon': Icons.work, 'prefix': 'https://linkedin.com/in/'},
    {'name': 'YouTube', 'icon': Icons.play_circle_filled, 'prefix': 'https://youtube.com/@'},
    {'name': 'Snapchat', 'icon': Icons.camera, 'prefix': 'https://snapchat.com/add/'},
    {'name': 'WhatsApp', 'icon': Icons.chat, 'prefix': 'https://wa.me/'},
    {'name': 'Telegram', 'icon': Icons.send, 'prefix': 'https://t.me/'},
  ];

  // App Store specific fields
  String _selectedAppStore = 'Google Play';
  final List<Map<String, dynamic>> _appStores = [
    {'name': 'Google Play', 'icon': Icons.android, 'prefix': 'https://play.google.com/store/apps/details?id='},
    {'name': 'App Store', 'icon': Icons.apple, 'prefix': 'https://apps.apple.com/app/id'},
    {'name': 'Huawei AppGallery', 'icon': Icons.phone_android, 'prefix': 'https://appgallery.huawei.com/app/'},
  ];

  @override
  void initState() {
    super.initState();
    _loadRecentItems();
  }

  @override
  void dispose() {
    _contentController.dispose();
    _labelController.dispose();
    _wifiPasswordController.dispose();
    _contactPhoneController.dispose();
    _contactEmailController.dispose();
    super.dispose();
  }

  Future<void> _loadRecentItems() async {
    final prefs = await SharedPreferences.getInstance();
    final jsonString = prefs.getString('recent_generated');
    if (jsonString != null) {
      final List<dynamic> decoded = jsonDecode(jsonString);
      setState(() {
        _recentItems = decoded.map((e) => RecentGeneratedItem.fromJson(e)).toList();
      });
    }
  }

  Future<void> _saveRecentItem(RecentGeneratedItem item) async {
    _recentItems.insert(0, item);
    if (_recentItems.length > 10) {
      _recentItems = _recentItems.sublist(0, 10);
    }
    
    final prefs = await SharedPreferences.getInstance();
    final encoded = jsonEncode(_recentItems.map((e) => e.toJson()).toList());
    await prefs.setString('recent_generated', encoded);
    setState(() {});
  }

  String _buildQRData() {
    final content = _contentController.text.trim();
    if (content.isEmpty) return '';

    switch (_selectedType) {
      case 'Website':
        if (!content.startsWith('http://') && !content.startsWith('https://')) {
          return 'https://$content';
        }
        return content;
      case 'Wi-Fi':
        final password = _wifiPasswordController.text;
        return 'WIFI:S:$content;T:$_wifiEncryption;P:$password;;';
      case 'Contact':
        final phone = _contactPhoneController.text;
        final email = _contactEmailController.text;
        return 'MECARD:N:$content;TEL:$phone;EMAIL:$email;;';
      case 'Email':
        return 'mailto:$content';
      case 'Phone':
        return 'tel:$content';
      case 'Social':
        final platform = _socialPlatforms.firstWhere(
          (p) => p['name'] == _selectedSocialPlatform,
          orElse: () => _socialPlatforms[0],
        );
        return '${platform['prefix']}$content';
      case 'Image':
      case 'Video':
      case 'MP3':
      case 'PDF':
        // For media types, just ensure it's a valid URL
        if (!content.startsWith('http://') && !content.startsWith('https://')) {
          return 'https://$content';
        }
        return content;
      case 'Apps':
        final store = _appStores.firstWhere(
          (s) => s['name'] == _selectedAppStore,
          orElse: () => _appStores[0],
        );
        return '${store['prefix']}$content';
      default:
        return content;
    }
  }

  void _generateQR() {
    final data = _buildQRData();
    if (data.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter content to generate QR code'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() {
      _generatedData = data;
    });

    // Save to recent
    _saveRecentItem(RecentGeneratedItem(
      data: data,
      type: _selectedType,
      label: _labelController.text.isNotEmpty ? _labelController.text : null,
      colorValue: _selectedColor.value,
      patternIndex: _selectedPattern,
      createdAt: DateTime.now(),
    ));

    // Show result modal
    _showResultModal();
  }

  Future<void> _downloadQRCode() async {
    try {
      final boundary = _qrKey.currentContext?.findRenderObject() as RenderRepaintBoundary?;
      if (boundary == null) return;

      final image = await boundary.toImage(pixelRatio: 4.0);
      final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
      if (byteData == null) return;

      final directory = await getApplicationDocumentsDirectory();
      final fileName = 'qr_code_${DateTime.now().millisecondsSinceEpoch}.png';
      final file = File('${directory.path}/$fileName');
      await file.writeAsBytes(byteData.buffer.asUint8List());

      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Saved to $fileName'),
            backgroundColor: const Color(0xFF13EC49),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to save: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _shareQRCode() async {
    try {
      // Wait for the widget to be rendered
      await Future.delayed(const Duration(milliseconds: 100));
      
      final boundary = _qrKey.currentContext?.findRenderObject() as RenderRepaintBoundary?;
      if (boundary == null) {
        throw Exception('QR code not rendered');
      }

      final image = await boundary.toImage(pixelRatio: 3.0);
      final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
      if (byteData == null) {
        throw Exception('Failed to convert to image');
      }

      final directory = await getTemporaryDirectory();
      final file = File('${directory.path}/qr_code_${DateTime.now().millisecondsSinceEpoch}.png');
      await file.writeAsBytes(byteData.buffer.asUint8List());

      Navigator.pop(context);
      
      await Share.shareXFiles(
        [XFile(file.path)],
        subject: 'QR Code',
        text: _labelController.text.isNotEmpty ? _labelController.text : 'Check out my QR code!',
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to share: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _showQRPreview() {
    final data = _generatedData!;
    final pattern = _patterns[_selectedPattern];
    final gradientColors = _gradients[_selectedGradientIndex];
    
    // Determine logo based on type
    IconData? typeIcon;
    if (_showLogo) {
      if (_selectedType == 'Social') {
        typeIcon = _socialPlatforms.firstWhere((p) => p['name'] == _selectedSocialPlatform)['icon'];
      } else if (_selectedType == 'Apps') {
        typeIcon = _appStores.firstWhere((s) => s['name'] == _selectedAppStore)['icon'];
      } else {
        typeIcon = _types.firstWhere((t) => t['name'] == _selectedType)['icon'];
      }
    }

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => StatefulBuilder(
        builder: (context, setModalState) => Container(
          height: MediaQuery.of(context).size.height * 0.85,
          decoration: const BoxDecoration(
            color: backgroundColor,
            borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
          ),
          padding: const EdgeInsets.all(24),
          child: Column(
            children: [
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 24),
              Text(
                'Ready to Use!',
                style: GoogleFonts.outfit(
                  color: Colors.white,
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Scan to test your custom QR code',
                style: GoogleFonts.inter(
                  color: Colors.grey,
                  fontSize: 14,
                ),
              ),
              const SizedBox(height: 40),
              // QR Display with Gradient Effect
              Center(
                child: RepaintBoundary(
                  key: _qrKey,
                  child: Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(24),
                      boxShadow: [
                        BoxShadow(
                          color: gradientColors[0].withOpacity(0.3),
                          blurRadius: 30,
                          spreadRadius: 5,
                        ),
                      ],
                    ),
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        ShaderMask(
                          shaderCallback: (bounds) => LinearGradient(
                            colors: gradientColors,
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ).createShader(bounds),
                          blendMode: BlendMode.srcIn,
                          child: QrImageView(
                            data: data,
                            version: QrVersions.auto,
                            size: 240,
                            gapless: false,
                            eyeStyle: QrEyeStyle(
                              eyeShape: pattern['eyeShape'] as QrEyeShape,
                              color: Colors.black, // Color is overridden by ShaderMask
                            ),
                            dataModuleStyle: QrDataModuleStyle(
                              dataModuleShape: pattern['dataShape'] as QrDataModuleShape,
                              color: Colors.black, // Color is overridden by ShaderMask
                            ),
                          ),
                        ),
                        if (_showLogo && typeIcon != null)
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              shape: BoxShape.circle,
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.1),
                                  blurRadius: 10,
                                )
                              ],
                            ),
                            child: Icon(
                              typeIcon,
                              size: 32,
                              color: gradientColors[0],
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 40),
              if (_labelController.text.isNotEmpty)
                Text(
                  _labelController.text,
                  style: GoogleFonts.inter(
                    color: Colors.white,
                  ),
                ),
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: gradientColors[0].withOpacity(0.2),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      _selectedType,
                      style: GoogleFonts.inter(
                        color: gradientColors[0],
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      pattern['name'],
                      style: GoogleFonts.inter(
                        color: Colors.grey,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 32),
              // Action buttons
              Row(
                children: [
                  Expanded(
                    child: _buildModalButton(
                      icon: Icons.download,
                      label: 'Download',
                      onTap: _downloadQRCode,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildModalButton(
                      icon: Icons.share,
                      label: 'Share',
                      onTap: _shareQRCode,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildModalButton(
                      icon: Icons.bookmark_add,
                      label: 'Save',
                      onTap: () async {
                        await SavedService.addToSaved(
                          _generatedData!,
                          _selectedType,
                          label: _labelController.text.isNotEmpty ? _labelController.text : null,
                        );
                        Navigator.pop(context);
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('Saved to your collection!'),
                            backgroundColor: gradientColors[0],
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              // Copy button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () {
                    Clipboard.setData(ClipboardData(text: _generatedData!));
                    Navigator.pop(context);
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Copied to clipboard!'),
                        backgroundColor: gradientColors[0],
                      ),
                    );
                  },
                  icon: const Icon(Icons.copy, size: 20),
                  label: Text(
                    'Copy Content',
                    style: GoogleFonts.inter(fontWeight: FontWeight.w600),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.white.withOpacity(0.05),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }

  void _showResultModal() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => StatefulBuilder(
        builder: (context, setModalState) => Container(
          decoration: const BoxDecoration(
            color: backgroundColor,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          padding: const EdgeInsets.all(24),
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
              const SizedBox(height: 24),
              Text(
                'Your QR Code',
                style: GoogleFonts.inter(
                  color: Colors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 24),
              // QR Code
              RepaintBoundary(
                key: _qrKey,
                child: Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: _selectedColor.withOpacity(0.3),
                        blurRadius: 20,
                        spreadRadius: 2,
                      ),
                    ],
                  ),
                  child: QrImageView(
                    data: _generatedData!,
                    version: QrVersions.auto,
                    size: 200,
                    backgroundColor: Colors.white,
                    eyeStyle: QrEyeStyle(
                      eyeShape: _patterns[_selectedPattern]['eyeShape'],
                      color: _selectedColor,
                    ),
                    dataModuleStyle: QrDataModuleStyle(
                      dataModuleShape: _patterns[_selectedPattern]['dataShape'],
                      color: _selectedColor,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              if (_labelController.text.isNotEmpty)
                Text(
                  _labelController.text,
                  style: GoogleFonts.inter(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: _selectedColor.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      _selectedType,
                      style: GoogleFonts.inter(
                        color: _selectedColor == Colors.black ? primaryColor : _selectedColor,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      _patterns[_selectedPattern]['name'],
                      style: GoogleFonts.inter(
                        color: Colors.grey,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 32),
              // Action buttons - First row
              Row(
                children: [
                  Expanded(
                    child: _buildModalButton(
                      icon: Icons.download,
                      label: 'Download',
                      onTap: _downloadQRCode,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildModalButton(
                      icon: Icons.share,
                      label: 'Share',
                      onTap: _shareQRCode,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildModalButton(
                      icon: Icons.bookmark_add,
                      label: 'Save',
                      onTap: () async {
                        await SavedService.addToSaved(
                          _generatedData!,
                          _selectedType,
                          label: _labelController.text.isNotEmpty ? _labelController.text : null,
                        );
                        Navigator.pop(context);
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Saved to your collection!'),
                            backgroundColor: primaryColor,
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              // Copy button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () {
                    Clipboard.setData(ClipboardData(text: _generatedData!));
                    Navigator.pop(context);
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Copied to clipboard!'),
                        backgroundColor: primaryColor,
                      ),
                    );
                  },
                  icon: const Icon(Icons.copy, size: 20),
                  label: Text(
                    'Copy Content',
                    style: GoogleFonts.inter(fontWeight: FontWeight.w600),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.white.withOpacity(0.05),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildModalButton({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.05),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.white.withOpacity(0.1)),
        ),
        child: Column(
          children: [
            Icon(icon, color: Colors.white, size: 24),
            const SizedBox(height: 8),
            Text(
              label,
              style: GoogleFonts.inter(
                color: Colors.white,
                fontSize: 12,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _formatTime(DateTime dateTime) {
    final hour = dateTime.hour;
    final minute = dateTime.minute.toString().padLeft(2, '0');
    final period = hour >= 12 ? 'PM' : 'AM';
    final displayHour = hour > 12 ? hour - 12 : (hour == 0 ? 12 : hour);
    return '$displayHour:$minute $period';
  }

  @override
  Widget build(BuildContext context) {
    const primaryColor = Color(0xFF13EC49);
    const bgColor = Color(0xFF102215);
    const surfaceColor = Color(0xFF1C3022);

    return Scaffold(
      backgroundColor: bgColor,
      appBar: AppBar(
        backgroundColor: bgColor,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: primaryColor),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Create QR Code',
          style: GoogleFonts.inter(
            color: Colors.white,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
      ),
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Type Selector Chips
                  SizedBox(
                    height: 44,
                    child: ListView.builder(
                      scrollDirection: Axis.horizontal,
                      itemCount: _types.length,
                      itemBuilder: (context, index) {
                        final type = _types[index];
                        final isSelected = _selectedType == type['name'];
                        
                        return Padding(
                          padding: EdgeInsets.only(right: 12, left: index == 0 ? 0 : 0),
                          child: GestureDetector(
                            onTap: () {
                              setState(() {
                                _selectedType = type['name'];
                                _contentController.clear();
                              });
                            },
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 200),
                              padding: const EdgeInsets.symmetric(horizontal: 20),
                              decoration: BoxDecoration(
                                color: isSelected ? primaryColor : surfaceColor,
                                borderRadius: BorderRadius.circular(22),
                                border: isSelected ? null : Border.all(color: Colors.white.withOpacity(0.05)),
                                boxShadow: isSelected ? [
                                  BoxShadow(
                                    color: primaryColor.withOpacity(0.3),
                                    blurRadius: 12,
                                    offset: const Offset(0, 4),
                                  ),
                                ] : null,
                              ),
                              child: Row(
                                children: [
                                  Icon(
                                    type['icon'],
                                    size: 20,
                                    color: isSelected ? Colors.black : Colors.grey,
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    type['name'],
                                    style: GoogleFonts.inter(
                                      color: isSelected ? Colors.black : Colors.white,
                                      fontSize: 14,
                                      fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                  const SizedBox(height: 32),

                  // Main Input Field
                  _buildInputField(
                    label: _getInputLabel(),
                    hint: _types.firstWhere((t) => t['name'] == _selectedType)['hint'],
                    controller: _contentController,
                    icon: _getInputIcon(),
                  ),
                  const SizedBox(height: 20),

                  // Type-specific fields
                  if (_selectedType == 'Wi-Fi') ...[
                    _buildInputField(
                      label: 'Password',
                      hint: 'Network password',
                      controller: _wifiPasswordController,
                      icon: Icons.lock,
                      isPassword: true,
                    ),
                    const SizedBox(height: 20),
                    Text(
                      'Encryption',
                      style: GoogleFonts.inter(
                        color: Colors.white,
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: ['WPA', 'WEP', 'None'].map((enc) {
                        final isSelected = _wifiEncryption == enc;
                        return Padding(
                          padding: const EdgeInsets.only(right: 12),
                          child: GestureDetector(
                            onTap: () => setState(() => _wifiEncryption = enc),
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                              decoration: BoxDecoration(
                                color: isSelected ? primaryColor : surfaceColor,
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Text(
                                enc,
                                style: GoogleFonts.inter(
                                  color: isSelected ? Colors.black : Colors.white,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 20),
                  ],

                  if (_selectedType == 'Social') ...[
                    // Social Platform Selector
                    Text(
                      'PLATFORM',
                      style: GoogleFonts.inter(
                        color: Colors.grey,
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 1,
                      ),
                    ),
                    const SizedBox(height: 12),
                    SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        children: _socialPlatforms.map((platform) {
                          final isSelected = _selectedSocialPlatform == platform['name'];
                          return GestureDetector(
                            onTap: () => setState(() => _selectedSocialPlatform = platform['name']),
                            child: Container(
                              margin: const EdgeInsets.only(right: 12),
                              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                              decoration: BoxDecoration(
                                color: isSelected ? primaryColor : Colors.white.withOpacity(0.05),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: isSelected ? primaryColor : Colors.white.withOpacity(0.1),
                                ),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    platform['icon'],
                                    size: 18,
                                    color: isSelected ? Colors.black : Colors.white,
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    platform['name'],
                                    style: GoogleFonts.inter(
                                      color: isSelected ? Colors.black : Colors.white,
                                      fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          );
                        }).toList(),
                      ),
                    ),
                    const SizedBox(height: 20),
                    _buildInputField(
                      label: 'Username / Handle',
                      hint: 'example_user',
                      controller: _contentController,
                      icon: Icons.alternate_email,
                    ),
                    const SizedBox(height: 20),
                  ],

                  if (_selectedType == 'Apps') ...[
                    // App Store Selector
                    Text(
                      'STORE',
                      style: GoogleFonts.inter(
                        color: Colors.grey,
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 1,
                      ),
                    ),
                    const SizedBox(height: 12),
                    SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        children: _appStores.map((store) {
                          final isSelected = _selectedAppStore == store['name'];
                          return GestureDetector(
                            onTap: () => setState(() => _selectedAppStore = store['name']),
                            child: Container(
                              margin: const EdgeInsets.only(right: 12),
                              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                              decoration: BoxDecoration(
                                color: isSelected ? primaryColor : Colors.white.withOpacity(0.05),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: isSelected ? primaryColor : Colors.white.withOpacity(0.1),
                                ),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    store['icon'],
                                    size: 18,
                                    color: isSelected ? Colors.black : Colors.white,
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    store['name'],
                                    style: GoogleFonts.inter(
                                      color: isSelected ? Colors.black : Colors.white,
                                      fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          );
                        }).toList(),
                      ),
                    ),
                    const SizedBox(height: 20),
                    _buildInputField(
                      label: 'Package ID / App ID',
                      hint: 'com.example.app',
                      controller: _contentController,
                      icon: Icons.get_app,
                    ),
                    const SizedBox(height: 20),
                  ],

                  if (['Image', 'Video', 'MP3', 'PDF'].contains(_selectedType)) ...[
                    _buildInputField(
                      label: 'Public Link',
                      hint: 'https://example.com/file.pdf',
                      controller: _contentController,
                      icon: Icons.link,
                    ),
                    const SizedBox(height: 20),
                  ],

                  if (_selectedType == 'Contact') ...[
                    _buildInputField(
                      label: 'Phone Number',
                      hint: '+1234567890',
                      controller: _contactPhoneController,
                      icon: Icons.phone,
                    ),
                    const SizedBox(height: 20),
                    _buildInputField(
                      label: 'Email',
                      hint: 'email@example.com',
                      controller: _contactEmailController,
                      icon: Icons.email,
                    ),
                    const SizedBox(height: 20),
                  ],

                  // Label (Optional)
                  _buildInputField(
                    label: 'Label (Optional)',
                    hint: 'My QR Code',
                    controller: _labelController,
                    icon: Icons.label_outline,
                  ),
                  const SizedBox(height: 32),

                  // Customize Design Section
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Customize Design',
                        style: GoogleFonts.inter(
                          color: Colors.white,
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: primaryColor.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          'NEW',
                          style: GoogleFonts.inter(
                            color: primaryColor,
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: surfaceColor,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Style Selection (Solid vs Gradient)
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'QR STYLE',
                              style: GoogleFonts.inter(
                                color: Colors.grey,
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                                letterSpacing: 1,
                              ),
                            ),
                            Switch(
                              value: _showLogo,
                              onChanged: (v) => setState(() => _showLogo = v),
                              activeColor: primaryColor,
                              materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                            ),
                            Text(
                              'ADD LOGO',
                              style: GoogleFonts.inter(
                                color: _showLogo ? primaryColor : Colors.grey,
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        // Gradient Selection
                        SingleChildScrollView(
                          scrollDirection: Axis.horizontal,
                          child: Row(
                            children: _gradients.asMap().entries.map((entry) {
                              final index = entry.key;
                              final colors = entry.value;
                              final isSelected = _selectedGradientIndex == index;
                              
                              return GestureDetector(
                                onTap: () => setState(() => _selectedGradientIndex = index),
                                child: Container(
                                  margin: const EdgeInsets.only(right: 12),
                                  width: 45,
                                  height: 45,
                                  decoration: BoxDecoration(
                                    gradient: LinearGradient(
                                      colors: colors,
                                      begin: Alignment.topLeft,
                                      end: Alignment.bottomRight,
                                    ),
                                    shape: BoxShape.circle,
                                    border: isSelected
                                        ? Border.all(color: Colors.white, width: 3)
                                        : Border.all(color: Colors.white.withOpacity(0.1)),
                                    boxShadow: isSelected ? [
                                      BoxShadow(
                                        color: colors[0].withOpacity(0.5),
                                        blurRadius: 10,
                                        spreadRadius: 2,
                                      )
                                    ] : null,
                                  ),
                                  child: isSelected ? const Icon(Icons.check, color: Colors.white, size: 20) : null,
                                ),
                              );
                            }).toList(),
                          ),
                        ),
                        const SizedBox(height: 24),
                        Divider(color: Colors.white.withOpacity(0.1)),
                        const SizedBox(height: 20),
                        // Pattern Selection
                        Text(
                          'PATTERN',
                          style: GoogleFonts.inter(
                            color: Colors.grey,
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 1,
                          ),
                        ),
                        const SizedBox(height: 12),
                        Row(
                          children: List.generate(_patterns.length, (index) {
                            final pattern = _patterns[index];
                            final isSelected = _selectedPattern == index;
                            return GestureDetector(
                              onTap: () => setState(() => _selectedPattern = index),
                              child: Container(
                                margin: const EdgeInsets.only(right: 12),
                                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                                decoration: BoxDecoration(
                                  color: isSelected ? primaryColor : bgColor,
                                  borderRadius: BorderRadius.circular(12),
                                  border: isSelected
                                      ? null
                                      : Border.all(color: Colors.white.withOpacity(0.1)),
                                ),
                                child: Column(
                                  children: [
                                    Icon(
                                      pattern['icon'],
                                      color: isSelected ? Colors.black : Colors.grey,
                                      size: 24,
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      pattern['name'],
                                      style: GoogleFonts.inter(
                                        color: isSelected ? Colors.black : Colors.grey,
                                        fontSize: 10,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            );
                          }),
                        ),
                      ],
                    ),
                  ),

                  // Recent Generated Section
                  if (_recentItems.isNotEmpty) ...[
                    const SizedBox(height: 32),
                    Text(
                      'Recently Generated',
                      style: GoogleFonts.inter(
                        color: Colors.white,
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 12),
                    ...(_recentItems.take(3).map((item) => Container(
                      margin: const EdgeInsets.only(bottom: 8),
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: surfaceColor,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        children: [
                          // Mini QR Preview
                          Container(
                            width: 48,
                            height: 48,
                            padding: const EdgeInsets.all(4),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: QrImageView(
                              data: item.data,
                              version: QrVersions.auto,
                              size: 40,
                              eyeStyle: QrEyeStyle(
                                eyeShape: _patterns[item.patternIndex]['eyeShape'],
                                color: Color(item.colorValue),
                              ),
                              dataModuleStyle: QrDataModuleStyle(
                                dataModuleShape: _patterns[item.patternIndex]['dataShape'],
                                color: Color(item.colorValue),
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  item.label ?? item.data,
                                  style: GoogleFonts.inter(
                                    color: Colors.white,
                                    fontSize: 14,
                                    fontWeight: FontWeight.w500,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  '${item.type} • ${_formatTime(item.createdAt)}',
                                  style: GoogleFonts.inter(
                                    color: Colors.grey,
                                    fontSize: 12,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          IconButton(
                            icon: const Icon(Icons.share, color: Colors.grey, size: 20),
                            onPressed: () {
                              Share.share(item.data);
                            },
                          ),
                        ],
                      ),
                    ))),
                  ],

                  const SizedBox(height: 100),
                ],
              ),
            ),
          ),

          // Bottom Generate Button
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: bgColor.withOpacity(0.95),
              border: Border(
                top: BorderSide(color: Colors.white.withOpacity(0.05)),
              ),
            ),
            child: SafeArea(
              child: SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton(
                  onPressed: _generateQR,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: primaryColor,
                    foregroundColor: Colors.black,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    elevation: 0,
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.qr_code_2, size: 24),
                      const SizedBox(width: 12),
                      Text(
                        'Generate Code',
                        style: GoogleFonts.inter(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _getInputLabel() {
    switch (_selectedType) {
      case 'Website': return 'Website URL';
      case 'Text': return 'Text Content';
      case 'Wi-Fi': return 'Network Name (SSID)';
      case 'Contact': return 'Full Name';
      case 'Email': return 'Email Address';
      case 'Phone': return 'Phone Number';
      default: return 'Content';
    }
  }

  IconData _getInputIcon() {
    switch (_selectedType) {
      case 'Website': return Icons.link;
      case 'Text': return Icons.text_fields;
      case 'Wi-Fi': return Icons.wifi;
      case 'Contact': return Icons.person;
      case 'Email': return Icons.email;
      case 'Phone': return Icons.phone;
      default: return Icons.qr_code;
    }
  }

  Widget _buildInputField({
    required String label,
    required String hint,
    required TextEditingController controller,
    required IconData icon,
    bool isPassword = false,
  }) {
    const surfaceColor = Color(0xFF1C3022);
    const primaryColor = Color(0xFF13EC49);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: GoogleFonts.inter(
            color: Colors.white,
            fontSize: 14,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 12),
        Container(
          decoration: BoxDecoration(
            color: surfaceColor,
            borderRadius: BorderRadius.circular(16),
          ),
          child: TextField(
            controller: controller,
            obscureText: isPassword,
            style: GoogleFonts.inter(color: Colors.white),
            decoration: InputDecoration(
              hintText: hint,
              hintStyle: GoogleFonts.inter(color: Colors.grey.withOpacity(0.6)),
              prefixIcon: Icon(icon, color: Colors.grey),
              border: InputBorder.none,
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: const BorderSide(color: primaryColor, width: 2),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
