-- macros/ingest_raw.sql
{% macro ingest_raw(source, folder, database=None, schema='raw', file_glob='*.csv') %}
  {# normalize args #}
  {% set db = database or target.database %}
  {% set p = folder | replace('\\','/') %}

  {% if source not in ['stocks','vix'] %}
    {{ exceptions.raise_compiler_error("ingest_raw: source must be 'stocks' or 'vix'") }}
  {% endif %}

  -- 1) ensure schema exists
  {{ run_query("create schema if not exists " ~ db ~ "." ~ schema ~ ";") }}

  {% if source == 'stocks' %}
    {# stocks: expected cols: trade_date, ticker, open, high, low, close, volume, loaded_at #}
    {{ run_query(
      "create table if not exists " ~ db ~ "." ~ schema ~ ".stocks (" ~
      "trade_date date, ticker text, \"open\" double, high double, low double, \"close\" double, " ~
      "volume double, loaded_at timestamp default now()" ~
      ");"
    ) }}

    {% set sql %}
      insert into {{ db }}.{{ schema }}.stocks
        (trade_date, ticker, "open", high, low, "close", volume, loaded_at)
      select
        cast(trade_date as date),
        cast(ticker as text),
        cast("open" as double),
        cast(high as double),
        cast(low as double),
        cast("close" as double),
        cast(volume as double),
        now()
      from read_csv_auto('{{ p }}/stocks/{{ file_glob }}')
      where not exists (
        select 1
        from {{ db }}.{{ schema }}.stocks t
        where t.ticker = cast(ticker as text)
          and t.trade_date = cast(trade_date as date)
      );
    {% endset %}
    {{ run_query(sql) }}

  {% elif source == 'vix' %}
    {{ run_query(
      "create table if not exists " ~ db ~ "." ~ schema ~ ".vix (" ~
      "\"date\" date, \"close\" double, loaded_at timestamp default now()" ~
      ");"
    ) }}

    {% set sql %}
      insert into {{ db }}.{{ schema }}.vix
        ("trade_date", "close", loaded_at)
      select
        cast(coalesce(observation_date) as date)        as "trade_date",
        cast(coalesce(Close) as double)   as "close",
        now()
      from read_csv_auto('{{ p }}/vix/{{ file_glob }}')
      where not exists (
        select 1
        from {{ db }}.{{ schema }}.vix t
        where t.trade_date = cast(coalesce(observation_date) as date)
      );
    {% endset %}
    {{ run_query(sql) }}

  {% endif %}
{% endmacro %}
