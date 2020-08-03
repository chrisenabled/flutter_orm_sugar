import 'dart:convert';
import 'dart:io';

typedef void GetCallback(params);
typedef void PostCallback(body);

class ResHandler {
  final HttpResponse response;

  ResHandler(this.response);

  Future<void> sendHtml(String path) async {
    final file = File('../lib/web/' + path);
    if (await file.exists()) {
      response.headers.contentType = ContentType.html;
      await file.openRead().pipe(response);
      closeResponse();
    }
  }

  closeResponse() async {
    await response.close();
  }

  Future<void> sendAsset(String path) async {
    final file = File('../lib/web' + path);
    if (file.existsSync()) {
      ContentType contentType;
      final ext = path.split('.').last;
      switch (ext) {
        case 'js':
          contentType = ContentType('text', 'javascript');
          break;
        case 'css':
          contentType = ContentType('text', 'css');
          break;
        case 'ttf':
          contentType = ContentType('font', 'ttf');
          break;
        case 'svg':
          contentType = ContentType('image', 'svg+xml');
          break;
        case 'jpg':
          contentType = ContentType('image', 'jpg');
          break;
        default:
          contentType = ContentType('text', 'plain');
      }
      if (path.contains('favicon')) {
        contentType = ContentType('image', 'x-icon');
      }
      response.headers.contentType = contentType;
      await response.addStream(file.openRead());
      closeResponse();
    }
  }

  Future<void> send(String message, [int code]) async {
    if (code != null) response.statusCode = code;
    response.write(message);
    closeResponse();
  }
}

class ReqHandler {
  final HttpRequest request;
  final knownPathsPool = [];
  final String path;

  ReqHandler(this.request) : path = request.uri.path;

  bool noMatch(dynamic path) {
    if (path.runtimeType == String) return path != request.uri.path;
    if (path.runtimeType.toString() == 'List<String>') {
      final p = path as List;
      return !p.contains(request.uri.path);
    }
    return true;
  }

  addToPool(path) {
    if (path.runtimeType.toString() == 'List<String>') {
      knownPathsPool.addAll(path);
    } else
      knownPathsPool.add(path);
  }

  inPool(path) {
    if (path.runtimeType == 'List<String>') {
      final p = path as List<String>;
      bool inPool = false;
      p.forEach((path) {
        if (knownPathsPool.contains(path)) inPool = true;
      });
      return inPool;
    } else
      return knownPathsPool.contains(path);
  }

  void GET(dynamic path, GetCallback ck) {
    addToPool(path);
    if (request.method != 'GET' || noMatch(path)) return;
    ck(request.uri.queryParameters);
  }

  Future<void> POST(String path, PostCallback ck) async {
    addToPool(path);
    ContentType contentType = request.headers.contentType;
    if (request.method != 'POST' ||
        contentType?.mimeType != 'application/json' ||
        noMatch(path)) return;
    String content = await utf8.decoder.bind(request).join();
    var data = jsonDecode(content) as Map;
    ck(data);
  }

  void notFound(String path, Function ck) {
    if (!inPool(path)) ck();
  }

  void serveAssets(Function ck) {
    final ext = request.uri.path.split('.').last;
    if (['js', 'css', 'vue', 'woff', 'ttf', 'svg', 'jpg', 'png']
        .contains(ext)) {
      final file = File('../lib/web' + path);
      if (file.existsSync()) addToPool(path);
      ck();
    }
  }
}
