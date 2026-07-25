import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/domain.dart';
import '../../../core/models.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/common.dart';
import '../../../i18n/strings.g.dart';
import '../../marketplace/data/marketplace_repository.dart';
import '../../marketplace/widgets/listing_card.dart';
import '../data/photo_service.dart';
import '../data/seller_repository.dart';
import 'seller_devices_page.dart';

/// Add/edit a device draft with the per-category checklist, live grade
/// preview, and photo management. Photos require the device to exist, so on
/// the "new" path we create the draft as soon as photos are added.
class SellerDeviceFormPage extends ConsumerStatefulWidget {
  const SellerDeviceFormPage({super.key, this.deviceId});

  final int? deviceId;

  @override
  ConsumerState<SellerDeviceFormPage> createState() =>
      _SellerDeviceFormPageState();
}

class _SellerDeviceFormPageState extends ConsumerState<SellerDeviceFormPage> {
  final _formKey = GlobalKey<FormState>();
  final _brand = TextEditingController();
  final _model = TextEditingController();
  final _title = TextEditingController();
  final _description = TextEditingController();
  final _price = TextEditingController();
  final _imei = TextEditingController();
  final _warranty = TextEditingController(text: '90');

  DeviceCategory _category = DeviceCategory.mobile;
  final Map<String, ChecklistResult> _results = {};
  final Map<String, String> _notes = {};

  int? _deviceId;
  DeviceStatus? _originalStatus;
  List<DevicePhoto> _photos = [];
  bool _loading = true;
  bool _saving = false;
  bool _uploading = false;
  Object? _loadError;

  @override
  void initState() {
    super.initState();
    _deviceId = widget.deviceId;
    _load();
  }

  @override
  void dispose() {
    _brand.dispose();
    _model.dispose();
    _title.dispose();
    _description.dispose();
    _price.dispose();
    _imei.dispose();
    _warranty.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    try {
      if (_deviceId != null) {
        final device =
            await ref.read(sellerRepositoryProvider).fetchDevice(_deviceId!);
        if (device != null && mounted) {
          _originalStatus = device.status;
          _category = device.category;
          _brand.text = device.brand;
          _model.text = device.model;
          _title.text = device.title;
          _description.text = device.description ?? '';
          _price.text =
              (device.price.minor ~/ Money.minorPerMajor).toString();
          _warranty.text = device.warrantyDays.toString();
          for (final entry in device.checklist) {
            _results[entry.key] = entry.result;
            if (entry.note != null) _notes[entry.key] = entry.note!;
          }
          _photos = device.photos;
        }
      }
      if (mounted) setState(() => _loading = false);
    } catch (e) {
      if (mounted) {
        setState(() {
          _loadError = e;
          _loading = false;
        });
      }
    }
  }

  List<ChecklistTemplate> _templatesFor(List<ChecklistTemplate> all) => all
      .where((t) => t.category == _category && t.isActive)
      .toList()
    ..sort((a, b) => a.sortOrder.compareTo(b.sortOrder));

  Grade? _previewGrade(List<ChecklistTemplate> templates) {
    final active = _templatesFor(templates);
    if (active.isEmpty) return null;
    final answered =
        active.where((t) => _results.containsKey(t.key)).toList();
    if (answered.length < active.length) return null;
    return gradeOf(answered.map((t) => _results[t.key]!));
  }

  List<ChecklistEntry> _checklistEntries(List<ChecklistTemplate> templates) {
    return [
      for (final template in _templatesFor(templates))
        if (_results.containsKey(template.key))
          ChecklistEntry(
            key: template.key,
            result: _results[template.key]!,
            note: _notes[template.key]?.trim().isEmpty ?? true
                ? null
                : _notes[template.key]!.trim(),
          ),
    ];
  }

  int? _priceMinor() {
    final major = int.tryParse(_price.text.trim());
    if (major == null || major <= 0) return null;
    return major * Money.minorPerMajor;
  }

