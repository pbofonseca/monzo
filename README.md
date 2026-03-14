# Monzo dbt project

dbt project for BigQuery (Monzo data warehouse). See **[dbt_monzo/README.md](dbt_monzo/README.md)** for setup and usage.

## Using this repo with GitHub

1. **Create a new repository on GitHub** (e.g. `monzo` or `dbt-monzo`). Do **not** initialize it with a README so the repo is empty.

2. **Add the remote and push** (replace `YOUR_USERNAME` and `YOUR_REPO` with your GitHub user and repo name):

   ```bash
   cd /Users/pablofonseca/Documents/dev/monzo
   git remote add origin https://github.com/YOUR_USERNAME/YOUR_REPO.git
   git branch -M main
   git push -u origin main
   ```

   Or with SSH:

   ```bash
   git remote add origin git@github.com:YOUR_USERNAME/YOUR_REPO.git
   git branch -M main
   git push -u origin main
   ```

3. **After cloning elsewhere**, set up dbt from `dbt_monzo/` using the instructions in `dbt_monzo/README.md` (copy `profiles.yml.example` to `profiles.yml` or use `~/.dbt/profiles.yml`, then run with `DBT_PROFILES_DIR=.`).
