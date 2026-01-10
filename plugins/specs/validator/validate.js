#!/usr/bin/env node

/**
 * Validates YAML spec files against JSON schemas.
 *
 * Usage:
 *   node validate.js --specs <specsDir> --schemas <schemasDir>
 *
 * Output:
 *   JSON object with validation results
 */

const fs = require("fs");
const path = require("path");
const yaml = require("js-yaml");
const Ajv2020 = require("ajv/dist/2020");
const addFormats = require("ajv-formats");

// Parse command line arguments
function parseArgs() {
  const args = process.argv.slice(2);
  const result = { specs: "docs.specs", schemas: null };

  for (let i = 0; i < args.length; i++) {
    if (args[i] === "--specs" && args[i + 1]) {
      result.specs = args[++i];
    } else if (args[i] === "--schemas" && args[i + 1]) {
      result.schemas = args[++i];
    }
  }

  if (!result.schemas) {
    console.error("Error: --schemas argument is required");
    process.exit(1);
  }

  return result;
}

// Recursively find all YAML files in a directory
function findYamlFiles(dir, baseDir = dir) {
  const files = [];

  if (!fs.existsSync(dir)) {
    return files;
  }

  for (const entry of fs.readdirSync(dir, { withFileTypes: true })) {
    const fullPath = path.join(dir, entry.name);
    if (entry.isDirectory()) {
      files.push(...findYamlFiles(fullPath, baseDir));
    } else if (entry.name.endsWith(".yaml") || entry.name.endsWith(".yml")) {
      files.push({
        absolute: fullPath,
        relative: path.relative(baseDir, fullPath).replace(/\\/g, "/"),
      });
    }
  }

  return files;
}

// Determine which schema to use based on file path
function getSchemaName(relativePath) {
  // Normalize path separators
  const p = relativePath.replace(/\\/g, "/");

  // system.yaml at root
  if (p === "system.yaml") {
    return "system";
  }

  // domain/[entity]/actions/*.yaml -> action
  if (/^domain\/[^/]+\/actions\/[^/]+\.yaml$/.test(p)) {
    return "action";
  }

  // domain/[entity]/[entity].yaml -> entity
  if (/^domain\/[^/]+\/[^/]+\.yaml$/.test(p)) {
    return "entity";
  }

  // tasks/*.yaml -> task
  if (/^tasks\/[^/]+\.yaml$/.test(p)) {
    return "task";
  }

  // external-services/*.yaml -> service
  if (/^external-services\/[^/]+\.yaml$/.test(p)) {
    return "service";
  }

  // apps/[app]/*.yaml -> app
  if (/^apps\/[^/]+\/[^/]+\.yaml$/.test(p)) {
    return "app";
  }

  return null;
}

// Load a YAML schema file and convert to JSON Schema
function loadSchema(schemasDir, schemaName) {
  const schemaPath = path.join(schemasDir, `${schemaName}.schema.yaml`);

  if (!fs.existsSync(schemaPath)) {
    throw new Error(`Schema not found: ${schemaPath}`);
  }

  const content = fs.readFileSync(schemaPath, "utf8");
  return yaml.load(content);
}

// Main validation function
function validate() {
  const args = parseArgs();
  const specsDir = path.resolve(args.specs);
  const schemasDir = path.resolve(args.schemas);

  // Check directories exist
  if (!fs.existsSync(specsDir)) {
    console.log(
      JSON.stringify({
        error: `Specs directory not found: ${specsDir}`,
        summary: { total: 0, valid: 0, invalid: 0 },
        results: [],
      })
    );
    return;
  }

  if (!fs.existsSync(schemasDir)) {
    console.log(
      JSON.stringify({
        error: `Schemas directory not found: ${schemasDir}`,
        summary: { total: 0, valid: 0, invalid: 0 },
        results: [],
      })
    );
    return;
  }

  // Set up AJV with format validation (using 2020-12 draft)
  const ajv = new Ajv2020({ allErrors: true, strict: false });
  addFormats(ajv);

  // Load and register the field-type schema (referenced by entity schema)
  try {
    const fieldTypeSchema = loadSchema(schemasDir, "field-type");
    ajv.addSchema(fieldTypeSchema, "field-type.schema.yaml");
  } catch (e) {
    // field-type schema is optional for backwards compatibility
  }

  // Cache for compiled validators
  const validators = {};

  // Find all spec files
  const files = findYamlFiles(specsDir);
  const results = [];

  for (const file of files) {
    const schemaName = getSchemaName(file.relative);

    if (!schemaName) {
      results.push({
        file: file.relative,
        schema: null,
        valid: false,
        errors: [{ path: "", message: "Unknown spec type - cannot determine schema" }],
      });
      continue;
    }

    // Get or compile validator
    if (!validators[schemaName]) {
      try {
        const schema = loadSchema(schemasDir, schemaName);
        validators[schemaName] = ajv.compile(schema);
      } catch (e) {
        results.push({
          file: file.relative,
          schema: schemaName,
          valid: false,
          errors: [{ path: "", message: `Failed to load schema: ${e.message}` }],
        });
        continue;
      }
    }

    // Load and parse spec file
    let specData;
    try {
      const content = fs.readFileSync(file.absolute, "utf8");
      specData = yaml.load(content);
    } catch (e) {
      results.push({
        file: file.relative,
        schema: schemaName,
        valid: false,
        errors: [{ path: "", message: `Failed to parse YAML: ${e.message}` }],
      });
      continue;
    }

    // Validate
    const validator = validators[schemaName];
    const valid = validator(specData);

    if (valid) {
      results.push({
        file: file.relative,
        schema: schemaName,
        valid: true,
      });
    } else {
      results.push({
        file: file.relative,
        schema: schemaName,
        valid: false,
        errors: validator.errors.map((err) => ({
          path: err.instancePath || "/",
          message: err.message,
          keyword: err.keyword,
        })),
      });
    }
  }

  // Calculate summary
  const summary = {
    total: results.length,
    valid: results.filter((r) => r.valid).length,
    invalid: results.filter((r) => !r.valid).length,
  };

  // Output JSON
  console.log(JSON.stringify({ summary, results }, null, 2));
}

validate();
