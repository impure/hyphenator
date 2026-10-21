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
  nl,
  it,
  bg,
  cs,
  el,
  esES,
  es419,
  fi,
  hu,
  nb,
  pl,
  ptBR,
  ptPT,
  ro,
  ru,
  sv,
  tr
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
    final pat = <String>[];
    final exc = <String>[];

    await _parse(lang._fileName, pat, exc);

    return DefaultResourceLoader._(
      pat,
      exc,
    );
  }

  static Future<void> _parse(
    String fileName,
    List<String> pat,
    List<String> exc,
  ) async {
    final value = await rootBundle.loadString(
      'packages/hyphenator_impure/hyphenate_patterns/$fileName',
    );

    List<String>? target;
    bool isNextInput = false;

    for (final line in value.split('\n')) {
      for (final token in line.split('%').first.split(RegExp(r'\s+'))) {
        if (token.isEmpty) continue;

        if (isNextInput) {
          isNextInput = false;
          await _parse(token, pat, exc);
        } else if (token == '\\input') {
          isNextInput = true;
        } else if (token.startsWith('\\patterns{')) {
          target = pat;
        } else if (token.startsWith('\\hyphenation{')) {
          target = exc;
        } else {
          final isEnd = token.endsWith('}');
          final entry = isEnd ? token.substring(0, token.length - 1) : token;

          if (entry.isNotEmpty) target?.add(entry);
          if (isEnd) target = null;
        }
      }
    }
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
      case DefaultResourceLoaderLanguage.nl:
        return _name('nl');
      case DefaultResourceLoaderLanguage.it:
        return _name('it');
      case DefaultResourceLoaderLanguage.bg:
        return _name('bg');
      case DefaultResourceLoaderLanguage.cs:
        return _name('cs');
      case DefaultResourceLoaderLanguage.el:
        return _name('el');
      case DefaultResourceLoaderLanguage.esES:
        return _name('es-es');
      case DefaultResourceLoaderLanguage.es419:
        return _name('es-419');
      case DefaultResourceLoaderLanguage.fi:
        return _name('fi');
      case DefaultResourceLoaderLanguage.hu:
        return _name('hu');
      case DefaultResourceLoaderLanguage.nb:
        return _name('nb');
      case DefaultResourceLoaderLanguage.pl:
        return _name('pl');
      case DefaultResourceLoaderLanguage.ptBR:
        return _name('pt-br');
      case DefaultResourceLoaderLanguage.ptPT:
        return _name('pt-pt');
      case DefaultResourceLoaderLanguage.ro:
        return _name('ro');
      case DefaultResourceLoaderLanguage.ru:
        return _name('ru');
      case DefaultResourceLoaderLanguage.sv:
        return _name('sv');
      case DefaultResourceLoaderLanguage.tr:
        return _name('tr');

      default:
        throw Exception('Invalid value');
    }
  }
}
