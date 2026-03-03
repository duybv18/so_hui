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
  final List<TextEditingController> _memberNameControllers = [];

  HuiType _selectedType = HuiType.fixed;
  FrequencyType _selectedFrequency = FrequencyType.monthly;
  UserRole _selectedUserRole = UserRole.player;
  DateTime _startDate = DateTime.now();
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _numMembersController.addListener(_syncMemberControllersWithCount);
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
        _selectedUserRole = hui.userRole;
        _startDate = hui.startDate;
      });

      if (hui.userRole == UserRole.admin && hui.id != null) {
        final huiRepo = ref.read(huiRepositoryProvider);
        final members = await huiRepo.getMembersByHuiGroup(hui.id!);
        if (!mounted) return;
        _syncMemberControllersWithCount();
        for (int i = 0; i < _memberNameControllers.length && i < members.length; i++) {
          _memberNameControllers[i].text = members[i].name;
        }
      } else {
        _syncMemberControllersWithCount();
      }
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _totalPeriodsController.dispose();
    _numMembersController.dispose();
    _contributionAmountController.dispose();
    _notesController.dispose();
    for (final controller in _memberNameControllers) {
      controller.dispose();
    }
    super.dispose();
  }

  void _syncMemberControllersWithCount() {
    final targetCount = int.tryParse(_numMembersController.text) ?? 0;
    if (_selectedUserRole != UserRole.admin || targetCount <= 0) {
      for (final controller in _memberNameControllers) {
        controller.dispose();
      }
      _memberNameControllers.clear();
      if (mounted) {
        setState(() {});
      }
      return;
    }

    if (_memberNameControllers.length < targetCount) {
      final toAdd = targetCount - _memberNameControllers.length;
      for (int i = 0; i < toAdd; i++) {
        _memberNameControllers.add(TextEditingController());
      }
    } else if (_memberNameControllers.length > targetCount) {
      final toRemove = _memberNameControllers.length - targetCount;
      for (int i = 0; i < toRemove; i++) {
        final controller = _memberNameControllers.removeLast();
        controller.dispose();
      }
    }

    if (mounted) {
      setState(() {});
    }
  }

  List<String>? _validateAdminMemberNames() {
    if (_selectedUserRole != UserRole.admin) {
      return [];
    }

    final names = _memberNameControllers.map((c) => c.text.trim()).toList();
    if (names.any((name) => name.isEmpty)) {
      return null;
    }

    final lowerSet = <String>{};
    for (final name in names) {
      final normalized = name.toLowerCase();
      if (lowerSet.contains(normalized)) {
        return null;
      }
      lowerSet.add(normalized);
    }

    return names;
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

    final memberNames = _validateAdminMemberNames();
    if (_selectedUserRole == UserRole.admin && memberNames == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Tên người tham gia phải đủ và không được trùng trong cùng dây hụi'),
        ),
      );
      return;
    }

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
        userRole: _selectedUserRole,
        notes: _notesController.text.trim().isEmpty ? null : _notesController.text.trim(),
      );

      if (widget.huiId == null) {
        // Create new hui
        final huiId = await huiRepo.createHuiGroup(huiModel);

        if (_selectedUserRole == UserRole.admin && memberNames != null) {
          await huiRepo.replaceMembers(huiId, memberNames);
        }
        
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

        if (_selectedUserRole == UserRole.admin && memberNames != null) {
          await huiRepo.replaceMembers(widget.huiId!, memberNames);
        }
        
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
            DropdownButtonFormField<UserRole>(
              value: _selectedUserRole,
              decoration: const InputDecoration(
                labelText: 'Vai trò của bạn trong hụi này',
                helperText: 'Chủ hụi không đóng tiền, chỉ nhận tiền dư cuối kỳ',
              ),
              items: const [
                DropdownMenuItem(
                  value: UserRole.player,
                  child: Text('Người chơi'),
                ),
                DropdownMenuItem(
                  value: UserRole.admin,
                  child: Text('Chủ hụi'),
                ),
              ],
              onChanged: (value) {
                if (value != null) {
                  setState(() {
                    _selectedUserRole = value;
                  });
                  _syncMemberControllersWithCount();
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
              onChanged: (_) => _syncMemberControllersWithCount(),
            ),
            if (_selectedUserRole == UserRole.admin && _memberNameControllers.isNotEmpty) ...[
              const SizedBox(height: 16),
              Text(
                'Tên người tham gia',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Mỗi tên phải khác nhau trong cùng dây hụi',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 8),
              ...List.generate(_memberNameControllers.length, (index) {
                return Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: TextFormField(
                    controller: _memberNameControllers[index],
                    decoration: InputDecoration(
                      labelText: 'Người ${index + 1}',
                      hintText: 'Nhập tên người tham gia',
                    ),
                    textInputAction: TextInputAction.next,
                  ),
                );
              }),
            ],
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
