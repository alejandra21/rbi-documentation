# RBI - Bruno API Collections

This repository contains the [Bruno](https://www.usebruno.com/) API collections for the RBI platform.

## Collections

| Collection | Description |
|---|---|
| **AI UW** | AI-powered underwriting workflows — borrower eligibility, business rules, tiering, validations, OCR, login, and third-party integrations (LexisNexis, TLO, Ocrolus) |
| **RBI Client Backend API** | Core backend API — loan applications, loans, users, access management, branches, brokers, companies, payment links, and servicing |
| **Prequalification Data Processing API** | Data enrichment services — credit reports, OFAC screening, flood reports, ID verification, USPS address validation, and more |
| **Externals** | External third-party service integrations |
| **Liquid-Dat** | Liquid-Dat service requests |
| **OpenAI - POC** | OpenAI proof-of-concept requests |
| **Who-Dat** | Who-Dat service requests |

## Requirements

- [Bruno](https://www.usebruno.com/) desktop app
- [Node.js](https://nodejs.org/) 18+ (for CLI usage)

## Setup

1. Open Bruno
2. Open Workspace → select the cloned repo folder
3. Select the desired collection and configure the environment variables as needed

## Environments

Each collection includes its own environment configurations (e.g. `local`, `dev`, `staging`). Select the appropriate environment from the environment switcher in Bruno before running requests.

## Running from the CLI

Bruno provides an official CLI (`@usebruno/cli`) to run requests and collections from the terminal — useful for automation, CI/CD, and scripting.

### Install

```bash
npm install -g @usebruno/cli
```

### Usage

```bash
# Run a single request
bru run "<folder>/<Request Name>.bru" --env <environment>

# Run all requests in a folder
bru run <folder>/ --env <environment>

# Run the entire collection
bru run --env <environment>
```

### Examples

See [`scripts/examples/`](scripts/examples/) for ready-to-run shell scripts.

```bash
# Run a single workflow against local
cd collections/ai-uw-lambda
bru run "initial-phase/Initial Validation.bru" --env local

# Run the full ai-uw-lambda collection against local and output a JSON report
cd collections/ai-uw-lambda
bru run --env local --reporter-json ../../scripts/examples/output/results.json
```

### Useful flags

| Flag | Description |
|------|-------------|
| `--env <name>` | Select environment (e.g. `local`, `production`) |
| `--env-var key=value` | Override an environment variable inline |
| `--reporter-json <file>` | Export results as JSON |
| `--reporter-html <file>` | Export results as HTML |
| `--reporter-junit <file>` | Export results as JUnit XML (CI-friendly) |
| `--parallel` | Run requests in parallel |
