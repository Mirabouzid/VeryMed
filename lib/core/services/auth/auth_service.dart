// ═══════════════════════════════════════════════════════════════════
//  auth_service.dart — El Asliفيري ميد
//
//  Authentification temps réel via backend Node.js + MongoDB Atlas
//  Fallback : SharedPreferences local si serveur indisponible
//
//  Architecture :
//    Flutter → HTTP → Backend Node.js (192.168.1.5:3000)
//                          ↓
//                    MongoDB Atlas (temps réel)
// ═══════════════════════════════════════════════════════════════════

import 'dart:convert';
import 'package:crypto/crypto.dart';
import 'package:dio/dio.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';

// ── Modèle utilisateur ───────────────────────────────────────────────
class AuthUser {
  final String id;
  final String email;
  final String fullName;
  final String? firstName;
  final String? lastName;
  final String? phone;
  final String language;
  final bool isVerified;
  final bool isGuest;
  final int totalScans;
  final int totalReports;

  const AuthUser({
    required this.id,
    required this.email,
    required this.fullName,
    this.firstName,
    this.lastName,
    this.phone,
    this.language = 'fr',
    this.isVerified = false,
    this.isGuest = false,
    this.totalScans = 0,
    this.totalReports = 0,
  });

  factory AuthUser.fromMap(Map<String, dynamic> m) => AuthUser(
    id: m['_id']?.toString() ?? m['id']?.toString() ?? '',
    email: m['email']?.toString() ?? '',
    fullName: m['fullName']?.toString() ?? '',
    firstName: m['firstName']?.toString(),
    lastName: m['lastName']?.toString(),
    phone: m['phone']?.toString(),
    language: m['language']?.toString() ?? 'fr',
    isVerified: m['isVerified'] as bool? ?? false,
    isGuest: m['isGuest'] as bool? ?? false,
    totalScans: (m['totalScans'] as num?)?.toInt() ?? 0,
    totalReports: (m['totalReports'] as num?)?.toInt() ?? 0,
  );

  Map<String, dynamic> toMap() => {
    '_id': id, 'email': email, 'fullName': fullName,
    'firstName': firstName, 'lastName': lastName,
    'phone': phone, 'language': language,
    'isVerified': isVerified, 'isGuest': isGuest,
    'totalScans': totalScans, 'totalReports': totalReports,
  };

  AuthUser copyWith({
    String? fullName, String? firstName, String? lastName,
    String? phone, String? language, bool? isVerified,
    int? totalScans, int? totalReports,
  }) => AuthUser(
    id: id, email: email,
    fullName: fullName ?? this.fullName,
    firstName: firstName ?? this.firstName,
    lastName: lastName ?? this.lastName,
    phone: phone ?? this.phone,
    language: language ?? this.language,
    isVerified: isVerified ?? this.isVerified,
    isGuest: isGuest,
    totalScans: totalScans ?? this.totalScans,
    totalReports: totalReports ?? this.totalReports,
  );
}

// ── Résultat opération ───────────────────────────────────────────────
class AuthResult {
  final bool success;
  final String? error;
  final AuthUser? user;
  const AuthResult({required this.success, this.error, this.user});
}

// ── Service principal ────────────────────────────────────────────────
class AuthService {
  static final AuthService _i = AuthService._();
  factory AuthService() => _i;

  AuthService._() {
    _dio = Dio(BaseOptions(
      baseUrl: _baseUrl,
      connectTimeout: const Duration(seconds: 8),
      receiveTimeout: const Duration(seconds: 8),
      headers: {
        'Content-Type': 'application/json',
        'x-api-key': _apiKey,
      },
    ));
  }

  // ── Configuration serveur ──────────────────────────────────────
  // 🔴 IMPORTANT : Choisir selon le contexte :
  //
  // Option 1 — Render.com (production, recommandé) :
  //   static const String _baseUrl = 'https://el-asli-backend.onrender.com';
  //
  // Option 2 — PC local WiFi (Redmi sur même réseau) :
  //   static const String _baseUrl = 'http://192.168.1.5:3000';
  //
  // Option 3 — Émulateur Android (localhost du PC) :
  //   static const String _baseUrl = 'http://10.0.2.2:3000';
  //
  // Actuellement : IP WiFi locale pour tests Redmi
  static const String _baseUrl = 'http://192.168.1.5:3000';
  static const String _apiKey  = 'el_asli_hackathon_2026_key';
  static const String _salt    = 'el_asli_2026_sec';

  late final Dio _dio;
  final _uuid = const Uuid();
  AuthUser? _currentUser;
  AuthUser? get currentUser => _currentUser;

  // ── Hash local (même sel que le serveur) ──────────────────────
  String _hash(String password) {
    final bytes = utf8.encode(password + _salt);
    return sha256.convert(bytes).toString();
  }

