import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'mindshift_models.dart';
import 'mindshift_reflection_store.dart';
import 'mindshift_ai_service.dart'
    hide ReflectionEntry, EmotionEntry, CognitiveDistortion, AIAnalysis, BehaviourResponse;

class _C {
  static const bg           = Color(0xFFF5F3FF);
  static const violet       = Color(0xFF7C3AED);
  static const electricBlue = Color(0xFF2563EB);
  static const cardBorder   = Color(0xFFE0D9F7);
  static const textMain     = Color(0xFF1E1040);
  static const textMuted    = Color(0xFF7C6FAA);
  static const lavender     = Color(0xFFEDE9FE);
  static const roseDeep     = Color(0xFFE11D48);
  static const emerald      = Color(0xFF059669);
}

const _grad = LinearGradient(colors: [_C.violet, _C.electricBlue]);

// ─── Helpers sobre ReflectionEntry ───────────────────────────────────────────
// Usa apenas campos que existem no modelo real
List<CognitiveDistortion> _distorcoes(ReflectionEntry e) =>
    e.aiAnalysis?.distortions ?? [];

int _distress(ReflectionEntry e) {
  if (e.emotions.isEmpty) return 0;
  return e.emotions
      .map((em) => em.intensity)
      .reduce((a, b) => a > b ? a : b);
}

// ─── Screen ───────────────────────────────────────────────────────────────────
class EvolutionScreen extends StatefulWidget {
  const EvolutionScreen({super.key});

  @override
  State<EvolutionScreen> createState() => _EvolutionScreenState();
}

class _EvolutionScreenState extends State<EvolutionScreen> {
  String? _relatorioIA;
  bool    _carregando = false;
  String? _erro;

  List<ReflectionEntry> _completas(ReflectionStore store) => store.entries
      .where((e) => e.aiAnalysis != null)
      .toList()
    ..sort((a, b) => b.createdAt.compareTo(a.createdAt));

  Future<void> _gerarRelatorio(List<ReflectionEntry> entradas) async {
    if (entradas.isEmpty) return;
    setState(() { _carregando = true; _erro = null; });

    try {
      final resumo = entradas.asMap().entries.map((e) {
        final i = e.key + 1;
        final r = e.value;
        final emocoes = r.emotions
            .map((em) => '${em.emotion.label} (${em.intensity}/10)')
            .join(', ');
        final dist = _distorcoes(r).map((d) => d.label).join(', ');
        return '''
Reflexão $i (${_fmt(r.createdAt)}):
- Situação: ${r.whatHappened}
- Pensamento: ${r.automaticThought}
- Emoções: ${emocoes.isEmpty ? 'não registadas' : emocoes}
- Distorções: ${dist.isEmpty ? 'nenhuma' : dist}
- Perspectiva alternativa: ${r.aiAnalysis!.alternativeThought}
''';
      }).join('\n');

      final texto = await MindShiftAIService.instance.analyseEvolution(
        summary: resumo,
        count: entradas.length,
      );
      setState(() { _relatorioIA = texto; _carregando = false; });
    } catch (e) {
      setState(() { _erro = e.toString(); _carregando = false; });
    }
  }

  String _fmt(DateTime d) =>
      '${d.day.toString().padLeft(2,'0')}/${d.month.toString().padLeft(2,'0')}/${d.year}';

