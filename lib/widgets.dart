import 'package:flutter/material.dart';
import 'theme.dart';

class PrimaryButton extends StatelessWidget {
  final String label;
  final VoidCallback? onPressed;
  final bool loading;

  const PrimaryButton({
    super.key,
    required this.label,
    this.onPressed,
    this.loading = false,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: loading ? null : onPressed,
        child: loading
            ? const SizedBox(
                height: 20,
                width: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: Colors.white,
                ),
              )
            : Text(label),
      ),
    );
  }
}

class TaskCard extends StatelessWidget {
  final String title;
  final String? subtitle;
  final String status; // pending, in_progress, done, blocked
  final Widget? trailing;

  const TaskCard({
    super.key,
    required this.title,
    this.subtitle,
    this.status = 'pending',
    this.trailing,
  });

  @override
  Widget build(BuildContext context) {
    final color = StatusColors.map[status] ?? AppTheme.primary;
    return Card(
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: color.withOpacity(0.15),
          child: Icon(Icons.check, color: color),
        ),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.w600)),
        subtitle: subtitle == null ? null : Text(subtitle!),
        trailing:
            trailing ??
            Chip(
              label: Text(status.replaceAll('_', ' ')),
              backgroundColor: color.withOpacity(0.12),
              labelStyle: TextStyle(color: color),
            ),
      ),
    );
  }
}

class UserAvatar extends StatelessWidget {
  final String initials;
  const UserAvatar({super.key, required this.initials});

  @override
  Widget build(BuildContext context) {
    return CircleAvatar(
      backgroundColor: AppTheme.primary.withOpacity(0.12),
      child: Text(
        initials,
        style: const TextStyle(fontWeight: FontWeight.bold),
      ),
    );
  }
}
