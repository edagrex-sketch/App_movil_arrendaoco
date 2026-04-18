import 'package:flutter/material.dart';
import 'package:arrendaoco/theme/tema.dart';
import 'package:arrendaoco/theme/app_gradients.dart';
import 'package:arrendaoco/sensors/ubicacion.dart';
import 'package:geolocator/geolocator.dart';
import 'package:image_picker/image_picker.dart';
import 'package:arrendaoco/widgets/map_preview_osm.dart';
import 'package:arrendaoco/widgets/lottie_loading.dart';
import 'package:arrendaoco/widgets/lottie_feedback.dart';
import 'package:arrendaoco/view/widgets/imagen_dinamica.dart';
import 'package:arrendaoco/widgets/stunning_widgets.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:arrendaoco/services/api_service.dart';
import 'package:dio/dio.dart' as dio;
import 'dart:convert';
import 'package:flutter/services.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:path/path.dart' as p;
import 'package:device_info_plus/device_info_plus.dart';
import 'dart:io';

class RegistrarInmuebleScreen extends StatefulWidget {
  final String propietarioId;
  final Map<String, dynamic>? inmuebleData;
  final String? inmuebleId;

  const RegistrarInmuebleScreen({
    super.key,
    required this.propietarioId,
    this.inmuebleData,
    this.inmuebleId,
  });

  @override
  State<RegistrarInmuebleScreen> createState() =>
      _RegistrarInmuebleScreenState();
}

