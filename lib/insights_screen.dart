import 'mindshift_models.dart';
import 'mindshift_reflection_store.dart';
import 'mindshift_theme.dart';
import 'mindshift_ai_service.dart';

// ─────────────────────────────────────────────────────────────────────────────
// ABCFlowScreen — 4-step guided reflection
// A: Stimulus → B: Thoughts → C: Consequences → AI Analysis
// ─────────────────────────────────────────────────────────────────────────────

class ABCFlowScreen extends StatefulWidget {
  const ABCFlowScreen({super.key});

  @override
  State<ABCFlowScreen> createState() => _ABCFlowScreenState();
}

class _ABCFlowScreenState extends State<ABCFlowScreen> {
  final _pageCtrl = PageController();
  int _step = 0; // 0=A, 1=B, 2=C, 3=AI

  // A — Stimulus
  final _whatCtrl   = TextEditingController();
  final _whereCtrl  = TextEditingController();
  final _withWhomCtrl = TextEditingController();

  // B — Thoughts
  final _thoughtCtrl = TextEditingController();

  // C — Consequences
  final _selectedEmotions   = <EmotionEntry>[];
  final _selectedBehaviours = <BehaviourResponse>{};

  // AI
  bool        _loading   = false;
  AIAnalysis? _analysis;
  String?     _error;

  @override
  void dispose() {
    _pageCtrl.dispose();
    _whatCtrl.dispose();
    _whereCtrl.dispose();
    _withWhomCtrl.dispose();
    _thoughtCtrl.dispose();
    super.dispose();
  }

  void _next() {
    if (_step == 0 && _whatCtrl.text.trim().isEmpty) {
      _snack('Please describe what happened.');
      return;
    }
    if (_step == 1 && _thoughtCtrl.text.trim().isEmpty) {
      _snack('Please write your automatic thought.');
      return;
    }
    if (_step == 2 && _selectedEmotions.isEmpty) {
      _snack('Select at least one emotion.');
      return;
    }
    if (_step == 2) { _runAI(); return; }

    setState(() => _step++);
    _pageCtrl.animateToPage(_step,
        duration: const Duration(milliseconds: 350), curve: Curves.easeInOut);
  }

  Future<void> _runAI() async {
    setState(() { _loading = true; _step = 3; });
    _pageCtrl.animateToPage(3,
        duration: const Duration(milliseconds: 350), curve: Curves.easeInOut);

    try {
      final analysis = await MindShiftAIService.instance.analyse(
        whatHappened:   _whatCtrl.text.trim(),
        automaticThought: _thoughtCtrl.text.trim(),
        emotions:       _selectedEmotions,
        behaviours:     _selectedBehaviours.toList(),
      );
      if (mounted) setState(() { _analysis = analysis; _loading = false; });
    } catch (e) {
      if (mounted) setState(() { _error = e.toString(); _loading = false; });
    }
  }

  Future<void> _save() async {
    final entry = ReflectionEntry(
      id:               DateTime.now().millisecondsSinceEpoch.toString(),
      createdAt:        DateTime.now(),
      whatHappened:     _whatCtrl.text.trim(),
      where:            _whereCtrl.text.trim(),
      withWhom:         _withWhomCtrl.text.trim(),
      automaticThought: _thoughtCtrl.text.trim(),
      detectedDistortions: _analysis?.distortions ?? [],
      emotions:         _selectedEmotions,
      behaviours:       _selectedBehaviours.toList(),
      aiAnalysis:       _analysis,
      completed:        _analysis != null,
    );

    await context.read<ReflectionStore>().add(entry);
    if (mounted) Navigator.pop(context);
  }

