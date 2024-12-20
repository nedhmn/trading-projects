Contango Strategy
================
Ned H
2024-12-15

- [Setup](#setup)
  - [Dependencies](#dependencies)
  - [Load Strangle Data](#load-strangle-data)
  - [Query Contango Data](#query-contango-data)
  - [Join tables into a base table](#join-tables-into-a-base-table)
- [Exploratory Data Analysis](#exploratory-data-analysis)
  - [Short Strangle Returns](#short-strangle-returns)
  - [Strangle Deltas](#strangle-deltas)
  - [Strangle Prices](#strangle-prices)
  - [Contango](#contango)
- [Decile Analysis](#decile-analysis)
  - [Total](#total)
  - [Across Years](#across-years)
- [Strategy Comparisons](#strategy-comparisons)
  - [Contango Strategy vs Benchmark](#contango-strategy-vs-benchmark)
  - [Summary Table](#summary-table)

## Setup

### Dependencies

``` r
library(gt)
library(tidyverse)

# Blog styling
source("packages/utils/aesthetics.R")
```

### Load Strangle Data

Ran [this big query sql script](scripts/bq-spy-strangle-query.sql) to
calculate strangle prices from SPY options.

``` r
# Read the data
bq_strangle_tbl <- read_csv(
    file = "apps/contango-strategy/data/bq-strangle-tbl.csv",
    show_col_types = FALSE
)

bq_strangle_tbl |>
    head(3)
```

<div class="kable-table">

| call_id | put_id | date_entry | date_exit | expiration | dte | stock_price_entry | stock_price_exit | call_delta_entry | put_delta_entry | strangle_price_entry | strangle_price_exit | short_strangle_dollar_pnl | short_strangle_pct_pnl |
|:---|:---|:---|:---|:---|---:|---:|---:|---:|---:|---:|---:|---:|---:|
| SPY190109C00255000 | SPY190109P00242000 | 2019-01-02 | 2019-01-09 | 2019-01-09 | 7 | 249.42 | 257.71 | 0.20508 | -0.18962 | 1.700 | 2.815 | -1.115 | -0.6559 |
| SPY190111C00258000 | SPY190111P00246000 | 2019-01-04 | 2019-01-11 | 2019-01-11 | 7 | 252.25 | 258.88 | 0.19767 | -0.20883 | 1.705 | 0.885 | 0.820 | 0.4809 |
| SPY190114C00260000 | SPY190114P00249000 | 2019-01-07 | 2019-01-14 | 2019-01-14 | 7 | 254.93 | 257.71 | 0.21437 | -0.20752 | 1.650 | 0.010 | 1.640 | 0.9939 |

</div>

### Query Contango Data

Query contango data from [ORATS
hist/cores](https://orats.com/docs/historical-data-api) end-point.

``` r
# Contango response
contango_res <- read_csv(
    sprintf(
        "https://api.orats.io/datav2/hist/cores.csv?token=%s&ticker=SPY&fields=ticker,tradeDate,contango",
        Sys.getenv("ORATS_API")
    ),
    show_col_types = FALSE
)

# Lag contango by 1 day to prevent forward-looking analysis
contango_tbl <- contango_res |>
    rename("tradedate" = tradeDate) |>
    arrange(tradedate) |>
    mutate(lagged_contango = lag(contango))

contango_tbl |>
    head(3)
```

<div class="kable-table">

| ticker | tradedate  | contango | lagged_contango |
|:-------|:-----------|---------:|----------------:|
| SPY    | 2007-01-03 |     0.48 |              NA |
| SPY    | 2007-01-04 |     0.55 |            0.48 |
| SPY    | 2007-01-05 |     0.33 |            0.55 |

</div>

### Join tables into a base table

Joining the contango and strangle prices tables to start doing more
complicated analysis.

``` r
base_tbl <- bq_strangle_tbl |>
    left_join(contango_tbl[, c("tradedate", "lagged_contango")], by = c("date_entry" = "tradedate")) |>
    drop_na(lagged_contango)

# write_csv(base_tbl, "apps/contango-strategy/data/base-tbl.csv")

# Create date ranges
from_date <- min(base_tbl$date_entry) # 2019-01-02
to_date <- max(base_tbl$date_entry) # 2024-11-14

base_tbl |>
    head(3)
```

<div class="kable-table">

| call_id | put_id | date_entry | date_exit | expiration | dte | stock_price_entry | stock_price_exit | call_delta_entry | put_delta_entry | strangle_price_entry | strangle_price_exit | short_strangle_dollar_pnl | short_strangle_pct_pnl | lagged_contango |
|:---|:---|:---|:---|:---|---:|---:|---:|---:|---:|---:|---:|---:|---:|---:|
| SPY190109C00255000 | SPY190109P00242000 | 2019-01-02 | 2019-01-09 | 2019-01-09 | 7 | 249.42 | 257.71 | 0.20508 | -0.18962 | 1.700 | 2.815 | -1.115 | -0.6559 | -0.65 |
| SPY190111C00258000 | SPY190111P00246000 | 2019-01-04 | 2019-01-11 | 2019-01-11 | 7 | 252.25 | 258.88 | 0.19767 | -0.20883 | 1.705 | 0.885 | 0.820 | 0.4809 | -0.41 |
| SPY190114C00260000 | SPY190114P00249000 | 2019-01-07 | 2019-01-14 | 2019-01-14 | 7 | 254.93 | 257.71 | 0.21437 | -0.20752 | 1.650 | 0.010 | 1.640 | 0.9939 | -0.02 |

</div>

## Exploratory Data Analysis

### Short Strangle Returns

``` r
# Summary table for subtitle
base_summary_tbl <- base_tbl |>
    select(short_strangle_pct_pnl) |>
    summarize(
        mean = mean(short_strangle_pct_pnl),
        min = min(short_strangle_pct_pnl),
        max = max(short_strangle_pct_pnl),
        sd = round(sd(short_strangle_pct_pnl), 2),
        n = n()
    ) |>
    mutate(across(mean:max, function(x) scales::percent(x, big.mark = ",")))

short_strangle_returns_plot <- base_tbl |>
    ggplot(aes(x = short_strangle_pct_pnl, fill = "name")) +
    geom_histogram(bins = 100) +
    scale_x_continuous(labels = scales::percent) +
    labs(
        title = "SPY Short Strangle Returns",
        subtitle = sprintf(
            "7DTE 20Delta Short Strangles (n=%s, µ=%s, min=%s, max=%s, sd=%s)",
            base_summary_tbl$n,
            base_summary_tbl$mean,
            base_summary_tbl$min,
            base_summary_tbl$max,
            base_summary_tbl$sd
        ) |>
            str_wrap(90),
        x = "Short Strangle Return",
        y = "Frequency"
    )

short_strangle_returns_plot +
    scale_fill_manual(values = viridis::viridis(1, option = "E")) +
    theme(legend.position = "none")
```

<img src="dist/images/unnamed-chunk-5-1.png" style="display: block; margin: auto;" />

### Strangle Deltas

``` r
delta_tbl <- base_tbl |>
    mutate(strangle_delta = call_delta_entry + put_delta_entry) |>
    select(strangle_delta)

delta_summaries <- delta_tbl |>
    summarize(
        n = n(),
        mean = round(mean(strangle_delta), 4),
        sd = sd(strangle_delta),
        min = min(strangle_delta),
        max = max(strangle_delta)
    ) |>
    mutate(across(sd:max, function(x) round(x, 2)))

strangle_deltas_plot <- delta_tbl |>
    ggplot(aes(x = strangle_delta, fill = "SPY")) +
    geom_histogram(bins = 100) +
    labs(
        title = "SPY Strangle Deltas",
        subtitle = sprintf(
            "7DTE 20Delta Strangles (n=%s, µ=%s, min=%s, max=%s, sd=%s)",
            delta_summaries$n,
            delta_summaries$mean,
            delta_summaries$min,
            delta_summaries$max,
            delta_summaries$sd
        ) |>
            str_wrap(width = 80),
        x = "Delta",
        y = "Frequency"
    )

strangle_deltas_plot +
    scale_fill_manual(values = viridis::viridis(1, option = "E")) +
    theme(legend.position = "none")
```

<img src="dist/images/unnamed-chunk-7-1.png" style="display: block; margin: auto;" />

### Strangle Prices

``` r
price_summaries <- base_tbl |>
    select(strangle_price_entry) |>
    summarize(
        n = n(),
        mean = mean(strangle_price_entry),
        sd = round(sd(strangle_price_entry), 2),
        min = min(strangle_price_entry),
        max = max(strangle_price_entry)
    ) |>
    mutate(across(c(mean, min, max), function(x) scales::dollar(round(x, 2))))

strangle_prices_plot <- base_tbl |>
    select(date_entry, strangle_price_entry) |>
    ggplot(aes(x = strangle_price_entry, fill = "name")) +
    geom_histogram(bins = 100) +
    scale_x_continuous(labels = scales::dollar) +
    labs(
        title = "SPY Strangle Prices",
        subtitle = sprintf(
            "Contango strategy's entry strangle prices (n=%s, µ=%s, min=%s, max=%s, sd=%s)",
            price_summaries$n,
            price_summaries$mean,
            price_summaries$min,
            price_summaries$max,
            price_summaries$sd
        ),
        x = "Strangle Prices",
        y = "Frequency"
    )

strangle_prices_plot +
    scale_fill_manual(values = viridis::viridis(1, option = "E")) +
    theme(legend.position = "none")
```

<img src="dist/images/unnamed-chunk-9-1.png" style="display: block; margin: auto;" />

### Contango

TODO

## Decile Analysis

### Total

``` r
# First, calculate the max values per bucket and store them
bucket_maxes <- base_tbl |>
    mutate(contango_ntile = ntile(lagged_contango, 10)) |>
    group_by(contango_ntile) |>
    summarize(max_contango = max(lagged_contango))

# Now create the plot with custom labels
deciles_total_plot <- base_tbl |>
    mutate(contango_ntile = ntile(lagged_contango, 10)) |>
    group_by(contango_ntile) |>
    summarize(mean_pnl = mean(short_strangle_pct_pnl)) |>
    ggplot(aes(x = contango_ntile, y = mean_pnl, fill = "deciles")) +
    geom_col() +
    scale_y_continuous(labels = scales::percent) +
    scale_x_continuous(
        breaks = 1:10,
        labels = function(x) {
            # Create two-line labels using the stored max values
            paste0(x, "\n<= ", round(bucket_maxes$max_contango[x], 2))
        }
    ) +
    labs(
        title = "Contango Decile vs Mean Short Strangle PnL",
        subtitle = sprintf(
            "SPY contango and 7dte 20delta short strangle percent returns from %s to %s",
            from_date,
            to_date
        ),
        x = "Contango Deciles",
        y = "Mean Short Strangle Returns"
    )

deciles_total_plot +
    scale_fill_manual(values = viridis::viridis(1, option = "E")) +
    theme(legend.position = "none")
```

<img src="dist/images/unnamed-chunk-11-1.png" style="display: block; margin: auto;" />

### Across Years

``` r
deciles_years_plot <- base_tbl |>
    mutate(year = year(date_entry)) |>
    group_by(year) |>
    mutate(contango_ntile = ntile(lagged_contango, 10)) |>
    group_by(year, contango_ntile) |>
    summarize(mean_pnl = mean(short_strangle_pct_pnl)) |>
    ggplot(aes(x = contango_ntile, y = mean_pnl, group = year, fill = "name")) +
    geom_col() +
    scale_y_continuous(labels = scales::percent) +
    scale_x_continuous(breaks = 1:10) +
    labs(
        title = "Contango Decile vs Mean Short Strangle PnL by Year",
        subtitle = "SPY contango and 7dte 20delta short strangle percent returns by year",
        x = "Contango Deciles",
        y = "Mean Short Strangle Returns"
    ) +
    facet_wrap(~year, scales = "free")

deciles_years_plot +
    scale_fill_manual(values = viridis::viridis(1, option = "E")) +
    theme(legend.position = "none")
```

<img src="dist/images/unnamed-chunk-13-1.png" style="display: block; margin: auto;" />

## Strategy Comparisons

### Contango Strategy vs Benchmark

``` r
portfolios_tbl <- base_tbl |>
    filter(lagged_contango > 0) |>
    select(date_entry, contains("_pnl"), lagged_contango) |>
    rename_all(function(x) str_replace(x, "short_strangle", "contango_strat")) |>
    select(-lagged_contango) |>
    right_join(base_tbl |>
        select(date_entry, contains("_pnl"), lagged_contango), by = "date_entry") |>
    arrange(date_entry) |>
    mutate(
        # For days that we aren't in the trade, replacing NA's with 0
        across(contains("contango_strat"), function(x) ifelse(is.na(x), 0, x)),
        across(contains("pnl"), function(x) cumsum(x), .names = "cum_{.col}")
    ) |>
    select(date_entry, lagged_contango, contains("contango_strat"), contains("short_strangle")) |>
    # Multiplying percent returns by $1k
    mutate(across(c("cum_contango_strat_pct_pnl", "cum_short_strangle_pct_pnl"), function(x) x * 1000, .names = "{.col}_1k"))

portfolios_plot <- portfolios_tbl |>
    select(date_entry, cum_contango_strat_pct_pnl_1k, cum_short_strangle_pct_pnl_1k) |>
    pivot_longer(2:3) |>
    arrange(name, date_entry) |>
    mutate(zindex = ifelse(name == "cum_contango_strat_pct_pnl_1k", 1, 0)) |>
    ggplot(aes(x = date_entry, y = value, color = name, zindex = zindex)) +
    geom_line() +
    scale_y_continuous(labels = scales::dollar) +
    labs(
        title = "SPY's Contango Strategy vs Benchmark",
        subtitle = sprintf("from %s to %s", min(portfolios_tbl$date_entry), max(portfolios_tbl$date_entry)),
        x = "",
        y = "Cumulative sum of dollar returns",
        caption = str_wrap(
            "Contango portfolio enters a 7dte 20delta short strangle position whenever the previous' day contango is above 0 and stays in that position until expiration. Benchmark is a simple short strangle without any signals. Both strategies have $1k per position and is not accounting for slippage.",
            width = 100
        ),
        color = "Portfolios"
    )

portfolios_plot +
    scale_color_manual(
        values = viridis::viridis(3)[c(1, 2)],
        labels = c("cum_contango_strat_pct_pnl_1k" = "Contango Strategy", "cum_short_strangle_pct_pnl_1k" = "Benchmark")
    )
```

<img src="dist/images/unnamed-chunk-15-1.png" style="display: block; margin: auto;" />

### Summary Table

``` r
summary_tbl <- portfolios_tbl |>
    reframe(
        date_entry,
        contango_strat_pct_pnl_1k = contango_strat_pct_pnl * 1000,
        short_strangle_pct_pnl_1k = short_strangle_pct_pnl * 1000,
        lagged_contango
    ) |>
    pivot_longer(contains("pnl")) |>
    # Filter out non-trade days for contango strategy so that it
    # doesn't bias the volatility, median, mean, or count.
    filter(!(name == "contango_strat_pct_pnl_1k" & lagged_contango <= 0)) |>
    arrange(name, date_entry) |>
    drop_na(value) |>
    group_by(name) |>
    reframe(
        total_dollar_pnl = sum(value),
        lowest_dollar_pnl = min(value),
        median_dollar_pnl = median(value),
        mean_dollar_pnl = mean(value),
        stdev = round(sd(value / 1000), 2),
        trades = n()
    ) |>
    mutate(
        name = c("Contango Strategy", "Benchmark"),
        across(contains("dollar"), function(x) scales::dollar(x))
    ) |>
    rename(
        " " = name,
        "Total PnL" = total_dollar_pnl,
        "Max Loss" = lowest_dollar_pnl,
        "Median Return" = median_dollar_pnl,
        "Mean Return" = mean_dollar_pnl,
        "StdDev" = stdev,
        "Trades" = trades
    ) |>
    arrange(` `)

summary_tbl
```

<div class="kable-table">

|                   | Total PnL | Max Loss  | Median Return | Mean Return | StdDev | Trades |
|:------------------|:----------|:----------|:--------------|:------------|-------:|-------:|
| Benchmark         | \$118,134 | -\$20,814 | \$970.40      | \$110.51    |   1.71 |   1069 |
| Contango Strategy | \$106,834 | -\$20,814 | \$972.60      | \$139.65    |   1.78 |    765 |

</div>
