import 'package:aves/services/common/services.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';

abstract class WindowService {
  Future<bool> isActivity();

  Future<void> keepScreenOn(bool on);

  Future<bool> isRotationLocked();

  Future<void> requestOrientation([Orientation? orientation]);

  Future<bool> isCutoutAware();

  Future<EdgeInsets> getCutoutInsets();
}

class PlatformWindowService implements WindowService {
  static const _platform = MethodChannel('deckers.thibault/aves/window');

  @override
  Future<bool> isActivity() async {
    try {
      final result = await _platform.invokeMethod('isActivity');
      if (result != null) return result as bool;
    } on PlatformException catch (e, stack) {
      await reportService.recordError(e, stack);
    }
    return false;
  }

  @override
  Future<void> keepScreenOn(bool on) async {
    try {
      await _platform.invokeMethod('keepScreenOn', <String, dynamic>{
        'on': on,
      });
    } on PlatformException catch (e, stack) {
      await reportService.recordError(e, stack);
    }
  }

  @override
  Future<bool> isRotationLocked() async {
    try {
      final result = await _platform.invokeMethod('isRotationLocked');
      if (result != null) return result as bool;
    } on PlatformException catch (e, stack) {
      await reportService.recordError(e, stack);
    }
    return false;
  }

  @override
  Future<void> requestOrientation([Orientation? orientation]) async {
    // cf Android `ActivityInfo.ScreenOrientation`
    late final int orientationCode;
    switch (orientation) {
      case Orientation.landscape:
        // SCREEN_ORIENTATION_SENSOR_LANDSCAPE
        orientationCode = 6;
        break;
      case Orientation.portrait:
        // SCREEN_ORIENTATION_SENSOR_PORTRAIT
        orientationCode = 7;
        break;
      default:
        // SCREEN_ORIENTATION_UNSPECIFIED
        orientationCode = -1;
        break;
    }
    try {
      await _platform.invokeMethod('requestOrientation', <String, dynamic>{
        'orientation': orientationCode,
      });
    } on PlatformException catch (e, stack) {
      await reportService.recordError(e, stack);
    }
  }

  bool? _isCutoutAware;

  @override
  Future<bool> isCutoutAware() async {
    if (_isCutoutAware != null) return SynchronousFuture(_isCutoutAware!);
    try {
      final result = await _platform.invokeMethod('isCutoutAware');
      _isCutoutAware = result as bool?;
    } on PlatformException catch (e, stack) {
      await reportService.recordError(e, stack);
    }
    return _isCutoutAware ?? false;
  }

  @override
  Future<EdgeInsets> getCutoutInsets() async {
    try {
      final result = await _platform.invokeMethod('getCutoutInsets');
      if (result != null) {
        return EdgeInsets.only(
          left: result['left']?.toDouble() ?? 0,
          top: result['top']?.toDouble() ?? 0,
          right: result['right']?.toDouble() ?? 0,
          bottom: result['bottom']?.toDouble() ?? 0,
        );
      }
    } on PlatformException catch (e, stack) {
      await reportService.recordError(e, stack);
    }
    return EdgeInsets.zero;
  }
}
