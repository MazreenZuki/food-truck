import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../db/database_helper.dart'; // Adjust this path as needed

class AdminReportPage extends StatefulWidget {
  const AdminReportPage({super.key});

  @override
  State<AdminReportPage> createState() => _AdminReportPageState();
}

class _AdminReportPageState extends State<AdminReportPage> {
  final DatabaseHelper _dbHelper = DatabaseHelper.instance;

  DateTime? startDate;
  DateTime? endDate;

  double totalSales = 0.0;
  String topPackage = '-';
  String reportPeriod = 'Date Range'; // New variable to indicate report type

  // Function to perform database query and update state
  void _generateReport() async {
    if (startDate == null || endDate == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Please select a date range or use a quick filter.')),
      );
      return;
    }

    // Ensure start date is not after end date
    if (startDate!.isAfter(endDate!)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Start Date cannot be after End Date.')),
      );
      return;
    }

    setState(() {
      totalSales = 0.0;
      topPackage = 'Generating...';
    });

    try {
      final reportData = await _dbHelper.generateSalesReport(
        startDate!,
        endDate!,
      );

      setState(() {
        totalSales = reportData['totalSales'] as double;
        topPackage = reportData['topPackage'] as String;
      });
    } catch (e) {
      print("Error generating sales report: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to generate report. Error: $e')),
      );
      setState(() {
        totalSales = 0.0;
        topPackage = 'Error fetching data';
      });
    }
  }

  // === NEW HELPER FUNCTIONS ===

  /// Sets the date range for the current month and generates the report.
  void _generateMonthlyReport() {
    final now = DateTime.now();
    // Start of the month (1st day at midnight)
    final startOfMonth = DateTime(now.year, now.month, 1);
    // End of the month (Last millisecond of the last day)
    final endOfMonth = DateTime(now.year, now.month + 1, 0);

    setState(() {
      startDate = startOfMonth;
      endDate = endOfMonth;
      reportPeriod = DateFormat('MMMM yyyy').format(now);
    });

    // Call the main report function
    _generateReport();
  }

  /// Prompts for a specific date and generates the report for that day.
  void _generateDailyReport() async {
    final pickedDate = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
    );

    if (pickedDate != null) {
      // Start of the selected day (midnight)
      final startOfDay =
          DateTime(pickedDate.year, pickedDate.month, pickedDate.day);
      // End of the selected day (just before midnight of the next day)
      final endOfDay = DateTime(
          pickedDate.year, pickedDate.month, pickedDate.day, 23, 59, 59);

      setState(() {
        startDate = startOfDay;
        endDate = endOfDay;
        reportPeriod = DateFormat('EEE, d MMM yyyy').format(pickedDate);
      });

      // Call the main report function
      _generateReport();
    }
  }

  // ============================

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Sales Report'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            /// Quick Filters
            Text(
              'Quick Filters',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed:
                        _generateMonthlyReport, // New Monthly Report button
                    child: const Text('This Month'),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: OutlinedButton(
                    onPressed: _generateDailyReport, // New Daily Report button
                    child: const Text('Specific Day'),
                  ),
                ),
              ],
            ),
            const Divider(height: 32),

            /// Date Filter (for custom range)
            Text(
              'Custom Date Range',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 12),

            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () async {
                      final picked = await showDatePicker(
                        context: context,
                        initialDate: startDate ?? DateTime.now(),
                        firstDate: DateTime(2020),
                        lastDate: DateTime(2100),
                      );
                      if (picked != null) {
                        setState(() {
                          startDate = picked;
                          reportPeriod = 'Custom Range';
                        });
                      }
                    },
                    child: Text(
                      startDate == null
                          ? 'Start Date'
                          : DateFormat('yyyy-MM-dd').format(startDate!),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: OutlinedButton(
                    onPressed: () async {
                      final picked = await showDatePicker(
                        context: context,
                        initialDate: endDate ?? DateTime.now(),
                        firstDate: DateTime(2020),
                        lastDate: DateTime(2100),
                      );
                      if (picked != null) {
                        setState(() {
                          endDate = picked;
                          reportPeriod = 'Custom Range';
                        });
                      }
                    },
                    child: Text(
                      endDate == null
                          ? 'End Date'
                          : DateFormat('yyyy-MM-dd').format(endDate!),
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 16),

            /// Generate Report Button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _generateReport,
                child: const Text('Generate Custom Report'),
              ),
            ),

            const Divider(height: 32),

            /// Report Result
            Text(
              'Report Summary for $reportPeriod',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 12),

            Expanded(
              child: SingleChildScrollView(
                child: Column(
                  children: [
                    _buildReportCard(
                      title: 'Total Sales',
                      value: 'RM ${NumberFormat("###0.00").format(totalSales)}',
                    ),
                    _buildReportCard(
                      title: 'Top Selling Package',
                      value: topPackage,
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildReportCard({required String title, required String value}) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        title: Text(title),
        trailing: Text(
          value,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
      ),
    );
  }
}
