import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:share_plus/share_plus.dart';
import 'package:in_app_review/in_app_review.dart';
import 'st_about_config.dart';
import 'inquiry_screen.dart';

/// 설정 화면에 삽입할 수 있는 공통 섹션 위젯 모음
/// 각 앱은 이 위젯들을 조합해서 설정 화면을 구성한다.
class STAboutSection {
  STAboutSection._();

  /// 도움말 섹션 (FAQ + 문의하기)
  static Widget helpSection({
    required BuildContext context,
    required STAboutConfig config,
    String? userId,
  }) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (config.faqUrl != null)
          _tile(
            icon: Icons.help_outline,
            iconColor: const Color(0xFF00B86C),
            iconBg: const Color(0xFFE5F9EE),
            title: '자주 묻는 질문',
            onTap: () => launchUrl(Uri.parse(config.faqUrl!)),
          ),
        _tile(
          icon: Icons.mail_outline,
          iconColor: const Color(0xFFF97316),
          iconBg: const Color(0xFFFFF3E0),
          title: '문의하기',
          onTap: () {
            if (config.inquiryApiUrl != null) {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => STInquiryScreen(config: config, userId: userId),
                ),
              );
            } else {
              launchUrl(Uri(
                scheme: 'mailto',
                path: config.supportEmail,
                queryParameters: {'subject': '[${config.appName}] 문의'},
              ));
            }
          },
        ),
      ],
    );
  }

  /// 법적 정보 섹션 (이용약관 + 개인정보처리방침)
  static Widget legalSection({
    required BuildContext context,
    required STAboutConfig config,
  }) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (config.termsUrl != null)
          _tile(
            icon: Icons.description_outlined,
            iconColor: const Color(0xFFF97316),
            iconBg: const Color(0xFFFFF3E0),
            title: '이용약관',
            onTap: () => launchUrl(Uri.parse(config.termsUrl!)),
          ),
        if (config.privacyUrl != null)
          _tile(
            icon: Icons.shield_outlined,
            iconColor: const Color(0xFF4B9AE8),
            iconBg: const Color(0xFFE8F3FF),
            title: '개인정보처리방침',
            onTap: () => launchUrl(Uri.parse(config.privacyUrl!)),
          ),
      ],
    );
  }

  /// 공유 섹션 (앱 공유 + 리뷰)
  static Widget shareSection({
    required BuildContext context,
    required STAboutConfig config,
  }) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (config.shareText != null)
          _tile(
            icon: Icons.share,
            iconColor: const Color(0xFF6C5CE7),
            iconBg: const Color(0xFFF3EEFF),
            title: '앱 공유하기',
            onTap: () => Share.share(config.shareText!, subject: '${config.appName} 공유'),
          ),
        _tile(
          icon: Icons.star_outline,
          iconColor: const Color(0xFFFFB800),
          iconBg: const Color(0xFFFFF8E1),
          title: '리뷰 남기기',
          onTap: () async {
            final review = InAppReview.instance;
            if (await review.isAvailable()) {
              await review.requestReview();
            } else if (config.appStoreId != null) {
              await review.openStoreListing(appStoreId: config.appStoreId!);
            }
          },
        ),
      ],
    );
  }

  /// 앱 정보 섹션 (버전 + 오픈소스 라이선스)
  static Widget infoSection({
    required BuildContext context,
    required STAboutConfig config,
    Widget? appIcon,
  }) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        _tile(
          icon: Icons.info_outline,
          iconColor: const Color(0xFF00B86C),
          iconBg: const Color(0xFFE5F9EE),
          title: '버전',
          trailing: Text(
            config.appVersion,
            style: const TextStyle(fontSize: 14, color: Color(0xFF8B95A1)),
          ),
        ),
        _tile(
          icon: Icons.description_outlined,
          iconColor: const Color(0xFFEEC200),
          iconBg: const Color(0xFFFFF8E1),
          title: '오픈소스 라이선스',
          onTap: () => showLicensePage(
            context: context,
            applicationName: config.appName,
            applicationVersion: config.appVersion,
            applicationIcon: appIcon,
          ),
        ),
      ],
    );
  }

  static Widget _tile({
    required IconData icon,
    required Color iconColor,
    required Color iconBg,
    required String title,
    String? subtitle,
    Widget? trailing,
    VoidCallback? onTap,
  }) {
    return Builder(builder: (context) {
      return InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          child: Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: iconBg,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, size: 20, color: iconColor),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w500)),
                    if (subtitle != null)
                      Text(subtitle, style: const TextStyle(fontSize: 12, color: Color(0xFF8B95A1))),
                  ],
                ),
              ),
              if (trailing != null)
                trailing
              else if (onTap != null)
                const Icon(Icons.chevron_right, size: 18, color: Color(0xFF8B95A1)),
            ],
          ),
        ),
      );
    });
  }
}
