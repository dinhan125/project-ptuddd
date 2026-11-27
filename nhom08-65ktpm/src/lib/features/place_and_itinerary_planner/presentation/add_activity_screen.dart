import 'package:flutter/material.dart';
import '../models/place_plan.dart';
import '../models/place_suggestion.dart';
import '../providers/itinerary_providers.dart';
import '../utils/schedule_conflict_helper.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class AddActivityScreen extends ConsumerStatefulWidget {
  final String tripId;
  final PlacePlan? initialPlan;
  final PlaceSuggestion? suggestion;
  const AddActivityScreen({
    super.key,
    required this.tripId,
    this.initialPlan,
    this.suggestion,
  });
  @override
  ConsumerState<AddActivityScreen> createState() => _AddActivityScreenState();
}

class _AddActivityScreenState extends ConsumerState<AddActivityScreen> {
  late final TextEditingController name = TextEditingController(
    text: widget.initialPlan?.placeName ?? widget.suggestion?.name ?? '',
  );
  late final TextEditingController address = TextEditingController(
    text: widget.initialPlan?.address ?? widget.suggestion?.address ?? '',
  );
  late final TextEditingController lat = TextEditingController(
    text:
        '${widget.initialPlan?.latitude ?? widget.suggestion?.latitude ?? 10.7769}',
  );
  late final TextEditingController lon = TextEditingController(
    text:
        '${widget.initialPlan?.longitude ?? widget.suggestion?.longitude ?? 106.7009}',
  );
  late final TextEditingController duration = TextEditingController(
    text:
        '${widget.initialPlan?.durationMinutes ?? widget.suggestion?.defaultDurationMinutes ?? 60}',
  );
  late final TextEditingController ticket = TextEditingController(
    text:
        '${widget.initialPlan?.ticketCost ?? widget.suggestion?.estimatedTicketCost ?? 0}',
  );
  late final TextEditingController food = TextEditingController(
    text:
        '${widget.initialPlan?.foodCost ?? widget.suggestion?.estimatedFoodCost ?? 0}',
  );
  late TimeOfDay time = TimeOfDay.fromDateTime(
    widget.initialPlan?.startTime ?? DateTime.now(),
  );
  late int day = widget.initialPlan?.dayNumber ?? 1;
  late PlaceCategory category =
      widget.initialPlan?.category ??
      widget.suggestion?.category ??
      PlaceCategory.attraction;
  @override
  void dispose() {
    for (final c in [name, address, lat, lon, duration, ticket, food])
      c.dispose();
    super.dispose();
  }

  DateTime get start => DateTime(2020, 1, 1, time.hour, time.minute);
  Future<void> _submit() async {
    final old = widget.initialPlan;
    final plan = PlacePlan(
      id:
          old?.id ??
          '${widget.tripId}_${DateTime.now().microsecondsSinceEpoch}',
      tripId: widget.tripId,
      dayNumber: day,
      sortOrder:
          old?.sortOrder ??
          ref.read(itineraryProvider(widget.tripId)).forDay(day).length,
      placeName: name.text.trim(),
      category: category,
      latitude: double.tryParse(lat.text) ?? 0,
      longitude: double.tryParse(lon.text) ?? 0,
      address: address.text.trim(),
      startTime: start,
      durationMinutes: int.tryParse(duration.text) ?? 60,
      ticketCost: double.tryParse(ticket.text) ?? 0,
      foodCost: double.tryParse(food.text) ?? 0,
    );
    if (plan.placeName.isEmpty) return;
    await ref.read(itineraryProvider(widget.tripId).notifier).save(plan);
    if (mounted) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final plans = ref.watch(itineraryProvider(widget.tripId)).forDay(day);
    final conflict = plans
        .where(
          (p) =>
              p.id != widget.initialPlan?.id &&
              p.startTime.isBefore(
                start.add(Duration(minutes: int.tryParse(duration.text) ?? 60)),
              ) &&
              start.isBefore(p.endTime),
        )
        .isNotEmpty;
    return Scaffold(
      appBar: AppBar(
        title: Text(
          widget.initialPlan == null ? 'Thêm địa điểm' : 'Sửa địa điểm',
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          TextField(
            controller: name,
            decoration: const InputDecoration(labelText: 'Tên địa điểm *'),
          ),
          TextField(
            controller: address,
            decoration: const InputDecoration(labelText: 'Địa chỉ'),
          ),
          DropdownButtonFormField<PlaceCategory>(
            value: category,
            decoration: const InputDecoration(labelText: 'Phân loại'),
            items: PlaceCategory.values
                .map(
                  (c) => DropdownMenuItem(value: c, child: Text(_category(c))),
                )
                .toList(),
            onChanged: (v) => setState(() => category = v!),
          ),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: lat,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(labelText: 'Vĩ độ'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: TextField(
                  controller: lon,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(labelText: 'Kinh độ'),
                ),
              ),
            ],
          ),
          DropdownButtonFormField<int>(
            value: day,
            decoration: const InputDecoration(labelText: 'Ngày'),
            items: List.generate(
              14,
              (i) =>
                  DropdownMenuItem(value: i + 1, child: Text('Ngày ${i + 1}')),
            ),
            onChanged: (v) => setState(() => day = v!),
          ),
          ListTile(
            title: Text('Bắt đầu: ${time.format(context)}'),
            trailing: const Icon(Icons.schedule),
            onTap: () async {
              final picked = await showTimePicker(
                context: context,
                initialTime: time,
              );
              if (picked != null) setState(() => time = picked);
            },
          ),
          TextField(
            controller: duration,
            keyboardType: TextInputType.number,
            decoration: const InputDecoration(
              labelText: 'Thời gian dừng (phút)',
            ),
          ),
          Text(
            'Kết thúc dự kiến: ${formatTime(start.add(Duration(minutes: int.tryParse(duration.text) ?? 60)))}',
          ),
          TextField(
            controller: ticket,
            keyboardType: TextInputType.number,
            decoration: const InputDecoration(labelText: 'Chi phí vé (VNĐ)'),
          ),
          TextField(
            controller: food,
            keyboardType: TextInputType.number,
            decoration: const InputDecoration(
              labelText: 'Ăn uống/phát sinh (VNĐ)',
            ),
          ),
          if (conflict)
            const Card(
              color: Color(0xfffff3cd),
              child: Padding(
                padding: EdgeInsets.all(12),
                child: Text(
                  'Cảnh báo: khung giờ này đang trùng với một địa điểm khác trong ngày.',
                  style: TextStyle(color: Colors.brown),
                ),
              ),
            ),
          const SizedBox(height: 16),
          FilledButton.icon(
            onPressed: _submit,
            icon: const Icon(Icons.save),
            label: const Text('Lưu lịch trình'),
          ),
        ],
      ),
    );
  }

  String _category(PlaceCategory c) => switch (c) {
    PlaceCategory.attraction => 'Tham quan',
    PlaceCategory.food => 'Ăn uống',
    PlaceCategory.hotel => 'Khách sạn',
  };
}