  void _snack(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(msg), behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 2)));
  }

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context);

    final steps = ['Situation', 'Thoughts', 'Emotions', 'Insight'];
    final colors = [kIndigo, kPurple, kTeal, kGreen];

    return Scaffold(
      backgroundColor: t.scaffoldBackgroundColor,
      body: SafeArea(
        child: Column(children: [

          // Header + progress
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
            child: Column(children: [
              Row(children: [
                GestureDetector(
                  onTap: () => Navigator.pop(context),
                  child: Container(
                    width: 40, height: 40,
                    decoration: BoxDecoration(shape: BoxShape.circle,
                        color: t.colorScheme.surfaceContainerHighest.withOpacity(0.6)),
                    child: Icon(Icons.close_rounded, size: 20,
                        color: t.colorScheme.onSurface),
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text('Step ${_step + 1} of 4',
                      style: TextStyle(fontSize: 12, color: t.colorScheme.onSurfaceVariant)),
                  Text(steps[_step], style: TextStyle(fontSize: 20,
                      fontWeight: FontWeight.w900, color: colors[_step])),
                ])),
              ]),
              const SizedBox(height: 16),
              // Progress bar
              Row(children: List.generate(4, (i) => Expanded(
                child: Container(
                  margin: EdgeInsets.only(right: i < 3 ? 4 : 0),
                  height: 4,
                  decoration: BoxDecoration(
                    color: i <= _step ? colors[i] : t.colorScheme.outline.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ))),
            ]),
          ),

          // Pages
          Expanded(child: PageView(
            controller: _pageCtrl,
            physics: const NeverScrollableScrollPhysics(),
            children: [
              _StepA(whatCtrl: _whatCtrl, whereCtrl: _whereCtrl,
                  withWhomCtrl: _withWhomCtrl),
              _StepB(thoughtCtrl: _thoughtCtrl),
              _StepC(
                selectedEmotions:   _selectedEmotions,
                selectedBehaviours: _selectedBehaviours,
                onChanged: () => setState(() {}),
              ),
              _StepAI(loading: _loading, analysis: _analysis, error: _error,
                  onSave: _save, onRetry: _runAI),
            ],
          )),

          // Bottom button
          if (_step < 3)
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
              child: SizedBox(
                width: double.infinity,
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                        colors: [colors[_step], colors[_step].withOpacity(0.7)]),
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [BoxShadow(color: colors[_step].withOpacity(0.3),
                        blurRadius: 12, offset: const Offset(0, 5))],
                  ),
                  child: ElevatedButton(
                    onPressed: _next,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.transparent, shadowColor: Colors.transparent,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    ),
                    child: Text(
                      _step == 2 ? '✨ Analyse with AI' : 'Continue',
                      style: const TextStyle(color: Colors.white,
                          fontWeight: FontWeight.w800, fontSize: 16),
                    ),
                  ),
                ),
              ),
            ),
        ]),
      ),
    );
  }
}

// ── Step A — Stimulus ─────────────────────────────────────────────────────────

class _StepA extends StatelessWidget {
  final TextEditingController whatCtrl, whereCtrl, withWhomCtrl;
  const _StepA({required this.whatCtrl, required this.whereCtrl,
    required this.withWhomCtrl});

  @override
  Widget build(BuildContext context) {
    return ListView(padding: const EdgeInsets.fromLTRB(20, 20, 20, 0), children: [
      const _StepBanner(emoji: '🎯', title: 'Activating Event',
          subtitle: 'What triggered this?', color: kIndigo),
      const SizedBox(height: 24),
      _Question(ctrl: whatCtrl, question: 'What happened?',
          hint: 'Describe the situation as objectively as possible…', maxLines: 4),
      const SizedBox(height: 16),
      _Question(ctrl: whereCtrl, question: 'Where were you?',
          hint: 'At home, work, on the phone…'),
      const SizedBox(height: 16),
      _Question(ctrl: withWhomCtrl, question: 'Who was involved?',
          hint: 'Alone, with partner, colleague, family…'),
    ]);
  }
}

// ── Step B — Thoughts ─────────────────────────────────────────────────────────

