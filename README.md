# 💚 Card Manager Pro — Studio Beta 1.0.3

> **Tu dinero. Tus tarjetas. Un panorama más claro.**
>
> Aplicación iOS privada, desarrollada en **SwiftUI**, con datos capturados **manualmente**. Sin SDK bancario, sin acceso a Apple Wallet y sin pagos reales.

![Versión](https://img.shields.io/badge/versi%C3%B3n-1.0.3-49e773) ![Build](https://img.shields.io/badge/build-103-222222) ![iOS](https://img.shields.io/badge/iOS-17%2B-444444) ![Estado](https://img.shields.io/badge/estado-beta%20sin%20probar%20en%20dispositivo-f3b353)

## ¿Qué cambió frente a la versión 1.0.1?

Este rediseño **no se limita a cambiar colores**. Organiza la aplicación por tipo de producto y separa cuidadosamente conceptos que en un banco no significan lo mismo: deuda actual, dinero propio, estado de cuenta, saldo al corte, pago para no generar intereses y cuota programada.

| Área | Rediseño y comportamiento |
| --- | --- |
| **Inicio** | Deuda total; importe conocido a pagar en el mes seleccionado; dinero en débito; crédito libre; barra de utilización; cobertura de pagos conocidos; carrusel de tarjetas y actividad reciente |
| **Planeador mensual** | Consulta meses anteriores o futuros, importes confirmados de tarjetas, cuotas programadas de préstamos y MSI informativos (sin sumarlos dos veces) |
| **Tarjetas** | Filtros por crédito/débito/préstamos; saldos específicos del producto; acceso a información detallada |
| **Débito** | Saldo real, entradas/salidas registradas, depósitos, ingresos, gastos, transferencias externas y transferencias entre tus cuentas; **sin fechas de corte ni MSI** |
| **Crédito** | Límite y utilización, fechas habituales de corte/pago, compra con fecha de contabilización distinta, captura de estado de cuenta, compras MSI y movimientos |
| **Préstamos** | Saldo de deuda separado, cuota habitual y calendario individual con importes, fechas y pagos parciales |
| **Movimientos** | Búsqueda, filtros, selección por mes, edición, categorías de gastos y confirmación para eliminar; pares vinculados protegidos contra edición individual |
| **Wallet** | Tarjeta grande seleccionada, lista de tarjetas con selección individual y acceso directo al detalle |
| **Análisis** | Utilización global, barras horizontales de deuda con nombres completos, entradas/salidas de débito de seis meses y categorías de gasto |
| **Respaldos** | Exportación e importación JSON conservadas; incluye estados de cuenta nuevos y referencias de pagos vinculados |

## 📆 ¿Qué significa «A pagar este mes»?

**Nunca se calcula como la suma de las deudas completas.** Se construye únicamente a partir de:

1. **Tarjetas de crédito:** pago **para no generar intereses** del estado de cuenta que capturaste, menos el importe pagado que registraste para ese estado de cuenta.
2. **Préstamos:** cuotas programadas que vencen durante el mes elegido y que todavía no figuran como pagadas en el calendario.
3. **MSI de tarjetas:** se muestran en un renglón **informativo**, sin añadirse nuevamente al total de tarjetas, porque ya pueden estar incluidos en el pago del estado de cuenta.

Si falta un estado de cuenta o el plan de un préstamo, el tablero avisa que el **total conocido es parcial**. No inventa el pago mínimo ni presenta el saldo total como una obligación inmediata.

**Ejemplo:** deuda total $20,000; pago para no generar intereses confirmado $1,800; préstamo con cuota pendiente $1,200. El total conocido a pagar durante ese mes es $3,000, **no $20,000**. Los MSI se muestran por separado, sin duplicarse. Si alguna tarjeta carece de estado de cuenta, faltarán importes por confirmar.

### Capturar un estado de cuenta

1. Abre una tarjeta de **crédito**.
2. Selecciona **Capturar corte**.
3. Escribe **saldo al corte**, **pago para no generar intereses**, **pago mínimo**, **fecha de corte**, **fecha límite** e importe ya pagado de ese periodo.
4. Guarda. El planeador mensual mostrará el importe confirmado en el mes del vencimiento.

Registrar el estado **no mueve dinero de ninguna cuenta**. Debes registrar los pagos cuando realmente se realizan.

## 💸 Débito: reglas diferentes a las de crédito

El saldo disponible de una cuenta de débito es tu **dinero propio**; no se presenta como «línea de crédito - usado» en la interfaz. El formato heredado de almacenamiento se conserva internamente para no romper respaldos anteriores.

| Operación | Saldo de débito | ¿Cuenta como ingreso o gasto de consumo? |
| --- | --- | --- |
| Depósito / ingreso | Aumenta | Ingreso manual |
| Gasto / compra | Disminuye | Gasto |
| Transferencia recibida desde fuera | Aumenta | Entrada de efectivo, no necesariamente ingreso ganado |
| Transferencia enviada fuera | Disminuye | Salida de efectivo, no necesariamente gasto de consumo |
| Transferencia entre dos cuentas propias | Resta de origen, suma en destino | **No modifica el dinero total ni es un ingreso nuevo** |
| Pago de tarjeta/préstamo desde débito | Disminuye débito, disminuye deuda | Es una transferencia de pago, **no un gasto nuevo** |
| Devolución | Aumenta | Reintegro |

El resumen de **entradas y salidas de efectivo** incluye transferencias externas y pagos de deuda, pero excluye transferencias entre tus cuentas. El análisis de **gastos por categoría** cuenta compras y gastos de consumo y excluye pagos de tarjeta para evitar duplicaciones.

### Pago vinculado desde débito

En el detalle de un producto de crédito o préstamo: **Registrar pago desde débito**. Selecciona cuenta origen, monto y fecha; si es tarjeta, puedes asociarlo a un estado de cuenta específico. Tras la confirmación, se registra un par de movimientos ligado por un identificador: salida de débito y reducción de deuda. Si se elimina el par, se revierten ambos saldos y el avance del estado de cuenta al que estuviera ligado.

**Esto registra un pago ya realizado:** la aplicación **no transfiere dinero por ti**.

## 📊 Indicadores de utilización

Usamos rangos gráficos orientativos por tarjeta y globales: **verde ≤30 %**, **amarillo >30 % a 60 %**, **naranja >60 %**. También se estima cuánto reducir el saldo para acercarse al 30 %.

CONDUSEF recomienda cuidar la proporción utilizada y pagar oportunamente, pero **los colores de la app no son un score oficial de Buró ni un indicador universal de aprobación bancaria**. La salud financiera completa requiere ingresos, gastos, endeudamiento y circunstancias personales que no pueden deducirse solamente del uso del crédito.

## 🔒 Privacidad, compatibilidad y respaldos

- La información sigue guardándose en `Application Support/cardmanager.json` **localmente**.
- Bundle ID **sin cambios**: `com.cardmanager.personal.app`.
- Se conservan los datos existentes: cuentas, movimientos, planes y calendarios individuales. Los campos nuevos tienen valores predeterminados al leer respaldos anteriores.
- Se recomienda **exportar JSON desde Más → Exportar respaldo ANTES de actualizar**.
- La importación de JSON **reemplaza** el conjunto actual; no fusiona automáticamente.
- Nunca publiques respaldos de datos personales, certificados `.p12`, `.mobileprovision` ni contraseñas.
- No hay acceso a bancos, consulta de Buró, conexión con Apple Pay, ni respaldo iCloud automático.

### Limitaciones a tener presentes

- Un movimiento retroactivo afecta el saldo manual registrado y su periodo de corte **estimado**, pero la fecha real de contabilización puede ser distinta; contrástala con el estado de cuenta.
- El pago para no generar intereses **no puede inferirse de manera segura del saldo utilizado**; debes capturarlo.
- La suma de cuotas futuras **no equivale necesariamente** al saldo de liquidación anticipada del préstamo (intereses, seguros, comisiones).
- Los pagos marcados en el **calendario de cuotas** no alteran automáticamente el saldo del banco: puedes registrar por separado el movimiento real o el pago vinculado, sin volver a contabilizarlo como gasto de consumo.
- Si concilias manualmente el saldo de una cuenta, una reversión antigua puede ser rechazada para evitar un saldo de débito negativo.
- La gráfica histórica refleja movimientos **registrados**, no transacciones bancarias sincronizadas.
- **Es un proyecto fuente beta. No fue compilado con Xcode ni probado en un iPhone durante esta entrega.** La verificación final se realiza en un runner macOS o Xcode y en el dispositivo.

## 🖥️ Compilación desde Windows con GitHub Actions

1. Crea un repositorio **privado** o utiliza tu repositorio actual.
2. Sube **todo el contenido del ZIP** conservando las carpetas `CardManager/`, `.github/workflows/`, `Tests/`, `project.yml` y los archivos `.md`.
3. Ve a **Actions → Build unsigned iOS IPA → Run workflow**, selecciona la rama y ejecuta.
4. El workflow ejecuta pruebas del motor financiero, genera el proyecto con XcodeGen, lo compila usando `xcodebuild`, crea `Payload/CardManager.app` y empaqueta el IPA sin firmar.
5. Descarga **CardManager-unsigned-IPA**, extrae el `.ipa`, y fírmalo en ESign con certificado/perfil válidos para el Bundle ID y tu dispositivo.
6. **No desinstales la app anterior** antes de exportar tu respaldo y comprobar que la actualización conserva datos.

### Compilar manualmente en macOS

```bash
brew install xcodegen
xcodegen generate
xcodebuild -project CardManager.xcodeproj -scheme CardManager \
  -configuration Release -sdk iphoneos \
  -destination 'generic/platform=iOS' \
  -derivedDataPath build CODE_SIGNING_ALLOWED=NO build
```

### Ejecutar pruebas del motor financiero (macOS o Linux con Swift)

```bash
swiftc CardManager/FinanceIntelligence.swift \
       CardManager/Models.swift \
       Tests/FinanceEngineChecks.swift \
       -o finance-checks
./finance-checks
```

Las pruebas incluyen asignación a cortes, días 28/29/30/31, cambio de año, depósito/gasto de débito, compra/pago de crédito, saldo insuficiente y lectura de un respaldo sin campos nuevos.

## 🗂️ Estructura principal

```text
CardManager/
├── CardManager/
│   ├── CardManagerApp.swift
│   ├── Models.swift
│   ├── FinanceStore.swift
│   ├── FinanceIntelligence.swift  # reglas comprobables sin SwiftUI
│   ├── StudioScreens.swift        # rediseño: Inicio, planeador, débito,
│   │                             # movimientos, análisis, detalle, Wallet
│   ├── Views.swift                # formularios y punto de entrada de pestañas
│   ├── PaymentFeatures.swift      # MSI/préstamos
│   ├── FinancePlusViews.swift      # línea de cuotas y salud de utilización
│   ├── PremiumScreens.swift       # estilos compartidos, calendario, Más
│   └── ProFeatures.swift
├── Tests/
│   └── FinanceEngineChecks.swift
├── .github/workflows/build-ipa.yml
├── project.yml
├── CHANGELOG.md
├── QA_CHECKLIST.md
└── README.md
```

## 📚 Referencias para el rediseño

- CONDUSEF — [Conceptos del estado de cuenta](https://www.gob.mx/condusef/articulos/que-debes-saber-de-una-tarjeta-de-credito?idiom=es) y [uso responsable de crédito](https://www.gob.mx/condusef/es/articulos/lleva-una-buena-relacion-con-el-credito?idiom=es).
- YNAB — [Los pagos de tarjetas se tratan como transferencias vinculadas](https://support.ynab.com/en_us/credit-card-payments-a-guide-r1_506Q1j).
- Comentarios de usuarios de Monarch Money sobre [proyección de efectivo](https://www.reddit.com/r/MonarchMoney/comments/1vdng6q/feature_requests/), [calendario de pagos claro](https://www.reddit.com/r/MonarchMoney/comments/1ijhnzf) y [control de recurrentes](https://www.reddit.com/r/MonarchMoney/comments/1w2m0ah/monarch_needs_a_true_manual_recurring_mode/).

**Estado:** Studio Beta 1.0.3 / Build 103. Código fuente, no lanzamiento público validado.
