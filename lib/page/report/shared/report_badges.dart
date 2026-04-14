import 'package:flutter/material.dart';
import 'package:smet/model/report_model.dart';

// ================================================================
// STATUS BADGE WIDGET
// ================================================================

class ReportStatusBadge extends StatelessWidget {
  final ReportStatus status;
  final double fontSize;
  final EdgeInsets padding;

  const ReportStatusBadge({
    super.key,
    required this.status,
    this.fontSize = 12,
    this.padding = const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: padding,
      decoration: BoxDecoration(
        color: _bgColor,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        status.displayName,
        style: TextStyle(
          color: _textColor,
          fontSize: fontSize,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  Color get _bgColor {
    switch (status) {
      case ReportStatus.DRAFT:
        return const Color(0xFFF59E0B).withValues(alpha: 0.12);
      case ReportStatus.SUBMITTED:
        return const Color(0xFF3B82F6).withValues(alpha: 0.12);
      case ReportStatus.APPROVED:
        return const Color(0xFF10B981).withValues(alpha: 0.12);
      case ReportStatus.REJECTED:
        return const Color(0xFFEF4444).withValues(alpha: 0.12);
    }
  }

  Color get _textColor {
    switch (status) {
      case ReportStatus.DRAFT:
        return const Color(0xFFB45309);
      case ReportStatus.SUBMITTED:
        return const Color(0xFF1D4ED8);
      case ReportStatus.APPROVED:
        return const Color(0xFF047857);
      case ReportStatus.REJECTED:
        return const Color(0xFFB91C1C);
    }
  }
}

// ================================================================
// REPORT TYPE BADGE WIDGET
// ================================================================

class ReportTypeBadge extends StatelessWidget {
  final ReportType type;
  final double fontSize;
  final EdgeInsets padding;

  const ReportTypeBadge({
    super.key,
    required this.type,
    this.fontSize = 12,
    this.padding = const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: padding,
      decoration: BoxDecoration(
        color: _bgColor,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        type.shortName,
        style: TextStyle(
          color: _textColor,
          fontSize: fontSize,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  Color get _bgColor {
    switch (type) {
      case ReportType.MENTOR_WEEKLY:
      case ReportType.MENTOR_MONTHLY:
        return const Color(0xFF8B5CF6).withValues(alpha: 0.12);
      case ReportType.PM_WEEKLY:
      case ReportType.PM_MONTHLY:
        return const Color(0xFFD946EF).withValues(alpha: 0.12);
      case ReportType.ADMIN_WEEKLY:
      case ReportType.ADMIN_MONTHLY:
        return const Color(0xFF0EA5E9).withValues(alpha: 0.12);
    }
  }

  Color get _textColor {
    switch (type) {
      case ReportType.MENTOR_WEEKLY:
      case ReportType.MENTOR_MONTHLY:
        return const Color(0xFF6D28D9);
      case ReportType.PM_WEEKLY:
      case ReportType.PM_MONTHLY:
        return const Color(0xFFC026D3);
      case ReportType.ADMIN_WEEKLY:
      case ReportType.ADMIN_MONTHLY:
        return const Color(0xFF0284C7);
    }
  }
}

// ================================================================
// REPORT SCOPE BADGE WIDGET
// ================================================================

class ReportScopeBadge extends StatelessWidget {
  final ReportScope scope;

  const ReportScopeBadge({super.key, required this.scope});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(_scopeIcon, size: 12, color: const Color(0xFF64748B)),
          const SizedBox(width: 4),
          Text(
            scope.displayName,
            style: const TextStyle(
              fontSize: 11,
              color: Color(0xFF64748B),
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  IconData get _scopeIcon {
    switch (scope) {
      case ReportScope.COURSE:
        return Icons.menu_book_rounded;
      case ReportScope.PROJECT:
        return Icons.folder_rounded;
      case ReportScope.SYSTEM:
        return Icons.settings_rounded;
    }
  }
}

// ================================================================
// ACTION TYPE BADGE (for version history)
// ================================================================

class ActionTypeBadge extends StatelessWidget {
  final ReportActionType actionType;

  const ActionTypeBadge({super.key, required this.actionType});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: _bgColor,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(_actionIcon, size: 12, color: _textColor),
          const SizedBox(width: 4),
          Text(
            actionType.displayName,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: _textColor,
            ),
          ),
        ],
      ),
    );
  }

  Color get _bgColor {
    switch (actionType) {
      case ReportActionType.EDIT:
        return const Color(0xFF64748B).withValues(alpha: 0.12);
      case ReportActionType.SUBMIT:
        return const Color(0xFF3B82F6).withValues(alpha: 0.12);
      case ReportActionType.APPROVE:
        return const Color(0xFF10B981).withValues(alpha: 0.12);
      case ReportActionType.REJECT:
        return const Color(0xFFEF4444).withValues(alpha: 0.12);
      case ReportActionType.DELETE:
        return const Color(0xFFEF4444).withValues(alpha: 0.12);
    }
  }

  Color get _textColor {
    switch (actionType) {
      case ReportActionType.EDIT:
        return const Color(0xFF475569);
      case ReportActionType.SUBMIT:
        return const Color(0xFF2563EB);
      case ReportActionType.APPROVE:
        return const Color(0xFF059669);
      case ReportActionType.REJECT:
        return const Color(0xFFDC2626);
      case ReportActionType.DELETE:
        return const Color(0xFFDC2626);
    }
  }

  IconData get _actionIcon {
    switch (actionType) {
      case ReportActionType.EDIT:
        return Icons.edit_rounded;
      case ReportActionType.SUBMIT:
        return Icons.send_rounded;
      case ReportActionType.APPROVE:
        return Icons.check_circle_rounded;
      case ReportActionType.REJECT:
        return Icons.cancel_rounded;
      case ReportActionType.DELETE:
        return Icons.delete_rounded;
    }
  }
}

// ================================================================
// VERSION NUMBER BADGE
// ================================================================

class VersionBadge extends StatelessWidget {
  final int version;

  const VersionBadge({super.key, required this.version});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Text(
        'v$version',
        style: const TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w600,
          color: Color(0xFF475569),
        ),
      ),
    );
  }
}
