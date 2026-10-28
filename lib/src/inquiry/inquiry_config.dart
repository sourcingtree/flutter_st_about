/// 문의 전역 설정.
///
/// 정본: ios_st_about_kit/Sources/STAboutKit/Inquiry/InquiryConfig.swift
/// iOS 의 `enum InquiryConfig`(정적 저장소)을 Dart static 클래스로 이식.
/// 호스트가 화면 진입 전에 값을 주입한다
/// (iOS 는 STAboutListViewController.swift:41-45 에서 주입).
///
/// iOS 는 serviceName/replyFromName 을 Bundle 에서 동기로 읽지만,
/// Flutter 는 번들 조회가 비동기라 호스트가 appName·serviceName(packageName)을
/// 주입하는 방식으로 이식한다.
class InquiryConfig {
  InquiryConfig._();

  static String apiURL = '';
  static String spreadsheetId = '';
  static String slackWebhookUrl = '';
  static String Function()? deviceIdProvider;
  static String Function()? environmentInfoProvider;

  /// 앱 표시명(replyFromName 계산에 사용). iOS: CFBundleDisplayName.
  static String appName = '';

  /// 서비스 식별자 = 번들 ID. iOS: Bundle.main.bundleIdentifier.
  /// Flutter: PackageInfo.packageName 을 호스트가 주입.
  static String serviceName = 'UNKNOWN';

  // 정본: InquiryConfig.swift#replyFromName
  static String get replyFromName {
    final name = appName.isNotEmpty ? appName : '고객지원';
    return '$name 고객지원';
  }

  // 정본: InquiryConfig.swift#deviceId
  static String get deviceId => deviceIdProvider?.call() ?? '';
}
