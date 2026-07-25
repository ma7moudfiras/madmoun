import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/domain.dart';
import '../../../core/models.dart';
import '../../../core/widgets/common.dart';
import '../../../i18n/strings.g.dart';
import '../data/admin_repository.dart';

class AdminTemplatesPage extends ConsumerWidget {
  const AdminTemplatesPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final templates = ref.watch(adminTemplatesProvider);
    return Scaffold(
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _editDialog(context, ref, null),
        icon: const Icon(Icons.add_rounded),
        label: Text(t.admin.templates.add),
      ),
      body: AsyncView(
        value: templates,
        onRetry: () => ref.invalidate(adminTemplatesProvider),
        data: (list) {
          final byCategory = <DeviceCategory, List<ChecklistTemplate>>{};
          for (final template in list) {
            byCategory.putIfAbsent(template.category, () => []).add(template);
          }
          return ListView(
            padding: const EdgeInsets.fromLTRB(24, 24, 24, 96),
            children: [
              for (final category in DeviceCategory.values) ...[
                Text(
                  t.enums.category[category.dbValue] ?? category.dbValue,
                  style: Theme.of(
                    context,
                  ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 8),
                Card(
                  child: Column(
                    children: [
                      for (final (i, template)
                          in (byCategory[category] ?? []).indexed) ...[
                        if (i > 0) const Divider(height: 1),
                        _TemplateRow(
                          template: template,
                          onEdit: () => _editDialog(context, ref, template),
                        ),
                      ],
                    ],
                  ),
                ),
                const SizedBox(height: 24),
              ],
            ],
          );
        },
      ),
    );
  }

  Future<void> _editDialog(
    BuildContext context,
    WidgetRef ref,
    ChecklistTemplate? template,
  ) async {
    final saved = await showDialog<bool>(
      context: context,
      builder: (context) => _TemplateDialog(template: template),
    );
    if (saved == true) {
      ref.invalidate(adminTemplatesProvider);
      if (context.mounted) showAppSnackBar(context, t.admin.templates.saved);
    }
  }
}

class _TemplateRow extends StatelessWidget {
  const _TemplateRow({required this.template, required this.onEdit});

  final ChecklistTemplate template;
  final VoidCallback onEdit;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return ListTile(
      title: Text(template.labelAr),
      subtitle: Text(
        template.key,
        style: theme.textTheme.bodySmall?.copyWith(
          color: theme.colorScheme.onSurfaceVariant,
        ),
      ),
      leading: CircleAvatar(
        radius: 14,
        backgroundColor: theme.colorScheme.primaryContainer,
        child: Text(
          '${template.sortOrder}',
          style: TextStyle(
            fontSize: 12,
            color: theme.colorScheme.onPrimaryContainer,
          ),
        ),
      ),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (!template.isActive)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: theme.colorScheme.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                t.admin.templates.disabledBadge,
                style: theme.textTheme.bodySmall,
              ),
            ),
          IconButton(onPressed: onEdit, icon: const Icon(Icons.edit_rounded)),
        ],
      ),
    );
  }
}

class _TemplateDialog extends ConsumerStatefulWidget {
  const _TemplateDialog({this.template});

  final ChecklistTemplate? template;

  @override
  ConsumerState<_TemplateDialog> createState() => _TemplateDialogState();
}

class _TemplateDialogState extends ConsumerState<_TemplateDialog> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _key = TextEditingController(
    text: widget.template?.key ?? '',
  );
  late final TextEditingController _label = TextEditingController(
    text: widget.template?.labelAr ?? '',
  );
  late final TextEditingController _sort = TextEditingController(
    text: (widget.template?.sortOrder ?? 0).toString(),
  );
  late DeviceCategory _category =
      widget.template?.category ?? DeviceCategory.mobile;
  late bool _active = widget.template?.isActive ?? true;
  bool _busy = false;

  @override
  void dispose() {
    _key.dispose();
    _label.dispose();
    _sort.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _busy = true);
    try {
      await ref
          .read(adminRepositoryProvider)
          .upsertTemplate(
            id: widget.template?.id,
            category: _category,
            key: _key.text.trim(),
            labelAr: _label.text.trim(),
            sortOrder: int.tryParse(_sort.text.trim()) ?? 0,
            isActive: _active,
          );
      if (mounted) Navigator.of(context).pop(true);
    } catch (e) {
      if (mounted) {
        setState(() => _busy = false);
        showErrorSnackBar(context, e);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isNew = widget.template == null;
    return AlertDialog(
      title: Text(isNew ? t.admin.templates.add : t.admin.templates.editTitle),
      content: Form(
        key: _formKey,
        child: SizedBox(
          width: 400,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (isNew)
                DropdownButtonFormField<DeviceCategory>(
                  value: _category,
                  decoration: InputDecoration(
                    labelText: t.seller.deviceForm.categoryLabel,
                  ),
                  items: [
                    for (final c in DeviceCategory.values)
                      DropdownMenuItem(
                        value: c,
                        child: Text(t.enums.category[c.dbValue] ?? c.dbValue),
                      ),
                  ],
                  onChanged: (v) => setState(() => _category = v ?? _category),
                ),
              if (isNew) const SizedBox(height: 12),
              TextFormField(
                textDirection: TextDirection.rtl,
                controller: _key,
                enabled: isNew,
                decoration: InputDecoration(
                  labelText: t.admin.templates.keyLabel,
                  hintText: t.admin.templates.keyHint,
                ),
                validator: (v) =>
                    RegExp(r'^[a-z][a-z0-9_]*$').hasMatch((v ?? '').trim())
                    ? null
                    : t.admin.templates.invalidKey,
              ),
              const SizedBox(height: 12),
              TextFormField(
                textDirection: TextDirection.rtl,
                controller: _label,
                decoration: InputDecoration(
                  labelText: t.admin.templates.labelArLabel,
                ),
                validator: (v) => (v == null || v.trim().isEmpty)
                    ? t.common.requiredField
                    : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                textDirection: TextDirection.rtl,
                controller: _sort,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                  labelText: t.admin.templates.sortLabel,
                ),
              ),
              const SizedBox(height: 8),
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                title: Text(t.admin.templates.activeLabel),
                value: _active,
                onChanged: (v) => setState(() => _active = v),
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text(t.common.cancel),
        ),
        FilledButton(
          onPressed: _busy ? null : _save,
          child: _busy
              ? const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : Text(t.common.save),
        ),
      ],
    );
  }
}
