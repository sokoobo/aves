import 'package:aves/app_flavor.dart';
import 'package:aves/model/settings/settings.dart';
import 'package:aves/ref/brand_colors.dart';
import 'package:aves/theme/colors.dart';
import 'package:aves/utils/dependencies.dart';
import 'package:aves/widgets/about/title.dart';
import 'package:aves/widgets/common/basic/link_chip.dart';
import 'package:aves/widgets/common/extensions/build_context.dart';
import 'package:aves/widgets/common/identity/aves_expansion_tile.dart';
import 'package:aves/widgets/common/identity/buttons/outlined_button.dart';
import 'package:collection/collection.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class Licenses extends StatefulWidget {
  const Licenses({super.key});

  @override
  State<Licenses> createState() => _LicensesState();
}

class _LicensesState extends State<Licenses> {
  final ValueNotifier<String?> _expandedNotifier = ValueNotifier(null);
  late List<Dependency> _platform, _flutterPlugins, _flutterPackages, _dartPackages;

  @override
  void initState() {
    super.initState();
    _platform = List<Dependency>.from(Dependencies.androidDependencies);
    _flutterPlugins = List<Dependency>.from(Dependencies.flutterPlugins(context.read<AppFlavor>()));
    _flutterPackages = List<Dependency>.from(Dependencies.flutterPackages);
    _dartPackages = List<Dependency>.from(Dependencies.dartPackages);
    _sortPackages();
  }

  void _sortPackages() {
    int compare(Dependency a, Dependency b) => compareAsciiUpperCase(a.name, b.name);
    _platform.sort(compare);
    _flutterPlugins.sort(compare);
    _flutterPackages.sort(compare);
    _dartPackages.sort(compare);
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.watch<AvesColorsData>();
    return SliverPadding(
      padding: const EdgeInsets.symmetric(horizontal: 8),
      sliver: SliverList(
        delegate: SliverChildListDelegate(
          [
            _buildHeader(),
            const SizedBox(height: 16),
            if (!settings.useTvLayout) ...[
              AvesExpansionTile(
                title: context.l10n.aboutLicensesAndroidLibrariesSectionTitle,
                highlightColor: colors.fromBrandColor(BrandColors.android),
                expandedNotifier: _expandedNotifier,
                children: _platform.map((package) => LicenseRow(package: package)).toList(),
              ),
              AvesExpansionTile(
                title: context.l10n.aboutLicensesFlutterPluginsSectionTitle,
                highlightColor: colors.fromBrandColor(BrandColors.flutter),
                expandedNotifier: _expandedNotifier,
                children: _flutterPlugins.map((package) => LicenseRow(package: package)).toList(),
              ),
              AvesExpansionTile(
                title: context.l10n.aboutLicensesFlutterPackagesSectionTitle,
                highlightColor: colors.fromBrandColor(BrandColors.flutter),
                expandedNotifier: _expandedNotifier,
                children: _flutterPackages.map((package) => LicenseRow(package: package)).toList(),
              ),
              AvesExpansionTile(
                title: context.l10n.aboutLicensesDartPackagesSectionTitle,
                highlightColor: colors.fromBrandColor(BrandColors.flutter),
                expandedNotifier: _expandedNotifier,
                children: _dartPackages.map((package) => LicenseRow(package: package)).toList(),
              ),
            ],
            Center(
              child: AvesOutlinedButton(
                label: context.l10n.aboutLicensesShowAllButtonLabel,
                onPressed: () => Navigator.maybeOf(context)?.push(
                  MaterialPageRoute(
                    builder: (context) => Theme(
                      data: Theme.of(context).copyWith(
                        // as of Flutter v1.22.4, `cardColor` is used as a background color by `LicensePage`
                        cardColor: Theme.of(context).scaffoldBackgroundColor,
                      ),
                      child: const LicensePage(),
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          AboutSectionTitle(text: context.l10n.aboutLicensesSectionTitle),
          const SizedBox(height: 8),
          Text(context.l10n.aboutLicensesBanner),
        ],
      ),
    );
  }
}

class LicenseRow extends StatelessWidget {
  final Dependency package;

  const LicenseRow({
    super.key,
    required this.package,
  });

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final bodyTextStyle = textTheme.bodyMedium!;
    final subColor = bodyTextStyle.color!.withOpacity(.6);

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          LinkChip(
            text: package.name,
            urlString: package.sourceUrl,
            textStyle: const TextStyle(fontWeight: FontWeight.bold),
          ),
          Padding(
            padding: const EdgeInsetsDirectional.only(start: 16),
            child: LinkChip(
              text: package.license,
              urlString: package.licenseUrl,
              color: subColor,
            ),
          ),
        ],
      ),
    );
  }
}
