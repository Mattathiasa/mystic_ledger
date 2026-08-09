import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/foundation.dart';

/// Connection + sync status for the app bar.
enum CloudSyncState {
  /// Online and no local writes waiting.
  synced,

  /// Online with writes still heading to the cloud (or queued while offline).
  saving,

  /// No network interface — reads come from the local cache, writes queue and
  /// flush automatically when the connection returns.
  offline,
}

/// Pure — maps connectivity + pending-write flags onto a single status so the
/// app bar logic is testable without plugins.
CloudSyncState computeSyncState({
  required bool online,
  required bool anyPending,
}) =>
    !online
        ? CloudSyncState.offline
        : anyPending
            ? CloudSyncState.saving
            : CloudSyncState.synced;

/// Watches Firestore stream metadata and the device's network interface so the
/// app bar can show whether the ledger is synced, still saving, or offline.
///
/// Firestore reports `hasPendingWrites` on each query snapshot while the local
/// cache still holds writes that have not reached the server (a fresh write,
/// or a queued write while offline). With offline persistence enabled, all
/// reads and writes keep working without a connection — the pill simply tells
/// the user which state they are in.
class CloudSyncService {
  CloudSyncService._();

  static final CloudSyncService instance = CloudSyncService._();

  final ValueNotifier<CloudSyncState> _state =
      ValueNotifier<CloudSyncState>(CloudSyncState.synced);

  /// Listen to this (ValueListenableBuilder) to render the status pill and
  /// the offline banner.
  ValueListenable<CloudSyncState> get state => _state;

  final ValueNotifier<bool> _online = ValueNotifier<bool>(true);

  /// Whether a network interface is currently available. Note: this reports
  /// interface presence, not internet reachability — Firestore's pending-write
  /// status is the authoritative signal for whether writes have actually
  /// reached the cloud.
  ValueListenable<bool> get online => _online;

  final List<StreamSubscription> _subs = [];
  final Map<String, bool> _pendingByCollection = {};
  final Map<String, bool> _latestFromCache = {};
  String? _uid;
  DateTime? _boundAt;

  /// Grace period before Firestore's `fromCache` metadata is trusted as an
  /// offline signal. On a normal online launch the first snapshot of each
  /// stream comes from the cache, so immediately treating "everything from
  /// cache" as offline would flash the banner on every start.
  static const _kServerGrace = Duration(seconds: 3);

  /// Binds the watcher to [uid], restarting if the signed-in user changed.
  /// Safe to call on every build — it is a no-op while already bound.
  void ensure(String? uid) {
    if (_uid == uid && _subs.isNotEmpty) return;
    dispose();
    _uid = uid;
    _boundAt = DateTime.now();

    // Network interface tracking — works on mobile, web and desktop.
    // MissingPluginException surfaces as a stream error, handled below.
    _subs.add(Connectivity().onConnectivityChanged.listen(
          (results) {
            _online.value = results.any((r) => r != ConnectivityResult.none);
            _recompute();
          },
          onError: (_) {},
        ));

    // Seed immediately from the current state, not just on the next change.
    Connectivity()
        .checkConnectivity()
        .then((results) {
          _online.value = results.any((r) => r != ConnectivityResult.none);
          _recompute();
        })
        .catchError((_) {});

    if (uid == null || uid.isEmpty) return;

    final db = FirebaseFirestore.instance;
    const collections = [
      'accounts',
      'transactions',
      'transfers',
      'debts',
      'budgets',
      'recurring',
    ];
    for (final name in collections) {
      final sub = db
          .collection('users/$uid/$name')
          .snapshots(includeMetadataChanges: true)
          .listen((snap) {
        _pendingByCollection[name] = snap.metadata.hasPendingWrites;
        _latestFromCache[name] = snap.metadata.isFromCache;
        _recompute();
      }, onError: (_) {
        // Keep the last known state: a failed stream must not invent a
        // "synced" claim (nor a spurious "saving") about a collection whose
        // write status we can no longer see.
      });
      _subs.add(sub);
    }
  }

  void _recompute() {
    final interfaceOnline = _online.value;
    final elapsed =
        _boundAt == null ? Duration.zero : DateTime.now().difference(_boundAt!);

    // connectivity_plus reports *interface* presence, not internet
    // reachability — on Wi-Fi without internet (captive portal) it stays
    // true. Firestore's fromCache metadata covers that gap: once the grace
    // period has passed, every stream still serving from cache means the
    // server never answered.
    final staleFromCache = _latestFromCache.isNotEmpty &&
        elapsed > _kServerGrace &&
        _latestFromCache.values.every((c) => c);

    final offline = !interfaceOnline || staleFromCache;
    _state.value = computeSyncState(
      online: !offline,
      anyPending: _pendingByCollection.values.any((p) => p),
    );
  }

  void dispose() {
    for (final s in _subs) {
      s.cancel();
    }
    _subs.clear();
    _pendingByCollection.clear();
    _latestFromCache.clear();
    _uid = null;
    _boundAt = null;
    _online.value = true;
    _state.value = CloudSyncState.synced;
  }
}
