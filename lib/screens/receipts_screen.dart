import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:file_picker/file_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../services/receipts_service.dart';
import '../services/localization_service.dart';

class ReceiptsScreen extends StatefulWidget {
  const ReceiptsScreen({super.key});

  @override
  State<ReceiptsScreen> createState() => _ReceiptsScreenState();
}

class _ReceiptsScreenState extends State<ReceiptsScreen> {
  List<Map<String, dynamic>> _receipts = [];
  List<int> _availableYears = [];
  List<int> _availableMonths = [];
  int? _selectedYear;
  int? _selectedMonth;
  bool _isLoading = true;
  String? _userId;

  String t(String locale, String key) => LocalizationService.t(locale, key);

  @override
  void initState() {
    super.initState();
    _initializeData();
  }

  Future<void> _initializeData() async {
    await _getCurrentUser();
    if (_userId != null) {
      await _loadAvailableYears();
      await _loadReceipts();
    }
  }

  Future<void> _getCurrentUser() async {
    final user = Supabase.instance.client.auth.currentUser;
    if (user != null) {
      setState(() {
        _userId = user.id;
      });
    }
  }

  Future<void> _loadAvailableYears() async {
    if (_userId == null) return;

    try {
      final years = await ReceiptsService.getAvailableYears(_userId!);
      setState(() {
        _availableYears = years;
      });
    } catch (e) {
      if (kDebugMode) {
        print('Error loading available years: $e');
      }
    }
  }

  Future<void> _loadAvailableMonths() async {
    if (_userId == null || _selectedYear == null) return;

    try {
      final months = await ReceiptsService.getAvailableMonths(
        _userId!,
        _selectedYear!,
      );
      setState(() {
        _availableMonths = months;
        // Reset selected month if it's not available in the new year
        if (_selectedMonth != null && !months.contains(_selectedMonth)) {
          _selectedMonth = null;
        }
      });
    } catch (e) {
      if (kDebugMode) {
        print('Error loading available months: $e');
      }
    }
  }

