import 'dart:io';

import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:file_picker/file_picker.dart';

void main() {
  runApp(const AirBridgeApp());
}

class AirBridgeApp extends StatelessWidget {
  const AirBridgeApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'AirBridge',
      theme: ThemeData(
        useMaterial3: true,
        brightness: Brightness.dark,
        scaffoldBackgroundColor: const Color(0xFF0B1220),
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF20D6C7),
          brightness: Brightness.dark,
        ),
        fontFamily: 'Roboto',
      ),
      home: const AirBridgeHomePage(),
    );
  }
}

class AirBridgeHomePage extends StatefulWidget {
  const AirBridgeHomePage({super.key});

  @override
  State<AirBridgeHomePage> createState() => _AirBridgeHomePageState();
}

class _AirBridgeHomePageState extends State<AirBridgeHomePage> {
  HttpServer? _receiveServer;
  String? _receiveUrl;
  StateSetter? _refreshReceiverDialog;
  final List<String> _receivedFiles = [];

  static const Color teal = Color(0xFF20D6C7);
  static const Color cardColor = Color(0xFF151F30);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(22),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 18),

              // App branding
              Row(
                children: [
                  Container(
                    width: 52,
                    height: 52,
                    decoration: BoxDecoration(
                      color: teal.withValues(alpha: 0.13),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: const Icon(
                      Icons.swap_horiz_rounded,
                      color: teal,
                      size: 34,
                    ),
                  ),
                  const SizedBox(width: 13),
                  const Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'AirBridge',
                        style: TextStyle(
                          fontSize: 25,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 0.3,
                        ),
                      ),
                      SizedBox(height: 3),
                      Text(
                        'Share freely. Connect instantly.',
                        style: TextStyle(
                          color: Colors.white60,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ],
              ),

              const SizedBox(height: 38),

              // Welcome section
              const Text(
                'Your files,',
                style: TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.w300,
                ),
              ),
              const Text(
                'moving freely.',
                style: TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                  color: teal,
                ),
              ),
              const SizedBox(height: 12),
              const Text(
                'Transfer photos, videos and documents\nbetween devices on your local network.',
                style: TextStyle(
                  fontSize: 14,
                  height: 1.6,
                  color: Colors.white60,
                ),
              ),

              const SizedBox(height: 28),

              // Connection status
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(17),
                decoration: BoxDecoration(
                  color: cardColor,
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(color: Colors.white10),
                ),
                child: const Row(
                  children: [
                    Icon(
                      Icons.wifi_rounded,
                      color: teal,
                      size: 28,
                    ),
                    SizedBox(width: 13),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Ready to connect',
                            style: TextStyle(
                              fontWeight: FontWeight.w600,
                              fontSize: 15,
                            ),
                          ),
                          SizedBox(height: 4),
                          Text(
                            'Connect both devices to the same Wi-Fi',
                            style: TextStyle(
                              color: Colors.white54,
                              fontSize: 11,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Icon(
                      Icons.circle,
                      size: 9,
                      color: teal,
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 28),

              const Text(
                'GET STARTED',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 2,
                  color: Colors.white54,
                ),
              ),

              const SizedBox(height: 14),

              // Send files
              _ActionCard(
                icon: Icons.upload_rounded,
                title: 'Send files',
                subtitle: 'Choose files to share with another device',
                color: teal,
                onTap: () {
                  _pickFiles(context);
                },
              ),

              const SizedBox(height: 14),

              // Receive files
              _ActionCard(
                icon: Icons.download_rounded,
                title: 'Receive files',
                subtitle: 'Connect and receive files from another device',
                color: const Color(0xFF8EA9FF),
                onTap: () {
                  _startReceiving(context);
                },
              ),

              const SizedBox(height: 14),

              // QR connection
              _ActionCard(
                icon: Icons.qr_code_scanner_rounded,
                title: 'Connect with QR',
                subtitle: 'Scan a code to connect devices quickly',
                color: const Color(0xFFFFC66D),
                onTap: () {
                  _showComingSoon(context, 'QR connection');
                },
              ),

              const SizedBox(height: 28),

              // Privacy information
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(17),
                decoration: BoxDecoration(
                  color: teal.withValues(alpha: 0.07),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: teal.withValues(alpha: 0.18),
                  ),
                ),
                child: const Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(
                      Icons.shield_outlined,
                      color: teal,
                      size: 24,
                    ),
                    SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Your files. Your devices.',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                            ),
                          ),
                          SizedBox(height: 5),
                          Text(
                            'AirBridge is designed for direct transfers '
                            'over your local network.',
                            style: TextStyle(
                              color: Colors.white60,
                              fontSize: 12,
                              height: 1.5,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 25),

              const Center(
                child: Text(
                  'AIRBRIDGE  •  PRIVATE FILE SHARING',
                  style: TextStyle(
                    color: Colors.white30,
                    fontSize: 10,
                    letterSpacing: 1.2,
                  ),
                ),
              ),

              const SizedBox(height: 12),
            ],
          ),
        ),
      ),
    );
  }

  static Future<void> _pickFiles(BuildContext context) async {
    try {
      final result = await FilePicker.platform.pickFiles(allowMultiple: true);
      if (result == null || !context.mounted) return;
      final files = result.files;
      await showDialog<void>(
        context: context,
        builder: (dialogContext) => AlertDialog(
          backgroundColor: cardColor,
          title: Text('Selected files (${files.length})'),
          content: SizedBox(
            width: double.maxFinite,
            child: ListView.separated(
              shrinkWrap: true,
              itemCount: files.length,
              separatorBuilder: (_, _) => const Divider(color: Colors.white12),
              itemBuilder: (context, index) {
                final file = files[index];
                final size = file.size < 1024
                    ? '${file.size} B'
                    : file.size < 1024 * 1024
                        ? '${(file.size / 1024).toStringAsFixed(1)} KB'
                        : '${(file.size / (1024 * 1024)).toStringAsFixed(1)} MB';
                return ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: const Icon(Icons.insert_drive_file_outlined, color: teal),
                  title: Text(file.name, maxLines: 2, overflow: TextOverflow.ellipsis),
                  subtitle: Text(size, style: const TextStyle(color: Colors.white54)),
                );
              },
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(),
              child: const Text('Done'),
            ),
          ],
        ),
      );
    } catch (error) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Could not open file picker: $error')),
      );
    }
  }

  Future<void> _startReceiving(BuildContext context) async {
    try {
      if (_receiveServer != null) {
        await _showReceiverDialog(context);
        return;
      }

      final interfaces = await NetworkInterface.list(
        includeLoopback: false,
        type: InternetAddressType.IPv4,
      );
      final addresses = interfaces
          .expand((interface) => interface.addresses)
          .where((address) => !address.isLoopback && !address.isLinkLocal)
          .toList();

      if (addresses.isEmpty) {
        throw Exception('No local Wi-Fi address found. Connect to Wi-Fi and try again.');
      }

      final server = await HttpServer.bind(InternetAddress.anyIPv4, 8765);
      _receiveServer = server;
      _receiveUrl = 'http://${addresses.first.address}:8765';

      server.listen((request) async {
        try {
          if (request.method == 'GET' && request.uri.path == '/') {
            request.response.headers.contentType = ContentType.html;
            request.response.write(_receiverHtml);
            await request.response.close();
            return;
          }

          if (request.method == 'POST' && request.uri.path == '/upload') {
            final rawName = request.uri.queryParameters['name'] ?? 'received_file';
            final safeName = rawName
                .replaceAll(RegExp(r'[\\/:*?"<>|]'), '_')
                .replaceAll('..', '_');
            final directory = await getApplicationDocumentsDirectory();
            var target = File('${directory.path}/$safeName');
            var count = 1;
            while (await target.exists()) {
              final dot = safeName.lastIndexOf('.');
              final base = dot > 0 ? safeName.substring(0, dot) : safeName;
              final ext = dot > 0 ? safeName.substring(dot) : '';
              target = File('${directory.path}/${base}_$count$ext');
              count++;
            }
            await target.writeAsBytes(await request.fold<List<int>>(
              <int>[],
              (bytes, chunk) => bytes..addAll(chunk),
            ));
            if (mounted) {
              setState(() => _receivedFiles.add(target.uri.pathSegments.last));
              _refreshReceiverDialog?.call(() {});
            }
            request.response
              ..statusCode = HttpStatus.ok
              ..headers.contentType = ContentType.text
              ..write('Received successfully');
            await request.response.close();
            return;
          }

          request.response
            ..statusCode = HttpStatus.notFound
            ..write('Not found');
          await request.response.close();
        } catch (error) {
          request.response
            ..statusCode = HttpStatus.internalServerError
            ..write('Upload failed');
          await request.response.close();
        }
      });

      if (!context.mounted) return;
      await _showReceiverDialog(context);
    } catch (error) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Could not start receiving: $error')),
      );
    }
  }

  Future<void> _showReceiverDialog(BuildContext context) async {
    await showDialog<void>(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (dialogContext, refreshDialog) {
          _refreshReceiverDialog = refreshDialog;
          return AlertDialog(
          backgroundColor: cardColor,
          title: const Text('Receive files'),
          content: SizedBox(
            width: double.maxFinite,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(Icons.wifi_tethering_rounded, color: teal, size: 38),
                const SizedBox(height: 12),
                const Text('On the sending device, open a browser connected to the same Wi-Fi and visit:'),
                const SizedBox(height: 10),
                SelectableText(
                  _receiveUrl ?? '',
                  style: const TextStyle(color: teal, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 10),
                const Text(
                  'Keep AirBridge open while receiving. Only use this on a trusted Wi-Fi network.',
                  style: TextStyle(color: Colors.white60, fontSize: 12),
                ),
                const SizedBox(height: 14),
                const Text('Received in this session:', style: TextStyle(fontWeight: FontWeight.bold)),
                const SizedBox(height: 6),
                if (_receivedFiles.isEmpty)
                  const Text('No files received yet.', style: TextStyle(color: Colors.white54))
                else
                  ..._receivedFiles.map((name) => Padding(
                        padding: const EdgeInsets.only(bottom: 4),
                        child: Text('✓ $name', maxLines: 2, overflow: TextOverflow.ellipsis),
                      )),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () async {
                await _receiveServer?.close(force: true);
                _receiveServer = null;
                if (mounted) {
                  setState(() => _receiveUrl = null);
                }
                if (dialogContext.mounted) Navigator.of(dialogContext).pop();
              },
              child: const Text('Stop receiving'),
            ),
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(),
              child: const Text('Done'),
            ),
          ],
          );
        },
      ),
    );
  }

  static const String _receiverHtml = r'''<!doctype html>
<html><head><meta name="viewport" content="width=device-width, initial-scale=1">
<title>AirBridge Receive</title>
<style>
body{font-family:system-ui;background:#0b1220;color:#f5f7fb;max-width:620px;margin:40px auto;padding:20px}
main{background:#151f30;border:1px solid #2b394d;border-radius:18px;padding:24px}
h1{color:#20d6c7}button{background:#20d6c7;border:0;border-radius:10px;padding:12px 18px;font-weight:700}
input{margin:16px 0;max-width:100%}#status{white-space:pre-wrap;color:#20d6c7}
</style></head><body><main><h1>AirBridge</h1><h2>Send files to this device</h2>
<p>Choose files below, then tap Upload. Keep the receiving phone open in AirBridge.</p>
<input id="files" type="file" multiple><br><button onclick="upload()">Upload files</button>
<p id="status">Waiting for files.</p></main>
<script>
async function upload(){
 const files=document.getElementById('files').files;
 const status=document.getElementById('status');
 if(!files.length){status.textContent='Choose at least one file first.';return;}
 for(const file of files){
  status.textContent='Uploading '+file.name+'...';
  try{
   const response=await fetch('/upload?name='+encodeURIComponent(file.name),{method:'POST',body:file});
   if(!response.ok)throw new Error('Upload failed');
   status.textContent+='\n✓ '+file.name+' received';
  }catch(e){status.textContent+='\n✗ '+file.name+': '+e.message;break;}
 }
}
</script></body></html>''';

  static void _showComingSoon(BuildContext context, String feature) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('$feature will be available in the next step.'),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }
}

class _ActionCard extends StatelessWidget {
  const _ActionCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.color,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: const Color(0xFF151F30),
      borderRadius: BorderRadius.circular(18),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(18),
        child: Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: Colors.white10),
          ),
          child: Row(
            children: [
              Container(
                width: 50,
                height: 50,
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(15),
                ),
                child: Icon(
                  icon,
                  color: color,
                  size: 27,
                ),
              ),
              const SizedBox(width: 15),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 5),
                    Text(
                      subtitle,
                      style: const TextStyle(
                        fontSize: 12,
                        color: Colors.white54,
                        height: 1.4,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Icon(
                Icons.arrow_forward_ios_rounded,
                color: color,
                size: 16,
              ),
            ],
          ),
        ),
      ),
    );
  }
}