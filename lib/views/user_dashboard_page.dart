import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:task_management/theme.dart' show AppTheme;
import 'package:task_management/viewmodels/user_dashboard_viewmodel.dart';

class UserDashboardPage extends StatefulWidget {
  const UserDashboardPage({super.key});

  @override
  State<UserDashboardPage> createState() => _UserDashboardPageState();
}

class _UserDashboardPageState extends State<UserDashboardPage> {
  @override
  void initState() {
    super.initState();
    // Trigger initial load
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<UserDashboardViewModel>().refresh();
    });
  }

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<UserDashboardViewModel>();

    return Scaffold(
      body: Stack(
        children: [
          // Background blobs
          Positioned(
            top: 80,
            left: -60,
            child: _buildBlob(AppTheme.blobGreen, 200),
          ),
          Positioned(
            top: 40,
            right: -80,
            child: _buildBlob(AppTheme.blobYellow, 220),
          ),
          Positioned(
            bottom: 300,
            left: -70,
            child: _buildBlob(AppTheme.blobBlue, 240),
          ),
          Positioned(
            bottom: 150,
            right: -60,
            child: _buildBlob(AppTheme.blobPurple, 200),
          ),

          SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Top Profile Row
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: const [_ProfileHeader(), _NotificationIcon()],
                  ),

                  const SizedBox(height: 24),

                  // Section Title
                  Row(
                    children: [
                      const Text(
                        'My Tasks',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.purple.shade50,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          '${vm.tasks.length}',
                          style: const TextStyle(
                            color: Colors.purple,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 16),

                  // Task List
                  Expanded(
                    child: vm.isRefreshing
                        ? const Center(child: CircularProgressIndicator())
                        : ListView.separated(
                            itemCount: vm.tasks.length,
                            separatorBuilder: (_, __) =>
                                const SizedBox(height: 12),
                            itemBuilder: (context, index) {
                              final task = vm.tasks[index];
                              final title = (task['name'] ?? '').toString();
                              final stage =
                                  (task['stage_id'] is List &&
                                      (task['stage_id'] as List).length >= 2)
                                  ? (task['stage_id'] as List)[1].toString()
                                  : 'Stage';
                              return _buildTaskCard(
                                title: title,
                                subtitle: stage,
                                status: '—',
                              );
                            },
                          ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTaskCard({
    required String title,
    required String subtitle,
    required String status,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black12.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          const CircleAvatar(
            radius: 24,
            backgroundColor: Color(0xFFEDE7F6),
            child: Icon(
              Icons.task_outlined,
              color: Color(0xFF7E57C2),
              size: 24,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 4),
                Text(subtitle, style: const TextStyle(color: Colors.black54)),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              const Text(
                'Task status',
                style: TextStyle(fontSize: 12, color: Colors.black54),
              ),
              Text(
                status,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Colors.red,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildBlob(Color color, double size) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        // color: color.withOpacity(0.35),
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.2),
            blurRadius: 120,
            spreadRadius: 60,
          ),
        ],
      ),
    );
  }
}

class _ProfileHeader extends StatelessWidget {
  const _ProfileHeader();
  @override
  Widget build(BuildContext context) {
    return Row(
      children: const [
        CircleAvatar(
          radius: 28,
          backgroundImage: NetworkImage(
            'https://randomuser.me/api/portraits/men/32.jpg',
          ),
        ),
        SizedBox(width: 12),
        _HelloName(),
      ],
    );
  }
}

class _HelloName extends StatelessWidget {
  const _HelloName();
  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: const [
        Text('Hello!', style: TextStyle(fontSize: 14, color: Colors.black54)),
        Text(
          'User',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
      ],
    );
  }
}

class _NotificationIcon extends StatelessWidget {
  const _NotificationIcon();
  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        const Icon(Icons.notifications, size: 28),
        Positioned(
          right: 0,
          top: 2,
          child: Container(
            width: 8,
            height: 8,
            decoration: const BoxDecoration(
              color: Colors.purple,
              shape: BoxShape.circle,
            ),
          ),
        ),
      ],
    );
  }
}
