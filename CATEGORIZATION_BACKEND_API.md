# Backend API: Package Categorization

This document describes the **process** that the SmartPub CLI currently performs for package categorization, and the **contract** a backend API must fulfill so the CLI can call the API instead of doing the fetching logic locally.

---

## 1. Process the backend must implement

The backend is responsible for **resolving a Flutter/Dart package name to category information** using a strict **meta-retrieval order**. Only move to the next step when the current step returns **no data**.

### Fetch order (mandatory)

1. **Local/cache** – Check your own cache (e.g. DB or in-memory) for the package. If found and still valid (e.g. within TTL), return it and stop.
2. **Firebase (Firestore)** – If not in cache, fetch from Firestore (or your mirror of it). If found, return it, **persist to your cache**, and stop.
3. **Flutter Gems** – If still not found, fetch from [Flutter Gems](https://fluttergems.dev) (e.g. scrape or use their data). If found:
   - Return the category data.
   - **Persist to your cache.**
   - **Persist to Firebase/Firestore** so future requests (and other clients) can use it.
4. **Heuristic fallback** – If no data from any source, derive a category from the package name using heuristics (e.g. name contains `bloc` → "State Management", `http`/`dio` → "Networking"). Return that result and **persist to your cache only** (do not write heuristics to Firestore).

So: **local/cache → Firebase → Flutter Gems → heuristic**; each step only runs if the previous step did not return data. New data from Flutter Gems must be written to both your cache and Firebase.

---

## 2. What the CLI will pass (required request)

The CLI will call the backend with:

| Input | Type | Required | Description |
|-------|------|----------|-------------|
| **Package name** | `string` | Yes | The pub package name (e.g. `flutter_bloc`, `http`, `cached_network_image`). |
| **Operation** | — | — | Either "classify" (need primary category only) or "get categories" (need full list). The same response body can serve both; see below. |

Suggested API shape:

- **Single package**
  - **Request:** `GET /packages/{packageName}/category` or `POST /category` with body `{ "packageName": "flutter_bloc" }`.
  - **Request (batch):** Optional: `POST /category/batch` with body `{ "packageNames": ["http", "flutter_bloc"] }` to reduce round-trips when grouping many packages.

- **Query parameters (optional)**  
  - `fetchGemsFallback` (boolean): if the backend should try Flutter Gems when not in cache/Firebase. Default true.  
  - Any other backend-specific options (e.g. cache TTL, project id) can be added as needed.

---

## 3. Response the backend must return

The CLI expects a **single package category object** per package. The backend must return JSON that matches or can be mapped to this shape.

### Response body (single package)

```json
{
  "name": "flutter_bloc",
  "categories": ["State Management", "Architecture"],
  "primaryCategory": "State Management",
  "source": "firestore",
  "confidence": 0.9,
  "fetchedAt": "2025-02-07T14:30:00.000Z"
}
```

| Field | Type | Required | Description |
|-------|------|----------|-------------|
| **name** | string | Yes | Package name (same as requested). |
| **categories** | array of strings | Yes | All categories for this package (e.g. from Flutter Gems or heuristic). At least one. |
| **primaryCategory** | string | Yes | The one category used for grouping (e.g. "State Management"). Must be one of `categories` or a canonical choice. |
| **source** | string | Yes | Origin of the data: `"cache"`, `"firestore"`, `"fluttergems"`, or `"heuristic"`. |
| **confidence** | number | Yes | 0.0–1.0. Suggest: firestore/cache 0.9, fluttergems 0.8, heuristic 0.5. |
| **fetchedAt** | string | Yes | ISO 8601 timestamp (e.g. `2025-02-07T14:30:00.000Z`) when this data was obtained. |

### Response (batch)

For `POST /category/batch` (or equivalent), return an array of the same object:

```json
{
  "packages": [
    {
      "name": "http",
      "categories": ["Networking", "HTTP Clients"],
      "primaryCategory": "Networking",
      "source": "fluttergems",
      "confidence": 0.8,
      "fetchedAt": "2025-02-07T14:30:00.000Z"
    },
    {
      "name": "flutter_bloc",
      "categories": ["State Management"],
      "primaryCategory": "State Management",
      "source": "firestore",
      "confidence": 0.9,
      "fetchedAt": "2025-02-07T14:29:00.000Z"
    }
  ]
}
```

- **Classify:** CLI uses `primaryCategory` for grouping.
- **Get categories:** CLI uses `categories` (and optionally `primaryCategory` for display).

### Error response

- **Package not found / no category:** Prefer returning **200** with a heuristic result (so `categories` and `primaryCategory` are still set) rather than 404. If you do use 404, CLI will fall back to local heuristic.
- **Server/network error:** Return appropriate 4xx/5xx and JSON body, e.g. `{ "error": "message" }`. CLI will treat as failure and can fall back to local heuristic.

---

## 4. Summary

| Aspect | Requirement |
|--------|-------------|
| **Process** | Meta-retrieval: cache → Firestore → Flutter Gems → heuristic; only proceed when current step has no data. |
| **Caching** | Persist to your cache when data is found; when data comes from Flutter Gems, also persist to Firestore. Heuristics: cache only. |
| **Request** | At least: package name(s). Optional: batch list, `fetchGemsFallback` flag. |
| **Response** | JSON: `name`, `categories[]`, `primaryCategory`, `source`, `confidence`, `fetchedAt` (ISO 8601). Same shape for single and per-item in batch. |

This contract allows the CLI to replace its current in-process fetching (local cache → Firestore → Flutter Gems → heuristic) with a single backend call while keeping the same behavior and response format.
