---
description: Guidelines for organizing files and folders in the codebase
allowed-tools: []
---

# Folder Structure

**Organize files so that related code lives together and the structure reflects how you think about the system.**

## Thought process

### 1. Establish a predictable top-level structure

Define a simple hierarchy that makes file placement obvious. Once established, developers should rarely need to decide where something belongs—the structure tells them. Use the concepts below as building blocks for your hierarchy.

| Concept        | Description                                                           |
| -------------- | --------------------------------------------------------------------- |
| App            | A runtime where our code executes (website, CLI, task runner)         |
| Domain         | Core business logic: entities, domain services, and events            |
| Service        | Anti-corruption layer wrapping a third-party API in our own interface |
| Infrastructure | Low-level utilities and cross-cutting concerns                        |
| Library        | Reusable code shared across apps                                      |

The key distinction: **Apps** are where our code runs. **Services** wrap external APIs so our domain code doesn't depend on third-party contracts directly. **Infrastructure** contains low-level utilities that support the system. **Library** holds reusable code shared across apps.

**Example:** A product catalog system with four apps, two external services, a shared library, and infrastructure:

```
project/
├── apps/
│   ├── website/
│   │   └── routes/
│   │       ├── home/
│   │       ├── catalog/
│   │       ├── checkout/
│   │       └── product/
│   ├── cli/
│   │   └── commands/
│   │       ├── add-product/
│   │       └── remove-product/
│   ├── mobile/
│   └── cloud-tasks/
│       ├── sync-inventory/
│       └── generate-reports/
├── domain/
│   ├── entities/
│   │   └── product/
│   │       ├── types.ts
│   │       ├── validation.ts
│   │       └── events/
│   └── services/
│       └── pricing/
├── services/
│   ├── gemini-ai/
│   └── google-maps/
├── library/
│   ├── ui-components/
│   └── excel/
└── infrastructure/
    ├── strings/
    └── security/
```

With this structure, there's no ambiguity: a new entity goes in `domain/entities/`, domain services go in `domain/services/`, a new third-party API wrapper goes in `services/`, reusable code goes in `library/`, background jobs go in `apps/cloud-tasks/`, and low-level utilities go in `infrastructure/`.

### 2. Group by feature, not file type

When creating additional folders or deciding where new files belong, group by feature rather than by file type. A feature folder might contain components, utilities, types, and tests that all relate to that feature.

### 3. Apply recursively

As a feature folder grows, it may need its own internal structure. When this happens, apply the same process: identify the concepts within that feature, then organize by sub-feature. Each level should follow the same thinking.

### 4. Keep similar features consistent

When multiple features share a similar shape, use the same folder structure for each. This makes the codebase predictable—once you learn how one feature is organized, you know where to look in the others.
