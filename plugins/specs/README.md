# Specs Plugin

This plugin contains JSON Schema definitions for generating system specification documents. Following Domain-Driven Design (DDD) principles, these schemas define how to describe a software system in a way that is:

- **Tech-agnostic** - Can be implemented in any language or framework
- **Business-focused** - Reflects the domain language and concepts
- **AI-friendly** - Structured for AI to understand and generate code from

A **system** represents a complete software project (typically a repository) which may contain multiple **apps** (e.g., web, cli, mobile) that work together. The specification captures everything needed to understand the system: its domain model, business logic, integrations, and applications.

The following schemas are available to document a system:

| Component   | Schema                | Description                                                      |
| ----------- | --------------------- | ---------------------------------------------------------------- |
| **System**  | `system.schema.yaml`  | Top-level definition with global roles and storage mechanisms    |
| **App**     | `app.schema.yaml`     | Application module within the system                             |
| **Entity**  | `entity.schema.yaml`  | Domain object with fields, types, enums, and context-based roles |
| **Action**  | `action.schema.yaml`  | Operation on an entity with authorization rules                  |
| **Task**    | `task.schema.yaml`    | Scheduled or background job with schedule and retry policy       |
| **Service** | `service.schema.yaml` | External third-party API or service                              |

All schema files are located in the `schemas/` folder and use YAML format for readability.

## Commands

### `/specs:generate-overview`

Analyzes your codebase and generates `.specs/overview.md` - a semantic map of the system architecture.

```
/specs:generate-overview
```

Run this first to create the overview, then use `/specs:generate-specs` to generate the spec files.

### `/specs:generate-specs`

Generates YAML specification files to `docs.specs/` using the system overview as a guide.

```
/specs:generate-specs
```

Requires `.specs/overview.md` to exist. Run `/specs:generate-overview` first.

### `/specs:serve`

Starts a local Hugo server to browse the generated specifications as a website.

```
/specs:serve
```

Requires Hugo to be installed. The server runs at http://localhost:1313.

### `/specs:validate`

Validates all specification files in `docs.specs/` against their JSON schemas.

```
/specs:validate
```

Reports validation errors with file paths and specific issues. Useful for catching schema violations before serving or sharing specs.

## Examples

### System

The system file defines global configuration: global roles and storage mechanisms.

```yaml
type: system
name: "Weekend Planner"
description: "A system for automating weekend planning using AI."
users:
  - name: visitor
    description: Anonymous user browsing the website
  - name: admin
    description: Authenticated administrator
storage:
  - name: firestore
    description: Cloud Firestore for persistent data
  - name: localStorage
    description: Browser localStorage for client-side data
```

### App

An app defines an application module and which roles can access it.

```yaml
type: app
name: "Website"
description: "Public-facing SvelteKit web application."
applicationType: "web"
users:
  - "user/visitor"
  - "user/admin"
```

### Entity

An entity defines a domain object with its fields, nested types, enums, and context-based roles.

```yaml
type: entity
name: "Event"
description: "A time-limited happening in a city."
storage: "firestore"
fields:
  - name: id
    type: string
    description: Unique identifier
  - name: name
    type: string
    description: Name of the event
  - name: category
    type: enum<category>
    description: Category of the event
types:
  Link:
    - name: url
      type: string
      description: The URL
enums:
  category:
    - value: "Fairs & Markets"
      description: Weekend markets and fairs
roles:
  - name: manager
    description: Can create, update, and delete events
```

### Action

An action defines an operation on an entity, including who is authorized to perform it.

```yaml
type: action
name: "Research Events"
entity: "Event"
description: "Discovers and creates new events using AI with web search."
authorization: "user/admin | user/developer"
```

### Task

A task defines a scheduled or background job with its schedule and retry behavior.

```yaml
type: task
name: "Daily Research"
description: "Runs automated research for all configured cities."
schedule: "0 0 * * *"
retryPolicy: "exponential-backoff"
```

