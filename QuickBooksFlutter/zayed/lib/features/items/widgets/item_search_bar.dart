import 'package:flutter/material.dart';

import '../../../l10n/app_localizations.dart';

class ItemSearchBar extends StatefulWidget {
  const ItemSearchBar({super.key, this.onChanged});
  final ValueChanged<String>? onChanged;

  @override
  State<ItemSearchBar> createState() => _ItemSearchBarState();
}

class _ItemSearchBarState extends State<ItemSearchBar> {
  final _ctrl = TextEditingController();

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return TextField(
      controller: _ctrl,
      decoration: InputDecoration(
        hintText: l10n.searchNameSkuBarcode,
        prefixIcon: const Icon(Icons.search, size: 20),
        suffixIcon: _ctrl.text.isNotEmpty
            ? IconButton(
                icon: const Icon(Icons.clear, size: 18),
                onPressed: () {
                  _ctrl.clear();
                  widget.onChanged?.call('');
                },
              )
            : null,
        isDense: true,
      ),
      onChanged: (v) {
        setState(() {});
        widget.onChanged?.call(v);
      },
    );
  }
}
