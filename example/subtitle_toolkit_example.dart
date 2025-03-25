import 'package:subtitle_toolkit/subtitle_toolkit.dart';

void main() async {
  // Parse subtitles from file
  final result = await SubtitleParser.parseFile('example/sample.srt');

  result.fold((error) => print('Error: $error'), (subtitles) {
    print('Original subtitles:');
    print(SubtitleParser.entriesToString(subtitles));

    // Demonstrate various transformations

    // 1. Shift all subtitles forward by 2 seconds
    final shiftedSubtitles = SubtitleParser.shiftTimings(
      subtitles,
      const Duration(seconds: 2),
    );
    print('\nShifted subtitles (+2 seconds):');
    print(SubtitleParser.entriesToString(shiftedSubtitles));

    // 2. Speed up subtitles by 50%
    final speedAdjustedSubtitles = SubtitleParser.adjustSpeed(subtitles, 1.5);
    print('\nSpeed adjusted subtitles (1.5x):');
    print(SubtitleParser.entriesToString(speedAdjustedSubtitles));

    // 3. Enforce minimum duration of 2 seconds
    final minDurationSubtitles = SubtitleParser.enforceMinimumDuration(
      subtitles,
      const Duration(seconds: 2),
    );
    print('\nSubtitles with minimum 2-second duration:');
    print(SubtitleParser.entriesToString(minDurationSubtitles));

    // 4. Merge overlapping subtitles
    final mergedSubtitles = SubtitleParser.mergeOverlapping(subtitles);
    print('\nMerged overlapping subtitles:');
    print(SubtitleParser.entriesToString(mergedSubtitles));

    // Save modified subtitles to a new file
    SubtitleParser.writeToFile(shiftedSubtitles, 'example/shifted_output.srt');
  });

  // Example of parsing from string
  const srtString = '''1
00:00:01,000 --> 00:00:04,000
Test subtitle''';

  final stringResult = SubtitleParser.parseString(srtString);
  stringResult.fold(
    (error) => print('Error parsing string: $error'),
    (subtitles) => print('\nParsed from string: ${subtitles.first.text}'),
  );
}
