import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:speech_to_text/speech_to_text.dart';
import 'package:uuid/uuid.dart';
import 'package:el_asli/core/theme/app_theme.dart';
import 'package:el_asli/data/models/product_model.dart';
import 'package:el_asli/data/providers/app_providers.dart';

class AssistantScreen extends ConsumerStatefulWidget {
  const AssistantScreen({super.key});

  @override
  ConsumerState<AssistantScreen> createState() => _AssistantScreenState();
}

class _AssistantScreenState extends ConsumerState<AssistantScreen> {
  final TextEditingController _textController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final SpeechToText _stt = SpeechToText();
  final _uuid = const Uuid();

  bool _sttAvailable = false;
  String _recognizedText = '';

  final List<String> _languages = ['fr', 'ar', 'tn', 'en'];
  final Map<String, String> _langLabels = {
    'fr': '🇫🇷 Français',
    'ar': '🇸🇦 العربية',
    'tn': '🇹🇳 Derja',
    'en': '🇬🇧 English',
  };

  @override
  void initState() {
    super.initState();
    _initStt();
  }

  Future<void> _initStt() async {
    final available = await _stt.initialize(
      onError: (_) => setState(() {}),
      onStatus: (_) => setState(() {}),
    );
    if (mounted) setState(() => _sttAvailable = available);
  }

  @override
  void dispose() {
    _textController.dispose();
    _scrollController.dispose();
    _stt.stop();
    super.dispose();
  }


  Future<void> _sendMessage(String text, {bool isVoice = false}) async {
    if (text.trim().isEmpty) return;
    _textController.clear();

    final userMsg = ChatMessage(
      id: _uuid.v4(),
      content: text.trim(),
      isUser: true,
      timestamp: DateTime.now(),
      isVoice: isVoice,
    );
    ref.read(chatMessagesProvider.notifier).addMessage(userMsg);
    _scrollToBottom();

    // Indicateur de frappe
    final typingMsg = ChatMessage(
      id: 'typing',
      content: '...',
      isUser: false,
      timestamp: DateTime.now(),
    );
    ref.read(chatMessagesProvider.notifier).addMessage(typingMsg);

    try {
      final lang = ref.read(languageProvider);
      final aiService = ref.read(aiAssistantServiceProvider);
      aiService.setLanguage(lang);

      final response = await aiService.ask(text.trim());
      final tts = ref.read(ttsServiceProvider);

      // Supprimer indicateur typing et ajouter vraie réponse
      final messages = ref.read(chatMessagesProvider);
      final filtered = messages.where((m) => m.id != 'typing').toList();
      ref.read(chatMessagesProvider.notifier).replaceMessages(filtered);

      final aiMsg = ChatMessage(
        id: _uuid.v4(),
        content: response,
        isUser: false,
        timestamp: DateTime.now(),
      );
      ref.read(chatMessagesProvider.notifier).addMessage(aiMsg);

      // Lire à voix haute la réponse
      final ttsLang = {'fr': 'fr-FR', 'ar': 'ar-SA', 'tn': 'ar-SA', 'en': 'en-US'}[lang] ?? 'fr-FR';
      await tts.speak(response, language: ttsLang);
    } catch (e) {
      final messages = ref.read(chatMessagesProvider);
      final filtered = messages.where((m) => m.id != 'typing').toList();
      ref.read(chatMessagesProvider.notifier).replaceMessages(filtered);

      ref.read(chatMessagesProvider.notifier).addMessage(ChatMessage(
        id: _uuid.v4(),
        content: 'Désolé, je n\'ai pas pu répondre. Vérifiez votre connexion.',
        isUser: false,
        timestamp: DateTime.now(),
      ));
    }

    _scrollToBottom();
  }

  
  Future<void> _toggleListening() async {
    final isListening = ref.read(isListeningProvider);

    if (isListening) {
      await _stt.stop();
      ref.read(isListeningProvider.notifier).state = false;
      if (_recognizedText.isNotEmpty) {
        await _sendMessage(_recognizedText, isVoice: true);
        _recognizedText = '';
      }
    } else {
      if (!_sttAvailable) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Reconnaissance vocale non disponible')),
        );
        return;
      }

      ref.read(isListeningProvider.notifier).state = true;
      final lang = ref.read(languageProvider);
      final localeId = {'fr': 'fr_FR', 'ar': 'ar_SA', 'tn': 'ar_SA', 'en': 'en_US'}[lang] ?? 'fr_FR';

