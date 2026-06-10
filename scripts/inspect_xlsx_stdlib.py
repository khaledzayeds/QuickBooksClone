from __future__ import annotations

import json
import sys
import zipfile
import xml.etree.ElementTree as ET
from pathlib import Path

NS = {
    "main": "http://schemas.openxmlformats.org/spreadsheetml/2006/main",
    "rel": "http://schemas.openxmlformats.org/officeDocument/2006/relationships",
    "pkgrel": "http://schemas.openxmlformats.org/package/2006/relationships",
}


def _text(node: ET.Element | None) -> str:
    if node is None:
        return ""
    return "".join(node.itertext())


def _col_index(cell_ref: str) -> int:
    letters = "".join(ch for ch in cell_ref if ch.isalpha())
    value = 0
    for ch in letters:
        value = value * 26 + (ord(ch.upper()) - 64)
    return value - 1


def read_workbook(path: Path) -> list[dict[str, object]]:
    with zipfile.ZipFile(path) as zf:
        shared: list[str] = []
        if "xl/sharedStrings.xml" in zf.namelist():
            root = ET.fromstring(zf.read("xl/sharedStrings.xml"))
            for si in root.findall("main:si", NS):
                shared.append(_text(si))

        workbook = ET.fromstring(zf.read("xl/workbook.xml"))
        rels = ET.fromstring(zf.read("xl/_rels/workbook.xml.rels"))
        rel_map = {
            rel.attrib["Id"]: rel.attrib["Target"]
            for rel in rels.findall("pkgrel:Relationship", NS)
        }

        sheets: list[dict[str, object]] = []
        for sheet in workbook.findall("main:sheets/main:sheet", NS):
            name = sheet.attrib["name"]
            rel_id = sheet.attrib[f"{{{NS['rel']}}}id"]
            target = rel_map[rel_id].replace("\\", "/")
            sheet_path = "xl/" + target.lstrip("/")
            if sheet_path not in zf.namelist():
                sheet_path = "xl/worksheets/" + Path(target).name
            ws = ET.fromstring(zf.read(sheet_path))
            rows: list[list[object]] = []
            for row in ws.findall("main:sheetData/main:row", NS):
                values: list[object] = []
                for cell in row.findall("main:c", NS):
                    idx = _col_index(cell.attrib.get("r", "A1"))
                    while len(values) <= idx:
                        values.append("")
                    raw = cell.find("main:v", NS)
                    inline = cell.find("main:is", NS)
                    cell_type = cell.attrib.get("t")
                    if cell_type == "s" and raw is not None:
                        val: object = shared[int(raw.text or 0)]
                    elif cell_type == "inlineStr":
                        val = _text(inline)
                    elif raw is not None:
                        text = raw.text or ""
                        try:
                            val = int(text) if "." not in text else float(text)
                        except ValueError:
                            val = text
                    else:
                        val = ""
                    values[idx] = val
                rows.append(values)
            sheets.append({"name": name, "rows": rows})
        return sheets


def main() -> None:
    path = Path(sys.argv[1])
    sheets = read_workbook(path)
    print(json.dumps(
        [
            {
                "name": sheet["name"],
                "row_count": len(sheet["rows"]),
                "col_count": max((len(r) for r in sheet["rows"]), default=0),
                "sample": sheet["rows"][:10],
            }
            for sheet in sheets
        ],
        ensure_ascii=False,
        default=str,
    ))


if __name__ == "__main__":
    main()
