import 'package:flutter_tts/flutter_tts.dart';

/// Service Text-to-Speech multilingue
class TtsService {
  static final TtsService _instance = TtsService._internal();
  factory TtsService() => _instance;
  TtsService._internal();

  final FlutterTts _tts = FlutterTts();
  bool _isInitialized = false;
  String _currentLanguage = 'fr-FR';

  Future<void> init() async {
    if (_isInitialized) return;
    await _tts.setLanguage('fr-FR');
    await _tts.setSpeechRate(0.5);
    await _tts.setVolume(1.0);
    await _tts.setPitch(1.0);
    _isInitialized = true;
  }

  Future<void> speak(String text, {String? language}) async {
    await init();
    if (language != null && language != _currentLanguage) {
      await setLanguage(language);
    }
    await _tts.stop();
    await _tts.speak(text);
  }

  Future<void> setLanguage(String langCode) async {
    _currentLanguage = langCode;
    await _tts.setLanguage(langCode);
  }

  Future<void> stop() async {
    await _tts.stop();
  }

  Future<void> speakAuthentic(String productName) async {
    final msg = _currentLanguage.startsWith('ar')
        ? 'هذا الدواء $productName أصلي وموثوق'
        : 'Le médicament $productName est authentique et approuvé.';
    await speak(msg);
  }

  Future<void> speakSuspect(String productName) async {
    final msg = _currentLanguage.startsWith('ar')
        ? 'تحذير: هذا الدواء $productName مشكوك في صحته. لا تستعمله.'
        : 'Attention ! Ce produit $productName est potentiellement contrefait. Ne l\'utilisez pas.';
    await speak(msg);
  }

  /// Mapping langues supportées
  static const Map<String, String> supportedLanguages = {
    'fr': 'fr-FR',
    'ar': 'ar-SA',
    'en': 'en-US',
    'tn': 'ar-TN', // Derja tunisien (fallback vers ar-SA)
  };
}
