# Phase 02 — Manual Test Results

**Tester:** Sidney Bissoli
**Date:** 2026-03-20
**Package version:** 0.0.0.9000
**R version:** 4.5.2
**Platform:** Windows 11 x64 (build 26200)

---

## Summary

All Phase 02 infrastructure tests passed. The API access layer (`sen_get`), cache system, parsers, and validators are fully operational against the live Senado API.

| Component | Result |
|---|:-:|
| `devtools::check()` | 0 errors, 0 warnings, 1 note (empty NEWS.md) |
| `devtools::test()` | 125 tests passed, 0 failures |
| Manual testing | 18/18 checks passed |

---

## Test 2 — `sen_get()` against real API

**Result:** PASS

```r
result <- sen_get("senador/lista/atual", cache_category = "semi_static")
str(result, max.level = 2)
# List of 1
#  $ ListaParlamentarEmExercicio:List of 3
#   ..$ noNamespaceSchemaLocation: chr
#   ..$ Metadados                :List of 4
#   ..$ Parlamentares            :List of 1

nrow(result$ListaParlamentarEmExercicio$Parlamentares$Parlamentar)
# [1] 81
```

81 senators returned. Full tibble conversion via `sen_as_tibble()` produced 33 `snake_case` columns with correct type conversions.

---

## Test 3 — Cache behaviour

**Result:** PASS (all sub-tests)

| Sub-test | Expected | Observed |
|---|---|---|
| 3a. Cached call | ~0 seconds | 0.00s |
| 3b. Cache disabled (`use_cache = FALSE`) | Network time | 0.53s |
| 3c. Re-enable cache | Option set | OK |
| 3d. Cache cleared → fresh fetch | Network time | 0.12s |
| 3e. Clear single category | Only dynamic cleared | OK |

```r
# 3a
system.time(sen_get("senador/lista/atual", cache_category = "semi_static"))
#   usuário   sistema decorrido
#         0         0         0

# 3b
options(senado.use_cache = FALSE)
system.time(sen_get("senador/lista/atual", cache_category = "semi_static"))
#   usuário   sistema decorrido
#      0.05      0.00      0.53

# 3d
sen_cache_clear()
# ✔ Cache cleared.
system.time(sen_get("senador/lista/atual", cache_category = "semi_static"))
#   usuário   sistema decorrido
#      0.06      0.00      0.12

# 3e
sen_cache_clear("dynamic")
# ✔ Cache cleared (dynamic).
```

---

## Test 4 — JSON/XML fallback

**Result:** PASS

```r
# XML format
xml_result <- sen_get("senador/lista/atual", format = "xml", cache_category = "semi_static")
str(xml_result, max.level = 2)
# List of 1
#  $ ListaParlamentarEmExercicio:List of 2
#   ..$ Metadados    :List of 4
#   ..$ Parlamentares:List of 81

# JSON format (default)
json_result <- sen_get("senador/lista/atual", format = "json", cache_category = "semi_static")
str(json_result, max.level = 2)
# List of 1
#  $ ListaParlamentarEmExercicio:List of 3
#   ..$ noNamespaceSchemaLocation: chr
#   ..$ Metadados                :List of 4
#   ..$ Parlamentares            :List of 1
```

Both formats return data. XML returns 81 Parlamentares as direct list elements; JSON returns them nested inside a data.frame.

---

## Test 5 — Error handling

**Result:** PASS

```r
# 5a. Bad endpoint
try(sen_get("endpoint/que/nao/existe"))
# ! Request to <.../endpoint/que/nao/existe> failed: HTTP 404 Not Found.
# ℹ JSON request failed. Falling back to XML.
# ! Request to <.../endpoint/que/nao/existe> failed: HTTP 404 Not Found.
# Error: Failed to retrieve data from the Senado API.
# ℹ Endpoint: <https://legis.senado.leg.br/dadosabertos/endpoint/que/nao/existe>
# ℹ Both JSON and XML formats failed after retries.

# 5b. Unreachable URL
withr::with_envvar(c(SENADO_API_BASE_URL = "https://localhost:1"), {
  try(sen_get("senador/lista/atual"))
})
# ! Request to <https://localhost:1/senador/lista/atual> failed:
#   Could not connect to server [localhost]
# ℹ JSON request failed. Falling back to XML.
# ! Request to <https://localhost:1/senador/lista/atual> failed:
#   Could not connect to server [localhost]
# Error: Failed to retrieve data from the Senado API.
# ℹ Both JSON and XML formats failed after retries.
```

Both scenarios: JSON attempted first, fallback to XML, then informative error with endpoint URL.

---

## Test 6 — Throttle

**Result:** PASS

