import 'dart:convert';
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'inquiry_models.dart';

/// 문의 내역 로컬 저장소.
///
/// 정본: ios_st_about_kit/Sources/STAboutKit/Inquiry/InquiryHistoryStore.swift
/// iOS 는 Documents 디렉토리의 inquiry_history.json 파일에 저장한다.
/// Flutter 는 path_provider 의 ApplicationDocumentsDirectory 로 동일하게 이식.
///
/// 이식 시 고친 점: Dart 파일 입출력이 비동기라 메서드가 Future 를 반환한다
/// (iOS 는 동기). 호출부(Interactor)는 이미 async.
class InquiryHistoryStore {
  InquiryHistoryStore._();

  static final InquiryHistoryStore shared = InquiryHistoryStore._();

  static const String _fileName = 'inquiry_history.json';

  Future<File> _file() async {
    final dir = await getApplicationDocumentsDirectory();
    return File('${dir.path}/$_fileName');
  }

  // MARK: - Public Methods

  // 정본: InquiryHistoryStore.swift#save
  Future<void> save(InquiryRecord record) async {
    final records = await fetchAll();
    records.insert(0, record);
    await _writeRecords(records);
  }

  // 정본: InquiryHistoryStore.swift#fetchAll
  Future<List<InquiryRecord>> fetchAll() async {
    try {
      final file = await _file();
      if (!await file.exists()) return [];
      final data = await file.readAsString();
      final list = jsonDecode(data) as List<dynamic>;
      return list
          .map((e) => InquiryRecord.fromJson(e as Map<String, dynamic>))
          .toList();
    } catch (_) {
      return [];
    }
  }

  // 정본: InquiryHistoryStore.swift#update
  Future<void> update(InquiryRecord record) async {
    final records = await fetchAll();
    final index = records.indexWhere((r) => r.id == record.id);
    if (index != -1) {
      records[index] = record;
      await _writeRecords(records);
    }
  }

  // 정본: InquiryHistoryStore.swift#deleteAll
  Future<void> deleteAll() async {
    try {
      final file = await _file();
      if (await file.exists()) {
        await file.delete();
      }
    } catch (_) {
      // 삭제 실패 시 무시
    }
  }

  /// 서버 레코드와 로컬 레코드 병합.
  /// - 로컬에 없는 서버 레코드 추가 (outbound 포함)
  /// - 로컬에 있는 레코드는 서버 상태로 업데이트
  // 정본: InquiryHistoryStore.swift#merge
  Future<void> merge(List<InquiryRecord> serverRecords) async {
    final localRecords = await fetchAll();
    var changed = false;

    for (final serverRecord in serverRecords) {
      final index = localRecords.indexWhere((r) => r.id == serverRecord.id);
      if (index != -1) {
        // 로컬에 있으면 상태 업데이트
        if (localRecords[index].status != serverRecord.status ||
            localRecords[index].reply != serverRecord.reply) {
          localRecords[index].status = serverRecord.status;
          localRecords[index].reply = serverRecord.reply;
          localRecords[index].repliedAt = serverRecord.repliedAt;
          changed = true;
        }
      } else {
        // 로컬에 없으면 추가 (outbound 또는 복원)
        localRecords.add(serverRecord);
        changed = true;
      }
    }

    if (changed) {
      // 최신순 정렬
      localRecords.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      await _writeRecords(localRecords);
    }
  }

  // MARK: - Private Methods

  // 정본: InquiryHistoryStore.swift#writeRecords
  Future<void> _writeRecords(List<InquiryRecord> records) async {
    try {
      final file = await _file();
      const encoder = JsonEncoder.withIndent('  ');
      final data = encoder.convert(records.map((r) => r.toJson()).toList());
      await file.writeAsString(data, flush: true);
    } catch (_) {
      // 저장 실패 시 무시
    }
  }
}
