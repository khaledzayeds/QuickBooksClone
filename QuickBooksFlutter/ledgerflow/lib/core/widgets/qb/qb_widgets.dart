import 'package:flutter/material.dart';

class QbDesignTokens {
  static const Color headerBlue = Color(0xFF264D5B);
  static const Color headerBorder = Color(0xFF183642);
  static const Color gridBorder = Color(0xFFB7C3CB);
  static const Color sideSectionBg = Color(0xFFE7EEF1);
  static const Color sidebarTitleBlue = Color(0xFF2D4854);
  static const Color accentBg = Color(0xFFE7F1F4);
  static const Color accentBorder = Color(0xFF8EABB7);
  static const Color textDark = Color(0xFF213D49);
  static const Color textMuted = Color(0xFF53656E);
}

class QbStripLabel extends StatelessWidget {
  const QbStripLabel(this.text, {super.key});
  final String text;

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: Theme.of(context).textTheme.labelSmall?.copyWith(
        color: Colors.white,
        fontWeight: FontWeight.w900,
      ),
    );
  }
}

class QbFieldLabel extends StatelessWidget {
  const QbFieldLabel(this.text, {super.key});
  final String text;

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: Theme.of(context).textTheme.labelSmall?.copyWith(
        color: QbDesignTokens.textMuted,
        fontWeight: FontWeight.w900,
      ),
    );
  }
}

class QbStaticBox extends StatelessWidget {
  const QbStaticBox({super.key, required this.text, this.icon, this.onTap});

  final String text;
  final IconData? icon;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final boxContent = Container(
      height: 34,
      alignment: Alignment.centerLeft,
      padding: const EdgeInsets.symmetric(horizontal: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: QbDesignTokens.gridBorder),
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(
              text,
              style: Theme.of(context).textTheme.bodySmall,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          if (icon != null)
            Icon(icon, size: 15, color: QbDesignTokens.textMuted),
        ],
      ),
    );

    if (onTap != null) {
      return InkWell(onTap: onTap, child: boxContent);
    }
    return boxContent;
  }
}

class QbDateBox extends StatelessWidget {
  const QbDateBox({
    super.key,
    required this.text,
    this.enabled = true,
    this.onTap,
  });

  final String text;
  final bool enabled;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return QbStaticBox(
      text: text,
      icon: Icons.calendar_today_outlined,
      onTap: enabled ? onTap : null,
    );
  }
}

class QbHorizontalField extends StatelessWidget {
  const QbHorizontalField({
    super.key,
    required this.label,
    required this.child,
    this.labelWidth = 86,
  });

  final String label;
  final Widget child;
  final double labelWidth;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        SizedBox(width: labelWidth, child: QbFieldLabel(label)),
        Expanded(child: child),
      ],
    );
  }
}

class QbStackedField extends StatelessWidget {
  const QbStackedField({super.key, required this.label, required this.child});

  final String label;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [QbFieldLabel(label), const SizedBox(height: 4), child],
    );
  }
}

class QbSideSection extends StatelessWidget {
  const QbSideSection({
    super.key,
    required this.title,
    required this.child,
    this.expanded = false,
  });

  final String title;
  final Widget child;
  final bool expanded;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.fromLTRB(8, 8, 8, 0),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: QbDesignTokens.gridBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: expanded ? MainAxisSize.max : MainAxisSize.min,
        children: [
          Container(
            height: 30,
            padding: const EdgeInsetsDirectional.only(start: 8, end: 4),
            decoration: const BoxDecoration(
              color: QbDesignTokens.sideSectionBg,
              border: Border(
                bottom: BorderSide(color: QbDesignTokens.gridBorder),
              ),
            ),
            child: Align(
              alignment: Alignment.centerLeft,
              child: Text(
                title,
                style: Theme.of(context).textTheme.labelMedium?.copyWith(
                  color: QbDesignTokens.sidebarTitleBlue,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ),
          ),
          Padding(padding: const EdgeInsets.all(8), child: child),
        ],
      ),
    );
  }
}

class QbInfoRow extends StatelessWidget {
  const QbInfoRow({
    super.key,
    required this.label,
    required this.value,
    this.strong = false,
  });

  final String label;
  final String value;
  final bool strong;

  @override
  Widget build(BuildContext context) {
    final style = Theme.of(context).textTheme.bodySmall?.copyWith(
      color: const Color(0xFF334A55),
      fontWeight: strong ? FontWeight.w900 : FontWeight.w600,
    );
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        children: [
          Expanded(
            child: Text(label, style: style, overflow: TextOverflow.ellipsis),
          ),
          Flexible(
            child: Text(
              value,
              textAlign: TextAlign.end,
              overflow: TextOverflow.ellipsis,
              style: style,
            ),
          ),
        ],
      ),
    );
  }
}

class QbSideTabBar extends StatelessWidget {
  const QbSideTabBar({
    super.key,
    required this.tabs,
    required this.currentIndex,
    required this.onTap,
  });

  final List<String> tabs;
  final int currentIndex;
  final ValueChanged<int> onTap;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 30,
      decoration: const BoxDecoration(
        color: Color(0xFFDDE6EB),
        border: Border(bottom: BorderSide(color: QbDesignTokens.gridBorder)),
      ),
      child: Row(
        children: List.generate(tabs.length, (index) {
          final isSelected = index == currentIndex;
          return Expanded(
            child: InkWell(
              onTap: () => onTap(index),
              child: Container(
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: isSelected ? Colors.white : Colors.transparent,
                  border: isSelected
                      ? const Border(
                          right: BorderSide(color: QbDesignTokens.gridBorder),
                          left: BorderSide(color: QbDesignTokens.gridBorder),
                        )
                      : null,
                ),
                child: Text(
                  tabs[index],
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    color: isSelected
                        ? QbDesignTokens.sidebarTitleBlue
                        : const Color(0xFF5A707C),
                    fontWeight: isSelected ? FontWeight.w900 : FontWeight.w700,
                  ),
                ),
              ),
            ),
          );
        }),
      ),
    );
  }
}
