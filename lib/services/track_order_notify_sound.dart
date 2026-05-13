import 'package:audioplayers/audioplayers.dart';

/// Short in-app tone when an order becomes ready (push notifications on).
abstract final class TrackOrderNotifySound {
  static final AudioPlayer _player = AudioPlayer();

  static Future<void> play() async {
    try {
      await _player.stop();
      await _player.play(AssetSource('sounds/notify.mp3'));
    } catch (_) {
      // Asset or platform audio not available (e.g. some desktop setups).
    }
  }
}
