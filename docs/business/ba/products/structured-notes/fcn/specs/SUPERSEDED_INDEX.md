# FCN Specification Supersession Index

This index tracks all superseded FCN specification versions for historical reference and audit purposes.

## Superseded Specifications

| Version | Status | Superseded By | Supersession Date | Spec File |
|---------|--------|---------------|-------------------|-----------|
| 1.0 | Superseded | fcn-v1.1.0.md | 2025-10-17 | fcn-v1.0.md |

## Notes

- Superseded specifications are retained for historical reference and existing trade audit
- New trades, templates, and migrations must not reference superseded versions without explicit governance approval
- For migration guidance from superseded versions, see the corresponding schema-diff documents

## Machine-Readable Format

For automated tooling and validation systems, the superseded specification metadata is available in JSON format:

```json
{
  "superseded_specs": [
    {
      "version": "1.0",
      "status": "Superseded",
      "superseded_by": "fcn-v1.1.0.md",
      "supersession_date": "2025-10-17",
      "spec_file": "fcn-v1.0.md",
      "lifecycle": "historical"
    }
  ]
}
```

This JSON structure can be consumed by CI/CD pipelines, documentation generators, and validation tools to enforce governance policies around specification versioning.
