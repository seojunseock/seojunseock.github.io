import 'dart:convert';
import 'dart:io';

import 'package:excel/excel.dart' as xls;
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

import '../models/gift_entry.dart';
import 'storage_service.dart';

/// Builds the reconciliation file the couple hands to whoever balances the
/// cash box afterward, and hands it to the OS share sheet. No server is
/// involved — the file is written to this device and shared directly, the
/// same way a photo goes from camera roll to a messaging app.
class ExportService {
  List<GiftEntry> _sortedByNo(LedgerData data) =>
      [...data.entries]..sort((a, b) => a.no.compareTo(b.no));

  Future<void> exportAsExcel(LedgerData data) async {
    final entries = _sortedByNo(data);
    final totalAmount = entries.fold<int>(0, (sum, e) => sum + e.amount);
    final usedTickets = entries.fold<int>(0, (sum, e) => sum + e.tickets);
    final remainingTickets = data.ticketTotal - usedTickets;

    final workbook = xls.Excel.createExcel();
    const sheetName = '축의금 명단';
    workbook.rename(workbook.getDefaultSheet()!, sheetName);

    workbook.appendRow(sheetName, [
      xls.TextCellValue('번호'),
      xls.TextCellValue('이름'),
      xls.TextCellValue('축의금(만원)'),
      xls.TextCellValue('식권(장)'),
    ]);
    for (final entry in entries) {
      workbook.appendRow(sheetName, [
        xls.IntCellValue(entry.no),
        xls.TextCellValue(entry.name),
        xls.IntCellValue(entry.amount),
        xls.IntCellValue(entry.tickets),
      ]);
    }
    workbook.appendRow(sheetName, [xls.TextCellValue('')]);
    workbook.appendRow(sheetName, [
      xls.TextCellValue('총 인원'),
      xls.IntCellValue(entries.length),
    ]);
    workbook.appendRow(sheetName, [
      xls.TextCellValue('총 축의금(만원)'),
      xls.IntCellValue(totalAmount),
    ]);
    workbook.appendRow(sheetName, [
      xls.TextCellValue('식권 준비 수량'),
      xls.IntCellValue(data.ticketTotal),
    ]);
    workbook.appendRow(sheetName, [
      xls.TextCellValue('식권 사용'),
      xls.IntCellValue(usedTickets),
    ]);
    workbook.appendRow(sheetName, [
      xls.TextCellValue('식권 잔여'),
      xls.IntCellValue(remainingTickets),
    ]);

    final bytes = workbook.save();
    if (bytes == null) return;

    final dir = await getTemporaryDirectory();
    final file = File('${dir.path}/축의금_정산.xlsx');
    await file.writeAsBytes(bytes, flush: true);

    await Share.shareXFiles([XFile(file.path)], text: '축의금 정산 결과');
  }

  Future<void> exportAsCsv(LedgerData data) async {
    final entries = _sortedByNo(data);
    final totalAmount = entries.fold<int>(0, (sum, e) => sum + e.amount);
    final usedTickets = entries.fold<int>(0, (sum, e) => sum + e.tickets);
    final remainingTickets = data.ticketTotal - usedTickets;

    String csvField(Object value) => '"${value.toString().replaceAll('"', '""')}"';
    String csvRow(List<Object> values) => '${values.map(csvField).join(',')}\n';

    final buffer = StringBuffer();
    buffer.write(csvRow(['번호', '이름', '축의금(만원)', '식권(장)']));
    for (final entry in entries) {
      buffer.write(csvRow([entry.no, entry.name, entry.amount, entry.tickets]));
    }
    buffer.write('\n');
    buffer.write(csvRow(['총 인원', entries.length]));
    buffer.write(csvRow(['총 축의금(만원)', totalAmount]));
    buffer.write(csvRow(['식권 준비 수량', data.ticketTotal]));
    buffer.write(csvRow(['식권 사용', usedTickets]));
    buffer.write(csvRow(['식권 잔여', remainingTickets]));

    // UTF-8 BOM so Excel opens Korean text correctly instead of garbling it.
    final bytes = <int>[0xEF, 0xBB, 0xBF, ...utf8.encode(buffer.toString())];

    final dir = await getTemporaryDirectory();
    final file = File('${dir.path}/축의금_정산.csv');
    await file.writeAsBytes(bytes, flush: true);

    await Share.shareXFiles([XFile(file.path)], text: '축의금 정산 결과');
  }
}
