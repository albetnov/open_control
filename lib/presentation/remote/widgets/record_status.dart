import 'package:flutter/material.dart';
import 'package:open_control/core/theme/app_colors.dart';
import 'package:open_control/core/theme/app_theme_colors.dart';
import 'package:open_control/data/managers/remote_control_manager.dart';

class RecordStatus extends StatelessWidget {
  const RecordStatus({required this.state, super.key});

  final RecordState state;

  @override
  Widget build(BuildContext context) {
    final label = switch (state) {
      RecordState.recording => 'Recording',
      RecordState.paused => 'Paused',
      RecordState.idle => 'Idle',
      RecordState.unknown => 'Syncing…',
    };

    return Row(
      children: [
        _PulseDot(active: state == RecordState.recording),
        const SizedBox(width: 10),
        Text(label, style: Theme.of(context).textTheme.headlineSmall),
      ],
    );
  }
}

class _PulseDot extends StatefulWidget {
  const _PulseDot({required this.active});

  final bool active;

  @override
  State<_PulseDot> createState() => _PulseDotState();
}

class _PulseDotState extends State<_PulseDot> with SingleTickerProviderStateMixin {
  late final _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 900),
  );

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _syncAnimation();
  }

  @override
  void didUpdateWidget(_PulseDot oldWidget) {
    super.didUpdateWidget(oldWidget);
    _syncAnimation();
  }

  void _syncAnimation() {
    final reduceMotion = MediaQuery.of(context).disableAnimations;
    if (widget.active && !reduceMotion) {
      if (!_controller.isAnimating) _controller.repeat(reverse: true);
    } else {
      _controller.stop();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!widget.active) {
      return _dot(context, filled: false);
    }
    return FadeTransition(
      opacity: Tween(
        begin: 0.45,
        end: 1.0,
      ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut)),
      child: _dot(context, filled: true),
    );
  }

  Widget _dot(BuildContext context, {required bool filled}) {
    return SizedBox(
      width: 12,
      height: 12,
      child: DecoratedBox(
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: filled ? AppColors.amber : Colors.transparent,
          border: filled ? null : Border.all(color: context.borderColor, width: 1.5),
        ),
      ),
    );
  }
}
