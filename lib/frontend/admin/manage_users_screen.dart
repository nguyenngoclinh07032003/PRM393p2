import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../backend/config/app_constants.dart';
import 'admin_theme.dart';

class ManageUsersScreen extends StatelessWidget {
  const ManageUsersScreen({super.key});

  @override
  Widget build(BuildContext context) => const ManageUsersBody();
}

class ManageUsersBody extends StatelessWidget {
  const ManageUsersBody({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection(AppConstants.usersCollection)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError) {
          return Center(child: Text('Lỗi: ${snapshot.error}'));
        }

        final docs = snapshot.data?.docs ?? [];

        return AdminPage(
          title: 'Quản Lý Người Dùng',
          subtitle: 'Phân quyền và trạng thái tài khoản',
          actions: [
            AdminPrimaryButton(
              label: 'Thêm người dùng',
              icon: Icons.person_add_outlined,
              onPressed: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Người dùng mới đăng ký qua màn Đăng ký'),
                  ),
                );
              },
            ),
          ],
          child: docs.isEmpty
              ? const AdminEmptyState(
                  message: 'Chưa có người dùng',
                  icon: Icons.people_alt_outlined,
                )
              : AdminDataTableWrap(
                  child: DataTable(
                    columnSpacing: 28,
                    columns: const [
                      DataColumn(label: Text('Người dùng')),
                      DataColumn(label: Text('Email')),
                      DataColumn(label: Text('Vai trò')),
                      DataColumn(label: Text('Trạng thái')),
                      DataColumn(label: Text('Thao tác')),
                    ],
                    rows: docs.map((doc) {
                      final data = doc.data() as Map<String, dynamic>;
                      final fullName =
                          (data['fullName'] as String?)?.trim() ?? 'Không có tên';
                      final email = data['email'] ?? '';
                      final role = data['role'] ?? AppConstants.roleCustomer;
                      final status =
                          data['status'] ?? AppConstants.statusActive;
                      final isActive = status != AppConstants.statusInactive;

                      return DataRow(
                        cells: [
                          DataCell(
                            Row(
                              children: [
                                CircleAvatar(
                                  radius: 16,
                                  backgroundColor:
                                      _roleColor(role).withValues(alpha: 0.15),
                                  child: Text(
                                    fullName.isNotEmpty
                                        ? fullName[0].toUpperCase()
                                        : 'U',
                                    style: TextStyle(
                                      color: _roleColor(role),
                                      fontWeight: FontWeight.w800,
                                      fontSize: 12,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 10),
                                Text(
                                  fullName,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w600,
                                    fontSize: 13,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          DataCell(Text(email, style: const TextStyle(fontSize: 12))),
                          DataCell(Text(_roleText(role))),
                          DataCell(
                            AdminStatusBadge(
                              label: isActive ? 'Đang hoạt động' : 'Tạm khóa',
                              color: isActive
                                  ? const Color(0xFF12B76A)
                                  : const Color(0xFFF04438),
                            ),
                          ),
                          DataCell(
                            PopupMenuButton<String>(
                              onSelected: (value) async {
                                if (value == 'deactivate') {
                                  await FirebaseFirestore.instance
                                      .collection(AppConstants.usersCollection)
                                      .doc(doc.id)
                                      .update({
                                    'status': AppConstants.statusInactive,
                                  });
                                } else {
                                  await FirebaseFirestore.instance
                                      .collection(AppConstants.usersCollection)
                                      .doc(doc.id)
                                      .update({'role': value});
                                }
                                if (context.mounted) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content: Text('Đã cập nhật người dùng'),
                                    ),
                                  );
                                }
                              },
                              itemBuilder: (context) => const [
                                PopupMenuItem(
                                  value: AppConstants.roleCustomer,
                                  child: Text('Đặt làm Khách hàng'),
                                ),
                                PopupMenuItem(
                                  value: AppConstants.roleSeller,
                                  child: Text('Đặt làm Seller'),
                                ),
                                PopupMenuItem(
                                  value: AppConstants.roleAdmin,
                                  child: Text('Đặt làm Admin'),
                                ),
                                PopupMenuItem(
                                  value: 'deactivate',
                                  child: Text('Tạm khóa'),
                                ),
                              ],
                              child: const Icon(Icons.more_horiz),
                            ),
                          ),
                        ],
                      );
                    }).toList(),
                  ),
                ),
        );
      },
    );
  }

  Color _roleColor(String role) {
    switch (role) {
      case AppConstants.roleAdmin:
        return const Color(0xFFF04438);
      case AppConstants.roleSeller:
        return const Color(0xFFF79009);
      default:
        return AdminTheme.accent;
    }
  }

  String _roleText(String role) {
    switch (role) {
      case AppConstants.roleAdmin:
        return 'Quản trị viên';
      case AppConstants.roleSeller:
        return 'Người bán';
      default:
        return 'Khách hàng';
    }
  }
}
