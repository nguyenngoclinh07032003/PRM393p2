import 'dart:async';

import 'package:flutter/material.dart';

import '../../backend/models/flash_sale.dart';

class FlashSaleCountdown extends StatefulWidget {
  const FlashSaleCountdown({
    super.key,
    required this.startTime,
    required this.endTime,
    this.style,
    this.activePrefix = 'Kết thúc sau',
    this.upcomingPrefix = 'Bắt đầu sau',
    this.endedText = 'Đã kết thúc',
    this.unknownText = 'Đang cập nhật thời gian',
    this.phase,
    this.slotRangeText,
    this.showSlotRange = true,
  });

  final DateTime? startTime;
  final DateTime? endTime;
  final TextStyle? style;
  final String activePrefix;
  final String upcomingPrefix;
  final String endedText;
  final String unknownText;
  final FlashSaleCountdownPhase? phase;
  final String? slotRangeText;
  final bool showSlotRange;

  @override
  State<FlashSaleCountdown> createState() => _FlashSaleCountdownState();
}

class _FlashSaleCountdownState extends State<FlashSaleCountdown> {
  Timer? _timer;
  DateTime _now = DateTime.now();

  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) {
        setState(() => _now = DateTime.now());
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final baseStyle = widget.style ?? const TextStyle();
    final slotStyle = baseStyle.copyWith(
      fontSize: (baseStyle.fontSize ?? 14) - 1,
      fontWeight: FontWeight.w600,
    );
    final clockStyle = baseStyle.copyWith(
      fontFeatures: const [FontFeature.tabularFigures()],
      letterSpacing: 0.4,
    );

    final content = _buildContent(clockStyle);

    if (widget.showSlotRange &&
        widget.slotRangeText != null &&
        widget.slotRangeText!.isNotEmpty) {
      return RepaintBoundary(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Khung giờ: ${widget.slotRangeText}', style: slotStyle),
            const SizedBox(height: 4),
            content,
          ],
        ),
      );
    }

    return RepaintBoundary(child: content);
  }

  Widget _buildContent(TextStyle clockStyle) {
    final startTime = widget.startTime;
    final endTime = widget.endTime;

    if (startTime == null && endTime == null) {
      return Text(widget.unknownText, style: widget.style);
    }

    if (widget.phase == FlashSaleCountdownPhase.beforeCampaign &&
        startTime != null) {
      final date =
          '${startTime.day.toString().padLeft(2, '0')}/${startTime.month.toString().padLeft(2, '0')}';
      final clock =
          '${startTime.hour.toString().padLeft(2, '0')}:${startTime.minute.toString().padLeft(2, '0')}';
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            '${widget.upcomingPrefix} $date lúc $clock',
            style: widget.style,
          ),
          const SizedBox(height: 2),
          _CountdownClockLine(
            prefix: '',
            clock: _formatClock(startTime.difference(_now)),
            style: widget.style,
            clockStyle: clockStyle,
          ),
        ],
      );
    }

    if (endTime != null && !_now.isBefore(endTime)) {
      return Text(widget.endedText, style: widget.style);
    }

    if (startTime != null && _now.isBefore(startTime)) {
      return _CountdownClockLine(
        prefix: widget.upcomingPrefix,
        clock: _formatClock(startTime.difference(_now)),
        style: widget.style,
        clockStyle: clockStyle,
      );
    }

    if (endTime != null) {
      return _CountdownClockLine(
        prefix: widget.activePrefix,
        clock: _formatClock(endTime.difference(_now)),
        style: widget.style,
        clockStyle: clockStyle,
      );
    }

    if (startTime != null) {
      return _CountdownClockLine(
        prefix: widget.upcomingPrefix,
        clock: _formatClock(startTime.difference(_now)),
        style: widget.style,
        clockStyle: clockStyle,
      );
    }

    return Text(widget.unknownText, style: widget.style);
  }

  String _formatClock(Duration duration) {
    final safe = duration.isNegative ? Duration.zero : duration;
    final days = safe.inDays;
    final hours = safe.inHours % 24;
    final minutes = safe.inMinutes % 60;
    final seconds = safe.inSeconds % 60;
    final clock =
        '${hours.toString().padLeft(2, '0')}:${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
    if (days > 0) {
      return '${days}d $clock';
    }
    return clock;
  }
}

class _CountdownClockLine extends StatelessWidget {
  const _CountdownClockLine({
    required this.prefix,
    required this.clock,
    required this.style,
    required this.clockStyle,
  });

  final String prefix;
  final String clock;
  final TextStyle? style;
  final TextStyle clockStyle;

  static const double _clockWidth = 88;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (prefix.isNotEmpty) ...[
          Text('$prefix ', style: style),
        ],
        SizedBox(
          width: _clockWidth,
          child: Text(
            clock,
            style: clockStyle,
            maxLines: 1,
            overflow: TextOverflow.clip,
          ),
        ),
      ],
    );
  }
}