  @override
  Widget build(BuildContext context) {
    final store    = context.watch<ReflectionStore>();
    final entradas = _completas(store);

    return Container(
      color: _C.bg,
      child: SafeArea(
        child: CustomScrollView(
          physics: const BouncingScrollPhysics(),
          slivers: [
            SliverToBoxAdapter(child: _buildHeader()),
            if (entradas.isEmpty)
              SliverFillRemaining(child: _buildVazio())
            else ...[
              SliverToBoxAdapter(
                child: _RelatorioCard(
                  texto: _relatorioIA,
                  carregando: _carregando,
                  erro: _erro,
                  onGerar: () => _gerarRelatorio(entradas),
                ),
              ),
              SliverToBoxAdapter(child: _StatsStrip(entradas: entradas)),
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 8, 20, 6),
                  child: Text('REFLEXÕES',
                      style: const TextStyle(
                          color: _C.textMuted,
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 1.2)),
                ),
              ),
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(20, 4, 20, 60),
                sliver: SliverList(
                  delegate: SliverChildBuilderDelegate(
                        (_, i) => _AnimatedCard(
                      index: i,
                      child: _ProgressCard(
                          entry: entradas[i],
                          numero: entradas.length - i),
                    ),
                    childCount: entradas.length,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() => Padding(
    padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
    child: Row(children: [
      Container(
        width: 44, height: 44,
        decoration: BoxDecoration(
          gradient: _grad,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [BoxShadow(
              color: _C.violet.withOpacity(0.3),
              blurRadius: 10, offset: const Offset(0, 4))],
        ),
        child: const Icon(Icons.trending_up_rounded,
            color: Colors.white, size: 22),
      ),
      const SizedBox(width: 14),
      const Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text('Evolução',
            style: TextStyle(color: _C.textMain, fontSize: 20,
                fontWeight: FontWeight.w800, letterSpacing: -0.3)),
        Text('O teu progresso ao longo do tempo',
            style: TextStyle(color: _C.textMuted, fontSize: 12)),
      ]),
    ]),
  );

  Widget _buildVazio() => Center(
    child: Padding(
      padding: const EdgeInsets.all(40),
      child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
        Container(
          width: 72, height: 72,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: _C.cardBorder, width: 1.5),
          ),
          child: const Icon(Icons.trending_up_rounded,
              color: _C.cardBorder, size: 36),
        ),
        const SizedBox(height: 20),
        const Text('A tua evolução começa aqui',
            style: TextStyle(color: _C.textMain,
                fontSize: 18, fontWeight: FontWeight.w800)),
        const SizedBox(height: 8),
        const Text(
          'Completa reflexões com análise IA\npara acompanhar o teu progresso.',
          textAlign: TextAlign.center,
          style: TextStyle(color: _C.textMuted, fontSize: 14, height: 1.6),
        ),
      ]),
    ),
  );
}

// ─── Card relatório IA ────────────────────────────────────────────────────────
class _RelatorioCard extends StatelessWidget {
  final String?      texto;
  final bool         carregando;
  final String?      erro;
  final VoidCallback onGerar;
  const _RelatorioCard({required this.texto, required this.carregando,
    required this.erro, required this.onGerar});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 8),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: _C.violet.withOpacity(0.3), width: 1.5),
          boxShadow: [BoxShadow(
              color: _C.violet.withOpacity(0.08),
              blurRadius: 14, offset: const Offset(0, 4))],
        ),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 12),
            child: Row(children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                    gradient: _grad,
                    borderRadius: BorderRadius.circular(20)),
                child: const Text('✦  Análise IA',
                    style: TextStyle(color: Colors.white, fontSize: 10,
                        fontWeight: FontWeight.w700, letterSpacing: 0.8)),
              ),
              const SizedBox(width: 8),
              const Expanded(
                child: Text('Relatório de Progresso',
                    style: TextStyle(color: _C.textMain, fontSize: 13,
                        fontWeight: FontWeight.w700)),
              ),
              if (!carregando)
                GestureDetector(
                  onTap: onGerar,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 10, vertical: 5),
                    decoration: BoxDecoration(
                      color: _C.lavender,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: _C.violet.withOpacity(0.3)),
                    ),
                    child: Row(mainAxisSize: MainAxisSize.min, children: [
                      Icon(
                          texto == null
                              ? Icons.auto_awesome_rounded
                              : Icons.refresh_rounded,
                          color: _C.violet, size: 13),
                      const SizedBox(width: 4),
                      Text(texto == null ? 'Gerar' : 'Atualizar',
                          style: const TextStyle(color: _C.violet,
                              fontSize: 11, fontWeight: FontWeight.w700)),
                    ]),
                  ),
                ),
            ]),
          ),
          const Divider(height: 1, color: _C.cardBorder),
          Padding(
            padding: const EdgeInsets.all(16),
            child: _buildCorpo(),
          ),
        ]),
      ),
    );
  }

  Widget _buildCorpo() {
    if (carregando) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: Row(children: [
          SizedBox(width: 18, height: 18,
              child: CircularProgressIndicator(strokeWidth: 2.5, color: _C.violet)),
          const SizedBox(width: 12),
          const Text('A analisar o teu progresso...',
              style: TextStyle(color: _C.textMuted, fontSize: 13)),
        ]),
      );
    }
    if (erro != null) {
      return const Text(
          'Não foi possível gerar a análise.\nVerifica a chave API nas definições.',
          style: TextStyle(color: _C.roseDeep, fontSize: 13, height: 1.5));
    }
    if (texto == null) {
      return const Text(
          'Toca em "Gerar" para a IA analisar o teu progresso e mostrar como o teu pensamento evoluiu.',
          style: TextStyle(color: _C.textMuted, fontSize: 13, height: 1.5));
    }
    return Text(texto!,
        style: const TextStyle(color: _C.textMain, fontSize: 13, height: 1.6));
  }
}

