class UserQuota {
  final String username;
  final int quotaGb;
  final bool isUnlimited;
  final int usedBytes;
  final String usedHuman;
  final int maxBytes;
  final String maxHuman;
  final int freeBytes;
  final String freeHuman;
  final double percentUsed;
  final int fileCount;
  final int photoCount;
  final String partitionName;

  UserQuota({
    required this.username,
    required this.quotaGb,
    required this.isUnlimited,
    required this.usedBytes,
    required this.usedHuman,
    required this.maxBytes,
    required this.maxHuman,
    required this.freeBytes,
    required this.freeHuman,
    required this.percentUsed,
    required this.fileCount,
    required this.photoCount,
    required this.partitionName,
  });

  factory UserQuota.fromJson(Map<String, dynamic> json) {
    return UserQuota(
      username: json['username'] ?? '',
      quotaGb: json['quota_gb'] ?? 0,
      isUnlimited: json['is_unlimited'] ?? (json['quota_gb'] == 0),
      usedBytes: json['used_bytes'] ?? 0,
      usedHuman: json['used_human'] ?? '0 B',
      maxBytes: json['max_bytes'] ?? 0,
      maxHuman: json['max_human'] ?? '0 GB',
      freeBytes: json['free_bytes'] ?? 0,
      freeHuman: json['free_human'] ?? '0 GB',
      percentUsed: (json['percent_used'] as num?)?.toDouble() ?? 0.0,
      fileCount: json['file_count'] ?? 0,
      photoCount: json['photo_count'] ?? 0,
      partitionName: json['partition_name'] ?? 'Partición Personal',
    );
  }

  bool get hasPartition => isUnlimited || quotaGb > 0;
  bool get isNearLimit => !isUnlimited && percentUsed >= 90.0;
}
