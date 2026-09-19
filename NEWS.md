# senado (development version)

## New functions

* Reference data: `sen_legislatures()`, `sen_parties()`, `sen_bill_types()`
  and `sen_bill_statuses()`.
* Senators: `sen_senators()` (currently in office, or by legislature),
  `sen_senator()`, `sen_senator_mandates()`, `sen_senator_committees()` and
  `sen_senator_speeches()`. `sen_senator_speeches()` splits periods longer
  than one year into yearly requests, because the API silently truncates
  them.

## Infrastructure

* Every function declares the columns it returns. Column types no longer
  depend on the content of the response, results without rows keep their
  columns, and the vote code `"NA"` is never read as a missing value.
* API errors are no longer swallowed. They are raised with the message sent
  by the API and a class: `senado_error_not_found`,
  `senado_error_bad_request` or `senado_error_unavailable` (all inherit from
  `senado_error`).
* The JSON/XML fallback happens only when a response cannot be parsed or the
  API answers 406 -- no longer on 4xx, 5xx or timeout.
* Requests are retried on 429, 500, 502, 503 and 504.
* New option `senado.timeout` (seconds, default 120; it was fixed at 30).
* A test reads the OpenAPI spec of the API and fails if any endpoint used by
  the package is deprecated or gone.

* Package scaffolding created.
* Initial project structure with CI/CD via GitHub Actions.
