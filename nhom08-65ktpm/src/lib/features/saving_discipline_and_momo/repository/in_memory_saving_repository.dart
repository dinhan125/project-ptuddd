import 'dart:async';
import 'dart:io';

import '../models/deposit_record.dart';
import '../models/member_streak.dart';
import '../models/momo_fund_config.dart';
import '../models/saving_plan.dart';
import 'saving_repository.dart';

/// In-memory [SavingRepository] fallback used when Firebase is not initialized
/// (e.g., `main_ui_preview.dart` or isolated widget/unit tests).
class InMemorySavingRepository implements SavingRepository {
  final Map<String, MoMoFundConfig> _fundConfigs = {};
  final Map<String, StreamController<MoMoFundConfig?>> _fundControllers = {};

  final Map<String, SavingPlan> _savingPlans = {};
  final Map<String, StreamController<SavingPlan?>> _planControllers = {};

  final Map<String, List<DepositRecord>> _deposits = {};
  final Map<String, StreamController<List<DepositRecord>>> _depositControllers = {};

  final Map<String, MemberStreak> _streaks = {};
  final Map<String, StreamController<MemberStreak>> _streakControllers = {};

  StreamController<MoMoFundConfig?> _fundController(String tripId) =>
      _fundControllers.putIfAbsent(tripId, () => StreamController<MoMoFundConfig?>.broadcast());

  StreamController<SavingPlan?> _planController(String key) =>
      _planControllers.putIfAbsent(key, () => StreamController<SavingPlan?>.broadcast());

  StreamController<List<DepositRecord>> _depositController(String tripId) =>
      _depositControllers.putIfAbsent(tripId, () => StreamController<List<DepositRecord>>.broadcast());

  StreamController<MemberStreak> _streakController(String key) =>
      _streakControllers.putIfAbsent(key, () => StreamController<MemberStreak>.broadcast());

  @override
  Future<MoMoFundConfig?> getFundConfig(String tripId) async => _fundConfigs[tripId];

  @override
  Stream<MoMoFundConfig?> watchFundConfig(String tripId) async* {
    yield _fundConfigs[tripId];
    yield* _fundController(tripId).stream;
  }

  @override
  Future<void> saveFundConfig(MoMoFundConfig config) async {
    _fundConfigs[config.tripId] = config;
    _fundController(config.tripId).add(config);
  }

  @override
  Future<SavingPlan?> getSavingPlan(String tripId, String memberId) async =>
      _savingPlans['${tripId}_$memberId'];

  @override
  Stream<SavingPlan?> watchSavingPlan(String tripId, String memberId) async* {
    final key = '${tripId}_$memberId';
    yield _savingPlans[key];
    yield* _planController(key).stream;
  }

  @override
  Future<void> saveSavingPlan(SavingPlan plan) async {
    final key = '${plan.tripId}_${plan.memberId}';
    _savingPlans[key] = plan;
    _planController(key).add(plan);
  }

  @override
  Future<void> submitDeposit(DepositRecord record, {File? receiptImage}) async {
    final list = _deposits.putIfAbsent(record.tripId, () => []);
    list.add(record.copyWith(receiptImageUrl: receiptImage?.path ?? record.receiptImageUrl));
    _depositController(record.tripId).add(List.unmodifiable(list));
  }

  @override
  Future<List<DepositRecord>> getPendingDeposits(String tripId) async {
    final list = _deposits[tripId] ?? [];
    return list.where((d) => d.status == DepositStatus.pending).toList();
  }

  @override
  Stream<List<DepositRecord>> watchPendingDeposits(String tripId) async* {
    yield await getPendingDeposits(tripId);
    yield* _depositController(tripId).stream.map(
          (list) => list.where((d) => d.status == DepositStatus.pending).toList(),
        );
  }

  @override
  Stream<List<DepositRecord>> watchMemberDeposits(String tripId, String memberId) async* {
    yield (_deposits[tripId] ?? []).where((d) => d.memberId == memberId).toList();
    yield* _depositController(tripId).stream.map(
          (list) => list.where((d) => d.memberId == memberId).toList(),
        );
  }

  @override
  Future<void> updateDepositStatus({
    required String tripId,
    required String depositId,
    required DepositStatus status,
    required String reviewerId,
  }) async {
    final list = _deposits[tripId] ?? [];
    final idx = list.indexWhere((d) => d.id == depositId);
    if (idx == -1) {
      throw Exception('Deposit record $depositId not found.');
    }
    list[idx] = list[idx].copyWith(
      status: status,
      approvedBy: reviewerId,
      approvedAt: DateTime.now(),
    );
    _depositController(tripId).add(List.unmodifiable(list));
  }

  @override
  Future<MemberStreak> getMemberStreak(String tripId, String memberId) async {
    return _streaks['${tripId}_$memberId'] ?? MemberStreak(memberId: memberId, tripId: tripId);
  }

  @override
  Stream<MemberStreak> watchMemberStreak(String tripId, String memberId) async* {
    final key = '${tripId}_$memberId';
    yield _streaks[key] ?? MemberStreak(memberId: memberId, tripId: tripId);
    yield* _streakController(key).stream;
  }

  @override
  Future<void> updateMemberStreak(MemberStreak streak) async {
    final key = '${streak.tripId}_${streak.memberId}';
    _streaks[key] = streak;
    _streakController(key).add(streak);
  }
}
