// account_tree_widget.dart
// account_tree_widget.dart

import 'package:flutter/material.dart';
import '../data/models/account_model.dart';

class AccountTreeWidget extends StatelessWidget {
  const AccountTreeWidget({
    super.key,
    required this.accounts,
    this.onSelect,
  });

  final List<AccountModel> accounts;
  final void Function(AccountModel)? onSelect;

  @override
  Widget build(BuildContext context) {
    // Group by parent
    final roots = accounts.where((a) => a.parentId == null).toList();

    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: roots.length,
      itemBuilder: (_, i) => _AccountTreeNode(
        account: roots[i],
        allAccounts: accounts,
        onSelect: onSelect,
        depth: 0,
      ),
    );
  }
}

class _AccountTreeNode extends StatefulWidget {
  const _AccountTreeNode({
    required this.account,
    required this.allAccounts,
    required this.depth,
    this.onSelect,
  });

  final AccountModel account;
  final List<AccountModel> allAccounts;
  final int depth;
  final void Function(AccountModel)? onSelect;

  @override
  State<_AccountTreeNode> createState() => _AccountTreeNodeState();
}

class _AccountTreeNodeState extends State<_AccountTreeNode> {
  bool _expanded = true;

  @override
  Widget build(BuildContext context) {
    final children = widget.allAccounts
        .where((a) => a.parentId == widget.account.id)
        .toList();
    final hasChildren = children.isNotEmpty;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        InkWell(
          onTap: () => widget.onSelect?.call(widget.account),
          child: Padding(
            padding: EdgeInsets.only(
                right: 16.0 + widget.depth * 20, left: 8, top: 4, bottom: 4),
            child: Row(
              children: [
                if (hasChildren)
                  GestureDetector(
                    onTap: () =>
                        setState(() => _expanded = !_expanded),
                    child: Icon(
                      _expanded
                          ? Icons.expand_more
                          : Icons.chevron_right,
                      size: 18,
                    ),
                  )
                else
                  const SizedBox(width: 18),
                const SizedBox(width: 4),
                Text(
                  '${widget.account.code} — ${widget.account.name}',
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
                const Spacer(),
                Text(
                  '${widget.account.balance.toStringAsFixed(2)} ج.م',
                  style: Theme.of(context).textTheme.labelSmall,
                ),
              ],
            ),
          ),
        ),
        if (hasChildren && _expanded)
          ...children.map((child) => _AccountTreeNode(
                account: child,
                allAccounts: widget.allAccounts,
                onSelect: widget.onSelect,
                depth: widget.depth + 1,
              )),
      ],
    );
  }
}