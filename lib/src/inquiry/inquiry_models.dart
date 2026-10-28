import 'dart:convert';
import 'dart:io';

/// 문의 데이터 모델.
///
/// 정본: ios_st_about_kit/Sources/STAboutKit/Inquiry/Models/InquiryModels.swift
///       + Inquiry/Models/InquiryRecord.swift
/// Swift enum/struct 를 Dart 로 줄 단위 이식. 분기·필드 수 동일.

// MARK: - Attachment Model
// 정본: InquiryModels.swift#InquiryAttachment
class InquiryAttachment {
  final String filename;
  final String mimeType;
  final String data; // Base64 encoded

  const InquiryAttachment._(this.filename, this.mimeType, this.data);

  /// 원본 바이트에서 생성(자동 base64 인코딩).
  factory InquiryAttachment.fromBytes({
    required String filename,
    required String mimeType,
    required List<int> bytes,
  }) {
    return InquiryAttachment._(filename, mimeType, base64Encode(bytes));
  }

  /// 이미 base64 인 데이터로 생성.
  factory InquiryAttachment.fromBase64({
    required String filename,
    required String mimeType,
    required String base64Data,
  }) {
    return InquiryAttachment._(filename, mimeType, base64Data);
  }

  Map<String, dynamic> toJson() => {
        'filename': filename,
        'mimeType': mimeType,
        'data': data,
      };
}

// MARK: - Attachment Provider Protocol
// 정본: InquiryModels.swift#InquiryAttachmentProvider
/// 문의 화면에 첨부 파일을 주입하기 위한 프로토콜.
/// 로그 파일, 스크린샷 등 다양한 첨부 파일을 외부에서 주입할 수 있음.
abstract class InquiryAttachmentProvider {
  /// 첨부할 파일 목록 반환.
  List<InquiryAttachment> provideAttachments();
}

// MARK: - Default Attachment Providers
// 정본: InquiryModels.swift#LogFileAttachmentProvider
/// 로그 파일 첨부 제공자.
class LogFileAttachmentProvider implements InquiryAttachmentProvider {
  final String? logFilePath;

  const LogFileAttachmentProvider(this.logFilePath);

  @override
  List<InquiryAttachment> provideAttachments() {
    final path = logFilePath;
    if (path == null) return [];
    final file = File(path);
    if (!file.existsSync()) return [];
    final bytes = file.readAsBytesSync();
    final filename = path.split(Platform.pathSeparator).last;
    return [
      InquiryAttachment.fromBytes(
        filename: filename,
        mimeType: 'text/plain',
        bytes: bytes,
      ),
    ];
  }
}

// 정본: InquiryModels.swift#CompositeAttachmentProvider
/// 여러 첨부 파일 제공자를 합치는 복합 제공자.
class CompositeAttachmentProvider implements InquiryAttachmentProvider {
  final List<InquiryAttachmentProvider> providers;

  const CompositeAttachmentProvider(this.providers);

  @override
  List<InquiryAttachment> provideAttachments() {
    return providers.expand((p) => p.provideAttachments()).toList();
  }
}

// 정본: InquiryModels.swift#DirectAttachmentProvider
/// 직접 첨부 파일 데이터를 주입하는 제공자.
class DirectAttachmentProvider implements InquiryAttachmentProvider {
  final List<InquiryAttachment> attachments;

  const DirectAttachmentProvider(this.attachments);

  @override
  List<InquiryAttachment> provideAttachments() => attachments;
}

// MARK: - Submit Inquiry
// 정본: InquiryModels.swift#Inquiry.SubmitInquiry.Response
class SubmitInquiryResponse {
  final bool success;
  final String? inquiryId;
  final String? errorMessage;

  const SubmitInquiryResponse({
    required this.success,
    this.inquiryId,
    this.errorMessage,
  });
}

// MARK: - Validation
// 정본: InquiryModels.swift#Inquiry.Validation.Response
class ValidationResponse {
  final bool isValid;
  final String? errorMessage;

  const ValidationResponse({required this.isValid, this.errorMessage});
}

// MARK: - Status Batch
// 정본: InquiryModels.swift#Inquiry.StatusResult
class StatusResult {
  final String inquiryId;
  final String status;
  final String? reply;
  final String? repliedAt;

  const StatusResult({
    required this.inquiryId,
    required this.status,
    this.reply,
    this.repliedAt,
  });

