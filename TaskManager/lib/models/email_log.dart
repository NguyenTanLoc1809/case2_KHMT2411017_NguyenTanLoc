class EmailLog {
  final String id;
  final String recipientEmail;
  final String eventType;
  final String subject;
  final String status; // pending | sent | failed
  final int attempts;
  final String errorMessage;
  final DateTime createdAt;

  const EmailLog({
    required this.id,
    required this.recipientEmail,
    required this.eventType,
    required this.subject,
    required this.status,
    required this.attempts,
    required this.errorMessage,
    required this.createdAt,
  });

  factory EmailLog.fromJson(Map<String, dynamic> j) => EmailLog(
        id: j['_id'].toString(),
        recipientEmail: (j['recipientEmail'] ?? '').toString(),
        eventType: (j['eventType'] ?? '').toString(),
        subject: (j['subject'] ?? '').toString(),
        status: (j['status'] ?? 'pending').toString(),
        attempts: (j['attempts'] as num?)?.toInt() ?? 0,
        errorMessage: (j['errorMessage'] ?? '').toString(),
        createdAt: DateTime.tryParse((j['createdAt'] ?? '').toString())?.toLocal() ?? DateTime.now(),
      );
}
