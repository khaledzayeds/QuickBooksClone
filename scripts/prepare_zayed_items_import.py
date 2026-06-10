from __future__ import annotations

import json
import re
import sys
import zipfile
import xml.etree.ElementTree as ET
from datetime import datetime, timezone
from pathlib import Path
from typing import Any

from inspect_xlsx_stdlib import read_workbook

HEADERS = [
    "Name",
    "Type",
    "Barcode",
    "Unit",
    "Sales Price",
    "Purchase Cost",
    "Qty on Hand",
    "Part No. (optional)",
    "Income Account",
    "Inventory Asset Account",
    "COGS Account",
    "Expense Account",
    "Active",
]

ORIGINAL_HEADERS = [
    "Barcode",
    "Name",
    "Category",
    "Quantity",
    "Purchase Cost",
    "Sales Price",
    "Wholesale Price",
    "Unit",
    "Minimum Qty",
    "Notes",
    "Inventory Value",
]


def clean_text(value: Any) -> str:
    text = "" if value is None else str(value)
    text = text.replace("\u200f", "").replace("\u200e", "")
    return re.sub(r"\s+", " ", text).strip()


def number(value: Any) -> float:
    if value is None or value == "":
        return 0.0
    if isinstance(value, (int, float)):
        return float(value)
    text = clean_text(value).replace(",", "")
    try:
        return float(text)
    except ValueError:
        return 0.0


def money(value: Any) -> str:
    amount = number(value)
    return f"{amount:.2f}"


def qty(value: Any) -> str:
    amount = number(value)
    return str(int(amount)) if amount.is_integer() else f"{amount:.2f}"


def normalize_unit(value: Any) -> str:
    unit = clean_text(value)
    return unit or "قطعة"


def dedupe_name(name: str, seen: dict[str, int]) -> str:
    base = name or "منتج بدون اسم"
    key = base.casefold()
    seen[key] = seen.get(key, 0) + 1
    if seen[key] == 1:
        return base
    return f"{base} ({seen[key]})"


def rows_from_source(path: Path) -> tuple[list[list[Any]], list[list[Any]], dict[str, Any]]:
    sheets = read_workbook(path)
    if not sheets:
        raise ValueError("Workbook has no sheets.")
    source_rows = sheets[0]["rows"]
    if len(source_rows) < 2:
        raise ValueError("Workbook has no item rows.")

    seen: dict[str, int] = {}
    items: list[list[Any]] = []
    original: list[list[Any]] = []
    skipped_blank = 0
    for raw in source_rows[1:]:
        row = list(raw) + [""] * (11 - len(raw))
        barcode, name, category, quantity, purchase, sales, wholesale, unit, minimum, notes, value = row[:11]
        item_name = clean_text(name)
        if not item_name:
            skipped_blank += 1
            continue
        item_name = dedupe_name(item_name, seen)
        barcode_text = clean_text(barcode)
        category_text = clean_text(category)
        notes_text = clean_text(notes)
        part_no = ""
        if category_text:
            notes_text = f"Category: {category_text}" + (f" | {notes_text}" if notes_text else "")

        items.append(
            [
                item_name,
                "Inventory Part",
                barcode_text,
                normalize_unit(unit),
                money(sales),
                money(purchase),
                qty(quantity),
                part_no,
                "Sales Income",
                "Inventory Asset",
                "Cost of Goods Sold",
                "",
                "Yes",
            ]
        )
        original.append(
            [
                barcode_text,
                item_name,
                category_text,
                number(quantity),
                number(purchase),
                number(sales),
                number(wholesale),
                normalize_unit(unit),
                number(minimum),
                notes_text,
                number(value),
            ]
        )

    summary = {
        "source_sheet": sheets[0]["name"],
        "source_rows": len(source_rows) - 1,
        "items_ready": len(items),
        "skipped_blank": skipped_blank,
        "total_quantity": sum(number(r[6]) for r in items),
        "total_inventory_value": sum(number(r[3]) * number(r[4]) for r in original),
        "categories": sorted({r[2] for r in original if r[2]}),
    }
    return items, original, summary


