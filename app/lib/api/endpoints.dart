// Spec: docs/specs/api/endpoints.md

import '../core/types.dart';
import 'client.dart';

class ApiEndpoints {
  final ApiClient _client;

  ApiEndpoints(this._client);

  Future<MonthDataResponse> getMonthData({String? month}) async {
    final r = await _client.get(
      'monthData',
      params: {if (month != null) 'month': month},
    );
    return MonthDataResponse.fromJson(r);
  }

  Future<HistoricalSummaryResponse> getHistoricalSummary() async {
    final r = await _client.get('historicalSummary');
    return HistoricalSummaryResponse.fromJson(r);
  }

  Future<LastEntriesResponse> getLastEntries({int n = 10}) async {
    final r = await _client.get('lastEntries', params: {'n': n});
    return LastEntriesResponse.fromJson(r);
  }

  Future<MutationResponse> updateEntry(int row, UpdateEntryFields fields) async {
    final r = await _client.post('updateEntry', {
      'row': row,
      'fields': fields.toJson(),
    });
    return MutationResponse.fromJson(r);
  }

  Future<MutationResponse> deleteEntry(int row) async {
    final r = await _client.post('deleteEntry', {'row': row});
    return MutationResponse.fromJson(r);
  }
}
