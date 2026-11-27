import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import '../../../core/services/supabase_storage_service.dart';
import '../models/place_plan.dart';

abstract class ItineraryRepository {
  Stream<List<PlacePlan>> watchPlans(String tripId);
  Future<void> savePlan(PlacePlan plan);
  Future<void> deletePlan(String tripId, String planId);
  Future<void> reorderPlans(
    String tripId,
    int dayNumber,
    List<PlacePlan> plans,
  );
  Future<PlacePlan> checkIn(PlacePlan plan, XFile image);
}

final itineraryRepositoryProvider = Provider<ItineraryRepository>((ref) {
  if (Firebase.apps.isEmpty) return InMemoryItineraryRepository();
  return FirestoreItineraryRepository(
    FirebaseFirestore.instance,
    ref.watch(supabaseStorageServiceProvider),
  );
});

class FirestoreItineraryRepository implements ItineraryRepository {
  final FirebaseFirestore firestore;
  final SupabaseStorageService storageService;
  FirestoreItineraryRepository(this.firestore, this.storageService);
  CollectionReference<Map<String, dynamic>> _collection(String tripId) =>
      firestore.collection('trips').doc(tripId).collection('place_plans');

  @override
  Stream<List<PlacePlan>> watchPlans(String tripId) => _collection(tripId)
      .orderBy('sortOrder')
      .snapshots()
      .map(
        (snapshot) => snapshot.docs
            .map((doc) => PlacePlan.fromMap(doc.data(), id: doc.id))
            .toList(),
      );

  @override
  Future<void> savePlan(PlacePlan plan) => _collection(
    plan.tripId,
  ).doc(plan.id).set(plan.toMap(), SetOptions(merge: true));

  @override
  Future<void> deletePlan(String tripId, String planId) =>
      _collection(tripId).doc(planId).delete();

  @override
  Future<void> reorderPlans(
    String tripId,
    int dayNumber,
    List<PlacePlan> plans,
  ) async {
    final batch = firestore.batch();
    for (var i = 0; i < plans.length; i++) {
      batch.update(_collection(tripId).doc(plans[i].id), {
        'sortOrder': i,
        'dayNumber': dayNumber,
      });
    }
    await batch.commit();
  }

  @override
  Future<PlacePlan> checkIn(PlacePlan plan, XFile image) async {
    final photoUrl = await storageService.uploadBytes(
      path: 'trips/${plan.tripId}/checkins/${plan.id}.jpg',
      bytes: await image.readAsBytes(),
    );
    final updated = plan.copyWith(
      isCheckedIn: true,
      checkedInAt: DateTime.now(),
      checkInPhotoUrl: photoUrl,
    );
    await savePlan(updated);
    return updated;
  }
}

class InMemoryItineraryRepository implements ItineraryRepository {
  final _data = <String, List<PlacePlan>>{};
  @override
  Stream<List<PlacePlan>> watchPlans(String tripId) =>
      Stream.value(List.unmodifiable(_data[tripId] ?? []));
  @override
  Future<void> savePlan(PlacePlan plan) async {
    final list = _data.putIfAbsent(plan.tripId, () => []);
    final index = list.indexWhere((item) => item.id == plan.id);
    if (index < 0) {
      list.add(plan);
    } else {
      list[index] = plan;
    }
  }

  @override
  Future<void> deletePlan(String tripId, String planId) async =>
      _data[tripId]?.removeWhere((p) => p.id == planId);
  @override
  Future<void> reorderPlans(
    String tripId,
    int dayNumber,
    List<PlacePlan> plans,
  ) async {
    for (var i = 0; i < plans.length; i++) {
      await savePlan(plans[i].copyWith(sortOrder: i));
    }
  }

  @override
  Future<PlacePlan> checkIn(PlacePlan plan, XFile image) async =>
      plan.copyWith(isCheckedIn: true, checkedInAt: DateTime.now());
}
