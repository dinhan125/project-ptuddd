import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/momo_fund_config.dart';
import '../models/saving_plan.dart';
import '../models/deposit_record.dart';
import '../models/member_streak.dart';
import 'in_memory_saving_repository.dart';
import 'saving_repository.dart';

final savingRepositoryProvider = Provider<SavingRepository>((ref) {
  if (Firebase.apps.isEmpty) {
    return InMemorySavingRepository();
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

  DocumentReference _savingPlanDoc(String tripId, String memberId) =>
      _firestore.collection('trips').doc(tripId).collection('saving_plans').doc(memberId);

  CollectionReference _depositRecordsColl(String tripId) =>
      _firestore.collection('trips').doc(tripId).collection('deposit_records');

  DocumentReference _memberStreakDoc(String tripId, String memberId) =>
      _firestore.collection('trips').doc(tripId).collection('member_streaks').doc(memberId);

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
        .orderBy('depositDate', descending: true)
        .get();

    return snapshot.docs
        .map((d) => DepositRecord.fromMap(d.data() as Map<String, dynamic>, id: d.id))
        .toList();
  }

  @override
  Stream<List<DepositRecord>> watchPendingDeposits(String tripId) {
    return _depositRecordsColl(tripId)
        .where('status', isEqualTo: 'PENDING')
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((d) => DepositRecord.fromMap(d.data() as Map<String, dynamic>, id: d.id))
            .toList());
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
  }) async {
    final depositRef = _depositRecordsColl(tripId).doc(depositId);
    
    // Using transaction to atomically update deposit and increment fund progress on approval
    await _firestore.runTransaction((transaction) async {
      final depositSnap = await transaction.get(depositRef);
      if (!depositSnap.exists) {
        throw Exception('Deposit record $depositId not found.');
      }
      final depositData = depositSnap.data() as Map<String, dynamic>;
      final currentStatus = depositData['status'] as String? ?? 'PENDING';
      final amount = (depositData['amount'] as num?)?.toDouble() ?? 0.0;
      final memberId = depositData['memberId'] as String? ?? '';

      String statusStr;
      switch (status) {
        case DepositStatus.approved:
          statusStr = 'APPROVED';
          break;
        case DepositStatus.rejected:
          statusStr = 'REJECTED';
          break;
        case DepositStatus.pending:
          statusStr = 'PENDING';
          break;
      }

      transaction.update(depositRef, {
        'status': statusStr,
        'approvedBy': reviewerId,
        'approvedAt': Timestamp.now(),
      });

      // If transition to APPROVED from PENDING, update fund collected amount and member paidAmount
      if (status == DepositStatus.approved && currentStatus != 'APPROVED') {
        final fundDocRef = _fundConfigDoc(tripId);
        transaction.update(fundDocRef, {
          'currentCollectedAmount': FieldValue.increment(amount),
          'updatedAt': Timestamp.now(),
        });

        if (memberId.isNotEmpty) {
          final planDocRef = _savingPlanDoc(tripId, memberId);
          transaction.update(planDocRef, {
            'paidAmount': FieldValue.increment(amount),
            'completedInstallments': FieldValue.increment(1),
          });
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
  Future<void> updateMemberStreak(MemberStreak streak) async {
    await _memberStreakDoc(streak.tripId, streak.memberId).set(streak.toMap(), SetOptions(merge: true));
  }
}
