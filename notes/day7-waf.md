# Day X — dzień walki z ARM/state (throttling, region, sieroty)

## Co było zepsute (po ludzku)
1. **429 na App Service Plan** — za dużo cykli apply/destroy jednego dnia. Azure
   throttluje CREATE planów per **subskrypcja+region** (komunikat "for subscription"
   kłamie — RG nie ma znaczenia, region TAK). Sprawdzone empirycznie: nowy RG w tym
   samym regionie = dalej 429, inny region = działa.
2. **Zmiana location na żywym stacku** — apply z nowym regionem = replace RG.
   Azure kasuje RG kaskadowo POD trwającym apply → zasoby znikają w trakcie,
   lawina 404 i "Root object absent". Plan tego nie pokazuje.
3. **Wybrałem region na ślepo (germanywestcentral)** — trial ma restrykcje per region:
   Postgres zablokowany, quota App Service = 0. Straciłem godzinę na region, którego
   nie sprawdziłem, mając potwierdzony testem swedencentral.
4. **"Root object was present, but now absent"** — to NIE znaczy, że zasób nie powstał.
   Provider tworzy zasób → od razu go czyta → ARM jeszcze nie zreplikował → 404 →
   provider WYRZUCA zasób ze state. Zasób żyje jako sierota. Znana klasa bugów azurerm,
   niezależna od wersji.
5. **Postgres `zone`** — Azure sam przydziela strefę, jeśli nie zadeklaruję. Brak `zone`
   w HCL ≠ "zostaw jak jest" — provider próbuje strefę ZDJĄĆ i ARM to odrzuca.
   Fix: przypiąć w HCL to, co przydzielił Azure (`zone = "3"`).

## Runbook na przyszłość
- **State rozjechany z rzeczywistością:** STOP apply → `terraform apply -refresh-only`
  → `terraform state list` vs `az resource list` → destroy/napraw → JEDEN apply.
- **404 zaraz po apply/przerwanym apply:** nie wierzyć. Odczekać 5 min, sprawdzić
  GET-em (`az ... show`), nie list-em. Decyzje o state tylko na świeżym GET.
- **Zasób w Azure, brak w state (sierota):** `terraform import <adres> <ID>`.
- **Zasób w state, brak w Azure (trup):** `terraform state rm <adres>` — ale dopiero
  po potwierdzeniu GET-em, że trwale nie istnieje.
- **Zmiana regionu = dwie fazy:** pełny destroy w starym regionie, PO destroy zmiana
  var, potem apply. Nigdy jednym przebiegiem.
- **Po każdym destroy/az group delete:** `az group exists` musi być stabilnie false
  (2x w odstępie minuty), zanim ruszy apply. Kasacja RG jest asynchroniczna.
- **Przed zmianą regionu:** test SKU w nowym regionie (30 s):
  `az appservice plan create --sku B1` + `az postgres flexible-server list-skus`.
- **Nie robić kilku pełnych cykli destroy/apply dziennie** — to nabija throttle.
  Baza (VNet/DNS/LAW) zostaje żywa, gaszę punktowo drogie rzeczy
  (`terraform destroy -target` na App GW).

## Na jutro
- [ ] Test frontendu przez publiczny IP App Gateway (403 z azurewebsites.net = OK, to lockdown)
- [ ] App GW: cert/listener 443, `pick_host_name_from_backend_address`, SCM won z backend poola
- [ ] WAF policy: `enabled = false` + Detection — włączyć i zdecydować tryb (ADR)
- [ ] Duplikat subnetów `snet-appgw` vs `snet-app-gw` — który kanoniczny, drugi wyleciał + ADR
- [ ] ADR: zone na Postgres (przydział niedeterministyczny, config podąża za API)
- [ ] Gotchas z dzisiaj przepisać do notes/ (throttle, RG-replace race, eventual
      consistency, import/state rm — obie strony rozjazdu state↔rzeczywistość)