  factory StatusResult.fromJson(Map<String, dynamic> j) => StatusResult(
        inquiryId: j['inquiryId'] as String,
        status: j['status'] as String,
        reply: j['reply'] as String?,
        repliedAt: j['repliedAt'] as String?,
      );
}

// 정본: InquiryModels.swift#Inquiry.StatusBatchResponse
class StatusBatchResponse {
  final bool? success;
  final List<StatusResult>? results;
  final String? error;
  final String? status;
  final String? message;

  const StatusBatchResponse({
    this.success,
    this.results,
    this.error,
    this.status,
    this.message,
  });

  bool get isSuccess => success == true;

  factory StatusBatchResponse.fromJson(Map<String, dynamic> j) {
    final raw = j['results'] as List<dynamic>?;
    return StatusBatchResponse(
      success: j['success'] as bool?,
      results: raw
          ?.map((e) => StatusResult.fromJson(e as Map<String, dynamic>))
          .toList(),
      error: j['error'] as String?,
      status: j['status'] as String?,
      message: j['message'] as String?,
    );
  }
}

// MARK: - Fetch By DeviceId
// 정본: InquiryModels.swift#Inquiry.ServerInquiryResult
class ServerInquiryResult {
  final String inquiryId;
  final String? email;
  final String subject;
  final String message;
  final String? createdAt;
  final String status;
  final String? reply;
  final String? repliedAt;

  const ServerInquiryResult({
    required this.inquiryId,
    this.email,
    required this.subject,
    required this.message,
    this.createdAt,
    required this.status,
    this.reply,
    this.repliedAt,
  });

  factory ServerInquiryResult.fromJson(Map<String, dynamic> j) =>
      ServerInquiryResult(
        inquiryId: j['inquiryId'] as String,
        email: j['email'] as String?,
        subject: j['subject'] as String,
        message: j['message'] as String,
        createdAt: j['createdAt'] as String?,
        status: j['status'] as String,
        reply: j['reply'] as String?,
        repliedAt: j['repliedAt'] as String?,
      );
}

// 정본: InquiryModels.swift#Inquiry.FetchByDeviceResponse
class FetchByDeviceResponse {
  final bool? success;
  final List<ServerInquiryResult>? results;
  final String? error;

  const FetchByDeviceResponse({this.success, this.results, this.error});

  bool get isSuccess => success == true;

  factory FetchByDeviceResponse.fromJson(Map<String, dynamic> j) {
    final raw = j['results'] as List<dynamic>?;
    return FetchByDeviceResponse(
      success: j['success'] as bool?,
      results: raw
          ?.map((e) => ServerInquiryResult.fromJson(e as Map<String, dynamic>))
          .toList(),
      error: j['error'] as String?,
    );
  }
}

// MARK: - Inquiry Status / Record
// 정본: InquiryRecord.swift#InquiryStatus
enum InquiryStatus {
  pending('대기중'),
  replied('답변완료');

  final String raw;
  const InquiryStatus(this.raw);

  static InquiryStatus fromRaw(String value) {
    return value == '답변완료' ? InquiryStatus.replied : InquiryStatus.pending;
  }
}

// 정본: InquiryRecord.swift#InquiryRecord
class InquiryRecord {
  final String id;
  final String email;
  final String subject;
  final String message;
  final DateTime createdAt;
  InquiryStatus status;
  String? reply;
  DateTime? repliedAt;

  InquiryRecord({
    required this.id,
    required this.email,
    required this.subject,
    required this.message,
    required this.createdAt,
    required this.status,
    this.reply,
    this.repliedAt,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'email': email,
        'subject': subject,
        'message': message,
        'createdAt': createdAt.toIso8601String(),
        'status': status.raw,
        'reply': reply,
        'repliedAt': repliedAt?.toIso8601String(),
      };

  factory InquiryRecord.fromJson(Map<String, dynamic> j) => InquiryRecord(
        id: j['id'] as String,
        email: j['email'] as String? ?? '',
        subject: j['subject'] as String,
        message: j['message'] as String,
        createdAt:
            DateTime.tryParse(j['createdAt'] as String? ?? '') ?? DateTime.now(),
        status: InquiryStatus.fromRaw(j['status'] as String? ?? '대기중'),
        reply: j['reply'] as String?,
        repliedAt: j['repliedAt'] != null
            ? DateTime.tryParse(j['repliedAt'] as String)
            : null,
      );
}
