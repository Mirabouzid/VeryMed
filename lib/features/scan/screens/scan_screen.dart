import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:image_picker/image_picker.dart';
import 'package:el_asli/core/constants/app_constants.dart';
import 'package:el_asli/core/theme/app_theme.dart';
import 'package:el_asli/data/providers/app_providers.dart';
import 'package:el_asli/data/models/product_model.dart';
import 'package:el_asli/features/scan/widgets/scan_overlay.dart';

class ScanScreen extends ConsumerStatefulWidget {
  const ScanScreen({super.key});
  @override
  ConsumerState<ScanScreen> createState() => _ScanScreenState();
}

class _ScanScreenState extends ConsumerState<ScanScreen>
    with TickerProviderStateMixin {
  late MobileScannerController _scanner;
  late AnimationController _pulseCtrl;
  late Animation<double> _pulseAnim;

  bool _isFlashOn   = false;
  bool _isProcessing = false;
  bool _hasScanned  = false;
  ScanMode _mode    = ScanMode.barcode;
  String _statusMsg = 'Pointez vers le code-barres ou l\'emballage';
  String _statusMsgAr = 'وجّه الكاميرا نحو الرمز الشريطي';

  @override
  void initState() {
    super.initState();
    _scanner = MobileScannerController(
      detectionSpeed: DetectionSpeed.noDuplicates,
      facing: CameraFacing.back,
      torchEnabled: false,
    );
    _pulseCtrl = AnimationController(vsync: this, duration: const Duration(seconds: 2))
      ..repeat(reverse: true);
    _pulseAnim = Tween<double>(begin: 0.85, end: 1.0).animate(
      CurvedAnimation(parent: _pulseCtrl, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _scanner.dispose();
    _pulseCtrl.dispose();
    super.dispose();
  }

 
  Future<void> _onDetect(BarcodeCapture capture) async {
    if (_isProcessing || _hasScanned) return;
    final raw = capture.barcodes.firstOrNull?.rawValue;
    if (raw == null || raw.isEmpty) return;

    HapticFeedback.mediumImpact(); // retour haptique
    setState(() {
      _isProcessing = true;
      _hasScanned   = true;
      _statusMsg    = 'Code détecté ✓\nVérification ANMPS...';
      _statusMsgAr  = 'تم اكتشاف الرمز ✓\nجاري التحقق...';
    });
    await _scanner.stop();
    await _processCode(raw, ScanType.barcode);
  }

  
  Future<void> _pickGallery() async {
    final img = await ImagePicker().pickImage(source: ImageSource.gallery,
        imageQuality: 90);
    if (img == null) return;

    setState(() { _isProcessing = true; _statusMsg = 'Analyse de l\'image…'; });

  
    final capture = await _scanner.analyzeImage(img.path);
    if (capture != null && capture.barcodes.isNotEmpty) {
      final code = capture.barcodes.first.rawValue ?? '';
      if (code.isNotEmpty) { await _processCode(code, ScanType.barcode); return; }
    }
   
    await _runOcr(img.path);
  }

 
  Future<void> _runOcr(String path) async {
    setState(() {
      _statusMsg = 'OCR non disponible dans cette version';
      _isProcessing = false;
      _hasScanned = false;
    });
    if (!mounted) return;
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('OCR non disponible'),
        content: const Text(
          'La lecture de texte sur emballage sera disponible dans la prochaine version.\n\n'
          'Utilisez la saisie manuelle pour entrer le nom ou le code.',
        ),
        actions: [
          TextButton(
            onPressed: () { Navigator.pop(context); _manualEntry(); },
            child: const Text('Saisie manuelle'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }


  Future<void> _manualEntry() async {
    final ctrl = TextEditingController();
    final code = await showDialog<String>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Row(children: [
          Icon(Icons.keyboard_rounded, color: AppTheme.primaryGreen),
          SizedBox(width: 8),
          Text('Saisie manuelle'),
        ]),
        content: TextField(
          controller: ctrl,
          keyboardType: TextInputType.text,
          autofocus: true,
          decoration: const InputDecoration(
            labelText: 'Code-barres ou nom du médicament',
            hintText: 'Ex: 3400930024263 ou Doliprane',
            prefixIcon: Icon(Icons.qr_code_rounded),
          ),
          onSubmitted: (v) => Navigator.pop(context, v),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Annuler')),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, ctrl.text),
            child: const Text('Vérifier'),
          ),
        ],
      ),
    );
    if (code != null && code.trim().isNotEmpty) {
      final isBarcode = RegExp(r'^\d{8,14}$').hasMatch(code.trim());
      await _processCode(code.trim(),
          isBarcode ? ScanType.barcode : ScanType.manual);
    }
  }


  Future<void> _processCode(String code, ScanType type) async {
    ref.read(isLoadingVerificationProvider.notifier).state = true;
    try {
      final service = ref.read(verificationServiceProvider);
      final ScanResult result = type == ScanType.ocr || type == ScanType.manual
          ? await service.verifyByText(code)
          : await service.verify(code, type: type);

      await ref.read(scanHistoryProvider.notifier).addScan(result);
      ref.read(currentScanResultProvider.notifier).state = result;

      if (mounted) context.push(AppRoutes.results, extra: result);
    } catch (e) {
      if (mounted) _errorDialog('Erreur de vérification\n$e');
    } finally {
      ref.read(isLoadingVerificationProvider.notifier).state = false;
      if (mounted) _resetState();
    }
  }

  void _resetState() {
    setState(() {
      _isProcessing = false;
      _hasScanned   = false;
      _mode         = ScanMode.barcode;
      _statusMsg    = 'Pointez vers le code-barres ou l\'emballage';
      _statusMsgAr  = 'وجّه الكاميرا نحو الرمز الشريطي';
    });
    _scanner.start();
  }

  void _noResult() {
    setState(() { _isProcessing = false; _hasScanned = false; });
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Aucun résultat'),
        content: const Text('Aucun code ni texte lisible trouvé.\n'
            'Essayez d\'améliorer l\'éclairage ou utilisez la saisie manuelle.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('OK')),
          ElevatedButton(onPressed: () { Navigator.pop(context); _manualEntry(); },
              child: const Text('Saisie manuelle')),
        ],
      ),
    );
  }

  void _errorDialog(String msg) {
    setState(() { _isProcessing = false; _hasScanned = false; });
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Row(children: [
          Icon(Icons.error_outline_rounded, color: AppTheme.dangerRed),
          SizedBox(width: 8), Text('Erreur'),
        ]),
        content: Text(msg),
        actions: [TextButton(onPressed: () => Navigator.pop(context), child: const Text('OK'))],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isLoading = ref.watch(isLoadingVerificationProvider);
    final top = MediaQuery.of(context).padding.top;

    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(children: [

       
        MobileScanner(controller: _scanner, onDetect: _onDetect),

      
        ScanOverlay(
          pulseAnimation: _pulseAnim,
          isProcessing: _isProcessing,
          statusMessage: _statusMsg,
        ),

       
        Positioned(
          top: top + 54,
          left: 0, right: 0,
          child: Center(child: _ModeBadge(mode: _mode)),
        ),

       
        if (isLoading)
          Container(
            color: Colors.black.withValues(alpha: 0.75),
            child: Center(child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const SizedBox(
                  width: 56, height: 56,
                  child: CircularProgressIndicator(
                    color: AppTheme.primaryGreen, strokeWidth: 3),
                ),
                const SizedBox(height: 20),
                const Text('Vérification ANMPS en cours…',
                    style: TextStyle(color: Colors.white, fontSize: 15,
                        fontWeight: FontWeight.w600)),
                const SizedBox(height: 6),
                Text(_statusMsgAr,
                    style: TextStyle(color: Colors.white.withValues(alpha: 0.7),
                        fontSize: 13)),
              ],
            )),
          ),

      
        Positioned(
          top: top + 8, left: 16,
          child: _CircleButton(
            icon: Icons.arrow_back_rounded,
            onTap: () => context.pop(),
          ),
        ),

    
        Positioned(
          top: top + 12, left: 0, right: 0,
          child: const Center(
            child: Text('El Asli —فيري ميد',
                style: TextStyle(color: Colors.white, fontSize: 17,
                    fontWeight: FontWeight.w700)),
          ),
        ),

       
        Positioned(
          top: top + 8, right: 16,
          child: _CircleButton(
            icon: _isFlashOn ? Icons.flash_on_rounded : Icons.flash_off_rounded,
            color: _isFlashOn ? AppTheme.warningOrange : Colors.white,
            onTap: () {
              setState(() => _isFlashOn = !_isFlashOn);
              _scanner.toggleTorch();
            },
          ),
        ),

        
        Positioned(
          bottom: 0, left: 0, right: 0,
          child: _BottomBar(
            isFlashOn: _isFlashOn,
            hasScanned: _hasScanned,
            onGallery: _pickGallery,
            onManual: _manualEntry,
            onSwitch: () => _scanner.switchCamera(),
            onReset: _resetState,
            onFlash: () {
              setState(() => _isFlashOn = !_isFlashOn);
              _scanner.toggleTorch();
            },
          ),
        ),
      ]),
    );
  }
}


