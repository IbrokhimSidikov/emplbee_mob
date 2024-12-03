import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'dart:convert';

class AttendanceListPage extends StatefulWidget {
  const AttendanceListPage({super.key});

  @override
  State<AttendanceListPage> createState() => _AttendanceListPageState();
}

class _AttendanceListPageState extends State<AttendanceListPage> {
  final List<WorkEntry> workEntries = [];
  final _storage = FlutterSecureStorage();

  @override
  void initState() {
    super.initState();
    _loadWorkEntries();
  }

  Future<void> _loadWorkEntries() async {
    final entriesJson = await _storage.read(key: 'work_entries');
    if (entriesJson != null) {
      final List<dynamic> entries = json.decode(entriesJson);
      setState(() {
        workEntries.clear();
        workEntries.addAll(
          entries.map((entry) => WorkEntry.fromJson(entry)).toList(),
        );
        workEntries.sort((a, b) => b.checkIn.compareTo(a.checkIn));
      });
    }
  }

  String _formatDuration(DateTime? checkIn, DateTime? checkOut) {
    if (checkIn == null || checkOut == null) return '-';
    final duration = checkOut.difference(checkIn);
    final hours = duration.inHours;
    final minutes = duration.inMinutes.remainder(60);
    return '${hours}h ${minutes}m';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Work Entries'),
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            Navigator.pushReplacementNamed(context, '/homepage');
          },
        ),
      ),
      body: RefreshIndicator(
        onRefresh: _loadWorkEntries,
        child: SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: SingleChildScrollView(
            child: DataTable(
              headingRowColor: MaterialStateProperty.all(Colors.blue[50]),
              columns: const [
                DataColumn(
                  label: Text(
                    'Date',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
                DataColumn(
                  label: Text(
                    'Check-in',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
                DataColumn(
                  label: Text(
                    'Check-out',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
                DataColumn(
                  label: Text(
                    'Duration',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
              ],
              rows: workEntries.map((entry) {
                return DataRow(
                  cells: [
                    DataCell(Text(
                      DateFormat('dd/MM/yyyy').format(entry.checkIn),
                    )),
                    DataCell(Text(
                      DateFormat('HH:mm').format(entry.checkIn),
                    )),
                    DataCell(Text(
                      entry.checkOut != null
                          ? DateFormat('HH:mm').format(entry.checkOut!)
                          : 'Active',
                      style: TextStyle(
                        color: entry.checkOut == null ? Colors.green : null,
                        fontWeight:
                            entry.checkOut == null ? FontWeight.bold : null,
                      ),
                    )),
                    DataCell(Text(
                      _formatDuration(entry.checkIn, entry.checkOut),
                    )),
                  ],
                );
              }).toList(),
            ),
          ),
        ),
      ),
    );
  }
}

class WorkEntry {
  final String id;
  final DateTime checkIn;
  final DateTime? checkOut;

  WorkEntry({
    required this.id,
    required this.checkIn,
    this.checkOut,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'checkIn': checkIn.toIso8601String(),
      'checkOut': checkOut?.toIso8601String(),
    };
  }

  factory WorkEntry.fromJson(Map<String, dynamic> json) {
    return WorkEntry(
      id: json['id'],
      checkIn: DateTime.parse(json['checkIn']),
      checkOut: json['checkOut'] != null ? DateTime.parse(json['checkOut']) : null,
    );
  }
}