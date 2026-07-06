import 'package:flutter/material.dart';
import '../../theme/app_colors.dart';
import '../../api/user_api.dart';
import 'add_influencer_page.dart';
import 'associated_profiles_page.dart';

/// Modelo de un influenciador asociado a un manager (solo visualización).
class ManagerInfluencer {
  final String id;
  final String nombre;
  final String apellido;
  final String email;
  final String status;
  final String puntos;

  /// ID de la relación manager-influencer (para eliminar asociación).
  final int? associationId;

  ManagerInfluencer({
    required this.id,
    required this.nombre,
    required this.apellido,
    required this.email,
    required this.status,
    this.puntos = '0',
    this.associationId,
  });

  factory ManagerInfluencer.fromApiData(Map<String, dynamic> json) {
    final influencer = json['influencer'] as Map<String, dynamic>? ?? json;
    final rawStatus =
        json['STATUS'] ??
        json['status'] ??
        influencer['STATUS'] ??
        influencer['status'] ??
        'active';
    final status = rawStatus.toString().toLowerCase();

    // En manager-influencers/manager/{managerId}/influencers cada ítem trae un ID: es el id de la asociación para eliminar.
    int? associationId;
    final rawAssocId = json['ID'] ?? json['id'];
    if (rawAssocId != null) {
      associationId = rawAssocId is int
          ? rawAssocId
          : int.tryParse(rawAssocId.toString());
    }

    // Id del influenciador (no confundir con el ID de la asociación anterior).
    return ManagerInfluencer(
      id:
          (json['INFLUENCER_ID'] ??
                  json['influencerId'] ??
                  influencer['ID'] ??
                  influencer['id'] ??
                  '')
              .toString(),
      nombre:
          influencer['NAME'] ??
          influencer['name'] ??
          json['NAME'] ??
          json['name'] ??
          '',
      apellido:
          influencer['LASTNAME'] ??
          influencer['lastName'] ??
          json['LASTNAME'] ??
          json['lastName'] ??
          '',
      email:
          influencer['EMAIL'] ??
          influencer['email'] ??
          json['EMAIL'] ??
          json['email'] ??
          '',
      puntos:
          (influencer['puntos']?.toString() ??
          json['puntos']?.toString() ??
          '0'),
      status: status,
      associationId: associationId,
    );
  }

  String get estado => status == 'active' ? 'Activo' : 'Pendiente';
}

/// Pantalla de solo lectura: lista de influenciadores asociados a un manager.
/// El vendedor entra aquí al tocar un manager en la lista de Managers.
class ManagerInfluencersPage extends StatefulWidget {
  final String managerId;
  final String managerName;
  final String? managerSapCode;

  const ManagerInfluencersPage({
    super.key,
    required this.managerId,
    required this.managerName,
    this.managerSapCode,
  });

  @override
  State<ManagerInfluencersPage> createState() => _ManagerInfluencersPageState();
}