class _RegistrarInmuebleScreenState extends State<RegistrarInmuebleScreen>
    with SingleTickerProviderStateMixin {
  final ApiService _api = ApiService();
  final _pageController = PageController();
  final _mapController = MapController();
  int _currentStep = 0;

  // FORM KEYS PER STEP
  final List<GlobalKey<FormState>> _formKeys = [
    GlobalKey<FormState>(),
    GlobalKey<FormState>(),
    GlobalKey<FormState>(),
    GlobalKey<FormState>(),
  ];

  // CONTROLLERS
  final _tituloController = TextEditingController();
  final _descripcionController = TextEditingController();
  final _precioController = TextEditingController();
  final _depositoController = TextEditingController();
  final _direccionController = TextEditingController();
  final _largoController = TextEditingController();
  final _anchoController = TextEditingController();
  final _clabeController = TextEditingController();
  final _clausulasController = TextEditingController();
  final _toleranciaController = TextEditingController(text: '2');
  final _preavisoController = TextEditingController(text: '30');
  final _duracionController = TextEditingController(text: '12');
  int _palabrasDescripcion = 0;

  // STATE DATA
  String? _categoriaSeleccionada = 'Casa';
  bool _requiereDeposito = false;
  
  // STEP 2
  int _camas = 1;
  int _banos = 1;
  int _mediosBanos = 0;
  String _banoSeleccionadoStr = '1 Baño Completo';
  Position? _ubicacionActual;

  // STEP 3
  String _mobiliario = 'No amueblado';
  bool _estacionamientoIncluido = false;
  bool _permiteMascotas = false;
  List<String> _tiposMascotasPermitidas = [];
  List<String> _serviciosSeleccionados = [];
  Map<String, String> _pagoServiciosResponsables = {}; // {Servicio: Inquilino/Arrendador}
  String _momentoPago = 'Por adelantado';
  int _duracionContrato = 12;
  bool _incluirClausulas = false;
  String? _bancoSeleccionado;

  // STEP 4
  List<XFile> _imagenesSeleccionadas = [];

  final List<String> _categorias = ['Casa', 'Departamento', 'Cuarto'];
  final List<String> _opcionesBanos = [
    'Medio Baño',
    '1 Baño Completo',
    '1 Baño Completo y Medio Baño',
    '2 Baños Completos',
    '2 Baños Completos y Medio Baño',
    '3 Baños Completos',
    '3 Baños Completos y Medio Baño',
    '4 Baños o más'
  ];
  final List<String> _listaTiposMascotas = [
    'Perros', 'Gatos', 'Pericos y loros', 'Pájaros de canto', 'Peces', 'Hamsters y ratones', 'Conejos', 'Tortugas', 'Iguanas', 'Serpientes', 'Ranas y ajolotes', 'Hurones', 'Arañas', 'Cuyos', 'Pollos', 'Otros'
  ];
  final List<String> _serviciosDisponibles = ['Agua', 'Luz', 'Internet', 'Gas', 'TV por Cable'];
  final List<String> _bancos = ['BBVA', 'Banamex', 'Santander', 'Banorte', 'HSBC', 'Coppel', 'Azteca'];

  @override
  void initState() {
    super.initState();
    if (widget.inmuebleData != null) {
      _cargarDatosInmueble();
    }
    _descripcionController.addListener(_actualizarContadorPalabras);
    _duracionController.addListener(() {
      final val = int.tryParse(_duracionController.text);
      if (val != null) setState(() => _duracionContrato = val);
    });
  }

  void _actualizarContadorPalabras() {
    final texto = _descripcionController.text.trim();
    if (texto.isEmpty) {
      setState(() => _palabrasDescripcion = 0);
      return;
    }
    setState(() {
      _palabrasDescripcion = texto.split(RegExp(r'\s+')).length;
    });
  }

  void _cargarDatosInmueble() {
    final data = widget.inmuebleData!;
    _tituloController.text = data['titulo'] ?? '';
    _descripcionController.text = data['descripcion'] ?? '';
    _precioController.text = data['renta_mensual']?.toString() ?? '';
    _depositoController.text = data['deposito']?.toString() ?? '';
    _direccionController.text = data['direccion'] ?? 'Ocosingo, Chiapas';
    _categoriaSeleccionada = data['tipo'];
    _camas = (data['habitaciones'] as num?)?.toInt() ?? 1;
    _banos = (data['banos'] as num?)?.toInt() ?? 1;
    _requiereDeposito = data['requiere_deposito'] == 1;
    _mobiliario = data['estado_mobiliario'] ?? 'No amueblado';
    _clabeController.text = data['clabe_interbancaria'] ?? '';
    _bancoSeleccionado = data['banco'];
    
    // Lat/Lng
    if (data['latitud'] != null && data['longitud'] != null) {
      _ubicacionActual = Position(
        latitude: double.parse(data['latitud'].toString()),
        longitude: double.parse(data['longitud'].toString()),
        timestamp: DateTime.now(),
        accuracy: 0, altitude: 0, heading: 0, speed: 0, speedAccuracy: 0,
        altitudeAccuracy: 0, headingAccuracy: 0,
      );
    }
  }

  Future<void> _obtenerUbicacion() async {
    LottieLoading.showLoadingDialog(context, message: 'Obteniendo ubicación...');
    try {
      final pos = await obtenerUbicacionActual();
      if (!mounted) return;
      LottieLoading.hideLoadingDialog(context);
      setState(() {
        _ubicacionActual = pos;
      });
    } catch (e) {
      if (!mounted) return;
      LottieLoading.hideLoadingDialog(context);
      LottieFeedback.showError(context, message: 'No se pudo obtener la ubicación');
    }
  }

  Future<void> _buscarDireccionManual() async {
    final query = _direccionController.text.trim();
    if (query.isEmpty) {
      LottieFeedback.showError(context, message: 'Escribe una dirección (calle, colonia o lugar)');
      return;
    }

    LottieLoading.showLoadingDialog(context, message: 'Buscando en Ocosingo...');
    try {
      final dioClient = dio.Dio(dio.BaseOptions(
        connectTimeout: const Duration(seconds: 15),
        receiveTimeout: const Duration(seconds: 15),
      ));

      // Bounding box aproximado de Ocosingo para priorizar resultados locales
      // format: viewbox=left,top,right,bottom (lon,lat,lon,lat)
      const String viewbox = '-92.15,17.05,-92.05,16.85'; 

      final response = await dioClient.get(
        'https://nominatim.openstreetmap.org/search',
        options: dio.Options(
          headers: {
            'User-Agent': 'ArrendaOco_Property_Locator/1.2',
            'Accept-Language': 'es',
          },
        ),
        queryParameters: {
          'q': '$query, Ocosingo, Chiapas',
          'format': 'jsonv2',
          'limit': 1,
          'viewbox': viewbox,
          'bounded': 1, // Restringir a Ocosingo
        },
      );

      if (!mounted) return;

      dynamic data = response.data;
      
      // Fallback: Si no hay resultados restringidos, buscar de forma más amplia
      if (data == null || (data is List && data.isEmpty)) {
        print('⚠️ No results in bounded box, trying broad search...');
        final broadResponse = await dioClient.get(
          'https://nominatim.openstreetmap.org/search',
          options: dio.Options(headers: {'User-Agent': 'ArrendaOco_Property_Locator/1.2'}),
          queryParameters: {
            'q': '$query, Ocosingo',
            'format': 'jsonv2',
            'limit': 1,
          },
        );
        data = broadResponse.data;
      }

      LottieLoading.hideLoadingDialog(context);

      if (data != null && data is List && data.isNotEmpty) {
        final result = data[0];
        final double lat = double.parse(result['lat'].toString());
        final double lon = double.parse(result['lon'].toString());

        setState(() {
          // Guardar información de ubicación para el POST final
          _ubicacionActual = Position(
            latitude: lat, longitude: lon,
            timestamp: DateTime.now(),
            accuracy: 0, altitude: 0, heading: 0, speed: 0, speedAccuracy: 0,
            altitudeAccuracy: 0, headingAccuracy: 0,
          );
        });
        
        // Mover el mapa y mostrar éxito
        _mapController.move(LatLng(lat, lon), 17.5);
        LottieFeedback.showSuccess(context, message: 'Dirección ubicada con éxito');
      } else {
        LottieFeedback.showError(context, message: 'No pudimos encontrar "$query". Prueba con una colonia o calle cercana.');
      }
    } catch (e) {
      if (!mounted) return;
      LottieLoading.hideLoadingDialog(context);
      print('❌ Error Geocoding: $e');
      LottieFeedback.showError(context, message: 'Error de conexión con el servicio de mapas');
    }
  }

  void _nextStep() {
    if (_formKeys[_currentStep].currentState!.validate()) {
      if (_currentStep < 3) {
        setState(() => _currentStep++);
        _pageController.animateToPage(
          _currentStep,
          duration: const Duration(milliseconds: 400),
          curve: Curves.easeInOut,
        );
      } else {
        _guardarInmueble();
      }
    }
  }

  void _prevStep() {
    if (_currentStep > 0) {
      setState(() => _currentStep--);
      _pageController.animateToPage(
        _currentStep,
        duration: const Duration(milliseconds: 400),
        curve: Curves.easeInOut,
      );
    } else {
      Navigator.pop(context);
    }
  }

  Future<void> _guardarInmueble() async {
    print('🚀 Iniciando proceso de guardado...');
    if (widget.inmuebleId == null && _imagenesSeleccionadas.length < 5) {
      LottieFeedback.showError(context, message: 'Debes subir al menos 5 fotos para una mejor visibilidad');
      return;
    }

    LottieLoading.showLoadingDialog(context, message: 'Publicando propiedad...');

    try {
      final deviceInfo = DeviceInfoPlugin();
      Map<String, dynamic> metadata = {'app_version': '1.1.0'};
      if (Platform.isAndroid) {
        final info = await deviceInfo.androidInfo;
        metadata['device'] = info.model;
        metadata['os_version'] = info.version.release;
      }

      final Map<String, dynamic> dataMap = {
        'titulo': _tituloController.text.trim(),
        'descripcion': _descripcionController.text.trim(),
        'renta_mensual': double.parse(_precioController.text),
        'deposito': _requiereDeposito ? (double.tryParse(_depositoController.text) ?? 0) : 0,
        'requiere_deposito': _requiereDeposito ? 1 : 0,
        'tipo': _categoriaSeleccionada,
        'habitaciones': _camas,
        'banos': _banos,
        'medios_banos': _mediosBanos,
        'direccion': _direccionController.text,
        'latitud': _ubicacionActual?.latitude,
        'longitud': _ubicacionActual?.longitude,
        'largo': double.tryParse(_largoController.text),
        'ancho': double.tryParse(_anchoController.text),
        'metros': (double.tryParse(_largoController.text) ?? 5) * (double.tryParse(_anchoController.text) ?? 5),
        'estado_mobiliario': _mobiliario == 'Amueblada' ? 'amueblada' : 
                            _mobiliario == 'Semiamueblada' ? 'semiamueblada' : 'no amueblada',
        'tiene_estacionamiento': _estacionamientoIncluido ? 1 : 0,
        'permite_mascotas': _permiteMascotas ? 1 : 0,
        'momento_pago': _momentoPago == 'Por adelantado' ? 'adelantado' : 'vencido',
        'dias_tolerancia': int.tryParse(_toleranciaController.text) ?? 3,
        'dias_preaviso': int.tryParse(_preavisoController.text) ?? 30,
        'duracion_contrato_meses': int.tryParse(_duracionController.text) ?? _duracionContrato,
        'clabe_interbancaria': _clabeController.text,
        'banco': _bancoSeleccionado,
        'incluir_clausulas': _incluirClausulas ? 1 : 0,
        'clausulas_extra': _clausulasController.text,
        'registrado_desde': 'mobile',
      };

      final dio.FormData formData = dio.FormData.fromMap(dataMap);

      // Agregar arreglos con [] para Laravel
      for (var s in _serviciosSeleccionados) {
        formData.fields.add(MapEntry('servicios_incluidos[]', s));
      }
      for (var m in _tiposMascotasPermitidas) {
        formData.fields.add(MapEntry('tipos_mascotas[]', m));
      }

      // Enviar mapas anidados como llave[subkey] para que Laravel los vea como arreglos
      _pagoServiciosResponsables.forEach((key, value) {
        formData.fields.add(MapEntry('pago_servicio[$key]', value));
      });
      metadata.forEach((key, value) {
        formData.fields.add(MapEntry('plataforma_metadata[$key]', value.toString()));
      });

      if (widget.inmuebleId != null) {
        formData.fields.add(const MapEntry('_method', 'PUT'));
      }

      for (var file in _imagenesSeleccionadas) {
        formData.files.add(MapEntry(
          'imagenes[]',
          await dio.MultipartFile.fromFile(file.path, filename: p.basename(file.path)),
        ));
      }

      final response = widget.inmuebleId != null
          ? await _api.post('/inmuebles/${widget.inmuebleId}', data: formData)
          : await _api.post('/inmuebles', data: formData);

      if (!mounted) return;
      LottieLoading.hideLoadingDialog(context);

      if (response.statusCode == 200 || response.statusCode == 201) {
        LottieFeedback.showSuccess(context, message: '¡Propiedad publicada!', onComplete: () => Navigator.pop(context, true));
      }
    } catch (e) {
      if (!mounted) return;
      LottieLoading.hideLoadingDialog(context);
      LottieFeedback.showError(context, message: 'Error al conectar con el servidor');
    }
  }

  @override
  void dispose() {
    _descripcionController.removeListener(_actualizarContadorPalabras);
    _tituloController.dispose();
    _descripcionController.dispose();
    _precioController.dispose();
    _depositoController.dispose();
    _direccionController.dispose();
    _largoController.dispose();
    _anchoController.dispose();
    _clabeController.dispose();
    _clausulasController.dispose();
    _toleranciaController.dispose();
    _preavisoController.dispose();
    _duracionController.dispose();
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: Text('Publicar Propiedad', style: TextStyle(fontWeight: FontWeight.bold, color: MiTema.azul)),
        centerTitle: true,
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios_new_rounded, color: MiTema.azul),
          onPressed: _prevStep,
        ),
      ),
      body: Column(
        children: [
          _buildStepProgress(),
          Expanded(
            child: PageView(
              controller: _pageController,
              physics: const NeverScrollableScrollPhysics(),
              children: [
                _buildStepBasic(),
                _buildStepDetails(),
                _buildStepRules(),
                _buildStepPhotos(),
              ],
            ),
          ),
          _buildBottomButtons(),
        ],
      ),
    );
  }

  Widget _buildStepProgress() {
    final titles = ['Básico', 'Detalles', 'Reglas', 'Archivos'];
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 30),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: List.generate(titles.length, (index) {
          final isActive = index <= _currentStep;
          final isCurrent = index == _currentStep;
          return Column(
            children: [
              Container(
                width: 35,
                height: 35,
                decoration: BoxDecoration(
                  color: isCurrent ? MiTema.azul : (isActive ? MiTema.celeste : Colors.grey[200]),
                  shape: BoxShape.circle,
                  border: isCurrent ? Border.all(color: MiTema.celeste, width: 3) : null,
                ),
                child: Center(
                  child: Text(
                    '${index + 1}',
                    style: TextStyle(
                      color: isActive ? Colors.white : Colors.grey[600],
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 5),
              Text(
                titles[index],
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: isCurrent ? FontWeight.bold : FontWeight.normal,
                  color: isCurrent ? MiTema.azul : Colors.grey,
                ),
              ),
            ],
          );
        }),
      ),
    );
  }

  Widget _buildStepBasic() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Form(
        key: _formKeys[0],
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const _SectionHeader(title: '¿Qué vas a rentar?', icon: Icons.home_rounded),
            const SizedBox(height: 20),
            StunningTextField(
              controller: _tituloController,
              label: 'Nombre del Anuncio *',
              icon: Icons.edit_note_rounded,
              validator: (v) => v!.isEmpty ? 'Campo requerido' : null,
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                Expanded(
                  child: StunningDropdown<String>(
                    value: _categoriaSeleccionada,
                    label: 'Tipo *',
                    icon: Icons.category_rounded,
                    items: _categorias.map((e) => DropdownMenuItem(value: e, child: Text(e))).toList(),
                    onChanged: (v) => setState(() => _categoriaSeleccionada = v),
                  ),
                ),
                const SizedBox(width: 15),
                Expanded(
                  child: StunningTextField(
                    controller: _precioController,
                    label: 'Renta Mensual *',
                    icon: Icons.monetization_on_rounded,
                    keyboardType: TextInputType.number,
                    validator: (v) => v!.isEmpty ? 'Campo requerido' : null,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 30),
            StunningCard(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('¿El inquilino deberá dar depósito?', style: TextStyle(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      _buildRadioOption('Sí', true, _requiereDeposito, (val) => setState(() => _requiereDeposito = val)),
                      const SizedBox(width: 20),
                      _buildRadioOption('No, sin depósito', false, _requiereDeposito, (val) => setState(() => _requiereDeposito = val)),
                    ],
                  ),
                  if (_requiereDeposito) ...[
                    const SizedBox(height: 20),
                    StunningTextField(
                      controller: _depositoController,
                      label: 'Monto del Depósito *',
                      icon: Icons.security_rounded,
                      keyboardType: TextInputType.number,
                      validator: (v) => _requiereDeposito && v!.isEmpty ? 'Campo requerido' : null,
                    ).animate().fadeIn().slideY(begin: 0.1),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStepDetails() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Form(
        key: _formKeys[1],
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const _SectionHeader(title: 'Características y Ubicación', icon: Icons.map_rounded),
            const SizedBox(height: 20),
            Row(
              children: [
                Expanded(
                  child: StunningTextField(
                    controller: _direccionController,
                    label: 'Dirección Completa *',
                    icon: Icons.location_on_rounded,
                  ),
                ),
                const SizedBox(width: 10),
                ElevatedButton(
                  onPressed: _buscarDireccionManual,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: MiTema.azul, 
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    minimumSize: const Size(50, 50),
                  ),
                  child: const Icon(Icons.search_rounded, color: Colors.white),
                ),
                const SizedBox(width: 8),
                ElevatedButton(
                  onPressed: _obtenerUbicacion,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: MiTema.celeste, 
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    minimumSize: const Size(50, 50),
                  ),
                  child: const Icon(Icons.my_location_rounded, color: Colors.white),
                ),
              ],
            ),
            const SizedBox(height: 15),
            Container(
              height: 200,
              decoration: BoxDecoration(borderRadius: BorderRadius.circular(20), border: Border.all(color: Colors.grey[200]!)),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(20),
                child: _ubicacionActual != null 
                  ? MapPreviewOsm(
                      lat: _ubicacionActual!.latitude, 
                      lng: _ubicacionActual!.longitude,
                      controller: _mapController,
                      onTap: (point) {
                        setState(() {
                          _ubicacionActual = Position(
                            latitude: point.latitude,
                            longitude: point.longitude,
                            timestamp: DateTime.now(),
                            accuracy: 0, altitude: 0, heading: 0, speed: 0, speedAccuracy: 0,
                            altitudeAccuracy: 0, headingAccuracy: 0,
                          );
                        });
                      },
                    )
                  : const Center(child: Text('Busca tu dirección o usa el GPS')),
              ),
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                Expanded(
                  child: StunningDropdown<int>(
                    value: _camas,
                    label: 'Habitaciones *',
                    icon: Icons.bed_rounded,
                    items: [1, 2, 3, 4, 5].map((e) => DropdownMenuItem(value: e, child: Text('$e'))).toList(),
                    onChanged: (v) => setState(() => _camas = v!),
                  ),
                ),
                const SizedBox(width: 15),
                Expanded(
                  child: StunningDropdown<String>(
                    value: _banoSeleccionadoStr,
                    label: 'Baños *',
                    icon: Icons.bathroom_rounded,
                    items: _opcionesBanos.map((e) => DropdownMenuItem(value: e, child: Text(e))).toList(),
                    onChanged: (v) {
                      setState(() {
                        _banoSeleccionadoStr = v!;
                        // Lógica de mapeo a valores numéricos para la API
                        if (v == 'Medio Baño') { _banos = 0; _mediosBanos = 1; }
                        else if (v == '1 Baño Completo') { _banos = 1; _mediosBanos = 0; }
                        else if (v == '1 Baño Completo y Medio Baño') { _banos = 1; _mediosBanos = 1; }
                        else if (v == '2 Baños Completos') { _banos = 2; _mediosBanos = 0; }
                        else if (v == '2 Baños Completos y Medio Baño') { _banos = 2; _mediosBanos = 1; }
                        else if (v == '3 Baños Completos') { _banos = 3; _mediosBanos = 0; }
                        else if (v == '3 Baños Completos y Medio Baño') { _banos = 3; _mediosBanos = 1; }
                        else if (v == '4 Baños o más') { _banos = 4; _mediosBanos = 0; }
                      });
                    },
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            StunningCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Dimensiones (Opcional)', style: TextStyle(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 15),
                  Row(
                    children: [
                      Expanded(
                        child: StunningTextField(
                          controller: _largoController, 
                          label: 'Largo (m)', 
                          icon: Icons.straighten_rounded,
                          keyboardType: const TextInputType.numberWithOptions(decimal: true),
                          inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'[0-9.]'))],
                        ),
                      ),
                      const Padding(padding: EdgeInsets.symmetric(horizontal: 10), child: Text('x')),
                      Expanded(
                        child: StunningTextField(
                          controller: _anchoController, 
                          label: 'Ancho (m)', 
                          icon: Icons.straighten_rounded,
                          keyboardType: const TextInputType.numberWithOptions(decimal: true),
                          inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'[0-9.]'))],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Descripción *', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: _palabrasDescripcion >= 30 ? Colors.green.withOpacity(0.1) : Colors.red.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    '$_palabrasDescripcion / 120 palabras (Mín. 30)',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: _palabrasDescripcion >= 30 ? Colors.green : Colors.red,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            StunningTextField(
              controller: _descripcionController,
              label: 'Cuéntanos más detalles del inmueble...',
              icon: Icons.description_rounded,
              maxLines: 4,
              inputFormatters: [
                FilteringTextInputFormatter.allow(RegExp(r'[a-zA-ZáéíóúÁÉÍÓÚñÑ ]')),
              ],
              validator: (v) {
                if (_palabrasDescripcion < 30) return 'Se requieren al menos 30 palabras';
                if (_palabrasDescripcion > 120) return 'Máximo 120 palabras';
                return null;
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStepRules() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Form(
        key: _formKeys[2],
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const _SectionHeader(title: 'Reglas y Pagos', icon: Icons.gavel_rounded),
            const SizedBox(height: 20),
            Row(
              children: [
                Expanded(
                  child: StunningDropdown<String>(
                    value: _mobiliario,
                    label: 'Mobiliario *',
                    icon: Icons.chair_rounded,
                    items: ['Amueblada', 'No amueblado', 'Semi-amueblado'].map((e) => DropdownMenuItem(value: e, child: Text(e))).toList(),
                    onChanged: (v) => setState(() => _mobiliario = v!),
                  ),
                ),
                const SizedBox(width: 15),
                Expanded(
                  child: StunningDropdown<bool>(
                    value: _estacionamientoIncluido,
                    label: '¿Estacionamiento? *',
                    icon: Icons.directions_car_rounded,
                    items: [
                      const DropdownMenuItem(value: true, child: Text('Sí')),
                      const DropdownMenuItem(value: false, child: Text('No')),
                    ],
                    onChanged: (v) => setState(() => _estacionamientoIncluido = v!),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            const Text('¿Están permitidas las mascotas?', style: TextStyle(fontWeight: FontWeight.bold)),
            Row(
              children: [
                _buildRadioOption('Sí', true, _permiteMascotas, (v) => setState(() => _permiteMascotas = v)),
                const SizedBox(width: 20),
                _buildRadioOption('No', false, _permiteMascotas, (v) => setState(() => _permiteMascotas = v)),
              ],
            ),
            if (_permiteMascotas) ...[
              const SizedBox(height: 15),
              const Text('Selecciona las mascotas permitidas:', style: TextStyle(fontSize: 13, color: Colors.grey)),
              const SizedBox(height: 10),
              _buildPetGrid(),
            ],
            const SizedBox(height: 25),
            const Text('¿Con qué servicios cuenta el inmueble?', style: TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 10),
            _buildServiceChips(),
            if (_serviciosSeleccionados.isNotEmpty) ...[
              const SizedBox(height: 25),
              const Center(child: Text('¿Quién será responsable de pagar los servicios?', style: TextStyle(fontWeight: FontWeight.bold))),
              const SizedBox(height: 15),
              _buildServicePaymentTable(),
            ],
            const SizedBox(height: 30),
            Row(
              children: [
                Expanded(
                  child: StunningDropdown<String>(
                    value: _momentoPago,
                    label: 'Momento de Pago *',
                    icon: Icons.payments_rounded,
                    items: ['Por adelantado', 'Mes vencido'].map((e) => DropdownMenuItem(value: e, child: Text(e))).toList(),
                    onChanged: (v) => setState(() => _momentoPago = v!),
                  ),
                ),
                const SizedBox(width: 15),
                Expanded(
                  child: StunningTextField(
                    controller: _toleranciaController, 
                    label: 'Tolerancia (Días)', 
                    icon: Icons.timer_rounded,
                    keyboardType: TextInputType.number,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                Expanded(
                  child: StunningTextField(
                    controller: _preavisoController, 
                    label: 'Preaviso Salida (Días)', 
                    icon: Icons.notification_important_rounded,
                    keyboardType: TextInputType.number,
                  ),
                ),
                const SizedBox(width: 15),
                Expanded(
                  child: StunningTextField(
                    controller: _clabeController, 
                    label: 'CLABE *', 
                    icon: Icons.account_balance_rounded,
                    keyboardType: TextInputType.number,
                    inputFormatters: [
                      FilteringTextInputFormatter.digitsOnly,
                      LengthLimitingTextInputFormatter(18),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            StunningDropdown<String>(
              value: _bancoSeleccionado,
              label: 'Banco Receptor de Pagos',
              icon: Icons.account_balance_wallet_rounded,
              items: _bancos.map((e) => DropdownMenuItem(value: e, child: Text(e))).toList(),
              onChanged: (v) => setState(() => _bancoSeleccionado = v),
            ),
            const SizedBox(height: 30),
            _buildDurationSelector(),
            const SizedBox(height: 30),
            StunningCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('¿Quieres incluir alguna cláusula o información adicional?', style: TextStyle(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      _buildRadioOption('Sí', true, _incluirClausulas, (v) => setState(() => _incluirClausulas = v)),
                      const SizedBox(width: 20),
                      _buildRadioOption('No', false, _incluirClausulas, (v) => setState(() => _incluirClausulas = v)),
                    ],
                  ),
                  if (_incluirClausulas) ...[
                    const SizedBox(height: 15),
                    StunningTextField(
                      controller: _clausulasController,
                      label: 'Escribe aquí tus cláusulas...',
                      icon: Icons.rule_rounded,
                      maxLines: 3,
                    ).animate().fadeIn(),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPetGrid() {
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(color: Colors.grey[50], borderRadius: BorderRadius.circular(15), border: Border.all(color: Colors.grey[200]!)),
      child: GridView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 2, childAspectRatio: 4, crossAxisSpacing: 10, mainAxisSpacing: 10),
        itemCount: _listaTiposMascotas.length,
        itemBuilder: (ctx, i) {
          final mascota = _listaTiposMascotas[i];
          final isSelected = _tiposMascotasPermitidas.contains(mascota);
          return InkWell(
            onTap: () {
              setState(() {
                if (isSelected) _tiposMascotasPermitidas.remove(mascota);
                else _tiposMascotasPermitidas.add(mascota);
              });
            },
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10),
              decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(10), border: Border.all(color: isSelected ? MiTema.azul : Colors.grey[300]!)),
              child: Row(
                children: [
                  Checkbox(
                    value: isSelected, 
                    onChanged: (v) => setState(() => isSelected ? _tiposMascotasPermitidas.remove(mascota) : _tiposMascotasPermitidas.add(mascota)),
                    activeColor: MiTema.azul,
                  ),
                  Expanded(child: Text(mascota, style: TextStyle(fontSize: 12, color: isSelected ? MiTema.azul : Colors.black87))),
                ],
              ),
            ),
          );
        },
      ).animate().fadeIn(),
    );
  }

  Widget _buildServiceChips() {
    return Wrap(
      spacing: 10,
      children: _serviciosDisponibles.map((s) {
        final isSelected = _serviciosSeleccionados.contains(s);
        return FilterChip(
          label: Text(s),
          selected: isSelected,
          onSelected: (val) {
            setState(() {
              if (val) {
                _serviciosSeleccionados.add(s);
                _pagoServiciosResponsables[s] = 'Inquilino'; // Default
              } else {
                _serviciosSeleccionados.remove(s);
                _pagoServiciosResponsables.remove(s);
              }
            });
          },
          selectedColor: MiTema.celeste.withOpacity(0.2),
          checkmarkColor: MiTema.azul,
        );
      }).toList(),
    );
  }

  Widget _buildServicePaymentTable() {
    return Container(
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(15), border: Border.all(color: Colors.grey[200]!)),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 15),
            color: Colors.grey[50],
            child: const Row(
              children: [
                Expanded(child: Text('Servicio', style: TextStyle(fontWeight: FontWeight.bold))),
                Text('Inquilino', style: TextStyle(fontSize: 11)),
                SizedBox(width: 40),
                Text('Arrendador', style: TextStyle(fontSize: 11)),
              ],
            ),
          ),
          ..._serviciosSeleccionados.map((s) => Container(
            padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 15),
            decoration: BoxDecoration(border: Border(top: BorderSide(color: Colors.grey[100]!))),
            child: Row(
              children: [
                Expanded(child: Text(s, style: const TextStyle(fontWeight: FontWeight.w500))),
                Radio<String>(
                  value: 'Inquilino', 
                  groupValue: _pagoServiciosResponsables[s], 
                  onChanged: (v) => setState(() => _pagoServiciosResponsables[s] = v!),
                  activeColor: MiTema.azul,
                ),
                const SizedBox(width: 30),
                Radio<String>(
                  value: 'Arrendador', 
                  groupValue: _pagoServiciosResponsables[s], 
                  onChanged: (v) => setState(() => _pagoServiciosResponsables[s] = v!),
                  activeColor: MiTema.azul,
                ),
              ],
            ),
          )),
        ],
      ),
    ).animate().slideY(begin: 0.1);
  }

  Widget _buildDurationSelector() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Duración del Contrato (Meses) *', style: TextStyle(fontWeight: FontWeight.bold)),
        const SizedBox(height: 10),
        Row(
          children: [
            SizedBox(
              width: 100,
              child: StunningTextField(
                controller: _duracionController, 
                label: 'Meses', 
                icon: Icons.calendar_today_rounded,
                keyboardType: TextInputType.number,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              ),
            ),
            const SizedBox(width: 15),
            Expanded(
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    _durationChip('6 meses', 6),
                    _durationChip('1 año', 12),
                    _durationChip('2 años', 24),
                  ],
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _durationChip(String label, int val) {
    final isSelected = _duracionContrato == val;
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: ChoiceChip(
        label: Text(label),
        selected: isSelected,
        onSelected: (s) {
          setState(() {
            _duracionContrato = val;
            _duracionController.text = val.toString();
          });
        },
        selectedColor: MiTema.celeste.withOpacity(0.3),
        labelStyle: TextStyle(color: isSelected ? MiTema.azul : Colors.black87),
      ),
    );
  }

  Widget _buildStepPhotos() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Form(
        key: _formKeys[3],
        child: Column(
          children: [
            const _SectionHeader(title: 'Archivos de la Propiedad', icon: Icons.photo_library_rounded),
            const SizedBox(height: 10),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  _imagenesSeleccionadas.length >= 5 ? Icons.check_circle_rounded : Icons.info_outline_rounded,
                  color: _imagenesSeleccionadas.length >= 5 ? Colors.green : Colors.orange,
                  size: 16,
                ),
                const SizedBox(width: 8),
                Text(
                  '${_imagenesSeleccionadas.length} / 5 fotos necesarias',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: _imagenesSeleccionadas.length >= 5 ? Colors.green : Colors.orange,
                  ),
                ),
              ],
            ).animate().fadeIn(),
            const SizedBox(height: 20),
            InkWell(
              onTap: seleccionarImagenes,
              child: Container(
                height: 200,
                width: double.infinity,
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey[300]!, width: 2, style: BorderStyle.none),
                  borderRadius: BorderRadius.circular(20),
                  color: Colors.grey[50],
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.cloud_upload_outlined, size: 60, color: Colors.grey[400]),
                    const SizedBox(height: 10),
                    const Text('Toca para subir fotos', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.grey)),
                  ],
                ),
              ).animate().shimmer(duration: 2.seconds),
            ),
            const SizedBox(height: 20),
            if (_imagenesSeleccionadas.isNotEmpty)
              GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 3, 
                  crossAxisSpacing: 10, 
                  mainAxisSpacing: 10
                ),
                itemCount: _imagenesSeleccionadas.length,
                itemBuilder: (ctx, i) => Stack(
                  children: [
                    Positioned.fill(
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(10),
                        child: Image.file(File(_imagenesSeleccionadas[i].path), fit: BoxFit.cover),
                      ),
                    ),
                    Positioned(
                      top: 5,
                      right: 5,
                      child: InkWell(
                        onTap: () => setState(() => _imagenesSeleccionadas.removeAt(i)),
                        child: Container(
                          padding: const EdgeInsets.all(4),
                          decoration: const BoxDecoration(color: Colors.red, shape: BoxShape.circle),
                          child: const Icon(Icons.close, size: 14, color: Colors.white),
                        ),
                      ),
                    ),
                  ],
                ),
              ).animate().fadeIn(),
          ],
        ),
      ),
    );
  }

  Widget _buildRadioOption(String label, bool value, bool groupValue, Function(bool) onChanged) {
    final isSelected = value == groupValue;
    return GestureDetector(
      onTap: () => onChanged(value),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: isSelected ? MiTema.azul : Colors.grey, width: 2),
            ),
            child: CircleAvatar(radius: 6, backgroundColor: isSelected ? MiTema.azul : Colors.transparent),
          ),
          const SizedBox(width: 8),
          Text(label, style: TextStyle(color: isSelected ? MiTema.azul : Colors.black87)),
        ],
      ),
    );
  }

  Widget _buildBottomButtons() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(color: Colors.white, boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, -5))]),
      child: Row(
        children: [
          Expanded(
            child: OutlinedButton(
              onPressed: _prevStep,
              style: OutlinedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 16), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16))),
              child: Text(_currentStep == 0 ? 'Cancelar' : 'Atrás'),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: ElevatedButton(
              onPressed: _nextStep,
              style: ElevatedButton.styleFrom(
                backgroundColor: MiTema.azul,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              ),
              child: Text(_currentStep == 3 ? '¡Publicar Ahora!' : 'Siguiente Paso →'),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> seleccionarImagenes() async {
    final picker = ImagePicker();
    final images = await picker.pickMultiImage();
    if (images.isNotEmpty) setState(() => _imagenesSeleccionadas = images);
  }
}

class _SectionHeader extends StatelessWidget {
  final String title;
  final IconData icon;
  const _SectionHeader({required this.title, required this.icon});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, color: MiTema.azul),
        const SizedBox(width: 10),
        Text(title, style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: MiTema.azul)),
      ],
    );
  }
}
