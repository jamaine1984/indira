#!/usr/bin/env dart

///
/// Automated Print Statement to LoggerService Converter
///
/// This script converts all print() statements to appropriate LoggerService calls
/// based on context and content analysis.
///
/// Usage:
///   dart scripts/convert_print_to_logger.dart
///
/// What it does:
/// 1. Scans all Dart files in lib/ directory
/// 2. Categorizes print statements by context:
///    - ERROR/FATAL → logger.error()
///    - WARNING → logger.warning()
///    - DEBUG → logger.debug()
///    - INFO → logger.info()
///    - SECURITY → logger.logSecurityEvent()
///    - NETWORK → logger.logNetworkRequest()
/// 3. Adds import if missing: import 'package:indira_love/core/services/logger_service.dart';
/// 4. Creates backup files before modification
///

import 'dart:io';

/// Configuration
const String libPath = 'lib';
const String backupSuffix = '.backup';
const bool dryRun = false; // Set to true for testing without writing

/// Log levels and their indicators
const Map<String, List<String>> logLevelIndicators = {
  'error': ['error', 'exception', 'failed', 'fail', 'crash', 'fatal'],
  'warning': ['warning', 'warn', 'deprecated', 'skipping', 'missing'],
  'debug': ['debug', 'testing', 'test', 'dev', 'development'],
  'security': ['security', 'auth', 'permission', 'unauthorized', 'blocked'],
  'network': ['http', 'api', 'request', 'response', 'fetch', 'post', 'get'],
  'info': [], // Default fallback
};

class PrintConversionStats {
  int filesProcessed = 0;
  int filesModified = 0;
  int printsConverted = 0;
  int importsAdded = 0;

  Map<String, int> levelCounts = {
    'error': 0,
    'warning': 0,
    'debug': 0,
    'info': 0,
    'security': 0,
    'network': 0,
  };

  void print() {
    stdout.writeln('\n' + '=' * 60);
    stdout.writeln('📊 CONVERSION STATISTICS');
    stdout.writeln('=' * 60);
    stdout.writeln('Files processed: $filesProcessed');
    stdout.writeln('Files modified: $filesModified');
    stdout.writeln('Print statements converted: $printsConverted');
    stdout.writeln('LoggerService imports added: $importsAdded');
    stdout.writeln('\nBreakdown by log level:');
    levelCounts.forEach((level, count) {
      if (count > 0) {
        stdout.writeln('  ${_getLevelEmoji(level)} $level: $count');
      }
    });
    stdout.writeln('=' * 60 + '\n');
  }

  String _getLevelEmoji(String level) {
    switch (level) {
      case 'error':
        return '❌';
      case 'warning':
        return '⚠️';
      case 'debug':
        return '🔍';
      case 'security':
        return '🔒';
      case 'network':
        return '🌐';
      default:
        return 'ℹ️';
    }
  }
}

final stats = PrintConversionStats();

void main() async {
  stdout.writeln('🚀 Starting Print Statement Conversion...\n');

  if (dryRun) {
    stdout.writeln('⚠️  DRY RUN MODE - No files will be modified\n');
  }

  final libDir = Directory(libPath);
  if (!await libDir.exists()) {
    stderr.writeln('❌ Error: lib/ directory not found');
    exit(1);
  }

  await processDirectory(libDir);

  stats.print();

  stdout.writeln('✅ Conversion complete!');
  stdout.writeln('\n💡 Next steps:');
  stdout.writeln('  1. Review modified files');
  stdout.writeln('  2. Run: flutter analyze');
  stdout.writeln('  3. Test the app');
  stdout.writeln('  4. If all good, delete .backup files');
  stdout.writeln('\n🔄 To restore backups: find lib -name "*.backup" -exec sh -c \'mv "\$1" "\${1%.backup}"\' _ {} \\;');
}

Future<void> processDirectory(Directory dir) async {
  await for (final entity in dir.list(recursive: true)) {
    if (entity is File && entity.path.endsWith('.dart')) {
      await processFile(entity);
      stats.filesProcessed++;
    }
  }
}

