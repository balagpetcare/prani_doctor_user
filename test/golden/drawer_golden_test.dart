import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pranidoctor_user/features/profile/data/mobile_me_dto.dart';
import 'package:pranidoctor_user/features/profile/presentation/profile_providers.dart';
import 'package:pranidoctor_user/features/profile/presentation/widgets/profile_hero_avatar.dart';
import 'package:pranidoctor_user/l10n/app_localizations.dart';
import 'package:pranidoctor_user/theme/app_theme.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  const profile = MobileMeDto(
    id: '1',
    name: 'Karim Ahmed',
    phone: '+8801712345678',
    email: 'k@example.com',
    locale: 'bn',
    role: 'customer',
    profilePhotoUrl: null,
    profilePhotoThumbUrl: null,
  );

  Widget buildHarness({required ThemeData theme}) {
    return ProviderScope(
      overrides: [
        mobileMeProvider.overrideWith(
          () => _DrawerGoldenMobileMeNotifier(profile),
        ),
      ],
      child: MaterialApp(
        theme: theme,
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Scaffold(
          body: Builder(
            builder: (context) {
              return Center(
                child: ElevatedButton(
                  onPressed: () => Scaffold.of(context).openDrawer(),
                  child: const Text('Open drawer'),
                ),
              );
            },
          ),
          drawer: Builder(
            builder: (context) {
              final l10n = AppLocalizations.of(context)!;
              final theme = Theme.of(context);
              return Drawer(
                child: SafeArea(
                  child: ListView(
                    padding: EdgeInsets.zero,
                    children: [
                      DrawerHeader(
                        decoration: BoxDecoration(
                          color: theme.colorScheme.primaryContainer,
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            Row(
                              children: [
                                ProfileHeroAvatar(
                                  displayName: profile.name,
                                  photoUrl: profile.profilePhotoUrl,
                                  thumbUrl: profile.profilePhotoThumbUrl,
                                  radius: 28,
                                  onTap: () {},
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        profile.name,
                                        style: theme.textTheme.titleMedium,
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                      Text(
                                        profile.phone,
                                        style: theme.textTheme.bodyMedium,
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                            TextButton.icon(
                              onPressed: () {},
                              icon: const Icon(Icons.edit_outlined, size: 18),
                              label: Text(l10n.editProfile),
                              style: TextButton.styleFrom(
                                padding: EdgeInsets.zero,
                              ),
                            ),
                          ],
                        ),
                      ),
                      ListTile(
                        leading: const Icon(Icons.dashboard_outlined),
                        title: Text(l10n.homeDrawerDashboard),
                      ),
                      ListTile(
                        leading: const Icon(Icons.receipt_long_outlined),
                        title: Text(l10n.homeDrawerOrders),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }

  testWidgets('drawer light golden', (tester) async {
    await tester.pumpWidget(buildHarness(theme: AppTheme.light()));
    await tester.tap(find.text('Open drawer'));
    await tester.pumpAndSettle();
    await expectLater(
      find.byType(Drawer),
      matchesGoldenFile('goldens/drawer_light.png'),
    );
  });
}

class _DrawerGoldenMobileMeNotifier extends MobileMeNotifier {
  _DrawerGoldenMobileMeNotifier(this._value);

  final MobileMeDto _value;

  @override
  Future<MobileMeDto?> build() async => _value;
}
