# MCP Toolbox DB — LiteLLM Sample Database
![MCP Toolbox DB — LiteLLM Sample Database](images/title.png)

โปรเจกต์ตัวอย่าง SQLite สำหรับใช้กับ [MCP Toolbox for Databases](https://mcp-toolbox.dev/) มีข้อมูลลูกค้า สินค้า คำสั่งซื้อ และยอดขาย เพื่อให้ AI assistant (เช่น Cursor, Claude) query ข้อมูลผ่าน MCP ได้

## โครงสร้างโปรเจกต์

```
mcp-toolbox-db/
├── db/
│   ├── sales_orders.db     # SQLite พร้อมข้อมูลตัวอย่าง
│   └── schema.sql
├── agent/                  # Google ADK agent (stdio MCP)
│   ├── agent.py
│   └── requirements.txt
├── mcp-prebuilt.json       # MCP config — prebuilt
├── mcp-custom.json         # MCP config — custom tools
├── start-prebuilt.sh       # รัน HTTP server (prebuilt)
├── start-custom.sh         # รัน HTTP server (custom tools)
└── README.md
```

## ตารางในฐานข้อมูล

| ตาราง | รายละเอียด |
|-------|-----------|
| `customers` | ข้อมูลลูกค้า (ชื่อ, อีเมล, ที่อยู่) |
| `products` | สินค้า (ราคา, หมวดหมู่, สต็อก) |
| `orders` | คำสั่งซื้อ (เชื่อมกับ `customers`) |
| `sales` | รายการขายแต่ละบรรทัด (เชื่อมกับ `orders` และ `products`, มี `sales_date`) |

ความสัมพันธ์: `customers` → `orders` → `sales` ← `products`

ข้อมูลตัวอย่างใน `db/sales_orders.db`:

- ลูกค้า 5 ราย
- สินค้า 8 รายการ
- คำสั่งซื้อ 19 รายการ
- ยอดขาย 51 รายการ (พ.ย. 2024 – มิ.ย. 2025)

## ความต้องการของระบบ

- [SQLite](https://www.sqlite.org/) (`sqlite3` CLI) — มีอยู่แล้วบน macOS ส่วนใหญ่
- [MCP Toolbox](https://mcp-toolbox.dev/) เวอร์ชัน **1.4.0+** (แนะนำ 1.5.0)
- Python 3.10+ (สำหรับ ADK agent)
- [Google AI API key](https://aistudio.google.com/apikey) (สำหรับ ADK agent)

---

## ขั้นตอนที่ 1: ติดตั้ง MCP Toolbox

คู่มือติดตั้งและรัน Toolbox server: [Install & Run the Toolbox Server](https://github.com/googleapis/mcp-toolbox#install--run-the-toolbox-server)

เลือกวิธีใดวิธีหนึ่ง:

### วิธี A: Homebrew (แนะนำบน macOS)

```bash
brew update
brew upgrade mcp-toolbox
toolbox --version   # ควรได้ 1.5.0 ขึ้นไป
```

### วิธี B: ดาวน์โหลด binary ไว้ในโปรเจกต์

**Apple Silicon (M1/M2/M3):**

```bash
export VERSION=1.5.0
curl -L -o toolbox "https://storage.googleapis.com/mcp-toolbox-for-databases/v${VERSION}/darwin/arm64/toolbox"
chmod +x toolbox
./toolbox --version
```

**Intel Mac:**

```bash
export VERSION=1.5.0
curl -L -o toolbox "https://storage.googleapis.com/mcp-toolbox-for-databases/v${VERSION}/darwin/amd64/toolbox"
chmod +x toolbox
./toolbox --version
```

> ดูเวอร์ชันล่าสุดได้ที่ [GitHub Releases](https://github.com/googleapis/mcp-toolbox/releases)

---

## ขั้นตอนที่ 2: เริ่ม MCP Toolbox

เลือกได้ 3 แบบ:

### แบบ 1: Prebuilt (ง่ายที่สุด — แนะนำเริ่มต้น)

ใช้ tools มาตรฐานของ MCP Toolbox ไม่ต้องพึ่ง `tools.yaml`:

| Tool | คำอธิบาย |
|------|----------|
| `list_tables` | แสดงตารางทั้งหมดในฐานข้อมูล |
| `execute_sql` | รัน SQL ใดก็ได้ (SELECT, INSERT, ...) |

**stdio (Cursor / Claude):**

```bash
SQLITE_DATABASE=./db/sales_orders.db toolbox --stdio --prebuilt sqlite
```

**HTTP server:**

```bash
./start-prebuilt.sh       # http://127.0.0.1:5000
./start-prebuilt.sh --ui  # + UI at /ui
```

### แบบ 2: Custom tools (`db/tools.yaml`)

ใช้ tools ที่กำหนดเอง เช่น `list-customers`, `sales-summary-by-month`

**stdio (Cursor / Claude):**

```bash
toolbox --stdio --config ./db/tools.yaml
```

**HTTP server:**

```bash
./start-custom.sh       # http://127.0.0.1:5000
./start-custom.sh --ui  # + UI at /ui
```

### แบบ 3: Prebuilt + Custom รวมกัน (toolbox 1.4.0+)

ได้ทั้ง `list_tables` / `execute_sql` และ custom tools พร้อมกัน:

```bash
SQLITE_DATABASE=./db/sales_orders.db toolbox --stdio --prebuilt sqlite --config ./tools.yaml
# หรือ
./start-combined.sh
```

---

## ขั้นตอนที่ 3: ตั้งค่า Cursor

โปรเจกต์มี MCP config หลายแบบให้เลือก:

### ตัวเลือก A: Prebuilt + Custom (`.cursor/mcp.json` — default)

```json
{
  "mcpServers": {
    "litellm-db-prebuilt": {
      "command": "toolbox",
      "args": ["--stdio", "--prebuilt", "sqlite"],
      "env": { "SQLITE_DATABASE": "./db/sales_orders.db" },
      "cwd": "${workspaceFolder}"
    },
    "litellm-db-custom": {
      "command": "toolbox",
      "args": ["--stdio", "--config", "./tools.yaml"],
      "cwd": "${workspaceFolder}"
    }
  }
}
```

- `litellm-db-prebuilt` — ใช้ได้ทันที (`list_tables`, `execute_sql`)
- `litellm-db-custom` — custom tools จาก `tools.yaml`

### ตัวเลือก B: Prebuilt เท่านั้น (`.cursor/mcp-prebuilt.json`)

คัดลอกเนื้อหาไปแทนที่ `.cursor/mcp.json` หรือใช้ไฟล์ `mcp-prebuilt.json` ที่ root:

```json
{
  "mcpServers": {
    "litellm-db-prebuilt": {
      "command": "toolbox",
      "args": ["--stdio", "--prebuilt", "sqlite"],
      "env": { "SQLITE_DATABASE": "./db/sales_orders.db" }
    }
  }
}
```

### ตัวเลือก C: รวมใน server เดียว (`mcp-combined.json` — toolbox 1.4.0+)

```json
{
  "mcpServers": {
    "litellm-db": {
      "command": "toolbox",
      "args": ["--stdio", "--prebuilt", "sqlite", "--config", "./tools.yaml"],
      "env": { "SQLITE_DATABASE": "./db/sales_orders.db" }
    }
  }
}
```

**เปิดใช้งานใน Cursor:**

1. เปิดโฟลเดอร์ `mcp-toolbox-db` ใน Cursor
2. ไปที่ **Settings → Cursor Settings → MCP**
3. ตรวจว่า server แสดงสถานะ **สีเขียว (active)**
4. ถ้ายังไม่ขึ้น ให้ reload window หรือ restart Cursor

---

## ขั้นตอนที่ 4: ตั้งค่า LiteLLM (ถ้าใช้)

1. เปิด `store_model_in_db` ใน LiteLLM config:

```yaml
general_settings:
  store_model_in_db: true
```

2. รัน MCP Toolbox เป็น HTTP server:

```bash
./start-prebuilt.sh          # prebuilt เท่านั้น
# หรือ
./start-combined.sh          # prebuilt + custom (1.4.0+)
```

3. ใน LiteLLM UI ไปที่ **MCP Servers → Add New MCP Server**
4. ใส่ URL ของ Toolbox เช่น `http://127.0.0.1:5000/mcp`

อ่านเพิ่มเติม: [LiteLLM MCP Documentation](https://docs.litellm.ai/docs/mcp)

---

## ขั้นตอนที่ 5: รัน Agent ด้วย ADK Web

Agent ในโฟลเดอร์ `agent/` ใช้ [Google ADK](https://google.github.io/adk-docs/) เชื่อมต่อฐานข้อมูลผ่าน MCP Toolbox แบบ stdio — **ไม่ต้องรัน** `./start-prebuilt.sh` ก่อน

```bash
cd mcp-toolbox-db
python3 -m venv agent/.venv
source agent/.venv/bin/activate
pip install -r agent/requirements.txt

cp agent/.env.example agent/.env
# แก้ agent/.env ใส่ GOOGLE_API_KEY

adk web .
```

เปิดเบราว์เซอร์ที่ **http://127.0.0.1:8000** แล้วเลือก agent `agent` เพื่อถามข้อมูล เช่น "แสดงยอดขายเดือนมีนาคม 2025"

> ต้องติดตั้ง `toolbox` ใน PATH แล้ว (ขั้นตอนที่ 1) — agent จะ spawn `toolbox --stdio --prebuilt sqlite` ให้อัตโนมัติ

---

## MCP Tools ที่พร้อมใช้

### Prebuilt tools (`--prebuilt sqlite`)

| Tool | คำอธิบาย |
|------|----------|
| `list_tables` | แสดงตารางทั้งหมดในฐานข้อมูล |
| `execute_sql` | รัน SQL กับฐานข้อมูลโดยตรง |

### Custom tools (`tools.yaml`)

| Tool | คำอธิบาย |
|------|----------|
| `list-customers` | แสดงรายชื่อลูกค้าทั้งหมด |
| `get-customer-by-id` | ดึงข้อมูลลูกค้าตาม ID |
| `list-products` | แสดงสินค้าทั้งหมด |
| `search-products-by-category` | ค้นหาสินค้าตามหมวดหมู่ |
| `list-orders` | แสดงคำสั่งซื้อพร้อมชื่อลูกค้า |
| `get-customer-orders` | ดึงคำสั่งซื้อของลูกค้า |
| `list-sales` | แสดงรายการขายทั้งหมด (เรียงตาม `sales_date`) |
| `get-order-sales` | ดึงรายการขายใน order |
| `sales-summary-by-product` | สรุปยอดขายและรายได้ต่อสินค้า |
| `get-sales-by-date-range` | ดึงยอดขายในช่วงวันที่ |
| `sales-summary-by-month` | สรุปยอดขายรายเดือน |
| `execute-sql` | รัน SQL กับฐานข้อมูลโดยตรง |

### ตัวอย่างคำถามที่ถาม AI ได้

- "แสดงยอดขายเดือนมีนาคม 2025"
- "ลูกค้า Somchai สั่งซื้ออะไรบ้าง?"
- "สินค้าไหนขายดีที่สุด?"
- "สรุปรายได้รายเดือนจากตาราง sales"

---

## ตั้งค่า MCP Client อื่น

### Claude Desktop / Claude Code

ใช้ `mcp-prebuilt.json` (prebuilt) หรือ `mcp-custom.json` (prebuilt + custom):

```json
{
  "mcpServers": {
    "litellm-db-prebuilt": {
      "command": "toolbox",
      "args": ["--stdio", "--prebuilt", "sqlite"],
      "env": { "SQLITE_DATABASE": "./db/sales_orders.db" }
    }
  }
}
```

### VS Code (Copilot)

```json
{
  "servers": {
    "litellm-db-prebuilt": {
      "command": "toolbox",
      "args": ["--stdio", "--prebuilt", "sqlite"],
      "env": { "SQLITE_DATABASE": "./db/sales_orders.db" }
    }
  }
}
```



---

## อ้างอิง

- [Install & Run the Toolbox Server](https://github.com/googleapis/mcp-toolbox#install--run-the-toolbox-server)
- [MCP Toolbox for Databases](https://mcp-toolbox.dev/)
- [Prebuilt Configs](https://mcp-toolbox.dev/documentation/configuration/prebuilt-configs/)
- [SQLite + MCP Guide](https://mcp-toolbox.dev/dev/documentation/connect-to/ides/sqlite_mcp/)
- [Configuration (tools.yaml)](https://mcp-toolbox.dev/documentation/configuration/)
- [LiteLLM MCP](https://docs.litellm.ai/docs/mcp)
- [Google ADK](https://google.github.io/adk-docs/)
