import 'package:flutter_test/flutter_test.dart';
import 'package:muststudy/routes/app_router.dart';

void main() {
  group('RouteGuard.canActivate', () {
    test('public route (login) is always accessible', () {
      RouteGuard.setLoggedIn(false);
      expect(RouteGuard.canActivate(RouteNames.login), isTrue);
    });

    test('protected route is blocked when not logged in', () {
      RouteGuard.setLoggedIn(false);
      expect(RouteGuard.canActivate(RouteNames.home), isFalse);
      expect(RouteGuard.canActivate(RouteNames.resources), isFalse);
    });

    test('protected route is allowed after login', () {
      RouteGuard.setLoggedIn(true);
      expect(RouteGuard.canActivate(RouteNames.home), isTrue);
      expect(RouteGuard.canActivate(RouteNames.forum), isTrue);
    });

    test('logout resets access control', () {
      RouteGuard.setLoggedIn(true);
      expect(RouteGuard.canActivate(RouteNames.home), isTrue);
      RouteGuard.setLoggedIn(false);
      expect(RouteGuard.canActivate(RouteNames.home), isFalse);
    });
  });
}
