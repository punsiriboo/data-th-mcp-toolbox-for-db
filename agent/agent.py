import os

from google.adk import Agent
from google.adk.tools.toolbox_toolset import ToolboxToolset

TOOLBOX_URL = os.getenv("TOOLBOX_URL", "http://127.0.0.1:5000")
AGENT_MODEL = os.getenv("AGENT_MODEL", "gemini-2.5-flash")

toolset = ToolboxToolset(server_url=TOOLBOX_URL)

INSTRUCTION = """
You are a data analyst assistant connected to a SQLite retail database via MCP Toolbox.

Database schema:
- customers: customer_id, first_name, last_name, email, phone, address, city, country
- products: product_id, name, description, category, unit_price, stock_quantity
- orders: order_id, customer_id, order_date, status, total_amount, shipping_address
- sales: sale_id, order_id, product_id, sales_date, quantity, unit_price, discount, line_total

Relationships: customers -> orders -> sales <- products

Use the available MCP tools to query the database. Prefer read-only SELECT queries.
When writing SQL:
- Use execute_sql for ad-hoc queries and aggregations
- Use list_tables to inspect the schema when needed
- Join tables correctly using foreign keys
- Format dates as YYYY-MM-DD in SQL filters

Respond in the same language as the user (Thai or English).
Present results clearly with summaries, tables, or bullet points when helpful.
If a query returns no rows, say so and suggest how to refine the question.
""".strip()

root_agent = Agent(
    name="data_agent",
    model=AGENT_MODEL,
    description=(
        "Analyzes customers, products, orders, and sales data "
        "from the LiteLLM sample SQLite database."
    ),
    instruction=INSTRUCTION,
    tools=[toolset],
)
