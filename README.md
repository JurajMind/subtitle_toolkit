# Subtitle Toolkit

A Flutter package for parsing, manipulating, and managing subtitle files. Currently supports SRT format with features for timing adjustments, speed modifications, and subtitle merging.

## Features

- Parse SRT files and strings into structured subtitle entries
- Convert subtitle entries back to SRT format
- Shift subtitle timings forward or backward
- Adjust playback speed of subtitles
- Merge overlapping subtitles
- Type-safe subtitle entry model with equality support
- Error handling using Either type from dartz

## Getting started

Add this package to your Flutter project by adding the following to your `pubspec.yaml`:

```yaml
dependencies:
  subtitle_toolkit: ^0.0.1
```

## Usage

### Parse SRT content

```dart
import 'package:subtitle_toolkit/subtitle_toolkit.dart';

// Parse from string
final result = SubtitleParser.parseString(srtContent);
result.fold(
  (error) => print('Error: $error'),
  (entries) => print('Parsed ${entries.length} subtitles'),
);

// Parse from file
final fileResult = await SubtitleParser.parseFile('path/to/file.srt');
fileResult.fold(
  (error) => print('Error: $error'),
  (entries) => print('Parsed ${entries.length} subtitles'),
);

// Parse from URL
final urlResult = await SubtitleParser.parseUrl('https://example.com/subtitles.srt');
urlResult.fold(
  (error) => print('Error: $error'),
  (entries) => print('Downloaded and parsed ${entries.length} subtitles'),
);
```

### Modify timings

```dart
// Shift all subtitles forward by 2 seconds
final shifted = SubtitleParser.shiftTimings(entries, Duration(seconds: 2));

// Make subtitles play 50% faster
final faster = SubtitleParser.adjustSpeed(entries, 1.5);

// Merge overlapping subtitles
final merged = SubtitleParser.mergeOverlapping(entries);
```

### Convert back to SRT

```dart
// Convert to SRT string
final srtString = SubtitleParser.entriesToString(entries);

// Write to file
final writeResult = await SubtitleParser.writeToFile(entries, 'output.srt');
writeResult.fold(
  (error) => print('Error: $error'),
  (_) => print('Successfully wrote to file'),
);
```

## Additional information

### Features

- Parse SRT files, strings, and URLs
- Convert subtitles to SRT format
- Shift subtitle timings
- Adjust playback speed
- Merge overlapping subtitles
- Enforce minimum subtitle duration
- Type-safe subtitle entry model
- Error handling using Either type

### Supported formats

Currently supports SRT (SubRip) format. Future versions may add support for additional subtitle formats like WebVTT, SSA/ASS, etc.

### Error Handling

All parsing methods (parseString, parseFile, parseUrl) return an Either type, providing clear error messages when something goes wrong:

```dart
final result = await SubtitleParser.parseUrl('https://example.com/subtitles.srt');
result.fold(
  (error) {
    // Handle errors (e.g., HTTP errors, invalid format)
    print('Failed to parse subtitles: $error');
  },
  (entries) {
    // Process valid subtitles
    for (final entry in entries) {
      print('${entry.startTime} -> ${entry.endTime}: ${entry.text}');
    }
  },
);
```

### Contributing

Contributions are welcome! Please feel free to submit a Pull Request.

### License

This project is licensed under the MIT License - see the LICENSE file for details.
