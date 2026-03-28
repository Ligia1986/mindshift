import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'mindshift_reflection_store.dart';

enum HomeType { situation, thought, insight }

// ─── Paleta clara ─────────────────────────────────────────────────────────────
class _C {
  static const bg           = Color(0xFFF5F3FF);
  static const surface      = Colors.white;
  static const violet       = Color(0xFF7C3AED);
  static const electricBlue = Color(0xFF2563EB);
  static const indigo       = Color(0xFF4338CA);
  static const cardBorder   = Color(0xFFE0D9F7);
  static const textMain     = Color(0xFF1E1040);
  static const textMuted    = Color(0xFF7C6FAA);
  static const lavender     = Color(0xFFEDE9FE);
}

InputDecoration _fieldDecoration(String label, IconData icon) {
  return InputDecoration(
    labelText: label,
    labelStyle: const TextStyle(color: _C.textMuted),
    prefixIcon: Icon(icon, color: _C.violet, size: 20),
    filled: true,
    fillColor: Colors.white,
    enabledBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(14),
      borderSide: const BorderSide(color: _C.cardBorder, width: 1.5),
    ),
    focusedBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(14),
      borderSide: const BorderSide(color: _C.violet, width: 2),
    ),
    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
  );
}

// ─── Screen ───────────────────────────────────────────────────────────────────
class HomeScreen extends StatefulWidget {
  final String title;
  final HomeType type;

  const HomeScreen({super.key, required this.title, required this.type});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen>
    with SingleTickerProviderStateMixin {
  final triggerCtrl = TextEditingController();
  final thoughtCtrl = TextEditingController();
  bool loading = false;
  late AnimationController _btnAnim;

  @override
  void initState() {
    super.initState();
    _btnAnim = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 150),
      lowerBound: 0.95,
      upperBound: 1.0,
      value: 1.0,
    );
  }

  @override
  void dispose() {
    triggerCtrl.dispose();
    thoughtCtrl.dispose();
    _btnAnim.dispose();
    super.dispose();
  }

  IconData get _typeIcon => switch (widget.type) {
    HomeType.situation => Icons.location_on_rounded,
    HomeType.thought   => Icons.psychology_rounded,
    HomeType.insight   => Icons.lightbulb_rounded,
  };

  Color get _typeAccent => switch (widget.type) {
    HomeType.situation => _C.electricBlue,
    HomeType.thought   => _C.violet,
    HomeType.insight   => _C.indigo,
  };

  @override
  Widget build(BuildContext context) {
    final store = context.watch<ReflectionStore>();
    return Container(
      color: _C.bg,
      child: SafeArea(
        child: Column(
          children: [
            _buildHeader(store),
            if (widget.type != HomeType.insight) _buildInputSection(store),
            _buildDivider(),
            Expanded(child: _buildContent(store)),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(ReflectionStore store) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [_typeAccent, _C.violet],
              ),
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: _typeAccent.withOpacity(0.3),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Icon(_typeIcon, color: Colors.white, size: 22),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.title,
                  style: const TextStyle(
                    color: _C.textMain,
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                    letterSpacing: -0.3,
                  ),
                ),
                Text(
                  _subtitleFor(widget.type),
                  style: const TextStyle(color: _C.textMuted, fontSize: 12),
                ),
              ],
            ),
          ),
          if (widget.type == HomeType.insight)
            GestureDetector(
              onTap: store.clear,
              child: Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: Colors.red.shade50,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.red.shade200),
                ),
                child: Icon(Icons.delete_sweep_rounded,
                    color: Colors.red.shade400, size: 20),
              ),
            ),
        ],
      ),
    );
  }

  String _subtitleFor(HomeType t) => switch (t) {
    HomeType.situation => 'O que aconteceu?',
    HomeType.thought   => 'O que pensaste?',
    HomeType.insight   => 'As tuas reflexões com IA',
  };

  Widget _buildInputSection(ReflectionStore store) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 4, 20, 0),
      child: Column(
        children: [
          if (widget.type == HomeType.situation)
            TextField(
              controller: triggerCtrl,
              style: const TextStyle(color: _C.textMain),
              maxLines: 2,
              decoration: _fieldDecoration(
                  'O que aconteceu?', Icons.location_on_rounded),
            ),
          if (widget.type == HomeType.thought)
            TextField(
              controller: thoughtCtrl,
              style: const TextStyle(color: _C.textMain),
              maxLines: 2,
              decoration: _fieldDecoration(
                  'O que pensaste?', Icons.psychology_rounded),
            ),
          const SizedBox(height: 14),
          _buildSaveButton(store),
        ],
      ),
    );
  }

  Widget _buildSaveButton(ReflectionStore store) {
    return GestureDetector(
      onTapDown: (_) => _btnAnim.reverse(),
      onTapUp: (_) => _btnAnim.forward(),
      onTapCancel: () => _btnAnim.forward(),
      onTap: loading
          ? null
          : () async {
        setState(() => loading = true);
        await store.addEntry(
          trigger: triggerCtrl.text,
          thought: thoughtCtrl.text,
        );
        triggerCtrl.clear();
        thoughtCtrl.clear();
        setState(() => loading = false);
      },
      child: ScaleTransition(
        scale: _btnAnim,
        child: Container(
          width: double.infinity,
          height: 50,
          decoration: BoxDecoration(
            gradient: loading
                ? LinearGradient(colors: [Colors.grey.shade300, Colors.grey.shade200])
                : const LinearGradient(
                colors: [_C.violet, _C.electricBlue]),
            borderRadius: BorderRadius.circular(14),
            boxShadow: loading
                ? []
                : [
              BoxShadow(
                color: _C.violet.withOpacity(0.3),
                blurRadius: 14,
                offset: const Offset(0, 5),
              ),
            ],
          ),
          child: Center(
            child: loading
                ? const SizedBox(
              height: 22,
              width: 22,
              child: CircularProgressIndicator(
                  color: Colors.white, strokeWidth: 2.5),
            )
                : const Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.save_alt_rounded,
                    color: Colors.white, size: 18),
                SizedBox(width: 8),
                Text(
                  'Guardar Reflexão',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
                    fontSize: 15,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildDivider() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
      child: Row(children: [
        Expanded(child: Container(height: 1, color: _C.cardBorder)),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 10),
          child: Text('Registos',
              style: TextStyle(
                  color: _C.textMuted,
                  fontSize: 11,
                  letterSpacing: 1.2)),
        ),
        Expanded(child: Container(height: 1, color: _C.cardBorder)),
      ]),
    );
  }

  Widget _buildContent(ReflectionStore store) {
    if (store.entries.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(_typeIcon, size: 48, color: _C.cardBorder),
            const SizedBox(height: 14),
            const Text('Sem reflexões ainda',
                style: TextStyle(
                    color: _C.textMuted,
                    fontSize: 16,
                    fontWeight: FontWeight.w600)),
            const SizedBox(height: 4),
            const Text('Adiciona a tua primeira entrada acima',
                style: TextStyle(color: _C.textMuted, fontSize: 13)),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 30),
      itemCount: store.entries.length,
      itemBuilder: (context, index) {
        final e = store.entries[index];
        return _AnimatedEntry(
          index: index,
          child: switch (widget.type) {
            HomeType.situation => _SimpleCard(
              emoji: '📍',
              label: 'Situação',
              value: e.whatHappened,
              accentColor: _C.electricBlue,
            ),
            HomeType.thought => _SimpleCard(
              emoji: '💭',
              label: 'Pensamento',
              value: e.automaticThought,
              accentColor: _C.violet,
            ),
            HomeType.insight => _InsightCard(entry: e),
          },
        );
      },
    );
  }
}

