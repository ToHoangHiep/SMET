import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class BreadcrumbItem {
  final String label;
  final String? route;

  const BreadcrumbItem({
    required this.label,
    this.route,
  });
}

class SharedBreadcrumb extends StatelessWidget {
  final List<BreadcrumbItem> items;
  final Color? primaryColor;
  final double fontSize;
  final EdgeInsets padding;

  const SharedBreadcrumb({
    super.key,
    required this.items,
    this.primaryColor,
    this.fontSize = 13,
    this.padding = const EdgeInsets.symmetric(vertical: 16),
  });

  @override
  Widget build(BuildContext context) {
    final color = primaryColor ?? const Color(0xFF6366F1);
    final activeColor = const Color(0xFF64748B);

    return Padding(
      padding: padding,
      child: Wrap(
        crossAxisAlignment: WrapCrossAlignment.center,
        spacing: 4,
        runSpacing: 4,
        children: [
          for (int i = 0; i < items.length; i++)
            _buildItem(context, items[i], i, color, activeColor),
        ],
      ),
    );
  }

  Widget _buildItem(
    BuildContext context,
    BreadcrumbItem item,
    int index,
    Color color,
    Color activeColor,
  ) {
    final isLast = index == items.length - 1;

    if (isLast) {
      return Text(
        item.label,
        style: TextStyle(
          fontSize: fontSize,
          fontWeight: FontWeight.w600,
          color: color,
        ),
      );
    }

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (item.route != null)
          _BreadcrumbLink(
            label: item.label,
            route: item.route!,
            fontSize: fontSize,
            color: color,
          )
        else
          Text(
            item.label,
            style: TextStyle(
              fontSize: fontSize,
              fontWeight: FontWeight.w500,
              color: activeColor,
            ),
          ),
        const SizedBox(width: 4),
        Icon(
          Icons.chevron_right,
          size: 16,
          color: Colors.grey[400],
        ),
        const SizedBox(width: 4),
      ],
    );
  }
}

class _BreadcrumbLink extends StatefulWidget {
  final String label;
  final String route;
  final double fontSize;
  final Color color;

  const _BreadcrumbLink({
    required this.label,
    required this.route,
    required this.fontSize,
    required this.color,
  });

  @override
  State<_BreadcrumbLink> createState() => _BreadcrumbLinkState();
}

class _BreadcrumbLinkState extends State<_BreadcrumbLink> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: InkWell(
        onTap: () => context.go(widget.route),
        borderRadius: BorderRadius.circular(4),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
          child: Text(
            widget.label,
            style: TextStyle(
              fontSize: widget.fontSize,
              fontWeight: FontWeight.w500,
              color: _isHovered ? widget.color : const Color(0xFF64748B),
              decoration: _isHovered ? TextDecoration.underline : null,
            ),
          ),
        ),
      ),
    );
  }
}

class BreadcrumbPageHeader extends StatelessWidget {
  final String pageTitle;
  final IconData pageIcon;
  final List<BreadcrumbItem> breadcrumbs;
  final Color primaryColor;
  final List<Widget>? actions;

  const BreadcrumbPageHeader({
    super.key,
    required this.pageTitle,
    required this.pageIcon,
    required this.breadcrumbs,
    this.primaryColor = const Color(0xFF6366F1),
    this.actions,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE5E7EB)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SharedBreadcrumb(
            items: breadcrumbs,
            primaryColor: primaryColor,
            fontSize: 13,
            padding: EdgeInsets.zero,
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: primaryColor.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  pageIcon,
                  color: primaryColor,
                  size: 22,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Text(
                  pageTitle,
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF0F172A),
                  ),
                ),
              ),
              if (actions != null) ...actions!,
            ],
          ),
        ],
      ),
    );
  }
}
