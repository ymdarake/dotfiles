# ダイアログパターン テンプレート集

本プロジェクトの実装例に基づく5パターンのテンプレート。

---

## 1. テキスト入力ダイアログ

単一のテキスト入力を受け付けて `String?` を返す。

**参考実装:** `lib/ui/page/settings/settings_page.dart` — `_ProjectInputDialog`

### ダイアログ本体

```dart
class _XxxInputDialog extends StatefulWidget {
  final String title;
  final String? initialText;
  final String confirmLabel;

  const _XxxInputDialog({
    required this.title,
    this.initialText,
    required this.confirmLabel,
  });

  @override
  State<_XxxInputDialog> createState() => _XxxInputDialogState();
}

class _XxxInputDialogState extends State<_XxxInputDialog> {
  late final TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.initialText);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _submit() {
    final text = _controller.text;
    if (text.trim().isEmpty) return;
    Navigator.pop(context, text);
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.title),
      content: TextField(
        controller: _controller,
        autofocus: true,
        decoration: widget.initialText == null
            ? const InputDecoration(hintText: 'ヒントテキスト')
            : null,
        onSubmitted: (_) => _submit(),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('キャンセル'),
        ),
        TextButton(
          onPressed: _submit,
          child: Text(widget.confirmLabel),
        ),
      ],
    );
  }
}
```

### 呼び出し側

```dart
Future<void> _showInputDialog(BuildContext context, WidgetRef ref) async {
  final name = await showDialog<String>(
    context: context,
    builder: (_) => const _XxxInputDialog(
      title: '追加',
      confirmLabel: '追加',
    ),
  );
  if (name == null) return;

  final result = await ref.read(repositoryProvider).add(name);
  ref.invalidate(listProvider);

  if (context.mounted) {
    switch (result) {
      case Success(): break;
      case Failure(error: final e): _showError(context, e);
    }
  }
}
```

---

## 2. 時刻範囲選択ダイアログ

開始/終了時刻を `showTimePicker` で選択し、Named record を返す。

**参考実装:** `lib/ui/page/day_detail/day_detail_page.dart` — `_EntryEditDialog`

### ダイアログ本体

```dart
class _TimeRangeDialog extends StatefulWidget {
  final DateTime baseDate;
  final TimeOfDay initialStart;
  final TimeOfDay initialEnd;

  const _TimeRangeDialog({
    required this.baseDate,
    required this.initialStart,
    required this.initialEnd,
  });

  @override
  State<_TimeRangeDialog> createState() => _TimeRangeDialogState();
}

class _TimeRangeDialogState extends State<_TimeRangeDialog> {
  late TimeOfDay _startTime;
  late TimeOfDay _endTime;
  String? _error;

  @override
  void initState() {
    super.initState();
    _startTime = widget.initialStart;
    _endTime = widget.initialEnd;
  }

  DateTime _toDateTime(TimeOfDay time) {
    final base = widget.baseDate;
    return DateTime(base.year, base.month, base.day, time.hour, time.minute);
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('時刻編集'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ListTile(
            title: const Text('開始時刻'),
            trailing: Text(_startTime.format(context)),
            onTap: () async {
              final picked = await showTimePicker(
                context: context,
                initialTime: _startTime,
              );
              if (picked != null) {
                setState(() {
                  _startTime = picked;
                  _error = null;
                });
              }
            },
          ),
          ListTile(
            title: const Text('終了時刻'),
            trailing: Text(_endTime.format(context)),
            onTap: () async {
              final picked = await showTimePicker(
                context: context,
                initialTime: _endTime,
              );
              if (picked != null) {
                setState(() {
                  _endTime = picked;
                  _error = null;
                });
              }
            },
          ),
          if (_error != null)
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Text(
                _error!,
                style: TextStyle(color: Theme.of(context).colorScheme.error),
              ),
            ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('キャンセル'),
        ),
        TextButton(
          onPressed: () {
            final start = _toDateTime(_startTime);
            final end = _toDateTime(_endTime);
            if (start.isAfter(end) || start.isAtSameMomentAs(end)) {
              setState(() {
                _error = '開始時刻は終了時刻より前にしてください';
              });
              return;
            }
            Navigator.pop(context, (start: start, end: end));
          },
          child: const Text('保存'),
        ),
      ],
    );
  }
}
```

### 呼び出し側

```dart
Future<void> _showEditDialog(
    BuildContext context, WidgetRef ref, EntryData entry) async {
  final result = await showDialog<({DateTime start, DateTime end})>(
    context: context,
    builder: (_) => _TimeRangeDialog(
      baseDate: entry.startedAt,
      initialStart: TimeOfDay.fromDateTime(entry.startedAt),
      initialEnd: TimeOfDay.fromDateTime(entry.endedAt!),
    ),
  );
  if (result == null) return;

  final updateResult = await ref
      .read(notifierProvider.notifier)
      .updateTime(entryId: entry.id, startedAt: result.start, endedAt: result.end);

  if (context.mounted) {
    switch (updateResult) {
      case Success(): break;
      case Failure():
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('更新エラー')),
        );
    }
  }
}
```

---

## 3. 複数入力フォームダイアログ

種別選択 + 時刻範囲など、複数のState を持つフォーム。