enum ScanMode { barcode, ocr, manual }

class _ModeBadge extends StatelessWidget {
  final ScanMode mode;
  const _ModeBadge({required this.mode});

  @override
  Widget build(BuildContext context) {
    final labels = {
      ScanMode.barcode: ('Code-barres', Icons.qr_code_2_rounded, AppTheme.primaryGreen),
      ScanMode.ocr:     ('Lecture OCR', Icons.document_scanner_rounded, AppTheme.accentBlue),
      ScanMode.manual:  ('Saisie manuelle', Icons.keyboard_rounded, AppTheme.warningOrange),
    };
    final (label, icon, color) = labels[mode]!;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha: 0.5)),
      ),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        Icon(icon, color: color, size: 14),
        const SizedBox(width: 6),
        Text(label, style: TextStyle(color: color, fontSize: 12,
            fontWeight: FontWeight.w600)),
      ]),
    );
  }
}


class _CircleButton extends StatelessWidget {
  final IconData icon;
  final Color color;
  final VoidCallback? onTap;

  const _CircleButton({
    required this.icon,
    this.color = Colors.white,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: Colors.black.withValues(alpha: 0.45),
          shape: BoxShape.circle,
        ),
        child: Icon(icon, color: color, size: 22),
      ),
    );
  }
}

