# Day 4 — PE + DNS zones

## Cheat sheet
```bash
# --- DNS / Private Endpoint ---

# rekordy A w prywatnej strefie (oczekiwane: site + site.scm, metadata "created by private endpoint")
az network private-dns record-set a list \
  -g rg-secure-workload \
  -z privatelink.azurewebsites.net -o table

# IP przydzielone przez PE (siedzi w state PE, nie w app)
terraform state show 'module.compute.azurerm_private_endpoint.secure_workload_pe' \
  | grep private_ip_address

# --- Testy DNS (split-horizon) ---

# z wnętrza VNet (Kudu/SSH frontendu) -> oczekiwane: 10.x z snet-pe
nslookup fvt-backend-secure-workload.azurewebsites.net

# fallback gdy w kontenerze brak nslookup
python3 -c "import socket; print(socket.gethostbyname('fvt-backend-secure-workload.azurewebsites.net'))"

# z laptopa -> oczekiwane: publiczny IP (prywatna strefa działa tylko w zlinkowanym VNet)
nslookup fvt-backend-secure-workload.azurewebsites.net

# --- Testy egzekwowania (asercja na kod, nie na stronę błędu) ---

# wzorzec: sam kod statusu
curl -s -o /dev/null -w "%{http_code}\n" https://<host>

# site z zewnątrz          -> 403 (default Deny, zero reguł allow)
curl -s -o /dev/null -w "%{http_code}\n" https://fvt-backend-secure-workload.azurewebsites.net

# SCM z allowlistowanego IP -> 401 (sieć przepuściła, auth żąda dowodu)
# SCM z obcego IP           -> 403 (Deny odbija przed warstwą auth)
curl -s -o /dev/null -w "%{http_code}\n" https://fvt-backend-secure-workload.scm.azurewebsites.net

# funkcjonalnie przez PE (z SSH frontendu) -> 200
curl -I https://fvt-backend-secure-workload.azurewebsites.net

# --- Terraform (higiena z dzisiejszych błędów) ---

# init/plan/apply TYLKO z root module; nowy moduł w kodzie => init obowiązkowy
terraform init
terraform fmt -recursive     # formatuje też moduły, z roota
terraform validate

# sprawdzenie regionu / driftu deklaracji vs stan
grep location terraform.tfvars
terraform state show 'azurerm_resource_group.rg' | grep location
```

## Notes
- I've decided to switch to public_network_access_enabled = true, enforcement was moved to these controls: ip_restriction_default_action = "Deny" and scm_ip_restriction_default_action="Deny" and  scm_ip_restriction set to my ip address. I'm compensating the risk of switching the rules by mistake to "allow" (unlike PNA=false which can't be broken by a rule), with future detection of changes from table AppServiceIPSecAuditLogs and azure policy which will be implemented in future for default action "deny". These make sure only allowlisted IPs are allowed to connect to SCM and the backend url is only reachable from PE, so traffic flowing inside of a VNet - frontend. This decision was made due to high cost of VM runner for project purpose and ability to make deploys from selected public IP.
- I've created private dns zone which make sure that names inside resolve to the private ip and link it to the Vnet, it makes sure that endpoints inside of my vnet can connect to backend via resolving it's private IP, which is only allowed way to connect. When someone tries to resolve the SCM endpoint name it's still resolvable with public IP but due to the ip_restriction, anyone outside of trusted IP allowlist will receive 403. When it comes to just backend endpoint anyone from outside will get 403 due to deny all.
- Record A is automatically created based zone group there is a link between DNS <-> PE <-> PE subnet. It would be posible to create it manually after the deployement -> listing output dynamic IP assigned to the backend but it would be anti-pattern. When doing a config if it's asking me for some input which i don't know I probably should research whether setting this up is a good idea.
-  Connection to SCM -> [network layer] scm_ip_restriciton:
IP outside of trusted list (my mobile transfer) -> 403 
IP from the list:
[authentication layer]
no detected session (incognito) -> 401 (network went through, auth blocked)
active session (cookie inside of a browser) -> 200
- Traffic between subnets inside of one Vnet is allowed by default if not prohibited by NSG. The deny rule is not evaulted for the traffic coming from PE.
- Runner in Vnet - The decision was rejected due to high cost of runner VM which would be normal in corporate setup, but I needed access from my private laptop to SCM endpoint and also for 1 VNet project it could be an overkill. 
How does runner work?
It's a VM with installed agent, and it holds outbound connection for 50 seconds (long-poll) to github , the github transfer the data back with the established connection. So even if the ingress is closed it can still work fine.

## Gotchas

-  azurerm_dns_zone ≠ azurerm_private_dns_zone  - I'm using private one for the project purpose.
- subresource_names = ["sites"] - this atribute is mandatory in private endpoint for app service
- NSG flow logs retired → VNet flow logs (NTANetAnalytics) for future detection

