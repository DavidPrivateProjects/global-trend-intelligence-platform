from __future__ import annotations

import argparse
from pathlib import Path
from textwrap import dedent

import matplotlib.pyplot as plt
import pandas as pd
import seaborn as sns
from google.cloud import bigquery


DEFAULT_PROJECT = "centering-crow-496515-u6"
DEFAULT_DATASET = "trend_intelligence_dev"


def parse_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser(
        description="Query BigQuery gold marts and save dashboard-ready insight charts."
    )
    parser.add_argument("--project", default=DEFAULT_PROJECT)
    parser.add_argument("--dataset", default=DEFAULT_DATASET)
    parser.add_argument("--output-dir", default="demo/gold_insights/outputs")
    parser.add_argument("--location", default="US")
    return parser.parse_args()


def query(client: bigquery.Client, sql: str) -> pd.DataFrame:
    return client.query(sql).to_dataframe()


def save_dataframe(df: pd.DataFrame, output_dir: Path, name: str) -> None:
    df.to_csv(output_dir / f"{name}.csv", index=False)


def save_barh(
    df: pd.DataFrame,
    output_dir: Path,
    filename: str,
    x: str,
    y: str,
    title: str,
    xlabel: str,
    ylabel: str = "",
    color: str = "#2563eb",
) -> None:
    plt.figure(figsize=(12, 7))
    sns.barplot(data=df, x=x, y=y, color=color)
    plt.title(title, fontsize=16, weight="bold")
    plt.xlabel(xlabel)
    plt.ylabel(ylabel)
    plt.tight_layout()
    plt.savefig(output_dir / filename, dpi=160)
    plt.close()


def save_bar(
    df: pd.DataFrame,
    output_dir: Path,
    filename: str,
    x: str,
    y: str,
    title: str,
    xlabel: str,
    ylabel: str,
    color: str = "#0f766e",
) -> None:
    plt.figure(figsize=(12, 7))
    sns.barplot(data=df, x=x, y=y, color=color)
    plt.title(title, fontsize=16, weight="bold")
    plt.xlabel(xlabel)
    plt.ylabel(ylabel)
    plt.xticks(rotation=35, ha="right")
    plt.tight_layout()
    plt.savefig(output_dir / filename, dpi=160)
    plt.close()


def save_line(
    df: pd.DataFrame,
    output_dir: Path,
    filename: str,
    x: str,
    y: str,
    hue: str,
    title: str,
    xlabel: str,
    ylabel: str,
) -> None:
    plt.figure(figsize=(13, 7))
    sns.lineplot(data=df, x=x, y=y, hue=hue, marker="o")
    plt.title(title, fontsize=16, weight="bold")
    plt.xlabel(xlabel)
    plt.ylabel(ylabel)
    plt.xticks(rotation=35, ha="right")
    plt.tight_layout()
    plt.savefig(output_dir / filename, dpi=160)
    plt.close()


def save_pie(
    df: pd.DataFrame,
    output_dir: Path,
    filename: str,
    label_col: str,
    value_col: str,
    title: str,
) -> None:
    plt.figure(figsize=(9, 7))
    plt.pie(
        df[value_col],
        labels=df[label_col],
        autopct="%1.1f%%",
        startangle=90,
        textprops={"fontsize": 11},
    )
    plt.title(title, fontsize=16, weight="bold")
    plt.tight_layout()
    plt.savefig(output_dir / filename, dpi=160)
    plt.close()


