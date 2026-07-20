import 'package:flutter_test/flutter_test.dart';
import 'package:mobile/models/vehicle_model.dart';
import 'package:mobile/providers/vehicle_provider.dart';
import 'package:mobile/repositories/vehicle_repository.dart';

class FakeVehicleRepository extends VehicleRepository {
  FakeVehicleRepository(this.vehicle);

  final VehicleModel vehicle;

  @override
  Future<VehicleModel> registerVehicle(Map<String, dynamic> data) async {
    return vehicle;
  }
}

VehicleModel buildVehicle({
  required int id,
  required String placa,
  required String marca,
  required String modelo,
}) {
  return VehicleModel(
    idVehiculo: id,
    placa: placa,
    marca: marca,
    modelo: modelo,
    tipoVehiculo: 'Camion',
    rolVehiculo: 'Propietario',
  );
}

void main() {
  test(
    'registerVehicle replaces existing vehicle instead of duplicating it',
    () async {
      final updatedVehicle = buildVehicle(
        id: 1,
        placa: 'ABC123',
        marca: 'Mercedes-Benz',
        modelo: '2026',
      );
      final provider = VehicleProvider(
        repository: FakeVehicleRepository(updatedVehicle),
      );

      provider.vehicles.add(
        buildVehicle(
          id: 1,
          placa: 'ABC123',
          marca: 'Sin Registrar',
          modelo: 'Sin Registrar',
        ),
      );

      await provider.registerVehicle({
        'placa': 'ABC123',
        'marca': 'Mercedes-Benz',
        'modelo': '2026',
        'tipo_vehiculo': 'Camion',
      });

      expect(provider.vehicles, hasLength(1));
      expect(provider.vehicles.single.marca, 'Mercedes-Benz');
      expect(provider.vehicles.single.modelo, '2026');
    },
  );
}