// ─── Stats Strip ──────────────────────────────────────────────────────────────
class _StatsStrip extends StatelessWidget {
  final List<ReflectionEntry> entradas;
  const _StatsStrip({required this.entradas});

  @override
  Widget build(BuildContext context) {
    final contagem = <CognitiveDistortion, int>{};
    for (final e in entradas) {
      for (final d in _distorcoes(e)) {
        contagem[d] = (contagem[d] ?? 0) + 1;
      }
    }
    final maisFreq = contagem.isEmpty
        ? '—'
        : (contagem.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value)))
        .first.key.label;

    final distMedio = entradas.isEmpty
        ? 0
        : (entradas.map((e) => _distress(e)).reduce((a, b) => a + b) /
        entradas.length)
        .round();

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: _C.cardBorder, width: 1.5),
          boxShadow: [BoxShadow(
              color: _C.violet.withOpacity(0.06),
              blurRadius: 10, offset: const Offset(0, 3))],
        ),
        child: Row(children: [
          _stat('${entradas.length}', 'Reflexões'),
          _div(),
          _stat('$distMedio/10', 'Distress médio'),
          _div(),
          Expanded(flex: 2, child: Column(children: [
            Text(maisFreq,
                textAlign: TextAlign.center,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(color: _C.textMain,
                    fontSize: 11, fontWeight: FontWeight.w800)),
            const SizedBox(height: 2),
            const Text('Distorção freq.',
                style: TextStyle(color: _C.textMuted, fontSize: 10)),
          ])),
        ]),
      ),
    );
  }

  Widget _stat(String val, String label) => Expanded(
    child: Column(children: [
      Text(val, style: const TextStyle(color: _C.textMain,
          fontSize: 15, fontWeight: FontWeight.w800)),
      const SizedBox(height: 2),
      Text(label, style: const TextStyle(color: _C.textMuted, fontSize: 10),
          textAlign: TextAlign.center),
    ]),
  );

  Widget _div() => Container(
      width: 1, height: 32, color: _C.cardBorder,
      margin: const EdgeInsets.symmetric(horizontal: 8));
}

// ─── Progress Card ────────────────────────────────────────────────────────────
class _ProgressCard extends StatelessWidget {
  final ReflectionEntry entry;
  final int numero;
  const _ProgressCard({required this.entry, required this.numero});

