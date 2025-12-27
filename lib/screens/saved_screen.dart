import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:qrapp/services/saved_service.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:share_plus/share_plus.dart';
import 'package:flutter/services.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:path_provider/path_provider.dart';
import 'package:flutter/rendering.dart';
import 'dart:io';
import 'dart:ui' as ui;
import 'package:qrapp/widgets/native_ad_widget.dart';

class SavedScreen extends StatefulWidget {
  const SavedScreen({super.key});

  @override
  State<SavedScreen> createState() => _SavedScreenState();
}

class _SavedScreenState extends State<SavedScreen> {
  List<SavedItem> _savedItems = [];
  List<SavedItem> _filteredItems = [];
  bool _isLoading = true;
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadSaved();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadSaved() async {
    final saved = await SavedService.loadSaved();
    setState(() {
      _savedItems = saved;
      _filteredItems = saved;
      _isLoading = false;
    });
  }

  void _filterItems(String query) {
    setState(() {
      if (query.isEmpty) {
        _filteredItems = _savedItems;
      } else {
        _filteredItems = _savedItems
            .where((item) =>
                item.code.toLowerCase().contains(query.toLowerCase()) ||
                (item.label?.toLowerCase().contains(query.toLowerCase()) ?? false) ||
                item.type.toLowerCase().contains(query.toLowerCase()))
            .toList();
      }
    });
  }

  IconData _getIconForType(String type) {
    final lowerType = type.toLowerCase();
    if (lowerType.contains('qr')) return Icons.qr_code_2;
    if (lowerType.contains('barcode')) return Icons.barcode_reader;
    if (lowerType.contains('url') || lowerType.contains('http')) return Icons.link;
    if (lowerType.contains('wifi')) return Icons.wifi;
    if (lowerType.contains('contact')) return Icons.person_add;
    return Icons.qr_code_scanner;
  }

  Color _getColorForType(String type) {
    final lowerType = type.toLowerCase();
    if (lowerType.contains('qr')) return const Color(0xFF13EC49);
    if (lowerType.contains('barcode')) return Colors.purple;
    if (lowerType.contains('url') || lowerType.contains('http')) return Colors.blue;
    if (lowerType.contains('wifi')) return Colors.blue;
    if (lowerType.contains('contact')) return Colors.orange;
    return const Color(0xFF13EC49);
  }
  final GlobalKey _qrKey = GlobalKey();

