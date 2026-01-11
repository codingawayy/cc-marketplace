# Generate Specs Plan

## Objective

Generate YAML specification files from the codebase and write them to `docs.specs/`.

Output structure:
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

## Approach

Generate specs in the following order: System → Entities → Actions → Tasks → Services → Apps.

Rules for generating specs:
- Use `.yaml` extension for all files
- Only include fields defined in the schema
- Omit optional fields if not applicable

## Detailed Plan

<!--
Checkbox items for each spec to generate, organized by phase.

When marking items complete, add a status note:
- [x] Generate system.yaml (created) - newly generated
- [x] Generate system.yaml (exists, valid) - already existed, validated
- [x] Generate system.yaml (updated) - existed but was modified

Update this plan after EACH item is processed.
-->

## Notes

<!-- Any relevant context from the overview or changes file -->

## Changelog

<!--
Track changes made during execution. Add entries as you complete items:
- Created domain/event/event.yaml
- Validated system.yaml (already existed)
- Updated domain/place/place.yaml (fixed enum values)
-->
