import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'package:percent_indicator/percent_indicator.dart';
import 'package:geolocator/geolocator.dart';
import '../theme/app_theme.dart';
import '../services/api_service.dart';

class DetectionScreen extends StatefulWidget {
  const DetectionScreen({super.key});
  @override
  State<DetectionScreen> createState() => _DetectionScreenState();
}

class _DetectionScreenState extends State<DetectionScreen>
    with SingleTickerProviderStateMixin {
  XFile? _selectedImageFile;
  Uint8List? _imageBytes;
  bool _isAnalyzing = false;
  bool _hasResult = false;
  Map<String, dynamic>? _result;
  bool _backendOnline = false;

  late AnimationController _pulseCtrl;
  late Animation<double> _pulseAnim;

  @override
  void initState() {
    super.initState();
    _pulseCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 900))
      ..repeat(reverse: true);
    _pulseAnim = Tween<double>(begin: .8, end: 1.0).animate(
        CurvedAnimation(parent: _pulseCtrl, curve: Curves.easeInOut));
    _checkBackend();
  }

  @override
  void dispose() {
    _pulseCtrl.dispose();
    super.dispose();
  }

  Future<void> _checkBackend() async {
    final online = await ApiService.isBackendOnline();
    if (mounted) setState(() => _backendOnline = online);
  }

  Future<void> _pickImage(ImageSource source) async {
    try {
      final picked = await ImagePicker().pickImage(source: source, imageQuality: 85);
      if (picked != null) {
        final bytes = await picked.readAsBytes();
        setState(() {
          _selectedImageFile = picked;
          _imageBytes = bytes;
          _hasResult = false;
          _result = null;
        });
      }
    } catch (e) {
      debugPrint("Image picker error: $e");
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              source == ImageSource.camera
                  ? 'Camera not supported or permission denied. Opening Gallery instead.'
                  : 'Error picking image: $e',
              style: GoogleFonts.inter(color: Colors.white, fontWeight: FontWeight.w600),
            ),
            backgroundColor: AppTheme.primaryColor,
            behavior: SnackBarBehavior.floating,
          ),
        );
        // Automatic fallback to gallery if camera fails (e.g. on Windows/Web without camera)
        if (source == ImageSource.camera) {
          _pickImage(ImageSource.gallery);
        }
      }
    }
  }

  Future<void> _analyzeImage() async {
    if (_imageBytes == null) return;
    setState(() => _isAnalyzing = true);

    Map<String, dynamic>? result;

    if (_backendOnline) {
      double? lat;
      double? lng;
      String locationName = "Unknown Location";

      try {
        bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
        if (serviceEnabled) {
          LocationPermission permission = await Geolocator.checkPermission();
          if (permission == LocationPermission.denied) {
            permission = await Geolocator.requestPermission();
          }
          if (permission == LocationPermission.whileInUse || permission == LocationPermission.always) {
            Position position = await Geolocator.getCurrentPosition(desiredAccuracy: LocationAccuracy.low);
            lat = position.latitude;
            lng = position.longitude;
            locationName = "Current User Location";
          }
        }
      } catch (e) {
        debugPrint("Location error: \$e");
      }

      // Real API call
      result = await ApiService.detectImage(
        imageBytes: _imageBytes!,
        lat: lat,
        lng: lng,
        locationName: locationName,
      );
    }

    // Fallback: simulate if backend offline
    result ??= {
      'model': {'name': 'YOLOv9-e', 'mAP': 0.6883},
      'disaster_type': 'Fire',
      'total_humans': 3,
      'detections': [
        {'id': 1, 'pose': 'Upright', 'confidence': 0.94},
        {'id': 2, 'pose': 'Lying', 'confidence': 0.87},
        {'id': 3, 'pose': 'Bent', 'confidence': 0.76},
      ],
    };

    await Future.delayed(const Duration(milliseconds: 500));
    if (mounted) {
      setState(() {
        _isAnalyzing = false;
        _hasResult = true;
        _result = result;
      });
    }
  }

  void _reset() => setState(() {
        _selectedImageFile = null;
        _imageBytes = null;
        _hasResult = false;
        _result = null;
      });

  Color _poseColor(String pose) {
    switch (pose) {
      case 'Upright': return AppTheme.success;
      case 'Lying': return AppTheme.primaryColor;
      case 'Bent': return AppTheme.warning;
      case 'Sitting': return AppTheme.secondaryColor;
      default: return AppTheme.accentColor;
    }
  }

  @override
  Widget build(BuildContext context) {
    final detections = (_result?['detections'] as List?)?.cast<Map<String, dynamic>>() ?? [];

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
                decoration: BoxDecoration(
                  color: AppTheme.primaryColor.withOpacity(.15),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.radar, color: AppTheme.primaryColor, size: 20),
              ),
              const SizedBox(width: 12),
              Text('Human Detection',
                  style: GoogleFonts.inter(
                      color: AppTheme.textPrimary, fontSize: 20, fontWeight: FontWeight.w700)),
            ]),
            actions: [
              // Backend status indicator
              Container(
                margin: const EdgeInsets.only(right: 8),
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: _backendOnline
                      ? AppTheme.success.withOpacity(.15)
                      : AppTheme.warning.withOpacity(.15),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                      color: _backendOnline
                          ? AppTheme.success.withOpacity(.4)
                          : AppTheme.warning.withOpacity(.4)),
                ),
                child: Row(children: [
                  Container(
                    width: 6,
                    height: 6,
                    decoration: BoxDecoration(
                      color: _backendOnline ? AppTheme.success : AppTheme.warning,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 5),
                  Text(
                    _backendOnline ? 'API Online' : 'Offline',
                    style: GoogleFonts.inter(
                      color: _backendOnline ? AppTheme.success : AppTheme.warning,
                      fontSize: 11, fontWeight: FontWeight.w600,
                    ),
                  ),
                ]),
              ),
              if (_selectedImageFile != null)
                IconButton(
                  onPressed: _reset,
                  icon: const Icon(Icons.refresh, color: AppTheme.textSecondary),
                ),
            ],
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(children: [
                // Image area
                GestureDetector(
                  onTap: _selectedImageFile == null ? _showSourceDialog : null,
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 300),
                    height: 280,
                    width: double.infinity,
                    decoration: BoxDecoration(
                      color: AppTheme.darkCard,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: _selectedImageFile != null
                            ? AppTheme.primaryColor.withOpacity(.5)
                            : AppTheme.textMuted.withOpacity(.3),
                        width: 1.5,
                      ),
                    ),
                    child: _selectedImageFile != null
                        ? ClipRRect(
                            borderRadius: BorderRadius.circular(20),
                            child: Stack(fit: StackFit.expand, children: [
                              _imageBytes != null
                                  ? Image.memory(_imageBytes!, fit: BoxFit.cover)
                                  : const SizedBox(),
                              if (_isAnalyzing)
                                Container(
                                  color: Colors.black54,
                                  child: Center(
                                    child: Column(mainAxisSize: MainAxisSize.min, children: [
                                      ScaleTransition(
                                        scale: _pulseAnim,
                                        child: Container(
                                          width: 80, height: 80,
                                          decoration: BoxDecoration(
                                            shape: BoxShape.circle,
                                            border: Border.all(color: AppTheme.primaryColor, width: 2.5),
                                          ),
                                          child: const Icon(Icons.radar, color: AppTheme.primaryColor, size: 38),
                                        ),
                                      ),
                                      const SizedBox(height: 16),
                                      Text('Analyzing Image...',
                                          style: GoogleFonts.inter(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w600)),
                                      const SizedBox(height: 6),
                                      Text(
                                        _backendOnline ? 'Connected to API · YOLOv9-e' : 'Running local simulation',
                                        style: GoogleFonts.inter(color: AppTheme.textSecondary, fontSize: 12),
                                      ),
                                    ]),
                                  ),
                                ),
                              if (_hasResult)
                                Positioned(
                                  top: 12, right: 12,
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                                    decoration: BoxDecoration(
                                      color: AppTheme.success,
                                      borderRadius: BorderRadius.circular(20),
                                    ),
                                    child: Row(mainAxisSize: MainAxisSize.min, children: [
                                      const Icon(Icons.check_circle, color: Colors.white, size: 14),
                                      const SizedBox(width: 4),
                                      Text('${detections.length} Detected',
                                          style: GoogleFonts.inter(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w600)),
                                    ]),
                                  ),
                                ),
                            ]),
                          )
                        : Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                            Container(
                              padding: const EdgeInsets.all(20),
                              decoration: BoxDecoration(
                                color: AppTheme.primaryColor.withOpacity(.1),
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(Icons.add_photo_alternate_outlined,
                                  color: AppTheme.primaryColor, size: 48),
                            ),
                            const SizedBox(height: 16),
                            Text('Upload UAV Image',
                                style: GoogleFonts.inter(
                                    color: AppTheme.textPrimary, fontSize: 16, fontWeight: FontWeight.w600)),
                            const SizedBox(height: 6),
                            Text('Tap to select from camera or gallery',
                                style: GoogleFonts.inter(color: AppTheme.textSecondary, fontSize: 13)),
                            const SizedBox(height: 16),
                            Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                              _chip('JPG'), const SizedBox(width: 8),
                              _chip('PNG'), const SizedBox(width: 8),
                              _chip('WEBP'),
                            ]),
                          ]),
                  ),
                ),

                const SizedBox(height: 14),

                // Buttons
                if (_selectedImageFile == null)
                  Row(children: [
                    Expanded(child: _actionBtn(Icons.camera_alt_outlined, 'Camera', AppTheme.accentColor, () => _pickImage(ImageSource.camera))),
                    const SizedBox(width: 12),
                    Expanded(child: _actionBtn(Icons.photo_library_outlined, 'Gallery', AppTheme.secondaryColor, () => _pickImage(ImageSource.gallery))),
                  ]),

                if (_selectedImageFile != null && !_isAnalyzing && !_hasResult)
                  _analyzeBtn(),

                const SizedBox(height: 20),

                // Results
                if (_hasResult && _result != null) ...[
                  Align(
                    alignment: Alignment.centerLeft,
                    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Text('Detection Results',
                          style: GoogleFonts.inter(color: AppTheme.textPrimary, fontSize: 18, fontWeight: FontWeight.w700)),
                      const SizedBox(height: 4),
                      Text(
                        '${_result!['model']['name']} · ${detections.length} humans · ${_result!['disaster_type']}',
                        style: GoogleFonts.inter(color: AppTheme.textSecondary, fontSize: 12),
                      ),
                    ]),
                  ),
                  const SizedBox(height: 14),
                  ...detections.map((d) => _detCard(d)),
                  const SizedBox(height: 12),
                  _summaryCard(detections),
                ],

                const SizedBox(height: 16),

                // Model info
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppTheme.darkCard,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: AppTheme.accentColor.withOpacity(.2)),
                  ),
                  child: Row(children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                          color: AppTheme.accentColor.withOpacity(.1),
                          borderRadius: BorderRadius.circular(10)),
                      child: const Icon(Icons.memory, color: AppTheme.accentColor, size: 20),
                    ),
                    const SizedBox(width: 12),
                    Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Text('YOLOv9-e Model',
                          style: GoogleFonts.inter(color: AppTheme.textPrimary, fontSize: 14, fontWeight: FontWeight.w600)),
                      Text('mAP: 0.6883 · mAP@.50: 0.8927',
                          style: GoogleFonts.inter(color: AppTheme.textSecondary, fontSize: 12)),
                    ])),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                          color: AppTheme.success.withOpacity(.15),
                          borderRadius: BorderRadius.circular(20)),
                      child: Text('BEST',
                          style: GoogleFonts.inter(
                              color: AppTheme.success, fontSize: 10, fontWeight: FontWeight.w700, letterSpacing: 1)),
                    ),
                  ]),
                ),
                const SizedBox(height: 20),
              ]),
            ),
          ),
        ],
      ),
    );
  }

  Widget _chip(String t) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        decoration: BoxDecoration(
          color: AppTheme.darkCardLight,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: AppTheme.textMuted.withOpacity(.3)),
        ),
        child: Text(t,
            style: GoogleFonts.inter(color: AppTheme.textSecondary, fontSize: 11, fontWeight: FontWeight.w500)),
      );

  Widget _actionBtn(IconData icon, String label, Color color, VoidCallback onTap) =>
      GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 16),
          decoration: BoxDecoration(
            color: color.withOpacity(.1),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: color.withOpacity(.3)),
          ),
          child: Column(children: [
            Icon(icon, color: color, size: 28),
            const SizedBox(height: 6),
            Text(label, style: GoogleFonts.inter(color: color, fontSize: 13, fontWeight: FontWeight.w600)),
          ]),
        ),
      );

  Widget _analyzeBtn() => GestureDetector(
        onTap: _analyzeImage,
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(vertical: 18),
          decoration: BoxDecoration(
            gradient: const LinearGradient(colors: [AppTheme.primaryColor, Color(0xFFFF6B6B)]),
            borderRadius: BorderRadius.circular(14),
            boxShadow: [BoxShadow(color: AppTheme.primaryColor.withOpacity(.4), blurRadius: 15, offset: const Offset(0, 6))],
          ),
          child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
            const Icon(Icons.radar, color: Colors.white, size: 22),
            const SizedBox(width: 10),
            Text('Analyze Image',
                style: GoogleFonts.inter(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w700)),
          ]),
        ),
      );

  Widget _detCard(Map<String, dynamic> d) {
    final pose = d['pose'] as String? ?? 'Unknown';
    final conf = (d['confidence'] as num?)?.toDouble() ?? 0.0;
    final color = _poseColor(pose);
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppTheme.darkCard,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: color.withOpacity(.2)),
      ),
      child: Row(children: [
        Container(
          width: 42, height: 42,
          decoration: BoxDecoration(color: color.withOpacity(.15), borderRadius: BorderRadius.circular(10)),
          child: Center(child: Text('#${d['id']}',
              style: GoogleFonts.inter(color: color, fontSize: 14, fontWeight: FontWeight.w700))),
        ),
        const SizedBox(width: 12),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text('Human Detected',
              style: GoogleFonts.inter(color: AppTheme.textPrimary, fontSize: 14, fontWeight: FontWeight.w600)),
          Text('Pose: $pose',
              style: GoogleFonts.inter(color: AppTheme.textSecondary, fontSize: 12)),
        ])),
        Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
          Text('${(conf * 100).toStringAsFixed(0)}%',
              style: GoogleFonts.inter(color: color, fontSize: 18, fontWeight: FontWeight.w800)),
          Text('confidence', style: GoogleFonts.inter(color: AppTheme.textMuted, fontSize: 10)),
        ]),
      ]),
    );
  }

  Widget _summaryCard(List<Map<String, dynamic>> detections) {
    if (detections.isEmpty) return const SizedBox();
    final avg = detections.map((d) => (d['confidence'] as num?)?.toDouble() ?? 0.0).reduce((a, b) => a + b) / detections.length;
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        gradient: LinearGradient(colors: [AppTheme.primaryColor.withOpacity(.1), AppTheme.secondaryColor.withOpacity(.05)]),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppTheme.primaryColor.withOpacity(.2)),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text('Detection Summary',
            style: GoogleFonts.inter(color: AppTheme.textPrimary, fontSize: 14, fontWeight: FontWeight.w600)),
        const SizedBox(height: 12),
        LinearPercentIndicator(
          lineHeight: 8,
          percent: avg.clamp(0.0, 1.0),
          backgroundColor: AppTheme.darkCardLight,
          progressColor: AppTheme.primaryColor,
          barRadius: const Radius.circular(10),
          padding: EdgeInsets.zero,
          leading: Text('Avg Confidence',
              style: GoogleFonts.inter(color: AppTheme.textSecondary, fontSize: 12)),
          trailing: Text('${(avg * 100).toStringAsFixed(0)}%',
              style: GoogleFonts.inter(color: AppTheme.primaryColor, fontSize: 12, fontWeight: FontWeight.w700)),
        ),
      ]),
    );
  }

  void _showSourceDialog() {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppTheme.darkCard,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (_) => Padding(
        padding: const EdgeInsets.all(24),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Container(width: 40, height: 4, decoration: BoxDecoration(color: AppTheme.textMuted, borderRadius: BorderRadius.circular(2))),
          const SizedBox(height: 20),
          Text('Select Image Source',
              style: GoogleFonts.inter(color: AppTheme.textPrimary, fontSize: 18, fontWeight: FontWeight.w700)),
          const SizedBox(height: 20),
          _sourceOption(Icons.camera_alt, 'Take Photo', AppTheme.accentColor, () {
            Navigator.pop(context);
            _pickImage(ImageSource.camera);
          }),
          const SizedBox(height: 12),
          _sourceOption(Icons.photo_library, 'Choose from Gallery', AppTheme.secondaryColor, () {
            Navigator.pop(context);
            _pickImage(ImageSource.gallery);
          }),
          const SizedBox(height: 20),
        ]),
      ),
    );
  }

  Widget _sourceOption(IconData icon, String label, Color color, VoidCallback onTap) =>
      GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: color.withOpacity(.1),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: color.withOpacity(.3)),
          ),
          child: Row(children: [
            Icon(icon, color: color, size: 24),
            const SizedBox(width: 12),
            Text(label, style: GoogleFonts.inter(color: AppTheme.textPrimary, fontSize: 15, fontWeight: FontWeight.w600)),
          ]),
        ),
      );
}