Future<void> processFile(File file) async {
  final content = await file.readAsString();

  // Skip if no print statements
  if (!content.contains(RegExp(r'print\('))) {
    return;
  }

  stdout.writeln('📝 Processing: ${file.path}');

  // Check if LoggerService import exists
  final hasLoggerImport = content.contains(
    "import 'package:indira_love/core/services/logger_service.dart';",
  );

  String modifiedContent = content;
  bool fileModified = false;

  // Add import if missing
  if (!hasLoggerImport) {
    modifiedContent = _addLoggerImport(modifiedContent);
    stats.importsAdded++;
    fileModified = true;
  }

  // Find and replace print statements
  final printRegex = RegExp(
    r'''print\(([^)]*(?:\([^)]*\)[^)]*)*)\);''',
    multiLine: true,
  );

  final matches = printRegex.allMatches(modifiedContent).toList();

  for (final match in matches.reversed) {
    final originalStatement = match.group(0)!;
    final printArgument = match.group(1)!;

    // Determine log level from context
    final logLevel = _determineLogLevel(printArgument, content);

    // Generate replacement
    final replacement = _generateLoggerCall(logLevel, printArgument);

    // Replace in content
    modifiedContent = modifiedContent.replaceRange(
      match.start,
      match.end,
      replacement,
    );

    stats.printsConverted++;
    stats.levelCounts[logLevel] = (stats.levelCounts[logLevel] ?? 0) + 1;
    fileModified = true;

    stdout.writeln('  ${stats._getLevelEmoji(logLevel)} Converted: ${_truncate(originalStatement, 50)} → ${_truncate(replacement, 50)}');
  }

  if (fileModified) {
    if (!dryRun) {
      // Create backup
      final backupFile = File('${file.path}$backupSuffix');
      await file.copy(backupFile.path);

      // Write modified content
      await file.writeAsString(modifiedContent);
    }

    stats.filesModified++;
  }
}

String _addLoggerImport(String content) {
  // Find the first import statement
  final importRegex = RegExp(r'^import\s+.+;$', multiLine: true);
  final firstImport = importRegex.firstMatch(content);

  if (firstImport != null) {
    // Add after the first import
    return content.replaceRange(
      firstImport.end,
      firstImport.end,
      "\nimport 'package:indira_love/core/services/logger_service.dart';",
    );
  } else {
    // Add at the top
    return "import 'package:indira_love/core/services/logger_service.dart';\n\n$content";
  }
}

String _determineLogLevel(String argument, String fileContent) {
  final lowerArg = argument.toLowerCase();

  // Check for error indicators
  if (_containsAny(lowerArg, logLevelIndicators['error']!)) {
    return 'error';
  }

  // Check for warning indicators
  if (_containsAny(lowerArg, logLevelIndicators['warning']!)) {
    return 'warning';
  }

  // Check for security indicators
  if (_containsAny(lowerArg, logLevelIndicators['security']!)) {
    return 'security';
  }

  // Check for network indicators
  if (_containsAny(lowerArg, logLevelIndicators['network']!)) {
    return 'network';
  }

  // Check for debug indicators or if in try-catch block
  if (_containsAny(lowerArg, logLevelIndicators['debug']!) ||
      lowerArg.contains('[debug]') ||
      lowerArg.contains('test')) {
    return 'debug';
  }

  // Check file path context
  if (fileContent.contains('catch') || fileContent.contains('Exception')) {
    if (lowerArg.contains('error') || lowerArg.contains('exception')) {
      return 'error';
    }
  }

  // Default to info
  return 'info';
}

bool _containsAny(String text, List<String> keywords) {
  return keywords.any((keyword) => text.contains(keyword));
}

String _generateLoggerCall(String logLevel, String argument) {
  switch (logLevel) {
    case 'error':
      return 'logger.error($argument);';
    case 'warning':
      return 'logger.warning($argument);';
    case 'debug':
      return 'logger.debug($argument);';
    case 'security':
      return 'logger.logSecurityEvent($argument);';
    case 'network':
      // Try to extract HTTP method and URL if present
      return 'logger.info($argument); // TODO: Use logger.logNetworkRequest if network call';
    case 'info':
    default:
      return 'logger.info($argument);';
  }
}

String _truncate(String text, int maxLength) {
  if (text.length <= maxLength) return text;
  return '${text.substring(0, maxLength)}...';
}
