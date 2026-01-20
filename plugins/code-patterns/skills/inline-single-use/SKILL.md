---
name: inline-single-use
description: Rule for when to inline code vs extract into separate files. Apply when writing new code, refactoring, or deciding whether to create a new file or abstraction.
---

# Inlining

**Avoid creating separate files or abstractions for code that is only used once.**

```
IF component/utility/function/etc is only used once across the entire codebase
   AND the code is not excessively large
   AND the code is not likely to be needed elsewhere (ie - it's not very general-purpose)
THEN inline the code at the callsite
```

## Exceptions

- The calling function becomes hard to read due to length or complexity
- The extracted code has a clear, self-contained responsibility that benefits from a name
- Testing the code in isolation provides significant value