  // ── Test connexion serveur ────────────────────────────────────
  Future<bool> isServerAvailable() async {
    try {
      final resp = await _dio.get('/health')
          .timeout(const Duration(seconds: 3));
      return resp.statusCode == 200;
    } catch (_) {
      return false;
    }
  }

  // ═══════════════════════════════════════════════════════════════
  //  INSCRIPTION — stocke dans MongoDB Atlas via backend
  // ═══════════════════════════════════════════════════════════════
  Future<AuthResult> register({
    required String email,
    required String password,
    required String fullName,
    String? firstName,
    String? lastName,
    String? phone,
    String language = 'fr',
  }) async {
    // Validation locale rapide
    if (!_isValidEmail(email)) {
      return const AuthResult(success: false, error: 'Adresse email invalide');
    }
    if (password.length < 6) {
      return const AuthResult(
          success: false, error: 'Mot de passe trop court (min 6 caractères)');
    }
    if (fullName.trim().isEmpty) {
      return const AuthResult(
          success: false, error: 'Le nom complet est requis');
    }

    final serverOk = await isServerAvailable();
    if (serverOk) {
      return _registerOnline(
        email: email, password: password, fullName: fullName,
        firstName: firstName, lastName: lastName,
        phone: phone, language: language,
      );
    } else {
      // Fallback local si serveur hors ligne
      return _registerOffline(
        email: email, password: password, fullName: fullName,
        firstName: firstName, lastName: lastName,
        phone: phone, language: language,
      );
    }
  }

  // ── Inscription en ligne (MongoDB Atlas) ──────────────────────
  Future<AuthResult> _registerOnline({
    required String email, required String password,
    required String fullName, String? firstName, String? lastName,
    String? phone, String language = 'fr',
  }) async {
    try {
      final resp = await _dio.post('/auth/register', data: {
        'email': email.toLowerCase().trim(),
        'password': password, // Le serveur hash lui-même
        'fullName': fullName.trim(),
        'firstName': firstName?.trim(),
        'lastName': lastName?.trim(),
        'phone': phone?.trim(),
        'language': language,
      });

      final data = resp.data as Map<String, dynamic>;
      if (data['success'] == true) {
        final user = AuthUser.fromMap(data['user'] as Map<String, dynamic>);
        await _saveSession(user);
        _currentUser = user;
        return AuthResult(success: true, user: user);
      }
      return AuthResult(success: false,
          error: data['error']?.toString() ?? 'Erreur inconnue');
    } on DioException catch (e) {
      final msg = (e.response?.data as Map?)?['error']?.toString()
          ?? e.message ?? 'Erreur réseau';
      return AuthResult(success: false, error: msg);
    }
  }

  // ── Inscription hors ligne (fallback) ─────────────────────────
  Future<AuthResult> _registerOffline({
    required String email, required String password,
    required String fullName, String? firstName, String? lastName,
    String? phone, String language = 'fr',
  }) async {
    await Future.delayed(const Duration(milliseconds: 400));
    final prefs = await SharedPreferences.getInstance();
    final key   = 'user_${email.toLowerCase().trim()}';

    if (prefs.containsKey(key)) {
      return const AuthResult(
          success: false, error: 'Cet email est déjà utilisé');
    }

    final user = AuthUser(
      id: _uuid.v4(),
      email: email.toLowerCase().trim(),
      fullName: fullName.trim(),
      firstName: firstName?.trim(),
      lastName: lastName?.trim(),
      phone: phone?.trim(),
      language: language,
      isVerified: false,
    );

    await prefs.setString(key, jsonEncode({
      ...user.toMap(),
      'password': _hash(password),
      'offline': true,
    }));
    await _saveSession(user);
    _currentUser = user;
    return AuthResult(success: true, user: user);
  }

  // ═══════════════════════════════════════════════════════════════
  //  CONNEXION — vérifie via backend MongoDB
  // ═══════════════════════════════════════════════════════════════
  Future<AuthResult> login({
    required String email,
    required String password,
  }) async {
    final serverOk = await isServerAvailable();
    if (serverOk) {
      return _loginOnline(email: email, password: password);
    } else {
      return _loginOffline(email: email, password: password);
    }
  }

  Future<AuthResult> _loginOnline({
    required String email, required String password,
  }) async {
    try {
      final resp = await _dio.post('/auth/login', data: {
        'email': email.toLowerCase().trim(),
        'password': password,
      });
      final data = resp.data as Map<String, dynamic>;
      if (data['success'] == true) {
        final user = AuthUser.fromMap(data['user'] as Map<String, dynamic>);
        await _saveSession(user);
        _currentUser = user;
        return AuthResult(success: true, user: user);
      }
      return AuthResult(success: false,
          error: data['error']?.toString() ?? 'Erreur inconnue');
    } on DioException catch (e) {
      final msg = (e.response?.data as Map?)?['error']?.toString()
          ?? e.message ?? 'Erreur réseau';
      return AuthResult(success: false, error: msg);
    }
  }

