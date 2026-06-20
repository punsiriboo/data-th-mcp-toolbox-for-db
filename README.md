# MCP Toolbox DB — LiteLLM Sample Database
![MCP Toolbox DB — LiteLLM Sample Database](images/title.png)

โปรเจกต์ตัวอย่าง SQLite สำหรับใช้กับ [MCP Toolbox for Databases](https://mcp-toolbox.dev/) มีข้อมูลลูกค้า สินค้า คำสั่งซื้อ และยอดขาย เพื่อให้ AI assistant (เช่น Cursor, Claude) query ข้อมูลผ่าน MCP ได้

## โครงสร้างโปรเจกต์

```
mcp-toolbox-db/
├── db/
│   ├── sales_orders.db     # SQLite (สร้างจาก db/init_db.sh)
│   ├── schema.sql
│   ├── seed.sql
│   └── init_db.sh
├── tools.yaml              # Custom MCP tools
├── tools-custom.yaml       # Custom tools ชุดเต็ม
├── mcp-prebuilt.json       # MCP config — prebuilt
├── mcp-combined.json       # MCP config — prebuilt + custom
├── start-prebuilt.sh       # รัน HTTP server
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

## ความต้องการของระบบ

- [SQLite](https://www.sqlite.org/) (`sqlite3` CLI) — มีอยู่แล้วบน macOS ส่วนใหญ่
- [MCP Toolbox](https://mcp-toolbox.dev/) เวอร์ชัน **1.4.0+** (แนะนำ 1.5.0)

---

## ขั้นตอนที่ 1: สร้างฐานข้อมูล

```bash
cd mcp-toolbox-db
./db/init_db.sh
```

สคริปต์จะสร้างไฟล์ `db/sales_orders.db` พร้อมข้อมูลตัวอย่าง:

- ลูกค้า 5 ราย
- สินค้า 8 รายการ
- คำสั่งซื้อ 19 รายการ
- ยอดขาย 51 รายการ (พ.ย. 2024 – มิ.ย. 2025)

ตรวจสอบว่าสร้างสำเร็จ:

```bash
sqlite3 db/sales_orders.db ".tables"
sqlite3 db/sales_orders.db "SELECT COUNT(*) FROM sales;"
```

---

## ขั้นตอนที่ 2: ติดตั้ง MCP Toolbox

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

## ขั้นตอนที่ 3: เริ่ม MCP Toolbox

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

### แบบ 2: Custom tools (`tools.yaml`)

ใช้ tools ที่กำหนดเอง เช่น `list-customers`, `sales-summary-by-month`

```bash
toolbox --config ./tools.yaml
# หรือรัน `toolbox` ในโฟลเดอร์โปรเจกต์ (โหลด tools.yaml อัตโนมัติ)
```

### แบบ 3: Prebuilt + Custom รวมกัน (toolbox 1.4.0+)

ได้ทั้ง `list_tables` / `execute_sql` และ custom tools พร้อมกัน:

```bash
SQLITE_DATABASE=./db/sales_orders.db toolbox --stdio --prebuilt sqlite --config ./tools.yaml
# หรือ
./start-combined.sh
```

---

## ขั้นตอนที่ 4: ตั้งค่า Cursor

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

## ขั้นตอนที่ 5: ตั้งค่า LiteLLM (ถ้าใช้)

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

ใช้ `mcp-prebuilt.json` (prebuilt) หรือ `mcp-combined.json` (prebuilt + custom):

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

## แก้ไขปัญหา

| ปัญหา | วิธีแก้ |
|-------|--------|
| MCP server ไม่ active | ตรวจว่า `toolbox` อยู่ใน PATH (`which toolbox`) หรือใช้ path เต็มใน `mcp.json` |
| ไม่พบ `db/sales_orders.db` | รัน `./db/init_db.sh` ก่อน |
| `permission denied` | รัน `chmod +x db/init_db.sh start-prebuilt.sh` |
| Custom tools ไม่ทำงาน | อัปเกรด: `brew upgrade mcp-toolbox` แล้วใช้ `--config` (ไม่ใช่ `--tools-file`) |
| Prebuilt ไม่เจอ database | ตั้ง `SQLITE_DATABASE=./db/sales_orders.db` ก่อนรัน หรือใช้ `./start-prebuilt.sh` |
| เข้า `/ui` แล้วได้ 403 | port 5000 บน macOS ถูก AirPlay ใช้ — รัน `PORT=8080 ./start-prebuilt.sh --ui` หรือปิด AirPlay Receiver |
| UI ไม่ขึ้น | ต้องใส่ flag `--ui` ตอน start server |
| Tool ไม่ขึ้นใน Cursor | Reload window, ทดสอบด้วย `SQLITE_DATABASE=./db/sales_orders.db toolbox --stdio --prebuilt sqlite` |
| ต้องการข้อมูลใหม่ | แก้ `db/seed.sql` แล้วรัน `./db/init_db.sh` อีกครั้ง |

---

## อ้างอิง

- [MCP Toolbox for Databases](https://mcp-toolbox.dev/)
- [Prebuilt Configs](https://mcp-toolbox.dev/documentation/configuration/prebuilt-configs/)
- [SQLite + MCP Guide](https://mcp-toolbox.dev/dev/documentation/connect-to/ides/sqlite_mcp/)
- [Configuration (tools.yaml)](https://mcp-toolbox.dev/documentation/configuration/)
- [LiteLLM MCP](https://docs.litellm.ai/docs/mcp)