      await _stt.listen(
        onResult: (result) {
          setState(() => _recognizedText = result.recognizedWords);
          _textController.text = result.recognizedWords;
        },
        listenOptions: SpeechListenOptions(localeId: localeId, listenFor: const Duration(seconds: 30), pauseFor: const Duration(seconds: 3), onDevice: false),
      );
    }
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final messages = ref.watch(chatMessagesProvider);
    final isListening = ref.watch(isListeningProvider);
    final currentLang = ref.watch(languageProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.smart_toy_rounded, color: AppTheme.primaryGreen, size: 22),
            SizedBox(width: 8),
            Text('Assistant VeryMed'),
          ],
        ),
        actions: [
          // Sélecteur de langue
          PopupMenuButton<String>(
            icon: Text(
              _langLabels[currentLang] ?? '🇫🇷',
              style: const TextStyle(fontSize: 13),
            ),
            onSelected: (lang) {
              ref.read(languageProvider.notifier).state = lang;
              final tts = ref.read(ttsServiceProvider);
              final ttsLang = {'fr': 'fr-FR', 'ar': 'ar-SA', 'tn': 'ar-SA', 'en': 'en-US'}[lang] ?? 'fr-FR';
              tts.setLanguage(ttsLang);
            },
            itemBuilder: (_) => _languages
                .map((l) => PopupMenuItem(
                      value: l,
                      child: Text(_langLabels[l] ?? l),
                    ))
                .toList(),
          ),
          // Effacer historique
          IconButton(
            icon: const Icon(Icons.delete_sweep_rounded),
            onPressed: () {
              ref.read(chatMessagesProvider.notifier).clearMessages();
              ref.read(ttsServiceProvider).stop();
            },
            tooltip: 'Effacer la conversation',
          ),
        ],
      ),

      body: Column(
        children: [
         
          _QuickSuggestions(onTap: _sendMessage),

         
          Expanded(
            child: ListView.builder(
              controller: _scrollController,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              itemCount: messages.length,
              itemBuilder: (context, index) {
                return _MessageBubble(message: messages[index]);
              },
            ),
          ),

      
          if (isListening)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              color: AppTheme.primaryGreen.withValues(alpha: 0.1),
              child: Row(
                children: [
                  const Icon(Icons.mic_rounded, color: AppTheme.primaryGreen, size: 18),
                  const SizedBox(width: 8),
                  Text(
                    _recognizedText.isEmpty
                        ? 'Parlez maintenant...'
                        : _recognizedText,
                    style: const TextStyle(
                      color: AppTheme.primaryGreen,
                      fontSize: 13,
                    ),
                  ),
                ],
              ),
            ),

      
          _InputArea(
            controller: _textController,
            isListening: isListening,
            sttAvailable: _sttAvailable,
            onSend: () => _sendMessage(_textController.text),
            onVoiceTap: _toggleListening,
          ),
        ],
      ),
    );
  }
}


class _QuickSuggestions extends StatelessWidget {
  final Future<void> Function(String) onTap;

  const _QuickSuggestions({required this.onTap});

  @override
  Widget build(BuildContext context) {
    final suggestions = [
      'Dangers des faux médicaments',
      'Comment vérifier un médicament ?',
      'Où signaler une contrefaçon ?',
      'Effets du dernier scan',
    ];

    return SizedBox(
      height: 40,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: suggestions.length,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (context, i) => GestureDetector(
          onTap: () => onTap(suggestions[i]),
          child: Container(
            alignment: Alignment.center,
            padding: const EdgeInsets.symmetric(horizontal: 14),
            decoration: BoxDecoration(
              color: AppTheme.primaryGreen.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: AppTheme.primaryGreen.withValues(alpha: 0.3)),
            ),
            child: Text(
              suggestions[i],
              style: const TextStyle(
                fontSize: 12,
                color: AppTheme.primaryGreen,
              ),
            ),
          ),
        ),
      ),
    );
  }
}


class _MessageBubble extends StatelessWidget {
  final ChatMessage message;
  const _MessageBubble({required this.message});

