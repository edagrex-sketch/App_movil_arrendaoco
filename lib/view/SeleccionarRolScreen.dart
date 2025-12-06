import 'package:arrendaoco/theme/tema.dart';
import 'package:flutter/material.dart';
import 'registrar.dart';

class SeleccionarRolScreen extends StatefulWidget {
  const SeleccionarRolScreen({super.key});

  @override
  _SeleccionarRolScreenState createState() => _SeleccionarRolScreenState();
}

class _SeleccionarRolScreenState extends State<SeleccionarRolScreen> {
  String? _rolSeleccionado;

  final roles = [
    {
      "nombre": "Quiero publicitar mi propiedad",
      "rol": "Arrendador",
      "icono": Icons.home_work,
    },
    {
      "nombre": "Buscar lugares para rentar",
      "rol": "Inquilino",
      "icono": Icons.people_alt,
    },
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            SizedBox(height: 36),
            Text(
              '¡Hola!',
              style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 12),
            Text(
              '¿Cuál es tu objetivo principal en la app?',
              style: TextStyle(fontSize: 19),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: 28),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: roles.map((rol) {
                final seleccionado = _rolSeleccionado == rol["rol"];
                return GestureDetector(
                  onTap: () {
                    setState(() {
                      _rolSeleccionado = rol["rol"] as String;
                    });
                  },
                  child: Column(
                    children: [
                      Container(
                        margin: EdgeInsets.symmetric(horizontal: 16),
                        width: 110,
                        height: 110,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: seleccionado
                              ? MiTema.azul.withOpacity(0.19)
                              : Colors.white,
                          border: Border.all(
                            color: seleccionado ? MiTema.azul : Colors.grey,
                            width: 3,
                          ),
                          boxShadow: seleccionado
                              ? [
                                  BoxShadow(
                                    color: MiTema.vino.withOpacity(0.22),
                                    blurRadius: 9,
                                    spreadRadius: 3,
                                  ),
                                ]
                              : [],
                        ),
                        child: Center(
                          child: Icon(
                            rol['icono'] as IconData,
                            size:
                                70, // ¡El ícono abarca la mayor parte del círculo!
                            color: MiTema.vino,
                          ),
                        ),
                      ),
                      SizedBox(height: 10),
                      SizedBox(
                        width: 120,
                        child: Text(
                          rol['nombre'] as String,
                          style: TextStyle(
                            color: MiTema.vino,
                            fontWeight: FontWeight.bold,
                            fontSize: 15,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ],
                  ),
                );
              }).toList(),
            ),
            Spacer(),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 28.0),
              child: SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _rolSeleccionado == null
                      ? null
                      : () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) =>
                                  RegisterScreen(rolInicial: _rolSeleccionado!),
                            ),
                          );
                        },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: MiTema.azul,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                    padding: EdgeInsets.symmetric(horizontal: 50, vertical: 13),
                  ),
                  child: Text('Continuar'),
                ),
              ),
            ),
            SizedBox(height: 25),
          ],
        ),
      ),
    );
  }
}
