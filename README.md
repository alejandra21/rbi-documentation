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

## Setup

1. Open Bruno
2. Open Workspace → select the cloned repo folder
3. Select the desired collection and configure the environment variables as needed

## Environments

Each collection includes its own environment configurations (e.g. `local`, `dev`, `staging`). Select the appropriate environment from the environment switcher in Bruno before running requests.
