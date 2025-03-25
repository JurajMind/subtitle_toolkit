import 'dart:convert';
import 'dart:io';

import 'package:dartz/dartz.dart';
import 'package:http/http.dart' as http;

import '../models/subtitle_entry.dart';

class SubtitleParser {
  /// Parses an SRT file content and returns a list of SubtitleEntry objects
  static Either<String, List<SubtitleEntry>> parseString(String content) {
    try {
      if (content.trim().isEmpty) {
        return const Left('Empty content');
      }

      final List<SubtitleEntry> entries = [];
      final lines = content.trim().split('\n');

      if (lines.isEmpty) {
        return const Left('No content found');
      }

      int currentIndex = -1;
      Duration? currentStartTime;
      Duration? currentEndTime;
      StringBuffer currentText = StringBuffer();

      for (int i = 0; i < lines.length; i++) {
        final line = lines[i].trim();
        if (line.isEmpty) {
          // End of current subtitle block
          if (currentIndex != -1 && currentStartTime != null && currentEndTime != null && currentText.isNotEmpty) {
            entries.add(
              SubtitleEntry(
                index: currentIndex,
                startTime: currentStartTime,
                endTime: currentEndTime,
                text: currentText.toString().trim(),
              ),
            );
            currentIndex = -1;
            currentStartTime = null;
            currentEndTime = null;
            currentText.clear();
          }
          continue;
        }

        try {
          // Try parse as index
          final parsedIndex = int.tryParse(line);
          if (parsedIndex != null) {
            // End previous subtitle if exists
            if (currentIndex != -1 && currentStartTime != null && currentEndTime != null && currentText.isNotEmpty) {
              entries.add(
                SubtitleEntry(
                  index: currentIndex,
                  startTime: currentStartTime,
                  endTime: currentEndTime,
                  text: currentText.toString().trim(),
                ),
              );
              currentText.clear();
            }
            currentIndex = parsedIndex;
            continue;
          }

          // Try parse as time range
          if (line.contains(' --> ')) {
            final timeRange = line.split(' --> ');
            if (timeRange.length == 2) {
              currentStartTime = SubtitleEntry.parseTimeString(timeRange[0]);
              currentEndTime = SubtitleEntry.parseTimeString(timeRange[1]);
              continue;
            }
          }

          // Must be subtitle text
          if (currentIndex != -1) {
            if (currentText.isNotEmpty) {
              currentText.write('\n');
            }
            currentText.write(line);
          }
        } catch (e) {
          // Skip invalid lines
          continue;
        }
      }

      // Add last subtitle if exists
      if (currentIndex != -1 && currentStartTime != null && currentEndTime != null && currentText.isNotEmpty) {
        entries.add(
          SubtitleEntry(
            index: currentIndex,
            startTime: currentStartTime,
            endTime: currentEndTime,
            text: currentText.toString().trim(),
          ),
        );
      }

      if (entries.isEmpty) {
        return const Left('No valid subtitles found');
      }

      return Right(entries);
    } catch (e) {
      return Left('Failed to parse SRT content: $e');
    }
  }

  /// Reads an SRT file and returns a list of SubtitleEntry objects
  static Future<Either<String, List<SubtitleEntry>>> parseFile(String filePath) async {
    try {
      final file = File(filePath);
      if (!await file.exists()) {
        return Left('File not found: $filePath');
      }
      final content = await file.readAsString();
      return parseString(content);
    } catch (e) {
      return Left('Failed to read SRT file: $e');
    }
  }

  /// Converts a list of SubtitleEntry objects to SRT format string
  static String entriesToString(List<SubtitleEntry> entries) {
    final buffer = StringBuffer();

    for (var i = 0; i < entries.length; i++) {
      final entry = entries[i];

      // Add index
      buffer.writeln(entry.index);

      // Add time range
      buffer.writeln(
        '${SubtitleEntry.formatDuration(entry.startTime)} --> ${SubtitleEntry.formatDuration(entry.endTime)}',
      );

      // Add text
      buffer.writeln(entry.text);

      // Add blank line between entries
      if (i < entries.length - 1) {
        buffer.writeln();
      }
    }

    return buffer.toString();
  }

  /// Writes a list of SubtitleEntry objects to an SRT file
  static Future<Either<String, bool>> writeToFile(List<SubtitleEntry> entries, String filePath) async {
    try {
      final file = File(filePath);
      await file.writeAsString(entriesToString(entries));
      return const Right(true);
    } catch (e) {
      return Left('Failed to write SRT file: $e');
    }
  }

