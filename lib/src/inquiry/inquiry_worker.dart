import 'dart:convert';
import 'package:http/http.dart' as http;
import 'inquiry_config.dart';
import 'inquiry_models.dart';

/// 문의 서버 통신 계층.
///
/// 정본: ios_st_about_kit/Sources/STAboutKit/Inquiry/InquiryWorker.swift
/// 공유 백엔드(dev-commons/inquiry/main.gs)와 동일한 요청 형식으로 이식.
/// submit POST body: {spreadsheetId, serviceName, slackWebhookUrl, replyFromName,
///                    deviceId, email, subject, message, attachments?}
/// (main.gs:174-177 가 받는 필드와 일치).
///
/// 이식 시 고친 점: iOS 는 쿼리 문자열을 raw 로 이어 붙이지만, Dart 는
/// Uri.replace(queryParameters:) 로 안전하게 인코딩한다(백엔드는 디코딩 값을 받음).
abstract class InquiryWorkerProtocol {
  Future<SubmitInquiryResponse> submitInquiry({
    required String email,
    required String subject,
    required String message,
    required List<InquiryAttachment> attachments,
  });

  Future<List<StatusResult>> fetchStatuses(List<String> inquiryIds);
  Future<List<ServerInquiryResult>> fetchInquiries(String deviceId);
}

class InquiryWorker implements InquiryWorkerProtocol {
  // MARK: - Submit Inquiry
  // 정본: InquiryWorker.swift#submitInquiry
  @override
  Future<SubmitInquiryResponse> submitInquiry({
    required String email,
    required String subject,
    required String message,
    required List<InquiryAttachment> attachments,
  }) async {
    final url = Uri.tryParse(InquiryConfig.apiURL);
    if (url == null || InquiryConfig.apiURL.isEmpty) {
      return const SubmitInquiryResponse(
        success: false,
        inquiryId: null,
        errorMessage: '서버 연결에 실패했습니다',
      );
    }

    final body = <String, dynamic>{
      'spreadsheetId': InquiryConfig.spreadsheetId,
      'serviceName': InquiryConfig.serviceName,
      'slackWebhookUrl': InquiryConfig.slackWebhookUrl,
      'replyFromName': InquiryConfig.replyFromName,
      'deviceId': InquiryConfig.deviceId,
      'email': email,
      'subject': subject,
      'message': message,
    };

    if (attachments.isNotEmpty) {
      body['attachments'] = attachments.map((a) => a.toJson()).toList();
    }

    try {
      final response = await http
          .post(
            url,
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode(body),
          )
          .timeout(const Duration(seconds: 30));

      final apiResponse = jsonDecode(response.body) as Map<String, dynamic>;

      if (apiResponse['success'] == true) {
        return SubmitInquiryResponse(
          success: true,
          inquiryId: apiResponse['inquiryId'] as String?,
          errorMessage: null,
        );
      } else {
        return SubmitInquiryResponse(
          success: false,
          inquiryId: null,
          errorMessage: apiResponse['error'] as String? ??
              '문의 접수에 실패했습니다.\n잠시 후 다시 시도해주세요.',
        );
      }
    } catch (_) {
      return const SubmitInquiryResponse(
        success: false,
        inquiryId: null,
        errorMessage: '네트워크 연결이 불안정합니다.\n다시 시도해주세요',
      );
    }
  }

  // MARK: - Fetch Statuses
  // 정본: InquiryWorker.swift#fetchStatuses
  @override
  Future<List<StatusResult>> fetchStatuses(List<String> inquiryIds) async {
    if (inquiryIds.isEmpty) return [];

    final base = Uri.tryParse(InquiryConfig.apiURL);
    if (base == null) return [];
    final url = base.replace(queryParameters: {
      'action': 'statusBatch',
      'spreadsheetId': InquiryConfig.spreadsheetId,
      'serviceName': InquiryConfig.serviceName,
      'inquiryIds': inquiryIds.join(','),
    });

    try {
      final response = await http.get(url);
      final decoded =
          StatusBatchResponse.fromJson(jsonDecode(response.body) as Map<String, dynamic>);
      if (decoded.isSuccess) {
        return decoded.results ?? [];
      }
      return [];
    } catch (_) {
      return [];
    }
  }

  // MARK: - Fetch Inquiries by DeviceId
  // 정본: InquiryWorker.swift#fetchInquiries
  @override
  Future<List<ServerInquiryResult>> fetchInquiries(String deviceId) async {
    final base = Uri.tryParse(InquiryConfig.apiURL);
    if (base == null) return [];
    final url = base.replace(queryParameters: {
      'action': 'fetchByDeviceId',
      'spreadsheetId': InquiryConfig.spreadsheetId,
      'serviceName': InquiryConfig.serviceName,
      'deviceId': deviceId,
    });

    try {
      final response = await http.get(url);
      final decoded = FetchByDeviceResponse.fromJson(
          jsonDecode(response.body) as Map<String, dynamic>);
      if (decoded.isSuccess) {
        return decoded.results ?? [];
      }
      return [];
    } catch (_) {
      return [];
    }
  }
}
