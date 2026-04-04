/// 앱별 설정 값을 주입하기 위한 Configuration
class STAboutConfig {
  const STAboutConfig({
    required this.appName,
    required this.appVersion,
    required this.supportEmail,
    this.faqUrl,
    this.termsUrl,
    this.privacyUrl,
    this.shareText,
    this.appStoreId,
    this.inquiryApiUrl,
    this.inquirySpreadsheetId,
    this.deviceInfoProvider,
  });

  final String appName;
  final String appVersion;
  final String supportEmail;
  final String? faqUrl;
  final String? termsUrl;
  final String? privacyUrl;
  final String? shareText;
  final String? appStoreId;

  /// GAS 문의 API URL (없으면 mailto 방식)
  final String? inquiryApiUrl;
  final String? inquirySpreadsheetId;

  /// 디바이스 정보 제공 함수 (문의 시 자동 첨부)
  final Future<String> Function()? deviceInfoProvider;
}
