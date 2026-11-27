import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';
import '../models/place_plan.dart';
import '../models/place_suggestion.dart';
import '../repository/itinerary_repository.dart';
import '../repository/place_discovery_repository.dart';
import '../utils/schedule_conflict_helper.dart';

final placeDiscoveryRepositoryProvider = Provider(
  (ref) => PlaceDiscoveryRepository(),
);
final selectedDayProvider = StateProvider.family<int, String>(
  (ref, tripId) => 1,
);
final suggestionFilterProvider = StateProvider<PlaceCategory?>((ref) => null);
final suggestionQueryProvider = StateProvider<String>((ref) => '');

final itineraryProvider =
    NotifierProvider.family<ItineraryNotifier, ItineraryState, String>(
      ItineraryNotifier.new,
    );

class ItineraryState {
  final List<PlacePlan> plans;
  final List<PlaceSuggestion> suggestions;
  final bool loading;
  final String? error;
  const ItineraryState({
    this.plans = const [],
    this.suggestions = const [],
    this.loading = false,
    this.error,
  });
  List<PlacePlan> forDay(int day) =>
      plans.where((p) => p.dayNumber == day).toList()
        ..sort((a, b) => a.sortOrder.compareTo(b.sortOrder));
  List<String> conflicts(int day) => findConflictingPlanIds(forDay(day));
  double dayCost(int day) => totalCost(forDay(day));
  double get tripCost => totalCost(plans);
}

class ItineraryNotifier extends Notifier<ItineraryState> {
  final String tripId;
  ItineraryNotifier(this.tripId);
  late final ItineraryRepository _repository;
  @override
  ItineraryState build() {
    _repository = ref.watch(itineraryRepositoryProvider);
    _load();
    return const ItineraryState(loading: true);
  }

  Future<void> _load() async {
    try {
      final plans = await _repository.watchPlans(tripId).first;
      state = ItineraryState(plans: plans, suggestions: state.suggestions);
    } catch (e) {
      state = ItineraryState(error: e.toString());
    }
  }

  Future<void> save(PlacePlan plan) async {
    await _repository.savePlan(plan);
    await _load();
  }

  Future<void> delete(PlacePlan plan) async {
    await _repository.deletePlan(plan.tripId, plan.id);
    await _load();
  }

  Future<void> reorder(int day, int oldIndex, int newIndex) async {
    final list = state.forDay(day);
    if (newIndex > oldIndex) newIndex--;
    final item = list.removeAt(oldIndex);
    list.insert(newIndex, item);
    final updated = [
      for (var i = 0; i < list.length; i++) list[i].copyWith(sortOrder: i),
    ];
    await _repository.reorderPlans(tripId, day, updated);
    await _load();
  }

  Future<void> searchSuggestions({
    String query = '',
    PlaceCategory? category,
  }) async {
    state = ItineraryState(
      plans: state.plans,
      suggestions: state.suggestions,
      loading: true,
    );
    final items = await ref
        .read(placeDiscoveryRepositoryProvider)
        .search(query: query, category: category);
    state = ItineraryState(plans: state.plans, suggestions: items);
  }
}
