// ui-structure-ok: 문의는 탭 화면이 아니라 문의→내역→스레드 상세진입 구조(iOS InquiryViewController 동일).
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'st_about_config.dart';
import 'inquiry/inquiry_config.dart';
import 'inquiry/inquiry_history_store.dart';
import 'inquiry/inquiry_interactor.dart';
import 'inquiry/inquiry_models.dart';

/// 공유 문의 백엔드(dev-commons/inquiry) 연동 문의 화면.
///
/// iOS STAboutKit 의 문의 비즈니스 로직(InquiryInteractor/Worker/HistoryStore)을
/// 그대로 쓴다. 화면 구성은 iOS InquiryViewController 의 흐름(입력·검증·제출·
/// 환경정보 첨부·이전 내역 첨부)을 Flutter 로 이식.
///
/// (이 파일은 공용 패키지 flutter_st_about 소속이라 carrot 의 lib/design/kit.dart
///  를 쓸 수 없다. 간격·말줄임 등은 Flutter 기본 위젯 — kit_lint 예외 `// kit-ok`.)
class STInquiryScreen extends StatefulWidget {
  const STInquiryScreen({super.key, required this.config, this.userId});

  final STAboutConfig config;
  final String? userId;

  @override
  State<STInquiryScreen> createState() => _STInquiryScreenState();
}

/// 호스트 설정값을 전역 InquiryConfig 로 복사한다.
/// 정본: STAboutListViewController.swift:41-45.
Future<void> _setupInquiryConfig(STAboutConfig config) async {
  InquiryConfig.apiURL = config.inquiryApiUrl ?? '';
  InquiryConfig.spreadsheetId = config.inquirySpreadsheetId ?? '';
  InquiryConfig.slackWebhookUrl = config.slackWebhookUrl ?? '';
  InquiryConfig.deviceIdProvider = config.deviceIdProvider;
  InquiryConfig.environmentInfoProvider = config.environmentInfoProvider;
  InquiryConfig.appName = config.appName;
  if (config.serviceName != null && config.serviceName!.isNotEmpty) {
    InquiryConfig.serviceName = config.serviceName!;
  } else {
    final info = await PackageInfo.fromPlatform();
    InquiryConfig.serviceName = info.packageName;
  }
}

class _STInquiryScreenState extends State<STInquiryScreen> {
  final _interactor = InquiryInteractor();
  final _emailController = TextEditingController();
  final _subjectController = TextEditingController();
  final _contentController = TextEditingController();
  bool _isSubmitting = false;
  List<InquiryRecord> _loadedRecords = [];

  @override
  void initState() {
    super.initState();
    _setup();
  }

  Future<void> _setup() async {
    await _setupInquiryConfig(widget.config);
    final records = await InquiryHistoryStore.shared.fetchAll();
    if (!mounted) return;
    setState(() => _loadedRecords = records);
  }

  @override
  void dispose() {
    _emailController.dispose();
    _subjectController.dispose();
    _contentController.dispose();
    super.dispose();
  }

  // 정본: InquiryViewController.swift#environmentInfoText
  // iOS 원본은 기기 모델 + OS 버전 + 앱 버전을 넣는다. 여기서는 의존성 없이
  // 플랫폼(android/ios) + OS 버전 + 앱 버전까지 — 기기 모델은 device_info_plus 필요라 생략.
  String _environmentInfoText() {
    final provider = InquiryConfig.environmentInfoProvider;
    if (provider != null) return provider();
    return 'OS ${Platform.operatingSystem} ${Platform.operatingSystemVersion}'
        ' | 앱 ${widget.config.appName} v${widget.config.appVersion}';
  }

  // 정본: InquiryViewController.swift:783-801 (검증 통과 후 본문 조립)
  String _buildMessage() {
    var message = _contentController.text;
    message += '\n\n--- 환경 정보 ---\n${_environmentInfoText()}';

    if (_loadedRecords.isNotEmpty) {
      message += '\n\n--- 이전 문의 내역 ---';
      for (final r in _loadedRecords) {
        final d = r.createdAt;
        final stamp =
            '${d.year}.${_two(d.month)}.${_two(d.day)} ${_two(d.hour)}:${_two(d.minute)}';
        message += '\n\n[ID: ${r.id}]';
        message += '\n제목: ${r.subject}';
        message += '\n일시: $stamp';
        message += '\n내용: ${r.message}';
      }
    }
    return message;
  }

  String _two(int v) => v.toString().padLeft(2, '0');

  Future<void> _submit() async {
    final validation = _interactor.validateInput(
      email: _emailController.text,
      subject: _subjectController.text,
      message: _contentController.text,
    );
    if (!validation.isValid) {
      _toast(validation.errorMessage ?? '입력 내용을 확인해주세요', isError: true);
      return;
    }

    setState(() => _isSubmitting = true);
    final response = await _interactor.submitInquiry(
      email: _emailController.text,
      subject: _subjectController.text,
      message: _buildMessage(),
      attachments: const [],
    );
    if (!mounted) return;
    setState(() => _isSubmitting = false);

    if (response.success) {
      _toast('문의가 접수되었습니다.\n빠른 시일 내에 답변 드리겠습니다.');
      Navigator.of(context).pop();
    } else {
      _toast(
        response.errorMessage ?? '문의 접수에 실패했습니다.\n잠시 후 다시 시도해주세요.',
        isError: true,
      );
    }
  }

