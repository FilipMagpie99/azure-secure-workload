# Day 9 — moduły (refaktor flat → modules/network)

## Cheat sheet
```bash
# generuj bloki moved zamiast klepać ręcznie
terraform state list | while read addr; do
  printf 'moved {\n  from = %s\n  to   = module.network.%s\n}\n\n' "$addr" "$addr"
done > moved.tf

terraform plan | grep '#'      # szybki podgląd add/change/destroy
terraform fmt                  # po każdej edycji
terraform apply                # ZAPISUJE migrację moved do stanu (plan tylko planuje)
rm moved.tf                    # rusztowanie schodzi po udanym apply
```

## Notes
- Moduł = KATALOG, nie plik. Wszystkie .tf w katalogu = jeden moduł. Nazwa pliku nieważna.
- Root = pozycja, nie deklaracja. Root = katalog, w którym odpalasz terraform. Nie ma `module "root"`.
- Każdy moduł ma WŁASNY komplet var / local / output. Nic nie jest globalne.
  - var    = wejście, jawny most: argument bloku module ↔ variable {} w childzie
  - output = wyjście, jawny most: output {} w childzie ↔ module.x.y w roocie
  - local  = środek, BRAK mostu, prywatne. Chcesz na zewnątrz → przepakuj w output.
- Relacja moduł↔moduł jednokierunkowa, z góry w dół. Child nie zna roota → reużywalny.
- Adres zasobu = typ.nazwa_lokalna. W module dostaje prefiks: module.network.typ.nazwa.
- moved {} = deklaratywne mapowanie stary_adres → nowy_adres. Robi z destroy+create
  przeprowadzkę. Leży w ROOT. Configuration-driven, jedzie przez plan/PR/CI.
  (vs `terraform state mv` = imperatywne, out-of-band, niewidoczne w gicie — gorsze.)
- Pętla outputów: zasób → output childa → module.network.x w roocie.

## 💡 Gotchas
- 3 ściany = 3 błędy, każdy uderzony na żywo:
  1. "Unsupported argument" → child nie ma variable {} na ten input. Zadeklaruj w childzie.
  2. "not declared in module.network" → moduł referuje zasób roota (azurerm_resource_group.rg).
     Nie widzi go! Zamień na var.*. Referencje do zasobów roota robisz w ROOCIE, w bloku module.
  3. plan pokazuje destroy+create po przeniesieniu → brak moved {}. Adres się zmienił, obiekt nie.
- "Enter a value:" przy plan = SMELL. Prawie zawsze: odpalasz Terraform nie z tego katalogu
  (np. z wnętrza modułu — wtedy moduł staje się rootem i pyta o brakujące inputy). Ctrl+C, cd do roota.
- Po moved bez przepięcia outputów: "Changes to Outputs: ... -> null". Root czyta zasoby po starym
  adresie, którego już nie ma. Fix: child wystawia output, root czyta module.network.x.
- DoD piece 3 = plan "0 to add, 0 to change, 0 to destroy" + brak sekcji Changes to Outputs.
- Implicit dependency: w bloku module przekaż azurerm_resource_group.rg.name (nie var.x) →
  zależność jawna przez referencję, graf sam ustawia kolejność (wzorzec z Day 7).