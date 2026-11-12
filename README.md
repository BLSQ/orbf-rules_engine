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

## Dependencies

- [hesabu](https://github.com/BLSQ/hesabu): solves the equations with [go-hesabu](https://github.com/BLSQ/go-hesabu) (`hesabucli`, Go)
- [dhis2](https://github.com/BLSQ/dhis2) (branch `legacy-v2`): DHIS2 API client
- [dentaku](https://github.com/rubysolo/dentaku): parses the formulas
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
