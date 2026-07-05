// ignore_for_file: cascade_invocations

import 'dart:async';
import 'dart:io';

/// ANSI escape codes
class _Ansi {
  static const String reset = '\x1B[0m';
  static const String bold = '\x1B[1m';
  static const String green = '\x1B[32m';
  static const String red = '\x1B[31m';
  static const String cyan = '\x1B[36m';
  static const String hideCursor = '\x1B[?25l';
  static const String showCursor = '\x1B[?25h';
  static const String clearLine = '\x1B[2K';
  static const String carriageReturn = '\r';
}

/// Spinner frames — matches Flutter's build output style
enum SpinnerStyle {
  /// ⠋ ⠙ ⠹ ⠸ ⠼ ⠴ ⠦ ⠧ ⠇ ⠏  (default, same as Flutter)
  braille,

  /// — \ | /
  classic,

  /// ◐ ◓ ◑ ◒
  circle,
}

const _frames = {
  SpinnerStyle.braille: ['⠋', '⠙', '⠹', '⠸', '⠼', '⠴', '⠦', '⠧', '⠇', '⠏'],
  SpinnerStyle.classic: ['—', r'\', '|', '/'],
  SpinnerStyle.circle: ['◐', '◓', '◑', '◒'],
};

class Spinner {
  Spinner({
    required String label,
    this.style = SpinnerStyle.braille,
    this.interval = const Duration(milliseconds: 80),
  }) : _label = label;

  String _label;
  final SpinnerStyle style;
  final Duration interval;

  Timer? _timer;
  int _frameIndex = 0;
  bool _active = false;

  /// Whether the terminal supports ANSI — false in CI / pipe / --no-color.
  bool get _ansiSupported => stdout.hasTerminal;

  void start() {
    if (_active) return;
    _active = true;

    if (!_ansiSupported) {
      // CI mode: print once, no animation
      stdout.writeln('$_label...');
      return;
    }

    stdout.write(_Ansi.hideCursor);
    _timer = Timer.periodic(interval, (_) => _render());
    _render(); // draw first frame immediately
  }

  void _render() {
    final frames = _frames[style]!;
    final frame = frames[_frameIndex % frames.length];
    _frameIndex++;

    // \r goes back to start of line, clearLine wipes it, then redraw
    stdout.write(
      '${_Ansi.carriageReturn}${_Ansi.clearLine}'
      '${_Ansi.cyan}$frame${_Ansi.reset} '
      '${_Ansi.bold}$_label${_Ansi.reset}',
    );
  }

  /// Call this when the task succeeds.
  void success([String? message]) => _stop(success: true, message: message);

  /// Call this when the task fails.
  void fail([String? message]) => _stop(success: false, message: message);

  void _stop({required bool success, String? message}) {
    if (!_active) return;
    _active = false;
    _timer?.cancel();
    _timer = null;

    if (!_ansiSupported) {
      stdout.writeln(success ? 'Done.' : 'Failed.');
      return;
    }

    final icon = success
        ? '${_Ansi.green}✓${_Ansi.reset}'
        : '${_Ansi.red}✗${_Ansi.reset}';

    final text = message ?? _label;

    stdout.write(
      '${_Ansi.carriageReturn}${_Ansi.clearLine}'
      '$icon ${_Ansi.bold}$text${_Ansi.reset}\n',
    );

    stdout.write(_Ansi.showCursor);
  }

  /// Update the label mid-spin (e.g. "Fetching... 3/12 packages").
  void update(String newLabel) {
    _label = newLabel;
    _render();
  }
}

/// Convenience: wrap an async task in a spinner automatically.
///
/// ```dart
/// final result = await withSpinner(
///   label: 'Grouping dependencies via FlutterGems',
///   task: () => serverApi.groupPackages(packages),
/// );
/// ```
Future<T> withSpinner<T>({
  required String label,
  required Future<T> Function() task,
  String? successLabel,
  String? failLabel,
  SpinnerStyle style = SpinnerStyle.braille,
}) async {
  final spinner = Spinner(label: label, style: style);
  spinner.start();
  try {
    final result = await task();
    spinner.success(successLabel);
    return result;
  } catch (e) {
    spinner.fail(failLabel ?? 'Failed: $e');
    rethrow;
  }
}

/// Multi-step spinner — shows "Step 1/3: Fetching...", "Step 2/3: ..."
class MultiStepSpinner {
  MultiStepSpinner(this.steps);

  final List<String> steps;
  int _current = 0;
  Spinner? _spinner;

  Future<void> run(List<Future<void> Function()> tasks) async {
    assert(
        tasks.length == steps.length, 'steps and tasks must match in length');

    for (var i = 0; i < tasks.length; i++) {
      _current = i + 1;
      final String label = '($_current/${steps.length}) ${steps[i]}';
      _spinner = Spinner(label: label);
      _spinner!.start();
      try {
        await tasks[i]();
        _spinner!.success();
      } catch (e) {
        _spinner!.fail();
        rethrow;
      }
    }
  }
}