class _StepB extends StatelessWidget {
  final TextEditingController thoughtCtrl;
  const _StepB({required this.thoughtCtrl});

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context);
    return ListView(padding: const EdgeInsets.fromLTRB(20, 20, 20, 0), children: [
      const _StepBanner(emoji: '💭', title: 'Automatic Thought',
          subtitle: 'What went through your mind?', color: kPurple),
      const SizedBox(height: 24),
      _Question(ctrl: thoughtCtrl,
          question: 'What thought crossed your mind?',
          hint: '"I always mess things up", "They must hate me", "This is terrible"…',
          maxLines: 5),
      const SizedBox(height: 20),
      Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: kPurple.withOpacity(0.06),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: kPurple.withOpacity(0.15)),
        ),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          const Row(children: [
            Icon(Icons.auto_awesome_rounded, color: kPurple, size: 16),
            SizedBox(width: 6),
            Text('AI will analyse this thought',
                style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: kPurple)),
          ]),
          const SizedBox(height: 6),
          Text('Our AI will identify cognitive distortions and help you reframe this thought.',
              style: TextStyle(fontSize: 12, color: t.colorScheme.onSurfaceVariant)),
        ]),
      ),
    ]);
  }
}

// ── Step C — Consequences ─────────────────────────────────────────────────────

class _StepC extends StatefulWidget {
  final List<EmotionEntry>        selectedEmotions;
  final Set<BehaviourResponse>    selectedBehaviours;
  final VoidCallback              onChanged;
  const _StepC({required this.selectedEmotions,
    required this.selectedBehaviours, required this.onChanged});

  @override
  State<_StepC> createState() => _StepCState();
}

class _StepCState extends State<_StepC> {
  Emotion? _pickedEmotion;
  double   _intensity = 5;

  void _addEmotion() {
    if (_pickedEmotion == null) return;
    final existing = widget.selectedEmotions
        .indexWhere((e) => e.emotion == _pickedEmotion);
    if (existing != -1) widget.selectedEmotions.removeAt(existing);
    widget.selectedEmotions.add(
        EmotionEntry(emotion: _pickedEmotion!, intensity: _intensity.round()));
    setState(() { _pickedEmotion = null; _intensity = 5; });
    widget.onChanged();
  }

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context);
    return ListView(padding: const EdgeInsets.fromLTRB(20, 20, 20, 0), children: [
      const _StepBanner(emoji: '❤️', title: 'Consequences',
          subtitle: 'How did you feel and react?', color: kTeal),
      const SizedBox(height: 20),

      // Emotions section
      Text('Emotions', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w800,
          color: t.colorScheme.onSurface)),
      const SizedBox(height: 8),

      // Emotion chips
      Wrap(spacing: 8, runSpacing: 8,
        children: Emotion.values.where((e) => e.isNegative).map((e) {
          final selected = widget.selectedEmotions.any((se) => se.emotion == e);
          return GestureDetector(
            onTap: () => setState(() {
              _pickedEmotion = e;
            }),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
              decoration: BoxDecoration(
                color: selected ? kTeal.withOpacity(0.12) :
                _pickedEmotion == e ? kPurple.withOpacity(0.1) : t.cardColor,
                borderRadius: BorderRadius.circular(999),
                border: Border.all(color: selected ? kTeal :
                _pickedEmotion == e ? kPurple :
                t.colorScheme.outline.withOpacity(0.15)),
              ),
              child: Text('${e.emoji} ${e.label}',
                  style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600,
                      color: selected ? kTeal :
                      _pickedEmotion == e ? kPurple : t.colorScheme.onSurface)),
            ),
          );
        }).toList(),
      ),

      if (_pickedEmotion != null) ...[
        const SizedBox(height: 14),
        Text('Intensity: ${_intensity.round()}/10',
            style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700,
                color: t.colorScheme.onSurface)),
        Slider(
          value: _intensity, min: 1, max: 10, divisions: 9,
          activeColor: kPurple,
          onChanged: (v) => setState(() => _intensity = v),
        ),
        Center(child: TextButton(
          onPressed: _addEmotion,
          child: const Text('Add emotion', style: TextStyle(color: kPurple, fontWeight: FontWeight.w700)),
        )),
      ],

      if (widget.selectedEmotions.isNotEmpty) ...[
        const SizedBox(height: 8),
        Wrap(spacing: 6, runSpacing: 6,
          children: widget.selectedEmotions.map((e) => Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              gradient: kGradientCool,
              borderRadius: BorderRadius.circular(999),
            ),
            child: Text('${e.emotion.emoji} ${e.emotion.label} ${e.intensity}/10',
                style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700,
                    color: Colors.white)),
          )).toList(),
        ),
      ],

      const SizedBox(height: 24),

      // Behaviours
      Text('How did you react?', style: TextStyle(fontSize: 14,
          fontWeight: FontWeight.w800, color: t.colorScheme.onSurface)),
      const SizedBox(height: 8),
      Wrap(spacing: 8, runSpacing: 8,
        children: BehaviourResponse.values.map((b) {
          final selected = widget.selectedBehaviours.contains(b);
          return GestureDetector(
            onTap: () {
              setState(() {
                if (selected) widget.selectedBehaviours.remove(b);
                else widget.selectedBehaviours.add(b);
              });
              widget.onChanged();
            },
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
              decoration: BoxDecoration(
                color: selected ? kTeal.withOpacity(0.12) : t.cardColor,
                borderRadius: BorderRadius.circular(999),
                border: Border.all(color: selected ? kTeal :
                t.colorScheme.outline.withOpacity(0.15)),
              ),
              child: Text('${b.emoji} ${b.label}',
                  style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600,
                      color: selected ? kTeal : t.colorScheme.onSurface)),
            ),
          );
        }).toList(),
      ),
      const SizedBox(height: 20),
    ]);
  }
}

