import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/connection_provider.dart';
import '../utils/app_theme.dart';
import 'login_screen.dart';
import 'qr_scanner_screen.dart';

class ConnectionScreen extends StatefulWidget {
  const ConnectionScreen({super.key});

  @override
  State<ConnectionScreen> createState() => _ConnectionScreenState();
}

class _ConnectionScreenState extends State<ConnectionScreen> {
  late TextEditingController _hostCtrl;
  late TextEditingController _portCtrl;
  String _selectedProtocol = 'http';
  bool _isProcessingTunnel = false;

  @override
  void initState() {
    super.initState();
    final config = context.read<ConnectionProvider>().config;
    _hostCtrl = TextEditingController(text: config.host);
    _portCtrl = TextEditingController(text: config.port.toString());
    _selectedProtocol = config.protocol;
  }

  @override
  void dispose() {
    _hostCtrl.dispose();
    _portCtrl.dispose();
    super.dispose();
  }

  void _applyConfig() {
    final port = int.tryParse(_portCtrl.text.trim()) ?? 8080;
    context.read<ConnectionProvider>().updateConfig(
          host: _hostCtrl.text.trim(),
          port: port,
          protocol: _selectedProtocol,
        );
  }

  /// Processes QR codes or pasted tunnel links
  Future<void> _handleTunnelData(String rawData) async {
    final text = rawData.trim();
    if (text.isEmpty) return;

    setState(() => _isProcessingTunnel = true);

    String targetHost = '127.0.0.1';
    int targetPort = 8080;
    String targetProto = 'http';
    String? tunnelName;

    try {
      if (text.startsWith('giganas://')) {
        final uri = Uri.parse(text);
        targetHost = uri.queryParameters['host'] ?? uri.host;
        targetPort = int.tryParse(uri.queryParameters['port'] ?? '8080') ?? 8080;
        targetProto = uri.queryParameters['protocol'] ?? 'http';
        tunnelName = uri.queryParameters['name'];
      } else if (text.startsWith('http://') || text.startsWith('https://')) {
        final uri = Uri.parse(text);
        targetProto = uri.scheme;
        targetHost = uri.host;
        targetPort = uri.port != 0 ? uri.port : (targetProto == 'https' ? 443 : 8080);
      } else if (text.startsWith('{') && text.endsWith('}')) {
        final map = jsonDecode(text);
        targetHost = map['host'] ?? '127.0.0.1';
        targetPort = int.tryParse(map['port']?.toString() ?? '8080') ?? 8080;
        targetProto = map['protocol'] ?? 'http';
        tunnelName = map['name'];
      } else if (text.contains('Endpoint')) {
        // Wireguard config text
        final match = RegExp(r'Endpoint\s*=\s*([^:\s]+):?(\d+)?').firstMatch(text);
        if (match != null) {
          targetHost = match.group(1) ?? targetHost;
          if (match.group(2) != null) {
            targetPort = int.tryParse(match.group(2)!) ?? 8080;
          }
        }
      } else if (text.contains(':')) {
        final parts = text.split(':');
        targetHost = parts[0];
        targetPort = int.tryParse(parts[1]) ?? 8080;
      } else {
        targetHost = text;
      }
    } catch (_) {
      targetHost = text;
    }

    setState(() {
      _hostCtrl.text = targetHost;
      _portCtrl.text = targetPort.toString();
      _selectedProtocol = targetProto;
      _isProcessingTunnel = false;
    });

    _applyConfig();

    // Automatically test connection and proceed
    final conn = context.read<ConnectionProvider>();
    final ok = await conn.testConnection();

    if (ok && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: AppTheme.emeraldGreen.withOpacity(0.9),
          content: Row(
            children: [
              const Icon(Icons.verified_user_rounded, color: Colors.white, size: 20),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  tunnelName != null
                      ? 'Túnel seguro establecido: $tunnelName'
                      : 'Túnel seguro establecido con GigaNas',
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
        ),
      );

      // Transition to Login Screen to ask for user credentials
      Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => const LoginScreen()),
      );
    }
  }

  void _showPasteLinkDialog() {
    final linkCtrl = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          backgroundColor: AppTheme.surface,
          title: Row(
            children: const [
              Icon(Icons.vpn_key_rounded, color: AppTheme.cyberCyan, size: 22),
              SizedBox(width: 8),
              Text('Vincular Túnel Seguro', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Pega el enlace del túnel generado en el panel web de GigaNas:',
                style: TextStyle(fontSize: 12, color: AppTheme.textSecondary),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: linkCtrl,
                autofocus: true,
                style: const TextStyle(fontSize: 12),
                decoration: const InputDecoration(
                  hintText: 'giganas://tunnel?host=192.168.1.50... o http://...',
                  prefixIcon: Icon(Icons.link_rounded, size: 18),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancelar', style: TextStyle(color: AppTheme.textMuted)),
            ),
            ElevatedButton(
              onPressed: () {
                final link = linkCtrl.text.trim();
                Navigator.pop(ctx);
                if (link.isNotEmpty) {
                  _handleTunnelData(link);
                }
              },
              child: const Text('Vincular'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final conn = context.watch<ConnectionProvider>();

    return Scaffold(
      backgroundColor: AppTheme.background,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                // Logo & Header
                Container(
                  width: 72,
                  height: 72,
                  decoration: BoxDecoration(
                    color: AppTheme.surface,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: AppTheme.cyberCyan.withOpacity(0.5), width: 1.5),
                    boxShadow: [
                      BoxShadow(
                        color: AppTheme.primaryBlue.withOpacity(0.2),
                        blurRadius: 20,
                        spreadRadius: 2,
                      ),
                    ],
                  ),
                  child: const Icon(Icons.dns_rounded, color: AppTheme.cyberCyan, size: 36),
                ),
                const SizedBox(height: 20),
                const Text(
                  'GigaNas OS',
                  style: TextStyle(
                    fontSize: 26,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 0.5,
                    color: AppTheme.textPrimary,
                  ),
                ),
                const SizedBox(height: 6),
                const Text(
                  'Vincula tu túnel seguro o ingresa los datos de tu servidor',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 13, color: AppTheme.textMuted),
                ),
                const SizedBox(height: 24),

                // FAST PAIRING HERO CARD: QR Scanner & Tunnel Link
                Card(
                  color: AppTheme.cardSub,
                  child: Padding(
                    padding: const EdgeInsets.all(18),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: const [
                            Icon(Icons.shield_rounded, color: AppTheme.cyberCyan, size: 20),
                            SizedBox(width: 8),
                            Text(
                              'Vinculación Rápida con Túnel Seguro',
                              style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: AppTheme.textPrimary),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        const Text(
                          'Escanea el QR generado en la sección "Túnel Móvil Seguro" de tu NAS para conectar tu teléfono al instante con cifrado WireGuard.',
                          style: TextStyle(fontSize: 11, color: AppTheme.textMuted, height: 1.3),
                        ),
                        const SizedBox(height: 16),
                        Row(
                          children: [
                            // QR Scanner Button
                            Expanded(
                              flex: 3,
                              child: ElevatedButton.icon(
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: AppTheme.cyberCyan,
                                  foregroundColor: Colors.black,
                                  padding: const EdgeInsets.symmetric(vertical: 12),
                                ),
                                onPressed: () async {
                                  final scannedCode = await Navigator.push<String>(
                                    context,
                                    MaterialPageRoute(builder: (_) => const QrScannerScreen()),
                                  );
                                  if (scannedCode != null && scannedCode.isNotEmpty) {
                                    _handleTunnelData(scannedCode);
                                  }
                                },
                                icon: const Icon(Icons.qr_code_scanner_rounded, size: 20),
                                label: const Text(
                                  'Escanear QR',
                                  style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            // Paste Tunnel Link Button
                            Expanded(
                              flex: 2,
                              child: OutlinedButton.icon(
                                style: OutlinedButton.styleFrom(
                                  foregroundColor: AppTheme.cyberCyan,
                                  padding: const EdgeInsets.symmetric(vertical: 12),
                                ),
                                onPressed: _showPasteLinkDialog,
                                icon: const Icon(Icons.link_rounded, size: 18),
                                label: const Text('Pegar Link', style: TextStyle(fontSize: 12)),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                // Manual Configuration Card Form
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: const [
                            Icon(Icons.tune_rounded, color: AppTheme.textSecondary, size: 18),
                            SizedBox(width: 8),
                            Text(
                              'O Configurar Manualmente IP / Puerto',
                              style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: AppTheme.textPrimary),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),

                        // Protocol & Host
                        Row(
                          children: [
                            SizedBox(
                              width: 115,
                              child: DropdownButtonFormField<String>(
                                value: _selectedProtocol,
                                isExpanded: true,
                                decoration: const InputDecoration(
                                  labelText: 'Tipo',
                                  contentPadding: EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                                ),
                                dropdownColor: AppTheme.cardSub,
                                items: const [
                                  DropdownMenuItem(value: 'http', child: Text('http://', style: TextStyle(fontSize: 13))),
                                  DropdownMenuItem(value: 'https', child: Text('https://', style: TextStyle(fontSize: 13))),
                                ],
                                onChanged: (val) {
                                  if (val != null) {
                                    setState(() => _selectedProtocol = val);
                                    _applyConfig();
                                  }
                                },
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: TextField(
                                controller: _hostCtrl,
                                onChanged: (_) => _applyConfig(),
                                decoration: const InputDecoration(
                                  labelText: 'IP o Host del NAS',
                                  hintText: '192.168.1.100',
                                  prefixIcon: Icon(Icons.router_rounded, size: 18),
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 14),

                        // Port
                        TextField(
                          controller: _portCtrl,
                          keyboardType: TextInputType.number,
                          onChanged: (_) => _applyConfig(),
                          decoration: const InputDecoration(
                            labelText: 'Puerto del Servidor',
                            hintText: '8080',
                            prefixIcon: Icon(Icons.settings_ethernet_rounded, size: 18),
                          ),
                        ),
                        const SizedBox(height: 16),

                        // Live URL preview
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                          decoration: BoxDecoration(
                            color: AppTheme.cardSub,
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(color: AppTheme.border.withOpacity(0.5)),
                          ),
                          child: Row(
                            children: [
                              const Icon(Icons.link_rounded, size: 16, color: AppTheme.cyberCyan),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  conn.config.baseUrl,
                                  style: const TextStyle(
                                    fontSize: 12,
                                    fontFamily: 'monospace',
                                    color: AppTheme.cyberCyan,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 16),

                        // Quick Presets Chips
                        const Text(
                          'Preajustes Rápidos:',
                          style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppTheme.textMuted),
                        ),
                        const SizedBox(height: 8),
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: [
                            _buildPresetChip('Localhost (127.0.0.1:8080)', '127.0.0.1', 8080),
                            _buildPresetChip('Red Local (192.168.1.50)', '192.168.1.50', 8080),
                            _buildPresetChip('Tailscale VPN (100.92.14.88)', '100.92.14.88', 8080),
                          ],
                        ),
                        const SizedBox(height: 20),

                        // Test Connection Button
                        SizedBox(
                          width: double.infinity,
                          child: OutlinedButton.icon(
                            onPressed: conn.status == ConnectionStateStatus.testing || _isProcessingTunnel
                                ? null
                                : () async {
                                    _applyConfig();
                                    await conn.testConnection();
                                  },
                            icon: conn.status == ConnectionStateStatus.testing
                                ? const SizedBox(
                                    width: 16,
                                    height: 16,
                                    child: CircularProgressIndicator(strokeWidth: 2, color: AppTheme.cyberCyan),
                                  )
                                : const Icon(Icons.sensors_rounded, size: 18),
                            label: Text(
                              conn.status == ConnectionStateStatus.testing
                                  ? 'Comprobando conexión...'
                                  : 'Probar Conexión con el NAS',
                            ),
                          ),
                        ),

                        // Connection Status Feedback
                        if (conn.status == ConnectionStateStatus.connected) ...[
                          const SizedBox(height: 14),
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: AppTheme.emeraldGreen.withOpacity(0.12),
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(color: AppTheme.emeraldGreen.withOpacity(0.4)),
                            ),
                            child: Row(
                              children: [
                                const Icon(Icons.check_circle_rounded, color: AppTheme.emeraldGreen, size: 20),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        'Conectado a ${conn.serverHostname ?? "GigaNas"}',
                                        style: const TextStyle(
                                          fontSize: 13,
                                          fontWeight: FontWeight.bold,
                                          color: AppTheme.emeraldGreen,
                                        ),
                                      ),
                                      Text(
                                        'Latencia: ${conn.latencyMs}ms • Versión ${conn.serverVersion}',
                                        style: const TextStyle(fontSize: 11, color: AppTheme.textSecondary),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ] else if (conn.status == ConnectionStateStatus.failed) ...[
                          const SizedBox(height: 14),
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: AppTheme.roseDanger.withOpacity(0.12),
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(color: AppTheme.roseDanger.withOpacity(0.4)),
                            ),
                            child: Row(
                              children: [
                                const Icon(Icons.error_outline_rounded, color: AppTheme.roseDanger, size: 20),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: Text(
                                    conn.errorMessage ?? 'Error de conexión',
                                    style: const TextStyle(fontSize: 11, color: AppTheme.roseDanger),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 24),

                // Continue to Login Button
                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: ElevatedButton(
                    onPressed: () {
                      _applyConfig();
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => const LoginScreen()),
                      );
                    },
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: const [
                        Text('Continuar al Inicio de Sesión', style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold)),
                        SizedBox(width: 8),
                        Icon(Icons.arrow_forward_rounded, size: 18),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildPresetChip(String label, String host, int port) {
    return ActionChip(
      label: Text(label, style: const TextStyle(fontSize: 11)),
      backgroundColor: AppTheme.cardSub,
      side: const BorderSide(color: AppTheme.border),
      onPressed: () {
        setState(() {
          _hostCtrl.text = host;
          _portCtrl.text = port.toString();
        });
        _applyConfig();
      },
    );
  }
}
