# Gold Insight Visualizations

This folder contains a small reporting script that queries the BigQuery gold marts and saves chart images plus CSV extracts.

The script is designed to run from an authenticated local environment because it needs access to the project BigQuery dataset.

## Target dataset

Default:

```text
centering-crow-496515-u6.trend_intelligence_dev
```

You can override the project or dataset with command-line arguments.

## Setup

From the repository root:

```bash
python -m pip install -r demo/gold_insights/requirements.txt
gcloud auth application-default login
gcloud auth application-default set-quota-project centering-crow-496515-u6
```

## Generate visualizations

```bash
python demo/gold_insights/generate_gold_insights.py
```

For the filtered development dataset:

```bash
python demo/gold_insights/generate_gold_insights.py \
  --dataset trend_intelligence_dev_filtered
```

## Outputs

The script saves CSV extracts and PNG charts to:

```text
demo/gold_insights/outputs/
```

Generated charts:

1. `01_top_terms_by_market_reach.png`
2. `02_fastest_rising_terms.png`
3. `03_top_markets_by_activity.png`
4. `04_trend_type_distribution.png`
5. `05_market_scope_distribution.png`
6. `06_country_activity.png`
7. `07_rank_history_top_terms.png`
8. `08_gold_table_sizes.png`

## Notes

The queries use aggregated gold marts where possible to keep runtime and BigQuery scan cost controlled. A few charts intentionally query the gold fact table to show current trend distribution and rank history.
