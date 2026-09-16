import 'dart:async';

import 'package:flutter/material.dart';

import '../services/export_service.dart';
import '../services/storage_service.dart';
import '../models/gift_entry.dart';
import '../theme/app_palette.dart';
import '../utils/korean_numeral.dart';
import '../widgets/ticket_icon.dart';

/// The only screen in the app. Opening the app lands here directly — no
/// splash, no login, no home page to click through — because the whole
/// point is that a receptionist can pick up the tablet mid-line and start
/// typing immediately.
class CalculatorScreen extends StatefulWidget {
  final ThemeMode themeMode;
  final VoidCallback onToggleTheme;

  const CalculatorScreen({
    super.key,
    required this.themeMode,
    required this.onToggleTheme,
  });

  @override
  State<CalculatorScreen> createState() => _CalculatorScreenState();
}

class _CalculatorScreenState extends State<CalculatorScreen> {
  final _storage = StorageService();
  final _exportService = ExportService();

  LedgerData _data = LedgerData.empty();
  bool _loading = true;
  bool _exporting = false;

  final _ownerNameController = TextEditingController();
  final _ticketTotalController = TextEditingController();
  final _searchController = TextEditingController();

  final _entryNameController = TextEditingController();
  final _entryAmountController = TextEditingController();
  final _entryTicketsController = TextEditingController();

  final _entryNameFocus = FocusNode();
  final _entryAmountFocus = FocusNode();
  final _entryTicketsFocus = FocusNode();

  final _scrollController = ScrollController();

  int? _editingNo;
  int? _justUpdatedNo;
  Timer? _justUpdatedTimer;

  final Map<int, TextEditingController> _editNameControllers = {};
  final Map<int, TextEditingController> _editAmountControllers = {};
  final Map<int, TextEditingController> _editTicketsControllers = {};

  @override
  void initState() {
    super.initState();
    _load();
    _searchController.addListener(() => setState(() {}));
    _entryAmountController.addListener(() => setState(() {}));
    _entryTicketsController.addListener(() => setState(() {}));
  }

  Future<void> _load() async {
    final data = await _storage.load();
    if (!mounted) return;
    setState(() {
      _data = data;
      _ownerNameController.text = data.ownerName;
      _ticketTotalController.text = data.ticketTotal.toString();
      _loading = false;
    });
  }

  Future<void> _persist() => _storage.save(_data);

  @override
  void dispose() {
    _justUpdatedTimer?.cancel();
    _ownerNameController.dispose();
    _ticketTotalController.dispose();
    _searchController.dispose();
    _entryNameController.dispose();
    _entryAmountController.dispose();
    _entryTicketsController.dispose();
    _entryNameFocus.dispose();
    _entryAmountFocus.dispose();
    _entryTicketsFocus.dispose();
    _scrollController.dispose();
    for (final c in _editNameControllers.values) {
      c.dispose();
    }
    for (final c in _editAmountControllers.values) {
      c.dispose();
    }
    for (final c in _editTicketsControllers.values) {
      c.dispose();
    }
    super.dispose();
  }

  // ---------- derived values ----------

  int get _totalCount => _data.entries.length;
  int get _totalAmount => _data.entries.fold(0, (s, e) => s + e.amount);
  int get _usedTickets => _data.entries.fold(0, (s, e) => s + e.tickets);
  int get _remainingTickets => _data.ticketTotal - _usedTickets;

  List<GiftEntry> get _filteredEntries {
    final q = _searchController.text.trim();
    final list = _data.entries.where((e) {
      if (q.isEmpty) return true;
      if (e.name.contains(q)) return true;
      final qNum = int.tryParse(q);
      return qNum != null && e.no == qNum;
    }).toList();
    list.sort((a, b) => b.no.compareTo(a.no));
    return list;
  }

  String _pad(int no) => no.toString().padLeft(3, '0');

  // ---------- actions ----------

