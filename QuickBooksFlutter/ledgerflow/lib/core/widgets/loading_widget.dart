// loading_widget.dart
// loading_widget.dart

import 'package:flutter/material.dart';

class LoadingWidget extends StatelessWidget {
  const LoadingWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: CircularProgressIndicator(),
    );
  }
}

// ─── Shimmer Skeleton Row ─────────────────────────
class SkeletonRow extends StatefulWidget {
  const SkeletonRow({super.key, this.height = 48});
  final double height;

  @override
  State<SkeletonRow> createState() => _SkeletonRowState();
}

class _SkeletonRowState extends State<SkeletonRow>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final Animation<double> _anim;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat();
    _anim = Tween<double>(begin: -1, end: 2).animate(
      CurvedAnimation(parent: _ctrl, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final base   = Theme.of(context).colorScheme.surface;
    final shimmer= Theme.of(context).dividerColor;

    return AnimatedBuilder(
      animation: _anim,
      builder: (_, _) => Container(
        height: widget.height,
        margin: const EdgeInsets.symmetric(vertical: 4),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(8),
          gradient: LinearGradient(
            begin: Alignment.centerLeft,
            end: Alignment.centerRight,
            stops: const [0.0, 0.5, 1.0],
            colors: [base, shimmer, base],
            transform: GradientRotation(_anim.value),
          ),
        ),
      ),
    );
  }
}

class SkeletonList extends StatelessWidget {
  const SkeletonList({super.key, this.count = 8});
  final int count;

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: count,
      itemBuilder: (_, _) => const SkeletonRow(),
    );
  }
}