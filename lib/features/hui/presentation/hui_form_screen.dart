import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:so_hui_app/core/database/database.dart';
import 'package:so_hui_app/core/providers/providers.dart';
import 'package:so_hui_app/models/models.dart';
import 'package:so_hui_app/common/utils/validators.dart';
import 'package:so_hui_app/common/utils/date_formatter.dart';

class HuiFormScreen extends ConsumerStatefulWidget {
  final int? huiId;

  const HuiFormScreen({super.key, this.huiId});

  @override
  ConsumerState<HuiFormScreen> createState() => _HuiFormScreenState();
}

class _HuiFormScreenState extends ConsumerState<HuiFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _totalPeriodsController = TextEditingController();
  final _numMembersController = TextEditingController();
  final _contributionAmountController = TextEditingController();
  final _notesController = TextEditingController();

  HuiType _selectedType = HuiType.fixed;
  FrequencyType _selectedFrequency = FrequencyType.monthly;
  DateTime _startDate = DateTime.now();
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    if (widget.huiId != null) {
      _loadHuiData();
    }
  }

  Future<void> _loadHuiData() async {
    final huiRepo = ref.read(huiRepositoryProvider);
    final hui = await huiRepo.getHuiGroupById(widget.huiId!);
    if (hui != null) {
      setState(() {
        _nameController.text = hui.name;
        _totalPeriodsController.text = hui.totalPeriods.toString();
        _numMembersController.text = hui.numMembers.toString();
        _contributionAmountController.text = hui.contributionAmount.toString();
        _notesController.text = hui.notes ?? '';
        _selectedType = hui.type;
        _selectedFrequency = hui.frequency;
        _startDate = hui.startDate;
      });
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _totalPeriodsController.dispose();
    _numMembersController.dispose();
    _contributionAmountController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _selectDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _startDate,
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );
    if (picked != null) {
      setState(() {
        _startDate = picked;
      });
    }
  }

  Future<void> _saveHui() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
    });

    try {
      final huiRepo = ref.read(huiRepositoryProvider);
      final contributionRepo = ref.read(contributionRepositoryProvider);
      final calcService = ref.read(huiCalculationServiceProvider);

      final huiModel = HuiGroupModel(
        id: widget.huiId,
        name: _nameController.text.trim(),
        totalPeriods: int.parse(_totalPeriodsController.text),
        numMembers: int.parse(_numMembersController.text),
        contributionAmount: double.parse(_contributionAmountController.text),
        type: _selectedType,
        startDate: _startDate,
        frequency: _selectedFrequency,
        notes: _notesController.text.trim().isEmpty ? null : _notesController.text.trim(),
      );

      if (widget.huiId == null) {
        // Create new hui
        final huiId = await huiRepo.createHuiGroup(huiModel);
        
        // Generate contributions
        final huiWithId = huiModel.copyWith(id: huiId);
        final contributions = calcService.generateContributions(huiWithId);
        
        for (final contribution in contributions) {
          await contributionRepo.createContribution(contribution);
        }

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Tạo dây hụi thành công')),
          );
          context.go('/hui/$huiId');
        }
      } else {
        // Update existing hui
        await huiRepo.updateHuiGroup(huiModel);
        
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Cập nhật dây hụi thành công')),
          );
          context.pop();
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Lỗi: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.huiId == null ? 'Tạo dây hụi' : 'Chỉnh sửa dây hụi'),
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            TextFormField(
              controller: _nameController,
              decoration: const InputDecoration(
                labelText: 'Tên dây hụi',
                hintText: 'VD: Hụi tháng 1',
              ),
              validator: (value) => Validators.validateRequired(value, 'Tên dây hụi'),
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<HuiType>(
              value: _selectedType,
              decoration: const InputDecoration(
                labelText: 'Loại hụi',
              ),
              items: const [
                DropdownMenuItem(
                  value: HuiType.fixed,
                  child: Text('Hụi chết (không lãi)'),
                ),
                DropdownMenuItem(
                  value: HuiType.interest,
                  child: Text('Hụi sống (có lãi)'),
                ),
              ],
              onChanged: (value) {
                if (value != null) {
                  setState(() {
                    _selectedType = value;
                  });
                }
              },
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _totalPeriodsController,
              decoration: const InputDecoration(
                labelText: 'Tổng số kỳ',
                hintText: 'VD: 12',
              ),
              keyboardType: TextInputType.number,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              validator: (value) => Validators.validateInteger(value, 'Tổng số kỳ'),
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _numMembersController,
              decoration: const InputDecoration(
                labelText: 'Số thành viên',
                hintText: 'VD: 10',
              ),
              keyboardType: TextInputType.number,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              validator: (value) => Validators.validateInteger(value, 'Số thành viên'),
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _contributionAmountController,
              decoration: const InputDecoration(
                labelText: 'Mệnh giá góp (VNĐ)',
                hintText: 'VD: 1000000',
              ),
              keyboardType: TextInputType.number,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              validator: (value) => Validators.validateNumber(value, 'Mệnh giá góp'),
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<FrequencyType>(
              value: _selectedFrequency,
              decoration: const InputDecoration(
                labelText: 'Tần suất kỳ',
              ),
              items: const [
                DropdownMenuItem(
                  value: FrequencyType.daily,
                  child: Text('Hàng ngày'),
                ),
                DropdownMenuItem(
                  value: FrequencyType.weekly,
                  child: Text('Hàng tuần'),
                ),
                DropdownMenuItem(
                  value: FrequencyType.monthly,
                  child: Text('Hàng tháng'),
                ),
              ],
              onChanged: (value) {
                if (value != null) {
                  setState(() {
                    _selectedFrequency = value;
                  });
                }
              },
            ),
            const SizedBox(height: 16),
            ListTile(
              contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
                side: BorderSide(color: Theme.of(context).colorScheme.outline),
              ),
              title: const Text('Ngày bắt đầu'),
              subtitle: Text(DateFormatter.formatDate(_startDate)),
              trailing: const Icon(Icons.calendar_today),
              onTap: _selectDate,
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _notesController,
              decoration: const InputDecoration(
                labelText: 'Ghi chú (tùy chọn)',
                hintText: 'Nhập ghi chú...',
              ),
              maxLines: 3,
            ),
            const SizedBox(height: 24),
            FilledButton(
              onPressed: _isLoading ? null : _saveHui,
              child: _isLoading
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : Text(widget.huiId == null ? 'Tạo dây hụi' : 'Cập nhật'),
            ),
          ],
        ),
      ),
    );
  }
}
