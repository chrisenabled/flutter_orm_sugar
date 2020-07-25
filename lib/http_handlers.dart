import 'dart:io';

typedef void OrmRequestCallback();

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
        default:
          contentType = ContentType('text', 'plain');
      }
      response.headers.contentType = contentType;
      await response.addStream(file.openRead());
      closeResponse();
    }
  }

  Future<void> send(String message, [int code]) async {
    if (code != null) response.statusCode = code;
    response.writeln(message);
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

  void GET(dynamic path, OrmRequestCallback ck) {
    addToPool(path);
    if (request.method != 'GET' || noMatch(path)) return;
    ck();
  }

  void POST(String path, OrmRequestCallback ck) {
    addToPool(path);
    if (request.method != 'POST' || noMatch(path)) return;
    ck();
  }

  void notFound(String path, OrmRequestCallback ck) {
    if (!inPool(path)) ck();
  }

  void serveAssets(OrmRequestCallback ck) {
    final ext = request.uri.path.split('.').last;
    if (['js', 'css', 'vue', 'woff', 'ttf','svg'].contains(ext)) {
      final file = File('../lib/web' + path);
      // if (ext == 'vue') print(request.headers.toString());
      if (file.existsSync()) addToPool(path);
      ck();
    }
  }
}
