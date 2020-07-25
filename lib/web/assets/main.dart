import 'dart:html';

HeadingElement h1;
HttpRequest request;
String url = 'http://localhost:4080';

void main() {
  h1 = querySelector('#welcome') as HeadingElement;
  h1.animate([
  {"transform": "translate(100px, -100%)"},
  {"transform" : "translate(400px, 500px)"}
], 1500);
}
