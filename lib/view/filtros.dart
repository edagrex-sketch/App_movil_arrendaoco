import 'package:flutter/material.dart';
import 'package:arrendaoco/theme/tema.dart';

class FiltrosScreen extends StatefulWidget {
  final Function(Map<String, dynamic>) onAplicarFiltros;

  const FiltrosScreen({super.key, required this.onAplicarFiltros});

  @override
  State<FiltrosScreen> createState() => _FiltrosScreenState();
}

class _FiltrosScreenState extends State<FiltrosScreen> {
  // Rango de precio
  RangeValues _precioRango = const RangeValues(1000, 2000);

  // Camas
  int? _camasSeleccionadas;

  // Tipo de inmueble
  String? _tipoInmueble;
  final List<String> _tipos = ['Todos', 'Casa', 'Departamento', 'Cuarto'];

  // Baños
  int? _banosSeleccionados;

  // Tamaño del inmueble
  String? _tamanoInmueble;
  final List<String> _tamanos = ['Todos', 'Pequeño', 'Mediano', 'Grande'];

  // Toggles
  bool _estacionamiento = false;
  bool _amueblado = false;
  bool _mascotas = false;

  void _aplicarFiltros() {
    final filtros = {
      'precioMin': _precioRango.start.toInt(),
      'precioMax': _precioRango.end.toInt(),
      'camas': _camasSeleccionadas,
      'tipo': _tipoInmueble,
      'banos': _banosSeleccionados,
      'tamano': _tamanoInmueble,
      'estacionamiento': _estacionamiento,
      'amueblado': _amueblado,
      'mascotas': _mascotas,
    };

    widget.onAplicarFiltros(filtros);
    Navigator.pop(context);
  }

  void _reiniciarFiltros() {
    setState(() {
      _precioRango = const RangeValues(1000, 2000);
      _camasSeleccionadas = null;
      _tipoInmueble = null;
      _banosSeleccionados = null;
      _tamanoInmueble = null;
      _estacionamiento = false;
      _amueblado = false;
      _mascotas = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: MiTema.vino,
        title: const Text('Filtros'),
        foregroundColor: MiTema.crema,
        centerTitle: true,
        leading: TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text('Cancelar', style: TextStyle(color: MiTema.crema)),
        ),
        actions: [
          TextButton(
            onPressed: _reiniciarFiltros,
            child: Text('Reiniciar', style: TextStyle(color: MiTema.crema)),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Rango de precio
            Text(
              'Rango de precio',
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.grey.shade100,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                children: [
                  Text(
                    '\$${_precioRango.start.toInt()} - \$${_precioRango.end.toInt()}',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: MiTema.vino,
                    ),
                  ),
                  RangeSlider(
                    values: _precioRango,
                    min: 500,
                    max: 5000,
                    divisions: 20,
                    onChanged: (RangeValues values) {
                      setState(() {
                        _precioRango = values;
                      });
                    },
                    activeColor: MiTema.vino,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Camas
            Text(
              'Cama',
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 12),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: List.generate(5, (index) {
                  final valor = index + 1;
                  return Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: ChoiceChip(
                      label: Text('$valor${valor > 3 ? '+' : ''}'),
                      selected: _camasSeleccionadas == valor,
                      selectedColor: MiTema.vino,
                      labelStyle: TextStyle(
                        color: _camasSeleccionadas == valor
                            ? Colors.white
                            : Colors.black,
                        fontWeight: FontWeight.w600,
                      ),
                      onSelected: (selected) {
                        setState(() {
                          _camasSeleccionadas = selected ? valor : null;
                        });
                      },
                    ),
                  );
                }),
              ),
            ),
            const SizedBox(height: 24),

            // Tipo de inmueble
            Text(
              'Tipo de inmueble',
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 8),
            DropdownButton<String>(
              value: _tipoInmueble,
              isExpanded: true,
              hint: const Text('Todos'),
              items: _tipos
                  .map(
                    (tipo) => DropdownMenuItem(
                      value: tipo == 'Todos' ? null : tipo,
                      child: Text(tipo),
                    ),
                  )
                  .toList(),
              onChanged: (valor) {
                setState(() {
                  _tipoInmueble = valor;
                });
              },
            ),
            const SizedBox(height: 24),

            // Baños
            Text(
              'Baño',
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 12),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: Chip(
                      label: const Text('Compartido'),
                      backgroundColor: _banosSeleccionados == 0
                          ? MiTema.vino
                          : Colors.grey.shade200,
                      labelStyle: TextStyle(
                        color: _banosSeleccionados == 0
                            ? Colors.white
                            : Colors.black,
                      ),
                      onDeleted: null,
                    ),
                  ),
                  ...List.generate(4, (index) {
                    final valor = index + 1;
                    return Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: ChoiceChip(
                        label: Text('$valor${valor > 2 ? '+' : ''}'),
                        selected: _banosSeleccionados == valor,
                        selectedColor: MiTema.vino,
                        labelStyle: TextStyle(
                          color: _banosSeleccionados == valor
                              ? Colors.white
                              : Colors.black,
                          fontWeight: FontWeight.w600,
                        ),
                        onSelected: (selected) {
                          setState(() {
                            _banosSeleccionados = selected ? valor : null;
                          });
                        },
                      ),
                    );
                  }),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Tamaño del inmueble
            Text(
              'Tamaño del inmueble',
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 8),
            DropdownButton<String>(
              value: _tamanoInmueble,
              isExpanded: true,
              hint: const Text('Todos'),
              items: _tamanos
                  .map(
                    (tamano) => DropdownMenuItem(
                      value: tamano == 'Todos' ? null : tamano,
                      child: Text(tamano),
                    ),
                  )
                  .toList(),
              onChanged: (valor) {
                setState(() {
                  _tamanoInmueble = valor;
                });
              },
            ),
            const SizedBox(height: 24),

            // Toggles
            Text(
              'Servicios',
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 12),
            SwitchListTile(
              title: const Text('Estacionamiento'),
              value: _estacionamiento,
              activeThumbColor: MiTema.celeste,
              onChanged: (value) {
                setState(() {
                  _estacionamiento = value;
                });
              },
              contentPadding: EdgeInsets.zero,
            ),
            SwitchListTile(
              title: const Text('Amueblado'),
              value: _amueblado,
              activeThumbColor: MiTema.celeste,
              onChanged: (value) {
                setState(() {
                  _amueblado = value;
                });
              },
              contentPadding: EdgeInsets.zero,
            ),
            SwitchListTile(
              title: const Text('Mascotas'),
              value: _mascotas,
              activeThumbColor: MiTema.celeste,
              onChanged: (value) {
                setState(() {
                  _mascotas = value;
                });
              },
              contentPadding: EdgeInsets.zero,
            ),
            const SizedBox(height: 32),

            // Botón Ver inmuebles
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _aplicarFiltros,
                style: ElevatedButton.styleFrom(
                  backgroundColor: MiTema.vino,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Text(
                  'Ver inmuebles',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
