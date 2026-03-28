import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'mindshift_models.dart';
import 'mindshift_reflection_store.dart';
import 'mindshift_theme.dart';

class PlanScreen extends StatelessWidget {
  const PlanScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context);
    final store = context.watch<ReflectionStore>();
    final plans = store.personalizedPlans;

    return SafeArea(
      child: CustomScrollView(
        slivers: [
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'My Plan',
                    style: TextStyle(fontSize: 28, fontWeight: FontWeight.w900),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Personalised based on your patterns',
                    style: TextStyle(
                      fontSize: 13,
                      color: t.colorScheme.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(height: 20),
                ],
              ),
            ),
          ),

          SliverPadding(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 40),
            sliver: SliverList(
              delegate: SliverChildListDelegate([
                ...plans.map((plan) => _PlanCard(plan: plan)),

                const SizedBox(height: 20),

                const _SectionTitle('CBT Techniques Library'),
                const SizedBox(height: 12),

                ..._techniques.map((tech) => _TechniqueCard(tech: tech)),
              ]),
            ),
          ),
        ],
      ),
    );
  }

  static const _techniques = [
    _Technique(
      'Thought Record',
      '📝',
      'Write down the situation, automatic thought, emotions, and evidence for/against.',
      kPurple,
    ),
    _Technique(
      'Behavioural Experiment',
      '🧪',
      'Test the accuracy of a belief by conducting a small real-world experiment.',
      kBlue,
    ),
    _Technique(
      'Decatastrophizing',
      '📉',
      'Ask: What is the worst/best/most likely outcome? Rate the probability.',
      kTeal,
    ),
    _Technique(
      '5-4-3-2-1 Grounding',
      '🌱',
      'Name 5 things you see, 4 you feel, 3 you hear, 2 you smell, 1 you taste.',
      kGreen,
    ),
    _Technique(
      'Mindful Observation',
      '👁️',
      'Observe thoughts without judgment. Label them: "I notice I\'m having the thought that…"',
      kIndigo,
    ),
    _Technique(
      'Cognitive Defusion',
      '🫧',
      'Separate yourself from thoughts. "My mind is telling me…" instead of "It\'s true that…"',
      kViolet,
    ),
  ];
}

class _PlanCard extends StatefulWidget {
  final PlanData plan;

  const _PlanCard({required this.plan});

  @override
  State<_PlanCard> createState() => _PlanCardState();
}

class _PlanCardState extends State<_PlanCard> {
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context);
    final plan = widget.plan;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: t.cardColor,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: plan.color.withOpacity(0.2)),
        boxShadow: [
          BoxShadow(
            color: plan.color.withOpacity(0.08),
            blurRadius: 8,
            offset: const Offset(0, 3),
          )
        ],
      ),
      child: Column(
        children: [
          InkWell(
            borderRadius: BorderRadius.circular(20),
            onTap: () => setState(() => _expanded = !_expanded),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: plan.color.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Center(
                      child: Text(
                        plan.icon,
                        style: const TextStyle(fontSize: 24),
                      ),
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          plan.title,
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w800,
                            color: plan.color,
                          ),
                        ),
                        const SizedBox(height: 3),
                        Text(
                          plan.description,
                          style: TextStyle(
                            fontSize: 12,
                            color: t.colorScheme.onSurfaceVariant,
                            height: 1.3,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                  Icon(
                    _expanded
                        ? Icons.keyboard_arrow_up_rounded
                        : Icons.keyboard_arrow_down_rounded,
                    color: t.colorScheme.onSurfaceVariant,
                  ),
                ],
              ),
            ),
          ),

          if (_expanded)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Divider(height: 1),
                  const SizedBox(height: 12),
                  const Text(
                    'Exercises',
                    style:
                    TextStyle(fontSize: 12, fontWeight: FontWeight.w700),
                  ),
                  const SizedBox(height: 8),
                  ...plan.exercises.map(
                        (e) => Padding(
                      padding: const EdgeInsets.only(bottom: 6),
                      child: Row(
                        children: [
                          Container(
                            width: 6,
                            height: 6,
                            decoration: BoxDecoration(
                              color: plan.color,
                              shape: BoxShape.circle,
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              e,
                              style: const TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

class _TechniqueCard extends StatelessWidget {
  final _Technique tech;

  const _TechniqueCard({required this.tech});

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context);

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: t.cardColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: t.colorScheme.outline.withOpacity(0.08),
        ),
      ),
      child: Row(
        children: [
          Text(tech.emoji, style: const TextStyle(fontSize: 22)),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  tech.name,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w800,
                    color: tech.color,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  tech.description,
                  style: TextStyle(
                    fontSize: 11,
                    color: t.colorScheme.onSurfaceVariant,
                    height: 1.3,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _Technique {
  final String name, emoji, description;
  final Color color;

  const _Technique(this.name, this.emoji, this.description, this.color);
}

class _SectionTitle extends StatelessWidget {
  final String text;

  const _SectionTitle(this.text);

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: TextStyle(
        fontSize: 16,
        fontWeight: FontWeight.w800,
        color: Theme.of(context).colorScheme.onSurface,
      ),
    );
  }
}