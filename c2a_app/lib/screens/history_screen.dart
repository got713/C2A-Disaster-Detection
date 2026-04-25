import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../theme/app_theme.dart';
import '../utils/animations.dart';
import '../models/detection_result.dart';

class HistoryRecord {
  final String id;
  final String imageName;
  final String disasterType;
  final List<DetectionResult> detections;
  final DateTime timestamp;
  final Color disasterColor;

  const HistoryRecord({
    required this.id,
    required this.imageName,
    required this.disasterType,
    required this.detections,
    required this.timestamp,
    required this.disasterColor,
  });
}

class HistoryScreen extends StatefulWidget {
  const HistoryScreen({super.key});
  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  String _filter = 'All';
  final List<String> _filters = ['All', 'Fire', 'Flood', 'Traffic', 'Collapse'];

  final List<HistoryRecord> _records = [
    HistoryRecord(id:'001', imageName:'UAV_0142.jpg', disasterType:'Fire',
      detections:[DetectionResult(id:1,pose:'Upright',confidence:.94,poseColor:AppTheme.success),DetectionResult(id:2,pose:'Lying',confidence:.87,poseColor:AppTheme.primaryColor)],
      timestamp:DateTime.now().subtract(const Duration(minutes:15)), disasterColor:AppTheme.primaryColor),
    HistoryRecord(id:'002', imageName:'UAV_0891.jpg', disasterType:'Flood',
      detections:[DetectionResult(id:1,pose:'Bent',confidence:.76,poseColor:AppTheme.warning)],
      timestamp:DateTime.now().subtract(const Duration(hours:2)), disasterColor:AppTheme.accentColor),
    HistoryRecord(id:'003', imageName:'UAV_1023.jpg', disasterType:'Collapse',
      detections:[DetectionResult(id:1,pose:'Kneeling',confidence:.91,poseColor:AppTheme.success),DetectionResult(id:2,pose:'Sitting',confidence:.83,poseColor:AppTheme.warning),DetectionResult(id:3,pose:'Lying',confidence:.78,poseColor:AppTheme.primaryColor)],
      timestamp:DateTime.now().subtract(const Duration(hours:5)), disasterColor:const Color(0xFF8B5CF6)),
    HistoryRecord(id:'004', imageName:'UAV_0334.jpg', disasterType:'Traffic',
      detections:[DetectionResult(id:1,pose:'Upright',confidence:.88,poseColor:AppTheme.success)],
      timestamp:DateTime.now().subtract(const Duration(days:1)), disasterColor:AppTheme.secondaryColor),
    HistoryRecord(id:'005', imageName:'UAV_0567.jpg', disasterType:'Fire',
      detections:[DetectionResult(id:1,pose:'Lying',confidence:.95,poseColor:AppTheme.primaryColor),DetectionResult(id:2,pose:'Bent',confidence:.72,poseColor:AppTheme.warning)],
      timestamp:DateTime.now().subtract(const Duration(days:2)), disasterColor:AppTheme.primaryColor),
  ];

  List<HistoryRecord> get _filtered =>
    _filter == 'All' ? _records : _records.where((r) => r.disasterType == _filter).toList();

  String _timeAgo(DateTime dt) {
    final diff = DateTime.now().difference(dt);
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    return '${diff.inDays}d ago';
  }

