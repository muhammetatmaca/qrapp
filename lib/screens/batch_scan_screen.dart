import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:flutter/services.dart';
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:qrapp/services/history_service.dart';
import 'package:qrapp/services/saved_service.dart';

/// Model for batch scanned items
class BatchScanItem {
  final String code;
  final String type;
  final DateTime scannedAt;
  bool isSelected;

  BatchScanItem({
    required this.code,
    required this.type,
    required this.scannedAt,
    this.isSelected = false,
  });
}

class BatchScanScreen extends StatefulWidget {
  const BatchScanScreen({super.key});

  @override
  State<BatchScanScreen> createState() => _BatchScanScreenState();
}

class _BatchScanScreenState extends State<BatchScanScreen> with SingleTickerProviderStateMixin, WidgetsBindingObserver {
  MobileScannerController? _controller;
  late AnimationController _animationController;
  bool _isFlashOn = false;
  bool _isScanning = true;
  bool _isPaused = false;
  bool _isInitialized = false;
  final List<BatchScanItem> _scannedItems = [];
  final Set<String> _scannedCodes = {}; // To prevent duplicates
  
  static const primaryColor = Color(0xFF13EC49);
  static const bgColor = Color(0xFF102215);
  static const surfaceColor = Color(0xFF1C3022);

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);
    _initCamera();
  }

  Future<void> _initCamera() async {
    try {
      _controller = MobileScannerController(
        facing: CameraFacing.back,
        torchEnabled: false,
        // FASTEST CONTINUOUS SCANNING SETTINGS:
        detectionSpeed: DetectionSpeed.unrestricted, // Maximum speed for batch scanning
        detectionTimeoutMs: 100, // Very quick for rapid successive scans
        autoStart: true,
        returnImage: false, // Don't return image - faster processing
      );
      
      // Wait for controller to be ready
      await Future.delayed(const Duration(milliseconds: 500));
      
      if (mounted) {
        setState(() {
          _isInitialized = true;
        });
      }
    } catch (e) {
      debugPrint('Batch camera init error: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Camera error: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (_controller == null) return;
    
    switch (state) {
      case AppLifecycleState.resumed:
        if (!_isPaused && _isInitialized) {
          _controller?.start();
        }
        break;
      case AppLifecycleState.inactive:
      case AppLifecycleState.paused:
      case AppLifecycleState.detached:
      case AppLifecycleState.hidden:
        _controller?.stop();
        break;
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _controller?.dispose();
    _animationController.dispose();
    super.dispose();
  }

  void _onDetect(BarcodeCapture capture) async {
    if (!_isScanning || _isPaused) return;

    final List<Barcode> barcodes = capture.barcodes;
    for (final barcode in barcodes) {
      if (barcode.rawValue != null && !_scannedCodes.contains(barcode.rawValue)) {
        final code = barcode.rawValue!;
        _scannedCodes.add(code);
        
        setState(() {
          _scannedItems.add(BatchScanItem(
            code: code,
            type: barcode.type.name,
            scannedAt: DateTime.now(),
          ));
        });

        // Haptic feedback for each scan
        HapticFeedback.mediumImpact();

        // Show snackbar
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Row(
                children: [
                  const Icon(Icons.check_circle, color: Colors.white, size: 20),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Scanned: ${code.length > 30 ? '${code.substring(0, 30)}...' : code}',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
              backgroundColor: primaryColor,
              duration: const Duration(milliseconds: 800),
              behavior: SnackBarBehavior.floating,
              margin: const EdgeInsets.only(bottom: 100, left: 16, right: 16),
            ),
          );
        }
      }
    }
  }

  void _togglePause() {
    setState(() {
      _isPaused = !_isPaused;
      if (_isPaused) {
        _controller?.stop();
      } else {
        _controller?.start();
      }
    });
  }

  void _clearAll() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: bgColor,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(
          'Clear All Scans?',
          style: GoogleFonts.inter(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        content: Text(
          'This will remove all ${_scannedItems.length} scanned items.',
          style: GoogleFonts.inter(color: Colors.grey),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancel', style: GoogleFonts.inter(color: Colors.grey)),
          ),
          TextButton(
            onPressed: () {
              setState(() {
                _scannedItems.clear();
                _scannedCodes.clear();
              });
              Navigator.pop(context);
            },
            child: Text('Clear', style: GoogleFonts.inter(color: Colors.red, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  void _showScannedItemsModal() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => StatefulBuilder(
        builder: (context, setModalState) => Container(
          height: MediaQuery.of(context).size.height * 0.85,
          decoration: const BoxDecoration(
            color: bgColor,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: Column(
            children: [
              // Handle
              Container(
                margin: const EdgeInsets.only(top: 12),
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey.withOpacity(0.3),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              // Header
              Padding(
                padding: const EdgeInsets.all(20),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Scanned Items',
                          style: GoogleFonts.inter(
                            color: Colors.white,
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '${_scannedItems.length} items scanned',
                          style: GoogleFonts.inter(
                            color: Colors.grey,
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                    Row(
                      children: [
                        _buildHeaderButton(
                          icon: Icons.select_all,
                          onTap: () {
                            setModalState(() {
                              final allSelected = _scannedItems.every((item) => item.isSelected);
                              for (var item in _scannedItems) {
                                item.isSelected = !allSelected;
                              }
                            });
                          },
                        ),
                        const SizedBox(width: 8),
                        _buildHeaderButton(
                          icon: Icons.share,
                          onTap: () => _shareSelected(),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              // List
              Expanded(
                child: _scannedItems.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.qr_code_scanner, size: 64, color: Colors.grey.withOpacity(0.3)),
                            const SizedBox(height: 16),
                            Text(
                              'No items scanned yet',
                              style: GoogleFonts.inter(color: Colors.grey, fontSize: 16),
                            ),
                          ],
                        ),
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        itemCount: _scannedItems.length,
                        itemBuilder: (context, index) {
                          final item = _scannedItems[index];
                          return _buildScannedItemTile(item, index, setModalState);
                        },
                      ),
              ),
              // Bottom Actions
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: surfaceColor,
                  border: Border(top: BorderSide(color: Colors.white.withOpacity(0.05))),
                ),
                child: SafeArea(
                  child: Row(
                    children: [
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: () => _copyAllToClipboard(),
                          icon: const Icon(Icons.copy, size: 20),
                          label: Text('Copy All', style: GoogleFonts.inter(fontWeight: FontWeight.w600)),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.white.withOpacity(0.1),
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: () => _saveAllToHistory(),
                          icon: const Icon(Icons.save, size: 20),
                          label: Text('Save All', style: GoogleFonts.inter(fontWeight: FontWeight.w600)),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: primaryColor,
                            foregroundColor: Colors.black,
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeaderButton({required IconData icon, required VoidCallback onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.1),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Icon(icon, color: Colors.white, size: 20),
      ),
    );
  }

  Widget _buildScannedItemTile(BatchScanItem item, int index, StateSetter setModalState) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: item.isSelected ? primaryColor.withOpacity(0.1) : surfaceColor,
        borderRadius: BorderRadius.circular(12),
        border: item.isSelected ? Border.all(color: primaryColor.withOpacity(0.5)) : null,
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        leading: GestureDetector(
          onTap: () {
            setModalState(() {
              item.isSelected = !item.isSelected;
            });
          },
          child: Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: item.isSelected ? primaryColor : Colors.white.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              item.isSelected ? Icons.check : Icons.qr_code_2,
              color: item.isSelected ? Colors.black : Colors.grey,
              size: 18,
            ),
          ),
        ),
        title: Text(
          item.code,
          style: GoogleFonts.inter(
            color: Colors.white,
            fontSize: 14,
            fontWeight: FontWeight.w500,
          ),
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
        ),
        subtitle: Text(
          '${item.type} • ${_formatTime(item.scannedAt)}',
          style: GoogleFonts.inter(
            color: Colors.grey,
            fontSize: 12,
          ),
        ),
        trailing: PopupMenuButton<String>(
          icon: Icon(Icons.more_vert, color: Colors.grey.withOpacity(0.7)),
          color: surfaceColor,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          onSelected: (value) {
            switch (value) {
              case 'copy':
                Clipboard.setData(ClipboardData(text: item.code));
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Copied!'), backgroundColor: primaryColor),
                );
                break;
              case 'share':
                Share.share(item.code);
                break;
              case 'save':
                SavedService.addToSaved(item.code, item.type);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Saved!'), backgroundColor: primaryColor),
                );
                break;
              case 'amazon':
                _searchOnAmazon(item.code);
                break;
              case 'ebay':
                _searchOnEbay(item.code);
                break;
              case 'google':
                _searchOnGoogle(item.code);
                break;
              case 'delete':
                setModalState(() {
                  _scannedItems.removeAt(index);
                  _scannedCodes.remove(item.code);
                });
                setState(() {}); // Update main screen count
                break;
            }
          },
          itemBuilder: (context) => [
            PopupMenuItem(
              value: 'copy',
              child: Row(
                children: [
                  const Icon(Icons.copy, size: 18, color: Colors.white),
                  const SizedBox(width: 12),
                  Text('Copy', style: GoogleFonts.inter(color: Colors.white)),
                ],
              ),
            ),
            PopupMenuItem(
              value: 'share',
              child: Row(
                children: [
                  const Icon(Icons.share, size: 18, color: Colors.white),
                  const SizedBox(width: 12),
                  Text('Share', style: GoogleFonts.inter(color: Colors.white)),
                ],
              ),
            ),
            PopupMenuItem(
              value: 'save',
              child: Row(
                children: [
                  const Icon(Icons.bookmark_add, size: 18, color: Colors.white),
                  const SizedBox(width: 12),
                  Text('Save', style: GoogleFonts.inter(color: Colors.white)),
                ],
              ),
            ),
            PopupMenuItem(
              value: 'amazon',
              child: Row(
                children: [
                  const Icon(Icons.shopping_cart, size: 18, color: Color(0xFFFF9900)),
                  const SizedBox(width: 12),
                  Text('Amazon', style: GoogleFonts.inter(color: Colors.white)),
                ],
              ),
            ),
            PopupMenuItem(
              value: 'ebay',
              child: Row(
                children: [
                  const Icon(Icons.storefront, size: 18, color: Color(0xFFE53238)),
                  const SizedBox(width: 12),
                  Text('eBay', style: GoogleFonts.inter(color: Colors.white)),
                ],
              ),
            ),
            PopupMenuItem(
              value: 'google',
              child: Row(
                children: [
                  const Icon(Icons.search, size: 18, color: Color(0xFF4285F4)),
                  const SizedBox(width: 12),
                  Text('Google', style: GoogleFonts.inter(color: Colors.white)),
                ],
              ),
            ),
            const PopupMenuDivider(),
            PopupMenuItem(
              value: 'delete',
              child: Row(
                children: [
                  const Icon(Icons.delete, size: 18, color: Colors.red),
                  const SizedBox(width: 12),
                  Text('Delete', style: GoogleFonts.inter(color: Colors.red)),
                ],
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
    final second = dateTime.second.toString().padLeft(2, '0');
    return '$hour:$minute:$second';
  }

  void _shareSelected() {
    final selectedItems = _scannedItems.where((item) => item.isSelected).toList();
    if (selectedItems.isEmpty) {
      Share.share(_scannedItems.map((e) => e.code).join('\n'));
    } else {
      Share.share(selectedItems.map((e) => e.code).join('\n'));
    }
  }

  Future<void> _searchOnAmazon(String code) async {
    final searchQuery = Uri.encodeComponent(code);
    final url = Uri.parse('https://www.amazon.com/s?k=$searchQuery');
    if (await canLaunchUrl(url)) {
      await launchUrl(url, mode: LaunchMode.externalApplication);
    }
  }

  Future<void> _searchOnEbay(String code) async {
    final searchQuery = Uri.encodeComponent(code);
    final url = Uri.parse('https://www.ebay.com/sch/i.html?_nkw=$searchQuery');
    if (await canLaunchUrl(url)) {
      await launchUrl(url, mode: LaunchMode.externalApplication);
    }
  }

  Future<void> _searchOnGoogle(String code) async {
    final searchQuery = Uri.encodeComponent(code);
    final url = Uri.parse('https://www.google.com/search?q=$searchQuery');
    if (await canLaunchUrl(url)) {
      await launchUrl(url, mode: LaunchMode.externalApplication);
    }
  }

  void _copyAllToClipboard() {
    final allCodes = _scannedItems.map((e) => e.code).join('\n');
    Clipboard.setData(ClipboardData(text: allCodes));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Copied ${_scannedItems.length} items to clipboard'),
        backgroundColor: primaryColor,
      ),
    );
  }

  Future<void> _saveAllToHistory() async {
    for (var item in _scannedItems) {
      await HistoryService.addToHistory(item.code, item.type);
    }
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Saved ${_scannedItems.length} items to history'),
          backgroundColor: primaryColor,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          // Camera Feed
          if (_isInitialized && _controller != null)
            MobileScanner(
              controller: _controller!,
              onDetect: _onDetect,
            )
          else
            const Center(
              child: CircularProgressIndicator(color: primaryColor),
            ),

          // Overlay
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Colors.black.withOpacity(0.7),
                  Colors.transparent,
                  Colors.black.withOpacity(0.9),
                ],
                stops: const [0.0, 0.4, 1.0],
              ),
            ),
          ),

          // Top Bar
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Row(
                children: [
                  // Back Button
                  GestureDetector(
                    onTap: () => Navigator.pop(context),
                    child: Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        color: Colors.black.withOpacity(0.3),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.white.withOpacity(0.1)),
                      ),
                      child: const Icon(Icons.arrow_back_ios_new, color: Colors.white, size: 20),
                    ),
                  ),
                  const SizedBox(width: 12),
                  // Title
                  Expanded(
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                      decoration: BoxDecoration(
                        color: Colors.black.withOpacity(0.3),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: primaryColor.withOpacity(0.3)),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.layers, color: primaryColor, size: 18),
                          const SizedBox(width: 8),
                          Text(
                            'Batch Scan',
                            style: GoogleFonts.inter(
                              color: Colors.white,
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  // Flash Button
                  GestureDetector(
                    onTap: () {
                      _controller?.toggleTorch();
                      setState(() {
                        _isFlashOn = !_isFlashOn;
                      });
                    },
                    child: Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        color: _isFlashOn ? primaryColor : Colors.black.withOpacity(0.3),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: _isFlashOn ? primaryColor : Colors.white.withOpacity(0.1)),
                      ),
                      child: Icon(
                        _isFlashOn ? Icons.flash_on : Icons.flash_off,
                        color: _isFlashOn ? Colors.black : Colors.white,
                        size: 20,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Scan Counter Badge
          if (_scannedItems.isNotEmpty)
            Positioned(
              top: MediaQuery.of(context).padding.top + 70,
              left: 0,
              right: 0,
              child: Center(
                child: GestureDetector(
                  onTap: _showScannedItemsModal,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                    decoration: BoxDecoration(
                      color: primaryColor,
                      borderRadius: BorderRadius.circular(30),
                      boxShadow: [
                        BoxShadow(
                          color: primaryColor.withOpacity(0.4),
                          blurRadius: 20,
                          spreadRadius: 2,
                        ),
                      ],
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.list_alt, color: Colors.black, size: 18),
                        const SizedBox(width: 8),
                        Text(
                          '${_scannedItems.length} scanned',
                          style: GoogleFonts.inter(
                            color: Colors.black,
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(width: 4),
                        const Icon(Icons.arrow_drop_down, color: Colors.black, size: 20),
                      ],
                    ),
                  ),
                ),
              ),
            ),

          // Center Scan Area
          Center(
            child: Container(
              width: 280,
              height: 280,
              decoration: BoxDecoration(
                border: Border.all(color: primaryColor.withOpacity(0.5), width: 2),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Stack(
                children: [
                  // Corners
                  _buildCorner(Alignment.topLeft),
                  _buildCorner(Alignment.topRight),
                  _buildCorner(Alignment.bottomLeft),
                  _buildCorner(Alignment.bottomRight),
                  // Scan Line
                  AnimatedBuilder(
                    animation: _animationController,
                    builder: (context, child) {
                      return Positioned(
                        top: 20 + (_animationController.value * 230),
                        left: 20,
                        right: 20,
                        child: Container(
                          height: 3,
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(2),
                            boxShadow: [
                              BoxShadow(
                                color: primaryColor,
                                blurRadius: 15,
                                spreadRadius: 2,
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ],
              ),
            ),
          ),

          // Pause Indicator
          if (_isPaused)
            Center(
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                decoration: BoxDecoration(
                  color: Colors.orange.withOpacity(0.9),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.pause_circle, color: Colors.white),
                    const SizedBox(width: 8),
                    Text(
                      'Scanning Paused',
                      style: GoogleFonts.inter(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ),

          // Bottom Controls
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: Container(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
              decoration: BoxDecoration(
                color: bgColor.withOpacity(0.95),
                borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
                border: Border.all(color: Colors.white.withOpacity(0.05)),
              ),
              child: SafeArea(
                top: false,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Instructions
                    Text(
                      _isPaused
                          ? 'Tap Play to continue scanning'
                          : 'Point at QR codes to scan continuously',
                      style: GoogleFonts.inter(
                        color: Colors.grey,
                        fontSize: 13,
                      ),
                    ),
                    const SizedBox(height: 20),
                    // Control Buttons
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        // Clear Button
                        _buildControlButton(
                          icon: Icons.delete_sweep,
                          label: 'Clear',
                          onTap: _scannedItems.isEmpty ? null : _clearAll,
                          color: Colors.red,
                        ),
                        // Play/Pause Button
                        GestureDetector(
                          onTap: _togglePause,
                          child: Container(
                            width: 72,
                            height: 72,
                            decoration: BoxDecoration(
                              color: _isPaused ? primaryColor : Colors.orange,
                              shape: BoxShape.circle,
                              boxShadow: [
                                BoxShadow(
                                  color: (_isPaused ? primaryColor : Colors.orange).withOpacity(0.4),
                                  blurRadius: 20,
                                  spreadRadius: 2,
                                ),
                              ],
                            ),
                            child: Icon(
                              _isPaused ? Icons.play_arrow : Icons.pause,
                              color: Colors.black,
                              size: 36,
                            ),
                          ),
                        ),
                        // View All Button
                        _buildControlButton(
                          icon: Icons.list_alt,
                          label: 'View All',
                          onTap: _scannedItems.isEmpty ? null : _showScannedItemsModal,
                          color: primaryColor,
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildControlButton({
    required IconData icon,
    required String label,
    VoidCallback? onTap,
    required Color color,
  }) {
    final isDisabled = onTap == null;
    return GestureDetector(
      onTap: onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              color: isDisabled ? Colors.grey.withOpacity(0.2) : color.withOpacity(0.2),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: isDisabled ? Colors.grey.withOpacity(0.3) : color.withOpacity(0.5),
              ),
            ),
            child: Icon(
              icon,
              color: isDisabled ? Colors.grey.withOpacity(0.5) : color,
              size: 24,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            label,
            style: GoogleFonts.inter(
              color: isDisabled ? Colors.grey.withOpacity(0.5) : Colors.white,
              fontSize: 11,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCorner(Alignment alignment) {
    const size = 24.0;
    const weight = 3.0;
    final bool isTop = alignment == Alignment.topLeft || alignment == Alignment.topRight;
    final bool isLeft = alignment == Alignment.topLeft || alignment == Alignment.bottomLeft;

    return Align(
      alignment: alignment,
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          border: Border(
            top: isTop ? const BorderSide(color: primaryColor, width: weight) : BorderSide.none,
            bottom: !isTop ? const BorderSide(color: primaryColor, width: weight) : BorderSide.none,
            left: isLeft ? const BorderSide(color: primaryColor, width: weight) : BorderSide.none,
            right: !isLeft ? const BorderSide(color: primaryColor, width: weight) : BorderSide.none,
          ),
        ),
      ),
    );
  }
}
