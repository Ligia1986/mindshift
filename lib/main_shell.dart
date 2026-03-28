import 'package:flutter/material.dart';
import 'home_screen.dart';
import 'settings_screen.dart';
import 'emotions_screen.dart';
import 'evolution_screen.dart';

class MainShell extends StatefulWidget {
  const MainShell({super.key});

  @override
  State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell> {
  int _index = 0;

  late final List<Widget> _screens = [
    const HomeScreen(title: 'A — Situação',   type: HomeType.situation),
    const HomeScreen(title: 'B — Pensamentos', type: HomeType.thought),
    const EmotionsScreen(),
    const EvolutionScreen(),
    const HomeScreen(title: 'Análise IA',     type: HomeType.insight),
  ];

  static const _navItems = [
    _NavItem(icon: Icons.location_on_rounded,  label: 'Situação'),
    _NavItem(icon: Icons.psychology_rounded,   label: 'Pensamentos'),
    _NavItem(icon: Icons.favorite_rounded,     label: 'Emoções'),
    _NavItem(icon: Icons.trending_up_rounded,  label: 'Evolução'),
    _NavItem(icon: Icons.lightbulb_rounded,    label: 'Análise'),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBody: true,
      backgroundColor: const Color(0xFFF5F3FF),
      body: _screens[_index],
      bottomNavigationBar: _LightBottomNav(
        currentIndex: _index,
        items: _navItems,
        onTap: (i) => setState(() => _index = i),
      ),
    );
  }
}

class _NavItem {
  final IconData icon;
  final String label;
  const _NavItem({required this.icon, required this.label});
}

class _LightBottomNav extends StatelessWidget {
  final int currentIndex;
  final List<_NavItem> items;
  final ValueChanged<int> onTap;

  const _LightBottomNav({
    required this.currentIndex,
    required this.items,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        border: const Border(
          top: BorderSide(color: Color(0xFFE0D9F7), width: 1),
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF7C3AED).withOpacity(0.08),
            blurRadius: 16,
            offset: const Offset(0, -3),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: SizedBox(
          height: 64,
          child: Row(
            children: List.generate(items.length, (i) {
              final sel = i == currentIndex;
              final item = items[i];

              return Expanded(
                child: GestureDetector(
                  onTap: () => onTap(i),
                  behavior: HitTestBehavior.opaque,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        width: sel ? 44 : 36,
                        height: sel ? 32 : 28,
                        decoration: sel
                            ? BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [
                              Color(0xFF7C3AED),
                              Color(0xFF2563EB),
                            ],
                          ),
                          borderRadius: BorderRadius.circular(10),
                          boxShadow: [
                            BoxShadow(
                              color: const Color(0xFF7C3AED)
                                  .withOpacity(0.3),
                              blurRadius: 8,
                              offset: const Offset(0, 3),
                            ),
                          ],
                        )
                            : null,
                        child: Icon(
                          item.icon,
                          size: sel ? 20 : 22,
                          color: sel
                              ? Colors.white
                              : const Color(0xFFB39DDB),
                        ),
                      ),
                      const SizedBox(height: 3),
                      AnimatedDefaultTextStyle(
                        duration: const Duration(milliseconds: 200),
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: sel
                              ? FontWeight.w700
                              : FontWeight.w400,
                          color: sel
                              ? const Color(0xFF4338CA)
                              : const Color(0xFFB39DDB),
                          letterSpacing: sel ? 0.2 : 0,
                        ),
                        child: Text(item.label),
                      ),
                    ],
                  ),
                ),
              );
            }),
          ),
        ),
      ),
    );
  }
}