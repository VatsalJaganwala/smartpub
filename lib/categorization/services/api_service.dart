/// API service for package categories from SmartPub Worker
library;

import 'dart:convert';
import 'package:http/http.dart' as http;

import '../models/package_category.dart';

/// Service for fetching package data from SmartPub Worker API
class ApiService {
  /// Creates an API service
  const ApiService({
    this.baseUrl = 'https://smartpub-worker.smartpub.workers.dev',
  });

  /// Base URL for the API
  final String baseUrl;

  /// Fetch categories for multiple packages
  Future<List<PackageCategory>> fetchPackages(
    List<String> packageNames,
  ) async {
    if (packageNames.isEmpty) return <PackageCategory>[];

    try {
      final String packagesParam = packageNames.join(',');
      final String url = '$baseUrl/category?packages=$packagesParam';

      final http.Response response = await http.get(Uri.parse(url));

      if (response.statusCode != 200) return <PackageCategory>[];

      final Map<String, dynamic> json = Map<String, dynamic>.from(
        jsonDecode(response.body) ?? <String, dynamic>{}
      );
      
      final List<dynamic> packages = List<dynamic>.from(json['packages'] ?? <dynamic>[]);

      return packages
          .where((dynamic p) => p is Map)
          .map((dynamic p) => PackageCategory.fromJson(
                Map<String, dynamic>.from(p as Map? ?? <String, dynamic>{})))
          .toList();
    } catch (e) {
      return <PackageCategory>[];
    }
  }

  /// Fetch category for a single package
  Future<PackageCategory?> fetchPackage(String packageName) async {
    final List<PackageCategory> results = await fetchPackages(<String>[packageName]);
    return results.isEmpty ? null : results.first;
  }
}
