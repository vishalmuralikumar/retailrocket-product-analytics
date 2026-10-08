import pandas as pd
import streamlit as st

from scripts.ai_query import execute_query
from scripts.test_cortex_analyst import ask_analyst


st.set_page_config(
    page_title="Retailrocket AI Analytics",
    page_icon="📊",
    layout="wide",
)


def display_results(dataframe):
    if dataframe.empty:
        st.info("No results found.")
        return

    if len(dataframe) == 1:
        st.markdown("### Answer")

        for column in dataframe.columns:
            value = dataframe.iloc[0][column]
            label = column.replace("_", " ").title()

            if pd.isna(value):
                st.write(f"**{label}:** unavailable")
            elif column.upper() == "SESSION_PURCHASE_RATE":
                rate = float(value)
                st.metric(label, f"{rate:.4%}")
                st.write(
                    f"Approximately {rate * 100:.4f}% of sessions "
                    "included a purchase."
                )
            elif column.upper() in {
                "TOTAL_SESSIONS",
                "PURCHASING_SESSIONS",
                "ACTIVE_VISITORS",
            }:
                st.metric(label, f"{int(value):,}")
            else:
                st.write(f"**{label}:** {value}")

    else:
        st.markdown("### Results")

    display_df = dataframe.copy()

    for column in display_df.columns:
        if column.upper() == "SESSION_PURCHASE_RATE":
            display_df[column] = display_df[column].map(
                lambda value: (
                    f"{float(value):.4%}"
                    if pd.notna(value)
                    else None
                )
            )

    st.dataframe(display_df, hide_index=True,width=True)


def render_message(message):
    for block in message["content"]:
        block_type = block.get("type")

        if block_type == "text":
            st.markdown(block["text"])

        elif block_type == "sql":
            st.markdown("**Generated SQL**")
            st.code(block["statement"], language="sql")

        elif block_type == "suggestions":
            st.markdown("**Suggested questions**")
            for suggestion in block["suggestions"]:
                st.write(f"• {suggestion}")

    if "dataframe" in message:
        display_results(message["dataframe"])

    if message.get("truncated"):
        st.caption("Showing the first 500 rows.")

    if message.get("error"):
        st.error(message["error"])

    if message.get("query_id"):
        st.caption(f"Snowflake query ID: {message['query_id']}")

    if message.get("request_id"):
        st.caption(f"Cortex request ID: {message['request_id']}")


def main():
    st.title("Retailrocket AI Analytics")
    st.caption("Ask a question and see the SQL and actual Snowflake results.")

    if "messages" not in st.session_state:
        st.session_state.messages = []

    with st.sidebar:
        st.header("Example questions")
        st.markdown(
            """
            - What is the overall session purchase rate?
            - How many sessions are there in total?
            - How many sessions included a purchase?
            - How many active visitors are there overall?
            - Show total sessions by month.
            """
        )
        st.caption(
            "Historical data: May–September 2015. "
            "This version supports overall metrics and simple grouping."
        )

        if st.button("Clear conversation"):
            st.session_state.messages = []
            st.rerun()

    for message in st.session_state.messages:
        with st.chat_message(message["role"]):
            render_message(message)

    question = st.chat_input("Ask about session analytics")

    if not question:
        return

    if len(question) > 2000:
        st.warning("Please keep your question under 2,000 characters.")
        return

    user_message = {
        "role": "user",
        "content": [{"type": "text", "text": question}],
    }
    st.session_state.messages.append(user_message)

    with st.chat_message("user"):
        render_message(user_message)

    with st.chat_message("assistant"):
        assistant_message = {
            "role": "assistant",
            "content": [],
        }

        try:
            with st.spinner("Generating SQL…"):
                result = ask_analyst(question)

            content = result.get("message", {}).get("content", [])
            if not content:
                raise ValueError("Cortex Analyst returned an empty response.")

            assistant_message["content"] = content
            assistant_message["request_id"] = result.get("request_id")

            sql_blocks = [
                block for block in content
                if block.get("type") == "sql"
            ]

            if len(sql_blocks) > 1:
                raise ValueError("Multiple SQL queries are not supported.")

            if sql_blocks:
                with st.spinner("Querying Snowflake…"):
                    dataframe, query_id, truncated = execute_query(
                        sql_blocks[0]["statement"]
                    )

                assistant_message["dataframe"] = dataframe
                assistant_message["query_id"] = query_id
                assistant_message["truncated"] = truncated

        except Exception as error:
            assistant_message["error"] = str(error)

        render_message(assistant_message)
        st.session_state.messages.append(assistant_message)


if __name__ == "__main__":
    main()