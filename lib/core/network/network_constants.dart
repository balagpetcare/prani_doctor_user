/// Default service ports (pranidoctor-backend / pranidoctor-web).
abstract final class NetworkConstants {
  NetworkConstants._();

  static const defaultApiPort = 3000;
  static const defaultWebPort = 3001;

  /// PC Wi-Fi IP for dev when [API_BASE_URL] is unset (physical device on LAN).
  static const defaultDevWifiHost = '192.168.10.111';

  /// Origin-only dev API URL (paths like `/api/mobile/*` are appended by Dio).
  static String devWifiApiBaseUrl({
    String host = defaultDevWifiHost,
    int port = defaultApiPort,
  }) => 'http://$host:$port';

  /// Backend liveness (no auth, no envelope).
  static const healthLive = '/live';

  /// Backend readiness (storage/db/redis).
  static const healthReady = '/ready';

  /// Storage subsystem health (upload readiness proxy).
  static const healthStorage = '/health/storage';

  static const defaultConnectTimeoutSec = 5;
  static const defaultReceiveTimeoutSec = 10;
  static const probeTimeoutSec = 12;
}
