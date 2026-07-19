import 'package:flutter/material.dart';
import 'package:open_control/core/theme/app_colors.dart';
import 'package:open_control/data/managers/remote_control_manager.dart';

class RecordActions extends StatefulWidget {
  const RecordActions({
    required this.state,
    required this.isStarting,
    required this.isStopping,
    required this.isPausing,
    required this.isResuming,
    required this.isAddingChapter,
    required this.onStart,
    required this.onStop,
    required this.onPause,
    required this.onResume,
    required this.onAddChapter,
    super.key,
  });

  final RecordState state;
  final bool isStarting;
  final bool isStopping;
  final bool isPausing;
  final bool isResuming;
  final bool isAddingChapter;
  final void Function(String? tag) onStart;
  final VoidCallback onStop;
  final VoidCallback onPause;
  final VoidCallback onResume;
  final void Function(String? name) onAddChapter;

  @override
  State<RecordActions> createState() => _RecordActionsState();
}

class _RecordActionsState extends State<RecordActions> {
  final _tagController = TextEditingController();
  final _chapterController = TextEditingController();

  @override
  void dispose() {
    _tagController.dispose();
    _chapterController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isIdle = widget.state == RecordState.idle;
    final isRecording = widget.state == RecordState.recording;
    final isPaused = widget.state == RecordState.paused;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (isIdle) ...[
          TextField(
            controller: _tagController,
            decoration: const InputDecoration(labelText: 'Tag (optional)', hintText: 'e.g. ep12'),
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: widget.isStarting ? null : () => widget.onStart(_tagController.text),
              child: widget.isStarting
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Text('Start'),
            ),
          ),
        ],
        if (isRecording || isPaused) ...[
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: isRecording
                      ? (widget.isPausing ? null : widget.onPause)
                      : (widget.isResuming ? null : widget.onResume),
                  child: Text(isRecording ? 'Pause' : 'Resume'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: OutlinedButton(
                  onPressed: widget.isStopping ? null : widget.onStop,
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.error,
                    side: const BorderSide(color: AppColors.error),
                  ),
                  child: const Text('Stop'),
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          TextField(
            controller: _chapterController,
            enabled: isRecording,
            decoration: const InputDecoration(labelText: 'Chapter name (optional)'),
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: isRecording && !widget.isAddingChapter
                  ? () => widget.onAddChapter(_chapterController.text)
                  : null,
              icon: const Icon(Icons.bookmark_add_outlined, size: 18),
              label: const Text('Add Chapter Marker'),
            ),
          ),
        ],
      ],
    );
  }
}
