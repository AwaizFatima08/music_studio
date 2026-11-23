import 'package:flutter_test/flutter_test.dart';
import 'package:tiny_tunes/features/grownups/more_apps.dart';

void main() {
  test('Play links are tagged with this app as the source', () {
    expect(
      playLink('com.homilabs.rainbowkeys'),
      'https://play.google.com/store/apps/details?id=com.homilabs.rainbowkeys'
      '&referrer=utm_source%3Dtinytunes%26utm_medium%3Dapp%26utm_campaign%3Dcrosspromo',
    );
    expect(moreApps.map((a) => a.package), isNot(contains(ownPackage)));
  });
}
