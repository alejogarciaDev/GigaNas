class NasSystemStatus {
  final String hostname;
  final String version;
  final String baseOs;
  final String kernel;
  final String uptime;
  final double cpuPercent;
  final int cpuCores;
  final double ramTotalGb;
  final double ramUsedGb;
  final double ramPercent;
  final double arcAllocatedGb;
  final String arcEfficiency;
  final double temperature;
  final String mode;

  NasSystemStatus({
    required this.hostname,
    required this.version,
    required this.baseOs,
    required this.kernel,
    required this.uptime,
    required this.cpuPercent,
    required this.cpuCores,
    required this.ramTotalGb,
    required this.ramUsedGb,
    required this.ramPercent,
    required this.arcAllocatedGb,
    required this.arcEfficiency,
    required this.temperature,
    required this.mode,
  });

  factory NasSystemStatus.fromJson(Map<String, dynamic> json) {
    final cpu = json['cpu'] as Map<String, dynamic>? ?? {};
    final mem = json['memory'] as Map<String, dynamic>? ?? {};

    return NasSystemStatus(
      hostname: json['hostname'] ?? 'gigarnas',
      version: json['version'] ?? '1.0.0-PRO',
      baseOs: json['base_os'] ?? 'GigaNas Core OS',
      kernel: json['kernel'] ?? 'Linux 6.12 GigaNas',
      uptime: json['uptime'] ?? '--',
      cpuPercent: (cpu['percent'] as num?)?.toDouble() ?? 0.0,
      cpuCores: cpu['cores_logical'] ?? 4,
      ramTotalGb: (mem['total_gb'] as num?)?.toDouble() ?? 8.0,
      ramUsedGb: (mem['used_gb'] as num?)?.toDouble() ?? 2.0,
      ramPercent: (mem['percent'] as num?)?.toDouble() ?? 25.0,
      arcAllocatedGb: (mem['zfs_arc_allocated_gb'] as num?)?.toDouble() ?? 2.5,
      arcEfficiency: mem['zfs_arc_efficiency'] ?? '98.4%',
      temperature: (json['temperature'] as num?)?.toDouble() ?? 36.0,
      mode: json['mode'] ?? 'Optimizado',
    );
  }
}