  @override
  Widget build(BuildContext context) {
    final isTyping = message.id == 'typing';
    final isUser = message.isUser;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment:
            isUser ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          if (!isUser) ...[
            // Avatar assistant
            Container(
              width: 32,
              height: 32,
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [AppTheme.primaryGreen, AppTheme.accentBlue],
                ),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.smart_toy_rounded,
                  color: Colors.white, size: 16),
            ),
            const SizedBox(width: 8),
          ],

          // Bulle
          Flexible(
            child: Container(
              constraints: BoxConstraints(
                maxWidth: MediaQuery.of(context).size.width * 0.75,
              ),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: isUser
                    ? AppTheme.primaryGreen
                    : Theme.of(context).cardTheme.color,
                borderRadius: BorderRadius.only(
                  topLeft: const Radius.circular(16),
                  topRight: const Radius.circular(16),
                  bottomLeft: Radius.circular(isUser ? 16 : 4),
                  bottomRight: Radius.circular(isUser ? 4 : 16),
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.06),
                    blurRadius: 6,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: isTyping
                  ? _TypingIndicator()
                  : Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (message.isVoice)
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.mic_rounded,
                                size: 12,
                                color: isUser
                                    ? Colors.white70
                                    : AppTheme.primaryGreen,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                'Message vocal',
                                style: TextStyle(
                                  fontSize: 10,
                                  color: isUser
                                      ? Colors.white70
                                      : AppTheme.primaryGreen,
                                ),
                              ),
                              const SizedBox(height: 4),
                            ],
                          ),
                        Text(
                          message.content,
                          style: TextStyle(
                            color: isUser ? Colors.white : null,
                            fontSize: 14,
                            height: 1.5,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          _formatTime(message.timestamp),
                          style: TextStyle(
                            fontSize: 10,
                            color: isUser
                                ? Colors.white60
                                : const Color(0xFF9EBEBB),
                          ),
                        ),
                      ],
                    ),
            ),
          ),

          if (isUser) const SizedBox(width: 8),
        ],
      ),
    );
  }

  String _formatTime(DateTime dt) {
    return '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
  }
}

class _TypingIndicator extends StatefulWidget {
  @override
  State<_TypingIndicator> createState() => _TypingIndicatorState();
}

class _TypingIndicatorState extends State<_TypingIndicator>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (_, __) {
        return Row(
          mainAxisSize: MainAxisSize.min,
          children: List.generate(3, (i) {
            final delay = i * 0.33;
            final value = ((_controller.value - delay) % 1.0).clamp(0.0, 1.0);
            final opacity = value < 0.5 ? value * 2 : (1 - value) * 2;
            return Container(
              margin: const EdgeInsets.symmetric(horizontal: 2),
              width: 7,
              height: 7,
              decoration: BoxDecoration(
                color: AppTheme.primaryGreen.withValues(alpha: 0.3 + opacity * 0.7),
                shape: BoxShape.circle,
              ),
            );
          }),
        );
      },
    );
  }
}

// ── Zone de saisie ──────────────────────────────────────────────────
class _InputArea extends StatelessWidget {
  final TextEditingController controller;
  final bool isListening;
  final bool sttAvailable;
  final VoidCallback onSend;
  final VoidCallback onVoiceTap;

  const _InputArea({
    required this.controller,
    required this.isListening,
    required this.sttAvailable,
    required this.onSend,
    required this.onVoiceTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.only(
        left: 16,
        right: 16,
        top: 10,
        bottom: MediaQuery.of(context).padding.bottom + 10,
      ),
      decoration: BoxDecoration(
        color: Theme.of(context).scaffoldBackgroundColor,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 10,
            offset: const Offset(0, -3),
          ),
        ],
      ),
      child: Row(
        children: [
          // Bouton vocal
          GestureDetector(
            onTap: onVoiceTap,
            child: Container(
              width: 46,
              height: 46,
              decoration: BoxDecoration(
                color: isListening
                    ? AppTheme.dangerRed
                    : AppTheme.primaryGreen.withValues(alpha: 0.1),
                shape: BoxShape.circle,
                border: Border.all(
                  color: isListening
                      ? AppTheme.dangerRed
                      : AppTheme.primaryGreen.withValues(alpha: 0.3),
                ),
              ),
              child: Icon(
                isListening ? Icons.stop_rounded : Icons.mic_rounded,
                color: isListening ? Colors.white : AppTheme.primaryGreen,
                size: 20,
              ),
            ),
          ),
          const SizedBox(width: 10),

          // Champ texte
          Expanded(
            child: TextField(
              controller: controller,
              maxLines: 3,
              minLines: 1,
              textInputAction: TextInputAction.send,
              onSubmitted: (_) => onSend(),
              decoration: InputDecoration(
                hintText: 'Posez votre question...',
                contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16, vertical: 12),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(24),
                  borderSide: BorderSide.none,
                ),
                filled: true,
              ),
            ),
          ),
          const SizedBox(width: 10),

          // Bouton envoyer
          GestureDetector(
            onTap: onSend,
            child: Container(
              width: 46,
              height: 46,
              decoration: const BoxDecoration(
                color: AppTheme.primaryGreen,
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.send_rounded,
                  color: Colors.white, size: 20),
            ),
          ),
        ],
      ),
    );
  }
}
