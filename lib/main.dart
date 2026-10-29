import 'dart:io';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:math';
import 'package:path_provider/path_provider.dart';
import 'package:file_picker/file_picker.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:url_launcher/url_launcher.dart';

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
        brightness: Brightness.light,
        scaffoldBackgroundColor: const Color(0xFFF3F9FF),
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF38A9F5),
          brightness: Brightness.light,
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
  HttpServer? _sendServer;
  RawDatagramSocket? _discoverySocket;
  String? _sendUrl;
  List<PlatformFile> _sharedFiles = [];
  StateSetter? _refreshReceiverDialog;
  final List<String> _receivedFiles = [];

  static const Color teal = Color(0xFF249DE8);
  static const Color cardColor = Colors.white;
  static const MethodChannel _shareChannel = MethodChannel('airbridge/share');
  String _transferCode = '';

  @override
  void initState() {
    super.initState();
    _shareChannel.setMethodCallHandler((call) async {
      if (call.method == 'sharedFiles') await _acceptSharedFiles(call.arguments);
      if (call.method == 'openReceiver' && mounted) await _showNearbyDevices(context);
    });
    _loadInitialSharedFiles();
  }

  Future<void> _loadInitialSharedFiles() async {
    try {
      final files = await _shareChannel.invokeMethod<List<dynamic>>('getSharedFiles');
      if (files != null && files.isNotEmpty) await _acceptSharedFiles(files);
    } catch (_) {}
  }

  Future<void> _acceptSharedFiles(dynamic rawFiles) async {
    if (rawFiles is! List) return;
    final files = <PlatformFile>[];
    for (final item in rawFiles) {
      if (item is Map) {
        final path = item['path']?.toString();
        final name = item['name']?.toString() ?? 'Shared file';
        final size = int.tryParse(item['size']?.toString() ?? '') ?? 0;
        if (path != null && path.isNotEmpty) files.add(PlatformFile(name: name, size: size, path: path));
      }
    }
    if (!mounted || files.isEmpty) return;
    setState(() { _sharedFiles = files; _transferCode = (1000 + Random.secure().nextInt(9000)).toString(); });
    await _startSharing(context);
    if (mounted) await _showSendDialog(context);
  }

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
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(18),
                    child: Image.asset(
                      'logo.jpg',
                      width: 112,
                      height: 112,
                      fit: BoxFit.contain,
                      errorBuilder: (context, error, stackTrace) => Container(
                        width: 64,
                        height: 64,
                        decoration: BoxDecoration(
                          color: teal.withValues(alpha: 0.13),
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: const Icon(Icons.swap_horiz_rounded, color: teal, size: 34),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  const Expanded(
                    child: Text(
                      'Share freely. Connect instantly.',
                      style: TextStyle(color: Colors.black54, fontSize: 12),
                    ),
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
                  color: Colors.black54,
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
                  border: Border.all(color: Colors.black12),
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
                              color: Colors.black54,
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
                  color: Colors.black45,
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

              _ActionCard(
                icon: Icons.radar_rounded,
                title: 'Scan nearby devices',
                subtitle: 'Look for AirBridge devices around you',
                color: const Color(0xFF249DE8),
                onTap: () => _showNearbyDevices(context),
              ),

              const SizedBox(height: 14),

              // QR connection
              _ActionCard(
                icon: Icons.qr_code_scanner_rounded,
                title: 'Connect with QR',
                subtitle: 'Scan a code to connect devices quickly',
                color: const Color(0xFFFFC66D),
                onTap: () => _showNearbyDevices(context),
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
                    color: Colors.black38,
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

  Future<void> _pickFiles(BuildContext context) async {
    try {
      final result = await FilePicker.platform.pickFiles(allowMultiple: true);
      if (result == null || !context.mounted) return;
      final files = result.files;
      if (files.any((file) => file.path == null)) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('One or more selected files could not be accessed. Please choose them again.')),
        );
        return;
      }
      setState(() { _sharedFiles = files; _transferCode = (1000 + Random.secure().nextInt(9000)).toString(); });
      await _showSendDialog(context);
    } catch (error) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Could not open file picker: $error')),
      );
    }
  }

  Future<void> _showSendDialog(BuildContext context) async {
    await showDialog<void>(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (dialogContext, refreshDialog) => AlertDialog(
          backgroundColor: cardColor,
          scrollable: true,
          title: Text(_sendServer == null ? 'Selected files (${_sharedFiles.length})' : 'Files ready to download'),
          content: SizedBox(
            width: double.maxFinite,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (_sendServer == null) ...[
                  Container(width: double.infinity, padding: const EdgeInsets.all(16), decoration: BoxDecoration(color: const Color(0xFFE8F5FF), borderRadius: BorderRadius.circular(16)), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [const Text('YOUR TRANSFER CODE', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, letterSpacing: 1.2, color: Color(0xFF47718F))), const SizedBox(height: 6), Text(_transferCode.isEmpty ? '----' : _transferCode, style: const TextStyle(fontSize: 34, letterSpacing: 8, fontWeight: FontWeight.bold, color: Color(0xFF167CC0))), const SizedBox(height: 4), const Text('Share this code with the receiving device.', style: TextStyle(fontSize: 12, color: Color(0xFF47718F)))])),
                  const SizedBox(height: 14),
                  const Text('Tap Start sharing to prepare your files. The receiver can use the address or QR code while both devices are on a reachable network.'),
                  const SizedBox(height: 12),
                  ConstrainedBox(
                    constraints: const BoxConstraints(maxHeight: 220),
                    child: ListView.builder(
                      shrinkWrap: true,
                      itemCount: _sharedFiles.length,
                      itemBuilder: (context, index) => ListTile(
                        contentPadding: EdgeInsets.zero,
                        leading: const Icon(Icons.insert_drive_file_outlined, color: teal),
                        title: Text(_sharedFiles[index].name, maxLines: 2, overflow: TextOverflow.ellipsis),
                        subtitle: Text(_formatSize(_sharedFiles[index].size), style: const TextStyle(color: Colors.black54)),
                      ),
                    ),
                  ),
                ] else ...[
                  const Icon(Icons.wifi_tethering_rounded, color: teal, size: 38),
                  const SizedBox(height: 12),
                  const Text('On the receiving device, open this address in a browser on the same Wi-Fi:'),
                  const SizedBox(height: 10),
                  SelectableText(_sendUrl ?? '', style: const TextStyle(color: teal, fontWeight: FontWeight.bold)),
                  if (_sendUrl != null) ...[
                    const SizedBox(height: 16),
                    Center(child: _qrCode(_sendUrl!)),
                    const SizedBox(height: 8),
                    const Center(child: Text('Scan this code on the receiving device', style: TextStyle(color: Colors.white60, fontSize: 12))),
                  ],
                  const SizedBox(height: 10),
                  const Text('The receiver can scan the code or open the address in a browser on the same Wi-Fi. Keep AirBridge open while sharing.', style: TextStyle(color: Colors.white60, fontSize: 12)),
                ],
              ],
            ),
          ),
          actions: [
            if (_sendServer == null)
              TextButton(
                onPressed: () async {
                  await _startSharing(context);
                  refreshDialog(() {});
                },
                child: const Text('Start sharing'),
              )
            else
              TextButton(
                onPressed: () async {
                  await _sendServer?.close(force: true);
                  _sendServer = null;
                  _sendUrl = null;
                  if (dialogContext.mounted) Navigator.of(dialogContext).pop();
                  if (mounted) setState(() {});
                },
                child: const Text('Stop sharing'),
              ),
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(),
              child: Text(_sendServer == null ? 'Cancel' : 'Done'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _startSharing(BuildContext context) async {
    try {
      if (_sharedFiles.isEmpty || _sharedFiles.any((file) => file.path == null)) {
        throw Exception('Please select accessible files first.');
      }
      final interfaces = await NetworkInterface.list(
        includeLoopback: false,
        type: InternetAddressType.IPv4,
      );
      final addresses = interfaces.expand((interface) => interface.addresses)
          .where((address) => !address.isLoopback && !address.isLinkLocal).toList();
      if (addresses.isEmpty) {
        throw Exception('No local network address found. Connect to Wi-Fi and try again.');
      }
      final server = await HttpServer.bind(InternetAddress.anyIPv4, 8766);
      _sendServer = server;
      _sendUrl = 'http://${addresses.first.address}:8766';
      server.listen((request) async {
        try {
          if (request.method == 'GET' && request.uri.path == '/verify') {
            final valid = request.uri.queryParameters['code'] == _transferCode;
            request.response.statusCode = valid ? HttpStatus.ok : HttpStatus.forbidden;
            request.response.headers.contentType = ContentType.json;
            request.response.write(jsonEncode(valid ? {'files': _sharedFiles.map((file) => {'name': file.name, 'size': file.size}).toList()} : {'error': 'Invalid transfer code'}));
            await request.response.close();
            return;
          }
          if (request.method == 'GET' && request.uri.path == '/') {
            request.response.headers.contentType = ContentType.html;
            final rows = _sharedFiles.asMap().entries.map((entry) {
              final name = const HtmlEscape().convert(entry.value.name);
              return '<li><a href="/download?index=${entry.key}">Download $name</a> <small>(${_formatSize(entry.value.size)})</small></li>';
            }).join('\n');
            request.response.write('''<!doctype html><html><head><meta name="viewport" content="width=device-width, initial-scale=1"><title>AirBridge downloads</title><style>body{font-family:system-ui;background:#0b1220;color:#f5f7fb;max-width:620px;margin:40px auto;padding:20px}main{background:#151f30;border:1px solid #2b394d;border-radius:18px;padding:24px}h1{color:#20d6c7}a{color:#20d6c7;line-height:2}</style></head><body><main><h1>AirBridge</h1><h2>Download shared files</h2><p>Tap a file below to download it to this device.</p><ul>$rows</ul></main></body></html>''');
            await request.response.close();
            return;
          }
          if (request.method == 'GET' && request.uri.path == '/download') {
            final index = int.tryParse(request.uri.queryParameters['index'] ?? '');
            if (index == null || index < 0 || index >= _sharedFiles.length) {
              request.response.statusCode = HttpStatus.notFound;
              await request.response.close();
              return;
            }
            final picked = _sharedFiles[index];
            final file = File(picked.path!);
            if (!await file.exists()) {
              request.response.statusCode = HttpStatus.notFound;
              await request.response.close();
              return;
            }
            final safeName = picked.name.replaceAll('"', '').replaceAll('\r', '').replaceAll('\n', '');
            request.response.headers
              ..set(HttpHeaders.contentTypeHeader, 'application/octet-stream')
              ..set('Content-Disposition', 'attachment; filename="$safeName"')
              ..contentLength = await file.length();
            await request.response.addStream(file.openRead());
            await request.response.close();
            return;
          }
          request.response.statusCode = HttpStatus.notFound;
          await request.response.close();
        } catch (_) {
          try {
            request.response.statusCode = HttpStatus.internalServerError;
            await request.response.close();
          } catch (_) {
            // The response may already have been closed after a client disconnect.
          }
        }
      });
      if (mounted) setState(() {});
    } catch (error) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Could not start sharing: $error')));
      }
    }
  }


  Widget _qrCode(String data) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(14)),
      child: QrImageView(
        data: data,
        version: QrVersions.auto,
        size: 180,
        backgroundColor: Colors.white,
        eyeStyle: const QrEyeStyle(eyeShape: QrEyeShape.square, color: Color(0xFF0B1220)),
        dataModuleStyle: const QrDataModuleStyle(dataModuleShape: QrDataModuleShape.square, color: Color(0xFF0B1220)),
      ),
    );
  }

  Future<List<Map<String, String>>> _discoverSenders() async {
    final socket = await RawDatagramSocket.bind(InternetAddress.anyIPv4, 0);
    final found = <String, Map<String, String>>{};
    final done = Completer<List<Map<String, String>>>();
    late StreamSubscription<RawSocketEvent> subscription;
    subscription = socket.listen((event) {
      if (event != RawSocketEvent.read) return;
      Datagram? packet;
      while ((packet = socket.receive()) != null) {
        try {
          final data = jsonDecode(utf8.decode(packet!.data));
          if (data is Map && data['type'] == 'airbridge_offer') {
            final host = data['host']?.toString() ?? packet!.address.address;
            final port = int.tryParse(data['port']?.toString() ?? '') ?? 8766;
            final name = data['name']?.toString() ?? 'AirBridge device';
            found['http://$host:$port'] = {'url': 'http://$host:$port', 'name': name};
          }
        } catch (_) {}
      }
    });
    socket.broadcastEnabled = true;
    socket.send(utf8.encode(jsonEncode({'type': 'airbridge_discover'})), InternetAddress('255.255.255.255'), 8767);
    Future<void>.delayed(const Duration(seconds: 4)).then((_) { if (!done.isCompleted) done.complete(found.values.toList()); });
    try { return await done.future; } finally { await subscription.cancel(); socket.close(); }
  }

  Future<void> _showNearbyDevices(BuildContext context) async {
    final codeController = TextEditingController();
    final addressController = TextEditingController();
    var scanning = false;
    var status = 'Scan for a sender first. If needed, enter its address manually.';
    var found = <Map<String, String>>[];
    await showModalBottomSheet<void>(
      context: context, isScrollControlled: true, backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(26))),
      builder: (sheetContext) => StatefulBuilder(builder: (sheetContext, refresh) => Padding(
        padding: EdgeInsets.fromLTRB(24, 24, 24, MediaQuery.of(sheetContext).viewInsets.bottom + 28),
        child: SingleChildScrollView(child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
          const Center(child: Icon(Icons.radar_rounded, size: 42, color: teal)),
          const SizedBox(height: 16),
          const Text('Connect to a nearby device', style: TextStyle(fontSize: 21, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          const Text('AirBridge searches nearby senders first. Both phones must be reachable on the same network in this version.', style: TextStyle(color: Colors.black54, height: 1.5)),
          const SizedBox(height: 16),
          SizedBox(width: double.infinity, child: FilledButton.icon(
            onPressed: scanning ? null : () async {
              refresh(() { scanning = true; status = 'Searching for AirBridge senders…'; });
              try {
                final devices = await _discoverSenders();
                if (!sheetContext.mounted) return;
                refresh(() {
                  scanning = false; found = devices;
                  if (devices.isEmpty) { status = 'No sender found. Start sharing on the other phone and try again.'; }
                  else { addressController.text = devices.first['url']!; status = 'Found ${devices.length} device(s). Selected ${devices.first['name']}.'; }
                });
              } catch (error) {
                if (!sheetContext.mounted) return;
                refresh(() { scanning = false; status = 'Scan failed: $error'; });
              }
            },
            icon: scanning ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2)) : const Icon(Icons.radar_rounded),
            label: Text(scanning ? 'Scanning…' : 'Scan nearby devices'),
          )),
          const SizedBox(height: 10),
          Text(status, style: const TextStyle(color: Colors.black54, height: 1.4)),
          if (found.isNotEmpty) ...found.map((device) => ListTile(
            contentPadding: EdgeInsets.zero, leading: const Icon(Icons.phone_android_rounded, color: teal),
            title: Text(device['name'] ?? 'AirBridge device'), subtitle: Text(device['url'] ?? ''),
            onTap: () => addressController.text = device['url'] ?? '',
          )),
          const SizedBox(height: 12),
          TextField(controller: addressController, keyboardType: TextInputType.url, decoration: const InputDecoration(labelText: 'Sender address (optional)', hintText: 'http://192.168.1.6:8766', border: OutlineInputBorder())),
          const SizedBox(height: 12),
          TextField(controller: codeController, keyboardType: TextInputType.number, maxLength: 4, decoration: const InputDecoration(labelText: '4-digit transfer code', border: OutlineInputBorder(), counterText: '')),
          const SizedBox(height: 10),
          SizedBox(width: double.infinity, child: FilledButton(onPressed: () async {
            final code = codeController.text.trim();
            final base = Uri.tryParse(addressController.text.trim());
            if (!RegExp(r'^\d{4}$').hasMatch(code)) {
              ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Enter a valid 4-digit code.'))); return;
            }
            if (base == null || base.host.isEmpty || !['http', 'https'].contains(base.scheme)) {
              ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Scan nearby devices or enter a valid sender address.'))); return;
            }
            Navigator.of(sheetContext).pop();
            await _receiveFromSender(base, code, context);
          }, child: const Text('Connect and receive'))),
          Align(alignment: Alignment.center, child: TextButton.icon(onPressed: () { Navigator.of(sheetContext).pop(); _scanQr(context); }, icon: const Icon(Icons.qr_code_scanner_rounded), label: const Text('Use QR code instead'))),
        ])),
      )),
    );
    codeController.dispose(); addressController.dispose();
  }

  Future<void> _receiveFromSender(Uri base, String code, BuildContext context) async {
    try {
      final client = HttpClient();
      final verifyRequest = await client.getUrl(base.replace(path: '/verify', queryParameters: {'code': code}));
      final verifyResponse = await verifyRequest.close();
      final body = await utf8.decoder.bind(verifyResponse).join();
      if (verifyResponse.statusCode != HttpStatus.ok) throw Exception('The code was not accepted. Check it and try again.');
      final decoded = jsonDecode(body);
      if (decoded is! Map || decoded['files'] is! List) throw Exception('Sender returned an invalid file list.');
      final directory = await getApplicationDocumentsDirectory();
      var count = 0;
      final files = decoded['files'] as List;
      for (var i = 0; i < files.length; i++) {
        final item = files[i]; if (item is! Map) continue;
        final name = (item['name']?.toString() ?? 'received_file').replaceAll(RegExp(r'[\\/:*?"<>|]'), '_').replaceAll('..', '_');
        final request = await client.getUrl(base.replace(path: '/download', queryParameters: {'index': '$i', 'code': code}));
        final response = await request.close(); if (response.statusCode != HttpStatus.ok) continue;
        final target = File('${directory.path}/$name'); final sink = target.openWrite();
        await response.pipe(sink); _receivedFiles.add(target.path); count++;
      }
      client.close(force: true);
      if (context.mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Received $count file(s). Saved inside AirBridge storage.')));
    } catch (error) {
      if (context.mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Could not receive files: $error')));
    }
  }

  Future<void> _scanQr(BuildContext context) async {
    final scanned = await Navigator.of(context).push<String>(
      MaterialPageRoute<String>(builder: (_) => const _QrScannerPage()),
    );
    if (!context.mounted || scanned == null) return;
    final uri = Uri.tryParse(scanned.trim());
    if (uri == null || (uri.scheme != 'http' && uri.scheme != 'https') || uri.host.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('That QR code is not a valid AirBridge sharing address.')),
      );
      return;
    }
    final shouldOpen = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: cardColor,
        title: const Text('Open sharing address?'),
        content: SelectableText(uri.toString(), style: const TextStyle(color: teal)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(dialogContext, false), child: const Text('Cancel')),
          FilledButton(onPressed: () => Navigator.pop(dialogContext, true), child: const Text('Open')),
        ],
      ),
    );
    if (!context.mounted || shouldOpen != true) return;
    try {
      final opened = await launchUrl(uri, mode: LaunchMode.externalApplication);
      if (!opened && context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Could not open that address.')));
      }
    } catch (error) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Could not open address: $error')));
      }
    }
  }

  static String _formatSize(int bytes) => bytes < 1024
      ? '$bytes B'
      : bytes < 1024 * 1024
          ? '${(bytes / 1024).toStringAsFixed(1)} KB'
          : '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';

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
          scrollable: true,
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
                if (_receiveUrl != null) ...[
                  const SizedBox(height: 16),
                  Center(child: _qrCode(_receiveUrl!)),
                  const SizedBox(height: 8),
                  const Center(child: Text('Scan this code on the sending device', style: TextStyle(color: Colors.white60, fontSize: 12))),
                ],
                const SizedBox(height: 10),
                const Text(
                  'Scan the code with AirBridge or open the address in a browser on the same Wi-Fi. Keep AirBridge open while receiving. Only use this on a trusted Wi-Fi network.',
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

}


class _QrScannerPage extends StatefulWidget {
  const _QrScannerPage();

  @override
  State<_QrScannerPage> createState() => _QrScannerPageState();
}

class _QrScannerPageState extends State<_QrScannerPage> {
  bool _handled = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Scan AirBridge QR'), backgroundColor: const Color(0xFFF3F9FF)),
      body: Stack(
        children: [
          MobileScanner(
            onDetect: (capture) {
              if (_handled) return;
              for (final barcode in capture.barcodes) {
                final value = barcode.rawValue;
                if (value != null && value.trim().isNotEmpty) {
                  _handled = true;
                  Navigator.of(context).pop(value.trim());
                  return;
                }
              }
            },
          ),
          Center(
            child: Container(
              width: 260,
              height: 260,
              decoration: BoxDecoration(
                border: Border.all(color: const Color(0xFF249DE8), width: 3),
                borderRadius: BorderRadius.circular(22),
              ),
            ),
          ),
          const Positioned(
            left: 24,
            right: 24,
            bottom: 44,
            child: Text(
              'Point your camera at the QR code shown on the other device.',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.white, fontSize: 14, shadows: [Shadow(color: Colors.black, blurRadius: 8)]),
            ),
          ),
        ],
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
      color: Colors.white,
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