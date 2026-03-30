import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import '../../features/shopping_list/models/pending_operation.dart';
import '../../features/shopping_list/data/sync_queue_repository.dart';

/// Service responsible for managing offline-to-online sync of shopping list operations.
///
/// Listens to connectivity changes and processes the pending operations queue
/// sequentially when the device comes back online.
class SyncService extends ChangeNotifier {
  static const int maxRetries = 3;

  final SyncQueueRepository _queueRepo;
  final dynamic _supabaseService; // Use dynamic to allow mocking in tests
  final Connectivity _connectivity;

  StreamSubscription<List<ConnectivityResult>>? _connectivitySub;
  bool _isProcessing = false;

  SyncStatusState _status = SyncStatusState.idle;
  int _pendingCount = 0;
  String? _lastError;

  // Stream for notifying when a createList operation succeeds
  final StreamController<Map<String, String>> _createListSyncController =
      StreamController<Map<String, String>>.broadcast();

  // Getters for UI
  SyncStatusState get status => _status;
  int get pendingCount => _pendingCount;
  String? get lastError => _lastError;

  /// Stream that emits events when a createList operation is successfully synced.
  /// Each event is a Map with keys 'tempId' and 'dbId'.
  Stream<Map<String, String>> get onCreateListSynced =>
      _createListSyncController.stream;

  SyncService({
    required SyncQueueRepository queueRepo,
    required dynamic supabaseService,
    Connectivity? connectivity,
  }) : _queueRepo = queueRepo,
       _supabaseService = supabaseService,
       _connectivity = connectivity ?? Connectivity();

  /// Initializes the service and starts listening to connectivity changes.
  Future<void> initialize() async {
    await _updatePendingCount();
    _connectivitySub = _connectivity.onConnectivityChanged.listen(
      _onConnectivityChanged,
    );
  }

  /// Enqueues a new operation for sync.
  Future<void> enqueue(PendingOperation operation) async {
    await _queueRepo.enqueue(operation);
    await _updatePendingCount();
    debugPrint(
      'SyncService: Enqueued operation ${operation.id} (${operation.type})',
    );

    // If we're online, try to process immediately
    final results = await _connectivity.checkConnectivity();
    final isOnline =
        results.isNotEmpty && results.last != ConnectivityResult.none;
    if (isOnline) {
      unawaited(processQueue());
    }
  }

  /// Processes all pending operations in the queue sequentially.
  Future<void> processQueue() async {
    if (_isProcessing) {
      debugPrint('SyncService: Already processing queue, skipping');
      return;
    }

    final results = await _connectivity.checkConnectivity();
    final isOnline =
        results.isNotEmpty && results.last != ConnectivityResult.none;
    if (!isOnline) {
      debugPrint('SyncService: Offline, skipping queue processing');
      return;
    }

    _isProcessing = true;
    _setStatus(SyncStatusState.syncing);
    _lastError = null;

    try {
      final queue = await _queueRepo.loadQueue();
      debugPrint('SyncService: Processing ${queue.length} pending operations');

      for (final operation in queue) {
        try {
          await _processOperation(operation);
          await _queueRepo.remove(operation.id);
          await _updatePendingCount();
          debugPrint(
            'SyncService: Successfully synced operation ${operation.id}',
          );
        } catch (e) {
          debugPrint(
            'SyncService: Failed to sync operation ${operation.id}: $e',
          );

          if (operation.retryCount >= maxRetries) {
            // Max retries reached, mark as permanently failed
            _lastError = 'Falha ao sincronizar: ${operation.type.name}';
            _setStatus(SyncStatusState.error);
            debugPrint(
              'SyncService: Max retries reached for ${operation.id}, marking as failed',
            );
            // Remove from queue so we don't keep retrying
            await _queueRepo.remove(operation.id);
            await _updatePendingCount();
          } else {
            // Increment retry count and re-enqueue
            await _queueRepo.updateRetryCount(
              operation.id,
              operation.retryCount + 1,
            );
            debugPrint(
              'SyncService: Incremented retry count for ${operation.id} to ${operation.retryCount + 1}',
            );
          }
          // Stop processing on first error to avoid cascading failures
          // Reset status to idle since we'll retry on next connectivity event
          _setStatus(SyncStatusState.idle);
          break;
        }
      }

      // If we processed everything without errors, go back to idle
      final remainingQueue = await _queueRepo.loadQueue();
      if (remainingQueue.isEmpty) {
        _setStatus(SyncStatusState.idle);
      }
    } finally {
      _isProcessing = false;
    }
  }

  /// Processes a single operation.
  Future<void> _processOperation(PendingOperation operation) async {
    switch (operation.type) {
      case PendingOperationType.createList:
        await _processCreateList(operation);
        break;
      case PendingOperationType.renameList:
        await _processRenameList(operation);
        break;
    }
  }

  /// Processes a createList operation.
  Future<void> _processCreateList(PendingOperation operation) async {
    final payload = operation.payload;
    final userId = payload['userId'] as String;
    final name = payload['name'] as String;
    final tempId = payload['tempId'] as String;

    final row = await _supabaseService.insertManualList(
      userId: userId,
      name: name,
    );
    final dbId = row['id'] as String;

    // Notify listeners that a createList operation was successfully synced
    // The controller will use this to update the local list ID from tempId to dbId
    _createListSyncController.add({'tempId': tempId, 'dbId': dbId});
    debugPrint('SyncService: Created list $dbId (was $tempId)');
  }

  /// Processes a renameList operation.
  Future<void> _processRenameList(PendingOperation operation) async {
    final payload = operation.payload;
    final listId = payload['listId'] as String;
    final newName = payload['newName'] as String;

    await _supabaseService.updateListName(listId, newName);
    debugPrint('SyncService: Renamed list $listId to $newName');
  }

  /// Handles connectivity change events.
  void _onConnectivityChanged(List<ConnectivityResult> results) {
    final result = results.isNotEmpty ? results.last : ConnectivityResult.none;
    debugPrint('SyncService: Connectivity changed to ${result.name}');
    if (result != ConnectivityResult.none && !_isProcessing) {
      unawaited(processQueue());
    }
  }

  /// Updates the pending count from the repository.
  Future<void> _updatePendingCount() async {
    final queue = await _queueRepo.loadQueue();
    _pendingCount = queue.length;
    notifyListeners();
  }

  /// Updates the sync status and notifies listeners.
  void _setStatus(SyncStatusState newStatus) {
    _status = newStatus;
    notifyListeners();
  }

  @override
  void dispose() {
    _connectivitySub?.cancel();
    _createListSyncController.close();
    super.dispose();
  }
}

/// Represents the current sync status.
enum SyncStatusState { idle, syncing, error }
