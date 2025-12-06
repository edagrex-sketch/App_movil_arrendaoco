import 'package:flutter/material.dart';
import 'package:arrendaoco/theme/tema.dart';
import 'package:arrendaoco/model/bd.dart';
import 'package:arrendaoco/model/sesion_actual.dart';
import 'package:arrendaoco/view/detalle_renta.dart';
import 'package:arrendaoco/services/notificaciones_service.dart';
import 'dart:io';

class GestionarRentasScreen extends StatefulWidget {
  const GestionarRentasScreen({super.key});

  @override
  State<GestionarRentasScreen> createState() => _GestionarRentasScreenState();
}

class _GestionarRentasScreenState extends State<GestionarRentasScreen> {
  late Future<List<Map<String, dynamic>>> _futureRentas;

  @override
  void initState() {
    super.initState();
    _cargarRentas();
  }

  void _cargarRentas() {
    final usuarioId = SesionActual.usuarioId;
    if (usuarioId != null) {
      _futureRentas = BaseDatos.obtenerRentasPorArrendador(usuarioId);
    } else {
      _futureRentas = Future.value([]);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text('Gestionar Rentas'),
        backgroundColor: MiTema.azul,
        foregroundColor: MiTema.crema,
        centerTitle: true,
      ),
      body: FutureBuilder<List<Map<String, dynamic>>>(
        future: _futureRentas,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          final rentas = snapshot.data ?? [];

          if (rentas.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.home_work_outlined,
                    size: 80,
                    color: Colors.grey[400],
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'No tienes rentas activas',
                    style: TextStyle(
                      fontSize: 18,
                      color: Colors.grey[600],
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Crea una nueva renta para comenzar',
                    style: TextStyle(fontSize: 14, color: Colors.grey[500]),
                  ),
                ],
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: rentas.length,
            itemBuilder: (context, index) {
              final renta = rentas[index];
              return _buildRentaCard(renta);
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _mostrarFormularioNuevaRenta,
        backgroundColor: MiTema.celeste,
        icon: Icon(Icons.add, color: MiTema.blanco),
        label: Text('Nueva Renta', style: TextStyle(color: MiTema.blanco)),
      ),
    );
  }

