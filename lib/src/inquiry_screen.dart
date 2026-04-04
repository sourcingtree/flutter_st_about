import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'st_about_config.dart';

/// GAS 연동 문의 화면
class STInquiryScreen extends StatefulWidget {
  const STInquiryScreen({super.key, required this.config, this.userId});

  final STAboutConfig config;
  final String? userId;

  @override
  State<STInquiryScreen> createState() => _STInquiryScreenState();
}

class _STInquiryScreenState extends State<STInquiryScreen> {
  final _subjectController = TextEditingController();
  final _contentController = TextEditingController();
  bool _isSubmitting = false;

  @override
  void dispose() {
    _subjectController.dispose();
    _contentController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_contentController.text.trim().isEmpty) return;
    setState(() => _isSubmitting = true);

    try {
      final deviceInfo = widget.config.deviceInfoProvider != null
          ? await widget.config.deviceInfoProvider!()
          : '';

      final response = await http.post(
        Uri.parse(widget.config.inquiryApiUrl!),
        headers: {'Content-Type': 'text/plain;charset=UTF-8'},
        body: jsonEncode({
          'action': 'submitInquiry',
          'subject': _subjectController.text.trim().isEmpty
              ? '일반 문의'
              : _subjectController.text.trim(),
          'content': _contentController.text.trim(),
          'deviceInfo': deviceInfo,
          'userId': widget.userId ?? '',
          'appName': widget.config.appName,
        }),
      ).timeout(const Duration(seconds: 15));

      final json = jsonDecode(response.body) as Map<String, dynamic>;
      if (mounted) {
        if (json['success'] == true) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('문의가 접수되었습니다'), backgroundColor: Colors.green),
          );
          Navigator.of(context).pop();
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('전송 실패: ${json['error']}'), backgroundColor: Colors.red),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('전송 실패: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('문의하기')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            TextField(
              controller: _subjectController,
              decoration: const InputDecoration(
                labelText: '제목',
                hintText: '문의 제목 (선택)',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            Expanded(
              child: TextField(
                controller: _contentController,
                maxLines: null,
                expands: true,
                textAlignVertical: TextAlignVertical.top,
                decoration: const InputDecoration(
                  labelText: '내용',
                  hintText: '문의 내용을 입력해주세요',
                  border: OutlineInputBorder(),
                  alignLabelWithHint: true,
                ),
              ),
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              height: 48,
              child: FilledButton(
                onPressed: _isSubmitting ? null : _submit,
                child: _isSubmitting
                    ? const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(strokeWidth: 2))
                    : const Text('문의 접수'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
