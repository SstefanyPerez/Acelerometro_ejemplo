// Enlaces (interop) con las APIs de sensores del navegador.
// Solo se compila en Web: lo importan permisos_web.dart y fuente_sensores_web.dart.

import 'dart:js_interop';
import 'dart:js_interop_unsafe';

import 'package:web/web.dart' as web;

/// Constructor `Accelerometer()` de la Generic Sensor API (Chrome, Edge).
/// package:web no lo trae, así que lo declaramos nosotros.
@JS('Accelerometer')
extension type AcelerometroJs._(JSObject _) implements web.Sensor, JSObject {
  external factory AcelerometroJs();
}

/// Clase `DeviceMotionEvent` del navegador. En Safari (iOS 13+) tiene el
/// método estático `requestPermission()`, que muestra el diálogo de permiso.
@JS('DeviceMotionEvent')
extension type ClaseDeviceMotion._(JSObject _) implements JSObject {
  external static JSPromise<JSString> requestPermission();
}

/// Objeto `{name: 'accelerometer'}` que recibe `navigator.permissions.query`.
extension type DescriptorPermiso._(JSObject _) implements JSObject {
  external factory DescriptorPermiso({String name});
}

/// true si el navegador tiene la Generic Sensor API (Chrome, Edge, Opera…).
bool get tieneGenericSensor =>
    globalContext.has('Accelerometer') && globalContext.has('Gyroscope');

/// true si el navegador tiene el evento clásico 'devicemotion'.
bool get tieneDeviceMotion => globalContext.has('DeviceMotionEvent');

/// true en Safari de iPhone/iPad: es el único que exige
/// `DeviceMotionEvent.requestPermission()`.
bool get esSafariConPermiso =>
    globalContext
        .getProperty<JSFunction?>('DeviceMotionEvent'.toJS)
        ?.has('requestPermission') ??
    false;
