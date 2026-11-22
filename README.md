# Card Manager — SwiftUI iOS

Proyecto fuente de una primera versión funcional, sin SDKs externos. Incluye cuatro pestañas: resumen, cuentas, movimientos y análisis. Persiste datos en Application Support/cardmanager.json en el dispositivo.

## Compilar desde Windows usando un Mac remoto o CI macOS

1. Subir esta carpeta a un repositorio privado de GitHub.
2. Usar un runner macOS con Xcode y ejecutar `brew install xcodegen` y `xcodegen generate`.
3. Ejecutar `xcodebuild -project CardManager.xcodeproj -scheme CardManager -configuration Release -sdk iphoneos -destination 'generic/platform=iOS' -derivedDataPath build CODE_SIGNING_ALLOWED=NO build`.
4. Para empaquetar un IPA sin firmar, crear `Payload/CardManager.app` copiando `build/Build/Products/Release-iphoneos/CardManager.app`; comprimir la carpeta Payload como ZIP y cambiar la extensión a `.ipa`.
5. Importar el IPA sin firmar en ESign, firmarlo con un certificado válido y un provisioning profile compatible con el bundle ID, e instalarlo.

**Nota:** El certificado P12 y el perfil `.mobileprovision` no deben compartirse en repositorios públicos. No todos los certificados empresariales permiten instalar cualquier app/dispositivo.

## Límites conocidos de esta versión

- No incluye integración bancaria, detección automática de Apple Pay, ni atajos App Intents todavía.
- Fechas de corte/pago son días del mes informativos, sin notificaciones automáticas.
- No incluye edición de cuentas ni respaldo iCloud. Eliminar la app elimina los datos locales si no hay respaldo del dispositivo.
- La contabilidad de débito usa el mismo modelo `límite - utilizado`, por lo que el campo límite representa el saldo inicial de referencia.
- Es un proyecto fuente preparado para compilación, no un IPA compilado o probado en dispositivo.
