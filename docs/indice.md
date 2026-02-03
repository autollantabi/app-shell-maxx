# Índice de documentación técnica

Índice de todos los documentos del proyecto Shell Maxx, con propósito, cuándo usarlos y orden de lectura recomendado para un desarrollador nuevo.

---

## Tabla de documentos

| Documento | Propósito | Cuándo usarlo |
|-----------|-----------|----------------|
| [setup.md](setup.md) | Requisitos del sistema, variables de entorno, pasos para ejecutar en local, errores comunes. | Primera vez que configuras el proyecto o cuando algo falla al ejecutar o al hacer build. |
| [arquitectura.md](arquitectura.md) | Arquitectura general, árbol de carpetas, responsabilidades, cómo añadir pantallas o providers, patrones usados. | Entender la estructura del código y dónde tocar para añadir o modificar funcionalidad. |
| [apis.md](apis.md) | Cliente HTTP, URL/env, cabeceras, endpoints por dominio, servicios que los usan, riesgos. | Integrar con el backend, añadir endpoints, depurar llamadas API o entender dependencias externas. |
| [flujo-funcional.md](flujo-funcional.md) | Flujos principales: arranque, login, recuperar contraseña, home/puntos/catálogo, canje, perfil y cierre de sesión; auth y permisos por rol. | Entender qué ocurre paso a paso en cada flujo y cómo se relacionan auth y roles. |
| [guia-proyecto.md](guia-proyecto.md) | Onboarding: qué es el proyecto, cómo empezar, dónde está cada cosa, resumen de APIs, flujo para añadir pantallas, decisiones históricas. | Llegada al proyecto; referencia rápida de “dónde está X” y “cómo añado Y”. |
| [decisiones-tecnicas.md](decisiones-tecnicas.md) | Justificación de tecnologías (Flutter, Provider, HTTP, auth, persistencia, navegación, etc.), alternativas y trade-offs. | Entender por qué está hecho así y qué costes/beneficios tiene cada decisión. |
| [despliegue.md](despliegue.md) | Proceso de build (Android/iOS), configuración de ambientes, consideraciones para producción, firma Android. | Hacer builds de release, publicar en stores o desplegar en entorno de producción. |
| [pendientes.md](pendientes.md) | Mejoras sugeridas, deuda técnica detectada, suposiciones y partes no claras. | Planificar mejoras, refactors o aclaraciones con el equipo/backend. |
| [indice.md](indice.md) | Este archivo: índice de la documentación y orden de lectura. | Encontrar el documento adecuado y seguir un orden de lectura coherente. |

---

## Orden de lectura recomendado (desarrollador nuevo)

1. **[README.md](../README.md)** (raíz) — Visión general, problema, stack, casos de uso, enlaces a setup e índice.
2. **[guia-proyecto.md](guia-proyecto.md)** — Onboarding: qué es el proyecto, cómo empezar, dónde está cada cosa.
3. **[setup.md](setup.md)** — Configurar entorno y ejecutar el proyecto en local.
4. **[arquitectura.md](arquitectura.md)** — Estructura, carpetas y cómo añadir pantallas o funcionalidad.
5. **[apis.md](apis.md)** — Qué APIs se consumen y desde dónde.
6. **[flujo-funcional.md](flujo-funcional.md)** — Flujos de login, canje, perfil y permisos.
7. **[decisiones-tecnicas.md](decisiones-tecnicas.md)** — Por qué están elegidas las tecnologías y trade-offs.
8. **[despliegue.md](despliegue.md)** — Cuando vayas a hacer builds de release o desplegar.
9. **[pendientes.md](pendientes.md)** — Mejoras y deuda técnica al planificar trabajo futuro.

---

## Uso como plantilla

Para replicar esta estructura en otro repositorio:

1. **Raíz**: README con descripción, problema, tipo de app, stack, casos de uso, guía rápida de ejecución (enlace a `docs/setup.md`) y enlace al índice (`docs/indice.md`).
2. **docs/** (sin README dentro de docs):
   - `setup.md` — Requisitos, variables de entorno, pasos de ejecución, errores comunes.
   - `arquitectura.md` — Arquitectura, carpetas, responsabilidades, cómo añadir pantallas/funcionalidad, patrones.
   - `apis.md` — Si hay APIs: cliente HTTP, URL/env, cabeceras, endpoints, servicios que los usan, riesgos.
   - `flujo-funcional.md` — Flujos principales paso a paso; auth y permisos si aplican.
   - `guia-proyecto.md` — Onboarding: qué es el proyecto, cómo empezar, dónde está cada cosa, flujo para añadir algo, decisiones históricas.
   - `decisiones-tecnicas.md` — Justificación de tecnologías, alternativas, trade-offs.
   - `despliegue.md` — Build, ambientes, consideraciones de producción.
   - `pendientes.md` — Mejoras, deuda técnica, suposiciones o partes no claras.
   - `indice.md` — Tabla documento / propósito / cuándo usarlo, orden de lectura recomendado, sección “Uso como plantilla”.

Adaptar nombres y contenido al proyecto concreto; mantener coherencia entre documentos y evitar duplicar información innecesaria.
