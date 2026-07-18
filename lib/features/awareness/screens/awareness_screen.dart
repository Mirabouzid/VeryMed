import 'package:flutter/material.dart';
import 'package:el_asli/core/theme/app_theme.dart';

class AwarenessScreen extends StatelessWidget {
  const AwarenessScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Centre de Sensibilisation'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // ── Bannière principale ───────────────────────────────────
          _HeroBanner(),
          const SizedBox(height: 16),

          // ── Statistiques choc ──────────────────────────────────────
          _StatsSection(),
          const SizedBox(height: 16),

          // ── Vidéos ────────────────────────────────────────────────
          Text('Vidéos de sensibilisation',
              style: Theme.of(context).textTheme.headlineSmall),
          const SizedBox(height: 12),
          ..._videos.map((v) => _VideoCard(video: v)),
          const SizedBox(height: 16),

          // ── Conseils pratiques ────────────────────────────────────
          Text('Conseils pratiques',
              style: Theme.of(context).textTheme.headlineSmall),
          const SizedBox(height: 12),
          ..._tips.map((t) => _TipCard(tip: t)),
          const SizedBox(height: 16),

          // ── Contacts urgence ──────────────────────────────────────
          _EmergencyContacts(),
          const SizedBox(height: 40),
        ],
      ),
    );
  }

  static final List<Map<String, dynamic>> _videos = [
    {
      'title': 'Les dangers des médicaments contrefaits',
      'subtitle': 'OMS — Organisation Mondiale de la Santé',
      'duration': '4:30',
      'thumbnail': Icons.play_circle_rounded,
      'color': AppTheme.dangerRed,
      'youtubeId': 'dQw4w9WgXcQ',
    },
    {
      'title': 'Comment identifier un médicament authentique',
      'subtitle': 'DPM Tunisie — Direction de la Pharmacie',
      'duration': '3:15',
      'thumbnail': Icons.play_circle_rounded,
      'color': AppTheme.primaryGreen,
      'youtubeId': '',
    },
    {
      'title': 'Les réseaux de contrefaçon en Tunisie',
      'subtitle': 'Ministère de la Santé — Campagne 2024',
      'duration': '6:45',
      'thumbnail': Icons.play_circle_rounded,
      'color': AppTheme.accentBlue,
      'youtubeId': '',
    },
  ];

  static final List<Map<String, dynamic>> _tips = [
    {
      'icon': Icons.store_rounded,
      'title': 'Achetez dans des pharmacies agréées',
      'description':
          'Les pharmacies officielles sont les seuls endroits sûrs pour acheter des médicaments en Tunisie. Méfiez-vous des vendeurs ambulants et des sites internet non certifiés.',
      'color': AppTheme.primaryGreen,
    },
    {
      'icon': Icons.qr_code_scanner_rounded,
      'title': 'Vérifiez toujours avec VeryMed',
      'description':
          'Avant de prendre un médicament, scannez son code-barres avec VeryMed. En cas de doute, ne le consommez pas.',
      'color': AppTheme.accentBlue,
    },
    {
      'icon': Icons.calendar_month_rounded,
      'title': 'Contrôlez la date d\'expiration',
      'description':
          'Un médicament périmé perd son efficacité et peut devenir toxique. Vérifiez systématiquement avant utilisation.',
      'color': AppTheme.warningOrange,
    },
    {
      'icon': Icons.visibility_rounded,
      'title': 'Inspectez l\'emballage',
      'description':
          'Vérifiez l\'intégrité du packaging, la qualité d\'impression, le numéro de lot et le numéro d\'enregistrement du médicament.',
      'color': const Color(0xFF9C27B0),
    },
    {
      'icon': Icons.report_rounded,
      'title': 'Signalez les contrefaçons',
      'description':
          'Si vous suspectez un médicament contrefait, signalez-le immédiatement à la DPM (Direction de la Pharmacie et du Médicament) au +216 71 570 900.',
      'color': AppTheme.dangerRed,
    },
    {
      'icon': Icons.medical_services_rounded,
      'title': 'Consultez un professionnel de santé',
      'description':
          'Ne vous auto-médicamentez jamais. Consultez toujours un médecin ou un pharmacien avant de prendre un traitement.',
      'color': const Color(0xFF00BCD4),
    },
  ];
}

class _HeroBanner extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      height: 150,
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF1A237E), Color(0xFF3949AB)],
        ),
        borderRadius: BorderRadius.circular(20),
      ),
      padding: const EdgeInsets.all(20),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Text(
                  'La santé n\'a pas de prix',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  'Les faux médicaments tuent chaque année. Informez-vous et protégez votre famille.',
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.85),
                    fontSize: 12,
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 16),
          const Icon(Icons.health_and_safety_rounded,
              color: Colors.white, size: 60),
        ],
      ),
    );
  }
}

