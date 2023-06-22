import 'package:flutter/foundation.dart' show listEquals;
import 'package:flutter/services.dart' show rootBundle;

abstract class ResourceLoader {
  Iterable<String> get patternsStrings;

  Iterable<String> get exceptionsStrings;
}

enum DefaultResourceLoaderLanguage {
  enUs,
  de1996,
  da,
  fr,
}

/// Files from: https://tug.org/tex-hyphen/
class DefaultResourceLoader extends ResourceLoader {
  DefaultResourceLoader._(
    this._patterns,
    this._exceptions,
  );

  final Iterable<String> _patterns;
  final Iterable<String> _exceptions;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is DefaultResourceLoader &&
          runtimeType == other.runtimeType &&
          listEquals(
            _exceptions.toList(
              growable: false,
            ),
            other._exceptions.toList(
              growable: false,
            ),
          ) &&
          listEquals(
            _patterns.toList(
              growable: false,
            ),
            other._patterns.toList(
              growable: false,
            ),
          );

  @override
  int get hashCode => Object.hash(
        _exceptions,
        _patterns,
      );

  @override
  String toString() => 'DefaultHyphenatorResourceLoader{'
      '_exceptions: $_exceptions, '
      '_patterns: $_patterns'
      '}';

  @override
  Iterable<String> get exceptionsStrings => _exceptions;

  @override
  Iterable<String> get patternsStrings => _patterns;

  static Future<DefaultResourceLoader> load([
    DefaultResourceLoaderLanguage lang = DefaultResourceLoaderLanguage.enUs,
  ]) async {
    return await rootBundle.loadStructuredData(
      'packages/hyphenator_impure/hyphenate_patterns/${lang._fileName}',
      (value) async {
        final lines = value
            .split('\n')
            .where(
              (e) => e.isNotEmpty && !e.startsWith('%'),
            )
            .map(
              (e) => e.trim(),
            );

        final pat = <String>[];
        final exc = <String>[];

        bool isNextPattern = false;
        bool isNextException = false;

        for (final line in lines) {
          if (line.startsWith('}')) {
            isNextPattern = false;
            isNextException = false;
          } else if (!isNextPattern && line.startsWith('\\patterns')) {
            isNextPattern = true;
          } else if (!isNextException && line.startsWith('\\hyphenation')) {
            isNextException = true;
          } else if (isNextPattern && !isNextException) {
            pat.add(line);
          } else if (isNextException) {
            exc.add(line);
          }
        }
        return DefaultResourceLoader._(
          pat,
          exc,
        );
      },
    );
  }
}

extension on DefaultResourceLoaderLanguage {
  static String _name(String lang) => 'hyph-$lang.tex';

  String get _fileName {
    switch (this) {
      case DefaultResourceLoaderLanguage.enUs:
        return _name('en-us');
      case DefaultResourceLoaderLanguage.de1996:
        return _name('de-1996');
      case DefaultResourceLoaderLanguage.da:
        return _name('da');
      case DefaultResourceLoaderLanguage.fr:
        return _name('fr');
      default:
        throw Exception('Invalid value');
    }
  }
}
