# Sources layer

The **sources** layer is the single place where every raw table in the project dataset is declared. It guarantees that no table from the warehouse dataset is used in the dbt project without being defined as a source.

## Where it lives

- **Path**: `models/sources/`
- **File**: `models/sources/_sources__sources.yml`

Only YAML lives in this folder (no `.sql`). All `sources:` definitions for the project belong here.

## Guarantee

**Every new table in the project dataset must be declared in the dbt project** by adding it to `models/sources/_sources__sources.yml` before any model references it.

- Ensures lineage and documentation for all raw data used.
- Ensures a single place to configure freshness and metadata.
- Prevents accidental use of unversioned or undocumented tables.

## Adding a new source table

1. **Declare the table** in `models/sources/_sources__sources.yml` under the correct source (e.g. `monzo_datawarehouse`):
   ```yaml
   - name: your_new_table
     description: Short description of the raw table
   ```
2. **Use it only via `source()`** in a staging model, e.g.:
   ```sql
   from {{ source('monzo_datawarehouse', 'your_new_table') }}
   ```
3. Optionally add a **staging model** (e.g. `stg_<entity>.sql`) that selects from this source and document it in `_staging__models.yml`.

## Referencing sources in models

- **Staging**: `select ... from {{ source('monzo_datawarehouse', 'table_name') }}`
- **Intermediate / marts**: Do not reference `source()`. Use refs to staging or intermediate models only.