**参考実装:** `lib/ui/page/day_detail/day_detail_page.dart` — `_AddEntryDialog`

### ダイアログ本体

```dart
class _MultiInputDialog extends StatefulWidget {
  final DateTime logicalDate;

  const _MultiInputDialog({required this.logicalDate});

  @override
  State<_MultiInputDialog> createState() => _MultiInputDialogState();
}

class _MultiInputDialogState extends State<_MultiInputDialog> {
  String _type = 'work';
  TimeOfDay _startTime = const TimeOfDay(hour: 9, minute: 0);
  TimeOfDay _endTime = const TimeOfDay(hour: 18, minute: 0);
  String? _error;

  DateTime _toDateTime(TimeOfDay time) {
    final base = widget.logicalDate;
    return DateTime(base.year, base.month, base.day, time.hour, time.minute);
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('エントリ追加'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // 種別選択
          SegmentedButton<String>(
            segments: const [
              ButtonSegment(value: 'work', label: Text('稼働')),
              ButtonSegment(value: 'break', label: Text('休憩')),
            ],
            selected: {_type},
            onSelectionChanged: (selected) {
              setState(() => _type = selected.first);
            },
          ),
          const SizedBox(height: 16),
          // 時刻選択（パターン2と同様）
          ListTile(
            title: const Text('開始時刻'),
            trailing: Text(_startTime.format(context)),
            onTap: () async {
              final picked = await showTimePicker(
                context: context,
                initialTime: _startTime,
              );
              if (picked != null) {
                setState(() { _startTime = picked; _error = null; });
              }
            },
          ),
          ListTile(
            title: const Text('終了時刻'),
            trailing: Text(_endTime.format(context)),
            onTap: () async {
              final picked = await showTimePicker(
                context: context,
                initialTime: _endTime,
              );
              if (picked != null) {
                setState(() { _endTime = picked; _error = null; });
              }
            },
          ),
          if (_error != null)
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Text(
                _error!,
                style: TextStyle(color: Theme.of(context).colorScheme.error),
              ),
            ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('キャンセル'),
        ),
        TextButton(
          onPressed: () {
            final start = _toDateTime(_startTime);
            final end = _toDateTime(_endTime);
            if (start.isAfter(end) || start.isAtSameMomentAs(end)) {
              setState(() {
                _error = '開始時刻は終了時刻より前にしてください';
              });
              return;
            }
            Navigator.pop(context, (type: _type, start: start, end: end));
          },
          child: const Text('追加'),
        ),
      ],
    );
  }
}
```

### 呼び出し側

```dart
Future<void> _showAddDialog(BuildContext context, WidgetRef ref) async {
  final result = await showDialog<({String type, DateTime start, DateTime end})>(
    context: context,
    builder: (_) => _MultiInputDialog(logicalDate: logicalDate),
  );
  if (result == null) return;

  final addResult = await ref.read(notifierProvider.notifier).addEntry(
    type: result.type,
    startedAt: result.start,
    endedAt: result.end,
  );

  if (context.mounted) {
    switch (addResult) {
      case Success(): break;
      case Failure():
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('追加エラー')),
        );
    }
  }
}
```

---

## 4. 確認ダイアログ

Yes/No の確認を取る。専用クラス不要でインラインで記述する。

**参考実装:** `lib/ui/page/day_detail/day_detail_page.dart` — 削除確認

### インライン実装

```dart
Future<void> _confirmDelete(
    BuildContext context, WidgetRef ref, EntryData entry) async {
  final confirm = await showDialog<bool>(
    context: context,
    builder: (context) => AlertDialog(
      title: const Text('削除確認'),
      content: const Text('このエントリを削除しますか？'),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context, false),
          child: const Text('キャンセル'),
        ),
        TextButton(
          onPressed: () => Navigator.pop(context, true),
          child: const Text('削除'),
        ),
      ],
    ),
  );

  if (confirm == true) {
    await ref.read(notifierProvider.notifier).delete(entryId: entry.id);
  }
}
```

**ポイント:**
- `confirm == true` で null と false の両方をキャンセル扱い
- シンプルなのでStatefulWidget不要

---

## 5. 選択ダイアログ

リストから1つのアイテムを選択する。`SimpleDialog` を使用。

**参考実装:** `lib/ui/page/timer/timer_page.dart` — プロジェクト選択

### インライン実装

```dart
Future<void> _showSelectDialog(BuildContext context, WidgetRef ref) async {
  final items = await ref.read(serviceProvider).getActiveItems();

  if (items.isEmpty) {
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('選択肢がありません')),
      );
    }
    return;
  }

  if (!context.mounted) return;

  final selected = await showDialog<ItemData>(
    context: context,
    builder: (context) => SimpleDialog(
      title: const Text('選択'),
      children: items
          .map(
            (item) => SimpleDialogOption(
              onPressed: () => Navigator.pop(context, item),
              child: Text(item.name),
            ),
          )
          .toList(),
    ),
  );

  if (selected == null) return;

  await ref.read(notifierProvider.notifier).select(itemId: selected.id);
}
```

**ポイント:**
- データ取得後に `context.mounted` チェック（非同期ギャップ）
- 空リストの場合はダイアログ表示せずSnackBarで通知
- `SimpleDialog` + `SimpleDialogOption` で簡潔に記述
