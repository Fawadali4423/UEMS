import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:provider/provider.dart';
import 'package:uems/app/theme.dart';
import 'package:uems/core/widgets/glassmorphism_card.dart';
import 'package:uems/features/auth/data/user_repository.dart';
import 'package:uems/features/auth/domain/models/user_model.dart';

/// Admin screen to manage organizers and assign permissions
class ManageOrganizersScreen extends StatefulWidget {
  const ManageOrganizersScreen({super.key});

  @override
  State<ManageOrganizersScreen> createState() => _ManageOrganizersScreenState();
}

class _ManageOrganizersScreenState extends State<ManageOrganizersScreen> {
  final UserRepository _userRepository = UserRepository();
  final TextEditingController _searchController = TextEditingController();
  
  List<UserModel> _allUsers = [];
  List<UserModel> _filteredUsers = [];
  bool _isLoading = true;
  String _filterRole = 'all'; // all, student, organizer

  @override
  void initState() {
    super.initState();
    _loadUsers();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadUsers() async {
    setState(() => _isLoading = true);
    try {
      _allUsers = await _userRepository.getAllUsers();
      _filteredUsers = _allUsers;
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading users: $e')),
        );
      }
    }
    setState(() => _isLoading = false);
  }

  void _filterUsers(String query) {
    setState(() {
      _filteredUsers = _allUsers.where((user) {
        final matchesSearch = user.name.toLowerCase().contains(query.toLowerCase()) ||
            (user.email.toLowerCase().contains(query.toLowerCase())) ||
            (user.rollNumber?.toLowerCase().contains(query.toLowerCase()) ?? false);
        
        final matchesRole = _filterRole == 'all' ||
            ((_filterRole == 'organizer' && user.isOrganizer) ||
             (_filterRole == 'student' && user.isStudent));
        
        return matchesSearch && matchesRole && !user.isAdmin;
      }).toList();
    });
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: isDark ? AppTheme.darkGradient : null,
          color: isDark ? null : Colors.grey[100],
        ),
        child: SafeArea(
          child: Column(
            children: [
              _buildHeader(isDark),
              _buildSearchAndFilter(isDark),
              const SizedBox(height: 16),
              _buildStats(isDark),
              const SizedBox(height: 16),
              Expanded(
                child: _isLoading
                    ? const Center(child: CircularProgressIndicator())
                    : _buildUsersList(isDark),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(bool isDark) {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Row(
        children: [
          IconButton(
            onPressed: () => Navigator.pop(context),
            icon: Icon(
              Icons.arrow_back_ios_rounded,
              color: isDark ? Colors.white : Colors.grey[800],
            ),
          ),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Manage Organizers',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: isDark ? Colors.white : Colors.grey[900],
                  ),
                ),
                Text(
                  'Assign roles & permissions',
                  style: TextStyle(
                    fontSize: 14,
                    color: isDark ? Colors.grey[400] : Colors.grey[600],
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            onPressed: _loadUsers,
            icon: Icon(
              Icons.refresh_rounded,
              color: isDark ? Colors.white : Colors.grey[800],
            ),
          ),
        ],
      ),
    ).animate().fadeIn().slideY(begin: -0.1, end: 0);
  }

  Widget _buildSearchAndFilter(bool isDark) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Row(
        children: [
          Expanded(
            flex: 2,
            child: GlassmorphismCard(
              padding: EdgeInsets.zero,
              child: TextField(
                controller: _searchController,
                onChanged: _filterUsers,
                style: TextStyle(color: isDark ? Colors.white : Colors.grey[900]),
                decoration: InputDecoration(
                  hintText: 'Search by name, email, or roll number',
                  prefixIcon: Icon(Icons.search_rounded, color: AppTheme.primaryColor),
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.all(16),
                  hintStyle: TextStyle(color: isDark ? Colors.grey[600] : Colors.grey[400]),
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          GlassmorphismCard(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: DropdownButtonHideUnderline(
              child: DropdownButton<String>(
                value: _filterRole,
                icon: Icon(Icons.filter_list_rounded, color: AppTheme.primaryColor, size: 20),
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: isDark ? Colors.white : Colors.grey[900],
                ),
                dropdownColor: isDark ? const Color(0xFF2D2D44) : Colors.white,
                items: const [
                  DropdownMenuItem(value: 'all', child: Text('All')),
                  DropdownMenuItem(value: 'student', child: Text('Students')),
                  DropdownMenuItem(value: 'organizer', child: Text('Organizers')),
                ],
                onChanged: (value) {
                  setState(() => _filterRole = value!);
                  _filterUsers(_searchController.text);
                },
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStats(bool isDark) {
    final organizers = _allUsers.where((u) => u.isOrganizer).length;
    final students = _allUsers.where((u) => u.isStudent).length;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Row(
        children: [
          Expanded(
            child: _buildStatCard(
              'Organizers',
              organizers.toString(),
              Icons.admin_panel_settings_rounded,
              AppTheme.primaryColor,
              isDark,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: _buildStatCard(
              'Students',
              students.toString(),
              Icons.school_rounded,
              AppTheme.accentColor,
              isDark,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard(String label, String value, IconData icon, Color color, bool isDark) {
    return GlassmorphismCard(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: color.withOpacity(0.2),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: color, size: 20),
          ),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                value,
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: isDark ? Colors.white : Colors.grey[900],
                ),
              ),
              Text(
                label,
                style: TextStyle(
                  fontSize: 12,
                  color: isDark ? Colors.grey[400] : Colors.grey[600],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildUsersList(bool isDark) {
    if (_filteredUsers.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.person_search_rounded,
              size: 64,
              color: isDark ? Colors.grey[700] : Colors.grey[400],
            ),
            const SizedBox(height: 16),
            Text(
              'No users found',
              style: TextStyle(
                fontSize: 16,
                color: isDark ? Colors.grey[500] : Colors.grey[600],
              ),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      itemCount: _filteredUsers.length,
      itemBuilder: (context, index) {
        return _buildUserCard(_filteredUsers[index], isDark, index);
      },
    );
  }

  Widget _buildUserCard(UserModel user, bool isDark, int index) {
    return GlassmorphismCard(
      margin: const EdgeInsets.only(bottom: 12),
      onTap: () => _showPermissionsDialog(user),
      child: Row(
        children: [
          // Avatar
          Container(
            width: 50,
            height: 50,
            decoration: BoxDecoration(
              gradient: user.isOrganizer 
                  ? AppTheme.primaryGradient 
                  : LinearGradient(colors: [Colors.grey[600]!, Colors.grey[700]!]),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Center(
              child: Text(
                user.name.substring(0, 1).toUpperCase(),
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ),
          ),
          const SizedBox(width: 14),
          // Info
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  user.name,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: isDark ? Colors.white : Colors.grey[900],
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  user.rollNumber ?? user.email,
                  style: TextStyle(
                    fontSize: 12,
                    color: isDark ? Colors.grey[400] : Colors.grey[600],
                  ),
                ),
                if (user.isOrganizer && user.permissions.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Wrap(
                    spacing: 4,
                    children: user.permissions.take(2).map((perm) {
                      return Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: AppTheme.primaryColor.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          _formatPermission(perm),
                          style: TextStyle(
                            fontSize: 10,
                            color: AppTheme.primaryColor,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                ],
              ],
            ),
          ),
          // Role badge
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: user.isOrganizer 
                  ? AppTheme.primaryColor.withOpacity(0.2)
                  : (isDark ? Colors.white.withOpacity(0.05) : Colors.grey[200]),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              user.isOrganizer ? 'Organizer' : 'Student',
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: user.isOrganizer ? AppTheme.primaryColor : (isDark ? Colors.grey[400] : Colors.grey[600]),
              ),
            ),
          ),
        ],
      ),
    ).animate(delay: Duration(milliseconds: 50 * index))
        .fadeIn()
        .slideX(begin: 0.05, end: 0);
  }

  String _formatPermission(String perm) {
    return perm.replaceAll('_', ' ').split(' ').map((word) => 
      word[0].toUpperCase() + word.substring(1)
    ).join(' ');
  }

  Future<void> _showPermissionsDialog(UserModel user) async {
    final permissions = <String>{
      'create_event',
      'scan_qr',
      'manage_finance',
      'approve_event',
      'manage_certificates',
    };

    final selectedPermissions = Set<String>.from(user.permissions);
    bool isOrganizer = user.isOrganizer;

    await showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            final isDark = Theme.of(context).brightness == Brightness.dark;
            
            return Dialog(
              backgroundColor: Colors.transparent,
              child: Container(
                constraints: const BoxConstraints(maxWidth: 400),
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF1a1a2e) : Colors.white,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            width: 50,
                            height: 50,
                            decoration: BoxDecoration(
                              gradient: AppTheme.primaryGradient,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Center(
                              child: Text(
                                user.name.substring(0, 1).toUpperCase(),
                                style: const TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                  color:Colors.white,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  user.name,
                                  style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                    color: isDark ? Colors.white : Colors.grey[900],
                                  ),
                                ),
                                Text(
                                  user.email,
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: isDark ? Colors.grey[400] : Colors.grey[600],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 24),
                      // Role toggle
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: isDark ? Colors.white.withOpacity(0.05) : Colors.grey[100],
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          children: [
                            Icon(Icons.admin_panel_settings_rounded, color: AppTheme.primaryColor),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                'Organizer Role',
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                  color: isDark ? Colors.white : Colors.grey[900],
                                ),
                              ),
                            ),
                            Switch(
                              value: isOrganizer,
                              onChanged: (value) {
                                setDialogState(() {
                                  isOrganizer = value;
                                  if (!value) selectedPermissions.clear();
                                });
                              },
                              activeColor: AppTheme.primaryColor,
                            ),
                          ],
                        ),
                      ),
                      if (isOrganizer) ...[
                        const SizedBox(height: 16),
                        Text(
                          'Permissions',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: isDark ? Colors.white : Colors.grey[900],
                          ),
                        ),
                        const SizedBox(height: 12),
                        ...permissions.map((perm) {
                          return CheckboxListTile(
                            title: Text(
                              _formatPermission(perm),
                              style: TextStyle(
                                fontSize: 14,
                                color: isDark ? Colors.white : Colors.grey[900],
                              ),
                            ),
                            value: selectedPermissions.contains(perm),
                            onChanged: (value) {
                              setDialogState(() {
                                if (value!) {
                                  selectedPermissions.add(perm);
                                } else {
                                  selectedPermissions.remove(perm);
                                }
                              });
                            },
                            activeColor: AppTheme.primaryColor,
                            contentPadding: EdgeInsets.zero,
                            dense: true,
                          );
                        }),
                      ],
                      const SizedBox(height: 24),
                      // Buttons
                      Row(
                        children: [
                          Expanded(
                            child: OutlinedButton(
                              onPressed: () => Navigator.pop(context),
                              style: OutlinedButton.styleFrom(
                                side: BorderSide(color: isDark ? Colors.grey[700]! : Colors.grey[300]!),
                                padding: const EdgeInsets.symmetric(vertical: 14),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                              child: Text(
                                'Cancel',
                                style: TextStyle(color: isDark ? Colors.white : Colors.grey[900]),
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: ElevatedButton(
                              onPressed: () async {
                                await _savePermissions(user, isOrganizer, selectedPermissions.toList());
                                if (context.mounted) Navigator.pop(context);
                              },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppTheme.primaryColor,
                                padding: const EdgeInsets.symmetric(vertical: 14),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                              child: const Text(
                                'Save',
                                style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }

  Future<void> _savePermissions(UserModel user, bool isOrganizer, List<String> permissions) async {
    try {
      await _userRepository.updateUser(user.uid, {
        'role': isOrganizer ? 'organizer' : 'student',
        'permissions': permissions,
      });
      
      await _loadUsers();
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Permissions updated for ${user.name}'),
            backgroundColor: AppTheme.successColor,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: AppTheme.errorColor,
          ),
        );
      }
    }
  }
}