  void _showItemDetails(SavedItem item) {
    const primaryColor = Color(0xFF13EC49);
    const bgColor = Color(0xFF102215);
    const surfaceColor = Color(0xFF1C3022);

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => StatefulBuilder(
        builder: (context, setModalState) => Container(
          decoration: const BoxDecoration(
            color: bgColor,
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
              // QR Code Preview with RepaintBoundary
              RepaintBoundary(
                key: _qrKey,
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: QrImageView(
                    data: item.code,
                    version: QrVersions.auto,
                    size: 180,
                    backgroundColor: Colors.white,
                  ),
                ),
              ),
              const SizedBox(height: 16),
              if (item.label != null && item.label!.isNotEmpty)
                Text(
                  item.label!,
                  style: GoogleFonts.inter(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              const SizedBox(height: 8),
              Text(
                item.type,
                style: GoogleFonts.inter(
                  color: Colors.grey,
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 12),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: surfaceColor,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: SelectableText(
                  item.code,
                  style: GoogleFonts.inter(
                    color: primaryColor,
                    fontSize: 14,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
              const SizedBox(height: 24),
              // Action Buttons - First Row
              Row(
                children: [
                  Expanded(
                    child: _buildActionButton(
                      icon: Icons.download,
                      label: 'Download',
                      onTap: () => _downloadQRImage(item),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildActionButton(
                      icon: Icons.share,
                      label: 'Share',
                      onTap: () => _shareQRImage(item),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildActionButton(
                      icon: Icons.copy,
                      label: 'Copy',
                      onTap: () {
                        Clipboard.setData(ClipboardData(text: item.code));
                        Navigator.pop(context);
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Copied to clipboard'),
                            backgroundColor: primaryColor,
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              // Second row
              Row(
                children: [
                  Expanded(
                    child: _buildActionButton(
                      icon: Icons.edit,
                      label: 'Edit',
                      onTap: () {
                        Navigator.pop(context);
                        _showEditLabelDialog(item);
                      },
                    ),
                  ),
                  const SizedBox(width: 12),
                  if (Uri.tryParse(item.code)?.hasAbsolutePath ?? false)
                    Expanded(
                      child: _buildActionButton(
                        icon: Icons.open_in_browser,
                        label: 'Open',
                        isPrimary: true,
                        onTap: () async {
                          Navigator.pop(context);
                          final uri = Uri.parse(item.code);
                          if (await canLaunchUrl(uri)) {
                            await launchUrl(uri, mode: LaunchMode.externalApplication);
                          }
                        },
                      ),
                    ),
                  if (Uri.tryParse(item.code)?.hasAbsolutePath ?? false)
                    const SizedBox(width: 12),
                  Expanded(
                    child: _buildActionButton(
                      icon: Icons.delete_outline,
                      label: 'Remove',
                      isDestructive: true,
                      onTap: () {
                        Navigator.pop(context);
                        _confirmDelete(item);
                      },
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _downloadQRImage(SavedItem item) async {
    try {
      await Future.delayed(const Duration(milliseconds: 100));
      
      final boundary = _qrKey.currentContext?.findRenderObject() as RenderRepaintBoundary?;
      if (boundary == null) throw Exception('Could not capture QR code');

      final image = await boundary.toImage(pixelRatio: 4.0);
      final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
      if (byteData == null) throw Exception('Failed to convert image');

      final directory = await getApplicationDocumentsDirectory();
      final fileName = 'qr_${item.label ?? 'code'}_${DateTime.now().millisecondsSinceEpoch}.png';
      final file = File('${directory.path}/$fileName');
      await file.writeAsBytes(byteData.buffer.asUint8List());

      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Saved as $fileName'),
            backgroundColor: const Color(0xFF13EC49),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Download failed: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _shareQRImage(SavedItem item) async {
    try {
      await Future.delayed(const Duration(milliseconds: 100));
      
      final boundary = _qrKey.currentContext?.findRenderObject() as RenderRepaintBoundary?;
      if (boundary == null) throw Exception('Could not capture QR code');

      final image = await boundary.toImage(pixelRatio: 3.0);
      final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
      if (byteData == null) throw Exception('Failed to convert image');

      final directory = await getTemporaryDirectory();
      final file = File('${directory.path}/qr_code_${DateTime.now().millisecondsSinceEpoch}.png');
      await file.writeAsBytes(byteData.buffer.asUint8List());

      Navigator.pop(context);
      
      await Share.shareXFiles(
        [XFile(file.path)],
        subject: item.label ?? 'QR Code',
        text: item.code,
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Share failed: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _showEditLabelDialog(SavedItem item) {
    const primaryColor = Color(0xFF13EC49);
    const bgColor = Color(0xFF102215);
    final controller = TextEditingController(text: item.label ?? '');

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: bgColor,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(
          'Edit Label',
          style: GoogleFonts.inter(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        content: TextField(
          controller: controller,
          style: GoogleFonts.inter(color: Colors.white),
          decoration: InputDecoration(
            hintText: 'Enter a label...',
            hintStyle: GoogleFonts.inter(color: Colors.grey),
            filled: true,
            fillColor: Colors.white.withOpacity(0.05),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide.none,
            ),
          ),
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
              await SavedService.updateLabel(item.code, controller.text);
              Navigator.pop(context);
              _loadSaved();
            },
            child: Text(
              'Save',
              style: GoogleFonts.inter(color: primaryColor, fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }

  void _confirmDelete(SavedItem item) {
    const primaryColor = Color(0xFF13EC49);
    const bgColor = Color(0xFF102215);

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: bgColor,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(
          'Remove Item',
          style: GoogleFonts.inter(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        content: Text(
          'Are you sure you want to remove this saved item?',
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
              await SavedService.removeFromSaved(item.code);
              Navigator.pop(context);
              _loadSaved();
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Item removed'),
                    backgroundColor: primaryColor,
                  ),
                );
              }
            },
            child: Text(
              'Remove',
              style: GoogleFonts.inter(color: Colors.red, fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
    bool isPrimary = false,
    bool isDestructive = false,
  }) {
    const primaryColor = Color(0xFF13EC49);
    
    Color bgColor;
    Color textColor;
    
    if (isPrimary) {
      bgColor = primaryColor;
      textColor = Colors.black;
    } else if (isDestructive) {
      bgColor = Colors.red.withOpacity(0.1);
      textColor = Colors.red;
    } else {
      bgColor = Colors.white.withOpacity(0.05);
      textColor = Colors.white;
    }
    
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(12),
          border: isDestructive ? Border.all(color: Colors.red.withOpacity(0.3)) : null,
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: textColor, size: 20),
            const SizedBox(width: 8),
            Text(
              label,
              style: GoogleFonts.inter(
                color: textColor,
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    const primaryColor = Color(0xFF13EC49);
    const bgColor = Color(0xFF102215);
    const surfaceColor = Color(0xFF1C3022);

    if (_isLoading) {
      return const Scaffold(
        backgroundColor: bgColor,
        body: Center(
          child: CircularProgressIndicator(color: primaryColor),
        ),
      );
    }

    return Scaffold(
      backgroundColor: bgColor,
      body: CustomScrollView(
        slivers: [
          // App Bar
          SliverAppBar(
            backgroundColor: bgColor.withOpacity(0.95),
            elevation: 0,
            pinned: true,
            expandedHeight: 120,
            leading: IconButton(
              icon: const Icon(Icons.arrow_back_ios, color: primaryColor),
              onPressed: () => Navigator.pop(context),
            ),
            flexibleSpace: FlexibleSpaceBar(
              titlePadding: const EdgeInsets.only(left: 56, bottom: 16),
              title: Text(
                'Saved',
                style: GoogleFonts.inter(
                  color: Colors.white,
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),

          // Search Bar
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
              child: Container(
                decoration: BoxDecoration(
                  color: surfaceColor,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: TextField(
                  controller: _searchController,
                  onChanged: _filterItems,
                  style: GoogleFonts.inter(color: Colors.white),
                  decoration: InputDecoration(
                    hintText: 'Search saved items...',
                    hintStyle: GoogleFonts.inter(color: Colors.grey),
                    prefixIcon: const Icon(Icons.search, color: Colors.grey),
                    border: InputBorder.none,
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                  ),
                ),
              ),
            ),
          ),

          // Native Ad
          const SliverToBoxAdapter(
            child: NativeAdWidget(),
          ),

          // Empty State
          if (_filteredItems.isEmpty)
            SliverFillRemaining(
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      width: 80,
                      height: 80,
                      decoration: BoxDecoration(
                        color: surfaceColor,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Icon(
                        Icons.bookmark_outline,
                        color: Colors.grey.withOpacity(0.5),
                        size: 40,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      _searchController.text.isNotEmpty
                          ? 'No results found'
                          : 'No saved items yet',
                      style: GoogleFonts.inter(
                        color: Colors.grey,
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      _searchController.text.isNotEmpty
                          ? 'Try a different search term'
                          : 'Save QR codes and barcodes for quick access',
                      style: GoogleFonts.inter(
                        color: Colors.grey.withOpacity(0.7),
                        fontSize: 14,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            )
          else
            // Saved Items Grid
            SliverPadding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              sliver: SliverGrid(
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  childAspectRatio: 0.85,
                  crossAxisSpacing: 12,
                  mainAxisSpacing: 12,
                ),
                delegate: SliverChildBuilderDelegate(
                  (context, index) {
                    final item = _filteredItems[index];
                    final iconColor = _getColorForType(item.type);
                    
                    return GestureDetector(
                      onTap: () => _showItemDetails(item),
                      child: Container(
                        decoration: BoxDecoration(
                          color: surfaceColor,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            // QR Preview
                            Container(
                              width: 80,
                              height: 80,
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: QrImageView(
                                data: item.code,
                                version: QrVersions.auto,
                                size: 64,
                                backgroundColor: Colors.white,
                              ),
                            ),
                            const SizedBox(height: 12),
                            // Label or Code
                            Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 12),
                              child: Text(
                                item.label?.isNotEmpty == true 
                                    ? item.label! 
                                    : item.code,
                                style: GoogleFonts.inter(
                                  color: Colors.white,
                                  fontSize: 14,
                                  fontWeight: FontWeight.w500,
                                ),
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                                textAlign: TextAlign.center,
                              ),
                            ),
                            const SizedBox(height: 4),
                            // Type badge
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: iconColor.withOpacity(0.2),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                item.type,
                                style: GoogleFonts.inter(
                                  color: iconColor,
                                  fontSize: 10,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                  childCount: _filteredItems.length,
                ),
              ),
            ),

          // Bottom padding
          const SliverToBoxAdapter(
            child: SizedBox(height: 100),
          ),
        ],
      ),
    );
  }
}
