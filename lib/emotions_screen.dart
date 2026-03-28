import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'mindshift_reflection_store.dart';

class _C {
  static const bg           = Color(0xFFF5F3FF);
  static const violet       = Color(0xFF7C3AED);
  static const electricBlue = Color(0xFF2563EB);
  static const cardBorder   = Color(0xFFE0D9F7);
  static const textMain     = Color(0xFF1E1040);
  static const textMuted    = Color(0xFF7C6FAA);
  static const lavender     = Color(0xFFEDE9FE);
}

class EmotionsScreen extends StatefulWidget {
  const EmotionsScreen({super.key});

  @override
  State<EmotionsScreen> createState() => _EmotionsScreenState();
}

class _EmotionsScreenState extends State<EmotionsScreen>
    with SingleTickerProviderStateMixin {
  final _emocaoCtrl = TextEditingController();
  bool _aguardar = false;
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
    _emocaoCtrl.dispose();
    _btnAnim.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final store = context.watch<ReflectionStore>();

    return Container(
      color: _C.bg,
      child: SafeArea(
        child: Column(
          children: [
            _buildHeader(),
            _buildInputSection(store),
            _buildDivider(),
            Expanded(child: _buildLista(store)),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                  colors: [_C.violet, _C.electricBlue]),
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                    color: _C.violet.withOpacity(0.3),
                    blurRadius: 10,
                    offset: const Offset(0, 4)),
              ],
            ),
            child: const Icon(Icons.favorite_rounded,
                color: Colors.white, size: 22),
          ),
          const SizedBox(width: 14),
          const Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Emoções',
                  style: TextStyle(
                      color: _C.textMain,
                      fontSize: 20,
                      fontWeight: FontWeight.w800,
                      letterSpacing: -0.3)),
              Text('C — O que sentiste?',
                  style: TextStyle(color: _C.textMuted, fontSize: 12)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildInputSection(ReflectionStore store) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 4, 20, 0),
      child: Column(
        children: [
          TextField(
            controller: _emocaoCtrl,
            style: const TextStyle(color: _C.textMain),
            maxLines: 2,
            decoration: InputDecoration(
              labelText: 'O que sentiste?',
              labelStyle: const TextStyle(color: _C.textMuted),
              prefixIcon: const Icon(Icons.favorite_rounded,
                  color: _C.violet, size: 20),
              filled: true,
              fillColor: Colors.white,
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide:
                const BorderSide(color: _C.cardBorder, width: 1.5),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide:
                const BorderSide(color: _C.violet, width: 2),
              ),
              contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16, vertical: 14),
            ),
          ),
          const SizedBox(height: 14),
          GestureDetector(
            onTapDown: (_) => _btnAnim.reverse(),
            onTapUp: (_) => _btnAnim.forward(),
            onTapCancel: () => _btnAnim.forward(),
            onTap: _aguardar ? null : () => _guardar(store),
            child: ScaleTransition(
              scale: _btnAnim,
              child: Container(
                width: double.infinity,
                height: 50,
                decoration: BoxDecoration(
                  gradient: _aguardar
                      ? LinearGradient(colors: [
                    Colors.grey.shade300,
                    Colors.grey.shade200
                  ])
                      : const LinearGradient(
                      colors: [_C.violet, _C.electricBlue]),
                  borderRadius: BorderRadius.circular(14),
                  boxShadow: _aguardar
                      ? []
                      : [
                    BoxShadow(
                        color: _C.violet.withOpacity(0.3),
                        blurRadius: 14,
                        offset: const Offset(0, 5))
                  ],
                ),
                child: Center(
                  child: _aguardar
                      ? const SizedBox(
                      height: 22,
                      width: 22,
                      child: CircularProgressIndicator(
                          color: Colors.white, strokeWidth: 2.5))
                      : const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.save_alt_rounded,
                          color: Colors.white, size: 18),
                      SizedBox(width: 8),
                      Text('Guardar Emoção',
                          style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w700,
                              fontSize: 15)),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
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

  Widget _buildLista(ReflectionStore store) {
    if (store.entries.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.favorite_outline_rounded,
                size: 48, color: _C.cardBorder),
            const SizedBox(height: 14),
            const Text('Sem emoções registadas',
                style: TextStyle(
                    color: _C.textMuted,
                    fontSize: 16,
                    fontWeight: FontWeight.w600)),
            const SizedBox(height: 4),
            const Text('Adiciona a tua primeira emoção acima',
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
          child: Container(
            margin: const EdgeInsets.only(bottom: 12),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: _C.cardBorder, width: 1.5),
              boxShadow: [
                BoxShadow(
                    color: Colors.black.withOpacity(0.04),
                    blurRadius: 8,
                    offset: const Offset(0, 2)),
              ],
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 5,
                  height: 70,
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [_C.violet, _C.electricBlue],
                    ),
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
                        Text('❤️ EMOÇÃO',
                            style: TextStyle(
                                color: _C.violet,
                                fontSize: 11,
                                fontWeight: FontWeight.w700,
                                letterSpacing: 0.8)),
                        const SizedBox(height: 5),
                        Text(e.whatHappened,
                            style: const TextStyle(
                                color: _C.textMain, fontSize: 14)),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 12),
              ],
            ),
          ),
        );
      },
    );
  }

  Future<void> _guardar(ReflectionStore store) async {
    if (_emocaoCtrl.text.trim().isEmpty) return;
    setState(() => _aguardar = true);
    await store.addEntry(
      trigger: _emocaoCtrl.text.trim(),
      thought: '',
    );
    _emocaoCtrl.clear();
    setState(() => _aguardar = false);
  }
}

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
        duration: Duration(milliseconds: 350 + widget.index * 60));
    _fade = CurvedAnimation(parent: _ctrl, curve: Curves.easeOut);
    _slide = Tween<Offset>(
        begin: const Offset(0, 0.12), end: Offset.zero)
        .animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeOut));
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
      child: SlideTransition(position: _slide, child: widget.child));
}