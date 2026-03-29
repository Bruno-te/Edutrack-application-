import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/models/user_model.dart';
import '../../../core/services/firestore_service.dart';
import '../../../core/widgets/shared_widgets.dart';

/// Admin: set a parent account's `studentId` to a child's Firebase Account ID.
class ParentLinkingScreen extends StatefulWidget {
  const ParentLinkingScreen({super.key});

  @override
  State<ParentLinkingScreen> createState() => _ParentLinkingScreenState();
}

class _ParentLinkingScreenState extends State<ParentLinkingScreen> {
  bool _loading = true;
  bool _saving = false;
  List<UserModel> _parents = const [];
  List<UserModel> _students = const [];

  String? _parentId;
  String? _childId;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _load());
  }

  Future<void> _load() async {
    final fs = context.read<FirestoreService>();
    final parents = await fs.getUsersByRole('parent');
    final students = await fs.getUsersByRole('student');
    if (!mounted) return;
    setState(() {
      _loading = false;
      _parents = parents;
      _students = students;
      _parentId ??= parents.isNotEmpty ? parents.first.id : null;
      _childId ??= students.isNotEmpty ? students.first.id : null;
    });
  }

  Future<void> _save() async {
    if (_parentId == null || _childId == null) return;
    setState(() => _saving = true);
    try {
      await context.read<FirestoreService>().linkParentToChild(
            parentUserId: _parentId!,
            childStudentUserId: _childId!,
          );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Parent linked to student successfully.'),
          backgroundColor: AppColors.success,
          behavior: SnackBarBehavior.floating,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Could not save: $e'),
          backgroundColor: AppColors.error,
          behavior: SnackBarBehavior.floating,
        ),
      );
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Link parents to students'),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Choose a parent account and the student (child) they should see in the app. '
                    'This stores the child\'s Account ID on the parent profile.',
                    style: TextStyle(
                      fontSize: 14,
                      color: AppColors.textSecondary.withOpacity(0.95),
                      height: 1.4,
                    ),
                  ),
                  const SizedBox(height: 20),
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          DropdownButtonFormField<String>(
                            value: _parentId,
                            items: _parents
                                .map(
                                  (p) => DropdownMenuItem(
                                    value: p.id,
                                    child: Text(
                                      '${p.fullName} (${p.email})',
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                )
                                .toList(),
                            onChanged: _parents.isEmpty
                                ? null
                                : (v) => setState(() => _parentId = v),
                            decoration: const InputDecoration(
                              labelText: 'Parent account',
                              border: OutlineInputBorder(),
                            ),
                          ),
                          const SizedBox(height: 16),
                          DropdownButtonFormField<String>(
                            value: _childId,
                            items: _students
                                .map(
                                  (s) => DropdownMenuItem(
                                    value: s.id,
                                    child: Text(
                                      '${s.fullName} — ${s.id}',
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                )
                                .toList(),
                            onChanged: _students.isEmpty
                                ? null
                                : (v) => setState(() => _childId = v),
                            decoration: const InputDecoration(
                              labelText: 'Child (student) Account ID',
                              border: OutlineInputBorder(),
                              helperText:
                                  'Student\'s Firebase id — also visible on their Profile',
                            ),
                          ),
                          const SizedBox(height: 20),
                          SizedBox(
                            width: double.infinity,
                            child: ElevatedButton(
                              onPressed: (_saving ||
                                      _parents.isEmpty ||
                                      _students.isEmpty ||
                                      _parentId == null ||
                                      _childId == null)
                                  ? null
                                  : _save,
                              child: _saving
                                  ? const SizedBox(
                                      height: 22,
                                      width: 22,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                        color: Colors.white,
                                      ),
                                    )
                                  : const Text('Save link'),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  if (_parents.isEmpty || _students.isEmpty) ...[
                    const SizedBox(height: 16),
                    EmptyState(
                      icon: Icons.family_restroom_outlined,
                      title: _parents.isEmpty && _students.isEmpty
                          ? 'No parent or student accounts'
                          : _parents.isEmpty
                              ? 'No parent accounts'
                              : 'No student accounts',
                      subtitle:
                          'Register users with role Parent or Student first.',
                    ),
                  ],
                ],
              ),
            ),
    );
  }
}