def col_name(index: int) -> str:
    name = ""
    index += 1
    while index:
        index, rem = divmod(index - 1, 26)
        name = chr(65 + rem) + name
    return name


def cell_xml(row_idx: int, col_idx: int, value: Any, style: int = 0) -> str:
    ref = f"{col_name(col_idx)}{row_idx}"
    style_attr = f' s="{style}"' if style else ""
    if isinstance(value, (int, float)) and not isinstance(value, bool):
        return f'<c r="{ref}"{style_attr}><v>{value}</v></c>'
    text = clean_text(value)
    escaped = (
        text.replace("&", "&amp;")
        .replace("<", "&lt;")
        .replace(">", "&gt;")
        .replace('"', "&quot;")
    )
    return f'<c r="{ref}" t="inlineStr"{style_attr}><is><t>{escaped}</t></is></c>'


def sheet_xml(rows: list[list[Any]], header_style: int = 1) -> str:
    lines = [
        '<?xml version="1.0" encoding="UTF-8" standalone="yes"?>',
        '<worksheet xmlns="http://schemas.openxmlformats.org/spreadsheetml/2006/main" '
        'xmlns:r="http://schemas.openxmlformats.org/officeDocument/2006/relationships">',
        '<sheetViews><sheetView workbookViewId="0"><pane ySplit="1" topLeftCell="A2" activePane="bottomLeft" state="frozen"/></sheetView></sheetViews>',
        '<sheetData>',
    ]
    for r_idx, row in enumerate(rows, start=1):
        lines.append(f'<row r="{r_idx}">')
        for c_idx, value in enumerate(row):
            lines.append(cell_xml(r_idx, c_idx, value, header_style if r_idx == 1 else 0))
        lines.append("</row>")
    lines.extend(["</sheetData>", "</worksheet>"])
    return "".join(lines)


def workbook_xml(sheet_names: list[str]) -> str:
    sheets = "".join(
        f'<sheet name="{name}" sheetId="{i + 1}" r:id="rId{i + 1}"/>'
        for i, name in enumerate(sheet_names)
    )
    return (
        '<?xml version="1.0" encoding="UTF-8" standalone="yes"?>'
        '<workbook xmlns="http://schemas.openxmlformats.org/spreadsheetml/2006/main" '
        'xmlns:r="http://schemas.openxmlformats.org/officeDocument/2006/relationships">'
        f"<sheets>{sheets}</sheets></workbook>"
    )


def workbook_rels(sheet_count: int) -> str:
    rels = [
        '<?xml version="1.0" encoding="UTF-8" standalone="yes"?>',
        '<Relationships xmlns="http://schemas.openxmlformats.org/package/2006/relationships">',
    ]
    for i in range(sheet_count):
        rels.append(
            f'<Relationship Id="rId{i + 1}" '
            'Type="http://schemas.openxmlformats.org/officeDocument/2006/relationships/worksheet" '
            f'Target="worksheets/sheet{i + 1}.xml"/>'
        )
    rels.append(
        f'<Relationship Id="rId{sheet_count + 1}" '
        'Type="http://schemas.openxmlformats.org/officeDocument/2006/relationships/styles" '
        'Target="styles.xml"/>'
    )
    rels.append("</Relationships>")
    return "".join(rels)


def content_types(sheet_count: int) -> str:
    overrides = "".join(
        f'<Override PartName="/xl/worksheets/sheet{i + 1}.xml" '
        'ContentType="application/vnd.openxmlformats-officedocument.spreadsheetml.worksheet+xml"/>'
        for i in range(sheet_count)
    )
    return (
        '<?xml version="1.0" encoding="UTF-8" standalone="yes"?>'
        '<Types xmlns="http://schemas.openxmlformats.org/package/2006/content-types">'
        '<Default Extension="rels" ContentType="application/vnd.openxmlformats-package.relationships+xml"/>'
        '<Default Extension="xml" ContentType="application/xml"/>'
        '<Override PartName="/xl/workbook.xml" ContentType="application/vnd.openxmlformats-officedocument.spreadsheetml.sheet.main+xml"/>'
        '<Override PartName="/xl/styles.xml" ContentType="application/vnd.openxmlformats-officedocument.spreadsheetml.styles+xml"/>'
        f"{overrides}</Types>"
    )


