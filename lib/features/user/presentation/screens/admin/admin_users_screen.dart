import 'dart:async';

import 'package:flutter/material.dart';
import 'package:medilink/core/database/schema/user_schema.dart';
import 'package:medilink/core/di/injection.dart';
import 'package:medilink/core/session/user_role.dart';
import 'package:medilink/core/theme/app_dimens.dart';
import 'package:medilink/core/widgets/widgets.dart';
import 'package:medilink/features/user/data/models/account_summary.dart';
import 'package:medilink/features/user/presentation/controllers/admin_controller.dart';
import 'package:medilink/features/user/presentation/screens/admin/admin_widgets.dart';

/// Tous les comptes : recherche, filtres par rôle et statut, actions.
class AdminUsersScreen extends StatefulWidget {
  const AdminUsersScreen({super.key, this.initialRole});

  final UserRole? initialRole;

  @override
  State<AdminUsersScreen> createState() => _AdminUsersScreenState();
}

class _AdminUsersScreenState extends State<AdminUsersScreen> {
  late final AdminController _controller = getIt<AdminController>()..search(role: widget.initialRole);
  Timer? _debounce;

  static const _statuses = [
    AccountStatus.active,
    AccountStatus.pending,
    AccountStatus.suspended,
    AccountStatus.rejected,
  ];

  @override
  void dispose() {
    _debounce?.cancel();
    _controller.dispose();
    super.dispose();
  }

  void _onSearch(String value) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 300), () => _controller.search(query: value));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Comptes')),
      body: ListenableBuilder(
        listenable: _controller,
        builder: (context, _) {
          return Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(AppSpacing.lg, AppSpacing.sm, AppSpacing.lg, 0),
                child: TextField(
                  onChanged: _onSearch,
                  decoration: const InputDecoration(
                    hintText: 'Nom, prénom ou e-mail',
                    prefixIcon: Icon(Icons.search_rounded),
                  ),
                ),
              ),
              SizedBox(
                height: 52,
                child: ListView(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg, vertical: AppSpacing.sm),
                  children: [
                    FilterChip(
                      label: const Text('Tous les rôles'),
                      selected: _controller.roleFilter == null,
                      onSelected: (_) => _controller.search(clearRole: true),
                    ),
                    for (final role in UserRole.values) ...[
                      const SizedBox(width: AppSpacing.sm),
                      FilterChip(
                        label: Text(role.label),
                        selected: _controller.roleFilter == role,
                        onSelected:
                            (selected) =>
                                selected ? _controller.search(role: role) : _controller.search(clearRole: true),
                      ),
                    ],
                  ],
                ),
              ),
              SizedBox(
                height: 48,
                child: ListView(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
                  children: [
                    ChoiceChip(
                      label: const Text('Tous statuts'),
                      selected: _controller.statusFilter == null,
                      onSelected: (_) => _controller.search(clearStatus: true),
                    ),
                    for (final status in _statuses) ...[
                      const SizedBox(width: AppSpacing.sm),
                      ChoiceChip(
                        label: Text(AccountSummary.statusLabel(status)),
                        selected: _controller.statusFilter == status,
                        onSelected:
                            (selected) =>
                                selected ? _controller.search(status: status) : _controller.search(clearStatus: true),
                      ),
                    ],
                  ],
                ),
              ),
              Expanded(
                child:
                    _controller.isLoading && _controller.accounts.isEmpty
                        ? const LoadingView()
                        : _controller.accounts.isEmpty
                        ? const EmptyState(icon: Icons.search_off_rounded, title: 'Aucun compte trouvé')
                        : ListView.separated(
                          padding: const EdgeInsets.all(AppSpacing.lg),
                          itemCount: _controller.accounts.length,
                          separatorBuilder: (_, _) => const SizedBox(height: AppSpacing.sm),
                          itemBuilder: (context, i) {
                            final a = _controller.accounts[i];
                            return AccountTile(
                              account: a,
                              onTap: () => showAccountSheet(context, a, _controller),
                              trailing: const Icon(Icons.chevron_right_rounded),
                            );
                          },
                        ),
              ),
            ],
          );
        },
      ),
    );
  }
}
