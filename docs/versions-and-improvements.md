# Fixing versions and applying improvements after a merge

After a PR is merged (e.g. the sources-layer PR), use this to get your local repo and project version in sync and ensure all improvements are on `main`.

## 1. Sync local with merged `main`

So your local `main` has the latest merged changes (sources layer, docs, rules):

```bash
git checkout main
git pull origin main
```

You can delete the feature branch locally if you no longer need it:

```bash
git branch -d feat/sources-layer
```

## 2. If something was missing from the merge (e.g. squash)

If the merge was a squash, only the first commit’s files may be on `main`. Commits added later on the feature branch (e.g. the PR testing rule) won’t be on `main`.

To add the missing file(s) to `main`:

```bash
git checkout main
git pull origin main
git checkout -b chore/add-missing-rule
# Copy or checkout the missing file from the feature branch, e.g.:
git checkout feat/sources-layer -- .cursor/rules/dbt-pr-and-testing.mdc
git add .cursor/rules/dbt-pr-and-testing.mdc
git commit -m "chore(dbt): add PR testing rule to main"
git push -u origin chore/add-missing-rule
# Open a PR chore/add-missing-rule → main, merge, then pull main again.
```

Or, from the feature branch, cherry-pick the missing commit onto `main` and push (if you have push access to `main`):

```bash
git checkout main
git pull origin main
git cherry-pick <commit-hash-for-pr-testing-rule>
git push origin main
```

## 3. Bump project version to reflect the improvement

To record the new feature in the project version (SemVer: minor = new feature):

1. In `dbt_project.yml`, set `version` to the next minor, e.g. `"1.1.0"` (was `"1.0.0"`).
2. Commit and push (directly on `main` or via a small PR):

```bash
# From main (after pull)
# Edit dbt_project.yml: version: "1.1.0"
git add dbt_project.yml
git commit -m "chore: bump version to 1.1.0 for sources layer"
git push origin main
```

## Summary

| Goal | Action |
|------|--------|
| Local `main` has merged improvements | `git checkout main && git pull origin main` |
| Missing rule/file from squash merge | Branch from `main`, bring file from feature branch, commit, PR (or cherry-pick). |
| Version reflects new feature | Bump `version` in `dbt_project.yml` (e.g. 1.0.0 → 1.1.0), commit and push. |