class _StatsSection extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final stats = [
      ('100 000', 'Décès/an\nmondial', AppTheme.dangerRed),
      ('10%', 'Médicaments\ncontrefaits', AppTheme.warningOrange),
      ('1/3', 'En Afrique\nsubsaharienne', const Color(0xFF9C27B0)),
    ];

    return Row(
      children: stats.map((s) {
        return Expanded(
          child: Container(
            margin: const EdgeInsets.symmetric(horizontal: 4),
            padding: const EdgeInsets.symmetric(vertical: 14),
            decoration: BoxDecoration(
              color: s.$3.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: s.$3.withValues(alpha: 0.2)),
            ),
            child: Column(
              children: [
                Text(s.$1,
                    style: TextStyle(
                        color: s.$3,
                        fontSize: 20,
                        fontWeight: FontWeight.w700)),
                const SizedBox(height: 4),
                Text(s.$2,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                        fontSize: 10, height: 1.3)),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }
}

class _VideoCard extends StatelessWidget {
  final Map<String, dynamic> video;
  const _VideoCard({required this.video});

  @override
  Widget build(BuildContext context) {
    final color = video['color'] as Color;

    return GestureDetector(
      onTap: () {
        showDialog(
          context: context,
          builder: (_) => AlertDialog(
            title: Text(video['title'] as String),
            content: Text(
              'Vidéo : ${video['subtitle']}\nDurée : ${video['duration']}\n\nCette vidéo sera disponible dans la prochaine version connectée.',
            ),
            actions: [
              TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Fermer')),
            ],
          ),
        );
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        height: 90,
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: color.withValues(alpha: 0.2)),
        ),
        child: Row(
          children: [
            // Thumbnail
            Container(
              width: 100,
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.15),
                borderRadius: const BorderRadius.horizontal(
                    left: Radius.circular(14)),
              ),
              child: Stack(
                alignment: Alignment.center,
                children: [
                  Icon(Icons.play_circle_rounded, color: color, size: 40),
                  Positioned(
                    bottom: 8,
                    right: 8,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: color,
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        video['duration'] as String,
                        style: const TextStyle(
                            color: Colors.white,
                            fontSize: 9,
                            fontWeight: FontWeight.w700),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            // Infos
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      video['title'] as String,
                      style: const TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 13,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      video['subtitle'] as String,
                      style: const TextStyle(
                          fontSize: 11, color: Colors.grey),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.only(right: 12),
              child: Icon(Icons.arrow_forward_ios_rounded,
                  size: 14, color: Colors.grey),
            ),
          ],
        ),
      ),
    );
  }
}

class _TipCard extends StatelessWidget {
  final Map<String, dynamic> tip;
  const _TipCard({required this.tip});

  @override
  Widget build(BuildContext context) {
    final color = tip['color'] as Color;

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Theme.of(context).cardTheme.color,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: color.withValues(alpha: 0.2)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(tip['icon'] as IconData, color: color, size: 22),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(tip['title'] as String,
                    style: const TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 14)),
                const SizedBox(height: 4),
                Text(tip['description'] as String,
                    style: const TextStyle(
                        fontSize: 12,
                        height: 1.5,
                        color: Colors.grey)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _EmergencyContacts extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.dangerRed.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.dangerRed.withValues(alpha: 0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.emergency_rounded, color: AppTheme.dangerRed),
              SizedBox(width: 8),
              Text('Contacts d\'urgence — Tunisie',
                  style: TextStyle(
                      fontWeight: FontWeight.w700,
                      color: AppTheme.dangerRed,
                      fontSize: 15)),
            ],
          ),
          const SizedBox(height: 12),
          _ContactRow('DPM — Direction Pharmacie & Médicament',
              '+216 71 570 900'),
          _ContactRow('SAMU — Urgences médicales', '190'),
          _ContactRow('Centre Anti-Poison Tunisie', '+216 71 780 000'),
          _ContactRow('Ministère de la Santé', '+216 71 578 000'),
        ],
      ),
    );
  }
}

class _ContactRow extends StatelessWidget {
  final String name;
  final String phone;
  const _ContactRow(this.name, this.phone);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          const Icon(Icons.phone_rounded, size: 14, color: AppTheme.dangerRed),
          const SizedBox(width: 8),
          Expanded(
            child: Text(name,
                style: const TextStyle(fontSize: 12)),
          ),
          Text(phone,
              style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: AppTheme.dangerRed)),
        ],
      ),
    );
  }
}