  @override
  Widget build(BuildContext context) {
    final d   = entry.createdAt;
    final fmt = '${d.day.toString().padLeft(2,'0')}/${d.month.toString().padLeft(2,'0')}/${d.year}';
    final ai  = entry.aiAnalysis!;
    final dist = _distress(entry);
    final distorcoes = _distorcoes(entry);

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: _C.cardBorder, width: 1.5),
        boxShadow: [BoxShadow(
            color: _C.violet.withOpacity(0.07),
            blurRadius: 12, offset: const Offset(0, 4))],
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [

        // Cabeçalho
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 14, 16, 10),
          child: Row(children: [
            Container(
              width: 26, height: 26,
              decoration: BoxDecoration(gradient: _grad, shape: BoxShape.circle),
              child: Center(child: Text('$numero',
                  style: const TextStyle(color: Colors.white,
                      fontSize: 11, fontWeight: FontWeight.w800))),
            ),
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                  color: _C.lavender, borderRadius: BorderRadius.circular(20)),
              child: Row(mainAxisSize: MainAxisSize.min, children: [
                const Icon(Icons.calendar_today_rounded,
                    size: 11, color: _C.textMuted),
                const SizedBox(width: 4),
                Text(fmt, style: const TextStyle(
                    fontSize: 11, color: _C.textMuted)),
              ]),
            ),
            const Spacer(),
            if (dist > 0) _DistressPill(nivel: dist),
          ]),
        ),

        // Situação
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
          child: _LabeledText(
              cor: _C.electricBlue, label: 'SITUAÇÃO',
              texto: entry.whatHappened),
        ),

        // Emoções
        if (entry.emotions.isNotEmpty)
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 10),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              const Text('EMOÇÕES', style: TextStyle(color: _C.textMuted,
                  fontSize: 10, fontWeight: FontWeight.w700, letterSpacing: 0.8)),
              const SizedBox(height: 5),
              Wrap(spacing: 6, runSpacing: 6,
                children: entry.emotions.map<Widget>((e) => Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: _C.lavender,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: _C.cardBorder),
                  ),
                  child: Text('${e.emotion.label} ${e.intensity}/10',
                      style: const TextStyle(color: _C.violet,
                          fontSize: 11, fontWeight: FontWeight.w600)),
                )).toList(),
              ),
            ]),
          ),

        // Distorções (de aiAnalysis)
        if (distorcoes.isNotEmpty)
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 10),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              const Text('DISTORÇÕES', style: TextStyle(color: _C.textMuted,
                  fontSize: 10, fontWeight: FontWeight.w700, letterSpacing: 0.8)),
              const SizedBox(height: 5),
              Wrap(spacing: 6, runSpacing: 6,
                children: distorcoes.map<Widget>((d) => Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: _C.roseDeep.withOpacity(0.07),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                        color: _C.roseDeep.withOpacity(0.25)),
                  ),
                  child: Text(d.label,
                      style: TextStyle(color: _C.roseDeep,
                          fontSize: 11, fontWeight: FontWeight.w600)),
                )).toList(),
              ),
            ]),
          ),

        // Antes
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14),
          child: _ThoughtBox(
            label: 'PENSAMENTO AUTOMÁTICO',
            icon: Icons.arrow_back_rounded,
            quote: entry.automaticThought,
            accentColor: _C.roseDeep,
            bgColor: const Color(0xFFFFF1F2),
          ),
        ),

        // Conector
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Column(children: [
            Container(width: 1.5, height: 10, color: _C.cardBorder),
            Container(
              width: 26, height: 26,
              decoration: BoxDecoration(
                gradient: _grad, shape: BoxShape.circle,
                boxShadow: [BoxShadow(
                    color: _C.violet.withOpacity(0.3),
                    blurRadius: 8, offset: const Offset(0, 2))],
              ),
              child: const Icon(Icons.arrow_downward_rounded,
                  color: Colors.white, size: 13),
            ),
            Container(width: 1.5, height: 10, color: _C.cardBorder),
          ]),
        ),

        // Depois
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14),
          child: _ThoughtBox(
            label: 'PERSPECTIVA ALTERNATIVA',
            icon: Icons.arrow_forward_rounded,
            quote: ai.alternativeThought,
            accentColor: _C.emerald,
            bgColor: const Color(0xFFF0FDF4),
          ),
        ),

        const SizedBox(height: 12),

        // Secção IA lavanda (igual ao Insights)
        Container(
          width: double.infinity,
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 14),
          decoration: const BoxDecoration(
            color: _C.lavender,
            borderRadius: BorderRadius.only(
              bottomLeft: Radius.circular(18),
              bottomRight: Radius.circular(18),
            ),
          ),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                  gradient: _grad, borderRadius: BorderRadius.circular(20)),
              child: const Text('✦  Reframe IA',
                  style: TextStyle(color: Colors.white, fontSize: 10,
                      fontWeight: FontWeight.w700, letterSpacing: 0.8)),
            ),
            const SizedBox(height: 8),
            Text(ai.reframingSuggestion,
                style: const TextStyle(
                    color: _C.textMain, fontSize: 13, height: 1.5)),
            if (ai.practiceRecommendations.isNotEmpty) ...[
              const SizedBox(height: 10),
              Wrap(spacing: 6, runSpacing: 6,
                children: ai.practiceRecommendations.map<Widget>((r) =>
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: _C.violet.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                            color: _C.violet.withOpacity(0.3)),
                      ),
                      child: Text(r, style: const TextStyle(color: _C.violet,
                          fontSize: 11, fontWeight: FontWeight.w600)),
                    )).toList(),
              ),
            ],
          ]),
        ),
      ]),
    );
  }
}

