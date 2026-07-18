import 'package:el_asli/data/models/product_model.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

/// Service IA pour l'assistant vocal multilingue
/// Utilise Gemini API avec fallback local
class AiAssistantService {
  static final AiAssistantService _instance = AiAssistantService._internal();
  factory AiAssistantService() => _instance;
  AiAssistantService._internal();

  ProductModel? _lastScannedProduct;
  String _currentLanguage = 'fr';

  void setContext(ProductModel? product) {
    _lastScannedProduct = product;
  }

  void setLanguage(String lang) {
    _currentLanguage = lang;
  }

  Future<String> ask(String question) async {
    // Essayer Gemini API d'abord
    try {
      return await _askGemini(question);
    } catch (_) {
      // Fallback vers réponses locales
      return _localFallback(question);
    }
  }

  Future<String> _askGemini(String question) async {
    // TODO: Remplacer YOUR_GEMINI_API_KEY par votre clé réelle
    const apiKey = 'YOUR_GEMINI_API_KEY';
    if (apiKey == 'YOUR_GEMINI_API_KEY') {
      throw Exception('Gemini API key not configured');
    }

    final context = _buildContext();
    final prompt = '$context\n\nQuestion: $question';

    final response = await http.post(
      Uri.parse(
        'https://generativelanguage.googleapis.com/v1beta/models/gemini-pro:generateContent?key=$apiKey',
      ),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'contents': [
          {
            'parts': [
              {'text': prompt}
            ]
          }
        ],
        'generationConfig': {
          'temperature': 0.7,
          'maxOutputTokens': 512,
        }
      }),
    ).timeout(const Duration(seconds: 15));

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body) as Map<String, dynamic>;
      return data['candidates'][0]['content']['parts'][0]['text'] as String;
    }
    throw Exception('Gemini API error: ${response.statusCode}');
  }

  String _buildContext() {
    final lang = _languageInstruction();
    var ctx = '''Tu es un assistant pharmaceutique expert nommé "VeryMed".
$lang
Tu aides les utilisateurs à comprendre les médicaments, vérifier leur authenticité et les risques des contrefaçons.
Sois bref, clair et bienveillant. Ne donne pas de conseils médicaux engageant ta responsabilité.''';

    if (_lastScannedProduct != null) {
      final p = _lastScannedProduct!;
      ctx += '''

Dernier médicament scanné :
- Nom: ${p.name}
- Fabricant: ${p.manufacturer}
- Authentique: ${p.isAuthentic ? "OUI" : "NON - SUSPECT"}
- Catégorie: ${p.category}''';
    }
    return ctx;
  }

  String _languageInstruction() {
    switch (_currentLanguage) {
      case 'ar':
        return 'Réponds en arabe classique (العربية الفصحى).';
      case 'tn':
        return 'Réponds en dialecte tunisien (الدارجة التونسية) de manière simple et accessible.';
      case 'en':
        return 'Reply in English.';
      default:
        return 'Réponds en français.';
    }
  }

  /// Réponses locales intelligentes sans API
  String _localFallback(String question) {
    final q = question.toLowerCase();

    // Contrefaçon
    if (q.contains('contrefait') || q.contains('faux') || q.contains('danger') ||
        q.contains('مزور') || q.contains('fake')) {
      return _getLocalResponse('counterfeit');
    }

    // Résultat du scan actuel
    if ((q.contains('scan') || q.contains('résultat') || q.contains('médicament')) &&
        _lastScannedProduct != null) {
      return _getLocalResponse('scan_result');
    }

    // Pharmacie
    if (q.contains('pharmacie') || q.contains('trouver') || q.contains('acheter')) {
      return _getLocalResponse('pharmacy');
    }

    // Effets secondaires
    if (q.contains('effet') || q.contains('secondaire') || q.contains('أعراض')) {
      return _getLocalResponse('side_effects');
    }

    // Expiration
    if (q.contains('expir') || q.contains('périm') || q.contains('date')) {
      return _getLocalResponse('expiration');
    }

    return _getLocalResponse('default');
  }

  String _getLocalResponse(String key) {
    final responses = _localResponses[_currentLanguage] ?? _localResponses['fr']!;
    return responses[key] ?? responses['default']!;
  }

  static const Map<String, Map<String, String>> _localResponses = {
    'fr': {
      'counterfeit':
          '🚨 Les médicaments contrefaits sont très dangereux. Ils peuvent contenir des substances toxiques, une dose incorrecte ou aucun principe actif. Achetez toujours vos médicaments dans des pharmacies agréées et vérifiez l\'emballage avec VeryMed.',
      'scan_result':
          '✅ Voici ce que nous savons de ce médicament. Consultez les détails sur l\'écran de résultats. Si vous avez des doutes, consultez un pharmacien.',
      'pharmacy':
          '🏥 Utilisez l\'onglet "Pharmacies" pour trouver les officines agréées près de vous. Elles sont certifiées et proposent uniquement des médicaments authentiques.',
      'side_effects':
          '⚠️ Tout médicament peut avoir des effets indésirables. Les effets courants sont indiqués sur la notice. En cas de réaction grave, consultez immédiatement un médecin.',
      'expiration':
          '📅 Un médicament périmé perd son efficacité et peut devenir dangereux. Vérifiez toujours la date avant utilisation et déposez les périmés en pharmacie.',
      'default':
          'Je suis VeryMed, votre assistant pharmaceutique. Je peux vous aider à vérifier l\'authenticité des médicaments, expliquer les risques et vous guider vers les pharmacies proches. Que puis-je faire pour vous ?',
    },
    'ar': {
      'counterfeit':
          '🚨 الأدوية المزورة خطيرة جداً. قد تحتوي على مواد سامة أو جرعات خاطئة. اشترِ دائماً من صيدليات معتمدة وتحقق من الغلاف باستخدام دوايا.',
      'scan_result':
          '✅ هذا ما نعرفه عن هذا الدواء. راجع التفاصيل على شاشة النتائج. إذا كان لديك شك، استشر صيدلانياً.',
      'pharmacy':
          '🏥 استخدم تبويب الصيدليات للعثور على الصيدليات المعتمدة القريبة منك. تبيع فقط أدوية أصلية.',
      'side_effects':
          '⚠️ كل دواء قد يكون له آثار جانبية. راجع النشرة الداخلية. في حالة رد فعل خطير، اتصل بالطبيب فوراً.',
      'expiration':
          '📅 الدواء منتهي الصلاحية يفقد فاعليته وقد يصبح خطيراً. تحقق دائماً من التاريخ قبل الاستخدام.',
      'default':
          'أنا دوايا، مساعدك الصيدلاني. يمكنني مساعدتك في التحقق من أصالة الأدوية وتوجيهك للصيدليات القريبة.',
    },
    'tn': {
      'counterfeit':
          '🚨 الدواء المزور خطر برشا. يمكن يكون فيه حاجات سامة ولا جرعة غالطة. اشري دائماً من صيدلية موثوقة وتحقق بـ دوايا.',
      'scan_result':
          '✅ هاك المعلومات على هذا الدواء. شوف التفاصيل في النتائج. كان عندك شك، اسأل الصيدلي.',
      'pharmacy':
          '🏥 استعمل قسم الصيدليات باش تلقى الصيدليات القريبة منك. هي موثوقة وتبيع فقط أدوية أصلية.',
      'side_effects':
          '⚠️ كل دواء يمكن يعمل أعراض جانبية. اقرا الورقة الداخلية. كان صاب حاجة خطيرة، روح للطبيب.',
      'expiration':
          '📅 الدواء المنتهي صلاحيته ما يجيش. تحقق دائماً من التاريخ قبل ما تاخذه.',
      'default':
          'أنا دوايا، مساعدك في عالم الأدوية. نقدر نعاونك تتحقق من الأدوية وتلقى الصيدلية القريبة منك.',
    },
    'en': {
      'counterfeit':
          '🚨 Counterfeit medicines are very dangerous. They may contain toxic substances, incorrect doses, or no active ingredient. Always buy from licensed pharmacies and verify with VeryMed.',
      'scan_result':
          '✅ Here is what we know about this medicine. Check the results screen for details. If in doubt, consult a pharmacist.',
      'pharmacy':
          '🏥 Use the Pharmacies tab to find certified pharmacies near you. They only sell authentic medicines.',
      'side_effects':
          '⚠️ All medicines can have side effects. Common ones are listed in the package insert. For serious reactions, see a doctor immediately.',
      'expiration':
          '📅 Expired medicine loses effectiveness and can be dangerous. Always check the date before use and dispose of expired medicines at a pharmacy.',
      'default':
          'I am VeryMed, your pharmaceutical assistant. I can help you verify medicine authenticity, explain risks, and guide you to nearby pharmacies. How can I help?',
    },
  };
}
