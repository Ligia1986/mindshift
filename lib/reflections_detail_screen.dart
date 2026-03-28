import 'mindshift_models.dart';
import 'mindshift_reflection_store.dart';
import 'mindshift_theme.dart';
import 'mindshift_ai_service.dart';

class ReflectionDetailScreen extends StatelessWidget {
  final ReflectionEntry entry;
  const ReflectionDetailScreen({super.key, required this.entry});

  @override
  Widget build(BuildContext context) {
    final t   = Theme.of(context);
    final fmt = '${entry.createdAt.day}/${entry.createdAt.month}/${entry.createdAt.year}';

    return Scaffold(
      backgroundColor: t.scaffoldBackgroundColor,
      body: SafeArea(child: CustomScrollView(slivers: [
        SliverToBoxAdapter(child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
          child: Row(children: [
            GestureDetector(
              onTap: () => Navigator.pop(context),
              child: Container(width: 40, height: 40,
                  decoration: BoxDecoration(shape: BoxShape.circle,
                      color: t.colorScheme.surfaceContainerHighest.withOpacity(0.6)),
                  child: Icon(Icons.arrow_back_rounded, size: 20, color: t.colorScheme.onSurface)),
            ),
            const SizedBox(width: 14),
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text('Reflection', style: TextStyle(fontSize: 20,
                  fontWeight: FontWeight.w900, color: t.colorScheme.onSurface)),
              Text(fmt, style: TextStyle(fontSize: 12, color: t.colorScheme.onSurfaceVariant)),
            ])),
            // Delete
            GestureDetector(
              onTap: () => _confirmDelete(context),
              child: Container(width: 40, height: 40,
                  decoration: BoxDecoration(shape: BoxShape.circle,
                      color: kRose.withOpacity(0.1)),
                  child: const Icon(Icons.delete_outline_rounded, size: 18, color: kRose)),
            ),
          ]),
        )),

        SliverPadding(
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 40),
          sliver: SliverList(delegate: SliverChildListDelegate([

            _Section('🎯 Situation', [
              _InfoRow('What happened', entry.whatHappened),
              if (entry.where.isNotEmpty) _InfoRow('Where', entry.where),
              if (entry.withWhom.isNotEmpty) _InfoRow('With whom', entry.withWhom),
            ]),
            const SizedBox(height: 16),

            _Section('💭 Automatic Thought', [
              _InfoRow('Thought', entry.automaticThought),
            ]),
            const SizedBox(height: 16),

            if (entry.detectedDistortions.isNotEmpty) ...[
              _Section('🔍 Distortions', [
                Wrap(spacing: 8, runSpacing: 6,
                  children: entry.detectedDistortions.map((d) =>
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                        decoration: BoxDecoration(color: kRose.withOpacity(0.08),
                            borderRadius: BorderRadius.circular(999),
                            border: Border.all(color: kRose.withOpacity(0.2))),
                        child: Text('${d.emoji} ${d.label}',
                            style: const TextStyle(fontSize: 11,
                                fontWeight: FontWeight.w600, color: kRose)),
                      )).toList(),
                ),
              ]),
              const SizedBox(height: 16),
            ],

            if (entry.emotions.isNotEmpty) ...[
              _Section('❤️ Emotions', [
                Wrap(spacing: 8, runSpacing: 6,
                  children: entry.emotions.map((e) =>
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                        decoration: BoxDecoration(
                          gradient: kGradientCool,
                          borderRadius: BorderRadius.circular(999),
                        ),
                        child: Text('${e.emotion.emoji} ${e.emotion.label} ${e.intensity}/10',
                            style: const TextStyle(fontSize: 11,
                                fontWeight: FontWeight.w700, color: Colors.white)),
                      )).toList(),
                ),
              ]),
              const SizedBox(height: 16),
            ],

            if (entry.aiAnalysis != null) ...[
              _Section('💡 AI Insight', [
                _InfoRow('Emotional validation', entry.aiAnalysis!.emotionalValidation),
                const SizedBox(height: 8),
                _InfoRow('Alternative thought', entry.aiAnalysis!.alternativeThought),
                const SizedBox(height: 8),
                _InfoRow('Reframing', entry.aiAnalysis!.reframingSuggestion),
              ]),
            ],
          ])),
        ),
      ])),
    );
  }

  void _confirmDelete(BuildContext context) {
    showDialog(context: context, builder: (_) => AlertDialog(
      title: const Text('Delete Reflection'),
      content: const Text('This reflection will be permanently deleted.'),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
        TextButton(
          onPressed: () {
            context.read<ReflectionStore>().delete(entry.id);
            Navigator.pop(context);
            Navigator.pop(context);
          },
          child: const Text('Delete', style: TextStyle(color: kRose)),
        ),
      ],
    ));
  }
}

class _Section extends StatelessWidget {
  final String title;
  final List<Widget> children;
  const _Section(this.title, this.children);
  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context);
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: t.cardColor, borderRadius: BorderRadius.circular(18),
        border: Border.all(color: t.colorScheme.outline.withOpacity(0.08)),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(title, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w800)),
        const SizedBox(height: 12),
        ...children,
      ]),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final String label, value;
  const _InfoRow(this.label, this.value);
  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context);
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text(label, style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600,
          color: t.colorScheme.onSurfaceVariant)),
      const SizedBox(height: 3),
      Text(value, style: TextStyle(fontSize: 13, color: t.colorScheme.onSurface, height: 1.4)),
    ]);
  }
}