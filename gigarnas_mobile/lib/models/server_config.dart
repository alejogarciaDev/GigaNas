class ServerConfig {
  final String host;
  final int port;
  final String protocol; // 'http' or 'https'
  final String name;

  ServerConfig({
    required this.host,
    this.port = 8080,
    this.protocol = 'http',
    this.name = 'Servidor GigaNas',
  });

  String get baseUrl {
    final cleanHost = host.trim().replaceFirst(RegExp(r'^https?://'), '').replaceAll('/', '');
    return '$protocol://$cleanHost:$port';
  }

  Map<String, dynamic> toJson() => {
    'host': host,
    'port': port,
    'protocol': protocol,
    'name': name,
  };

  factory ServerConfig.fromJson(Map<String, dynamic> json) {
    return ServerConfig(
      host: json['host'] ?? '127.0.0.1',
      port: json['port'] is int ? json['port'] : int.tryParse(json['port']?.toString() ?? '8080') ?? 8080,
      protocol: json['protocol'] ?? 'http',
      name: json['name'] ?? 'Servidor GigaNas',
    );
  }

  ServerConfig copyWith({
    String? host,
    int? port,
    String? protocol,
    String? name,
  }) {
    return ServerConfig(
      host: host ?? this.host,
      port: port ?? this.port,
      protocol: protocol ?? this.protocol,
      name: name ?? this.name,
    );
  }
}