  /// Ensures a draft row exists (needed before photos can be attached).
  Future<int?> _ensureDeviceSaved(
    List<ChecklistTemplate> templates, {
    required bool requireValid,
  }) async {
    if (requireValid && !_formKey.currentState!.validate()) return null;
    final priceMinor = _priceMinor();
    if (priceMinor == null) {
      if (requireValid) {
        showAppSnackBar(context, t.seller.deviceForm.invalidPrice,
            isError: true);
      }
      return null;
    }
    final shopId = ref.read(myShopProvider).valueOrNull?.id;
    if (shopId == null) return null;

    final grade = _previewGrade(templates);
    final entries = _checklistEntries(templates);
    final imei = _imei.text.trim();
    final repo = ref.read(sellerRepositoryProvider);

    if (_deviceId == null) {
      final id = await repo.createDeviceDraft(
        shopId: shopId,
        category: _category,
        brand: _brand.text.trim(),
        model: _model.text.trim(),
        title: _title.text.trim(),
        description: _description.text.trim().isEmpty
            ? null
            : _description.text.trim(),
        priceMinor: priceMinor,
        currency: Currency.ils,
        grade: grade,
        warrantyDays: int.tryParse(_warranty.text.trim()) ?? 90,
        imei: imei.isEmpty ? null : imei,
        checklist: entries,
      );
      _deviceId = id;
      return id;
    } else {
      await repo.updateDeviceDraft(
        id: _deviceId!,
        category: _category,
        brand: _brand.text.trim(),
        model: _model.text.trim(),
        title: _title.text.trim(),
        description: _description.text.trim().isEmpty
            ? null
            : _description.text.trim(),
        priceMinor: priceMinor,
        currency: Currency.ils,
        grade: grade,
        warrantyDays: int.tryParse(_warranty.text.trim()) ?? 90,
        imei: imei.isEmpty ? null : imei,
        checklist: entries,
      );
      return _deviceId;
    }
  }

