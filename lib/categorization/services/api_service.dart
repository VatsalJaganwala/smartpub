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
    if (packageNames.isEmpty) return [];

    try {
      final packagesParam = packageNames.join(',');
      final url = '$baseUrl/category?packages=$packagesParam';

      final response = await http.get(Uri.parse(url));

      if (response.statusCode != 200) return [];

      final json = jsonDecode(response.body) as Map<String, dynamic>;
      final packages = json['packages'] as List<dynamic>?;

      if (packages == null) return [];

      return packages
          .map((p) => PackageCategory.fromJson(p as Map<String, dynamic>))
          .toList();
    } on Exception {
      return [];
    }
  }

  /// Fetch category for a single package
  Future<PackageCategory?> fetchPackage(String packageName) async {
    final results = await fetchPackages([packageName]);
    return results.isEmpty ? null : results.first;
  }
}
