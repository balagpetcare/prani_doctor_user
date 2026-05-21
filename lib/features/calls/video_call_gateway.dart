import 'package:flutter/foundation.dart';

/// Abstract gateway for a future video provider (Agora, Daily, native WebRTC).
abstract class VideoCallGateway {
  Future<void> joinRoom(String roomId);
  Future<void> leaveRoom();
  Stream<String> get connectionStates;
}

/// Placeholder implementation until a vendor SDK is selected.
class NoOpVideoCallGateway implements VideoCallGateway {
  @override
  Future<void> joinRoom(String roomId) async {
    debugPrint('VideoCallGateway.joinRoom ($roomId) — not implemented');
  }

  @override
  Future<void> leaveRoom() async {}

  @override
  Stream<String> get connectionStates => const Stream.empty();
}