// ─── Widgets auxiliares ───────────────────────────────────────────────────────
class _LabeledText extends StatelessWidget {
  final Color cor;
  final String label, texto;
  const _LabeledText({required this.cor, required this.label, required this.texto});

  @override
  Widget build(BuildContext context) => Column(
      crossAxisAlignment: CrossAxisAlignment.start, children: [
    Text(label, style: TextStyle(color: cor, fontSize: 10,
        fontWeight: FontWeight.w700, letterSpacing: 0.8)),
    const SizedBox(height: 3),
    Text(texto, style: const TextStyle(
        color: _C.textMain, fontSize: 13, height: 1.4)),
  ]);
}

class _DistressPill extends StatelessWidget {
  final int nivel;
  const _DistressPill({required this.nivel});

  @override
  Widget build(BuildContext context) {
    final cor = nivel >= 8 ? _C.roseDeep
        : nivel >= 5 ? const Color(0xFFF97316)
        : _C.emerald;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: cor.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: cor.withOpacity(0.3)),
      ),
      child: Text('Distress $nivel/10',
          style: TextStyle(color: cor, fontSize: 10,
              fontWeight: FontWeight.w700)),
    );
  }
}

class _ThoughtBox extends StatelessWidget {
  final String label, quote;
  final IconData icon;
  final Color accentColor, bgColor;
  const _ThoughtBox({required this.label, required this.icon,
    required this.quote, required this.accentColor, required this.bgColor});

  @override
  Widget build(BuildContext context) => Container(
    width: double.infinity,
    padding: const EdgeInsets.all(12),
    decoration: BoxDecoration(
      color: bgColor,
      borderRadius: BorderRadius.circular(14),
      border: Border.all(color: accentColor.withOpacity(0.25), width: 1.5),
    ),
    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Row(children: [
        Icon(icon, size: 12, color: accentColor),
        const SizedBox(width: 5),
        Text(label, style: TextStyle(fontSize: 10,
            fontWeight: FontWeight.w800, color: accentColor, letterSpacing: 0.7)),
      ]),
      const SizedBox(height: 6),
      Text('"$quote"', style: const TextStyle(fontSize: 13,
          color: _C.textMain, height: 1.4, fontStyle: FontStyle.italic)),
    ]),
  );
}

class _AnimatedCard extends StatefulWidget {
  final Widget child;
  final int index;
  const _AnimatedCard({required this.child, required this.index});

  @override
  State<_AnimatedCard> createState() => _AnimatedCardState();
}

class _AnimatedCardState extends State<_AnimatedCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _fade;
  late Animation<Offset> _slide;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(vsync: this,
        duration: Duration(milliseconds: 350 + widget.index * 60));
    _fade  = CurvedAnimation(parent: _ctrl, curve: Curves.easeOut);
    _slide = Tween<Offset>(begin: const Offset(0, 0.1), end: Offset.zero)
        .animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeOut));
    _ctrl.forward();
  }

  @override
  void dispose() { _ctrl.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) => FadeTransition(
      opacity: _fade,
      child: SlideTransition(position: _slide, child: widget.child));
}