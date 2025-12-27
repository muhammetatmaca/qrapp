import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:qrapp/services/history_service.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:share_plus/share_plus.dart';
import 'package:flutter/services.dart';
import 'package:qrapp/widgets/native_ad_widget.dart';

class HistoryScreen extends StatefulWidget {
  const HistoryScreen({super.key});

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  List<ScanHistoryItem> _history = [];
  List<ScanHistoryItem> _filteredHistory = [];
  bool _isLoading = true;
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadHistory();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadHistory() async {
    final history = await HistoryService.loadHistory();
    setState(() {
      _history = history;
      _filteredHistory = history;
      _isLoading = false;
    });
  }

  void _filterHistory(String query) {
    setState(() {
      if (query.isEmpty) {
        _filteredHistory = _history;
      } else {
        _filteredHistory = _history
            .where((item) =>
                item.code.toLowerCase().contains(query.toLowerCase()) ||
                item.type.toLowerCase().contains(query.toLowerCase()))
            .toList();
      }
    });
  }

  // Group history by date
  Map<String, List<ScanHistoryItem>> _groupByDate() {
    final Map<String, List<ScanHistoryItem>> grouped = {};
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = today.subtract(const Duration(days: 1));

    for (final item in _filteredHistory) {
      final itemDate = DateTime(item.scannedAt.year, item.scannedAt.month, item.scannedAt.day);
      String dateLabel;
      
      if (itemDate == today) {
        dateLabel = 'Today';
      } else if (itemDate == yesterday) {
        dateLabel = 'Yesterday';
      } else {
        dateLabel = '${itemDate.day}/${itemDate.month}/${itemDate.year}';
      }
      
      grouped.putIfAbsent(dateLabel, () => []);
      grouped[dateLabel]!.add(item);
    }
    
    return grouped;
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

  String _formatTime(DateTime dateTime) {
    final hour = dateTime.hour;
    final minute = dateTime.minute.toString().padLeft(2, '0');
    final period = hour >= 12 ? 'PM' : 'AM';
    final displayHour = hour > 12 ? hour - 12 : (hour == 0 ? 12 : hour);
    return '$displayHour:$minute $period';
  }

  void _showItemDetails(ScanHistoryItem item) {
    const primaryColor = Color(0xFF13EC49);
    const bgColor = Color(0xFF102215);

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => Container(
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
            Container(
              width: 64,
              height: 64,
              decoration: BoxDecoration(
                color: _getColorForType(item.type).withOpacity(0.2),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Icon(
                _getIconForType(item.type),
                color: _getColorForType(item.type),
                size: 32,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              item.type,
              style: GoogleFonts.inter(
                color: Colors.grey,
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 8),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.3),
                borderRadius: BorderRadius.circular(12),
              ),
              child: SelectableText(
                item.code,
                style: GoogleFonts.inter(
                  color: primaryColor,
                  fontSize: 16,
                ),
                textAlign: TextAlign.center,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              '${item.scannedAt.day}/${item.scannedAt.month}/${item.scannedAt.year} at ${_formatTime(item.scannedAt)}',
              style: GoogleFonts.inter(
                color: Colors.grey.withOpacity(0.7),
                fontSize: 12,
              ),
            ),
            const SizedBox(height: 24),
            Row(
              children: [
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
                const SizedBox(width: 12),
                Expanded(
                  child: _buildActionButton(
                    icon: Icons.share,
                    label: 'Share',
                    onTap: () {
                      Navigator.pop(context);
                      Share.share(item.code);
                    },
                  ),
                ),
                if (Uri.tryParse(item.code)?.hasAbsolutePath ?? false) ...[
                  const SizedBox(width: 12),
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
                ],
              ],
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
    bool isPrimary = false,
  }) {
    const primaryColor = Color(0xFF13EC49);
    
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(
          color: isPrimary ? primaryColor : Colors.white.withOpacity(0.05),
          borderRadius: BorderRadius.circular(12),
          border: isPrimary ? null : Border.all(color: Colors.white.withOpacity(0.1)),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              color: isPrimary ? Colors.black : Colors.white,
              size: 20,
            ),
            const SizedBox(width: 8),
            Text(
              label,
              style: GoogleFonts.inter(
                color: isPrimary ? Colors.black : Colors.white,
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

    final groupedHistory = _groupByDate();

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
                'History',
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
                  onChanged: _filterHistory,
                  style: GoogleFonts.inter(color: Colors.white),
                  decoration: InputDecoration(
                    hintText: 'Search scans, barcodes, or URLs...',
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
          if (_filteredHistory.isEmpty)
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
                        Icons.history,
                        color: Colors.grey.withOpacity(0.5),
                        size: 40,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      _searchController.text.isNotEmpty
                          ? 'No results found'
                          : 'No scan history yet',
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
                          : 'Start scanning to see your history',
                      style: GoogleFonts.inter(
                        color: Colors.grey.withOpacity(0.7),
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ),
            )
          else
            // History Items grouped by date
            ...groupedHistory.entries.expand((entry) => [
              // Date Header
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                  child: Text(
                    entry.key.toUpperCase(),
                    style: GoogleFonts.inter(
                      color: Colors.grey,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1,
                    ),
                  ),
                ),
              ),
              // Items for this date
              SliverList(
                delegate: SliverChildBuilderDelegate(
                  (context, index) {
                    final item = entry.value[index];
                    final iconColor = _getColorForType(item.type);
                    
                    return GestureDetector(
                      onTap: () => _showItemDetails(item),
                      child: Container(
                        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: surfaceColor,
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Row(
                          children: [
                            // Icon
                            Container(
                              width: 48,
                              height: 48,
                              decoration: BoxDecoration(
                                color: iconColor.withOpacity(0.2),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Icon(
                                _getIconForType(item.type),
                                color: iconColor,
                                size: 24,
                              ),
                            ),
                            const SizedBox(width: 16),
                            // Content
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    item.code,
                                    style: GoogleFonts.inter(
                                      color: Colors.white,
                                      fontSize: 15,
                                      fontWeight: FontWeight.w500,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  const SizedBox(height: 4),
                                  Row(
                                    children: [
                                      Text(
                                        item.type,
                                        style: GoogleFonts.inter(
                                          color: Colors.grey,
                                          fontSize: 12,
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                      Container(
                                        width: 4,
                                        height: 4,
                                        margin: const EdgeInsets.symmetric(horizontal: 8),
                                        decoration: const BoxDecoration(
                                          color: Colors.grey,
                                          shape: BoxShape.circle,
                                        ),
                                      ),
                                      Text(
                                        _formatTime(item.scannedAt),
                                        style: GoogleFonts.inter(
                                          color: Colors.grey.withOpacity(0.7),
                                          fontSize: 12,
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                            // Chevron
                            Icon(
                              Icons.chevron_right,
                              color: Colors.grey.withOpacity(0.5),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                  childCount: entry.value.length,
                ),
              ),
            ]),

          // Bottom padding
          const SliverToBoxAdapter(
            child: SizedBox(height: 100),
          ),
        ],
      ),
    );
  }
}