  Future<AuthResult> _loginOffline({
    required String email, required String password,
  }) async {
    await Future.delayed(const Duration(milliseconds: 400));
    final prefs = await SharedPreferences.getInstance();

    // Compte démo intégré
    if (email.trim().toLowerCase() == 'demo@elasli.tn' &&
        password == 'Demo1234!') {
      final user = AuthUser(
        id: 'demo-001', email: 'demo@elasli.tn',
        fullName: 'Compte Démo',
        language: 'fr', isVerified: true,
      );
      await _saveSession(user);
      _currentUser = user;
      return AuthResult(success: true, user: user);
    }

    final stored = prefs.getString('user_${email.toLowerCase().trim()}');
    if (stored == null) {
      return const AuthResult(
          success: false,
          error: 'Email ou mot de passe incorrect\n(Mode hors-ligne)');
    }
    final map = jsonDecode(stored) as Map<String, dynamic>;
    if (map['password'] != _hash(password)) {
      return const AuthResult(
          success: false, error: 'Email ou mot de passe incorrect');
    }
    final user = AuthUser.fromMap(map);
    await _saveSession(user);
    _currentUser = user;
    return AuthResult(success: true, user: user);
  }

  // ═══════════════════════════════════════════════════════════════
  //  INVITÉ — sans inscription
  // ═══════════════════════════════════════════════════════════════
  Future<AuthResult> loginAsGuest() async {
    final user = AuthUser(
      id: 'guest_${_uuid.v4().substring(0, 8)}',
      email: 'invité@elasli.tn',
      fullName: 'Invité',
      language: 'fr',
      isGuest: true,
    );
    _currentUser = user;
    // PAS de sauvegarde session pour invité
    return AuthResult(success: true, user: user);
  }

  // ═══════════════════════════════════════════════════════════════
  //  MOT DE PASSE OUBLIÉ
  // ═══════════════════════════════════════════════════════════════
  Future<AuthResult> sendPasswordReset(String email) async {
    final serverOk = await isServerAvailable();
    if (!serverOk) {
      return const AuthResult(
          success: false,
          error: 'Serveur indisponible. Vérifiez votre connexion WiFi.');
    }
    try {
      final resp = await _dio.post('/auth/forgot-password',
          data: {'email': email.toLowerCase().trim()});
      final data = resp.data as Map<String, dynamic>;
      final otp  = data['otpDemo']?.toString();
      return AuthResult(
        success: true,
        error: otp != null ? 'OTP_CODE:$otp' : null,
      );
    } on DioException catch (e) {
      return AuthResult(success: false, error: e.message);
    }
  }

  Future<AuthResult> resetPasswordWithOtp({
    required String email,
    required String otp,
    required String newPassword,
  }) async {
    if (newPassword.length < 6) {
      return const AuthResult(
          success: false, error: 'Mot de passe trop court');
    }
    try {
      final resp = await _dio.post('/auth/reset-password', data: {
        'email': email.toLowerCase().trim(),
        'otp': otp,
        'newPassword': newPassword,
      });
      final data = resp.data as Map<String, dynamic>;
      return AuthResult(success: data['success'] == true,
          error: data['error']?.toString());
    } on DioException catch (e) {
      final msg = (e.response?.data as Map?)?['error']?.toString()
          ?? e.message ?? 'Erreur réseau';
      return AuthResult(success: false, error: msg);
    }
  }

  // ═══════════════════════════════════════════════════════════════
  //  INCRÉMENTER COMPTEUR SCANS (temps réel)
  // ═══════════════════════════════════════════════════════════════
  Future<void> incrementScans() async {
    if (_currentUser == null || _currentUser!.isGuest) return;
    try {
      await _dio.post('/auth/scan/${_currentUser!.id}');
    } catch (_) {}
  }

  // ═══════════════════════════════════════════════════════════════
  //  SESSION
  // ═══════════════════════════════════════════════════════════════
  Future<void> logout() async {
    _currentUser = null;
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('auth_session');
  }

  Future<AuthUser?> restoreSession() async {
    final prefs = await SharedPreferences.getInstance();
    final json  = prefs.getString('auth_session');
    if (json == null) return null;
    try {
      final map  = jsonDecode(json) as Map<String, dynamic>;
      final user = AuthUser.fromMap(map);
      if (user.isGuest) return null;
      if (user.email.contains('invité')) return null;
      _currentUser = user;
      return user;
    } catch (_) {
      await prefs.remove('auth_session');
      return null;
    }
  }

  Future<void> _saveSession(AuthUser user) async {
    if (user.isGuest) return;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('auth_session', jsonEncode(user.toMap()));
  }

  bool _isValidEmail(String email) =>
      RegExp(r'^[\w\.-]+@[\w\.-]+\.\w{2,}$').hasMatch(email.trim());
}