  IconData _disasterIcon(String type) {
    switch (type) {
      case 'Fire': return Icons.local_fire_department;
      case 'Flood': return Icons.water;
      case 'Traffic': return Icons.car_crash;
      default: return Icons.home_outlined;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.darkBg,
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            pinned: true,
            backgroundColor: AppTheme.darkBg,
            title: Row(children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(color: AppTheme.warning.withOpacity(.2), borderRadius: BorderRadius.circular(10)),
                child: const Icon(Icons.history, color: AppTheme.warning, size: 20),
              ),
              const SizedBox(width: 12),
              Text('Detection History', style: GoogleFonts.inter(color: AppTheme.textPrimary, fontSize: 20, fontWeight: FontWeight.w700)),
            ]),
            actions: [
              IconButton(
                icon: const Icon(Icons.delete_sweep_outlined, color: AppTheme.textSecondary),
                onPressed: () => ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Clear history coming soon'), backgroundColor: AppTheme.darkCard),
                ),
              ),
            ],
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                // Summary Row
                FadeInDown(
                  child: Row(children: [
                    _buildSummaryChip('Total', '${_records.length}', AppTheme.accentColor),
                    const SizedBox(width: 8),
                    _buildSummaryChip('Humans', '${_records.fold(0,(s,r)=>s+r.detections.length)}', AppTheme.primaryColor),
                    const SizedBox(width: 8),
                    _buildSummaryChip('This Week', '3', AppTheme.success),
                  ]),
                ),
                const SizedBox(height: 16),

                // Filter Chips
                FadeInDown(
                  delay: const Duration(milliseconds: 100),
                  child: SizedBox(
                    height: 36,
                    child: ListView(scrollDirection: Axis.horizontal, children: _filters.map((f) {
                      final active = _filter == f;
                      return GestureDetector(
                        onTap: () => setState(() => _filter = f),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          margin: const EdgeInsets.only(right: 8),
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                          decoration: BoxDecoration(
                            color: active ? AppTheme.primaryColor.withOpacity(.15) : AppTheme.darkCard,
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(color: active ? AppTheme.primaryColor.withOpacity(.5) : AppTheme.textMuted.withOpacity(.2)),
                          ),
                          child: Text(f, style: GoogleFonts.inter(color: active ? AppTheme.primaryColor : AppTheme.textSecondary, fontSize: 13, fontWeight: active ? FontWeight.w600 : FontWeight.w400)),
                        ),
                      );
                    }).toList()),
                  ),
                ),
                const SizedBox(height: 16),

                // List
                if (_filtered.isEmpty)
                  Center(child: Padding(
                    padding: const EdgeInsets.all(40),
                    child: Column(children: [
                      const Icon(Icons.history_toggle_off, color: AppTheme.textMuted, size: 48),
                      const SizedBox(height: 12),
                      Text('No records found', style: GoogleFonts.inter(color: AppTheme.textSecondary, fontSize: 15, fontWeight: FontWeight.w600)),
                    ]),
                  ))
                else
                  ..._filtered.asMap().entries.map((entry) {
                    final r = entry.value;
                    return FadeInUp(
                      delay: Duration(milliseconds: entry.key * 80),
                      child: _buildRecordCard(r),
                    );
                  }),
              ]),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryChip(String label, String value, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        color: color.withOpacity(.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(.25)),
      ),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        Text(value, style: GoogleFonts.inter(color: color, fontSize: 16, fontWeight: FontWeight.w800)),
        const SizedBox(width: 6),
        Text(label, style: GoogleFonts.inter(color: AppTheme.textSecondary, fontSize: 12)),
      ]),
    );
  }

  Widget _buildRecordCard(HistoryRecord r) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: AppTheme.darkCard,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: r.disasterColor.withOpacity(.2)),
      ),
      child: ExpansionTile(
        tilePadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        leading: Container(
          width: 42, height: 42,
          decoration: BoxDecoration(color: r.disasterColor.withOpacity(.15), borderRadius: BorderRadius.circular(10)),
          child: Icon(_disasterIcon(r.disasterType), color: r.disasterColor, size: 20),
        ),
        title: Text(r.imageName, style: GoogleFonts.inter(color: AppTheme.textPrimary, fontSize: 14, fontWeight: FontWeight.w600)),
        subtitle: Row(children: [
          Container(
            margin: const EdgeInsets.only(top: 4),
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
            decoration: BoxDecoration(color: r.disasterColor.withOpacity(.15), borderRadius: BorderRadius.circular(10)),
            child: Text(r.disasterType, style: GoogleFonts.inter(color: r.disasterColor, fontSize: 10, fontWeight: FontWeight.w600)),
          ),
          const SizedBox(width: 8),
          Text(_timeAgo(r.timestamp), style: GoogleFonts.inter(color: AppTheme.textMuted, fontSize: 11)),
        ]),
        trailing: Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
          decoration: BoxDecoration(color: AppTheme.primaryColor.withOpacity(.12), borderRadius: BorderRadius.circular(20)),
          child: Text('${r.detections.length} found', style: GoogleFonts.inter(color: AppTheme.primaryColor, fontSize: 11, fontWeight: FontWeight.w700)),
        ),
        iconColor: AppTheme.textMuted,
        collapsedIconColor: AppTheme.textMuted,
        children: r.detections.map((d) => Container(
          margin: const EdgeInsets.only(bottom: 6),
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(color: AppTheme.darkCardLight, borderRadius: BorderRadius.circular(10)),
          child: Row(children: [
            Container(
              width: 32, height: 32,
              decoration: BoxDecoration(color: d.poseColor.withOpacity(.15), borderRadius: BorderRadius.circular(8)),
              child: Center(child: Text('#${d.id}', style: GoogleFonts.inter(color: d.poseColor, fontSize: 11, fontWeight: FontWeight.w700))),
            ),
            const SizedBox(width: 10),
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text('Human Detected', style: GoogleFonts.inter(color: AppTheme.textPrimary, fontSize: 12, fontWeight: FontWeight.w600)),
              Text('Pose: ${d.pose}', style: GoogleFonts.inter(color: AppTheme.textSecondary, fontSize: 11)),
            ])),
            Text('${(d.confidence * 100).toStringAsFixed(0)}%', style: GoogleFonts.inter(color: d.poseColor, fontSize: 15, fontWeight: FontWeight.w800)),
          ]),
        )).toList(),
      ),
    );
  }
}
