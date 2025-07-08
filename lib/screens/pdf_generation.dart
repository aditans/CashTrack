import 'dart:io';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:month_picker_dialog/month_picker_dialog.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:path_provider/path_provider.dart';
import 'package:mailer/mailer.dart';
import 'package:mailer/smtp_server.dart';

class PdfEmailPage extends StatefulWidget {
  const PdfEmailPage({super.key});

  @override
  State<PdfEmailPage> createState() => _PdfEmailPageState();
}

class _PdfEmailPageState extends State<PdfEmailPage> {
  bool _sending = false;
  DateTime? _selectedMonth;

  Future<void> _generateAndSendPdf() async {
    // 1. Pick month and year
    final picked = await showMonthPicker(
      context: context,
      initialDate: _selectedMonth ?? DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime.now(),
    );
    if (picked == null) return;
    setState(() => _selectedMonth = picked);

    // 2. Get recipient email
    final email = await _getUserEmail();
    if (email == null || email.isEmpty) return;

    setState(() => _sending = true);

    try {
      // 3. Generate PDF (replace placeholder with real data for the selected month)
      final pdf = pw.Document();
      pdf.addPage(
        pw.MultiPage(build: (ctx) => [
          pw.Header(
            level: 0,
            child: pw.Text(
              'CashTrack Report',
              style: pw.TextStyle(fontSize: 24, fontWeight: pw.FontWeight.bold),
            ),
          ),
          pw.Text(
            'Month: ${DateFormat('MMMM yyyy').format(picked)}',
            style: pw.TextStyle(fontSize: 16),
          ),
          pw.SizedBox(height: 20),
          // TODO: Replace with your actual table or content
          pw.Center(child: pw.Text('Report content goes here…')),
        ]),
      );

      final bytes = await pdf.save();
      final dir = await getApplicationDocumentsDirectory();
      final filePath =
          '${dir.path}/report_${picked.year}_${picked.month.toString().padLeft(2, '0')}.pdf';
      final file = File(filePath);
      await file.writeAsBytes(bytes);

      // 4. Send email with attachment
      await _sendEmailWithAttachment(email, file);

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(Icons.check_circle, color: Colors.green),
              const SizedBox(width: 8),
              Text('PDF sent to $email'),
            ],
          ),
          backgroundColor: Colors.green.shade50,
          behavior: SnackBarBehavior.floating,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(Icons.error, color: Colors.red),
              const SizedBox(width: 8),
              Text('Failed to send: $e'),
            ],
          ),
          backgroundColor: Colors.red.shade50,
          behavior: SnackBarBehavior.floating,
        ),
      );
    } finally {
      setState(() => _sending = false);
    }
  }

  Future<String?> _getUserEmail() async {
    final controller = TextEditingController();
    String? email;
    await showDialog(
      context: context,
      builder: (_) => Dialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.email, color: Colors.blueAccent, size: 48),
              const SizedBox(height: 12),
              const Text(
                "Enter recipient's email",
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: controller,
                decoration: InputDecoration(
                  hintText: 'example@gmail.com',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  prefixIcon: const Icon(Icons.mail_outline),
                ),
                keyboardType: TextInputType.emailAddress,
              ),
              const SizedBox(height: 18),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text('Cancel')),
                  const SizedBox(width: 8),
                  ElevatedButton.icon(
                    onPressed: () {
                      final entered = controller.text.trim();
                      if (entered.contains('@')) {
                        email = entered;
                        Navigator.pop(context);
                      }
                    },
                    icon: const Icon(Icons.send),
                    label: const Text('Send'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blueAccent,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10)),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
    return email;
  }

  Future<void> _sendEmailWithAttachment(String toEmail, File file) async {
    const username = 'your@gmail.com';           // your Gmail address
    const appPassword = 'your_app_password';     // Gmail App Password

    final smtpServer = gmail(username, appPassword);

    final message = Message()
      ..from = Address(username, 'CashTrack')
      ..recipients.add(toEmail)
      ..subject =
          'CashTrack Report ${DateFormat('dd MMM yyyy').format(DateTime.now())}'
      ..text = 'Hello!\nPlease find attached your CashTrack report.'
      ..attachments = [
        FileAttachment(file)
          ..location = Location.inline
          ..fileName = file.uri.pathSegments.last,
      ];

    await send(message, smtpServer);
  }

  @override
  Widget build(BuildContext context) {
    final Color gradientStart = Colors.tealAccent.shade100;
    final Color gradientEnd = Colors.blue.shade200;
    final buttonText = _selectedMonth == null
        ? 'Select Month & Send'
        : 'Send report for ${DateFormat('MMMM yyyy').format(_selectedMonth!)}';

    return Scaffold(
      appBar: AppBar(
        title: const Text("Generate & Email PDF"),
        elevation: 0,
        backgroundColor: gradientEnd,
      ),
      body: Container(
        width: double.infinity,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [gradientStart, gradientEnd],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: Center(
          child: _sending
              ? Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const CircularProgressIndicator(),
              const SizedBox(height: 24),
              Text(
                "Generating and sending PDF...",
                style: TextStyle(
                  color: Colors.blueGrey.shade700,
                  fontSize: 18,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          )
              : Card(
            elevation: 8,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(24),
            ),
            margin: const EdgeInsets.symmetric(horizontal: 24),
            child: Padding(
              padding: const EdgeInsets.symmetric(
                  horizontal: 32, vertical: 36),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.picture_as_pdf,
                      color: Colors.redAccent, size: 64),
                  const SizedBox(height: 18),
                  Text(
                    "Export Monthly PDF Report",
                    style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: Colors.grey[800]),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    _selectedMonth == null
                        ? "Choose a month and send your report to any email address."
                        : "Ready to send your report for ${DateFormat('MMMM yyyy').format(_selectedMonth!)}.",
                    style: TextStyle(
                        fontSize: 16, color: Colors.grey[700]),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 28),
                  ElevatedButton.icon(
                    icon: const Icon(Icons.calendar_month),
                    label: Text(buttonText),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blueAccent,
                      foregroundColor: Colors.white,
                      textStyle: const TextStyle(fontSize: 18),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 24, vertical: 14),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16)),
                    ),
                    onPressed: _generateAndSendPdf,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
