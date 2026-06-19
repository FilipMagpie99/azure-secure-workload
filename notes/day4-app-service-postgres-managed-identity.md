# Day 4 — App service + Postgres Managed identity

## Cheat sheet
```bash
# 1. App Service (Linux, B1) + system-assigned MI
az appservice plan create -g azure-secure-workload-rg -n asp-lab --sku B1 --is-linux
az webapp create -g azure-secure-workload-rg -p asp-lab -n app-lab-fs01 --runtime "PYTHON:3.12"
az webapp identity assign -g azure-secure-workload-rg -n app-lab-fs01   # zwróci principalId — to jest tożsamość w Entra

# 2. Postgres Flexible Server (Burstable B1ms) — deploy potrwa kilka minut
az postgres flexible-server create -g azure-secure-workload-rg -n pg-lab-fs01 \
  --tier Burstable --sku-name Standard_B1ms --version 16 \
  --admin-user pgadmin --public-access None --yes

# 3. Rozszerzenie passwordless do Service Connectora
az extension add --name serviceconnector-passwordless --upgrade

# 4. Passwordless połączenie App Service → Postgres
az webapp connection create postgres-flexible \
  -g azure-secure-workload-rg --name app-lab-fs01 \
  --target-resource-group azure-secure-workload-rg \
  --server pg-lab-fs01 --database postgres \
  --system-identity --client-type python
```

## Notes
- Before creating webapp, a appservice plan must be created.
- az webbapp identity assigns, adds identity to webapp (returns service principal ID)
- Service Connector completes multiple tasks in the background - sets microsoft entra auth for the db server if not enabled, set the MS entra admin to the current signed-in user,  adds db user for the system-assigned managed identity, user-assigned managed identity or service principal. Grants all privileges to the data base name to this user. Set configs names to the resource based on the DB type.

## 💡 Gotchas
- User-assigned managed identity can be assigned to multiple resources, outlives the resource
- System-assigned lifecycle managed by resource lifecycle. Bound to one specific instance of a resource.
- Workload identity such as managed identity is stored as an object in Entra ID, can be monitored through AADnoninteractive sign-in logs.
- It elimnates the need for managing passwords, which makes it a lot safer. No secret present, no leakage possiblity.
App gets tokens via IMDS endpoint (169.254.169.254) using DefaultAzureCredential — short-lived tokens, nothing stored on disk.