class _ManagerInfluencersPageState extends State<ManagerInfluencersPage> {
  List<ManagerInfluencer> _influencers = [];
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadInfluencers();
  }

  Future<void> _loadInfluencers() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final apiResponse = await UserApi.getInfluencersByManagerId(
        managerId: widget.managerId,
      );

      if (!mounted) return;

      List<ManagerInfluencer> list = [];

      if (apiResponse.success) {
        dynamic data = apiResponse.data;
        if (data == null && apiResponse.rawData != null) {
          final raw = apiResponse.rawData;
          if (raw is Map<String, dynamic> && raw.containsKey('data')) {
            data = raw['data'];
          }
        }
        if (data is List) {
          for (var item in data) {
            if (item is Map<String, dynamic>) {
              list.add(ManagerInfluencer.fromApiData(item));
            }
          }
        } else if (data is Map<String, dynamic> &&
            data.containsKey('data') &&
            data['data'] is List) {
          for (var item in data['data'] as List) {
            if (item is Map<String, dynamic>) {
              list.add(ManagerInfluencer.fromApiData(item));
            }
          }
        }
        list.sort((a, b) {
          final nameA = '${a.nombre} ${a.apellido}'.toLowerCase();
          final nameB = '${b.nombre} ${b.apellido}'.toLowerCase();
          return nameA.compareTo(nameB);
        });
      }

      if (!mounted) return;
      setState(() {
        _influencers = list;
        _errorMessage = apiResponse.success
            ? null
            : (apiResponse.message.isNotEmpty
                  ? apiResponse.message
                  : 'Error al cargar influenciadores');
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _errorMessage = 'Error de conexión: $e';
        _influencers = [];
        _isLoading = false;
      });
    }
  }

  Future<void> _handleRefresh() async {
    await _loadInfluencers();
  }

  Future<void> _confirmAndDeleteAssociation(ManagerInfluencer inf) async {
    if (inf.associationId == null) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'No se puede eliminar esta asociación. Falta el ID de relación.',
          ),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    final didConfirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Confirmar eliminación'),
        content: Text(
          '¿Estás seguro de que deseas eliminar la asociación de ${inf.nombre} ${inf.apellido} (${inf.email}) con este manager? Esta acción no se puede deshacer.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Eliminar'),
          ),
        ],
      ),
    );
    if (didConfirm != true || !mounted) return;

    try {
      final apiResponse = await UserApi.deleteInfluencerAssociation(
        associationId: inf.associationId!,
      );
      if (!mounted) return;
      if (apiResponse.success) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Asociación eliminada'),
            backgroundColor: Colors.green,
          ),
        );
        await _loadInfluencers();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              apiResponse.message.isNotEmpty
                  ? apiResponse.message
                  : 'Error al eliminar',
            ),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error de conexión: $e'),
          backgroundColor: Colors.red,
        ),
      );
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
        title: Text(
          widget.managerName,
          style: const TextStyle(
            color: AppColors.textPrimary,
            fontSize: 18,
            fontFamily: 'ShellHeavy',
          ),
          overflow: TextOverflow.ellipsis,
        ),
        centerTitle: false,
        titleSpacing: 0,
        backgroundColor: Colors.white,
        foregroundColor: AppColors.textPrimary,
        elevation: 0,
        iconTheme: const IconThemeData(color: AppColors.textPrimary),
      ),
      body: Column(
        children: [
          Expanded(
            child: RefreshIndicator(
              onRefresh: _handleRefresh,
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : _errorMessage != null
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.error_outline,
                            size: 64,
                            color: Colors.grey[400],
                          ),
                          const SizedBox(height: 16),
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 24),
                            child: Text(
                              _errorMessage!,
                              style: TextStyle(
                                fontSize: 16,
                                color: Colors.grey[600],
                                fontFamily: 'ShellBook',
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ),
                          const SizedBox(height: 24),
                          ElevatedButton(
                            onPressed: _loadInfluencers,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.secondary,
                              foregroundColor: AppColors.textPrimary,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(26),
                              ),
                            ),
                            child: const Text(
                              'Reintentar',
                              style: TextStyle(
                                fontSize: 16,
                                fontFamily: 'ShellHeavy',
                              ),
                            ),
                          ),
                        ],
                      ),
                    )
                  : _influencers.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.people_outline,
                            size: 64,
                            color: Colors.grey[400],
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'No hay influenciadores asociados',
                            style: TextStyle(
                              fontSize: 16,
                              color: Colors.grey[600],
                              fontFamily: 'ShellBook',
                            ),
                          ),
                        ],
                      ),
                    )
                  : ListView.separated(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 24,
                        vertical: 16,
                      ).copyWith(bottom: 16),
                      itemCount: _influencers.length,
                      separatorBuilder: (context, index) => Divider(
                        height: 1,
                        thickness: 1,
                        color: Colors.grey[300],
                      ),
                      itemBuilder: (context, index) {
                        final inf = _influencers[index];
                        final isActive = inf.status == 'active';
                        return Padding(
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          child: Row(
                            children: [
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      '${inf.nombre} ${inf.apellido}',
                                      style: const TextStyle(
                                        fontSize: 16,
                                        fontFamily: 'ShellHeavy',
                                        color: AppColors.textPrimary,
                                      ),
                                    ),
                                    if (inf.email.isNotEmpty) ...[
                                      const SizedBox(height: 4),
                                      Text(
                                        inf.email,
                                        style: TextStyle(
                                          fontSize: 14,
                                          fontFamily: 'ShellBook',
                                          color: Colors.grey[600],
                                        ),
                                      ),
                                    ],
                                    const SizedBox(height: 4),
                                    Text(
                                      '${inf.puntos} Puntos Disponibles',
                                      style: TextStyle(
                                        fontSize: 14,
                                        fontFamily: 'ShellBook',
                                        color: Colors.grey[600],
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 6,
                                ),
                                decoration: BoxDecoration(
                                  color: isActive
                                      ? Colors.green[100]
                                      : Colors.grey[200],
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                child: Text(
                                  inf.estado,
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontFamily: 'ShellBook',
                                    color: isActive
                                        ? Colors.green[800]
                                        : Colors.grey[700],
                                  ),
                                ),
                              ),
                              const SizedBox(width: 8),
                              IconButton(
                                icon: const Icon(
                                  Icons.delete_outline,
                                  color: Colors.red,
                                  size: 22,
                                ),
                                onPressed: () =>
                                    _confirmAndDeleteAssociation(inf),
                                tooltip: 'Eliminar asociación',
                                padding: EdgeInsets.zero,
                                constraints: const BoxConstraints(
                                  minWidth: 40,
                                  minHeight: 40,
                                ),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
            ),
          ),
          // Botón sticky: Asociar influenciador
          SafeArea(
            top: false,
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.fromLTRB(24, 12, 24, 16),
              decoration: BoxDecoration(
                color: Colors.white,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.06),
                    blurRadius: 8,
                    offset: const Offset(0, -2),
                  ),
                ],
              ),
              child: SizedBox(
                height: 50,
                child: ElevatedButton(
                  onPressed: () async {
                    await Navigator.push<void>(
                      context,
                      MaterialPageRoute(
                        builder: (context) => AddInfluencerPage(
                          managerId: widget.managerId,
                          managerSapCode: widget.managerSapCode,
                          onSave: (AssociatedProfile profile) {
                            if (mounted) _loadInfluencers();
                          },
                        ),
                      ),
                    );
                    if (mounted) _loadInfluencers();
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.secondary,
                    foregroundColor: AppColors.textPrimary,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(26),
                    ),
                    elevation: 0,
                  ),
                  child: const Text(
                    'Asociar influenciador',
                    style: TextStyle(fontSize: 16, fontFamily: 'ShellHeavy'),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
