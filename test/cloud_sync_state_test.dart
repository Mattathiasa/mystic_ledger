import 'package:flutter_test/flutter_test.dart';
import 'package:mystic_ledger/services/cloud_sync_service.dart';

void main() {
  group('computeSyncState', () {
    test('online with nothing pending → synced', () {
      expect(
        computeSyncState(online: true, anyPending: false),
        CloudSyncState.synced,
      );
    });

    test('online with pending writes → saving', () {
      expect(
        computeSyncState(online: true, anyPending: true),
        CloudSyncState.saving,
      );
    });

    test('offline → offline whether or not writes are pending', () {
      expect(
        computeSyncState(online: false, anyPending: false),
        CloudSyncState.offline,
      );
      expect(
        computeSyncState(online: false, anyPending: true),
        CloudSyncState.offline,
      );
    });
  });
}
