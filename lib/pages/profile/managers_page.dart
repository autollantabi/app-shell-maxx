import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import '../../theme/app_colors.dart';
import '../../models/user_model.dart';
import '../../api/user_api.dart';
import 'manager_influencers_page.dart';

class ManagersPage extends StatefulWidget {
  final UserModel user;

  const ManagersPage({super.key, required this.user});

  @override
  State<ManagersPage> createState() => _ManagersPageState();
}

class _ManagersPageState extends State<ManagersPage> {
  List<Map<String, dynamic>> _managers = [];
  bool _isLoading = true;
  String? _errorMessage;
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _loadManagers();
    _searchController.addListener(() {
      setState(() {
        _searchQuery = _searchController.text.trim().toLowerCase();
      });
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  List<Map<String, dynamic>> get _filteredManagers {
    if (_searchQuery.isEmpty) return _managers;
    return _managers
        .where(
          (m) =>
              (m['name'] as String?)
                  ?.toLowerCase()
                  .contains(_searchQuery) ??
              false,
        )
        .toList();
  }

  Future<void> _loadManagers() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final apiResponse = await UserApi.getVendedorManagers();
      if (!mounted) return;

      // Usar rawData si data es null
      Map<String, dynamic>? data = apiResponse.data;
      if (data == null && apiResponse.rawData != null) {
        try {
          final rawDataMap = apiResponse.rawData as Map<String, dynamic>;
          if (rawDataMap.containsKey('data') && rawDataMap['data'] is Map) {
            data = rawDataMap['data'] as Map<String, dynamic>;
          }
        } catch (e) {
          debugPrint('Error al extraer data de rawData: $e');
        }
      }

      if (apiResponse.success && data != null) {
        final managersData = data['managers'] as List<dynamic>?;

        if (managersData != null) {
          final list = managersData
              .map(
                (manager) => {
                  'userId':
                      (manager['userId'] ??
                              manager['id'] ??
                              manager['managerId'] ??
                              '')
                          .toString(),
                  'name': manager['name'] as String? ?? 'Sin nombre',
                  'isRegistered': manager['isRegistered'] as bool? ?? false,
                },
              )
              .toList()
              .cast<Map<String, dynamic>>();
          list.sort((a, b) {
            final nameA = (a['name'] as String).toLowerCase();
            final nameB = (b['name'] as String).toLowerCase();
            return nameA.compareTo(nameB);
          });
          setState(() {
            _managers = list;
            _isLoading = false;
          });
        } else {
          setState(() {
            _managers = [];
            _isLoading = false;
          });
        }
      } else {
        setState(() {
          _errorMessage = apiResponse.message.isNotEmpty
              ? apiResponse.message
              : 'Error al cargar los managers';
          _isLoading = false;
        });
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _errorMessage = 'Error de conexión: $e';
        _isLoading = false;
      });
    }
  }

  Future<void> _handleRefresh() async {
    await _loadManagers();
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
          'Managers',
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
      body: RefreshIndicator(
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
                        Text(
                          _errorMessage!,
                          style: TextStyle(
                            fontSize: 16,
                            color: Colors.grey[600],
                            fontFamily: 'ShellBook',
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 24),
                        ElevatedButton(
                          onPressed: _loadManagers,
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
                : _managers.isEmpty
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
                              'No hay managers asociados',
                              style: TextStyle(
                                fontSize: 16,
                                color: Colors.grey[600],
                                fontFamily: 'ShellBook',
                              ),
                            ),
                          ],
                        ),
                      )
                    : Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          // Barra de búsqueda
                          Padding(
                            padding: const EdgeInsets.fromLTRB(24, 16, 24, 8),
                            child: TextField(
                              controller: _searchController,
                              decoration: InputDecoration(
                                hintText: 'Buscar por nombre...',
                                hintStyle: TextStyle(
                                  fontSize: 14,
                                  color: Colors.grey[500],
                                  fontFamily: 'ShellBook',
                                ),
                                prefixIcon: Icon(
                                  Icons.search,
                                  color: Colors.grey[500],
                                  size: 22,
                                ),
                                suffixIcon: _searchQuery.isNotEmpty
                                    ? IconButton(
                                        icon: const Icon(Icons.clear),
                                        onPressed: () {
                                          _searchController.clear();
                                        },
                                        color: Colors.grey[600],
                                      )
                                    : null,
                                filled: true,
                                fillColor: Colors.grey[100],
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: BorderSide.none,
                                ),
                                contentPadding: const EdgeInsets.symmetric(
                                  horizontal: 16,
                                  vertical: 12,
                                ),
                              ),
                              style: const TextStyle(
                                fontSize: 16,
                                fontFamily: 'ShellBook',
                              ),
                            ),
                          ),
                          Expanded(
                            child: _filteredManagers.isEmpty
                                ? Center(
                                    child: Column(
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      children: [
                                        Icon(
                                          Icons.search_off,
                                          size: 64,
                                          color: Colors.grey[400],
                                        ),
                                        const SizedBox(height: 16),
                                        Text(
                                          'Ningún manager coincide con la búsqueda',
                                          style: TextStyle(
                                            fontSize: 16,
                                            color: Colors.grey[600],
                                            fontFamily: 'ShellBook',
                                          ),
                                          textAlign: TextAlign.center,
                                        ),
                                      ],
                                    ),
                                  )
                                : ListView.separated(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 24,
                                      vertical: 8,
                                    ),
                                    itemCount: _filteredManagers.length,
                                    separatorBuilder: (context, index) =>
                                        Divider(
                                            height: 1,
                                            thickness: 1,
                                            color: Colors.grey[300]),
                                    itemBuilder: (context, index) {
                                      final manager =
                                          _filteredManagers[index];
                                      final userId =
                                          manager['userId'] as String;
                                      final name =
                                          manager['name'] as String;
                                      final isRegistered =
                                          manager['isRegistered'] as bool;

                                      return ListTile(
                                        contentPadding: EdgeInsets.zero,
                                        title: Text(
                                          name,
                                          style: const TextStyle(
                                            fontSize: 16,
                                            fontFamily: 'ShellBook',
                                          ),
                                        ),
                                        trailing: Row(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            Container(
                                              padding: const EdgeInsets
                                                  .symmetric(
                                                horizontal: 12,
                                                vertical: 6,
                                              ),
                                              decoration: BoxDecoration(
                                                color: isRegistered
                                                    ? Colors.green[100]
                                                    : Colors.grey[200],
                                                borderRadius:
                                                    BorderRadius.circular(20),
                                              ),
                                              child: Text(
                                                isRegistered
                                                    ? 'Activo'
                                                    : 'Inactivo',
                                                style: TextStyle(
                                                  fontSize: 12,
                                                  fontFamily: 'ShellBook',
                                                  color: isRegistered
                                                      ? Colors.green[800]
                                                      : Colors.grey[700],
                                                ),
                                              ),
                                            ),
                                            const SizedBox(width: 8),
                                            Icon(
                                              Icons.chevron_right,
                                              color: Colors.grey[400],
                                              size: 20,
                                            ),
                                          ],
                                        ),
                                        onTap: userId.isEmpty
                                            ? null
                                            : () {
                                                Navigator.push(
                                                  context,
                                                  MaterialPageRoute(
                                                    builder: (context) =>
                                                        ManagerInfluencersPage(
                                                      managerId: userId,
                                                      managerName: name,
                                                    ),
                                                  ),
                                                );
                                              },
                                      );
                                    },
                                ),
                          ),
                        ],
                      ),
      ),
    );
  }
}
