// Spec: docs/specs/features/captura-notificacoes.md (Histórico de capturas)

class CaptureLogEntry {
  final int ts;
  final String package;
  final String title;
  final String content;
  final String status; // 'ok' | 'error'
  final String? error;

  const CaptureLogEntry({
    required this.ts,
    required this.package,
    required this.title,
    required this.content,
    required this.status,
    this.error,
  });

  Map<String, dynamic> toJson() => {
        'ts': ts,
        'package': package,
        'title': title,
        'content': content,
        'status': status,
        'error': error,
      };

  factory CaptureLogEntry.fromJson(Map<String, dynamic> j) => CaptureLogEntry(
        ts: (j['ts'] as num?)?.toInt() ?? 0,
        package: (j['package'] ?? '') as String,
        title: (j['title'] ?? '') as String,
        content: (j['content'] ?? '') as String,
        status: (j['status'] ?? 'ok') as String,
        error: j['error'] as String?,
      );

  DateTime get when => DateTime.fromMillisecondsSinceEpoch(ts);
}
