from pathlib import Path

import pandas as pd

RAW_DIR = Path(__file__).resolve().parents[1] / "data" / "raw"
ALLOWED_EVENTS = ["view", "addtocart", "transaction"]
REQUIRED_COLUMNS = {
    "timestamp",
    "visitorid",
    "event",
    "itemid",
    "transactionid",
}


def inspect_sample(events_path):
    events = pd.read_csv(
        events_path,
        nrows=100_000,
        dtype={"transactionid": "Int64"},
    )

    events["event_time"] = pd.to_datetime(
        events["timestamp"],
        unit="ms",
        utc=True,
        errors="coerce",
    )

    print("\nFIRST FIVE ROWS")
    print(events.head().to_string(index=False))

    print("\nCOLUMN TYPES")
    print(events.dtypes)

    print("\nMISSING VALUES — SAMPLE")
    print(events.isna().sum())

    print("\nEVENT COUNTS — SAMPLE")
    print(events["event"].value_counts(dropna=False))

    print("\nTIME RANGE — SAMPLE")
    print(events["event_time"].min(), "to", events["event_time"].max())

    print("\nEXACT DUPLICATE ROWS — SAMPLE")
    print(events.duplicated().sum())

    purchase = events["event"].eq("transaction").fillna(False)

    print("\nPURCHASE EVENTS WITHOUT TRANSACTION ID — SAMPLE")
    print(events.loc[purchase, "transactionid"].isna().sum())

    print("\nNON-PURCHASE EVENTS WITH TRANSACTION ID — SAMPLE")
    print(events.loc[~purchase, "transactionid"].notna().sum())

    print("\nUNEXPECTED EVENT TYPES — SAMPLE")
    print(
        events.loc[
            ~events["event"].isin(ALLOWED_EVENTS), "event"
        ].value_counts(dropna=False)
    )


def validate_full_events(events_path):
    print("\nFULL EVENTS VALIDATION")

    total_rows = 0
    event_counts = pd.Series(dtype="int64")
    missing_core = 0
    invalid_times = 0
    purchase_without_id = 0
    non_purchase_with_id = 0
    unexpected_events = 0
    earliest = None
    latest = None

    for chunk in pd.read_csv(
        events_path,
        chunksize=100_000,
        dtype={"transactionid": "Int64"},
    ):
        total_rows += len(chunk)

        event_counts = event_counts.add(
            chunk["event"].value_counts(dropna=False),
            fill_value=0,
        )

        missing_core += int(
            chunk[["timestamp", "visitorid", "event", "itemid"]]
            .isna()
            .any(axis=1)
            .sum()
        )

        times = pd.to_datetime(
            chunk["timestamp"],
            unit="ms",
            utc=True,
            errors="coerce",
        )
        invalid_times += int(times.isna().sum())

        valid_times = times.dropna()
        if not valid_times.empty:
            chunk_min = valid_times.min()
            chunk_max = valid_times.max()
            earliest = (
                chunk_min if earliest is None else min(earliest, chunk_min)
            )
            latest = (
                chunk_max if latest is None else max(latest, chunk_max)
            )

        purchase = chunk["event"].eq("transaction").fillna(False)

        purchase_without_id += int(
            (purchase & chunk["transactionid"].isna()).sum()
        )
        non_purchase_with_id += int(
            (~purchase & chunk["transactionid"].notna()).sum()
        )
        unexpected_events += int(
            (~chunk["event"].isin(ALLOWED_EVENTS)).sum()
        )

    print("Total rows:", total_rows)
    print("\nEvent counts:")
    print(event_counts.astype("int64"))
    print("\nRows missing core fields:", missing_core)
    print("Invalid timestamps:", invalid_times)
    print("Purchase events without ID:", purchase_without_id)
    print("Non-purchase events with ID:", non_purchase_with_id)
    print("Unexpected events:", unexpected_events)
    print("Full time range:", earliest, "to", latest)

    print(
        "\nNote: Full-dataset duplicate detection is not included. "
        "Raw data has not been modified."
    )


def main():
    files = sorted(RAW_DIR.rglob("*.csv"))

    if not files:
        raise FileNotFoundError(f"No CSV files found in {RAW_DIR}")

    print("DOWNLOADED FILES")
    for path in files:
        size_mb = path.stat().st_size / (1024 ** 2)
        print(f"{path.name}: {size_mb:.2f} MB")

    matches = [path for path in files if path.name == "events.csv"]
    if len(matches) != 1:
        raise ValueError(
            f"Expected exactly one events.csv, found {len(matches)}"
        )

    events_path = matches[0]

    columns = set(pd.read_csv(events_path, nrows=0).columns)
    missing = REQUIRED_COLUMNS - columns
    if missing:
        raise ValueError(f"Missing required columns: {sorted(missing)}")

    inspect_sample(events_path)
    validate_full_events(events_path)


if __name__ == "__main__":
    main()