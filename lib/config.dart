class Config {
  // static const String baseUrl = 'http://10.0.2.2/safesync-api'; -- //Local API

  // Base Url
  static const String baseUrl = 'https://safesync.helioho.st/mobile-api';

  // Auth APIs
  static const String loginUrl = '$baseUrl/user/login.php';
  
  // Incident Reporting APIs
  static const String createReportUrl = '$baseUrl/reporting/submit_report.php';

  // fetch incident types
  static const String fetchIncidentUrl = '$baseUrl/reporting/fetch_incident_types.php';

  // fetch incident types
  static const String fetchReportstUrl = '$baseUrl/reporting/fetch_reports.php';
}
