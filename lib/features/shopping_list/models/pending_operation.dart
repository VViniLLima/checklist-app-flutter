import 'dart:convert';

/// Represents a pending sync operation that needs to be replayed
/// when the device comes back online.
class PendingOperation {
  final String id;
  final PendingOperationType type;
  final Map<String, dynamic> payload;
  final DateTime timestamp;
  final int retryCount;

  const PendingOperation({
    required this.id,
    required this.type,
    required this.payload,
    required this.timestamp,
    this.retryCount = 0,
  });

  PendingOperation copyWith({
    String? id,
    PendingOperationType? type,
    Map<String, dynamic>? payload,
    DateTime? timestamp,
    int? retryCount,
  }) {
    return PendingOperation(
      id: id ?? this.id,
      type: type ?? this.type,
      payload: payload ?? this.payload,
      timestamp: timestamp ?? this.timestamp,
      retryCount: retryCount ?? this.retryCount,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'type': type.name,
      'payload': payload,
      'timestamp': timestamp.toIso8601String(),
      'retryCount': retryCount,
    };
  }

  factory PendingOperation.fromJson(Map<String, dynamic> json) {
    return PendingOperation(
      id: json['id'] as String,
      type: PendingOperationType.values.firstWhere(
        (e) => e.name == json['type'] as String,
      ),
      payload: json['payload'] as Map<String, dynamic>,
      timestamp: DateTime.parse(json['timestamp'] as String),
      retryCount: json['retryCount'] as int? ?? 0,
    );
  }

  @override
  String toString() {
    return 'PendingOperation(id: $id, type: $type, retryCount: $retryCount)';
  }
}

enum PendingOperationType { createList, renameList }
