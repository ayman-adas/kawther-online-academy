import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:screen_protector/screen_protector.dart';
import 'package:syncfusion_flutter_pdfviewer/pdfviewer.dart';
import '../../../../core/widgets/watermark_overlay.dart';
import '../../../../core/constants/app_colors.dart';

class PdfScreen extends StatefulWidget {
  final String pdfUrl;
  final String userId;
  final String title;

  const PdfScreen({
    super.key,
    required this.pdfUrl,
    required this.userId,
    required this.title,
  });

  @override
  State<PdfScreen> createState() => _PdfScreenState();
}

class _PdfScreenState extends State<PdfScreen> {
  @override
  void initState() {
    super.initState();
    _enableScreenProtection();
  }

  @override
  void dispose() {
    _disableScreenProtection();
    super.dispose();
  }

  Future<void> _enableScreenProtection() async {
    // Prevent generic screenshots (iOS/Android)
    await ScreenProtector.preventScreenshotOn();
    // Android: Protect against screen recording (black screen)
    // iOS: Hides app in switcher
    await ScreenProtector.protectDataLeakageOn();
    // Enable immersive mode to hide status & navigation bars
    await SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
  }

  Future<void> _disableScreenProtection() async {
    await ScreenProtector.preventScreenshotOff();
    await ScreenProtector.protectDataLeakageOff();
    // Restore system UI bars
    await SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
  }

  @override
  Widget build(BuildContext context) {
    // ignore: unused_local_variable
    final l10n = AppLocalizations.of(context)!;
    return Scaffold(
      backgroundColor: AppColors.background,
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: Text(widget.title),
        backgroundColor: Colors.transparent,
        elevation: 0,
        foregroundColor: Colors.black,
      ),
      body: SizedBox(
        width: MediaQuery.of(context).size.width,
        height: MediaQuery.of(context).size.height,
        child: SfPdfViewer.network(
          widget.pdfUrl,
          pageSpacing: 0,
          // Disable interactions for security
          enableDocumentLinkAnnotation: false,
          enableTextSelection: false,
          enableDoubleTapZooming: false,
          // canShowScrollHead: false,
          // canShowScrollStatus: false,
          canShowPaginationDialog: false,
          canShowSignaturePadDialog: false,
          canShowPasswordDialog: false,
          canShowHyperlinkDialog: false,
          enableHyperlinkNavigation: false,
          interactionMode: PdfInteractionMode.pan,
        ),
      ),
    );
  }
}
