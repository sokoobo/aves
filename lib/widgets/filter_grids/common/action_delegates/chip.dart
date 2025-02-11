import 'package:aves/model/actions/chip_actions.dart';
import 'package:aves/model/filters/filters.dart';
import 'package:aves/model/highlight.dart';
import 'package:aves/model/settings/settings.dart';
import 'package:aves/services/common/services.dart';
import 'package:aves/widgets/common/extensions/build_context.dart';
import 'package:aves/widgets/dialogs/aves_dialog.dart';
import 'package:aves/widgets/filter_grids/albums_page.dart';
import 'package:aves/widgets/filter_grids/countries_page.dart';
import 'package:aves/widgets/filter_grids/tags_page.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class ChipActionDelegate {
  void onActionSelected(BuildContext context, CollectionFilter filter, ChipAction action) {
    reportService.log('$action');
    switch (action) {
      case ChipAction.goToAlbumPage:
        _goTo(context, filter, AlbumListPage.routeName, (context) => const AlbumListPage());
        break;
      case ChipAction.goToCountryPage:
        _goTo(context, filter, CountryListPage.routeName, (context) => const CountryListPage());
        break;
      case ChipAction.goToTagPage:
        _goTo(context, filter, TagListPage.routeName, (context) => const TagListPage());
        break;
      case ChipAction.reverse:
        ReverseFilterNotification(filter).dispatch(context);
        break;
      case ChipAction.hide:
        _hide(context, filter);
        break;
      default:
        break;
    }
  }

  void _goTo(
    BuildContext context,
    CollectionFilter filter,
    String routeName,
    WidgetBuilder pageBuilder,
  ) {
    context.read<HighlightInfo>().set(filter);
    Navigator.maybeOf(context)?.pushAndRemoveUntil(
      MaterialPageRoute(
        settings: RouteSettings(name: routeName),
        builder: pageBuilder,
      ),
      (route) => false,
    );
  }

  Future<void> _hide(BuildContext context, CollectionFilter filter) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AvesDialog(
        content: Text(context.l10n.hideFilterConfirmationDialogMessage),
        actions: [
          const CancelButton(),
          TextButton(
            onPressed: () => Navigator.maybeOf(context)?.pop(true),
            child: Text(context.l10n.hideButtonLabel),
          ),
        ],
      ),
      routeSettings: const RouteSettings(name: AvesDialog.confirmationRouteName),
    );
    if (confirmed == null || !confirmed) return;

    settings.changeFilterVisibility({filter}, false);
  }
}

@immutable
class ReverseFilterNotification extends Notification {
  final CollectionFilter reversedFilter;

  ReverseFilterNotification(CollectionFilter filter) : reversedFilter = filter.reverse();
}