### Service

A service defines an external API dependency with its authentication method and usage.

```yaml
type: service
name: "Gemini AI"
description: "Google's AI model for research and review tasks."
provider: "Google"
documentation: "https://ai.google.dev/docs"
authentication: "api-key"
usage: "Used for event/place research and review validation."
rateLimits:
  - limit: "Requests per minute"
    value: "60"
```

## Reference

### Roles

A user can have one or more roles in the system. There are two types of roles.

**Global Roles** are defined in `system.yaml` under `users`. A user holds these roles against the system as a whole.

- Format: `user/[role]`
- Examples: `user/visitor`, `user/admin`, `user/developer`

**Context-Based Roles** are defined in an entity's `roles` field. A user holds these roles against a specific entity instance.

- Format: `[entity]/[role]`
- Examples: `event/manager`, `city/editor`, `project/owner`

### Role Expressions

A role expression defines which roles grant access to particular functionality. It can be a single role or a combination using operators:

| Operator | Meaning | Example                                      |
| -------- | ------- | -------------------------------------------- |
| `\|`     | OR      | `user/admin \| user/developer`               |
| `&`      | AND     | `user/visitor & event/owner`                 |
| `()`     | Group   | `user/admin \| (user/visitor & event/owner)` |

### Type System

Use these standard types for entity fields:

| Type                | Description                                  |
| ------------------- | -------------------------------------------- |
| `string`            | Text value                                   |
| `text`              | Long-form text (multi-line)                  |
| `number`            | Numeric value (integer or decimal)           |
| `boolean`           | True/false                                   |
| `datetime`          | Date and time                                |
| `date`              | Date only                                    |
| `enum<enumName>`    | One of a predefined set of values            |
| `Type[]`            | Array of values (e.g., `string[]`, `Link[]`) |
| `object`            | Nested structure                             |
| `reference<Entity>` | Reference to another entity                  |

Add `?` after the type to indicate optional (e.g., `string?`, `number?`).

### Naming Conventions

When generating specifications from existing code, always use the names established in the codebase.

For new specifications where no code exists yet, use these defaults:

| Element         | Convention | Example                             |
| --------------- | ---------- | ----------------------------------- |
| Entity names    | PascalCase | `Event`, `CityConfig`               |
| Field names     | camelCase  | `googleMapsUrl`, `lastReviewedAt`   |
| Enum type names | camelCase  | `category`, `status`                |
| Enum values     | PascalCase | `FairsAndMarkets`, `Active`         |
| File names      | kebab-case | `city-config.yaml`, `research.yaml` |

## Output Structure

Generated specs follow this folder structure:

```
docs.specs/
├── system.yaml
├── domain/
│   └── [entity]/
│       ├── [entity].yaml
│       └── actions/
│           └── [action].yaml
├── tasks/
│   └── [task].yaml
├── external-services/
│   └── [service].yaml
└── apps/
    └── [app]/
        └── [app].yaml
```

## Configuration

### `.specs/config.json`

The plugin uses `.specs/config.json` to configure exclusion patterns. This file is created automatically when you first run `/specs:generate`.

```json
{
  "exclude": [
    "docs.specs/",
    ".claude/",
    ".git/",
    "node_modules/"
  ]
}
```

| Property         | Type       | Description                                           |
| ---------------- | ---------- | ----------------------------------------------------- |
| `exclude`        | `string[]` | Glob patterns for paths to exclude from analysis      |
| `overviewCommit` | `string`   | Git commit hash for which the overview was generated  |

**Default exclusions:** `docs.specs/`, `.specs/`, `.claude/`, `.git/`, `.github/`, `.rider/`, `.idea/`, `.vscode/`, `node_modules/`, `dist/`, `build/`, `.svelte-kit/`

**Gitignore:** Patterns from `.gitignore` are always applied automatically in addition to the config file.