class _BottomBar extends StatelessWidget {
  final bool isFlashOn;
  final bool hasScanned;
  final VoidCallback onGallery;
  final VoidCallback onManual;
  final VoidCallback onSwitch;
  final VoidCallback onReset;
  final VoidCallback onFlash;

  const _BottomBar({
    required this.isFlashOn, required this.hasScanned,
    required this.onGallery, required this.onManual,
    required this.onSwitch,  required this.onReset,
    required this.onFlash,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.only(
        left: 16, right: 16, top: 18,
        bottom: MediaQuery.of(context).padding.bottom + 18,
      ),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.bottomCenter, end: Alignment.topCenter,
          colors: [Colors.black.withValues(alpha: 0.92), Colors.transparent],
        ),
      ),
      child: Column(mainAxisSize: MainAxisSize.min, children: [
        // Type de codes supportés
        const _SupportedCodesBadges(),
        const SizedBox(height: 16),
        // Boutons
        Row(mainAxisAlignment: MainAxisAlignment.spaceEvenly, children: [
          _ActionBtn(icon: Icons.photo_library_rounded,
              label: 'Galerie', onTap: onGallery),
          _ActionBtn(icon: Icons.keyboard_rounded,
              label: 'Manuel', onTap: onManual),
          // Bouton central : reset ou aide
          _ActionBtn(
            icon: hasScanned ? Icons.refresh_rounded : Icons.help_outline_rounded,
            label: hasScanned ? 'Nouveau' : 'Aide',
            color: hasScanned ? AppTheme.primaryGreen : Colors.white,
            large: hasScanned,
            onTap: hasScanned ? onReset : () => _showHelp(context),
          ),
          _ActionBtn(icon: Icons.flip_camera_ios_rounded,
              label: 'Caméra', onTap: onSwitch),
          _ActionBtn(
            icon: isFlashOn ? Icons.flash_on_rounded : Icons.flash_off_rounded,
            label: 'Flash',
            color: isFlashOn ? AppTheme.warningOrange : Colors.white,
            onTap: onFlash,
          ),
        ]),
      ]),
    );
  }

  void _showHelp(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (_) => Container(
        margin: const EdgeInsets.all(16),
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Theme.of(context).scaffoldBackgroundColor,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Container(width: 40, height: 4,
              decoration: BoxDecoration(color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(2))),
          const SizedBox(height: 16),
          const Text('Comment utiliser El Asli',
              style: TextStyle(fontSize: 17, fontWeight: FontWeight.w700)),
          const SizedBox(height: 16),
          ...[
            ('Scan auto', Icons.qr_code_scanner_rounded,
                'Pointez la caméra vers le code-barres ou QR code'),
            ('Galerie', Icons.photo_library_rounded,
                'Choisissez une photo depuis votre galerie'),
            ('Manuel', Icons.keyboard_rounded,
                'Saisissez le code ou le nom du médicament'),
            ('OCR', Icons.document_scanner_rounded,
                'Le texte de l\'emballage est analysé automatiquement'),
          ].map((item) => Padding(
            padding: const EdgeInsets.symmetric(vertical: 6),
            child: Row(children: [
              Container(padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(color: AppTheme.primaryGreen.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8)),
                child: Icon(item.$2, color: AppTheme.primaryGreen, size: 18)),
              const SizedBox(width: 12),
              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(item.$1, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
                Text(item.$3, style: const TextStyle(fontSize: 12, color: Colors.grey)),
              ])),
            ]),
          )),
          const SizedBox(height: 8),
        ]),
      ),
    );
  }
}

