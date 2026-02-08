# SmartPub Worker API Documentation

Base URL: `https://smartpub-worker.smartpub.workers.dev`

## Overview

The SmartPub Worker API provides package categorization for Flutter/Dart packages using a multi-tier retrieval system:

1. **KV Cache** - Fast in-memory cache (30-day TTL)
2. **Firestore** - Persistent database storage
3. **Flutter Gems** - Web scraping fallback
4. **Heuristic** - Name-based classification fallback

## Endpoints

### GET /category

Retrieve categories for one or more packages.

#### Request

**URL:** `GET /category?packages={package1,package2,...}`

**Query Parameters:**
- `packages` (required): Comma-separated list of package names

**Example:**
```
GET https://smartpub-worker.smartpub.workers.dev/category?packages=provider
GET https://smartpub-worker.smartpub.workers.dev/category?packages=provider,riverpod,bloc
```

#### Response

**Status:** `200 OK`

**Body:**
```json
{
  "packages": [
    {
      "name": "provider",
      "categories": ["Dependency Injection & State Management"],
      "primaryCategory": "Dependency Injection & State Management",
      "source": "fluttergems",
      "confidence": 0.8,
      "fetchedAt": "2026-02-08T13:30:00.000Z"
    }
  ]
}
```

**Response Fields:**

| Field | Type | Description |
|-------|------|-------------|
| `name` | string | Package name |
| `categories` | string[] | All categories for the package |
| `primaryCategory` | string | Main category used for grouping |
| `source` | string | Data source: `cache`, `firestore`, `fluttergems`, or `heuristic` |
| `confidence` | number | Confidence score (0.0-1.0): cache/firestore=0.9, fluttergems=0.8, heuristic=0.5 |
| `fetchedAt` | string | ISO 8601 timestamp when data was retrieved |

#### Source Priority

The API follows this retrieval order:

1. **cache** (0.9 confidence) - Returns immediately if cached and valid (< 30 days)
2. **firestore** (0.9 confidence) - Queries Firestore database, then caches result
3. **fluttergems** (0.8 confidence) - Scrapes Flutter Gems website, saves to Firestore and cache
4. **heuristic** (0.5 confidence) - Name-based classification, saves to cache only

### GET /health

Health check endpoint.

#### Request

**URL:** `GET /health`

**Example:**
```
GET https://smartpub-worker.smartpub.workers.dev/health
```

#### Response

**Status:** `200 OK`

**Body:**
```json
{
  "service": "smartpub-worker",
  "version": "1.0",
  "endpoint": "GET /category?packages=provider,riverpod,bloc"
}
```

## Examples

### Single Package

**Request:**
```bash
curl "https://smartpub-worker.smartpub.workers.dev/category?packages=dio"
```

**Response:**
```json
{
  "packages": [
    {
      "name": "dio",
      "categories": ["Networking"],
      "primaryCategory": "Networking",
      "source": "fluttergems",
      "confidence": 0.8,
      "fetchedAt": "2026-02-08T13:30:00.000Z"
    }
  ]
}
```

### Multiple Packages

**Request:**
```bash
curl "https://smartpub-worker.smartpub.workers.dev/category?packages=provider,riverpod,bloc,get"
```

**Response:**
```json
{
  "packages": [
    {
      "name": "provider",
      "categories": ["Dependency Injection & State Management"],
      "primaryCategory": "Dependency Injection & State Management",
      "source": "cache",
      "confidence": 0.9,
      "fetchedAt": "2026-02-08T13:25:00.000Z"
    },
    {
      "name": "riverpod",
      "categories": ["State Management"],
      "primaryCategory": "State Management",
      "source": "firestore",
      "confidence": 0.9,
      "fetchedAt": "2026-02-08T13:30:00.000Z"
    },
    {
      "name": "bloc",
      "categories": ["State Management"],
      "primaryCategory": "State Management",
      "source": "fluttergems",
      "confidence": 0.8,
      "fetchedAt": "2026-02-08T13:30:15.000Z"
    },
    {
      "name": "get",
      "categories": ["State Management"],
      "primaryCategory": "State Management",
      "source": "heuristic",
      "confidence": 0.5,
      "fetchedAt": "2026-02-08T13:30:20.000Z"
    }
  ]
}
```

### Heuristic Fallback Example

When a package is not found in any source, the API uses name-based heuristics:

**Request:**
```bash
curl "https://smartpub-worker.smartpub.workers.dev/category?packages=my_custom_http_client"
```

**Response:**
```json
{
  "packages": [
    {
      "name": "my_custom_http_client",
      "categories": ["Networking"],
      "primaryCategory": "Networking",
      "source": "heuristic",
      "confidence": 0.5,
      "fetchedAt": "2026-02-08T13:30:00.000Z"
    }
  ]
}
```

## Error Responses

### Missing Query Parameter

**Request:**
```bash
curl "https://smartpub-worker.smartpub.workers.dev/category"
```

**Response:**
```json
{
  "error": "Missing packages query parameter"
}
```
**Status:** `400 Bad Request`

### Invalid Package Names

**Request:**
```bash
curl "https://smartpub-worker.smartpub.workers.dev/category?packages="
```

**Response:**
```json
{
  "error": "No valid package names provided"
}
```
**Status:** `400 Bad Request`

### Not Found

**Request:**
```bash
curl "https://smartpub-worker.smartpub.workers.dev/invalid"
```

**Response:**
```json
{
  "error": "Not Found"
}
```
**Status:** `404 Not Found`

## CORS

All endpoints support CORS with the following headers:
- `Access-Control-Allow-Origin: *`
- `Access-Control-Allow-Methods: GET, OPTIONS`
- `Access-Control-Allow-Headers: Content-Type`

## Rate Limiting

No rate limiting is currently enforced, but please use the API responsibly.

## Caching

- **KV Cache TTL:** 30 days
- **Cache Key Format:** `category:{packageName}`
- Cached responses include `source: "cache"` in the response

## Category Priority Order

When multiple categories are available, the primary category is selected based on this priority:

1. State Management
2. Networking
3. HTTP Clients
4. Database
5. Storage
6. UI Components
7. Widgets
8. Navigation
9. Authentication
10. Testing
11. Development Tools
12. Utilities

If no priority match is found, the first category in the list is used.
