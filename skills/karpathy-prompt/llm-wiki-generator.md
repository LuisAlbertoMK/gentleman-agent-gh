# LLM Wiki Generator — Karpathy Pattern v1.1

## Concepto

Pre-compilar contexto del proyecto ANTES de sesiones de chat con IA.
Resultado: 90% reducción de tokens por sesión.

## Estructura

```
wiki/
├── index.md              # Mapa liviano (~200 tokens)
├── proyecto.md          # Overview del proyecto
├── arquitectura.md       # Decisiones de diseño
├── api.md                # Endpoints y contratos
├── componentes.md        # UI y componentes
└── dependencias.md       # Deps y configuraciones
```

## index.md Template

```markdown
# Wiki Index

## Proyecto
[Overview] → proyecto.md

## Arquitectura
[Decisiones] → arquitectura.md

## API
[Endpoints] → api.md

## UI
[Componentes] → componentes.md

## Config
[Deps/Env] → dependencias.md
```

## Generador de Context Map

Para proyectos de código, usar AST parsing:

```typescript
// Ejemplo: TypeScript context compiler
import ts from 'typescript';

function compileProjectContext(rootDir: string) {
  const files = ts.sys.readDirectory(rootDir, ['.ts', '.tsx']);
  
  return {
    routes: extractRoutes(files),
    components: extractComponents(files),
    dependencies: extractDeps(files),
    schemas: extractTypes(files),
    hotFiles: getHotFiles(files),
    env: readEnvFiles()
  };
}
```

## Context Map Output Template

```markdown
# Project Context Map

## Overview
[descripción breve del proyecto]

## Stack
- Framework: [nombre]
- Language: [versión]
- Key deps: [lista]

## Architecture
[patrón arquitectónico]

## Routes/API
```
[rutas con métodos y paths]
```

## Components
| Component | Purpose | Deps |
|-----------|---------|------|
| [nombre] | [función] | [deps] |

## Key Types
```typescript
[key types definidos]
```

## Hot Files (editados frecuentemente)
- [archivo 1]
- [archivo 2]

## Environment
```
[vars importantes]
```

## Middleware
- [middleware activo]
```

## Usage

1. Generar wiki la primera vez
2. Actualizar solo archivos relevantes cuando cambian
3. En cada sesión: cargar index.md + artículos relevantes
4. Máximo: 50-100K tokens para wiki completa

## Beneficios

| Sin Wiki | Con Wiki |
|----------|----------|
| 26-66K tokens/sesión | 3-5K tokens/sesión |
| Exploración manual | Contexto estructurado |
| Falsos positivos en búsqueda | 100% retrieval rate |
| Contexto perdido entre sesiones | Persistente |