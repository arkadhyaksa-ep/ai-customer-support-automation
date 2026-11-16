# AI Customer Support Automation

**An AI-assisted customer-support ticket classification and routing system built with n8n, Ollama, and Gemma 3 4B.**

This project demonstrates the design of an automated support-ticket processing workflow with structured AI classification, rule-based safety checks, human review, duplicate-submission handling, error recovery, and persistent ticket tracking.

The system runs locally and uses an open-source language model through Ollama.

## Overview

When a customer submits a support inquiry, the system:

1. Receives the inquiry through an HTTP webhook.
2. Validates the required ticket information.
3. Checks existing tickets and review records for duplicate or conflicting submissions.
4. Uses Gemma 3 4B to classify the inquiry.
5. Validates the AI-generated classification.
6. Applies additional rule-based safety checks.
7. Routes eligible tickets to the appropriate support team or sends flagged inquiries to a human-review queue.
8. Stores the result in n8n Data Tables and returns an HTTP response.

The project also includes separate workflows for reviewing flagged tickets, promoting approved tickets, reconciling partial promotions, and benchmarking classification performance.

## Technology Stack

| Technology | Purpose |
|---|---|
| n8n | Workflow orchestration and automation |
| Ollama | Local AI inference |
| Gemma 3 4B | Customer inquiry classification |
| JavaScript | Validation, routing, safety rules, and workflow logic |
| n8n Data Tables | Ticket, review, and audit persistence |
| HTTP / JSON | Webhook communication and AI integration |
| PowerShell | API testing and reproducible examples |

## System Architecture

```text
Customer Request
       |
       v
  n8n Webhook
       |
       v
 Input Validation
       |
       v
Global Duplicate Check
       |
       +---- Replay / Conflict --> HTTP Response
       |
       v
  Ollama / Gemma 3
       |
       v
AI Response Validation
       |
       v
Classification Safety Check
       |
       +---- Review Required
       |          |
       |          v
       |     Review Queue
       |          |
       |          v
       |     Human Review
       |          |
       |          v
       |     Ticket Promotion
       |
       v
   Team Routing
       |
       v
  Main Ticket Table
       |
       v
   HTTP Response
```

A separate reconciliation workflow handles selected partial-promotion recovery scenarios and records audit events.

## Classification Categories

| Category | Assigned Team | Example |
|---|---|---|
| billing | Finance | Duplicate payment or incorrect charge |
| technical | Technical Support | Login failures or application errors |
| delivery | Logistics | Delayed shipments or missing packages |
| other | Customer Support | Opening hours or general inquiries |

The AI returns a structured JSON response containing one of these categories.

Example:

```json
{
  "category": "billing"
}
```

## Engineering Features

### Structured AI Classification

- Uses locally hosted Gemma 3 4B through Ollama.
- Provides explicit category definitions and classification instructions.
- Requests JSON Schema-constrained output.
- Validates model responses before downstream processing.
- Routes invalid AI responses through an error-handling path.

### Duplicate and Conflict Handling

- Detects previously submitted ticket IDs.
- Recognizes identical submissions as replays.
- Returns HTTP 200 for recognized replays.
- Returns HTTP 409 for conflicting submissions.
- Avoids unnecessary AI inference for known duplicate requests.

### Human-in-the-Loop Review

- Uses rule-based checks to identify classification conflicts and selected security-sensitive inquiries.
- Stores flagged tickets in a separate review queue.
- Supports approval, category correction, and rejection.
- Preserves the original AI classification for review history.
- Allows approved tickets to be promoted into the main ticket table.

### Reliability and Recovery

- Uses separate storage-error response paths.
- Handles unavailable AI services and invalid AI outputs.
- Uses Insert operations for primary ticket creation.
- Provides a reconciliation workflow for selected interrupted promotion states.
- Records recovery events in an audit table.

### Local Model Benchmarking

A separate workflow evaluates the model using 12 predefined support inquiries across four categories.

During development, Gemma 3 4B achieved **12/12 correct predictions** on this small evaluation dataset.

This result demonstrates performance on the defined test cases only. It is not a statistical estimate of production accuracy.

## Included Workflows

| File | Purpose |
|---|---|
| `01-customer-intake.json` | Primary webhook, classification, validation, and routing |
| `02-ticket-validator.json` | Reusable ticket validation |
| `03-human-review.json` | Human-review decisions |
| `04-ticket-promotion.json` | Promotion of approved tickets |
| `05-ticket-reconciliation.json` | Recovery of selected partial promotion states |
| `06-model-benchmark.json` | Local AI classification evaluation |

## Getting Started

### Prerequisites

- n8n with Data Table support
- Ollama
- Gemma 3 4B
- A local environment with sufficient resources to run the model
- PowerShell for the included example scripts

### Setup

1. Install and configure n8n.
2. Install Ollama and download `gemma3:4b`.
3. Import the six n8n workflows.
4. Create the required Data Tables.
5. Relink the imported Data Tables and reusable Ticket Validator workflow.
6. Configure the Ollama endpoint for your environment.
7. Configure and activate the Customer Intake workflow.
8. Submit a test inquiry.

See [Setup and Configuration](docs/setup.md) for detailed instructions.

## Testing

The `examples/` directory contains PowerShell scripts demonstrating:

| Script | Scenario | Expected HTTP Status |
|---|---|---|
| `test-billing.ps1` | Successful billing inquiry | 201 |
| `test-replay.ps1` | Identical ticket submitted twice | 201, then 200 |
| `test-conflict.ps1` | Conflicting submission using an existing ID | 201, then 409 |
| `test-human-review.ps1` | Security-sensitive inquiry requiring review | 202 |

The expected outcomes assume correctly configured workflows and fresh ticket IDs.

Development testing also covered invalid inputs, AI response failures, storage failures, duplicate handling, reviewer decisions, promotion, and reconciliation.

The example scripts demonstrate selected behaviors; they are not a comprehensive automated test suite.

## Project Structure

```text
ai-customer-support-automation/
├── workflows/
│   ├── 01-customer-intake.json
│   ├── 02-ticket-validator.json
│   ├── 03-human-review.json
│   ├── 04-ticket-promotion.json
│   ├── 05-ticket-reconciliation.json
│   └── 06-model-benchmark.json
├── docs/
│   └── setup.md
├── examples/
│   ├── test-billing.ps1
│   ├── test-replay.ps1
│   ├── test-conflict.ps1
│   └── test-human-review.ps1
└── README.md
```

## Limitations

This project is an engineering portfolio demonstration, not a production-ready customer-support platform.

Important limitations include:

- Duplicate checks do not guarantee exactly-once execution under concurrent requests.
- Operations spanning multiple Data Tables are not transactional.
- Human-review and promotion workflows use manual execution inputs rather than a dedicated reviewer interface.
- Rule-based safety checks cover selected patterns, not all ambiguous or high-risk inquiries.
- The classification benchmark contains only 12 labeled examples.
- Workflow and Data Table references require reconfiguration after import.
- Authentication, authorization, monitoring, and deployment hardening would be required for real customer use.

## Potential Improvements

Future development could include a reviewer dashboard, centralized configuration, automated integration tests, broader model benchmarking, transactional storage, and monitoring.

## Project Purpose

This project was developed as a hands-on exploration of AI automation engineering, focusing on integrating a local language model into a multi-workflow system with validation, persistence, human oversight, and failure handling.

It demonstrates practical experience with n8n workflow orchestration, REST APIs, structured AI outputs, JavaScript, debugging, and reliability-oriented automation design.