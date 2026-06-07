class IdFactory {
  IdFactory();

  int _next = 0;

  String next(String prefix) {
    _next += 1;
    return '$prefix-$_next';
  }
}