class _SupportedCodesBadges extends StatelessWidget {
  const _SupportedCodesBadges();
  @override
  Widget build(BuildContext context) {
    const codes = ['EAN-13', 'QR', 'Code 128', 'Datamatrix', 'OCR'];
    return Wrap(
      alignment: WrapAlignment.center,
      spacing: 6,
      children: codes.map((c) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 3),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(6),
          border: Border.all(color: Colors.white.withValues(alpha: 0.25)),
        ),
        child: Text(c, style: const TextStyle(color: Colors.white, fontSize: 10,
            fontWeight: FontWeight.w500)),
      )).toList(),
    );
  }
}

class _ActionBtn extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final bool large;
  final VoidCallback? onTap;

  const _ActionBtn({
    required this.icon, required this.label,
    this.color = Colors.white, this.large = false, this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Column(mainAxisSize: MainAxisSize.min, children: [
        Container(
          padding: EdgeInsets.all(large ? 16 : 12),
          decoration: BoxDecoration(
            color: large
                ? color.withValues(alpha: 0.9)
                : Colors.white.withValues(alpha: 0.12),
            shape: BoxShape.circle,
            border: large ? null : Border.all(
                color: Colors.white.withValues(alpha: 0.2)),
            boxShadow: large ? [BoxShadow(color: color.withValues(alpha: 0.4),
                blurRadius: 12, offset: const Offset(0, 4))] : null,
          ),
          child: Icon(icon, color: large ? Colors.white : color,
              size: large ? 28 : 22),
        ),
        const SizedBox(height: 4),
        Text(label, style: TextStyle(
            color: onTap != null ? color : Colors.white30,
            fontSize: 10, fontWeight: FontWeight.w500)),
      ]),
    );
  }
}
