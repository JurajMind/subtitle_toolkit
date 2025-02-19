import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:subtitle_toolkit/subtitle_toolkit.dart';

/// Tests for the subtitle_toolkit package.
/// Covers core functionality including parsing, formatting,
/// and utility operations on subtitle entries.
void main() {
  group('SubtitleParser', () {
    test('parseString successfully parses valid SRT content', () {
      final srtContent = '''1
00:00:01,000 --> 00:00:04,000
Hello world!

2
00:00:05,000 --> 00:00:08,000
This is a test subtitle
With multiple lines''';

      final result = SubtitleParser.parseString(srtContent);

      expect(result.isRight(), true);
      final entries = result.getOrElse(() => []);
      expect(entries.length, 2);

      expect(entries[0].index, 1);
      expect(entries[0].startTime, Duration(seconds: 1));
      expect(entries[0].endTime, Duration(seconds: 4));
      expect(entries[0].text, 'Hello world!');

      expect(entries[1].index, 2);
      expect(entries[1].startTime, Duration(seconds: 5));
      expect(entries[1].endTime, Duration(seconds: 8));
      expect(entries[1].text, 'This is a test subtitle\nWith multiple lines');
    });

    test('parseString returns Left for invalid SRT content', () {
      final invalidContent = '''Invalid
content''';

      final result = SubtitleParser.parseString(invalidContent);
      expect(result.isLeft(), true);
    });

    test('entriesToString formats entries correctly', () {
      final entries = [
        SubtitleEntry(index: 1, startTime: Duration(seconds: 1), endTime: Duration(seconds: 4), text: 'Hello world!'),
        SubtitleEntry(
          index: 2,
          startTime: Duration(seconds: 5),
          endTime: Duration(seconds: 8),
          text: 'Second subtitle',
        ),
      ];

      final srtString = SubtitleParser.entriesToString(entries);
      expect(srtString.contains('1'), true);
      expect(srtString.contains('00:00:01,000 --> 00:00:04,000'), true);
      expect(srtString.contains('Hello world!'), true);
      expect(srtString.contains('2'), true);
      expect(srtString.contains('00:00:05,000 --> 00:00:08,000'), true);
      expect(srtString.contains('Second subtitle'), true);
    });

    test('shiftTimings shifts all timings correctly', () {
      final entries = [
        SubtitleEntry(index: 1, startTime: Duration(seconds: 1), endTime: Duration(seconds: 4), text: 'Test'),
      ];

      final shifted = SubtitleParser.shiftTimings(entries, Duration(seconds: 2));
      expect(shifted[0].startTime, Duration(seconds: 3));
      expect(shifted[0].endTime, Duration(seconds: 6));
    });

    test('adjustSpeed modifies timings correctly', () {
      final entries = [
        SubtitleEntry(index: 1, startTime: Duration(seconds: 2), endTime: Duration(seconds: 4), text: 'Test'),
      ];

      final adjusted = SubtitleParser.adjustSpeed(entries, 2.0);
      expect(adjusted[0].startTime, Duration(seconds: 4));
      expect(adjusted[0].endTime, Duration(seconds: 8));
    });

    test('enforceMinimumDuration merges multiple short subtitles with spaces by default', () {
      final entries = [
        SubtitleEntry(index: 1, startTime: Duration(seconds: 1), endTime: Duration(seconds: 2), text: 'First short'),
        SubtitleEntry(index: 2, startTime: Duration(seconds: 3), endTime: Duration(seconds: 4), text: 'Second short'),
        SubtitleEntry(index: 3, startTime: Duration(seconds: 5), endTime: Duration(seconds: 6), text: 'Third short'),
        SubtitleEntry(index: 4, startTime: Duration(seconds: 7), endTime: Duration(seconds: 12), text: 'Long enough'),
        SubtitleEntry(index: 5, startTime: Duration(seconds: 13), endTime: Duration(seconds: 14), text: 'Final short'),
      ];

      final minimumDuration = Duration(seconds: 5);
      final result = SubtitleParser.enforceMinimumDuration(entries, minimumDuration);

      expect(result.length, 3);

      // First three short subtitles should be merged since they need 5 seconds
      expect(result[0].startTime, Duration(seconds: 1));
      expect(result[0].endTime, Duration(seconds: 6));
      expect(result[0].text, 'First short Second short Third short');

      // Long subtitle should remain as is
      expect(result[1].startTime, Duration(seconds: 7));
      expect(result[1].endTime, Duration(seconds: 12));
      expect(result[1].text, 'Long enough');

      // Last short subtitle should remain as is since it can't be merged
      expect(result[2].startTime, Duration(seconds: 13));
      expect(result[2].endTime, Duration(seconds: 14));
      expect(result[2].text, 'Final short');
    });

    test('enforceMinimumDuration can preserve newlines when merging', () {
      final entries = [
        SubtitleEntry(index: 1, startTime: Duration(seconds: 1), endTime: Duration(seconds: 2), text: 'First short'),
        SubtitleEntry(index: 2, startTime: Duration(seconds: 3), endTime: Duration(seconds: 4), text: 'Second short'),
        SubtitleEntry(index: 3, startTime: Duration(seconds: 5), endTime: Duration(seconds: 6), text: 'Third short'),
      ];

      final minimumDuration = Duration(seconds: 5);
      final result = SubtitleParser.enforceMinimumDuration(entries, minimumDuration, removeNewlines: false);

      expect(result.length, 1);
      expect(result[0].startTime, Duration(seconds: 1));
      expect(result[0].endTime, Duration(seconds: 6));
      expect(result[0].text, 'First short\nSecond short\nThird short');
    });

    test('enforceMinimumDuration handles single short subtitle', () {
      final entries = [
        SubtitleEntry(index: 1, startTime: Duration(seconds: 1), endTime: Duration(seconds: 2), text: 'Short'),
      ];

      final minimumDuration = Duration(seconds: 3);
      final result = SubtitleParser.enforceMinimumDuration(entries, minimumDuration);

      expect(result.length, 1);
      expect(result[0].startTime, Duration(seconds: 1));
      expect(result[0].endTime, Duration(seconds: 2));
      expect(result[0].text, 'Short');
    });

    test('mergeOverlapping combines overlapping subtitles', () {
      final entries = [
        SubtitleEntry(index: 1, startTime: Duration(seconds: 1), endTime: Duration(seconds: 4), text: 'First'),
        SubtitleEntry(index: 2, startTime: Duration(seconds: 3), endTime: Duration(seconds: 6), text: 'Second'),
      ];

      final merged = SubtitleParser.mergeOverlapping(entries);
      expect(merged.length, 1);
      expect(merged[0].startTime, Duration(seconds: 1));
      expect(merged[0].endTime, Duration(seconds: 6));
      expect(merged[0].text, 'First\nSecond');
    });

    group('parseUrl', () {
      late http.Client mockClient;

      setUp(() {
        mockClient = MockClient((request) async {
          if (request.url.toString() == 'https://example.com/valid.srt') {
            return http.Response('''1
00:00:01,000 --> 00:00:04,000
Test subtitle''', 200);
          } else if (request.url.toString() == 'https://example.com/invalid.srt') {
            return http.Response('Invalid content', 200);
          } else {
            return http.Response('Not found', 404);
          }
        });
      });

      test('successfully downloads and parses valid SRT from URL', () async {
        final result = await SubtitleParser.parseUrl('https://example.com/valid.srt', client: mockClient);
        expect(result.isRight(), true);

        final entries = result.getOrElse(() => []);
        expect(entries.length, 1);
        expect(entries[0].text, 'Test subtitle');
      });

      test('returns Left for invalid SRT content from URL', () async {
        final result = await SubtitleParser.parseUrl('https://example.com/invalid.srt', client: mockClient);
        expect(result.isLeft(), true);
      });

      test('returns Left for failed HTTP request', () async {
        final result = await SubtitleParser.parseUrl('https://example.com/notfound.srt', client: mockClient);
        expect(result.isLeft(), true);
        result.fold((error) => expect(error.contains('404'), true), (_) => fail('Expected Left with 404 error'));
      });
    });
  });

  group('SubtitleEntry', () {
    test('parseTimeString correctly parses time string', () {
      final duration = SubtitleEntry.parseTimeString('01:30:45,500');
      expect(duration.inHours, 1);
      expect(duration.inMinutes % 60, 30);
      expect(duration.inSeconds % 60, 45);
      expect(duration.inMilliseconds % 1000, 500);
    });

    test('formatDuration correctly formats duration', () {
      final duration = Duration(hours: 1, minutes: 30, seconds: 45, milliseconds: 500);
      final formatted = SubtitleEntry.formatDuration(duration);
      expect(formatted, '01:30:45,500');
    });

    test('copyWith creates new instance with updated values', () {
      final entry = SubtitleEntry(
        index: 1,
        startTime: Duration(seconds: 1),
        endTime: Duration(seconds: 4),
        text: 'Test',
      );

      final copied = entry.copyWith(index: 2, text: 'Updated');

      expect(copied.index, 2);
      expect(copied.startTime, entry.startTime);
      expect(copied.endTime, entry.endTime);
      expect(copied.text, 'Updated');
    });
  });
}
