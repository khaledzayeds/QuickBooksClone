// item_search_bar.dart
// item_search_bar.dart

import 'package:flutter/material.dart';

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
    return TextField(
      controller: _ctrl,
      decoration: InputDecoration(
        hintText: 'بحث بالاسم أو SKU أو الباركود...',
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