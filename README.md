# Streakify

Aplicacion Flutter para seguimiento de habitos diarios.

## Desarrollo

```powershell
flutter pub get
flutter analyze
flutter run
```

Los datos se guardan localmente en SQLite. Las notificaciones requieren permiso
del sistema y se programan para las 12:00 y las 20:00.

## APK de pruebas

```powershell
flutter build apk --release --no-tree-shake-icons
```

El resultado queda en `build/app/outputs/flutter-apk/app-release.apk`.

## Firma para publicar

El paquete Android es `com.streakify.app`. Para publicar se debe configurar una
keystore privada y sustituir la firma debug de `android/app/build.gradle.kts`
por una configuracion release. No se deben guardar la keystore ni las
credenciales en el repositorio.
