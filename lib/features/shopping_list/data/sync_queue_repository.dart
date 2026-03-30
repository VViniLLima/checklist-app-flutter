import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/pending_operation.dart';

/// Repository for persisting and loading pending sync operations.
///
/// Uses SharedPreferences to store the queue so operations survive app restarts.
class SyncQueueRepository {
  static const String _queueKey = 'pending_sync_queue';

  final SharedPreferences _prefs;

  SyncQueueRepository(this._prefs);

  /// Factory to create an instance asynchronously.
  static Future<SyncQueueRepository> create() async {
    final prefs = await SharedPreferences.getInstance();
    return SyncQueueRepository(prefs);
  }

  /// Loads all pending operations from storage.
  Future<List<PendingOperation>> loadQueue() async {
    final jsonString = _prefs.getString(_queueKey);
    if (jsonString == null || jsonString.isEmpty) {
      return [];
    }

    try {
      final List<dynamic> jsonList = jsonDecode(jsonString);
      return jsonList
          .map(
            (json) => PendingOperation.fromJson(json as Map<String, dynamic>),
          )
          .toList();
    } catch (e) {
      return [];
    }
  }

  /// Saves the entire queue to storage.
  Future<void> saveQueue(List<PendingOperation> operations) async {
    final jsonList = operations.map((op) => op.toJson()).toList();
    final jsonString = jsonEncode(jsonList);
    await _prefs.setString(_queueKey, jsonString);
  }

  /// Enqueues a new operation at the end of the queue.
  Future<void> enqueue(PendingOperation operation) async {
    final currentQueue = await loadQueue();
    currentQueue.add(operation);
    await saveQueue(currentQueue);
  }

  /// Removes an operation from the queue by its ID.
  Future<void> remove(String operationId) async {
    final currentQueue = await loadQueue();
    currentQueue.removeWhere((op) => op.id == operationId);
    await saveQueue(currentQueue);
  }

  /// Updates the retry count for a specific operation.
  Future<void> updateRetryCount(String operationId, int newCount) async {
    final currentQueue = await loadQueue();
    final index = currentQueue.indexWhere((op) => op.id == operationId);
    if (index != -1) {
      currentQueue[index] = currentQueue[index].copyWith(retryCount: newCount);
      await saveQueue(currentQueue);
    }
  }

  /// Clears all pending operations (useful for testing or reset).
  Future<void> clear() async {
    await _prefs.remove(_queueKey);
  }
}
