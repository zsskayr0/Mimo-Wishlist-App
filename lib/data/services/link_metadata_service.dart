import 'dart:convert';

import 'package:html/dom.dart' as dom;
import 'package:html/parser.dart' as html_parser;
import 'package:http/http.dart' as http;

class LinkMetadata {
  const LinkMetadata({this.title, this.price, this.imageUrl});

  final String? title;
  final double? price;
  final String? imageUrl;

  bool get isEmpty => title == null && price == null && imageUrl == null;
}

/// Best-effort product metadata from a pasted link: Open Graph / product
/// meta tags first, JSON-LD `Product` structured data as a fallback for
/// whatever those didn't have. No backend involved — the app fetches the
/// page itself, which a native client can do without the CORS restriction
/// a browser would hit. Real store pages vary wildly, so every step here
/// degrades to "leave it blank" rather than throwing: a failed fetch is a
/// worse experience than making the user type three fields themselves,
/// never one that blocks the capture entirely.
class LinkMetadataService {
  static const _timeout = Duration(seconds: 8);
  static const _userAgent =
      'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 '
      '(KHTML, like Gecko) Chrome/124.0 Safari/537.36';

  Future<LinkMetadata> fetch(String url) async {
    final uri = Uri.tryParse(url.trim());
    if (uri == null || !uri.hasScheme) return const LinkMetadata();

    try {
      final response = await http
          .get(uri, headers: const {'User-Agent': _userAgent})
          .timeout(_timeout);
      if (response.statusCode != 200) return const LinkMetadata();

      final doc = html_parser.parse(response.body);

      String? title = _meta(doc, const ['og:title']) ?? _titleTag(doc);
      String? imageUrl = _meta(doc, const ['og:image', 'og:image:secure_url']);
      double? price = _parsePrice(_meta(doc, const ['product:price:amount', 'og:price:amount']));

      if (title == null || imageUrl == null || price == null) {
        final fromLd = _fromJsonLd(doc);
        title ??= fromLd.title;
        imageUrl ??= fromLd.imageUrl;
        price ??= fromLd.price;
      }

      return LinkMetadata(title: _cleanTitle(title), price: price, imageUrl: imageUrl);
    } catch (_) {
      return const LinkMetadata();
    }
  }

  String? _meta(dom.Document doc, List<String> properties) {
    for (final property in properties) {
      final element = doc.querySelector('meta[property="$property"]') ??
          doc.querySelector('meta[name="$property"]');
      final content = element?.attributes['content']?.trim();
      if (content != null && content.isNotEmpty) return content;
    }
    return null;
  }

  String? _titleTag(dom.Document doc) {
    final text = doc.querySelector('title')?.text.trim();
    return (text == null || text.isEmpty) ? null : text;
  }

  String? _cleanTitle(String? title) {
    if (title == null) return null;
    // Page titles are often "Product Name | Store" — keep just the product
    // side when the split leaves something substantial.
    for (final sep in [' | ', ' – ', ' — ', ' - ']) {
      if (title.contains(sep)) {
        final first = title.split(sep).first.trim();
        if (first.length >= 4) return first;
      }
    }
    return title;
  }

  double? _parsePrice(String? raw) {
    if (raw == null) return null;
    final cleaned = raw.replaceAll(RegExp(r'[^0-9.]'), '');
    if (cleaned.isEmpty) return null;
    return double.tryParse(cleaned);
  }

  LinkMetadata _fromJsonLd(dom.Document doc) {
    for (final script in doc.querySelectorAll('script[type="application/ld+json"]')) {
      try {
        final decoded = jsonDecode(script.text);
        final product = _findProduct(decoded);
        if (product == null) continue;

        final name = product['name'] as String?;

        final image = product['image'];
        final imageUrl = image is List
            ? (image.isNotEmpty ? image.first as String? : null)
            : image as String?;

        String? priceRaw;
        final offers = product['offers'];
        final offer = offers is List ? (offers.isNotEmpty ? offers.first : null) : offers;
        if (offer is Map) priceRaw = offer['price']?.toString();

        if (name != null || imageUrl != null || priceRaw != null) {
          return LinkMetadata(title: name, price: _parsePrice(priceRaw), imageUrl: imageUrl);
        }
      } catch (_) {
        // Malformed JSON-LD on the page — skip it, try the next block.
      }
    }
    return const LinkMetadata();
  }

  Map<String, dynamic>? _findProduct(dynamic node) {
    if (node is Map<String, dynamic>) {
      final type = node['@type'];
      final isProduct = type == 'Product' || (type is List && type.contains('Product'));
      if (isProduct) return node;
      if (node['@graph'] is List) {
        for (final entry in node['@graph'] as List) {
          final found = _findProduct(entry);
          if (found != null) return found;
        }
      }
    } else if (node is List) {
      for (final entry in node) {
        final found = _findProduct(entry);
        if (found != null) return found;
      }
    }
    return null;
  }
}