// ── Step AI — Analysis ────────────────────────────────────────────────────────

class _StepAI extends StatelessWidget {
  final bool       loading;
  final AIAnalysis? analysis;
  final String?    error;
  final VoidCallback onSave, onRetry;
  const _StepAI({required this.loading, required this.analysis,
    required this.error, required this.onSave, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context);

    if (loading) {
      return Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
        Container(
          width: 80, height: 80,
          decoration: BoxDecoration(gradient: kGradientPrimary, shape: BoxShape.circle),
          child: const Padding(padding: EdgeInsets.all(20),
              child: CircularProgressIndicator(color: Colors.white, strokeWidth: 3)),
        ),
        const SizedBox(height: 20),
        const Text('Analysing your thoughts…',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
        const SizedBox(height: 8),
        Text('AI is identifying cognitive patterns', style: TextStyle(
            fontSize: 13, color: t.colorScheme.onSurfaceVariant)),
      ]));
    }

    if (error != null) {
      return Center(child: Padding(padding: const EdgeInsets.all(32), child: Column(
        mainAxisAlignment: MainAxisAlignment.center, children: [
        const Text('⚠️', style: TextStyle(fontSize: 48)),
        const SizedBox(height: 16),
        const Text('Analysis unavailable', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800)),
        const SizedBox(height: 8),
        Text('Check your OpenAI API key in settings.',
            style: TextStyle(color: t.colorScheme.onSurfaceVariant, fontSize: 13)),
        const SizedBox(height: 20),
        Row(mainAxisAlignment: MainAxisAlignment.center, children: [
          TextButton(onPressed: onRetry, child: const Text('Retry')),
          const SizedBox(width: 12),
          ElevatedButton(
            onPressed: onSave,
            style: ElevatedButton.styleFrom(backgroundColor: kGreen),
            child: const Text('Save without AI', style: TextStyle(color: Colors.white)),
          ),
        ]),
      ],
      )));
    }

    if (analysis == null) return const SizedBox();

    return ListView(padding: const EdgeInsets.fromLTRB(20, 20, 20, 100), children: [
      // Distortions
      if (analysis!.distortions.isNotEmpty) ...[
        _AISectionHeader('🔍 Cognitive Distortions Detected', kRose),
        const SizedBox(height: 10),
        ...analysis!.distortions.map((d) => Container(
          margin: const EdgeInsets.only(bottom: 8),
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: kRose.withOpacity(0.05),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: kRose.withOpacity(0.15)),
          ),
          child: Row(children: [
            Text(d.emoji, style: const TextStyle(fontSize: 24)),
            const SizedBox(width: 12),
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(d.label, style: const TextStyle(
                  fontWeight: FontWeight.w800, fontSize: 13)),
              Text(d.description, style: TextStyle(
                  fontSize: 11, color: Colors.grey[600])),
            ])),
          ]),
        )),
        const SizedBox(height: 20),
      ],

      // Emotional validation
      _AISectionHeader('💛 Your Feelings Are Valid', kAmber),
      const SizedBox(height: 10),
      _AICard(text: analysis!.emotionalValidation, color: kAmber),
      const SizedBox(height: 20),

      // Alternative thought
      _AISectionHeader('💡 Alternative Perspective', kGreen),
      const SizedBox(height: 10),
      _AICard(text: analysis!.alternativeThought, color: kGreen),
      const SizedBox(height: 20),

      // Reframing
      _AISectionHeader('🔄 Reframing Suggestion', kBlue),
      const SizedBox(height: 10),
      _AICard(text: analysis!.reframingSuggestion, color: kBlue),
      const SizedBox(height: 20),

      // Practice
      if (analysis!.practiceRecommendations.isNotEmpty) ...[
        _AISectionHeader('🎯 Recommended Practice', kPurple),
        const SizedBox(height: 10),
        Wrap(spacing: 8, runSpacing: 8,
          children: analysis!.practiceRecommendations.map((r) => Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              gradient: kGradientPrimary,
              borderRadius: BorderRadius.circular(999),
            ),
            child: Text(r, style: const TextStyle(color: Colors.white,
                fontSize: 12, fontWeight: FontWeight.w700)),
          )).toList(),
        ),
        const SizedBox(height: 24),
      ],

      // Save button
      SizedBox(
        width: double.infinity,
        child: DecoratedBox(
          decoration: BoxDecoration(
            gradient: kGradientPrimary,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [BoxShadow(color: kPurple.withOpacity(0.3),
                blurRadius: 12, offset: const Offset(0, 5))],
          ),
          child: ElevatedButton.icon(
            onPressed: onSave,
            icon: const Icon(Icons.check_circle_rounded, color: Colors.white),
            label: const Text('Save Reflection',
                style: TextStyle(color: Colors.white,
                    fontWeight: FontWeight.w800, fontSize: 16)),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.transparent, shadowColor: Colors.transparent,
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            ),
          ),
        ),
      ),
    ]);
  }
}

