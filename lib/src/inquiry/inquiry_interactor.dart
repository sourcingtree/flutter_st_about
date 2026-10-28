import 'inquiry_config.dart';
import 'inquiry_history_store.dart';
import 'inquiry_models.dart';
import 'inquiry_worker.dart';

/// 문의 비즈니스 로직(검증·제출·상태조회·서버동기화).
///
/// 정본: ios_st_about_kit/Sources/STAboutKit/Inquiry/InquiryInteractor.swift
///
/// 이식 시 고친 점: iOS 는 VIP(Interactor→Presenter 콜백) 구조라
/// validateInput·submitInquiry 가 presenter 로 결과를 밀지만, Flutter 는
/// 화면이 직접 호출하므로 결과를 반환(return)하는 순수/async 함수로 이식한다.
/// 검증 규칙·분기·길이 상한·정규식은 원본과 동일.
class InquiryInteractor {
  final InquiryWorkerProtocol worker;

  InquiryInteractor({InquiryWorkerProtocol? worker})
      : worker = worker ?? InquiryWorker();

  // MARK: - Business Logic

  // 정본: InquiryInteractor.swift#validateInput
  ValidationResponse validateInput({
    required String email,
    required String subject,
    required String message,
  }) {
    final e = email.trim();
    final s = subject.trim();
    final m = message.trim();

    // 빈 값 체크
    if (e.isEmpty) {
      return const ValidationResponse(
          isValid: false, errorMessage: '이메일을 입력해주세요');
    }
    if (s.isEmpty) {
      return const ValidationResponse(
          isValid: false, errorMessage: '제목을 입력해주세요');
    }
    if (m.isEmpty) {
      return const ValidationResponse(
          isValid: false, errorMessage: '내용을 입력해주세요');
    }

    // 이메일 형식 체크
    final emailRegex =
        RegExp(r'[A-Z0-9a-z._%+-]+@[A-Za-z0-9.-]+\.[A-Za-z]{2,64}');
    if (!emailRegex.hasMatch(e)) {
      return const ValidationResponse(
          isValid: false, errorMessage: '올바른 이메일 형식을 입력해주세요');
    }

    // 길이 체크
    if (s.length > 200) {
      return const ValidationResponse(
          isValid: false, errorMessage: '제목은 200자 이내로 입력해주세요');
    }
    if (m.length > 5000) {
      return const ValidationResponse(
          isValid: false, errorMessage: '내용은 5000자 이내로 입력해주세요');
    }

    return const ValidationResponse(isValid: true, errorMessage: null);
  }

  // 정본: InquiryInteractor.swift#submitInquiry
  Future<SubmitInquiryResponse> submitInquiry({
    required String email,
    required String subject,
    required String message,
    required List<InquiryAttachment> attachments,
  }) async {
    final e = email.trim();
    final s = subject.trim();
    final m = message.trim();

    final response = await worker.submitInquiry(
      email: e,
      subject: s,
      message: m,
      attachments: attachments,
    );

    if (response.success && response.inquiryId != null) {
      final record = InquiryRecord(
        id: response.inquiryId!,
        email: e,
        subject: s,
        message: m,
        createdAt: DateTime.now(),
        status: InquiryStatus.pending,
        reply: null,
        repliedAt: null,
      );
      await InquiryHistoryStore.shared.save(record);
    }

    return response;
  }

  // 정본: InquiryInteractor.swift#fetchStatuses
  Future<List<StatusResult>> fetchStatuses(List<String> inquiryIds) {
    return worker.fetchStatuses(inquiryIds);
  }

  // 정본: InquiryInteractor.swift#syncWithServer
  Future<List<InquiryRecord>> syncWithServer() async {
    final deviceId = InquiryConfig.deviceId;
    final serverResults = await worker.fetchInquiries(deviceId);

    final serverRecords = serverResults.map((result) {
      // iOS DateFormatter "yyyy-MM-dd HH:mm:ss" → DateTime.parse 가 같은 형식 수용
      final createdAt = result.createdAt != null
          ? (DateTime.tryParse(result.createdAt!) ?? DateTime.now())
          : DateTime.now();

      final repliedAt = result.repliedAt != null
          ? DateTime.tryParse(result.repliedAt!)
          : null;

      final status = result.status == '답변완료'
          ? InquiryStatus.replied
          : InquiryStatus.pending;

      return InquiryRecord(
        id: result.inquiryId,
        email: result.email ?? '',
        subject: result.subject,
        message: result.message,
        createdAt: createdAt,
        status: status,
        reply: result.reply,
        repliedAt: repliedAt,
      );
    }).toList();

    await InquiryHistoryStore.shared.merge(serverRecords);
    return InquiryHistoryStore.shared.fetchAll();
  }
}