  void _toast(String msg, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        backgroundColor: isError ? Colors.red : Colors.green,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('문의하기'),
        actions: [
          IconButton(
            tooltip: '문의 내역',
            icon: const Icon(Icons.history),
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute(
                builder: (_) => const InquiryHistoryScreen(),
              ),
            ),
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            TextField(
              controller: _emailController,
              keyboardType: TextInputType.emailAddress,
              decoration: const InputDecoration(
                labelText: '이메일',
                hintText: '답변 받으실 이메일',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12), // kit-ok
            TextField(
              controller: _subjectController,
              decoration: const InputDecoration(
                labelText: '제목',
                hintText: '문의 제목을 입력하세요',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12), // kit-ok
            Expanded(
              child: TextField(
                controller: _contentController,
                maxLines: null,
                expands: true,
                textAlignVertical: TextAlignVertical.top,
                decoration: const InputDecoration(
                  labelText: '내용',
                  hintText: '문의 내용을 입력하세요',
                  border: OutlineInputBorder(),
                  alignLabelWithHint: true,
                ),
              ),
            ),
            const SizedBox(height: 16), // kit-ok
            SizedBox(
              height: 48, // kit-ok
              child: FilledButton(
                onPressed: _isSubmitting ? null : _submit,
                child: _isSubmitting
                    ? const SizedBox(
                        width: 24, // kit-ok
                        height: 24,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Text('문의 보내기'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// 문의 내역 목록 화면.
/// 정본: InquiryListViewController.swift (목록 + 당겨서 서버 동기화).
class InquiryHistoryScreen extends StatefulWidget {
  const InquiryHistoryScreen({super.key});

  @override
  State<InquiryHistoryScreen> createState() => _InquiryHistoryScreenState();
}

class _InquiryHistoryScreenState extends State<InquiryHistoryScreen> {
  final _interactor = InquiryInteractor();
  List<InquiryRecord> _records = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _refresh();
  }

  Future<void> _refresh() async {
    setState(() => _loading = true);
    // 서버와 동기화 후 최신 목록. 실패 시 로컬만.
    final records = await _interactor.syncWithServer();
    if (!mounted) return;
    setState(() {
      _records = records;
      _loading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('문의 내역')),
      body: RefreshIndicator(
        onRefresh: _refresh,
        child: _loading
            ? const Center(child: CircularProgressIndicator())
            : _records.isEmpty
                ? ListView(
                    children: const [
                      SizedBox(height: 120), // kit-ok
                      Center(child: Text('문의 내역이 없습니다')),
                    ],
                  )
                : ListView.separated(
                    itemCount: _records.length,
                    separatorBuilder: (_, __) => const Divider(height: 1),
                    itemBuilder: (_, i) {
                      final r = _records[i];
                      final replied = r.status == InquiryStatus.replied;
                      return ListTile(
                        title: Text(
                          r.subject,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis, // kit-ok
                        ),
                        subtitle: Text(
                          r.message,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis, // kit-ok
                        ),
                        trailing: Text(
                          replied ? '답변완료' : '대기중',
                          style: TextStyle(
                            color: replied ? Colors.green : Colors.orange,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        onTap: () => Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) => InquiryThreadScreen(record: r),
                          ),
                        ),
                      );
                    },
                  ),
      ),
    );
  }
}

/// 문의 상세(스레드) 화면 — 내 문의 + 답변 또는 대기 안내.
/// 정본: InquiryThreadViewController.swift.
class InquiryThreadScreen extends StatelessWidget {
  const InquiryThreadScreen({super.key, required this.record});

  final InquiryRecord record;

  @override
  Widget build(BuildContext context) {
    final replied = record.status == InquiryStatus.replied;
    return Scaffold(
      appBar: AppBar(title: const Text('문의 상세')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _bubble(context, '나', record.message, mine: true),
          const SizedBox(height: 12), // kit-ok
          if (replied && record.reply != null)
            _bubble(context, '고객지원', record.reply!, mine: false)
          else
            const Center(
              child: Padding(
                padding: EdgeInsets.symmetric(vertical: 24),
                child: Text('답변 대기중입니다',
                    style: TextStyle(color: Colors.grey)),
              ),
            ),
        ],
      ),
    );
  }

  Widget _bubble(BuildContext context, String who, String text,
      {required bool mine}) {
    return Column(
      crossAxisAlignment:
          mine ? CrossAxisAlignment.end : CrossAxisAlignment.start,
      children: [
        Text(who, style: const TextStyle(fontSize: 12, color: Colors.grey)), // kit-ok
        const SizedBox(height: 4), // kit-ok
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: mine
                ? Theme.of(context).colorScheme.primaryContainer
                : Theme.of(context).colorScheme.surfaceContainerHighest,
            borderRadius: BorderRadius.circular(12), // kit-ok
          ),
          child: Text(text),
        ),
      ],
    );
  }
}
