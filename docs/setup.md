# Setup and Configuration

## Ticket Validator Dependency

The Customer Intake Orchestrator calls a reusable n8n workflow named **Ticket Validator**.

### Configuration after import

1. Import `02-ticket-validator.json` into n8n.
2. Import `01-customer-intake.json`.
3. Open **Customer Intake Orchestrator**.
4. Find the node named `Call 'Ticket Validator'`.
5. In the workflow selection field, select the newly imported **Ticket Validator** workflow.
6. Save the Customer Intake Orchestrator.

The original workflow export contains an installation-specific workflow reference that must be relinked after import.

### Important

This configuration step does not modify the classification or validation logic.

Other environment-specific dependencies, including n8n Data Tables and the local Ollama endpoint, must also be configured before the project can run. Their setup instructions will be added separately.

## Data Table Setup

This project requires three n8n Data Tables. Create them before running the imported workflows.

### 1. Customer Support Tickets - Lab 09

Stores successfully classified and routed tickets, including tickets promoted after human review.

| Column | Type |
|---|---|
| ticket_id | String |
| customer_name | String |
| message | String |
| category | String |
| assigned_team | String |
| ticket_status | String |

Expected category values: `billing`, `technical`, `delivery`, `other`.

Assigned teams:

- `billing` → Finance
- `technical` → Technical Support
- `delivery` → Logistics
- `other` → Customer Support

Successfully routed tickets use `ticket_status = routed`.

### 2. AI Ticket Review Queue - Lab 12

Stores inquiries requiring human review and tracks reviewer decisions and promotion status.

| Column | Type |
|---|---|
| ticket_id | String |
| customer_name | String |
| message | String |
| ai_category | String |
| review_reason | String |
| review_status | String |
| reviewed_category | String |
| reviewed_note | String |
| reviewed_at | Date & Time |

The `reviewed_category`, `reviewed_note`, and `reviewed_at` fields may initially be empty.

Review statuses used by the workflows include:

- `pending_review`
- `approved`
- `approved_corrected`
- `rejected`
- `promoted`

### 3. Ticket Audit Log - Lab 12

Records reconciliation events when a partially completed ticket promotion is safely recovered.

| Column | Type |
|---|---|
| event_id | String |
| ticket_id | String |
| event_type | String |
| details | String |
| recorded_at | String |

The current workflow records `promotion_recovered` events.

The event ID follows the format:

`<ticket_id>:promotion_recovered`

The `recorded_at` value is an ISO 8601 timestamp stored as a string in the current exported node schema.

### Relinking Data Tables After Import

Data Table IDs are specific to each n8n installation.

After creating the three tables:

1. Open each imported workflow.
2. Locate its Data Table nodes.
3. Select the corresponding newly created table.
4. Verify the column mappings and filter conditions.
5. Save the workflow.

Do not assume that the Data Table IDs embedded in the exported JSON will work on another installation.

### Data Table Relinking Checklist

After importing the workflows and creating the three required Data Tables, reconnect the Data Table nodes in each workflow.

| Workflow | Main Tickets | Review Queue | Audit Log |
|---|---:|---:|---:|
| Customer Intake Orchestrator | 3 | 3 | 0 |
| Human Review | 0 | 2 | 0 |
| Ticket Promotion | 2 | 2 | 0 |
| Ticket Reconciliation | 1 | 2 | 1 |
| **Total** | **6** | **9** | **1** |

The other two workflows, Ticket Validator and Model Benchmark, do not use Data Tables.

For each Data Table node:

1. Open the imported workflow in n8n.
2. Open the Data Table node.
3. Select the corresponding table created in the new environment.
4. Confirm the operation remains unchanged (`Get`, `Insert`, `Update`, `Upsert`, or `Row Does Not Exist`, as applicable).
5. Verify filter columns, comparison values, and mapped output fields.
6. Save the workflow.

Do not assume that table names alone automatically relink imported Data Table nodes. Confirm the selected table and column mappings explicitly.

### Recommended Import Order

