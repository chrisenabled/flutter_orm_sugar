import 'dart:io';

import 'package:flutter_orm_sugar/http_handlers.dart';

void addCorsHeaders(HttpResponse response) {
  response.headers.add('Access-Control-Allow-Origin', '*');
  response.headers
      .add('Access-Control-Allow-Methods', 'POST, OPTIONS,GET');
  response.headers.add('Access-Control-Allow-Headers',
      'Origin, X-Requested-With, Content-Type, Accept');
}

Future<void> handleRequest(ReqHandler req, ResHandler res) async {
  print('handling request to: ${req.path}');
  req.serveAssets(() async {
    await res.sendAsset(req.path);
  });

  req.GET(['/', '/main.html'], () async {
    await res.sendHtml('main.html');
  });

  req.notFound(req.request.uri.path, () async {
    await res.send('Oopss!! the path requested does not exist on our server',
        HttpStatus.notFound);
  });

  // export PATH="$PATH":"$HOME/.pub-cache/bin"
}
