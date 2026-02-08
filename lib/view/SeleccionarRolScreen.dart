import 'package:arrendaoco/theme/tema.dart';
import 'package:arrendaoco/theme/app_gradients.dart';
import 'package:arrendaoco/widgets/stunning_widgets.dart';
import 'package:flutter/material.dart';
import 'registrar.dart';

class SeleccionarRolScreen extends StatefulWidget {
  const SeleccionarRolScreen({super.key});

  @override
  _SeleccionarRolScreenState createState() => _SeleccionarRolScreenState();
}

class _SeleccionarRolScreenState extends State<SeleccionarRolScreen>
    with SingleTickerProviderStateMixin {
  String? _rolSeleccionado;

  final roles = [
    {
      "nombre": "Quiero publicitar mi propiedad",
      "rol": "arrendador",
      "icono": Icons.home_work_rounded,
      "description": "Publica y gestiona tus inmuebles fácilmente.",
    },
    {
      "nombre": "Buscar lugares para rentar",
      "rol": "inquilino",
      "icono": Icons.person_search_rounded,
      "description": "Encuentra el hogar perfecto para ti.",
    },
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: IconThemeData(color: MiTema.azul),
      ),
      body: Container(
        decoration: const BoxDecoration(gradient: AppGradients.surfaceGradient),
        child: SafeArea(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 20),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24.0),
                child: Column(
                  children: [
                    Text(
                      '¡Hola!',
                      style: Theme.of(context).textTheme.displaySmall?.copyWith(
                        fontWeight: FontWeight.w900,
                        color: MiTema.azul,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      '¿Cuál es tu objetivo principal?',
                      style: Theme.of(context).textTheme.headlineSmall
                          ?.copyWith(
                            fontWeight: FontWeight.w500,
                            color: Colors.grey[700],
                            fontSize: 20,
                          ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 48),

              Expanded(
                child: Center(
                  child: SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: roles.map((rol) {
                        final seleccionado = _rolSeleccionado == rol["rol"];
                        return GestureDetector(
                          onTap: () {
                            setState(() {
                              _rolSeleccionado = rol["rol"] as String;
                            });
                          },
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 300),
                            curve: Curves.easeOutBack,
                            width: 160,
                            margin: const EdgeInsets.symmetric(horizontal: 12),
                            padding: const EdgeInsets.all(20),
                            decoration: BoxDecoration(
                              color: seleccionado
                                  ? Colors.white
                                  : Colors.white.withOpacity(0.7),
                              borderRadius: BorderRadius.circular(24),
                              border: Border.all(
                                color: seleccionado
                                    ? MiTema.azul
                                    : Colors.transparent,
                                width: 2,
                              ),
                              boxShadow: seleccionado
                                  ? [
                                      BoxShadow(
                                        color: MiTema.azul.withOpacity(0.3),
                                        blurRadius: 20,
                                        offset: const Offset(0, 10),
                                      ),
                                    ]
                                  : [
                                      BoxShadow(
                                        color: Colors.grey.withOpacity(0.1),
                                        blurRadius: 10,
                                        offset: const Offset(0, 5),
                                      ),
                                    ],
                            ),
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                AnimatedScale(
                                  scale: seleccionado ? 1.1 : 1.0,
                                  duration: const Duration(milliseconds: 300),
                                  child: Container(
                                    padding: const EdgeInsets.all(16),
                                    decoration: BoxDecoration(
                                      color: seleccionado
                                          ? MiTema.celeste.withOpacity(0.1)
                                          : Colors.grey[100],
                                      shape: BoxShape.circle,
                                    ),
                                    child: Icon(
                                      rol['icono'] as IconData,
                                      size: 50,
                                      color: seleccionado
                                          ? MiTema.azul
                                          : Colors.grey[400],
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 16),
                                Text(
                                  rol['nombre'] as String,
                                  style: TextStyle(
                                    color: seleccionado
                                        ? MiTema.azul
                                        : Colors.grey[600],
                                    fontWeight: FontWeight.bold,
                                    fontSize: 14,
                                  ),
                                  textAlign: TextAlign.center,
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  rol['description'] as String,
                                  style: TextStyle(
                                    color: Colors.grey[500],
                                    fontSize: 11,
                                  ),
                                  textAlign: TextAlign.center,
                                ),
                              ],
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                  ),
                ),
              ),

              Padding(
                padding: const EdgeInsets.all(24.0),
                child: StunningButton(
                  onPressed: () {
                    if (_rolSeleccionado != null) {
                      Navigator.push(
                        context,
                        StunningPageRoute(
                          page: RegisterScreen(rolInicial: _rolSeleccionado!),
                        ),
                      );
                    }
                  },
                  text: 'CONTINUAR',
                  icon: Icons.arrow_forward_rounded,
                ),
              ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }
}