1. Create the three Data Tables with the documented schemas.
2. Import Ticket Validator.
3. Import Customer Intake Orchestrator and relink its Data Tables and Ticket Validator dependency.
4. Import Human Review, Ticket Promotion, and Ticket Reconciliation, relinking their Data Tables.
5. Import Model Benchmark and configure its Ollama endpoint.

The original Data Table IDs are retained in the JSON exports as reference metadata. They must be replaced by selecting the appropriate tables in the imported n8n instance.

These steps preserve the original workflow logic but require validation in the target environment before use.

### Data Integrity Note

The workflows implement duplicate checks and replay handling. However, these checks do not provide a database transaction across multiple Data Tables or guarantee atomic uniqueness under concurrent requests.

This is a portfolio demonstration of defensive workflow design, not a production-grade transactional ticketing system.

## Ollama and AI Model Setup

This project uses **Ollama** to run **Gemma 3 4B** locally for customer-support inquiry classification.

Ollama is accessed through n8n HTTP Request nodes. No cloud AI API key is required for this configuration.

### 1. Install Ollama

Download and install Ollama from:

https://ollama.com/download

Ensure the Ollama service is running.

### 2. Download the Model

Open a terminal or PowerShell and run:

```powershell
ollama pull gemma3:4b
```

Verify that the model is installed:

```powershell
ollama list
```

The installed models should include `gemma3:4b`.

### 3. Verify the Local API

Run the following PowerShell command:

```powershell
Invoke-RestMethod `
    -Uri "http://localhost:11434/api/tags" `
    -Method GET
```

A successful response should return information about the locally installed Ollama models.

### 4. Configure the n8n HTTP Request Nodes

Two workflows use Ollama:

- `01-customer-intake.json` — node: `Ollama Classifier`
- `06-model-benchmark.json` — node: `Evaluate Gemma`

Both workflows currently use:

```text
POST http://host.docker.internal:11434/api/generate
```

The correct hostname depends on where n8n and Ollama are running.

| Environment | Example Ollama URL |
|---|---|
| n8n running directly on the same host as Ollama | `http://localhost:11434/api/generate` |
| n8n running in Docker with Ollama on the host | `http://host.docker.internal:11434/api/generate` |
| Both services running in a configured Docker network | `http://ollama:11434/api/generate` |

These URLs are examples, not universal defaults. Configure Docker networking and Ollama's listening interface as needed. Only expose the Ollama API to trusted services.

### 5. AI Classification Configuration

The HTTP Request nodes use the following settings:

- Model: `gemma3:4b`
- Streaming: `false`
- Temperature: `0`
- Structured output: JSON Schema
- Allowed categories: `billing`, `technical`, `delivery`, `other`

The expected model response content is:

```json
{
  "category": "billing"
}
```

The category is returned in the Ollama API response's `response` field as a JSON-encoded string. The workflow parses and validates it before routing the ticket.

The prompt includes category definitions, decision rules, examples, and instructions to treat customer messages as data.

### 6. Classification Safety Checks

The Customer Intake Orchestrator also performs rule-based safety checks after AI classification.

Selected keyword signals and potentially security-sensitive inquiries can trigger human review rather than automatic ticket creation.

The safety checker is intentionally limited and is not a comprehensive semantic or security classifier.

### 7. Model Benchmark

The Model Benchmark workflow evaluates the classification model against 12 predefined customer-support inquiries.

Each test case contains a message and an expected category.

The evaluator reports overall accuracy, per-category results, and individual predictions.

The benchmark is a small functional evaluation, not evidence of production-level model accuracy or generalization.

### Troubleshooting

If an Ollama HTTP Request fails, verify that:

1. Ollama is running.
2. `gemma3:4b` is installed.
3. The configured Ollama hostname is reachable from the n8n runtime.
4. Port `11434` is accessible within the intended network.
5. The HTTP Request node uses the expected model name and JSON body.

A successful request from the host machine does not necessarily mean that the same hostname is reachable from an n8n Docker container.