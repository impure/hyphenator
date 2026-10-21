
import 'extensions.dart';
import 'hyphenator_resource_loader.dart';

const _startEndMarker = '.';
const _exceptionDelimiter = '-';

// RegExp('\\w') works only for English letters
List<int> _createExceptionMask(String exc) {
  final list = <int>[];

  int index = 0;

  while (index < exc.length) {
    if (exc[index] == _exceptionDelimiter) {
      list.add(1);
      index++;
    } else {
      list.add(0);
    }

    index++;
  }

  list.add(0);

  return list;
}

MapEntry<String, List<int>> _parsePattern(String pattern) {
  final letters = StringBuffer();
  final levels = <int>[0];

  for (int i = 0; i < pattern.length; i++) {
    final c = pattern[i];

    if (c.isDigit) {
      levels.last = c.asInt!;
    } else {
      letters.write(c);
      levels.add(0);
    }
  }

  return MapEntry(letters.toString(), levels);
}

class Hyphenator {
  Hyphenator({
    required ResourceLoader resource,
    this.hyphenateSymbol = '\u{00AD}',
    this.minWordLength = 5,
    this.minLetterCount = 3,
  })  : assert(minWordLength > 0),
        _patterns = Map.fromEntries(
          resource.patternsStrings.map(_parsePattern),
        ) {
    _maxPatternLength = _patterns.keys.fold(
      0,
      (length, pattern) => pattern.length > length ? pattern.length : length,
    );
    _exceptions.addEntries(
      resource.exceptionsStrings.map(
        (exception) => MapEntry(
          exception.replaceAll(_exceptionDelimiter, ''),
          _createExceptionMask(exception),
        ),
      ),
    );
  }

  final Map<String, List<int>> _patterns;
  late final int _maxPatternLength;
  final Map<String, List<int>> _exceptions = {};
  final String hyphenateSymbol;
  final int minWordLength;
  final int minLetterCount;

  String hyphenate(String text) {
    var currentWord = StringBuffer();
    var result = new StringBuffer();

    for (int i = 0; i < text.length; i++) {
      final c = text[i];

      if (c.isLetter) {
        currentWord.write(c);
      } else {
        if (currentWord.length > 0) {
          result.write(hyphenateWord(currentWord.toString()));
          currentWord.clear();
        }
        result.write(c);
      }
    }

    result.write(hyphenateWord(currentWord.toString()));

    return result.toString();
  }

  String hyphenateWord(String inputWord) {
    if (_isNotNeedHyphenate(inputWord)) return inputWord;

    final word = inputWord.toLowerCase();

    List<int>? hyphenationMask;

    if (_exceptions.containsKey(word))
      hyphenationMask = _exceptions[word];
    else {
      final levels = _generateLevelsForWord(word);
      hyphenationMask = _hyphenatedMaskFromLevels(levels);
      _correctHyphenationMask(hyphenationMask);
    }

    return _hyphenateByMask(inputWord, hyphenationMask);
  }

  List<String> hyphenateWordToList(String inputWord) {
    if (_isNotNeedHyphenate(inputWord)) return <String>[inputWord];

    final word = inputWord.toLowerCase();

    List<int>? hyphenationMask;

    if (_exceptions.containsKey(word))
      hyphenationMask = _exceptions[word];
    else {
      final levels = _generateLevelsForWord(word);
      hyphenationMask = _hyphenatedMaskFromLevels(levels);
      _correctHyphenationMask(hyphenationMask);
    }

    return _hyphenateByMaskToList(inputWord, hyphenationMask);
  }

  List<int> _generateLevelsForWord(String word) {
    final wordString = '$_startEndMarker$word$_startEndMarker';

    final levels = List.filled(wordString.length + 1, 0);

    for (int i = 0; i < wordString.length; ++i) {
      for (int end = i + 1;
          end <= wordString.length && end - i <= _maxPatternLength;
          ++end) {
        final patternLevels = _patterns[wordString.substring(i, end)];

        if (patternLevels == null) continue;

        for (int levelIndex = 0;
            levelIndex < patternLevels.length;
            ++levelIndex) {
          final level = patternLevels[levelIndex];

          if (level > levels[i + levelIndex]) levels[i + levelIndex] = level;
        }
      }
    }
    return levels.sublist(0, wordString.length);
  }

  List<int> _hyphenatedMaskFromLevels(List<int> levels) {
    int length = levels.length - 2;

    final hyphenationMask = List<int>.filled(length, 0);
    hyphenationMask[0] = 0;

    for (int i = 1; i < length; i++) {
      if (levels[i + 1] % 2 != 0) hyphenationMask[i] = 1;
    }

    return hyphenationMask;
  }

  void _correctHyphenationMask(List<int> mask) {
    if (mask.length > minLetterCount) {
      for (int i = 0; i < minLetterCount; i++) {
        mask[i] = 0;
      }

      final correctionLength = minLetterCount > 0 ? minLetterCount - 1 : 0;

      for (int i = mask.length - correctionLength; i < mask.length; i++) {
        mask[i] = 0;
      }
    } else {
      for (int i = 0; i < mask.length; i++) {
        mask[i] = 0;
      }
    }
  }

  String _hyphenateByMask(String word, List<int>? mask) {
    var result = StringBuffer();
    for (int i = 0; i < word.length; i++) {
      if (mask![i] > 0) result.write(hyphenateSymbol);
      result.write(word[i]);
    }
    return result.toString();
  }

  List<String> _hyphenateByMaskToList(String word, List<int>? mask) {
    StringBuffer currentSyllable = StringBuffer();
    List<String> returnList = <String>[];

    for (int i = 0; i < word.length; i++) {
      if (mask![i] > 0) {
        returnList.add(currentSyllable.toString());
        currentSyllable.clear();
      }
      currentSyllable.write(word[i]);
    }

    returnList.add(currentSyllable.toString());
    return returnList;
  }

  bool _isNotNeedHyphenate(String input) => input.length < minWordLength;
}