  Future<void> _saveDraft(List<ChecklistTemplate> templates) async {
    setState(() => _saving = true);
    try {
      final id = await _ensureDeviceSaved(templates, requireValid: true);
      if (id == null) return;
      // Editing an already-listed device pulls it back into review so an
      // admin re-approves the changes before it returns to the marketplace.
      final resubmitted = _originalStatus == DeviceStatus.listed;
      if (resubmitted) {
        await ref
            .read(sellerRepositoryProvider)
            .setDeviceStatus(id, DeviceStatus.underInspection);
      }
      ref.invalidate(sellerDevicesProvider);
      if (!mounted) return;
      showAppSnackBar(
        context,
        resubmitted
            ? t.seller.devices.resubmitted
            : t.seller.deviceForm.saved,
      );
      context.go('/seller');
    } catch (e) {
      if (mounted) showErrorSnackBar(context, e);
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _addPhotos() async {
    final service = ref.read(photoServiceProvider);
    final files = await service.pickImages();
    if (files.isEmpty) return;

    // A device row must exist before uploading; persist current form first.
    final templates =
        ref.read(checklistTemplatesProvider).valueOrNull ?? const [];
    final shopId = ref.read(myShopProvider).valueOrNull?.id;
    if (shopId == null) return;

    setState(() => _uploading = true);
    try {
      final id = await _ensureDeviceSaved(templates, requireValid: false);
      if (id == null) {
        if (mounted) {
          showAppSnackBar(context, t.seller.deviceForm.invalidPrice,
              isError: true);
        }
        return;
      }
      var order = _photos.length;
      final added = <DevicePhoto>[];
      for (final file in files) {
        final photo = await service.uploadPhoto(
          shopId: shopId,
          deviceId: id,
          file: file,
          sortOrder: order++,
        );
        added.add(photo);
      }
      if (!mounted) return;
      setState(() => _photos = [..._photos, ...added]);
      ref.invalidate(sellerDevicesProvider);
    } catch (e) {
      if (mounted) {
        showAppSnackBar(context, t.seller.deviceForm.uploadFailed,
            isError: true);
      }
    } finally {
      if (mounted) setState(() => _uploading = false);
    }
  }

  Future<void> _removePhoto(DevicePhoto photo) async {
    try {
      await ref.read(photoServiceProvider).softDelete(photo.id);
      if (!mounted) return;
      setState(() => _photos = _photos.where((p) => p.id != photo.id).toList());
      ref.invalidate(sellerDevicesProvider);
    } catch (e) {
      if (mounted) showErrorSnackBar(context, e);
    }
  }

  Future<void> _reorderPhoto(int oldIndex, int newIndex) async {
    setState(() {
      if (newIndex > oldIndex) newIndex -= 1;
      final list = [..._photos];
      final item = list.removeAt(oldIndex);
      list.insert(newIndex, item);
      _photos = list;
    });
    try {
      await ref.read(photoServiceProvider).reorder(_photos);
      ref.invalidate(sellerDevicesProvider);
    } catch (e) {
      if (mounted) showErrorSnackBar(context, e);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final templatesAsync = ref.watch(checklistTemplatesProvider);

    if (_loading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_loadError != null) {
      return ErrorSurface(error: _loadError!, onRetry: _load);
    }

    return AsyncView(
      value: templatesAsync,
      data: (allTemplates) {
        final templates = _templatesFor(allTemplates);
        final grade = _previewGrade(allTemplates);
        final photoCount = _photos.length;

        return Scaffold(
          body: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 720),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Text(
                        _deviceId == null
                            ? t.seller.deviceForm.newTitle
                            : t.seller.deviceForm.editTitle,
                        style: theme.textTheme.headlineSmall
                            ?.copyWith(fontWeight: FontWeight.w700),
                      ),
                      const SizedBox(height: 20),
                      _categorySelector(),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          Expanded(
                            child: TextFormField(
                              controller: _brand,
                              decoration: InputDecoration(
                                labelText: t.seller.deviceForm.brandLabel,
                                hintText: t.seller.deviceForm.brandHint,
                              ),
                              validator: _required,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: TextFormField(
                              controller: _model,
                              decoration: InputDecoration(
                                labelText: t.seller.deviceForm.modelLabel,
                                hintText: t.seller.deviceForm.modelHint,
                              ),
                              validator: _required,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _title,
                        decoration: InputDecoration(
                          labelText: t.seller.deviceForm.titleLabel,
                          hintText: t.seller.deviceForm.titleHint,
                        ),
                        validator: (v) => (v == null || v.trim().length < 3)
                            ? t.common.requiredField
                            : null,
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _description,
                        maxLines: 3,
                        decoration: InputDecoration(
                          labelText: t.seller.deviceForm.descriptionLabel,
                          hintText: t.seller.deviceForm.descriptionHint,
                        ),
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _price,
                        keyboardType: TextInputType.number,
                        decoration: InputDecoration(
                          labelText: t.seller.deviceForm.priceLabel,
                          hintText: t.seller.deviceForm.priceHint,
                          suffixText: Currency.ils.symbol,
                        ),
                        validator: (v) {
                          final n = int.tryParse((v ?? '').trim());
                          return (n == null || n <= 0)
                              ? t.seller.deviceForm.invalidPrice
                              : null;
                        },
                      ),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          Expanded(
                            child: TextFormField(
                              controller: _warranty,
                              keyboardType: TextInputType.number,
                              decoration: InputDecoration(
                                labelText: t.seller.deviceForm.warrantyLabel,
                              ),
                              validator: (v) {
                                final n = int.tryParse((v ?? '').trim());
                                return (n == null || n < 30)
                                    ? t.common.requiredField
                                    : null;
                              },
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: TextFormField(
                              controller: _imei,
                              decoration: InputDecoration(
                                labelText: _category == DeviceCategory.mobile
                                    ? t.seller.deviceForm.imeiLabel
                                    : t.seller.deviceForm.serialLabel,
                                hintText: t.seller.deviceForm.imeiHint,
                              ),
                              validator: (v) {
                                if (_category != DeviceCategory.mobile) {
                                  return null;
                                }
                                // Required for mobiles unless already stored.
                                final stored = _deviceId != null;
                                if ((v == null || v.trim().isEmpty) &&
                                    !stored) {
                                  return t.common.requiredField;
                                }
                                return null;
                              },
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 24),
                      _photosSection(photoCount),
                      const SizedBox(height: 24),
                      _checklistSection(templates, grade),
                      const SizedBox(height: 24),
                      FilledButton.icon(
                        onPressed:
                            _saving ? null : () => _saveDraft(allTemplates),
                        icon: _saving
                            ? const SizedBox(
                                width: 18,
                                height: 18,
                                child:
                                    CircularProgressIndicator(strokeWidth: 2))
                            : const Icon(Icons.save_rounded),
                        label: Text(t.seller.deviceForm.saveDraft),
                      ),
                      const SizedBox(height: 8),
                      OutlinedButton(
                        onPressed: () => context.go('/seller'),
                        child: Text(t.common.cancel),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _categorySelector() {
    return SegmentedButton<DeviceCategory>(
      segments: [
        for (final c in DeviceCategory.values)
          ButtonSegment(
            value: c,
            label: Text(t.enums.category[c.dbValue] ?? c.dbValue),
            icon: Icon(c == DeviceCategory.mobile
                ? Icons.smartphone_rounded
                : Icons.laptop_mac_rounded),
          ),
      ],
      selected: {_category},
      onSelectionChanged: _deviceId != null
          ? null // category is fixed once a draft exists (checklist is tied to it)
          : (value) => setState(() {
                _category = value.first;
                _results.clear();
                _notes.clear();
              }),
    );
  }

  Widget _photosSection(int count) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          t.seller.deviceForm.photosTitle,
          style:
              theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
        ),
        const SizedBox(height: 4),
        Text(
          t.seller.deviceForm.photosHint,
          style: theme.textTheme.bodySmall
              ?.copyWith(color: theme.colorScheme.onSurfaceVariant),
        ),
        const SizedBox(height: 12),
        if (_photos.isNotEmpty)
          ReorderableWrap(
            photos: _photos,
            onReorder: _reorderPhoto,
            onRemove: _removePhoto,
          ),
        const SizedBox(height: 12),
        Row(
          children: [
            OutlinedButton.icon(
              onPressed: _uploading ? null : _addPhotos,
              icon: _uploading
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2))
                  : const Icon(Icons.add_photo_alternate_rounded, size: 18),
              label: Text(_uploading
                  ? t.seller.deviceForm.uploading
                  : t.seller.deviceForm.addPhotos),
            ),
            const SizedBox(width: 12),
            if (count < 4)
              Text(
                t.seller.devices.needsPhotos(count: '${4 - count}'),
                style: theme.textTheme.bodySmall
                    ?.copyWith(color: context.appColors.warning),
              )
            else
              Row(
                children: [
                  Icon(Icons.check_circle_rounded,
                      size: 16, color: context.appColors.success),
                  const SizedBox(width: 4),
                  Text(t.seller.devices.photosCount(count: '$count'),
                      style: theme.textTheme.bodySmall),
                ],
              ),
          ],
        ),
      ],
    );
  }

  Widget _checklistSection(List<ChecklistTemplate> templates, Grade? grade) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                t.seller.deviceForm.checklistTitle,
                style: theme.textTheme.titleMedium
                    ?.copyWith(fontWeight: FontWeight.w700),
              ),
            ),
            if (grade != null)
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: theme.colorScheme.primaryContainer,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  t.seller.deviceForm.gradePreview(
                      grade: t.enums.grade[grade.dbValue] ?? grade.dbValue),
                  style: TextStyle(
                    fontWeight: FontWeight.w700,
                    color: theme.colorScheme.onPrimaryContainer,
                  ),
                ),
              ),
          ],
        ),
        const SizedBox(height: 12),
        Card(
          child: Column(
            children: [
              for (final (i, template) in templates.indexed) ...[
                if (i > 0) const Divider(height: 1),
                Padding(
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        template.labelAr,
                        style: theme.textTheme.titleSmall
                            ?.copyWith(fontWeight: FontWeight.w600),
                      ),
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 8,
                        children: [
                          for (final result in ChecklistResult.values)
                            ChoiceChip(
                              label: Text(t.enums
                                      .checklistResult[result.dbValue] ??
                                  result.dbValue),
                              avatar: ChecklistResultIcon(result, size: 16),
                              selected: _results[template.key] == result,
                              onSelected: (_) => setState(
                                  () => _results[template.key] = result),
                            ),
                        ],
                      ),
                      if (_results[template.key] != null) ...[
                        const SizedBox(height: 8),
                        TextFormField(
                          initialValue: _notes[template.key],
                          decoration: InputDecoration(
                            hintText: t.seller.deviceForm.checklistNoteHint,
                            isDense: true,
                          ),
                          onChanged: (v) => _notes[template.key] = v,
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }

  String? _required(String? v) =>
      (v == null || v.trim().isEmpty) ? t.common.requiredField : null;
}

/// Reorderable thumbnail grid with cover badge + delete.
class ReorderableWrap extends StatelessWidget {
  const ReorderableWrap({
    super.key,
    required this.photos,
    required this.onReorder,
    required this.onRemove,
  });

  final List<DevicePhoto> photos;
  final void Function(int oldIndex, int newIndex) onReorder;
  final void Function(DevicePhoto photo) onRemove;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 120,
      child: ReorderableListView.builder(
        scrollDirection: Axis.horizontal,
        buildDefaultDragHandles: false,
        itemCount: photos.length,
        onReorder: onReorder,
        itemBuilder: (context, index) {
          final photo = photos[index];
          return ReorderableDragStartListener(
            key: ValueKey(photo.id),
            index: index,
            child: Padding(
              padding: const EdgeInsetsDirectional.only(end: 8),
              child: Stack(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: SizedBox(
                      width: 120,
                      height: 120,
                      child: DevicePhotoImage(path: photo.storagePath),
                    ),
                  ),
                  if (index == 0)
                    PositionedDirectional(
                      start: 4,
                      top: 4,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: Theme.of(context).colorScheme.primary,
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          '★',
                          style: TextStyle(
                            color: Theme.of(context).colorScheme.onPrimary,
                            fontSize: 12,
                          ),
                        ),
                      ),
                    ),
                  PositionedDirectional(
                    end: 2,
                    top: 2,
                    child: IconButton(
                      tooltip: t.seller.deviceForm.removePhoto,
                      iconSize: 18,
                      style: IconButton.styleFrom(
                        backgroundColor: Colors.black45,
                        foregroundColor: Colors.white,
                        minimumSize: const Size(28, 28),
                        padding: EdgeInsets.zero,
                      ),
                      onPressed: () => onRemove(photo),
                      icon: const Icon(Icons.close_rounded),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
