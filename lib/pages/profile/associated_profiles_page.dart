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
  final int puntos;

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
    this.puntos = 0,
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
      puntos: int.tryParse(
            (influencer['puntos'] ?? json['puntos'] ?? 0).toString(),
          ) ??
          0,
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
      final apiResponse = await UserApi.getInfluencersByManagerId(
        managerId: widget.user.id,
      );

      if (apiResponse.success && mounted) {
        List<AssociatedProfile> profiles = [];

        dynamic raw = apiResponse.data;

        // El endpoint devuelve {status, message, data: [...]}
        // ApiResponse puede poner el array directamente en data o en rawData
        if (raw is List) {
          for (var item in raw) {
            if (item is Map<String, dynamic>) {
              profiles.add(AssociatedProfile.fromApiData(item));
            }
          }
        } else if (raw is Map<String, dynamic> && raw.containsKey('data')) {
          final list = raw['data'];
          if (list is List) {
            for (var item in list) {
              if (item is Map<String, dynamic>) {
                profiles.add(AssociatedProfile.fromApiData(item));
              }
            }
          }
        }

        // Fallback: buscar en rawData si data no contenía los items
        if (profiles.isEmpty && apiResponse.rawData != null) {
          final rawData = apiResponse.rawData!;
          dynamic dataField = rawData['data'];

          if (dataField is String) {
            try {
              dataField = jsonDecode(dataField);
            } catch (_) {}
          }

          if (dataField is List) {
            for (var item in dataField) {
              if (item is Map<String, dynamic>) {
                profiles.add(AssociatedProfile.fromApiData(item));
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
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
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
                if (profile.email.isNotEmpty) ...[
                  const SizedBox(height: 2),
                  Text(
                    profile.email,
                    style: TextStyle(
                      fontSize: 13,
                      fontFamily: 'ShellBook',
                      color: Colors.grey[600],
                    ),
                  ),
                ],
                const SizedBox(height: 2),
                Text(
                  '${profile.puntos} Puntos Disponibles',
                  style: TextStyle(
                    fontSize: 13,
                    fontFamily: 'ShellBook',
                    color: Colors.grey[500],
                  ),
                ),
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
