// Fuente de datos para Android, iOS y escritorio: usa sensors_plus tal cual.

import 'package:sensors_plus/sensors_plus.dart';

Stream<AccelerometerEvent> acelerometro(Duration samplingPeriod) =>
    accelerometerEventStream(samplingPeriod: samplingPeriod);

Stream<UserAccelerometerEvent> acelerometroUsuario(Duration samplingPeriod) =>
    userAccelerometerEventStream(samplingPeriod: samplingPeriod);

Stream<GyroscopeEvent> giroscopio(Duration samplingPeriod) =>
    gyroscopeEventStream(samplingPeriod: samplingPeriod);