  void _toast(String message) {
    if (!mounted) return;
    final palette = Theme.of(context).extension<AppPalette>()!;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(
            message,
            style: TextStyle(color: palette.bg, fontWeight: FontWeight.w600),
          ),
          backgroundColor: palette.text,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          duration: const Duration(seconds: 2),
        ),
      );
  }

  void _scheduleJustUpdatedClear(int no) {
    _justUpdatedTimer?.cancel();
    _justUpdatedTimer = Timer(const Duration(seconds: 4), () {
      if (!mounted) return;
      setState(() {
        if (_justUpdatedNo == no) _justUpdatedNo = null;
      });
    });
  }

  void _saveTicketSetup() {
    final name = _ownerNameController.text.trim();
    final total = resolveNumberField(_ticketTotalController.text, ['장']);
    if (name.isEmpty) {
      _toast('이름을 입력해주세요');
      return;
    }
    if (total == null || total < 0) {
      _toast('올바른 식권 수를 입력해주세요');
      return;
    }
    setState(() {
      _data.ownerName = name;
      _data.ticketTotal = total;
    });
    _ticketTotalController.text = total.toString();
    _persist();
    _toast('$name님 · 식권 $total장으로 저장되었어요');
  }

  void _onAmountSubmitted() {
    final val = resolveAmount(_entryAmountController.text);
    if (val == null) {
      _toast('금액을 숫자나 한글로 다시 입력해주세요');
      return;
    }
    _entryAmountController.text = val.toString();
    _entryTicketsFocus.requestFocus();
  }

  void _onTicketsSubmitted() {
    final val = resolveTickets(_entryTicketsController.text);
    if (val == null) {
      _toast('식권 수를 숫자나 한글로 다시 입력해주세요');
      return;
    }
    _entryTicketsController.text = val.toString();
    _saveEntry();
  }

  void _saveEntry() {
    final name = _entryNameController.text.trim();
    if (name.isEmpty) {
      _toast('이름을 입력해주세요');
      _entryNameFocus.requestFocus();
      return;
    }
    final amount = resolveAmount(_entryAmountController.text);
    if (amount == null) {
      _toast('금액을 숫자나 한글로 다시 입력해주세요');
      _entryAmountFocus.requestFocus();
      return;
    }
    final tickets = resolveTickets(_entryTicketsController.text);
    if (tickets == null) {
      _toast('식권 수를 숫자나 한글로 다시 입력해주세요');
      _entryTicketsFocus.requestFocus();
      return;
    }

    final no = _data.nextNo;
    setState(() {
      _data.entries.add(GiftEntry(no: no, name: name, amount: amount, tickets: tickets));
      _data.nextNo += 1;
      _entryNameController.clear();
      _entryAmountController.clear();
      _entryTicketsController.clear();
      _searchController.clear();
      _justUpdatedNo = no;
    });
    _persist();
    _scheduleJustUpdatedClear(no);
    _entryNameFocus.requestFocus();
    if (_scrollController.hasClients) {
      _scrollController.jumpTo(0);
    }
    _toast('${_pad(no)}번 $name님 등록 완료');
  }

  void _startEdit(GiftEntry entry) {
    setState(() {
      _editingNo = entry.no;
      _editNameControllers[entry.no] = TextEditingController(text: entry.name);
      _editAmountControllers[entry.no] =
          TextEditingController(text: entry.amount.toString());
      _editTicketsControllers[entry.no] =
          TextEditingController(text: entry.tickets.toString());
    });
  }

  void _cancelEdit(int no) {
    setState(() {
      _editingNo = null;
      _editNameControllers.remove(no)?.dispose();
      _editAmountControllers.remove(no)?.dispose();
      _editTicketsControllers.remove(no)?.dispose();
    });
  }

  void _completeEdit(int no) {
    final nameCtrl = _editNameControllers[no]!;
    final amountCtrl = _editAmountControllers[no]!;
    final ticketsCtrl = _editTicketsControllers[no]!;

    final name = nameCtrl.text.trim();
    if (name.isEmpty) {
      _toast('이름을 입력해주세요');
      return;
    }
    final amount = resolveAmount(amountCtrl.text);
    if (amount == null) {
      _toast('금액을 다시 입력해주세요');
      return;
    }
    final tickets = resolveTickets(ticketsCtrl.text);
    if (tickets == null) {
      _toast('식권 수를 다시 입력해주세요');
      return;
    }

    final entry = _data.entries.firstWhere((e) => e.no == no);
    setState(() {
      entry.name = name;
      entry.amount = amount;
      entry.tickets = tickets;
      _editingNo = null;
      _justUpdatedNo = no;
      _editNameControllers.remove(no)?.dispose();
      _editAmountControllers.remove(no)?.dispose();
      _editTicketsControllers.remove(no)?.dispose();
    });
    _persist();
    _scheduleJustUpdatedClear(no);
    _toast('${_pad(no)}번 수정 완료');
  }

  Future<void> _deleteEntry(int no) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('삭제할까요?'),
        content: const Text('이 항목을 삭제할까요? 번호는 다시 사용되지 않아요.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('취소')),
          TextButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('삭제')),
        ],
      ),
    );
    if (confirmed != true) return;
    setState(() {
      _data.entries.removeWhere((e) => e.no == no);
      _editingNo = null;
      _editNameControllers.remove(no)?.dispose();
      _editAmountControllers.remove(no)?.dispose();
      _editTicketsControllers.remove(no)?.dispose();
    });
    _persist();
    _toast('삭제되었어요');
  }

  Future<void> _resetAll() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('전체 초기화'),
        content: const Text('접수된 내역을 모두 지울까요? 번호는 1번부터 다시 시작해요.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('취소')),
          TextButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('비우기')),
        ],
      ),
    );
    if (confirmed != true) return;
    setState(() {
      _data.entries = [];
      _data.nextNo = 1;
    });
    await _persist();
    _toast('전체 내역을 비웠어요');
  }

  Future<void> _export(bool asExcel) async {
    if (_exporting) return;
    setState(() => _exporting = true);
    try {
      if (asExcel) {
        await _exportService.exportAsExcel(_data);
      } else {
        await _exportService.exportAsCsv(_data);
      }
    } catch (_) {
      _toast('내보내기에 실패했어요. 다시 시도해주세요.');
    } finally {
      if (mounted) setState(() => _exporting = false);
    }
  }

  // ---------- build ----------

  @override
  Widget build(BuildContext context) {
    final palette = Theme.of(context).extension<AppPalette>()!;
    final isDark = _resolveBrightness(context) == Brightness.dark;

    if (_loading) {
      return Scaffold(
        backgroundColor: palette.bg,
        body: Center(child: CircularProgressIndicator(color: palette.accent)),
      );
    }

    return Scaffold(
      backgroundColor: palette.bg,
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 640),
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
                  child: _buildTitleRow(palette, isDark),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: _buildSummaryCard(palette),
                ),
                const SizedBox(height: 12),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: _buildColumnLabels(palette),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: _buildEntryRow(palette),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
                  child: _buildEntryHint(palette),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: _buildSearchField(palette),
                ),
                const SizedBox(height: 4),
                Expanded(child: _buildLedgerList(palette)),
                _buildExportBar(palette),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Brightness _resolveBrightness(BuildContext context) {
    if (widget.themeMode == ThemeMode.system) {
      return MediaQuery.platformBrightnessOf(context);
    }
    return widget.themeMode == ThemeMode.dark ? Brightness.dark : Brightness.light;
  }

  Widget _buildTitleRow(AppPalette palette, bool isDark) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          '축의금 계산기',
          style: TextStyle(
            fontFamily: 'Do Hyeon',
            fontSize: 20,
            color: palette.text,
          ),
        ),
        Material(
          color: palette.fill,
          shape: CircleBorder(side: BorderSide(color: palette.line, width: 1.5)),
          child: InkWell(
            customBorder: const CircleBorder(),
            onTap: widget.onToggleTheme,
            child: Padding(
              padding: const EdgeInsets.all(6),
              child: Icon(
                isDark ? Icons.dark_mode : Icons.wb_sunny_outlined,
                size: 18,
                color: palette.textSoft,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSummaryCard(AppPalette palette) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: palette.tint,
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Expanded(
                flex: 3,
                child: TextField(
                  controller: _ownerNameController,
                  decoration: const InputDecoration(hintText: '이름 (신랑 또는 신부)'),
                  style: TextStyle(color: palette.text, fontWeight: FontWeight.w700),
                ),
              ),
              const SizedBox(width: 6),
              SizedBox(
                width: 74,
                child: TextField(
                  controller: _ticketTotalController,
                  decoration: const InputDecoration(hintText: '식권장수'),
                  textAlign: TextAlign.center,
                  style: TextStyle(color: palette.text, fontWeight: FontWeight.w700),
                ),
              ),
              const SizedBox(width: 6),
              Text('장', style: TextStyle(color: palette.textSoft, fontSize: 13)),
              const SizedBox(width: 6),
              ElevatedButton(
                onPressed: _saveTicketSetup,
                style: ElevatedButton.styleFrom(
                  backgroundColor: palette.accent,
                  foregroundColor: palette.accentInk,
                  textStyle: const TextStyle(fontFamily: 'Do Hyeon', fontSize: 13),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(11)),
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                ),
                child: const Text('저장'),
              ),
            ],
          ),
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 10),
            child: Divider(
              height: 1,
              thickness: 1.2,
              color: palette.textFaint.withValues(alpha: 0.25),
            ),
          ),
          Row(
            children: [
              _statColumn(palette, '인원', '$_totalCount명'),
              _statColumn(palette, '축의금', manwonLabel(_totalAmount)),
              _statColumn(
                palette,
                '잔여 식권',
                '$_remainingTickets장',
                warn: _remainingTickets <= 0,
                icon: TicketIcon(
                  color: _remainingTickets <= 0 ? palette.warn : palette.textSoft,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _statColumn(
    AppPalette palette,
    String label,
    String value, {
    bool warn = false,
    Widget? icon,
  }) {
    final color = warn ? palette.warn : palette.text;
    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (icon != null) ...[icon, const SizedBox(width: 3)],
              Text(
                label,
                style: TextStyle(
                  fontSize: 11,
                  color: warn ? palette.warn : palette.textSoft,
                ),
              ),
            ],
          ),
          const SizedBox(height: 3),
          Text(
            value,
            style: TextStyle(
              fontFamily: 'Do Hyeon',
              fontSize: 16,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildColumnLabels(AppPalette palette) {
    final style = TextStyle(fontSize: 10, color: palette.textFaint);
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 2),
      child: Row(
        children: [
          SizedBox(width: 30, child: Text('번호', style: style)),
          Expanded(child: Text('이름', style: style)),
          SizedBox(width: 56, child: Text('금액', style: style, textAlign: TextAlign.right)),
          SizedBox(width: 44, child: Text('식권', style: style, textAlign: TextAlign.right)),
          const SizedBox(width: 44),
        ],
      ),
    );
  }

  Widget _buildEntryRow(AppPalette palette) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Container(
          width: 30,
          padding: const EdgeInsets.symmetric(vertical: 9),
          decoration: BoxDecoration(
            color: palette.accentSoft,
            borderRadius: BorderRadius.circular(9),
          ),
          alignment: Alignment.center,
          child: Text(
            _pad(_data.nextNo),
            style: TextStyle(fontFamily: 'Do Hyeon', fontSize: 12.5, color: palette.accent),
          ),
        ),
        const SizedBox(width: 6),
        Expanded(
          child: TextField(
            controller: _entryNameController,
            focusNode: _entryNameFocus,
            decoration: const InputDecoration(hintText: '이름'),
            textInputAction: TextInputAction.next,
            onSubmitted: (_) => _entryAmountFocus.requestFocus(),
          ),
        ),
        const SizedBox(width: 6),
        SizedBox(
          width: 56,
          child: TextField(
            controller: _entryAmountController,
            focusNode: _entryAmountFocus,
            decoration: const InputDecoration(hintText: '금액'),
            textAlign: TextAlign.right,
            textInputAction: TextInputAction.next,
            onSubmitted: (_) => _onAmountSubmitted(),
          ),
        ),
        const SizedBox(width: 6),
        SizedBox(
          width: 44,
          child: TextField(
            controller: _entryTicketsController,
            focusNode: _entryTicketsFocus,
            decoration: const InputDecoration(hintText: '식권'),
            textAlign: TextAlign.right,
            textInputAction: TextInputAction.done,
            onSubmitted: (_) => _onTicketsSubmitted(),
          ),
        ),
        const SizedBox(width: 6),
        SizedBox(
          width: 52,
          child: ElevatedButton(
            onPressed: _saveEntry,
            style: ElevatedButton.styleFrom(
              backgroundColor: palette.accent,
              foregroundColor: palette.accentInk,
              textStyle: const TextStyle(fontFamily: 'Do Hyeon', fontSize: 12.5),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(11)),
              padding: const EdgeInsets.symmetric(vertical: 12),
            ),
            child: const Text('등록'),
          ),
        ),
      ],
    );
  }

  Widget _buildEntryHint(AppPalette palette) {
    final amountRaw = _entryAmountController.text;
    final ticketsRaw = _entryTicketsController.text;
    final parts = <InlineSpan>[];

    void addPart(String raw, int? Function(String) resolve, String suffix, String errorLabel) {
      if (raw.trim().isEmpty) return;
      if (parts.isNotEmpty) {
        parts.add(TextSpan(text: '  ·  ', style: TextStyle(color: palette.textFaint)));
      }
      final value = resolve(raw);
      if (value == null) {
        parts.add(TextSpan(text: errorLabel, style: TextStyle(color: palette.textFaint)));
      } else {
        parts.add(TextSpan(
          text: suffix == '만원' ? manwonLabel(value) : '$value$suffix',
          style: TextStyle(color: palette.accent, fontWeight: FontWeight.w700),
        ));
      }
    }

    addPart(amountRaw, resolveAmount, '만원', '금액을 알아볼 수 없어요');
    addPart(ticketsRaw, resolveTickets, '장', '식권을 알아볼 수 없어요');

    if (parts.isEmpty) {
      return Text(
        '숫자 대신 십오처럼 한글로 써도 15로 바뀌어요',
        style: TextStyle(fontSize: 11.5, color: palette.textFaint),
      );
    }
    return Text.rich(TextSpan(children: parts), style: const TextStyle(fontSize: 11.5));
  }

  Widget _buildSearchField(AppPalette palette) {
    return TextField(
      controller: _searchController,
      decoration: InputDecoration(
        hintText: '번호 또는 이름으로 찾기',
        prefixIcon: Icon(Icons.search, size: 18, color: palette.textFaint),
      ),
    );
  }

  Widget _buildLedgerList(AppPalette palette) {
    final rows = _filteredEntries;
    if (rows.isEmpty) {
      return Center(
        child: Text(
          _searchController.text.trim().isEmpty ? '아직 접수된 내역이 없어요.' : '일치하는 사람이 없어요.',
          style: TextStyle(color: palette.textFaint, fontSize: 13),
        ),
      );
    }
    return ListView.builder(
      controller: _scrollController,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      itemCount: rows.length,
      itemBuilder: (context, index) => _buildLedgerRow(palette, rows[index]),
    );
  }

  Widget _buildLedgerRow(AppPalette palette, GiftEntry entry) {
    final isEditing = _editingNo == entry.no;
    final isJustUpdated = _justUpdatedNo == entry.no;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
      margin: const EdgeInsets.only(bottom: 2),
      decoration: BoxDecoration(
        color: isJustUpdated ? palette.goodSoft : Colors.transparent,
        border: Border(bottom: BorderSide(color: palette.line, width: 1)),
        borderRadius: BorderRadius.circular(8),
      ),
      child: isEditing ? _buildEditingRow(palette, entry) : _buildDisplayRow(palette, entry, isJustUpdated),
    );
  }

  Widget _buildDisplayRow(AppPalette palette, GiftEntry entry, bool isJustUpdated) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        SizedBox(
          width: 30,
          child: Text(
            _pad(entry.no),
            style: TextStyle(fontFamily: 'Do Hyeon', fontSize: 12, color: palette.textFaint),
          ),
        ),
        Expanded(
          child: Row(
            children: [
              Flexible(
                child: Text(
                  entry.name,
                  style: TextStyle(fontSize: 13.5, fontWeight: FontWeight.w500, color: palette.text),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              if (isJustUpdated)
                Padding(
                  padding: const EdgeInsets.only(left: 4),
                  child: Text('수정됨', style: TextStyle(fontSize: 10, color: palette.good, fontWeight: FontWeight.w700)),
                ),
            ],
          ),
        ),
        SizedBox(
          width: 56,
          child: Text(
            manwonLabel(entry.amount),
            textAlign: TextAlign.right,
            style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: palette.text),
          ),
        ),
        SizedBox(
          width: 44,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              Text('${entry.tickets}장', style: TextStyle(fontSize: 12, color: palette.textSoft)),
              const SizedBox(width: 3),
              TicketIcon(color: palette.textFaint),
            ],
          ),
        ),
        SizedBox(
          width: 44,
          child: TextButton(
            onPressed: () => _startEdit(entry),
            style: TextButton.styleFrom(
              padding: EdgeInsets.zero,
              foregroundColor: palette.accent,
              minimumSize: const Size(40, 32),
            ),
            child: const Text('수정', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700)),
          ),
        ),
      ],
    );
  }

  Widget _buildEditingRow(AppPalette palette, GiftEntry entry) {
    final nameCtrl = _editNameControllers[entry.no]!;
    final amountCtrl = _editAmountControllers[entry.no]!;
    final ticketsCtrl = _editTicketsControllers[entry.no]!;
    final editStyle = TextStyle(fontSize: 12.5, color: palette.text);
    InputDecoration editDecoration() => InputDecoration(
          isDense: true,
          contentPadding: const EdgeInsets.symmetric(horizontal: 6, vertical: 8),
          filled: true,
          fillColor: palette.fillStrong,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(9),
            borderSide: BorderSide(color: palette.accent, width: 1.5),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(9),
            borderSide: BorderSide(color: palette.accent, width: 1.5),
          ),
        );

    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        SizedBox(
          width: 30,
          child: Text(
            _pad(entry.no),
            style: TextStyle(fontFamily: 'Do Hyeon', fontSize: 12, color: palette.textFaint),
          ),
        ),
        Expanded(
          child: TextField(controller: nameCtrl, style: editStyle, decoration: editDecoration()),
        ),
        const SizedBox(width: 4),
        SizedBox(
          width: 56,
          child: TextField(
            controller: amountCtrl,
            style: editStyle,
            textAlign: TextAlign.right,
            decoration: editDecoration(),
          ),
        ),
        const SizedBox(width: 4),
        SizedBox(
          width: 44,
          child: TextField(
            controller: ticketsCtrl,
            style: editStyle,
            textAlign: TextAlign.right,
            decoration: editDecoration(),
          ),
        ),
        const SizedBox(width: 4),
        SizedBox(
          width: 44,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              SizedBox(
                width: 40,
                height: 26,
                child: ElevatedButton(
                  onPressed: () => _completeEdit(entry.no),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: palette.accent,
                    foregroundColor: palette.accentInk,
                    padding: EdgeInsets.zero,
                    textStyle: const TextStyle(fontSize: 11, fontFamily: 'Do Hyeon'),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                  child: const Text('완료'),
                ),
              ),
              GestureDetector(
                onTap: () => _deleteEntry(entry.no),
                onLongPress: () => _cancelEdit(entry.no),
                child: Padding(
                  padding: const EdgeInsets.only(top: 2),
                  child: Text('삭제', style: TextStyle(fontSize: 10, color: palette.warn)),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildExportBar(AppPalette palette) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 14),
      child: Column(
        children: [
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _exporting ? null : () => _export(true),
              style: ElevatedButton.styleFrom(
                backgroundColor: palette.accent,
                foregroundColor: palette.accentInk,
                textStyle: const TextStyle(fontFamily: 'Do Hyeon', fontSize: 15.5),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                padding: const EdgeInsets.symmetric(vertical: 14),
              ),
              child: _exporting
                  ? SizedBox(
                      height: 18,
                      width: 18,
                      child: CircularProgressIndicator(strokeWidth: 2, color: palette.accentInk),
                    )
                  : const Text('엑셀로 내보내기'),
            ),
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              TextButton(
                onPressed: _exporting ? null : () => _export(false),
                child: Text('CSV로 내보내기', style: TextStyle(fontSize: 11.5, color: palette.textFaint)),
              ),
              TextButton(
                onPressed: _resetAll,
                child: Text('전체 비우기', style: TextStyle(fontSize: 11.5, color: palette.textFaint)),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
