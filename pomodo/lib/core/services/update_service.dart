import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:url_launcher/url_launcher.dart';

class AppUpdateInfo {
  final String tagName;
  final String version;
  final String title;
  final String changelog;
  final String releaseUrl;
  final String? apkDownloadUrl;
  final bool hasNewVersion;

  AppUpdateInfo({
    required this.tagName,
    required this.version,
    required this.title,
    required this.changelog,
    required this.releaseUrl,
    this.apkDownloadUrl,
    required this.hasNewVersion,
  });
}

class UpdateService {
  static const String currentVersion = '1.0.4';
  static const String githubRepo = 'chonggao9/pomodo';
  static const String latestReleaseApi = 'https://api.github.com/repos/$githubRepo/releases/latest';

  /// 检查 GitHub Releases 最新版本
  static Future<AppUpdateInfo?> checkUpdate() async {
    HttpClient? client;
    try {
      client = HttpClient();
      client.connectionTimeout = const Duration(seconds: 6);

      final uri = Uri.parse(latestReleaseApi);
      final request = await client.getUrl(uri);
      request.headers.set('User-Agent', 'PomoDo-Android-App');
      request.headers.set('Accept', 'application/vnd.github.v3+json');

      final response = await request.close();
      if (response.statusCode == 200) {
        final bodyStr = await response.transform(utf8.decoder).join();
        final Map<String, dynamic> data = jsonDecode(bodyStr);

        final String tagName = (data['tag_name'] as String?) ?? 'v1.0.0';
        final String remoteVer = tagName.replaceAll(RegExp(r'^[vV]'), '');
        final String title = (data['name'] as String?) ?? '最新发布版';
        final String changelog = (data['body'] as String?) ?? '优化性能与交互细节。';
        final String releaseUrl = (data['html_url'] as String?) ?? 'https://github.com/$githubRepo/releases';

        // 提取 .apk 下载直链
        String? apkDownloadUrl;
        if (data['assets'] is List) {
          final assets = data['assets'] as List;
          for (final item in assets) {
            final name = (item['name'] as String? ?? '').toLowerCase();
            if (name.endsWith('.apk')) {
              apkDownloadUrl = item['browser_download_url'] as String?;
              break;
            }
          }
        }

        final bool hasNew = _isVersionHigher(remoteVer, currentVersion);

        return AppUpdateInfo(
          tagName: tagName,
          version: remoteVer,
          title: title,
          changelog: changelog,
          releaseUrl: releaseUrl,
          apkDownloadUrl: apkDownloadUrl,
          hasNewVersion: hasNew,
        );
      }
    } catch (e) {
      debugPrint('Check update error: $e');
    } finally {
      client?.close();
    }
    return null;
  }

  /// 打开浏览器跳转下载或 Release 页面
  static Future<bool> openUrl(String urlStr) async {
    try {
      final uri = Uri.parse(urlStr);
      if (await canLaunchUrl(uri)) {
        return await launchUrl(uri, mode: LaunchMode.externalApplication);
      }
    } catch (e) {
      debugPrint('Error launching url: $e');
    }
    return false;
  }

  /// 简易语义化版本比对
  static bool _isVersionHigher(String remote, String local) {
    final rParts = remote.split('.').map((e) => int.tryParse(e) ?? 0).toList();
    final lParts = local.split('.').map((e) => int.tryParse(e) ?? 0).toList();

    for (int i = 0; i < 3; i++) {
      final r = i < rParts.length ? rParts[i] : 0;
      final l = i < lParts.length ? lParts[i] : 0;
      if (r > l) return true;
      if (r < l) return false;
    }
    return false;
  }
}
