import 'package:flutter/material.dart';
import '../../data/mocks/milestones.dart';

/// Displays a brief overlay toast when a milestone is unlocked.
/// Auto-dismisses after [duration].
class MilestoneToast extends StatefulWidget {
  final Milestone milestone;
  final Duration duration;
  final VoidCallback? onDismissed;

  const MilestoneToast({
    super.key,
    required this.milestone,
    this.duration = const Duration(seconds: 3),
    this.onDismissed,
  });

  @override
  State<MilestoneToast> createState() => _MilestoneToastState();
}

class _MilestoneToastState extends State<MilestoneToast>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _fade;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 400));
    _fade = CurvedAnimation(parent: _ctrl, curve: Curves.easeOut);
    _ctrl.forward();

    Future.delayed(widget.duration - const Duration(milliseconds: 400), () {
      if (mounted) {
        _ctrl.reverse().then((_) {
          if (mounted) widget.onDismissed?.call();
        });
      }
    });
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _fade,
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 24),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
        decoration: BoxDecoration(
          color: const Color(0xFF230A0C),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0xFFFFD700), width: 1.5),
          boxShadow: [
            BoxShadow(
                color: const Color(0xFFFFD700).withValues(alpha: 0.25),
                blurRadius: 16,
                spreadRadius: 2),
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.military_tech, color: Color(0xFFFFD700), size: 32),
            const SizedBox(width: 12),
            Flexible(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text(
                    'MILESTONE UNLOCKED',
                    style: TextStyle(
                      color: Color(0xFFFFD700),
                      fontSize: 11,
                      letterSpacing: 2,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  Text(
                    widget.milestone.title,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 17,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  Text(
                    widget.milestone.description,
                    style: const TextStyle(
                      color: Colors.white60,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Shows milestone toasts one-by-one in a queue over the game screen.
class MilestoneToastQueue extends StatefulWidget {
  final List<Milestone> milestones;

  const MilestoneToastQueue({super.key, required this.milestones});

  @override
  State<MilestoneToastQueue> createState() => _MilestoneToastQueueState();
}

class _MilestoneToastQueueState extends State<MilestoneToastQueue> {
  int _current = 0;

  @override
  Widget build(BuildContext context) {
    if (_current >= widget.milestones.length) return const SizedBox.shrink();
    return Positioned(
      top: 100,
      left: 0,
      right: 0,
      child: Center(
        child: MilestoneToast(
          key: ValueKey(_current),
          milestone: widget.milestones[_current],
          onDismissed: () {
            if (mounted) setState(() => _current++);
          },
        ),
      ),
    );
  }
}
