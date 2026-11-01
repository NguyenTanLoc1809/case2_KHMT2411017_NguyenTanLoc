import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/notification_provider.dart';
import 'notifications/notification_screen.dart';
import 'profile/profile_screen.dart';
import 'tasks/task_list_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _index = 0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) context.read<NotificationProvider>().refresh();
    });
  }

  Widget _page() {
    switch (_index) {
      case 1:
        return const NotificationScreen();
      case 2:
        return const ProfileScreen();
      default:
        return const TaskListScreen();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _page(),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _index,
        onDestinationSelected: (i) {
          setState(() => _index = i);
          context.read<NotificationProvider>().refresh();
        },
        destinations: [
          const NavigationDestination(
            icon: Icon(Icons.checklist_outlined),
            selectedIcon: Icon(Icons.checklist),
            label: 'Công việc',
          ),
          NavigationDestination(
            icon: Consumer<NotificationProvider>(
              builder: (_, np, __) => Badge(
                isLabelVisible: np.unread > 0,
                label: Text('${np.unread}'),
                child: const Icon(Icons.notifications_outlined),
              ),
            ),
            selectedIcon: const Icon(Icons.notifications),
            label: 'Thông báo',
          ),
          const NavigationDestination(
            icon: Icon(Icons.person_outline),
            selectedIcon: Icon(Icons.person),
            label: 'Cá nhân',
          ),
        ],
      ),
    );
  }
}
