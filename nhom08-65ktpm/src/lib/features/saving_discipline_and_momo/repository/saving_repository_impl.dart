import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/deposit_record.dart';
import '../models/member_streak.dart';
import '../models/momo_fund_config.dart';
import '../models/saving_plan.dart';
import '../utils/saving_streak_calculator.dart';
import 'in_memory_saving_repository.dart';
import 'saving_repository.dart';

final savingRepositoryProvider = Provider<SavingRepository>((ref) {
  if (Firebase.apps.isEmpty) {
    return InMemorySavingRepository(seedDemo: true);
  }
  return SavingRepositoryImpl(
    firestore: FirebaseFirestore.instance,
    storage: FirebaseStorage.instance,
  );
});

class SavingRepositoryImpl implements SavingRepository {
  final FirebaseFirestore _firestore;
  final FirebaseStorage _storage;

  SavingRepositoryImpl({
    FirebaseFirestore? firestore,
    FirebaseStorage? storage,
  })  : _firestore = firestore ?? FirebaseFirestore.instance,
        _storage = storage ?? FirebaseStorage.instance;

  // --- Collection references ---
  DocumentReference _fundConfigDoc(String tripId) =>
      _firestore.collection('trips').doc(tripId).collection('momo_fund_config').doc('default');

  CollectionReference _savingPlansColl(String tripId) =>
      _firestore.collection('trips').doc(tripId).collection('saving_plans');

  DocumentReference _savingPlanDoc(String tripId, String memberId) =>
      _savingPlansColl(tripId).doc(memberId);

  CollectionReference _depositRecordsColl(String tripId) =>
      _firestore.collection('trips').doc(tripId).collection('deposit_records');

  CollectionReference _memberStreaksColl(String tripId) =>
      _firestore.collection('trips').doc(tripId).collection('member_streaks');

  DocumentReference _memberStreakDoc(String tripId, String memberId) =>
      _memberStreaksColl(tripId).doc(memberId);

  // --- MoMo Fund Config ---
  @override
  Future<MoMoFundConfig?> getFundConfig(String tripId) async {
    final doc = await _fundConfigDoc(tripId).get();
    if (!doc.exists || doc.data() == null) return null;
    return MoMoFundConfig.fromMap(doc.data() as Map<String, dynamic>, tripId: tripId);
  }

  @override
  Stream<MoMoFundConfig?> watchFundConfig(String tripId) {
    return _fundConfigDoc(tripId).snapshots().map((doc) {
      if (!doc.exists || doc.data() == null) return null;
      return MoMoFundConfig.fromMap(doc.data() as Map<String, dynamic>, tripId: tripId);
    });
  }

  @override
  Future<void> saveFundConfig(MoMoFundConfig config) async {
    await _fundConfigDoc(config.tripId).set(config.toMap(), SetOptions(merge: true));
  }

  // --- Saving Plan ---
  @override
  Future<SavingPlan?> getSavingPlan(String tripId, String memberId) async {
    final doc = await _savingPlanDoc(tripId, memberId).get();
    if (!doc.exists || doc.data() == null) return null;
    return SavingPlan.fromMap(doc.data() as Map<String, dynamic>, id: doc.id);
  }

  @override
  Stream<SavingPlan?> watchSavingPlan(String tripId, String memberId) {
    return _savingPlanDoc(tripId, memberId).snapshots().map((doc) {
      if (!doc.exists || doc.data() == null) return null;
      return SavingPlan.fromMap(doc.data() as Map<String, dynamic>, id: doc.id);
    });
  }

  @override
  Stream<List<SavingPlan>> watchTripSavingPlans(String tripId) {
    return _savingPlansColl(tripId).snapshots().map(
          (snapshot) => snapshot.docs
              .map((d) => SavingPlan.fromMap(d.data() as Map<String, dynamic>, id: d.id))
              .toList(),
        );
  }

  @override
  Future<void> saveSavingPlan(SavingPlan plan) async {
    await _savingPlanDoc(plan.tripId, plan.memberId).set(plan.toMap(), SetOptions(merge: true));
  }

  // --- Deposit Records ---
  @override
  Future<void> submitDeposit(DepositRecord record, {File? receiptImage}) async {
    String? imageUrl = record.receiptImageUrl;

    if (receiptImage != null) {
      final fileName = '${DateTime.now().millisecondsSinceEpoch}_${record.id}.jpg';
      final storageRef = _storage.ref().child('trips/${record.tripId}/receipts/$fileName');
      final uploadTask = await storageRef.putFile(receiptImage);
      imageUrl = await uploadTask.ref.getDownloadURL();
    }

    final recordToSave = record.copyWith(receiptImageUrl: imageUrl);
    await _depositRecordsColl(record.tripId).doc(record.id).set(recordToSave.toMap());
  }

  @override
  Future<List<DepositRecord>> getPendingDeposits(String tripId) async {
    final snapshot = await _depositRecordsColl(tripId)
        .where('status', isEqualTo: 'PENDING')
        .get();

    final list = snapshot.docs
        .map((d) => DepositRecord.fromMap(d.data() as Map<String, dynamic>, id: d.id))
        .toList();
    list.sort((a, b) => b.depositDate.compareTo(a.depositDate));
    return list;
  }

  @override
  Stream<List<DepositRecord>> watchPendingDeposits(String tripId) {
    return _depositRecordsColl(tripId)
        .where('status', isEqualTo: 'PENDING')
        .snapshots()
        .map((snapshot) {
      final list = snapshot.docs
          .map((d) => DepositRecord.fromMap(d.data() as Map<String, dynamic>, id: d.id))
          .toList();
      list.sort((a, b) => b.depositDate.compareTo(a.depositDate));
      return list;
    });
  }

