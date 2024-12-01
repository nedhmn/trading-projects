WITH
    dte_7_data AS (
        SELECT
            call_id,
            put_id,
            trade_date,
            expir_date,
            dte,
            strike_price,
            stock_price,
            delta AS call_delta,
            (delta - 1) AS put_delta
        FROM
            `nedhmn.option_prices.spy_data`
        WHERE
            dte = 7
    ),
    call_selection AS (
        SELECT
            *,
            ROW_NUMBER() OVER (
                PARTITION BY
                    trade_date,
                    expir_date
                ORDER BY
                    ABS(call_delta - 0.20)
            ) AS rn
        FROM
            dte_7_data
    ),
    put_selection AS (
        SELECT
            *,
            ROW_NUMBER() OVER (
                PARTITION BY
                    trade_date,
                    expir_date
                ORDER BY
                    ABS(put_delta - (-0.20))
            ) AS rn
        FROM
            dte_7_data
    ),
    selected_pairs AS (
        SELECT
            c.call_id,
            p.put_id,
            c.trade_date AS signal_date,
            c.expir_date,
            c.call_delta,
            p.put_delta,
            c.strike_price AS call_strike,
            p.strike_price AS put_strike,
            c.stock_price
        FROM
            call_selection c
            INNER JOIN put_selection p ON c.trade_date = p.trade_date
            AND c.expir_date = p.expir_date
            AND c.rn = 1
            AND p.rn = 1
    ),
    option_prices AS (
        SELECT
            sp.call_id,
            sp.put_id,
            sp.signal_date,
            c.trade_date,
            sp.expir_date,
            c.dte,
            sp.call_strike,
            sp.put_strike,
            c.stock_price,
            (c.call_bid_price + c.call_ask_price) / 2 AS call_mid_price,
            (p.put_bid_price + p.put_ask_price) / 2 AS put_mid_price,
            c.delta AS call_delta,
            (p.delta - 1) AS put_delta
        FROM
            selected_pairs sp
            INNER JOIN `nedhmn.option_prices.spy_data` c ON sp.call_id = c.call_id
            INNER JOIN `nedhmn.option_prices.spy_data` p ON sp.put_id = p.put_id
            AND p.trade_date = c.trade_date
        WHERE
            c.trade_date BETWEEN sp.signal_date AND sp.expir_date
    ),
    prices_with_strangle AS (
        SELECT
            *,
            call_mid_price + put_mid_price AS strangle_price,
            FIRST_VALUE(dte) OVER (
                PARTITION BY
                    signal_date
                ORDER BY
                    dte DESC
            ) AS max_dte,
            FIRST_VALUE(dte) OVER (
                PARTITION BY
                    signal_date
                ORDER BY
                    dte ASC
            ) AS min_dte
        FROM
            option_prices
    ),
    entry_prices AS (
        SELECT
            signal_date,
            call_id,
            put_id,
            trade_date AS trade_date_entry,
            expir_date,
            dte AS dte_entry,
            call_strike,
            put_strike,
            stock_price AS stock_price_entry,
            call_mid_price AS call_mid_price_entry,
            put_mid_price AS put_mid_price_entry,
            call_delta AS call_delta_entry,
            put_delta AS put_delta_entry,
            strangle_price AS strangle_price_entry
        FROM
            prices_with_strangle
        WHERE
            dte = max_dte
    ),
    exit_prices AS (
        SELECT
            signal_date,
            trade_date AS trade_date_exit,
            stock_price AS stock_price_exit,
            call_mid_price AS call_mid_price_exit,
            put_mid_price AS put_mid_price_exit,
            strangle_price AS strangle_price_exit
        FROM
            prices_with_strangle
        WHERE
            dte = min_dte
    ),
    strangle_pnl AS (
        SELECT
            e.*,
            x.trade_date_exit,
            x.stock_price_exit,
            x.call_mid_price_exit,
            x.put_mid_price_exit,
            x.strangle_price_exit,
            x.strangle_price_exit - e.strangle_price_entry AS long_strangle_dollar_pnl,
            (x.strangle_price_exit - e.strangle_price_entry) * -1 AS short_strangle_dollar_pnl,
            x.strangle_price_exit / e.strangle_price_entry - 1 AS long_strangle_pct_pnl,
            (x.strangle_price_exit / e.strangle_price_entry - 1) * -1 AS short_strangle_pct_pnl
        FROM
            entry_prices e
            LEFT JOIN exit_prices x ON e.signal_date = x.signal_date
        ORDER BY
            e.signal_date
    )
SELECT
    call_id,
    put_id,
    trade_date_entry AS date_entry,
    trade_date_exit AS date_exit,
    expir_date AS expiration,
    dte_entry AS dte,
    -- call_strike,
    -- put_strike,
    stock_price_entry,
    stock_price_exit,
    call_delta_entry,
    ROUND(put_delta_entry, 5) AS put_delta_entry,
    ROUND(strangle_price_entry, 3) AS strangle_price_entry,
    ROUND(strangle_price_exit, 3) AS strangle_price_exit,
    ROUND(short_strangle_dollar_pnl, 4) AS short_strangle_dollar_pnl,
    ROUND(short_strangle_pct_pnl, 4) AS short_strangle_pct_pnl
FROM
    strangle_pnl
WHERE
    DATE_DIFF(trade_date_exit, trade_date_entry, DAY) = 7