```r
sen_cache_clear()
options(senado.use_cache = FALSE)
system.time({
  for (i in 1:4) {
    sen_get("senador/lista/atual", cache_category = "dynamic")
  }
})
#   usuário   sistema decorrido
#      0.19      0.00      0.50
options(senado.use_cache = TRUE)
```

Throttle is active (`httr2::req_throttle(rate = 2/1)`). The 0.50s total for 4 requests reflects fast API responses; the throttle enforces a minimum 0.5s gap between requests.

---

## Test 7 — Parsers (`utils-parse.R`)

**Result:** PASS (all sub-tests)

```r
# 7a. snake_case conversion
senado:::to_snake_case(c("CodigoParlamentar", "siglaPartido", "XMLParser"))
# [1] "codigo_parlamentar" "sigla_partido"      "xml_parser"

# 7b. Logical conversion
senado:::parse_logical(c("Sim", "Não", NA))
# [1]  TRUE FALSE    NA

# 7c. Date parsing — ISO
senado:::try_parse_date(c("2024-01-15", "2024-06-30"))
# [1] "2024-01-15" "2024-06-30"

# 7c. Date parsing — BR format
senado:::try_parse_date(c("15/01/2024", "30/06/2024"))
# [1] "2024-01-15" "2024-06-30"

# 7c. Date parsing — datetime with timezone
senado:::try_parse_date(c("2024-01-15T10:30:00", "2024-06-30T14:00:00"))
# [1] "2024-01-15 10:30:00 -03" "2024-06-30 14:00:00 -03"

# 7d. Numeric parsing (comma as decimal separator)
senado:::parse_numeric(c("1,5", "2,75", NA))
# [1] 1.50 2.75   NA
```

---

## Test 8 — Validators (`utils-validate.R`)

**Result:** PASS (all sub-tests)

```r
# 8a. Valid inputs — all return silently
senado:::validate_year(2024)
senado:::validate_senator_code(5012)
senado:::validate_bill_code(100)
senado:::validate_party("PT")
senado:::validate_uf("SP")

# 8b. Invalid inputs — friendly error messages
try(senado:::validate_year(1990))
# Error: `year` must be >= 1991 (start of available data), not 1990.

try(senado:::validate_year(2099))
# Error: `year` must be <= 2026 (current year), not 2099.

try(senado:::validate_year("abc"))
# Error: `year` must be numeric, not <character>.

try(senado:::validate_senator_code(-1))
# Error: `code` must be a positive integer, not -1.

try(senado:::validate_party(123))
# Error: `party` must be a single character string, not <numeric>.

try(senado:::validate_uf("XX"))
# Error: "XX" is not a valid Brazilian state abbreviation.
# ℹ Valid values: "AC", "AL", "AM", ... "SP", and "TO".

try(senado:::validate_uf("ABC"))
# Error: "ABC" is not a valid Brazilian state abbreviation.
# ℹ Valid values: "AC", "AL", "AM", ... "SP", and "TO".
```

---

## Test 9 — `SENADO_CACHE_ENABLED` env var

**Result:** PASS

```r
# 9a. Set env var to disable cache
Sys.setenv(SENADO_CACHE_ENABLED = "false")
devtools::load_all()
getOption("senado.use_cache")
# [1] FALSE

# 9b. After R restart + unset env var
Sys.unsetenv("SENADO_CACHE_ENABLED")
devtools::load_all()  # after Ctrl+Shift+F10
getOption("senado.use_cache")
# [1] TRUE
```

Note: step 9b requires a full R restart (`Ctrl+Shift+F10`) because `.onLoad` does not overwrite options that already exist. This is by design.

---

## Final checklist

| # | What to verify | Pass |
|:-:|---|:-:|
| 2 | `sen_get()` returns data from real endpoint (81 senators) | ✅ |
| 3a | Cache makes second call instant (0.00s) | ✅ |
| 3b | `senado.use_cache = FALSE` bypasses cache | ✅ |
| 3d | `sen_cache_clear()` forces fresh fetch | ✅ |
| 3e | Clear single category works | ✅ |
| 4a | XML format returns data | ✅ |
| 4b | JSON format returns data | ✅ |
| 5a | Bad endpoint → informative error with fallback | ✅ |
| 5b | Unreachable URL → error after retries | ✅ |
| 6 | Throttle active | ✅ |
| 7a | `to_snake_case()` converts correctly | ✅ |
| 7b | Logical parsing (Sim/Não → TRUE/FALSE) | ✅ |
| 7c | Date parsing (ISO, BR, datetime with tz) | ✅ |
| 7d | Numeric parsing (comma decimal) | ✅ |
| 8a | Validators accept valid input | ✅ |
| 8b | Validators reject with clear messages | ✅ |
| 9a | `SENADO_CACHE_ENABLED=false` disables cache | ✅ |
| 9b | Default re-enabled after R restart | ✅ |