def main() -> None:
    args = parse_args()
    output_dir = Path(args.output_dir)
    output_dir.mkdir(parents=True, exist_ok=True)

    sns.set_theme(style="whitegrid")
    client = bigquery.Client(project=args.project, location=args.location)
    dataset_ref = f"`{args.project}.{args.dataset}`"

    queries = {
        "top_terms_by_market_reach": f"""
            select
                search_term_display,
                markets_seen_count,
                international_markets_seen_count,
                us_markets_seen_count,
                trend_signal_count,
                best_rank,
                max_percent_gain
            from {dataset_ref}.agg_search_term_performance
            order by markets_seen_count desc, trend_signal_count desc
            limit 15
        """,
        "fastest_rising_terms": f"""
            select
                search_term_display,
                max_percent_gain,
                markets_seen_count,
                rising_appearances,
                best_rank
            from {dataset_ref}.agg_search_term_performance
            where max_percent_gain is not null
            order by max_percent_gain desc, markets_seen_count desc
            limit 15
        """,
        "top_markets_by_activity": f"""
            select
                coalesce(m.market_display_name, s.geo_market_key) as market_display_name,
                m.market_scope,
                m.country_name,
                s.trend_signal_count,
                s.unique_search_terms,
                s.rising_terms_count,
                s.top_terms_count,
                s.avg_percent_gain
            from {dataset_ref}.agg_market_trend_summary s
            left join {dataset_ref}.dim_geo_market m
                on s.geo_market_key = m.geo_market_key
            order by s.trend_signal_count desc
            limit 20
        """,
        "trend_type_distribution": f"""
            select
                trend_type,
                count(*) as trend_signal_count
            from {dataset_ref}.fact_trend_rank_history
            where is_current = true
            group by trend_type
            order by trend_signal_count desc
        """,
        "market_scope_distribution": f"""
            select
                market_scope,
                count(*) as trend_signal_count
            from {dataset_ref}.fact_trend_rank_history
            where is_current = true
            group by market_scope
            order by trend_signal_count desc
        """,
        "country_activity": f"""
            select
                coalesce(m.country_name, 'Unknown') as country_name,
                count(distinct f.search_term_key) as unique_search_terms,
                count(*) as trend_signal_count,
                avg(f.trend_rank) as avg_rank
            from {dataset_ref}.fact_trend_rank_history f
            left join {dataset_ref}.dim_geo_market m
                on f.geo_market_key = m.geo_market_key
            where f.is_current = true
            group by country_name
            order by trend_signal_count desc
            limit 15
        """,
        "rank_history_top_terms": f"""
            with top_terms as (
                select search_term_key
                from {dataset_ref}.agg_search_term_performance
                order by markets_seen_count desc, trend_signal_count desc
                limit 5
            )
            select
                f.week_start_date,
                any_value(f.search_term_display) as search_term_display,
                avg(f.trend_rank) as avg_rank
            from {dataset_ref}.fact_trend_rank_history f
            inner join top_terms t
                on f.search_term_key = t.search_term_key
            where f.is_current = true
            group by f.week_start_date, f.search_term_key
            order by f.week_start_date
        """,
        "gold_table_sizes": f"""
            select
                table_id as table_name,
                row_count,
                size_bytes / 1024 / 1024 as size_mb
            from `{args.project}.{args.dataset}.__TABLES__`
            where table_id in (
                'dim_geo_market',
                'dim_search_term',
                'fact_trend_rank_history',
                'fact_rising_term_momentum',
                'agg_market_trend_summary',
                'agg_search_term_performance'
            )
            order by row_count desc
        """,
    }

    frames = {}
    for name, sql in queries.items():
        print(f"Querying {name}...")
        df = query(client, dedent(sql))
        frames[name] = df
        save_dataframe(df, output_dir, name)

    save_barh(
        frames["top_terms_by_market_reach"],
        output_dir,
        "01_top_terms_by_market_reach.png",
        x="markets_seen_count",
        y="search_term_display",
        title="Search Terms With the Broadest Market Reach",
        xlabel="Markets seen",
    )

    save_barh(
        frames["fastest_rising_terms"],
        output_dir,
        "02_fastest_rising_terms.png",
        x="max_percent_gain",
        y="search_term_display",
        title="Fastest Rising Search Terms",
        xlabel="Maximum percent gain",
        color="#dc2626",
    )

    save_barh(
        frames["top_markets_by_activity"],
        output_dir,
        "03_top_markets_by_activity.png",
        x="trend_signal_count",
        y="market_display_name",
        title="Most Active Trend Markets",
        xlabel="Trend signals",
        color="#7c3aed",
    )

    save_pie(
        frames["trend_type_distribution"],
        output_dir,
        "04_trend_type_distribution.png",
        label_col="trend_type",
        value_col="trend_signal_count",
        title="Trend Signal Mix: Top vs Rising",
    )

    save_pie(
        frames["market_scope_distribution"],
        output_dir,
        "05_market_scope_distribution.png",
        label_col="market_scope",
        value_col="trend_signal_count",
        title="Trend Signal Mix by Market Scope",
    )

    save_barh(
        frames["country_activity"],
        output_dir,
        "06_country_activity.png",
        x="trend_signal_count",
        y="country_name",
        title="Countries With the Most Current Trend Activity",
        xlabel="Trend signals",
        color="#0891b2",
    )

    save_line(
        frames["rank_history_top_terms"],
        output_dir,
        "07_rank_history_top_terms.png",
        x="week_start_date",
        y="avg_rank",
        hue="search_term_display",
        title="Average Rank History for Broad-Reach Terms",
        xlabel="Week",
        ylabel="Average rank",
    )

    save_bar(
        frames["gold_table_sizes"],
        output_dir,
        "08_gold_table_sizes.png",
        x="table_name",
        y="row_count",
        title="Gold Mart Row Counts",
        xlabel="Gold table",
        ylabel="Rows",
        color="#ea580c",
    )

    print(f"Saved charts and CSV extracts to {output_dir}")


if __name__ == "__main__":
    main()
