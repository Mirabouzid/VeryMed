import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:el_asli/core/services/auth/auth_service.dart';
import 'package:el_asli/data/models/product_model.dart';
import 'package:el_asli/core/services/verification_service.dart';
import 'package:el_asli/core/services/ai_assistant_service.dart';
import 'package:el_asli/core/services/tts_service.dart';

// ── Providers de services ─────────────────────────────────────────

final verificationServiceProvider = Provider<VerificationService>((ref) {
  return VerificationService();
});

final aiAssistantServiceProvider = Provider<AiAssistantService>((ref) {
  return AiAssistantService();
});

final ttsServiceProvider = Provider<TtsService>((ref) {
  return TtsService();
});

// ── Provider thème ────────────────────────────────────────────────

final themeModeProvider = StateProvider<bool>((ref) {
  final box = Hive.box('settings');
  return box.get('darkMode', defaultValue: false) as bool;
});

// ── Provider langue ───────────────────────────────────────────────

final languageProvider = StateProvider<String>((ref) {
  final box = Hive.box('settings');
  return box.get('language', defaultValue: 'fr') as String;
});

// ── Provider scan actuel ──────────────────────────────────────────

final currentScanResultProvider = StateProvider<ScanResult?>((ref) => null);

// ── Provider historique ───────────────────────────────────────────

final scanHistoryProvider = StateNotifierProvider<ScanHistoryNotifier, List<ScanResult>>((ref) {
  return ScanHistoryNotifier();
});

class ScanHistoryNotifier extends StateNotifier<List<ScanResult>> {
  ScanHistoryNotifier() : super([]) {
    _loadFromHive();
  }

  void _loadFromHive() {
    try {
      final box = Hive.box<ScanResult>('scan_history');
      state = box.values.toList().reversed.toList();
    } catch (_) {
      state = [];
    }
  }

  Future<void> addScan(ScanResult result) async {
    try {
      final box = Hive.box<ScanResult>('scan_history');
      await box.put(result.id, result);
      state = [result, ...state];
    } catch (_) {
      state = [result, ...state];
    }
  }

  Future<void> clearHistory() async {
    try {
      final box = Hive.box<ScanResult>('scan_history');
      await box.clear();
    } catch (_) {}
    state = [];
  }

  Future<void> markAsReported(String scanId) async {
    state = state.map((s) {
      if (s.id == scanId) return s.copyWith(wasReported: true);
      return s;
    }).toList();
  }
}

// ── Provider messages assistant ───────────────────────────────────

final chatMessagesProvider = StateNotifierProvider<ChatNotifier, List<ChatMessage>>((ref) {
  return ChatNotifier();
});

class ChatNotifier extends StateNotifier<List<ChatMessage>> {
  ChatNotifier() : super([
    ChatMessage(
      id: 'welcome',
      content: 'مرحباً! Bonjour! Je suis VeryMed, votre assistant pharmaceutique. Scannez un médicament ou posez-moi une question.',
      isUser: false,
      timestamp: DateTime.now(),
    ),
  ]);

  void addMessage(ChatMessage message) {
    state = [...state, message];
  }

  void replaceMessages(List<ChatMessage> messages) {
    state = messages;
  }

  void clearMessages() {
    state = [
      ChatMessage(
        id: 'welcome',
        content: 'مرحباً! Bonjour! Je suis VeryMed, votre assistant pharmaceutique.',
        isUser: false,
        timestamp: DateTime.now(),
      ),
    ];
  }
}

// ── Provider Auth ─────────────────────────────────────────────────

final authServiceProvider = Provider<AuthService>((ref) => AuthService());

final authUserProvider = StateProvider<AuthUser?>((ref) => null);

final isAuthenticatedProvider = Provider<bool>((ref) {
  return ref.watch(authUserProvider) != null;
});

// ── Provider scanning ─────────────────────────────────────────────

final isScanningProvider = StateProvider<bool>((ref) => false);
final isLoadingVerificationProvider = StateProvider<bool>((ref) => false);
final isListeningProvider = StateProvider<bool>((ref) => false);
final isSpeakingProvider = StateProvider<bool>((ref) => false);
