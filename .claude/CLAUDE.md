# Bruno RBI — Claude Guide

## Collections

| Collection | Format | Base URL var | Auth |
|------------|--------|-------------|------|
| `AI UW` | `.yml` | `{{base_url}}` | `inherit` |
| `ai-uw-lambda` | `.bru` | `{{aiUwLambdaUrl}}` | `none` |

## AI UW Collection

**Purpose:** CRUD requests against the Django backend (`http://localhost:8000`).

### File format (.yml)

```yaml
info:
  name: <Human readable name>
  type: http
  seq: <integer — unique within folder, determines sort order>

http:
  method: GET|POST|PATCH|DELETE
  url: "{{base_url}}/api/workflows/<endpoint>/"
  params:                        # optional, for query params
    - name: <param_name>
      value: <default_value>
      type: query
  body:
    type: text|json              # use json for POST/PATCH with body
    data: |-
      { ... }
  auth: inherit                  # always inherit — auth set at collection level

settings:
  encodeUrl: true
  timeout: 0
  followRedirects: true
  maxRedirects: 5
```

### Folder convention

- Each workflow phase has its own subfolder: `Validations/<N>. <Phase Name>/`
- Subfolder needs a `folder.yml`:
  ```yaml
  info:
    name: <N>. <Phase Name>
    type: folder
    seq: <N>
  request:
    auth: inherit
  ```
- Seq numbers are **global within the folder** — check existing max before adding.

### URL patterns

| Operation | Method | URL |
|-----------|--------|-----|
| List | GET | `{{base_url}}/api/workflows/<endpoint>/` |
| List filtered | GET | `{{base_url}}/api/workflows/<endpoint>/?<field>=<value>` |
| Retrieve | GET | `{{base_url}}/api/workflows/<endpoint>/<uuid>/` |
| Create | POST | `{{base_url}}/api/workflows/<endpoint>/` |
| Partial update | PATCH | `{{base_url}}/api/workflows/<endpoint>/<uuid>/` |
| Delete | DELETE | `{{base_url}}/api/workflows/<endpoint>/<uuid>/` |

### Environments

| Name | base_url |
|------|---------|
| Local | `http://localhost:8000` |
| QA | `https://ai-underwriting-backend-qa-bda7d5625b58.herokuapp.com` |
| Production | `https://ai-underwriting-backend-c85acb35e7f9.herokuapp.com` |

### Seed UUIDs (used in examples)

- `final_approval_validation`: `7982b1f1-7d7e-4518-bbf3-3c0e1dbff0f2`
- `workflow_loan_summary`: `9bde3157-4cf6-4a29-a0d1-4e5acf4c74ad`
- `loan_id`: `615`

---

## ai-uw-lambda Collection

**Purpose:** POST requests to trigger workflow phase runs.

### File format (.bru)

```
meta {
  name: <name>
  type: http
  seq: <integer>
}

post {
  url: {{aiUwLambdaUrl}}/workflows/<trigger-name>/run
  body: json
  auth: none
}

headers {
  Content-Type: application/json
}

body:json {
  {
    "loan_id": 615,
    "workflow_id": "9bde3157-4cf6-4a29-a0d1-4e5acf4c74ad",
    "workflow_run_id": "4ac50db3-68a3-403e-bc0c-05f3716f0847",
    "phase": "PHASE_11"
  }
}
```

Local env: `aiUwLambdaUrl = http://127.0.0.1:3002`

---

## Adding requests for a new Django endpoint

1. Find the folder: `collections/AI UW/Validations/<phase>/`
2. Check max `seq:` in existing files
3. Create `.yml` files starting from max+1
4. Standard set: List, Create, Retrieve, Partial Update
5. Use seed UUIDs for body placeholders
6. Replace `<id>` in Retrieve/PATCH URLs with actual UUID when testing