  @override
  Stream<List<DepositRecord>> watchTripDeposits(String tripId) {
    return _depositRecordsColl(tripId).snapshots().map((snapshot) {
      final list = snapshot.docs
          .map((d) => DepositRecord.fromMap(d.data() as Map<String, dynamic>, id: d.id))
          .toList();
      list.sort((a, b) => b.depositDate.compareTo(a.depositDate));
      return list;
    });
  }

  @override
  Stream<List<DepositRecord>> watchMemberDeposits(String tripId, String memberId) {
    return _depositRecordsColl(tripId)
        .where('memberId', isEqualTo: memberId)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((d) => DepositRecord.fromMap(d.data() as Map<String, dynamic>, id: d.id))
            .toList());
  }

  @override
  Future<void> updateDepositStatus({
    required String tripId,
    required String depositId,
    required DepositStatus status,
    required String reviewerId,
    String? rejectionReason,
  }) async {
    final depositRef = _depositRecordsColl(tripId).doc(depositId);

    // Firestore transactions require all reads before any writes.
    await _firestore.runTransaction((transaction) async {
      final depositSnap = await transaction.get(depositRef);
      if (!depositSnap.exists) {
        throw Exception('Deposit record $depositId not found.');
      }
      final depositData = depositSnap.data() as Map<String, dynamic>;
      final parsedDeposit = DepositRecord.fromMap(depositData, id: depositSnap.id);
      final isTransitionToApproved =
          status == DepositStatus.approved && parsedDeposit.status != DepositStatus.approved;

      final fundDocRef = _fundConfigDoc(tripId);
      final planDocRef = parsedDeposit.memberId.isNotEmpty
          ? _savingPlanDoc(tripId, parsedDeposit.memberId)
          : null;
      final streakDocRef = parsedDeposit.memberId.isNotEmpty
          ? _memberStreakDoc(tripId, parsedDeposit.memberId)
          : null;

      DocumentSnapshot? fundSnap;
      DocumentSnapshot? planSnap;
      DocumentSnapshot? streakSnap;

      if (isTransitionToApproved) {
        fundSnap = await transaction.get(fundDocRef);
        if (planDocRef != null) {
          planSnap = await transaction.get(planDocRef);
        }
        if (streakDocRef != null) {
          streakSnap = await transaction.get(streakDocRef);
        }
      }

      final statusStr = switch (status) {
        DepositStatus.approved => 'APPROVED',
        DepositStatus.rejected => 'REJECTED',
        DepositStatus.pending => 'PENDING',
      };

      final trimmedReason = rejectionReason?.trim();
      final updatePayload = <String, dynamic>{
        'status': statusStr,
        'approvedBy': reviewerId,
        'approvedAt': Timestamp.now(),
        if (status == DepositStatus.rejected && trimmedReason != null && trimmedReason.isNotEmpty)
          'rejectionReason': trimmedReason,
      };
      transaction.update(depositRef, updatePayload);

      if (isTransitionToApproved) {
        if (fundSnap != null && fundSnap.exists) {
          transaction.update(fundDocRef, {
            'currentCollectedAmount': FieldValue.increment(parsedDeposit.amount),
            'updatedAt': Timestamp.now(),
          });
        }

        if (planDocRef != null && planSnap != null && planSnap.exists) {
          transaction.update(planDocRef, {
            'paidAmount': FieldValue.increment(parsedDeposit.amount),
            'completedInstallments': FieldValue.increment(1),
          });
        }

        if (streakDocRef != null) {
          final currentStreak = (streakSnap != null && streakSnap.exists && streakSnap.data() != null)
              ? MemberStreak.fromMap(
                  streakSnap.data() as Map<String, dynamic>,
                  memberId: parsedDeposit.memberId,
                  tripId: tripId,
                )
              : MemberStreak(memberId: parsedDeposit.memberId, tripId: tripId);

          final updatedStreak = SavingStreakCalculator.recordCheckIn(
            currentStreak,
            parsedDeposit.depositDate,
            referenceDate: DateTime.now(),
          );
          transaction.set(streakDocRef, updatedStreak.toMap(), SetOptions(merge: true));
        }
      }
    });
  }

  // --- Member Streak ---
  @override
  Future<MemberStreak> getMemberStreak(String tripId, String memberId) async {
    final doc = await _memberStreakDoc(tripId, memberId).get();
    if (!doc.exists || doc.data() == null) {
      return MemberStreak(memberId: memberId, tripId: tripId);
    }
    return MemberStreak.fromMap(doc.data() as Map<String, dynamic>, memberId: memberId, tripId: tripId);
  }

  @override
  Stream<MemberStreak> watchMemberStreak(String tripId, String memberId) {
    return _memberStreakDoc(tripId, memberId).snapshots().map((doc) {
      if (!doc.exists || doc.data() == null) {
        return MemberStreak(memberId: memberId, tripId: tripId);
      }
      return MemberStreak.fromMap(doc.data() as Map<String, dynamic>, memberId: memberId, tripId: tripId);
    });
  }

  @override
  Stream<List<MemberStreak>> watchTripStreaks(String tripId) {
    return _memberStreaksColl(tripId).snapshots().map(
          (snapshot) => snapshot.docs
              .map(
                (d) => MemberStreak.fromMap(
                  d.data() as Map<String, dynamic>,
                  memberId: d.id,
                  tripId: tripId,
                ),
              )
              .toList(),
        );
  }

  @override
  Future<void> updateMemberStreak(MemberStreak streak) async {
    await _memberStreakDoc(streak.tripId, streak.memberId).set(streak.toMap(), SetOptions(merge: true));
  }
}