def styles_xml() -> str:
    return (
        '<?xml version="1.0" encoding="UTF-8" standalone="yes"?>'
        '<styleSheet xmlns="http://schemas.openxmlformats.org/spreadsheetml/2006/main">'
        '<fonts count="2"><font><sz val="11"/><name val="Calibri"/></font>'
        '<font><b/><color rgb="FFFFFFFF"/><sz val="11"/><name val="Calibri"/></font></fonts>'
        '<fills count="3"><fill><patternFill patternType="none"/></fill><fill><patternFill patternType="gray125"/></fill>'
        '<fill><patternFill patternType="solid"><fgColor rgb="FF1F7A1F"/><bgColor indexed="64"/></patternFill></fill></fills>'
        '<borders count="1"><border><left/><right/><top/><bottom/><diagonal/></border></borders>'
        '<cellStyleXfs count="1"><xf numFmtId="0" fontId="0" fillId="0" borderId="0"/></cellStyleXfs>'
        '<cellXfs count="2"><xf numFmtId="0" fontId="0" fillId="0" borderId="0" xfId="0"/>'
        '<xf numFmtId="0" fontId="1" fillId="2" borderId="0" xfId="0" applyFont="1" applyFill="1"/></cellXfs>'
        '<cellStyles count="1"><cellStyle name="Normal" xfId="0" builtinId="0"/></cellStyles>'
        '</styleSheet>'
    )


def root_rels() -> str:
    return (
        '<?xml version="1.0" encoding="UTF-8" standalone="yes"?>'
        '<Relationships xmlns="http://schemas.openxmlformats.org/package/2006/relationships">'
        '<Relationship Id="rId1" Type="http://schemas.openxmlformats.org/officeDocument/2006/relationships/officeDocument" Target="xl/workbook.xml"/>'
        '</Relationships>'
    )


def write_xlsx(path: Path, sheets: dict[str, list[list[Any]]]) -> None:
    names = list(sheets)
    with zipfile.ZipFile(path, "w", compression=zipfile.ZIP_DEFLATED) as zf:
        zf.writestr("[Content_Types].xml", content_types(len(names)))
        zf.writestr("_rels/.rels", root_rels())
        zf.writestr("xl/workbook.xml", workbook_xml(names))
        zf.writestr("xl/_rels/workbook.xml.rels", workbook_rels(len(names)))
        zf.writestr("xl/styles.xml", styles_xml())
        for i, name in enumerate(names, start=1):
            zf.writestr(f"xl/worksheets/sheet{i}.xml", sheet_xml(sheets[name]))


def main() -> None:
    src = Path(sys.argv[1])
    out = Path(sys.argv[2])
    items, original, summary = rows_from_source(src)
    generated_at = datetime.now(timezone.utc).strftime("%Y-%m-%d %H:%M UTC")
    summary_rows = [
        ["Metric", "Value"],
        ["Generated at", generated_at],
        ["Source file", str(src)],
        ["Source sheet", summary["source_sheet"]],
        ["Source data rows", summary["source_rows"]],
        ["Import-ready rows", summary["items_ready"]],
        ["Skipped blank-name rows", summary["skipped_blank"]],
        ["Total quantity", summary["total_quantity"]],
        ["Total inventory value", round(summary["total_inventory_value"], 2)],
        ["Categories preserved in Original Data", ", ".join(summary["categories"])],
    ]
    sheets = {
        "Items": [HEADERS, *items],
        "Original Data": [ORIGINAL_HEADERS, *original],
        "Summary": summary_rows,
    }
    out.parent.mkdir(parents=True, exist_ok=True)
    write_xlsx(out, sheets)
    print(json.dumps({"output": str(out), **summary}, ensure_ascii=False, default=str))


if __name__ == "__main__":
    main()