  Widget _buildRentaCard(Map<String, dynamic> renta) {
    final titulo = renta['inmueble_titulo'] ?? '';
    final inquilino = renta['inquilino_nombre'] ?? '';
    final monto = renta['monto_mensual'] ?? 0;
    final estado = renta['estado'] ?? 'activa';
    final rutas = (renta['rutas_imagen'] as String?) ?? '';
    final primeraRuta = rutas.isNotEmpty ? rutas.split('|').first : null;

    Color estadoColor;
    switch (estado) {
      case 'activa':
        estadoColor = Colors.green;
        break;
      case 'finalizada':
        estadoColor = Colors.grey;
        break;
      default:
        estadoColor = Colors.orange;
    }

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: InkWell(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) =>
                  DetalleRentaScreen(rentaId: renta['id'] as int),
            ),
          ).then((_) => setState(() => _cargarRentas()));
        },
        borderRadius: BorderRadius.circular(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (primeraRuta != null)
              ClipRRect(
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(16),
                ),
                child: Image.file(
                  File(primeraRuta),
                  height: 150,
                  width: double.infinity,
                  fit: BoxFit.cover,
                ),
              ),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          titulo,
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: MiTema.azul,
                          ),
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: estadoColor.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: estadoColor),
                        ),
                        child: Text(
                          estado.toUpperCase(),
                          style: TextStyle(
                            color: estadoColor,
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Icon(Icons.person, size: 16, color: MiTema.celeste),
                      const SizedBox(width: 4),
                      Text(
                        inquilino,
                        style: TextStyle(fontSize: 14, color: MiTema.celeste),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '\$$monto/mes',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w800,
                      color: MiTema.vino,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      TextButton.icon(
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => DetalleRentaScreen(
                                rentaId: renta['id'] as int,
                              ),
                            ),
                          ).then((_) => setState(() => _cargarRentas()));
                        },
                        icon: const Icon(Icons.visibility, size: 18),
                        label: const Text('Ver Detalles'),
                        style: TextButton.styleFrom(
                          foregroundColor: MiTema.celeste,
                        ),
                      ),
                      TextButton.icon(
                        onPressed: () {
                          // Navegar a calendario compartido
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Calendario próximamente'),
                            ),
                          );
                        },
                        icon: const Icon(Icons.calendar_today, size: 18),
                        label: const Text('Calendario'),
                        style: TextButton.styleFrom(
                          foregroundColor: MiTema.azul,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _mostrarFormularioNuevaRenta() async {
    final usuarioId = SesionActual.usuarioId;
    if (usuarioId == null) return;

    // Obtener inmuebles del arrendador
    final db = await BaseDatos.conecta();
    final inmuebles = await db.query(
      'inmuebles',
      where: 'propietario_id = ?',
      whereArgs: [usuarioId],
    );

    if (!mounted) return;

    if (inmuebles.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Primero debes publicar un inmueble')),
      );
      return;
    }

    final inquilinoIdController = TextEditingController();
    final montoController = TextEditingController();
    final diaPagoController = TextEditingController(text: '5');
    int? inmuebleSeleccionado;
    DateTime fechaInicio = DateTime.now();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) {
        return Padding(
          padding: EdgeInsets.only(
            left: 16,
            right: 16,
            top: 16,
            bottom: MediaQuery.of(context).viewInsets.bottom + 16,
          ),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Nueva Renta',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: MiTema.azul,
                  ),
                ),
                const SizedBox(height: 16),
                StatefulBuilder(
                  builder: (context, setModalState) {
                    return Column(
                      children: [
                        DropdownButtonFormField<int>(
                          decoration: const InputDecoration(
                            labelText: 'Inmueble',
                            border: OutlineInputBorder(),
                          ),
                          value: inmuebleSeleccionado,
                          items: inmuebles.map((i) {
                            return DropdownMenuItem<int>(
                              value: i['id'] as int,
                              child: Text(i['titulo'].toString()),
                            );
                          }).toList(),
                          onChanged: (value) {
                            setModalState(() {
                              inmuebleSeleccionado = value;
                            });
                          },
                        ),
                        const SizedBox(height: 12),
                        TextField(
                          controller: inquilinoIdController,
                          decoration: const InputDecoration(
                            labelText: 'ID del Inquilino',
                            hintText: 'Ej: 5',
                            border: OutlineInputBorder(),
                          ),
                          keyboardType: TextInputType.number,
                        ),
                        const SizedBox(height: 12),
                        TextField(
                          controller: montoController,
                          decoration: const InputDecoration(
                            labelText: 'Monto Mensual',
                            prefixText: '\$',
                            border: OutlineInputBorder(),
                          ),
                          keyboardType: TextInputType.number,
                        ),
                        const SizedBox(height: 12),
                        TextField(
                          controller: diaPagoController,
                          decoration: const InputDecoration(
                            labelText: 'Día de Pago',
                            hintText: '1-31',
                            border: OutlineInputBorder(),
                          ),
                          keyboardType: TextInputType.number,
                        ),
                        const SizedBox(height: 12),
                        ListTile(
                          leading: Icon(
                            Icons.calendar_today,
                            color: MiTema.azul,
                          ),
                          title: const Text('Fecha de Inicio'),
                          subtitle: Text(
                            '${fechaInicio.day}/${fechaInicio.month}/${fechaInicio.year}',
                          ),
                          onTap: () async {
                            final picked = await showDatePicker(
                              context: context,
                              initialDate: fechaInicio,
                              firstDate: DateTime.now(),
                              lastDate: DateTime.now().add(
                                const Duration(days: 365),
                              ),
                            );
                            if (picked != null) {
                              setModalState(() {
                                fechaInicio = picked;
                              });
                            }
                          },
                        ),
                      ],
                    );
                  },
                ),
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () async {
                      if (inmuebleSeleccionado == null) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Selecciona un inmueble'),
                          ),
                        );
                        return;
                      }

                      final inquilinoId = int.tryParse(
                        inquilinoIdController.text,
                      );
                      if (inquilinoId == null) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('ID de inquilino inválido'),
                          ),
                        );
                        return;
                      }

                      // Verificar que el inquilino existe
                      final existe = await BaseDatos.verificarInquilinoExiste(
                        inquilinoId,
                      );
                      if (!existe) {
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text(
                                'El ID no corresponde a un inquilino',
                              ),
                            ),
                          );
                        }
                        return;
                      }

                      // Verificar que el inmueble no tiene renta activa
                      final tieneRenta =
                          await BaseDatos.inmuebleTieneRentaActiva(
                            inmuebleSeleccionado!,
                          );
                      if (tieneRenta) {
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text(
                                'Este inmueble ya tiene una renta activa',
                              ),
                            ),
                          );
                        }
                        return;
                      }

                      final monto = double.tryParse(montoController.text);
                      if (monto == null || monto <= 0) {
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Monto inválido')),
                          );
                        }
                        return;
                      }

                      final diaPago = int.tryParse(diaPagoController.text);
                      if (diaPago == null || diaPago < 1 || diaPago > 31) {
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text(
                                'Día de pago debe estar entre 1 y 31',
                              ),
                            ),
                          );
                        }
                        return;
                      }

                      // Crear renta
                      final rentaId = await BaseDatos.crearRenta({
                        'inmueble_id': inmuebleSeleccionado,
                        'arrendador_id': usuarioId,
                        'inquilino_id': inquilinoId,
                        'fecha_inicio': fechaInicio.toIso8601String(),
                        'monto_mensual': monto,
                        'dia_pago': diaPago,
                        'estado': 'activa',
                      });

                      // Generar pagos mensuales (12 meses)
                      await BaseDatos.generarPagosMensuales(
                        rentaId,
                        fechaInicio,
                        monto,
                        diaPago,
                        12,
                      );

                      // Obtener título del inmueble para notificación
                      final inmuebleData = inmuebles.firstWhere(
                        (i) => i['id'] == inmuebleSeleccionado,
                      );
                      final tituloInmueble = inmuebleData['titulo'].toString();

                      // Notificar al inquilino
                      await NotificacionesService.notificarNuevaRenta(
                        inquilinoId: inquilinoId,
                        inmuebleTitulo: tituloInmueble,
                        monto: monto,
                      );

                      if (context.mounted) {
                        Navigator.pop(context);
                        setState(() => _cargarRentas());
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Renta creada exitosamente'),
                          ),
                        );
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: MiTema.celeste,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: const Text('Crear Renta'),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
