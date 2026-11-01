import 'dart:async';

import 'package:flutter/material.dart';

import '../models/user.dart';
import '../services/user_service.dart';

/// Tìm người dùng theo tên/email (gọi API /users/search) và chọn một hoặc nhiều người.
class UserSelector extends StatefulWidget {
  final List<AppUser> selected;
  final ValueChanged<List<AppUser>> onChanged;
  final bool multiple;
  final Set<String> excludeIds;
  final String label;

  const UserSelector({
    super.key,
    required this.selected,
    required this.onChanged,
    this.multiple = true,
    this.excludeIds = const {},
    this.label = 'Tìm theo tên hoặc email',
  });

  @override
  State<UserSelector> createState() => _UserSelectorState();
}

class _UserSelectorState extends State<UserSelector> {
  final _controller = TextEditingController();
  final _service = UserService();
  Timer? _debounce;
  List<AppUser> _results = [];
  bool _loading = false;
  String? _error;

  @override
  void dispose() {
    _debounce?.cancel();
    _controller.dispose();
    super.dispose();
  }

  void _onChanged(String text) {
    _debounce?.cancel();
    if (text.trim().isEmpty) {
      setState(() {
        _results = [];
        _error = null;
        _loading = false;
      });
      return;
    }
    _debounce = Timer(const Duration(milliseconds: 350), () => _search(text.trim()));
  }

  Future<void> _search(String q) async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final users = await _service.search(q);
      if (!mounted) return;
      setState(() => _results = users);
    } catch (e) {
      if (!mounted) return;
      setState(() => _error = e.toString());
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _pick(AppUser user) {
    if (widget.multiple) {
      if (!widget.selected.any((u) => u.id == user.id)) {
        widget.onChanged([...widget.selected, user]);
      }
    } else {
      widget.onChanged([user]);
    }
    _controller.clear();
    setState(() => _results = []);
  }

  void _remove(AppUser user) =>
      widget.onChanged(widget.selected.where((u) => u.id != user.id).toList());

  @override
  Widget build(BuildContext context) {
    final visible = _results
        .where((u) => !widget.excludeIds.contains(u.id) && !widget.selected.any((s) => s.id == u.id))
        .toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (widget.selected.isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Wrap(
              spacing: 6,
              runSpacing: 4,
              children: widget.selected
                  .map((u) => InputChip(
                        avatar: CircleAvatar(child: Text(u.initials)),
                        label: Text(u.fullName),
                        onDeleted: () => _remove(u),
                      ))
                  .toList(),
            ),
          ),
        TextField(
          controller: _controller,
          onChanged: _onChanged,
          decoration: InputDecoration(
            labelText: widget.label,
            prefixIcon: const Icon(Icons.search),
            border: const OutlineInputBorder(),
            suffixIcon: _loading
                ? const Padding(
                    padding: EdgeInsets.all(12),
                    child: SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2)),
                  )
                : null,
          ),
        ),
        if (_error != null)
          Padding(
            padding: const EdgeInsets.only(top: 6),
            child: Text(_error!, style: TextStyle(color: Theme.of(context).colorScheme.error)),
          ),
        if (_controller.text.trim().isNotEmpty && !_loading && _error == null && visible.isEmpty)
          const Padding(
            padding: EdgeInsets.only(top: 8),
            child: Text('Không tìm thấy người dùng phù hợp', style: TextStyle(color: Colors.grey)),
          ),
        ...visible.map((u) => ListTile(
              dense: true,
              leading: CircleAvatar(child: Text(u.initials)),
              title: Text(u.fullName),
              subtitle: Text(u.email),
              onTap: () => _pick(u),
            )),
      ],
    );
  }
}
