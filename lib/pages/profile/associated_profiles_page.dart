import 'dart:convert';
import 'package:flutter/material.dart';
import '../../models/user_model.dart';
import '../../theme/app_colors.dart';
import '../../api/user_api.dart';

class AssociatedProfile {
  final int id;
  final String managerId;
  final String influencerId;
  final String status; // 'active' o 'pending'
  final String? notes;
  final String nombre;
  final String apellido;
  final String email;
  final int? roleId;
  final String? sapCode;
  AssociatedProfile({
    required this.id,
    required this.managerId,
    required this.influencerId,
    required this.status,
    this.notes,
    required this.nombre,
    required this.apellido,
    required this.email,
    this.roleId,
    this.sapCode,
  });

  factory AssociatedProfile.fromApiData(Map<String, dynamic> json) {
    final influencer = json['influencer'] as Map<String, dynamic>? ?? {};

    return AssociatedProfile(
      id: json['ID'] ?? json['id'] ?? 0,
      managerId: json['MANAGER_ID'] ?? json['managerId'] ?? '',
      influencerId: json['INFLUENCER_ID'] ?? json['influencerId'] ?? '',
      status: (json['STATUS'] ?? json['status'] ?? 'active')
          .toString()
          .toLowerCase(),
      notes: json['NOTES'] ?? json['notes'],
      nombre: influencer['NAME'] ?? influencer['name'] ?? '',
      apellido: influencer['LASTNAME'] ?? influencer['lastName'] ?? '',
      email: influencer['EMAIL'] ?? influencer['email'] ?? '',
      roleId: influencer['ROLE_ID'] ?? influencer['roleId'],
      sapCode: influencer['SAP_CODE'] ?? influencer['sapCode'],
    );
  }

  String get estado {
    return status == 'active' ? 'activo' : 'pendiente';
  }
}

class AssociatedProfilesPage extends StatefulWidget {
  final UserModel user;

  const AssociatedProfilesPage({super.key, required this.user});

  @override
  State<AssociatedProfilesPage> createState() => _AssociatedProfilesPageState();
}

class _AssociatedProfilesPageState extends State<AssociatedProfilesPage> {
  List<AssociatedProfile> _profiles = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadProfiles();
  }

  Future<void> _loadProfiles() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final apiResponse = await UserApi.getMyInfluencers();

      if (apiResponse.success && mounted) {
        List<AssociatedProfile> profiles = [];

        // Intentar obtener desde apiResponse.data
        if (apiResponse.data != null) {
          if (apiResponse.data is List) {
            final dataList = apiResponse.data as List;
            for (var item in dataList) {
              if (item is Map<String, dynamic>) {
                profiles.add(AssociatedProfile.fromApiData(item));
              }
            }
          } else if (apiResponse.data is Map<String, dynamic>) {
            final data = apiResponse.data as Map<String, dynamic>;
            if (data.containsKey('data') && data['data'] is List) {
              final dataList = data['data'] as List;
              for (var item in dataList) {
                if (item is Map<String, dynamic>) {
                  profiles.add(AssociatedProfile.fromApiData(item));
                }
              }
            }
          }
        }

        // Si no está en data, intentar desde rawData
        if (profiles.isEmpty && apiResponse.rawData != null) {
          Map<String, dynamic>? actualData = apiResponse.rawData;

          if (apiResponse.rawData!.containsKey('body')) {
            final body = apiResponse.rawData!['body'];
            if (body is Map<String, dynamic>) {
              actualData = body;
            } else if (body is String) {
              try {
                actualData = jsonDecode(body) as Map<String, dynamic>?;
              } catch (e) {}
            }
          }

          if (actualData != null && actualData.containsKey('data')) {
            final data = actualData['data'];
            if (data is List) {
              for (var item in data) {
                if (item is Map<String, dynamic>) {
                  profiles.add(AssociatedProfile.fromApiData(item));
                }
              }
            }
          }
        }

        setState(() {
          _profiles = profiles;
          _isLoading = false;
        });
      } else {
        setState(() {
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.chevron_left),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: const Text(
          'Ver influenciadores',
          style: TextStyle(
            color: AppColors.textPrimary,
            fontSize: 18,
            fontFamily: 'ShellHeavy',
          ),
        ),
        centerTitle: false,
        titleSpacing: 0,
        backgroundColor: Colors.white,
        foregroundColor: AppColors.textPrimary,
        elevation: 0,
        iconTheme: const IconThemeData(color: AppColors.textPrimary),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _profiles.isEmpty
          ? _buildEmptyState()
          : ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              itemCount: _profiles.length,
              itemBuilder: (context, index) {
                final profile = _profiles[index];
                return _buildProfileListItem(profile, index);
              },
            ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              'Todavía no tienes asociados influenciadores',
              style: TextStyle(fontSize: 16, color: Colors.grey[600]),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProfileListItem(AssociatedProfile profile, int index) {
    final isPendiente = profile.estado == 'pendiente';
    final badgeColor = isPendiente
        ? AppColors.secondary.withValues(alpha: 0.3)
        : Colors.green.withValues(alpha: 0.2);

    return Padding(
      padding: const EdgeInsets.only(bottom: 16, right: 16, left: 16, top: 16),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  '${profile.nombre} ${profile.apellido}',
                  style: const TextStyle(
                    fontSize: 16,
                    fontFamily: 'ShellHeavy',
                    color: AppColors.textPrimary,
                  ),
                ),
                if (profile.sapCode != null) ...[
                  const SizedBox(height: 2),
                  Text(
                    'ID ${profile.sapCode}',
                    style: TextStyle(
                      fontSize: 14,
                      fontFamily: 'ShellBook',
                      color: Colors.grey[600],
                    ),
                  ),
                ],
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: badgeColor,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              profile.estado,
              style: TextStyle(
                fontSize: 12,
                fontFamily: 'ShellMedium',
                color: AppColors.textPrimary,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