// ─── Card simples ─────────────────────────────────────────────────────────────
class _SimpleCard extends StatelessWidget {
  final String emoji, label, value;
  final Color accentColor;

  const _SimpleCard({
    required this.emoji,
    required this.label,
    required this.value,
    required this.accentColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _C.cardBorder, width: 1.5),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 5,
            height: 70,
            decoration: BoxDecoration(
              color: accentColor,
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(16),
                bottomLeft: Radius.circular(16),
              ),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '$emoji $label',
                    style: TextStyle(
                      color: accentColor,
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.8,
                    ),
                  ),
                  const SizedBox(height: 5),
                  Text(value,
                      style: const TextStyle(
                          color: _C.textMain, fontSize: 14)),
                ],
              ),
            ),
          ),
          const SizedBox(width: 12),
        ],
      ),
    );
  }
}

// ─── Insight Card ─────────────────────────────────────────────────────────────
class _InsightCard extends StatelessWidget {
  final dynamic entry;
  const _InsightCard({required this.entry});

  @override
  Widget build(BuildContext context) {
    final hasInsight = entry.aiAnalysis?.alternativeThought != null;
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: _C.cardBorder, width: 1.5),
        boxShadow: [
          BoxShadow(
            color: _C.violet.withOpacity(0.08),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 10),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _rowLabel('📍', 'Situação', _C.electricBlue),
                const SizedBox(height: 4),
                Text(entry.whatHappened ?? '—',
                    style: const TextStyle(
                        color: _C.textMain, fontSize: 14)),
                const SizedBox(height: 10),
                _rowLabel('💭', 'Pensamento', _C.violet),
                const SizedBox(height: 4),
                Text(entry.automaticThought ?? '—',
                    style: const TextStyle(
                        color: _C.textMuted, fontSize: 14)),
              ],
            ),
          ),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 14),
            decoration: BoxDecoration(
              color: _C.lavender,
              borderRadius: const BorderRadius.only(
                bottomLeft: Radius.circular(18),
                bottomRight: Radius.circular(18),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [_C.violet, _C.electricBlue],
                    ),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: const Text(
                    '✦  Análise IA',
                    style: TextStyle(
                        color: Colors.white,
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0.8),
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  hasInsight
                      ? entry.aiAnalysis!.alternativeThought
                      : 'A analisar...',
                  style: TextStyle(
                    color: hasInsight ? _C.textMain : _C.textMuted,
                    fontSize: 14,
                    height: 1.5,
                    fontStyle: hasInsight
                        ? FontStyle.normal
                        : FontStyle.italic,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _rowLabel(String emoji, String label, Color color) {
    return Row(children: [
      Text(emoji),
      const SizedBox(width: 5),
      Text(
        label.toUpperCase(),
        style: TextStyle(
          color: color,
          fontSize: 10,
          fontWeight: FontWeight.w700,
          letterSpacing: 1.0,
        ),
      ),
    ]);
  }
}

// ─── Entrada animada ──────────────────────────────────────────────────────────
class _AnimatedEntry extends StatefulWidget {
  final Widget child;
  final int index;
  const _AnimatedEntry({required this.child, required this.index});

  @override
  State<_AnimatedEntry> createState() => _AnimatedEntryState();
}

class _AnimatedEntryState extends State<_AnimatedEntry>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _fade;
  late Animation<Offset> _slide;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: Duration(milliseconds: 350 + widget.index * 60),
    );
    _fade = CurvedAnimation(parent: _ctrl, curve: Curves.easeOut);
    _slide = Tween<Offset>(
      begin: const Offset(0, 0.12),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeOut));
    _ctrl.forward();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => FadeTransition(
    opacity: _fade,
    child: SlideTransition(position: _slide, child: widget.child),
  );
}