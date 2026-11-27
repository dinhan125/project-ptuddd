import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../models/saving_plan.dart';
import '../../providers/saving_plan_provider.dart';
import '../../utils/saving_calculator.dart';
import '../widgets/module_provider_scope.dart';

class SavingPlanScreen extends StatelessWidget {
  final String tripId;
  final String memberId;
  final String memberName;
  final double defaultTargetAmount;
  final DateTime? tripDepartureDate;

  const SavingPlanScreen({
    super.key,
    required this.tripId,
    required this.memberId,
    required this.memberName,
    this.defaultTargetAmount = 3000000,
    this.tripDepartureDate,
  });

  @override
  Widget build(BuildContext context) {
    return ModuleProviderScope(
      child: _SavingPlanContent(
        tripId: tripId,
        memberId: memberId,
        memberName: memberName,
        defaultTargetAmount: defaultTargetAmount,
        tripDepartureDate: tripDepartureDate,
      ),
    );
  }
}

class _SavingPlanContent extends ConsumerStatefulWidget {
  final String tripId;
  final String memberId;
  final String memberName;
  final double defaultTargetAmount;
  final DateTime? tripDepartureDate;

  const _SavingPlanContent({
    required this.tripId,
    required this.memberId,
    required this.memberName,
    required this.defaultTargetAmount,
    this.tripDepartureDate,
  });

  @override
  ConsumerState<_SavingPlanContent> createState() => _SavingPlanContentState();
}

