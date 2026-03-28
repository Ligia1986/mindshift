import 'mindshift_models.dart';
import 'mindshift_reflection_store.dart';
import 'mindshift_theme.dart';
import 'mindshift_ai_service.dart';

class InsightsScreen extends StatelessWidget {
  const InsightsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final t     = Theme.of(context);
    final store = context.watch<ReflectionStore>();
    final emotions    = store.emotionFrequency;
    final distortions = store.distortionFrequency;

    return SafeArea(
      child: CustomScrollView(slivers: [
        SliverToBoxAdapter(child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            const Text('Insights', style: TextStyle(fontSize: 28, fontWeight: FontWeight.w900)),
            const SizedBox(height: 4),
            Text('Patterns from your reflections',
                style: TextStyle(fontSize: 13, color: t.colorScheme.onSurfaceVariant)),
          ]),
        )),

        if (store.completed.isEmpty)
          SliverFillRemaining(child: Center(child: Padding(
            padding: const EdgeInsets.all(40),
            child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
              const Text('📊', style: TextStyle(fontSize: 64)),
              const SizedBox(height: 16),
              const Text('No insights yet', style: TextStyle(
                  fontSize: 20, fontWeight: FontWeight.w900)),
              const SizedBox(height: 8),
              Text('Complete reflections to see your emotional patterns here.',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.grey[600], fontSize: 14)),
            ]),
          )))
        else
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 40),
            sliver: SliverList(delegate: SliverChildListDelegate([

              // Summary cards
              Row(children: [
                _InsightCard(icon: '📔', label: 'Total', value: '${store.completed.length}',
                    color: kPurple),
                const SizedBox(width: 12),
                _InsightCard(icon: '🔥', label: 'Streak', value: '${store.currentStreak}d',
                    color: kRose),
                const SizedBox(width: 12),
                _InsightCard(icon: '📅', label: 'This week', value: '${store.thisWeek.length}',
                    color: kBlue),
              ]),
              const SizedBox(height: 24),

              // Top emotions
              if (emotions.isNotEmpty) ...[
                const _SectionTitle('Most frequent emotions'),
                const SizedBox(height: 12),
                ...(_topEntries(emotions, 5).map((e) =>
                    _FrequencyBar(
                      label: '${e.key.emoji} ${e.key.label}',
                      count: e.value,
                      max: emotions.values.reduce((a, b) => a > b ? a : b),
                      color: e.key.isNegative ? kRose : kGreen,
                    ))),
                const SizedBox(height: 24),
              ],

              // Top distortions
              if (distortions.isNotEmpty) ...[
                const _SectionTitle('Most common patterns'),
                const SizedBox(height: 12),
                ...(_topEntries(distortions, 5).map((e) =>
                    _FrequencyBar(
                      label: '${e.key.emoji} ${e.key.label}',
                      count: e.value,
                      max: distortions.values.reduce((a, b) => a > b ? a : b),
                      color: kPurple,
                    ))),
                const SizedBox(height: 24),
              ],

              // Recommendation
              Container(
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  gradient: kGradientPrimary,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [BoxShadow(color: kPurple.withOpacity(0.3),
                      blurRadius: 16, offset: const Offset(0, 6))],
                ),
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  const Row(children: [
                    Icon(Icons.lightbulb_rounded, color: Colors.white, size: 18),
                    SizedBox(width: 8),
                    Text('Recommendation', style: TextStyle(
                        color: Colors.white70, fontSize: 12, fontWeight: FontWeight.w600)),
                  ]),
                  const SizedBox(height: 8),
                  Text(store.topRecommendation, style: const TextStyle(
                      color: Colors.white, fontSize: 14, height: 1.5,
                      fontWeight: FontWeight.w600)),
                ]),
              ),
            ])),
          ),
      ]),
    );
  }

  List<MapEntry<K, int>> _topEntries<K>(Map<K, int> map, int n) {
    final sorted = map.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    return sorted.take(n).toList();
  }
}

class _InsightCard extends StatelessWidget {
  final String icon, label, value;
  final Color color;
  const _InsightCard({required this.icon, required this.label,
    required this.value, required this.color});
  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context);
    return Expanded(child: Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: t.cardColor, borderRadius: BorderRadius.circular(16),
        border: Border.all(color: t.colorScheme.outline.withOpacity(0.08)),
      ),
      child: Column(children: [
        Text(icon, style: const TextStyle(fontSize: 22)),
        const SizedBox(height: 4),
        Text(value, style: TextStyle(fontSize: 20, fontWeight: FontWeight.w900, color: color)),
        Text(label, style: TextStyle(fontSize: 10, color: t.colorScheme.onSurfaceVariant)),
      ]),
    ));
  }
}

class _SectionTitle extends StatelessWidget {
  final String text;
  const _SectionTitle(this.text);
  @override
  Widget build(BuildContext c) => Text(text,
      style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800,
          color: Theme.of(c).colorScheme.onSurface));
}

class _FrequencyBar extends StatelessWidget {
  final String label;
  final int count, max;
  final Color color;
  const _FrequencyBar({required this.label, required this.count,
    required this.max, required this.color});
  @override
  Widget build(BuildContext context) {
    final t   = Theme.of(context);
    final pct = max > 0 ? count / max : 0.0;
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(children: [
        SizedBox(width: 150,
            child: Text(label, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
                maxLines: 1, overflow: TextOverflow.ellipsis)),
        const SizedBox(width: 8),
        Expanded(child: Stack(children: [
          Container(height: 8, decoration: BoxDecoration(
            color: t.colorScheme.outline.withOpacity(0.1),
            borderRadius: BorderRadius.circular(4),
          )),
          FractionallySizedBox(widthFactor: pct,
              child: Container(height: 8, decoration: BoxDecoration(
                color: color, borderRadius: BorderRadius.circular(4),
              ))),
        ])),
        const SizedBox(width: 8),
        SizedBox(width: 24, child: Text('$count',
            style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700,
                color: t.colorScheme.onSurfaceVariant))),
      ]),
    );
  }
}