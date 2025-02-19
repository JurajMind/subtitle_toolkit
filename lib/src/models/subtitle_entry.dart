import 'package:equatable/equatable.dart';

class SubtitleEntry extends Equatable {
  const SubtitleEntry({required this.index, required this.startTime, required this.endTime, required this.text});
  final int index;
  final Duration startTime;
  final Duration endTime;
  final String text;

  @override
  List<Object?> get props => [index, startTime, endTime, text];

  SubtitleEntry copyWith({int? index, Duration? startTime, Duration? endTime, String? text}) {
    return SubtitleEntry(
      index: index ?? this.index,
      startTime: startTime ?? this.startTime,
      endTime: endTime ?? this.endTime,
      text: text ?? this.text,
    );
  }

  static Duration parseTimeString(String timeStr) {
    final parts = timeStr.split(':');
    final secondsAndMillis = parts[2].split(',');

    final hours = int.parse(parts[0]);
    final minutes = int.parse(parts[1]);
    final seconds = int.parse(secondsAndMillis[0]);
    final milliseconds = int.parse(secondsAndMillis[1]);

    return Duration(hours: hours, minutes: minutes, seconds: seconds, milliseconds: milliseconds);
  }

  static String formatDuration(Duration duration) {
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    String threeDigits(int n) => n.toString().padLeft(3, '0');

    final hours = twoDigits(duration.inHours);
    final minutes = twoDigits(duration.inMinutes.remainder(60));
    final seconds = twoDigits(duration.inSeconds.remainder(60));
    final milliseconds = threeDigits(duration.inMilliseconds.remainder(1000));

    return '$hours:$minutes:$seconds,$milliseconds';
  }
}