class _SavingPlanContentState extends ConsumerState<_SavingPlanContent> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _amountController;
  late DateTime _startDate;
  late DateTime _deadlineDate;
  SavingFrequency _frequency = SavingFrequency.weekly;
  SavingPlanCalculationResult? _calculationPreview;

  @override
  void initState() {
    super.initState();
    _amountController = TextEditingController(
      text: widget.defaultTargetAmount.toStringAsFixed(0),
    );
    _startDate = DateTime.now();
    _deadlineDate = widget.tripDepartureDate ?? _startDate.add(const Duration(days: 30));
    _updateCalculationPreview();
  }

  @override
  void dispose() {
    _amountController.dispose();
    super.dispose();
  }

  void _updateCalculationPreview() {
    final amount = double.tryParse(_amountController.text.trim()) ?? 0;
    if (amount > 0 && _deadlineDate.isAfter(_startDate)) {
      setState(() {
        _calculationPreview = SavingCalculator.calculateInstallments(
          targetAmount: amount,
          startDate: _startDate,
          deadlineDate: _deadlineDate,
          preferredFrequency: _frequency,
        );
      });
    } else {
      setState(() {
        _calculationPreview = null;
      });
    }
  }

  Future<void> _selectDeadlineDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _deadlineDate,
      firstDate: _startDate.add(const Duration(days: 1)),
      lastDate: _startDate.add(const Duration(days: 365 * 2)),
    );
    if (picked != null) {
      setState(() {
        _deadlineDate = picked;
      });
      _updateCalculationPreview();
    }
  }

  Future<void> _savePlan() async {
    if (!_formKey.currentState!.validate()) return;
    final amount = double.parse(_amountController.text.trim());

    final params = SavingPlanParams(tripId: widget.tripId, memberId: widget.memberId);
    try {
      await ref.read(savingPlanProvider(params).notifier).createSavingPlan(
            memberName: widget.memberName,
            targetAmount: amount,
            startDate: _startDate,
            deadlineDate: _deadlineDate,
            preferredFrequency: _frequency,
          );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Kế hoạch tích góp đã được tạo thành công!'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Lỗi tạo kế hoạch: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final params = SavingPlanParams(tripId: widget.tripId, memberId: widget.memberId);
    final planAsync = ref.watch(savingPlanProvider(params));

    return Scaffold(
      appBar: AppBar(
        title: const Text('Kế hoạch Tích góp Định kỳ'),
        centerTitle: true,
      ),
      body: planAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, _) => Center(child: Text('Lỗi: $err')),
        data: (existingPlan) {
          return SingleChildScrollView(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                if (existingPlan != null) ...[
                  _buildExistingPlanSummary(existingPlan),
                  const SizedBox(height: 24),
                  const Divider(),
                  const SizedBox(height: 16),
                  Text(
                    'Điều chỉnh lại kế hoạch',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                  const SizedBox(height: 12),
                ],
                _buildPlanForm(),
                if (_calculationPreview != null) ...[
                  const SizedBox(height: 24),
                  _buildCalculationPreviewCard(_calculationPreview!),
                ],
                const SizedBox(height: 24),
                FilledButton.icon(
                  onPressed: _savePlan,
                  icon: const Icon(Icons.check_circle_outline),
                  label: Text(
                    existingPlan != null ? 'Cập nhật Kế hoạch' : 'Tạo Kế hoạch Tích góp',
                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  style: FilledButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildExistingPlanSummary(SavingPlan plan) {
    final progress = plan.targetAmount > 0
        ? (plan.paidAmount / plan.targetAmount).clamp(0.0, 1.0)
        : 0.0;

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Kế hoạch của ${plan.memberName}',
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                Chip(
                  label: Text(
                    plan.status == SavingPlanStatus.completed ? 'ĐÃ HOÀN THÀNH' : 'ĐANG THỰC HIỆN',
                    style: const TextStyle(fontSize: 12, color: Colors.white),
                  ),
                  backgroundColor: plan.status == SavingPlanStatus.completed
                      ? Colors.green
                      : Theme.of(context).primaryColor,
                ),
              ],
            ),
            const SizedBox(height: 12),
            LinearProgressIndicator(
              value: progress,
              minHeight: 8,
              borderRadius: BorderRadius.circular(4),
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Đã nộp: ${plan.paidAmount.toStringAsFixed(0)} VND'),
                Text('Mục tiêu: ${plan.targetAmount.toStringAsFixed(0)} VND'),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              'Tiến độ: ${plan.completedInstallments}/${plan.totalInstallments} kỳ '
              '(${plan.installmentAmount.toStringAsFixed(0)} VND/${plan.frequency.name})',
              style: TextStyle(color: Colors.grey.shade700),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPlanForm() {
    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          TextFormField(
            controller: _amountController,
            keyboardType: TextInputType.number,
            decoration: const InputDecoration(
              labelText: 'Tổng kinh phí mục tiêu (VND)',
              prefixIcon: Icon(Icons.payments_outlined),
              border: OutlineInputBorder(),
            ),
            validator: (val) {
              if (val == null || val.isEmpty) return 'Vui lòng nhập số tiền';
              final numVal = double.tryParse(val);
              if (numVal == null || numVal <= 0) return 'Số tiền phải lớn hơn 0';
              return null;
            },
            onChanged: (_) => _updateCalculationPreview(),
          ),
          const SizedBox(height: 16),
          ListTile(
            shape: RoundedRectangleBorder(
              side: BorderSide(color: Colors.grey.shade400),
              borderRadius: BorderRadius.circular(4),
            ),
            leading: const Icon(Icons.calendar_today_outlined),
            title: const Text('Ngày xuất phát (Hạn chót)'),
            subtitle: Text('${_deadlineDate.day}/${_deadlineDate.month}/${_deadlineDate.year}'),
            trailing: const Icon(Icons.edit_calendar),
            onTap: _selectDeadlineDate,
          ),
          const SizedBox(height: 16),
          const Text(
            'Chu kỳ tích góp mong muốn:',
            style: TextStyle(fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 8),
          SegmentedButton<SavingFrequency>(
            segments: const [
              ButtonSegment(
                value: SavingFrequency.daily,
                label: Text('Hàng ngày'),
                icon: Icon(Icons.today),
              ),
              ButtonSegment(
                value: SavingFrequency.weekly,
                label: Text('Hàng tuần'),
                icon: Icon(Icons.date_range),
              ),
              ButtonSegment(
                value: SavingFrequency.monthly,
                label: Text('Hàng tháng'),
                icon: Icon(Icons.calendar_month),
              ),
            ],
            selected: {_frequency},
            onSelectionChanged: (selected) {
              setState(() {
                _frequency = selected.first;
              });
              _updateCalculationPreview();
            },
          ),
        ],
      ),
    );
  }

  Widget _buildCalculationPreviewCard(SavingPlanCalculationResult result) {
    return Card(
      color: Colors.blue.shade50,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.auto_awesome, color: Colors.blue),
                const SizedBox(width: 8),
                Text(
                  'Kế hoạch chia nhỏ tự động',
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: Colors.blue.shade900,
                      ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              '• Tần suất: ${result.frequency == SavingFrequency.daily ? "Hàng ngày" : result.frequency == SavingFrequency.weekly ? "Hàng tuần" : "Hàng tháng"}',
              style: const TextStyle(fontWeight: FontWeight.w500),
            ),
            Text('• Số kỳ đóng: ${result.totalInstallments} kỳ'),
            Text('• Số tiền mỗi kỳ: ${result.installmentAmount.toStringAsFixed(0)} VND'),
            if (result.finalInstallmentAmount != result.installmentAmount)
              Text(
                '• Kỳ cuối cùng điều chỉnh: ${result.finalInstallmentAmount.toStringAsFixed(0)} VND',
                style: const TextStyle(color: Colors.deepOrange, fontWeight: FontWeight.bold),
              ),
            const SizedBox(height: 12),
            const Text(
              'Lịch đóng chi tiết các kỳ:',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 6),
            SizedBox(
              height: 140,
              child: ListView.separated(
                itemCount: result.schedule.length,
                separatorBuilder: (_, _) => const Divider(height: 8),
                itemBuilder: (context, idx) {
                  final item = result.schedule[idx];
                  return Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('Kỳ ${item.index} (${item.dueDate.day}/${item.dueDate.month}/${item.dueDate.year})'),
                      Text(
                        '${item.amount.toStringAsFixed(0)} VND',
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                          color: item.isAdjusted ? Colors.deepOrange : Colors.black87,
                        ),
                      ),
                    ],
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
