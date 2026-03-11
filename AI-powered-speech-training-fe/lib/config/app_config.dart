/// Cấu hình API endpoint cho từng môi trường
///
/// Đổi [baseUrl] phù hợp với môi trường chạy:
/// - Web/Desktop      : http://localhost:3000/api
/// - Emulator Android : http://10.0.2.2:3000/api
/// - Device vật lý   : http://<IP_MÁY_TÍNH>:3000/api  (VD: http://192.168.1.5:3000/api)
class AppConfig {
  static const String baseUrl = 'http://localhost:3000/api';

  // Timeout mặc định cho HTTP requests
  static const Duration requestTimeout = Duration(seconds: 15);
}