  Future<void> _loadReceipts() async {
    if (_userId == null) return;

    setState(() {
      _isLoading = true;
    });

    try {
      final receipts = await ReceiptsService.getStudentReceipts(
        _userId!,
        month: _selectedMonth,
        year: _selectedYear,
      );
      setState(() {
        _receipts = receipts;
      });
    } catch (e) {
      if (kDebugMode) {
        print('Error loading receipts: $e');
      }
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading receipts: ${e.toString()}')),
        );
      }
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _downloadReceipt(Map<String, dynamic> receipt) async {
    final locale = Localizations.localeOf(context).languageCode;
    final fileName = receipt['original_file_name'] as String;

    if (kIsWeb) {
      // For web, show message that download is not supported
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(t(locale, 'web_download_not_supported')),
            duration: const Duration(seconds: 3),
          ),
        );
      }
      return;
    }

    // Show download options dialog
    final option = await showDialog<String>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(t(locale, 'download_options')),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('${t(locale, 'file_name')}: $fileName'),
              const SizedBox(height: 16),
              Text(t(locale, 'choose_download_location')),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text(t(locale, 'cancel')),
            ),
            ElevatedButton(
              onPressed: () => Navigator.of(context).pop('downloads'),
              child: Text(t(locale, 'downloads_folder')),
            ),
            ElevatedButton(
              onPressed: () => Navigator.of(context).pop('choose'),
              child: Text(t(locale, 'choose_location')),
            ),
            TextButton(
              onPressed: () => Navigator.of(context).pop('documents'),
              child: Text(t(locale, 'app_documents')),
            ),
          ],
        );
      },
    );

    if (option == null) return;

    try {
      // Show loading indicator
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(t(locale, 'downloading'))));
      }

      final bytes = await ReceiptsService.downloadReceipt(receipt['file_path']);
      if (bytes == null) {
        if (mounted) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text(t(locale, 'download_failed'))));
        }
        return;
      }

      String? savePath;

      // Add timestamp to filename to prevent conflicts
      final now = DateTime.now();
      final timestamp =
          '${now.year.toString().padLeft(4, '0')}${now.month.toString().padLeft(2, '0')}${now.day.toString().padLeft(2, '0')}-${now.hour.toString().padLeft(2, '0')}${now.minute.toString().padLeft(2, '0')}${now.second.toString().padLeft(2, '0')}';
      final extension = fileName.contains('.') ? fileName.split('.').last : '';
      final nameWithoutExtension = fileName.contains('.')
          ? fileName.substring(0, fileName.lastIndexOf('.'))
          : fileName;
      final timestampedFileName = extension.isNotEmpty
          ? '${nameWithoutExtension}_$timestamp.$extension'
          : '${fileName}_$timestamp';

      if (option == 'downloads') {
        // Try to save to Downloads directory
        try {
          Directory? downloadsDir;
          if (Platform.isAndroid) {
            downloadsDir = Directory('/storage/emulated/0/Download');
            if (!await downloadsDir.exists()) {
              downloadsDir = await getDownloadsDirectory();
            }
          } else {
            downloadsDir = await getDownloadsDirectory();
          }

          if (downloadsDir != null && await downloadsDir.exists()) {
            final file = File('${downloadsDir.path}/$timestampedFileName');
            await file.writeAsBytes(bytes);
            savePath = file.path;
          } else {
            throw Exception('Downloads folder not accessible');
          }
        } catch (e) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('${t(locale, 'downloads_folder_error')}: $e'),
                duration: const Duration(seconds: 4),
              ),
            );
          }
          return;
        }
      } else if (option == 'documents') {
        // Save to app documents directory
        try {
          final documentsDir = await getApplicationDocumentsDirectory();
          final file = File('${documentsDir.path}/$timestampedFileName');
          await file.writeAsBytes(bytes);
          savePath = file.path;
        } catch (e) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('${t(locale, 'documents_folder_error')}: $e'),
                duration: const Duration(seconds: 4),
              ),
            );
          }
          return;
        }
      } else if (option == 'choose') {
        // Let user choose location
        final result = await FilePicker.platform.getDirectoryPath(
          dialogTitle: t(locale, 'choose_save_location'),
        );

        if (result != null) {
          final file = File('$result/$timestampedFileName');
          await file.writeAsBytes(bytes);
          savePath = file.path;
        } else {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(t(locale, 'download_cancelled'))),
            );
          }
          return;
        }
      }

      // Show success message
      if (mounted && savePath != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${t(locale, 'file_saved_to')}: $savePath'),
            duration: const Duration(seconds: 3),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('${t(locale, 'download_error')}: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final locale = Localizations.localeOf(context).languageCode;

    return Scaffold(
      appBar: AppBar(title: Text(t(locale, 'receipts'))),
      body: Column(
        children: [
          // Filters
          Container(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Expanded(
                  child: DropdownButtonFormField<int>(
                    decoration: InputDecoration(
                      labelText: t(locale, 'year'),
                      border: const OutlineInputBorder(),
                    ),
                    // ignore: deprecated_member_use
                    value: _selectedYear,
                    items: [
                      DropdownMenuItem<int>(
                        value: null,
                        child: Text(t(locale, 'all_years')),
                      ),
                      ..._availableYears.map(
                        (year) => DropdownMenuItem(
                          value: year,
                          child: Text(year.toString()),
                        ),
                      ),
                    ],
                    onChanged: (value) async {
                      setState(() {
                        _selectedYear = value;
                        _selectedMonth = null; // Reset month when year changes
                      });
                      if (value != null) {
                        await _loadAvailableMonths();
                      } else {
                        setState(() {
                          _availableMonths = [];
                        });
                      }
                      await _loadReceipts();
                    },
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: DropdownButtonFormField<int>(
                    decoration: InputDecoration(
                      labelText: t(locale, 'month'),
                      border: const OutlineInputBorder(),
                    ),
                    // ignore: deprecated_member_use
                    value: _selectedMonth,
                    items: [
                      DropdownMenuItem<int>(
                        value: null,
                        child: Text(t(locale, 'all_months')),
                      ),
                      ..._availableMonths.map(
                        (month) => DropdownMenuItem(
                          value: month,
                          child: Text(
                            ReceiptsService.getMonthName(month, locale),
                          ),
                        ),
                      ),
                    ],
                    onChanged: (value) async {
                      setState(() {
                        _selectedMonth = value;
                      });
                      await _loadReceipts();
                    },
                  ),
                ),
              ],
            ),
          ),

          // Loading indicator
          if (_isLoading)
            const Expanded(child: Center(child: CircularProgressIndicator()))
          else if (_receipts.isEmpty)
            Expanded(
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.receipt_outlined,
                      size: 64,
                      color: Colors.grey[400],
                    ),
                    const SizedBox(height: 16),
                    Text(
                      t(locale, 'no_receipts_found'),
                      style: Theme.of(context).textTheme.headlineSmall
                          ?.copyWith(color: Colors.grey[600]),
                    ),
                  ],
                ),
              ),
            )
          else
            // Receipts list
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: _receipts.length,
                itemBuilder: (context, index) {
                  final receipt = _receipts[index];
                  final uploadedAt = DateTime.parse(receipt['uploaded_at']);

                  return Card(
                    margin: const EdgeInsets.only(bottom: 8),
                    child: ListTile(
                      leading: Icon(
                        _getFileIcon(receipt['file_type']),
                        size: 32,
                        color: Theme.of(context).primaryColor,
                      ),
                      title: Text(
                        receipt['original_file_name'],
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                      subtitle: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          if (receipt['concerns_month'] != null &&
                              receipt['concerns_year'] != null)
                            Text(
                              '${ReceiptsService.getMonthName(receipt['concerns_month'], locale)} ${receipt['concerns_year']}',
                              style: const TextStyle(
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          Text(
                            '${t(locale, 'uploaded')}: ${uploadedAt.day}/${uploadedAt.month}/${uploadedAt.year}',
                          ),
                          Text(
                            '${t(locale, 'size')}: ${ReceiptsService.formatFileSize(receipt['file_size_bytes'])}',
                          ),
                        ],
                      ),
                      trailing: IconButton(
                        icon: const Icon(Icons.download),
                        onPressed: () => _downloadReceipt(receipt),
                      ),
                    ),
                  );
                },
              ),
            ),
        ],
      ),
    );
  }

  IconData _getFileIcon(String fileType) {
    switch (fileType.toLowerCase()) {
      case 'pdf':
        return Icons.picture_as_pdf;
      case 'jpg':
      case 'jpeg':
      case 'png':
        return Icons.image;
      default:
        return Icons.insert_drive_file;
    }
  }
}