class _AISectionHeader extends StatelessWidget {
  final String text;
  final Color color;
  const _AISectionHeader(this.text, this.color);
  @override
  Widget build(BuildContext c) => Text(text, style: TextStyle(
      fontSize: 14, fontWeight: FontWeight.w800, color: color));
}

class _AICard extends StatelessWidget {
  final String text;
  final Color color;
  const _AICard({required this.text, required this.color});
  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context);
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withOpacity(0.05),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: color.withOpacity(0.15)),
      ),
      child: Text(text, style: TextStyle(fontSize: 13,
          color: t.colorScheme.onSurface, height: 1.5)),
    );
  }
}

// ── Shared ────────────────────────────────────────────────────────────────────

class _StepBanner extends StatelessWidget {
  final String emoji, title, subtitle;
  final Color color;
  const _StepBanner({required this.emoji, required this.title,
    required this.subtitle, required this.color});
  @override
  Widget build(BuildContext context) => Row(children: [
    Container(
      width: 52, height: 52,
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Center(child: Text(emoji, style: const TextStyle(fontSize: 26))),
    ),
    const SizedBox(width: 14),
    Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text(title, style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: color)),
      Text(subtitle, style: TextStyle(fontSize: 12,
          color: Theme.of(context).colorScheme.onSurfaceVariant)),
    ]),
  ]);
}

class _Question extends StatelessWidget {
  final TextEditingController ctrl;
  final String question, hint;
  final int maxLines;
  const _Question({required this.ctrl, required this.question,
    required this.hint, this.maxLines = 1});
  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context);
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text(question, style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700,
          color: t.colorScheme.onSurface)),
      const SizedBox(height: 8),
      TextField(
        controller: ctrl,
        maxLines: maxLines,
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: TextStyle(color: t.colorScheme.onSurfaceVariant.withOpacity(0.5),
              fontSize: 13),
          filled: true, fillColor: t.cardColor,
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(14),
              borderSide: BorderSide(color: t.colorScheme.outline.withOpacity(0.15))),
          enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14),
              borderSide: BorderSide(color: t.colorScheme.outline.withOpacity(0.15))),
          focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14),
              borderSide: const BorderSide(color: kPurple, width: 1.5)),
          contentPadding: const EdgeInsets.all(14),
        ),
      ),
    ]);
  }
}