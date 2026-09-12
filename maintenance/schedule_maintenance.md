# Maintenance Scheduling

Run the maintenance bot on a fixed cadence so it actually fires without you babysitting it.

## Recommended cadence
- **Weekly**: stale scenario detector + rubric drift monitor + chain health check.
- **Monthly**: full checklist review, scenario library refresh, research team sync.

## Automation options
1. **GitHub Actions** (preferred for this repo)
   - Create `.github/workflows/maintenance.yml`
   - Trigger: `schedule` cron `0 9 * * 1` (Monday 9am UTC) for weekly, plus monthly.
   - Step: run the maintenance bot prompt against the current library and open a draft issue with findings.
2. **Cron + local script**
   - `0 9 * * 1 /path/to/run_maintenance.sh`
3. **Manual trigger**
   - Tag a release or push to `maintenance/` to force a run.

## Output rules
- Maintenance bot reports only. It never silently rewrites scenarios or rubric.
- All findings land as GitHub issues labeled `maintenance`.
- Critical drift (rubric disagreement > 20% on calibration set) opens a `priority` issue.

## Starter workflow
```yaml
name: weekly-maintenance
on:
  schedule:
    - cron: '0 9 * * 1'
jobs:
  run:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - name: Run maintenance checks
        run: |
          echo "Stale scenario detector"
          echo "Rubric drift monitor"
          echo "Chain health check"
      - name: Open findings issue
        uses: actions/github-script@v7
        with:
          script: |
            github.rest.issues.create({
              owner: context.repo.owner,
              repo: context.repo.repo,
              title: 'Weekly maintenance report',
              body: 'See maintenance/ outputs.',
              labels: ['maintenance']
            })
```

Wire the real Grok client into the workflow when ready. Until then the echo steps keep the cadence honest.
