class Config {
  // static const String baseUrl = 'http://10.0.2.2/safesync-api'; //Local API
   static const String baseUrl = 'https://safesync.helioho.st/mobile-api';
  // Auth APIs
  static const String loginUrl = '$baseUrl/user/login.php';
  // Incident Reporting APIs
  static const String createReportUrl = '$baseUrl/reporting/submit_report.php';
}
