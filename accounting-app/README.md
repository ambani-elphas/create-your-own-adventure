# Accounting App Starter Repository

This folder is a **new repository skeleton** for building an accounting application.

## Goals
- Manage chart of accounts
- Record journal entries
- Track invoices, payments, and expenses
- Generate financial reports (P&L, balance sheet, cash flow)

## Suggested Stack
- **Frontend:** React + TypeScript
- **Backend:** FastAPI (Python)
- **Database:** PostgreSQL
- **Auth:** JWT-based authentication
- **Infrastructure:** Docker Compose for local development

## Initial Repository Structure

```text
accounting-app/
├── backend/
├── frontend/
├── docs/
│   └── PROJECT_PLAN.md
├── infra/
├── .env.example
├── .gitignore
└── README.md
```

## Quick Start
1. Copy this folder into a new Git repository:
   ```bash
   cp -r accounting-app /path/to/new/accounting-app
   cd /path/to/new/accounting-app
   git init
   git add .
   git commit -m "Initial scaffold for accounting app"
   ```
2. Define first milestones in `docs/PROJECT_PLAN.md`.
3. Set up backend and frontend services.

## Next Steps
- Add API contracts for core accounting workflows.
- Define database schema with migration tooling.
- Implement role-based access for accountants/admins.
- Add automated tests and CI pipeline.
