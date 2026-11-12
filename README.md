[![Test](https://github.com/BLSQ/orbf-rules_engine/actions/workflows/ci.yml/badge.svg)](https://github.com/BLSQ/orbf-rules_engine/actions/workflows/ci.yml)

# orbf-rules_engine

Computes Results-Based Financing (RBF) invoices for [orbf2](https://github.com/BLSQ/orbf2) (OpenRBF 2.0).

Given a project (packages, activities, formulas, payment rules), an org unit and a period, `Orbf::RulesEngine::FetchAndSolve`:

1. resolves the org units concerned (contracts, groups, zones),
2. fetches their values from DHIS2 (data value sets, analytics),
3. builds the equations (current and past periods, sums, decision tables),
4. solves them,
5. returns the values to publish back to DHIS2.

orbf2 stores the projects, runs this engine (simulations, invoices) and publishes the results.

The engine lives outside of Rails on purpose: plain Ruby objects in, values out, no database or other
persistence side effects, so the same calculation serves simulations, invoices and tests.

It is also kept fast and lean: one invoice can mean tens of thousands of equations (32k for the Liberia
benchmark), so check the time and the memory allocations when changing it (see Development). For the
same reason the equations are solved in Go: hesabu hands them to the `hesabucli` binary of go-hesabu.

## How it works: instantiate, expand, problem, solve

The formulas are declarative: they say what to compute, not how or in which order. A formula can use any
other formula or value, wherever it is defined; the solver works out the order from the dependencies
(a cycle between equations is reported as an error).

Every value is a variable named `<package>_<activity>_<state or formula>_for_<org unit>_and_<period>`.
Examples from [spec/sigl_system_spec.rb](spec/sigl_system_spec.rb), package `sigl_zone`, activity `act1`:

- **instantiate**: a formula, written once per package, becomes one equation per org unit, activity and
  period. `balance = stock_start - stock_end` gives
  `sigl_zone_act1_balance_for_1_and_201601 = sigl_zone_act1_stock_start_for_1_and_201601 - sigl_zone_act1_stock_end_for_1_and_201601`
- **expand**: `%{..._values}` placeholders become the list of variables they cover
  - over periods (spans, windows): `AVG(%{consumed_last_6_months_window_values})` gives
    `AVG(sigl_zone_act1_consumed_for_1_and_201508, ..., sigl_zone_act1_consumed_for_1_and_201601)`
  - over org units (zones): `SUM(%{balance_values})` gives
    `SUM(sigl_zone_act1_balance_for_1_and_201601, sigl_zone_act1_balance_for_2_and_201601)`
- **problem**: all the equations in one `{variable => expression}` hash, the DHIS2 values as constants
  (`sigl_zone_act1_consumed_for_1_and_201601 => 500`); 288 equations in this spec, 32k for the Liberia benchmark
- **solve**: hesabu orders and evaluates the problem (project `engine_version` 3; older ones use dentaku),
  eg balance `10`, zone total `30`, 6 months average `91.67`
- **export**: the solved formulas mapped to DHIS2 data elements are the values orbf2 publishes

## Dependencies

- [hesabu](https://github.com/BLSQ/hesabu): solves the equations with [go-hesabu](https://github.com/BLSQ/go-hesabu) (`hesabucli`, Go)
- [dhis2](https://github.com/BLSQ/dhis2) (branch `legacy-v2`): DHIS2 API client
- [dentaku](https://github.com/rubysolo/dentaku): parses the formulas (and solves them for `engine_version` < 3)
- activesupport

## Development

Ruby 4.0.

```
bundle install
bundle exec rspec
bundle exec ruby bench/invoice_bench.rb 10   # invoice benchmark, appends to bench/results.jsonl
PROF=true bundle exec rspec spec/lib_spec.rb   # profile (ALLOC=true: allocations)
```

`HESABU_DEV_MODE=1` uses a local `../hesabu` checkout.

## License

[MIT](https://opensource.org/licenses/MIT)
