
# 💚 Card Manager Pro

### Tu dinero, tus tarjetas, todo bajo control.

![Version](https://img.shields.io/badge/Version-1.7.0-39d66b)
![iOS](https://img.shields.io/badge/iOS-17%2B-black)
![Swift](https://img.shields.io/badge/Swift-5-orange)
![SwiftUI](https://img.shields.io/badge/Framework-SwiftUI-blue)
![Status](https://img.shields.io/badge/Status-Beta-yellow)

---

## 📱 ¿Qué es Card Manager Pro?

**Card Manager Pro** es una aplicación de administración financiera personal para iPhone, desarrollada con SwiftUI.

Su objetivo es ayudarte a gestionar tus tarjetas de crédito y débito, préstamos, compras a meses, movimientos y obligaciones financieras desde una sola aplicación.

Cuenta con una interfaz moderna de estilo premium, modo oscuro, acentos verde neón, tarjetas visuales y herramientas de análisis financiero.

> Card Manager Pro es una aplicación de registro manual. No está afiliada a instituciones bancarias ni consulta automáticamente sus sistemas.

---

## ✨ Características principales

### 🏠 1. Dashboard financiero

Una pantalla de inicio que presenta un panorama general de tus finanzas.

- Dinero propio disponible.
- Crédito total autorizado.
- Crédito utilizado.
- Crédito disponible.
- Deuda total registrada.
- Préstamos pendientes.
- Balance financiero estimado.
- Próximos pagos.
- Acceso rápido a tus tarjetas.

Los saldos de débito, crédito y préstamos se presentan por separado para evitar confundir dinero propio con dinero prestado.

### 💳 2. Administración de tarjetas

Registra y administra diferentes productos financieros.

**Tarjetas de crédito**
- Institución bancaria.
- Nombre personalizado.
- Línea de crédito.
- Saldo utilizado.
- Crédito disponible.
- Porcentaje de utilización.
- Fecha de corte.
- Fecha límite de pago.
- Compras a meses.

**Tarjetas de débito**
- Institución bancaria.
- Saldo disponible.
- Ingresos y gastos.
- Historial de movimientos.
- Transferencias entre cuentas propias.

**Préstamos**
- Institución financiera.
- Monto original.
- Saldo pendiente.
- Cantidad de mensualidades.
- Mensualidad programada.
- Pagos realizados.
- Próximo vencimiento.

### 🪪 3. Wallet visual

Una sección inspirada en la presentación de tarjetas digitales.

- Tarjetas con diseños diferenciados.
- Identificación visual de instituciones.
- Consulta de saldos.
- Selección individual de tarjetas.
- Acceso a detalles y movimientos.
- Diseño adaptado a iPhone.

### 📆 4. Compras a MSI y préstamos

Organiza tus compras financiadas y préstamos mediante planes de pago.

- Nombre del producto o préstamo.
- Importe registrado.
- Número de mensualidades.
- Mensualidad programada.
- Mensualidades pagadas.
- Mensualidades pendientes.
- Fecha del siguiente vencimiento.
- Cuenta regresiva.
- Calendario individual de cuotas.
- Modificación de importes y fechas.
- Registro de pagos parciales.
- Confirmación antes de registrar pagos.

Cada compra puede administrarse independientemente.

> Los cálculos de mensualidades no sustituyen el estado de cuenta oficial. Los intereses y comisiones pueden modificar el saldo real.

### 📊 5. Análisis financiero

Herramientas visuales para comprender tu situación financiera.

- Gráficas de utilización de crédito.
- Distribución de deuda por tarjeta.
- Barras horizontales con nombres legibles.
- Comparación de crédito disponible y utilizado.
- Resumen de préstamos.
- Seguimiento de saldos.
- Indicadores de utilización.

### 🟢 6. Indicadores de utilización crediticia

Card Manager Pro utiliza referencias orientativas para identificar el porcentaje de crédito utilizado.

| Utilización | Indicador | Interpretación |
|---|---|---|
| 0 % – 30 % | 🟢 Verde | Dentro de la referencia |
| Más de 30 % – 60 % | 🟡 Amarillo | Utilización moderada |
| Más de 60 % | 🟠 Naranja | Utilización elevada |

También permite estimar cuánto tendrías que reducir tu saldo para alcanzar una utilización del 30 %.

**Importante:** estos rangos no constituyen una calificación oficial de Buró de Crédito ni garantizan una mejora de tu historial.

La puntualidad, capacidad de pago, ingresos y nivel de endeudamiento también son factores importantes.

### 💰 7. Control de débito

Administra el dinero que realmente tienes disponible.

- Saldo individual por cuenta.
- Dinero total disponible.
- Registro de ingresos.
- Registro de gastos.
- Transferencias entre cuentas propias.
- Historial de movimientos.

Las transferencias entre cuentas propias no deben contabilizarse como ingresos nuevos.

### 📁 8. Respaldos

Herramientas para conservar y recuperar tu información.

- Exportación de respaldos JSON.
- Importación de respaldos.
- Almacenamiento local.
- Confirmación antes de reemplazar datos.

**Advertencia:** importar un respaldo reemplaza los datos actuales; no los fusiona.

---

## 🛠️ Tecnologías utilizadas

- Swift 5
- SwiftUI
- Xcode
- XcodeGen
- GitHub Actions
- Almacenamiento JSON local
- iOS 17 o posterior

La aplicación no requiere SDKs bancarios externos.

---

## 📂 Estructura del proyecto

```text
CardManager/
├── CardManager/
│   ├── CardManagerApp.swift
│   ├── Models.swift
│   ├── FinanceStore.swift
│   ├── Views.swift
│   ├── PremiumScreens.swift
│   ├── FinancePlusViews.swift
│   ├── PaymentFeatures.swift
│   └── ProFeatures.swift
├── .github/
│   └── workflows/
│       └── build-ipa.yml
├── project.yml
├── .gitignore
└── README.md
```

---

## 🚀 Compilación desde Windows

Card Manager Pro puede compilarse mediante GitHub Actions utilizando un runner macOS.

### Paso 1. Preparar el repositorio

Sube los archivos a un repositorio privado de GitHub, respetando su estructura original.

### Paso 2. Ejecutar GitHub Actions

1. Abre tu repositorio.
2. Entra a **Actions**.
3. Selecciona **Build unsigned iOS IPA**.
4. Pulsa **Run workflow**.
5. Selecciona la rama `main`.
6. Ejecuta el workflow.

### Paso 3. Descargar el IPA

Cuando termine correctamente:

1. Abre la ejecución.
2. Busca la sección **Artifacts**.
3. Descarga `CardManager-unsigned-IPA`.
4. Extrae el archivo IPA.

### Paso 4. Instalar mediante ESign

1. Importa el IPA en ESign.
2. Selecciona un certificado válido.
3. Firma la aplicación.
4. Instálala en el iPhone.

El certificado y el perfil de aprovisionamiento deben ser compatibles con el dispositivo y el identificador de la aplicación.

---

## 💻 Compilación manual con Xcode

En macOS:

```bash
brew install xcodegen

xcodegen generate

xcodebuild \
  -project CardManager.xcodeproj \
  -scheme CardManager \
  -configuration Release \
  -sdk iphoneos \
  -destination 'generic/platform=iOS' \
  -derivedDataPath build \
  CODE_SIGNING_ALLOWED=NO \
  build
```

La aplicación compilada se encontrará en:

`build/Build/Products/Release-iphoneos/CardManager.app`

---

## 🔐 Seguridad y almacenamiento

Card Manager Pro almacena la información financiera localmente en el dispositivo.

Ruta utilizada:

`Application Support/cardmanager.json`

**Bundle ID:**

`com.cardmanager.personal.app`

Recomendaciones:

- Exportar respaldos periódicamente.
- No compartir archivos que contengan información financiera.
- No publicar certificados P12.
- No publicar perfiles de aprovisionamiento.
- No eliminar la aplicación antes de respaldar los datos.

---

## ⚠️ Limitaciones actuales

- No existe sincronización bancaria automática.
- No consulta directamente Buró de Crédito.
- No detecta automáticamente pagos mediante Apple Pay.
- No dispone de sincronización iCloud.
- Los datos financieros requieren actualización manual.
- Las fechas de pago deben verificarse con cada institución.
- Los indicadores financieros son orientativos.
- La aplicación requiere pruebas de compilación y funcionamiento antes de considerarse lista para distribución pública.

---

## 🧪 Pruebas recomendadas

Antes de publicar una versión estable:

- [ ] Verificar compilación en Xcode.
- [ ] Probar instalación mediante ESign.
- [ ] Comprobar conservación de datos al actualizar.
- [ ] Registrar y editar tarjetas.
- [ ] Registrar y editar préstamos.
- [ ] Agregar compras a MSI.
- [ ] Editar mensualidades individuales.
- [ ] Registrar pagos parciales.
- [ ] Evitar confirmaciones accidentales de pagos.
- [ ] Validar saldos de débito.
- [ ] Revisar gráficas e indicadores.
- [ ] Exportar e importar respaldos.
- [ ] Comprobar navegación y diseño en iPhone.

---

## 🗺️ Próximas mejoras

- Notificaciones automáticas de vencimientos.
- Integración con Atajos de iOS.
- Widgets para pantalla de inicio.
- Protección adicional mediante Face ID.
- Sincronización opcional con iCloud.
- Presupuestos mensuales.
- Administración de suscripciones.
- Proyecciones de deuda.
- Herramientas adicionales de planificación financiera.

---

## 📌 Información del proyecto

**Nombre:** Card Manager Pro

**Versión:** 1.7.0

**Compilación:** 170

**Plataforma:** iOS

**Lenguaje:** Swift

**Interfaz:** SwiftUI

**Estado:** Beta / En pruebas

---

### 💚 Card Manager Pro

**Controla tu dinero. Organiza tus pagos. Entiende tus finanzas.**

Desarrollado para ofrecer una experiencia de administración financiera personal moderna, organizada y sencilla.