  /// Shifts all subtitle timings by the specified duration
  static List<SubtitleEntry> shiftTimings(List<SubtitleEntry> entries, Duration shift) {
    return entries
        .map((entry) => entry.copyWith(startTime: entry.startTime + shift, endTime: entry.endTime + shift))
        .toList();
  }

  /// Adjusts subtitle timings by a speed factor (e.g., 1.5 for 50% faster)
  static List<SubtitleEntry> adjustSpeed(List<SubtitleEntry> entries, double factor) {
    return entries
        .map(
          (entry) => entry.copyWith(
            startTime: Duration(milliseconds: (entry.startTime.inMilliseconds * factor).round()),
            endTime: Duration(milliseconds: (entry.endTime.inMilliseconds * factor).round()),
          ),
        )
        .toList();
  }

  /// Ensures all subtitles meet a minimum duration by merging short subtitles
  /// with their neighbors. This is useful for ensuring subtitles are displayed
  /// long enough to be readable.
  static List<SubtitleEntry> enforceMinimumDuration(
    List<SubtitleEntry> entries,
    Duration minimumDuration, {
    int subtitlesToSkipLimit = 3,
    bool removeNewlines = true,
  }) {
    if (entries.isEmpty) return [];

    final List<SubtitleEntry> result = [];
    var current = entries.first;

    var i = 0;
    while (i < entries.length) {
      current = entries[i];
      final currentDuration = current.endTime - current.startTime;

      if (currentDuration < minimumDuration && i < entries.length - 1) {
        // Look ahead for a subtitle that would make this one long enough
        var mergedText = current.text;
        var mergedEndTime = current.endTime;
        var foundLongEnough = false;
        var subtitlesToSkip = 0;

        // Try merging with subsequent subtitles until we reach minimum duration
        for (var j = i + 1; j < entries.length; j++) {
          final next = entries[j];
          final potentialDuration = next.endTime - current.startTime;

          mergedText = '$mergedText${removeNewlines ? ' ' : '\n'}${next.text}';
          mergedEndTime = next.endTime;
          subtitlesToSkip = j - i;

          if (potentialDuration >= minimumDuration) {
            foundLongEnough = true;
            break;
          }

          // Limit how many subtitles we merge to avoid creating too-long subtitles
          if (subtitlesToSkip >= subtitlesToSkipLimit) break;
        }

        if (foundLongEnough) {
          // Add the merged subtitle
          result.add(current.copyWith(endTime: mergedEndTime, text: mergedText));
          i += subtitlesToSkip + 1; // Skip the subtitles we merged
        } else {
          // If we couldn't find a long enough combination, keep the subtitle as is
          result.add(current);
          i++;
        }
      } else {
        // Add current subtitle if it's long enough or it's the last one
        result.add(current);
        i++;
      }
    }

    // Reindex entries
    return result.asMap().entries.map((e) => e.value.copyWith(index: e.key + 1)).toList();
  }

  /// Downloads and parses subtitles from a URL
  /// Returns Either an error message or a list of parsed subtitle entries
  /// Optionally accepts a custom HTTP client for testing
  static Future<Either<String, List<SubtitleEntry>>> parseUrl(String url, {http.Client? client}) async {
    try {
      final response = await (client ?? http.Client()).get(Uri.parse(url));

      if (response.statusCode != 200) {
        return Left('Failed to download subtitles: HTTP ${response.statusCode}');
      }

      return parseString(utf8.decode(response.bodyBytes));
    } catch (e) {
      return Left('Failed to download subtitles: $e');
    }
  }

  /// Merges overlapping subtitles into single entries
  static List<SubtitleEntry> mergeOverlapping(List<SubtitleEntry> entries) {
    if (entries.isEmpty) return [];

    final List<SubtitleEntry> merged = [];
    var current = entries.first;

    for (var i = 1; i < entries.length; i++) {
      final next = entries[i];

      if (current.endTime >= next.startTime) {
        // Merge overlapping entries
        current = current.copyWith(endTime: next.endTime, text: '${current.text}\n${next.text}');
      } else {
        merged.add(current);
        current = next;
      }
    }

    merged.add(current);

    // Reindex entries
    return merged.asMap().entries.map((e) => e.value.copyWith(index: e.key + 1)).toList();
  }
}
