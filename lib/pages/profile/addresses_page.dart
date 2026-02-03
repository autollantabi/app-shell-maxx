import 'dart:convert';
import 'package:flutter/material.dart';
import '../../models/user_model.dart';
import '../../theme/app_colors.dart';
import '../../api/user_api.dart';

class AddressesPage extends StatefulWidget {
  final UserModel user;

  const AddressesPage({super.key, required this.user});

  @override
  State<AddressesPage> createState() => _AddressesPageState();
}

class _AddressesPageState extends State<AddressesPage> {
  bool _isLoading = true;
  List<Map<String, dynamic>> _addresses = [];

  @override
  void initState() {
    super.initState();
    _loadAddresses();
  }

  Future<void> _loadAddresses() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final apiResponse = await UserApi.getUserAddress(widget.user.id);


      // Verificar success basado en status code o status field
      final isSuccess =
          apiResponse.success ||
          (apiResponse.rawData != null &&
              (apiResponse.rawData!.containsKey('statusCode') &&
                  apiResponse.rawData!['statusCode'] == 200));

      if (isSuccess && mounted) {
        List<Map<String, dynamic>> addresses = [];

        // Intentar obtener desde apiResponse.data (puede ser array o objeto)
        if (apiResponse.data != null) {
          if (apiResponse.data is List) {
            // Si es un array
            final dataList = apiResponse.data as List;
            for (var item in dataList) {
              if (item is Map<String, dynamic>) {
                addresses.add(item);
              }
            }
          } else if (apiResponse.data is Map<String, dynamic>) {
            // Si es un objeto único, convertirlo a array
            final data = apiResponse.data as Map<String, dynamic>;
            if (data.containsKey('ID_ADDRESS') || data.containsKey('ID_USER')) {
              addresses.add(data);
            }
          }
        }

        // Si no está en data, intentar desde rawData
        if (addresses.isEmpty && apiResponse.rawData != null) {
          // Primero verificar si rawData tiene 'body' (respuesta envuelta)
          Map<String, dynamic>? actualData = apiResponse.rawData;
          if (apiResponse.rawData!.containsKey('body')) {
            final body = apiResponse.rawData!['body'];
            if (body is Map<String, dynamic>) {
              actualData = body;
            } else if (body is String) {
              try {
                actualData = jsonDecode(body) as Map<String, dynamic>?;
              } catch (e) {
              }
            }
          }

          // Buscar 'data' en el JSON real
          if (actualData != null && actualData.containsKey('data')) {
            final data = actualData['data'];
            if (data is List) {
              // Si es un array
              for (var item in data) {
                if (item is Map<String, dynamic>) {
                  addresses.add(item);
                }
              }
            } else if (data is Map<String, dynamic>) {
              // Si es un objeto único
              if (data.containsKey('ID_ADDRESS') ||
                  data.containsKey('ID_USER')) {
                addresses.add(data);
              }
            }
          }
        }

        setState(() {
          _addresses = addresses;
        });

      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Widget _buildAddressCard(Map<String, dynamic> address) {
    final province = address['PROVINCE']?.toString() ?? '';
    final city = address['CITY']?.toString() ?? '';
    final street = address['ADDRESS']?.toString() ?? '';
    final phone = address['PHONE']?.toString() ?? '';
    final deliveryInstructions =
        address['DELIVERY_INSTRUCTIONS']?.toString() ?? '';

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 1,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: Colors.grey[200]!, width: 1),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Icono y título
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    Icons.location_on,
                    color: AppColors.primary,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 12),
                const Expanded(
                  child: Text(
                    'Dirección de envío',
                    style: TextStyle(
                      fontSize: 14,
                      fontFamily: 'ShellMedium',
                      color: Colors.grey,
                      letterSpacing: 0.5,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Dirección principal
            if (street.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Text(
                  street,
                  style: const TextStyle(
                    fontSize: 16,
                    fontFamily: 'ShellHeavy',
                    color: Colors.black87,
                    height: 1.4,
                  ),
                ),
              ),

            // Ciudad y Provincia
            if (city.isNotEmpty || province.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Row(
                  children: [
                    if (city.isNotEmpty) ...[
                      Icon(
                        Icons.location_city,
                        size: 16,
                        color: Colors.grey[600],
                      ),
                      const SizedBox(width: 6),
                      Text(
                        city,
                        style: TextStyle(
                          fontSize: 14,
                          fontFamily: 'ShellMedium',
                          color: Colors.grey[700],
                        ),
                      ),
                    ],
                    if (city.isNotEmpty && province.isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 8),
                        child: Container(
                          width: 4,
                          height: 4,
                          decoration: BoxDecoration(
                            color: Colors.grey[400],
                            shape: BoxShape.circle,
                          ),
                        ),
                      ),
                    if (province.isNotEmpty) ...[
                      Icon(Icons.map, size: 16, color: Colors.grey[600]),
                      const SizedBox(width: 6),
                      Text(
                        province,
                        style: TextStyle(
                          fontSize: 14,
                          fontFamily: 'ShellMedium',
                          color: Colors.grey[700],
                        ),
                      ),
                    ],
                  ],
                ),
              ),

            // Divider
            if (phone.isNotEmpty || deliveryInstructions.isNotEmpty)
              Divider(height: 24, thickness: 1, color: Colors.grey[200]),

            // Teléfono
            if (phone.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Row(
                  children: [
                    Icon(
                      Icons.phone_outlined,
                      size: 18,
                      color: Colors.grey[600],
                    ),
                    const SizedBox(width: 10),
                    Text(
                      phone,
                      style: TextStyle(
                        fontSize: 14,
                        fontFamily: 'ShellMedium',
                        color: Colors.grey[800],
                      ),
                    ),
                  ],
                ),
              ),

            // Instrucciones de entrega
            if (deliveryInstructions.isNotEmpty) ...[
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(
                      Icons.note_outlined,
                      size: 18,
                      color: Colors.grey[600],
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Instrucciones de entrega:',
                            style: TextStyle(
                              fontSize: 12,
                              fontFamily: 'ShellMedium',
                              color: Colors.grey[600],
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            deliveryInstructions,
                            style: TextStyle(
                              fontSize: 14,
                              fontFamily: 'Shell',
                              color: Colors.grey[800],
                              height: 1.4,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
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
          'Mis direcciones',
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
          : _addresses.isEmpty
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.location_off, size: 64, color: Colors.grey[400]),
                  const SizedBox(height: 16),
                  Text(
                    'No tienes direcciones guardadas',
                    style: TextStyle(fontSize: 16, color: Colors.grey[600]),
                  ),
                ],
              ),
            )
          : ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
              itemCount: _addresses.length,
              itemBuilder: (context, index) {
                final address = _addresses[index];
                return _buildAddressCard(address);
              },
            ),
    );
  }
}

