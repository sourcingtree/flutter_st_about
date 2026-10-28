/// 앱별 설정 값을 주입하기 위한 Configuration.
///
/// 문의 관련 필드(apiURL·spreadsheetId·slackWebhookUrl·deviceIdProvider·
/// environmentInfoProvider)는 iOS STAboutConfiguration.InquiryConfiguration 과
/// 동일한 역할이다(정본: ios_st_about_kit/.../STAboutConfiguration.swift:71-87).
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
    this.slackWebhookUrl,
    this.serviceName,
    this.deviceIdProvider,
    this.environmentInfoProvider,
  });

  final String appName;
  final String appVersion;
  final String supportEmail;
  final String? faqUrl;
  final String? termsUrl;
  final String? privacyUrl;
  final String? shareText;
  final String? appStoreId;

  /// 공유 문의 백엔드 URL(GAS). 없으면 mailto 방식.
  final String? inquiryApiUrl;

  /// 문의 내역 스프레드시트 ID.
  final String? inquirySpreadsheetId;

  /// 슬랙 웹훅(선택). 백엔드가 serviceName 으로 채널을 정하므로 비워도 된다.
  final String? slackWebhookUrl;

  /// 서비스 식별자 = 번들 ID. 미지정 시 PackageInfo.packageName 자동 사용.
  final String? serviceName;

  /// 디바이스 식별자 제공 함수(문의 작성자 식별·내역 동기화에 사용).
  final String Function()? deviceIdProvider;

  /// 환경 정보 제공 함수(문의 본문 끝에 자동 첨부). 미지정 시 기본 기기 정보.
  final String Function()? environmentInfoProvider;
}
