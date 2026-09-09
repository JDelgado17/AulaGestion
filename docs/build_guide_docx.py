from pathlib import Path
import re

from docx import Document
from docx.enum.section import WD_SECTION
from docx.enum.table import WD_CELL_VERTICAL_ALIGNMENT, WD_TABLE_ALIGNMENT
from docx.enum.text import WD_ALIGN_PARAGRAPH, WD_BREAK, WD_LINE_SPACING
from docx.oxml import OxmlElement
from docx.oxml.ns import qn
from docx.shared import Inches, Pt, RGBColor


ROOT = Path(__file__).resolve().parents[1]
SOURCE = ROOT / "docs" / "GUIA_TECNICA_Y_USUARIO.md"
OUTPUT = ROOT / "docs" / "AulaGestion_Guia_Tecnica_y_Usuario.docx"

NAVY = "12365A"
BLUE = "1466B8"
TEAL = "00A8A8"
SKY = "E9F4FF"
LIGHT = "F4F7FA"
MID = "D7E1EC"
MUTED = "617184"
INK = "152536"
WHITE = "FFFFFF"


def set_font(run, name="Calibri", size=None, color=None, bold=None):
    run.font.name = name
    run._element.get_or_add_rPr().rFonts.set(qn("w:ascii"), name)
    run._element.get_or_add_rPr().rFonts.set(qn("w:hAnsi"), name)
    if size is not None:
        run.font.size = Pt(size)
    if color:
        run.font.color.rgb = RGBColor.from_string(color)
    if bold is not None:
        run.bold = bold


def shade(cell, fill):
    tc_pr = cell._tc.get_or_add_tcPr()
    shd = tc_pr.find(qn("w:shd"))
    if shd is None:
        shd = OxmlElement("w:shd")
        tc_pr.append(shd)
    shd.set(qn("w:fill"), fill)


def set_cell_margins(cell, top=80, start=120, bottom=80, end=120):
    tc = cell._tc
    tc_pr = tc.get_or_add_tcPr()
    tc_mar = tc_pr.first_child_found_in("w:tcMar")
    if tc_mar is None:
        tc_mar = OxmlElement("w:tcMar")
        tc_pr.append(tc_mar)
    for margin, value in (("top", top), ("start", start), ("bottom", bottom), ("end", end)):
        node = tc_mar.find(qn(f"w:{margin}"))
        if node is None:
            node = OxmlElement(f"w:{margin}")
            tc_mar.append(node)
        node.set(qn("w:w"), str(value))
        node.set(qn("w:type"), "dxa")


def set_cell_width(cell, dxa):
    tc_pr = cell._tc.get_or_add_tcPr()
    tc_w = tc_pr.find(qn("w:tcW"))
    if tc_w is None:
        tc_w = OxmlElement("w:tcW")
        tc_pr.append(tc_w)
    tc_w.set(qn("w:w"), str(dxa))
    tc_w.set(qn("w:type"), "dxa")


def set_table_geometry(table, widths):
    table.alignment = WD_TABLE_ALIGNMENT.LEFT
    table.autofit = False
    tbl_pr = table._tbl.tblPr
    tbl_w = tbl_pr.find(qn("w:tblW"))
    if tbl_w is None:
        tbl_w = OxmlElement("w:tblW")
        tbl_pr.append(tbl_w)
    tbl_w.set(qn("w:w"), str(sum(widths)))
    tbl_w.set(qn("w:type"), "dxa")
    tbl_ind = tbl_pr.find(qn("w:tblInd"))
    if tbl_ind is None:
        tbl_ind = OxmlElement("w:tblInd")
        tbl_pr.append(tbl_ind)
    tbl_ind.set(qn("w:w"), "120")
    tbl_ind.set(qn("w:type"), "dxa")
    layout = tbl_pr.find(qn("w:tblLayout"))
    if layout is None:
        layout = OxmlElement("w:tblLayout")
        tbl_pr.append(layout)
    layout.set(qn("w:type"), "fixed")
    grid = table._tbl.tblGrid
    for child in list(grid):
        grid.remove(child)
    for width in widths:
        col = OxmlElement("w:gridCol")
        col.set(qn("w:w"), str(width))
        grid.append(col)
    for row in table.rows:
        for index, cell in enumerate(row.cells):
            set_cell_width(cell, widths[index])
            set_cell_margins(cell)
            cell.vertical_alignment = WD_CELL_VERTICAL_ALIGNMENT.CENTER


def set_repeat_header(row):
    tr_pr = row._tr.get_or_add_trPr()
    tbl_header = OxmlElement("w:tblHeader")
    tbl_header.set(qn("w:val"), "true")
    tr_pr.append(tbl_header)


def add_page_number(paragraph):
    paragraph.alignment = WD_ALIGN_PARAGRAPH.RIGHT
    run = paragraph.add_run("Página ")
    set_font(run, size=9, color=MUTED)
    fld_char1 = OxmlElement("w:fldChar")
    fld_char1.set(qn("w:fldCharType"), "begin")
    instr = OxmlElement("w:instrText")
    instr.set(qn("xml:space"), "preserve")
    instr.text = " PAGE "
    fld_char2 = OxmlElement("w:fldChar")
    fld_char2.set(qn("w:fldCharType"), "end")
    run._r.extend([fld_char1, instr, fld_char2])


def create_numbering_instance(doc):
    numbering = doc.part.numbering_part.element
    current_ids = [int(node.get(qn("w:numId"))) for node in numbering.findall(qn("w:num"))]
    new_id = max(current_ids, default=0) + 1
    num = OxmlElement("w:num")
    num.set(qn("w:numId"), str(new_id))
    abstract = OxmlElement("w:abstractNumId")
    abstract.set(qn("w:val"), "7")
    num.append(abstract)
    override = OxmlElement("w:lvlOverride")
    override.set(qn("w:ilvl"), "0")
    start = OxmlElement("w:startOverride")
    start.set(qn("w:val"), "1")
    override.append(start)
    num.append(override)
    numbering.append(num)
    return new_id


def apply_numbering(paragraph, num_id):
    p_pr = paragraph._p.get_or_add_pPr()
    num_pr = OxmlElement("w:numPr")
    ilvl = OxmlElement("w:ilvl")
    ilvl.set(qn("w:val"), "0")
    num = OxmlElement("w:numId")
    num.set(qn("w:val"), str(num_id))
    num_pr.extend([ilvl, num])
    p_pr.append(num_pr)


def configure_styles(doc):
    styles = doc.styles
    normal = styles["Normal"]
    normal.font.name = "Calibri"
    normal._element.rPr.rFonts.set(qn("w:ascii"), "Calibri")
    normal._element.rPr.rFonts.set(qn("w:hAnsi"), "Calibri")
    normal.font.size = Pt(11)
    normal.font.color.rgb = RGBColor.from_string(INK)
    normal.paragraph_format.space_after = Pt(6)
    normal.paragraph_format.line_spacing = 1.25

    tokens = {
        "Heading 1": (16, BLUE, 18, 10),
        "Heading 2": (13, BLUE, 14, 7),
        "Heading 3": (12, NAVY, 10, 5),
    }
    for name, (size, color, before, after) in tokens.items():
        style = styles[name]
        style.font.name = "Calibri"
        style._element.rPr.rFonts.set(qn("w:ascii"), "Calibri")
        style._element.rPr.rFonts.set(qn("w:hAnsi"), "Calibri")
        style.font.size = Pt(size)
        style.font.bold = True
        style.font.color.rgb = RGBColor.from_string(color)
        style.paragraph_format.space_before = Pt(before)
        style.paragraph_format.space_after = Pt(after)
        style.paragraph_format.keep_with_next = True

    for name in ("List Bullet", "List Number"):
        style = styles[name]
        style.font.name = "Calibri"
        style.font.size = Pt(11)
        style.paragraph_format.left_indent = Inches(0.375)
        style.paragraph_format.first_line_indent = Inches(-0.188)
        style.paragraph_format.space_after = Pt(4)
        style.paragraph_format.line_spacing = 1.25


def add_inline(paragraph, text, base_color=INK):
    pattern = re.compile(r"(\*\*.*?\*\*|`.*?`)")
    cursor = 0
    for match in pattern.finditer(text):
        if match.start() > cursor:
            run = paragraph.add_run(text[cursor:match.start()])
            set_font(run, color=base_color)
        token = match.group(0)
        if token.startswith("**"):
            run = paragraph.add_run(token[2:-2])
            set_font(run, color=base_color, bold=True)
        else:
            run = paragraph.add_run(token[1:-1])
            set_font(run, name="Consolas", size=9.5, color=NAVY)
            run.font.highlight_color = None
        cursor = match.end()
    if cursor < len(text):
        run = paragraph.add_run(text[cursor:])
        set_font(run, color=base_color)


def add_table(doc, rows):
    if not rows:
        return
    columns = len(rows[0])
    table = doc.add_table(rows=len(rows), cols=columns)
    table.style = "Table Grid"
    widths = [9360 // columns] * columns
    widths[-1] += 9360 - sum(widths)
    if columns == 2:
        first_max = max(len(row[0]) for row in rows)
        widths = [2700, 6660] if first_max < 28 else [4000, 5360]
    elif columns == 3:
        widths = [2200, 3400, 3760]
    elif columns == 4:
        widths = [1350, 2850, 2580, 2580]
    set_table_geometry(table, widths)
    for row_index, values in enumerate(rows):
        for col_index, value in enumerate(values):
            cell = table.cell(row_index, col_index)
            cell.text = ""
            paragraph = cell.paragraphs[0]
            paragraph.paragraph_format.space_after = Pt(0)
            add_inline(paragraph, value, WHITE if row_index == 0 else INK)
            if row_index == 0:
                shade(cell, NAVY)
                for run in paragraph.runs:
                    run.bold = True
            elif row_index % 2 == 0:
                shade(cell, LIGHT)
        if row_index == 0:
            set_repeat_header(table.rows[0])
    doc.add_paragraph().paragraph_format.space_after = Pt(2)


def add_code_block(doc, lines):
    table = doc.add_table(rows=1, cols=1)
    table.style = "Table Grid"
    set_table_geometry(table, [9360])
    cell = table.cell(0, 0)
    shade(cell, "F2F5F8")
    paragraph = cell.paragraphs[0]
    paragraph.paragraph_format.space_after = Pt(0)
    paragraph.paragraph_format.line_spacing = 1.0
    run = paragraph.add_run("\n".join(lines))
    set_font(run, name="Consolas", size=8.5, color=NAVY)
    doc.add_paragraph().paragraph_format.space_after = Pt(2)


def add_architecture_visual(doc):
    table = doc.add_table(rows=1, cols=3)
    table.style = "Table Grid"
    set_table_geometry(table, [3000, 3360, 3000])
    values = [
        ("APP MÓVIL", "Flutter · Android", BLUE),
        ("SERVICIOS", "Laravel · API REST", TEAL),
        ("DATOS", "MySQL · Auditoría", NAVY),
    ]
    for cell, (title, subtitle, color) in zip(table.rows[0].cells, values):
        shade(cell, color)
        paragraph = cell.paragraphs[0]
        paragraph.alignment = WD_ALIGN_PARAGRAPH.CENTER
        paragraph.paragraph_format.space_after = Pt(3)
        run = paragraph.add_run(title)
        set_font(run, size=11, color=WHITE, bold=True)
        paragraph.add_run("\n")
        run = paragraph.add_run(subtitle)
        set_font(run, size=9, color=WHITE)
    doc.add_paragraph().paragraph_format.space_after = Pt(2)


def add_cover(doc):
    paragraph = doc.add_paragraph()
    paragraph.paragraph_format.space_after = Pt(28)
    run = paragraph.add_run("AULA")
    set_font(run, size=13, color=TEAL, bold=True)
    run = paragraph.add_run("GESTIÓN")
    set_font(run, size=13, color=BLUE, bold=True)

    paragraph = doc.add_paragraph()
    paragraph.paragraph_format.space_before = Pt(50)
    paragraph.paragraph_format.space_after = Pt(12)
    run = paragraph.add_run("Guía técnica, instalación,\npruebas y manual de usuario")
    set_font(run, size=30, color=NAVY, bold=True)

    paragraph = doc.add_paragraph()
    paragraph.paragraph_format.space_after = Pt(24)
    run = paragraph.add_run("Aplicativo móvil para inventario, recomendación y reserva de aulas")
    set_font(run, size=15, color=BLUE)

    bar = doc.add_table(rows=1, cols=2)
    bar.style = "Table Grid"
    set_table_geometry(bar, [6240, 3120])
    shade(bar.cell(0, 0), BLUE)
    shade(bar.cell(0, 1), TEAL)
    bar.rows[0].height = Inches(0.12)
    for cell in bar.rows[0].cells:
        cell.text = ""

    doc.add_paragraph().paragraph_format.space_after = Pt(18)
    table = doc.add_table(rows=5, cols=2)
    table.style = "Table Grid"
    set_table_geometry(table, [2500, 6860])
    metadata = [
        ("Proyecto", "App Inventario Colegio"),
        ("Versión", "1.0.0 · Prototipo funcional"),
        ("Tecnologías", "Flutter · Laravel 13 · MySQL 8 · Sanctum"),
        ("Metodología", "Scrum · 12 requerimientos consolidados"),
        ("Fecha", "Septiembre de 2026"),
    ]
    for index, (label, value) in enumerate(metadata):
        shade(table.cell(index, 0), SKY)
        p = table.cell(index, 0).paragraphs[0]
        p.text = ""
        r = p.add_run(label)
        set_font(r, color=NAVY, bold=True)
        p = table.cell(index, 1).paragraphs[0]
        p.text = ""
        r = p.add_run(value)
        set_font(r, color=INK)

    doc.add_paragraph().paragraph_format.space_after = Pt(18)
    paragraph = doc.add_paragraph()
    paragraph.paragraph_format.space_before = Pt(24)
    run = paragraph.add_run("Equipo Scrum")
    set_font(run, size=11, color=TEAL, bold=True)
    team = [
        "María Alejandra Vallejo Zamora · Product Owner",
        "Juan David Delgado Muñoz · Scrum Master e integración",
        "Julián Andrés Ceballos Eraso · Backend y base de datos",
        "David Esteban Ortiz Ortiz · Aplicativo móvil",
    ]
    for member in team:
        p = doc.add_paragraph(style="List Bullet")
        add_inline(p, member)
    doc.add_page_break()


def build():
    doc = Document()
    section = doc.sections[0]
    section.page_width = Inches(8.5)
    section.page_height = Inches(11)
    section.top_margin = Inches(1)
    section.bottom_margin = Inches(1)
    section.left_margin = Inches(1)
    section.right_margin = Inches(1)
    section.header_distance = Inches(0.492)
    section.footer_distance = Inches(0.492)
    configure_styles(doc)

    header = section.header
    p = header.paragraphs[0]
    p.text = ""
    p.alignment = WD_ALIGN_PARAGRAPH.RIGHT
    run = p.add_run("AULAGESTIÓN  |  GUÍA TÉCNICA Y DE USUARIO")
    set_font(run, size=8.5, color=MUTED, bold=True)
    pPr = p._p.get_or_add_pPr()
    borders = OxmlElement("w:pBdr")
    bottom = OxmlElement("w:bottom")
    bottom.set(qn("w:val"), "single")
    bottom.set(qn("w:sz"), "8")
    bottom.set(qn("w:space"), "4")
    bottom.set(qn("w:color"), MID)
    borders.append(bottom)
    pPr.append(borders)
    add_page_number(section.footer.paragraphs[0])

    add_cover(doc)

    lines = SOURCE.read_text(encoding="utf-8").splitlines()
    in_code = False
    code_language = ""
    code_lines = []
    table_rows = []
    skipped_first_title = False
    active_numbering_id = None

    def flush_table():
        nonlocal table_rows
        if table_rows:
            cleaned = [row for index, row in enumerate(table_rows) if not (index == 1 and all(re.fullmatch(r"[-: ]+", cell) for cell in row))]
            add_table(doc, cleaned)
            table_rows = []

    for line in lines:
        if line.startswith("```"):
            flush_table()
            if not in_code:
                in_code = True
                code_language = line[3:].strip()
                code_lines = []
            else:
                if code_language != "mermaid":
                    add_code_block(doc, code_lines)
                in_code = False
                code_language = ""
                code_lines = []
            continue
        if in_code:
            code_lines.append(line)
            continue
        if line.startswith("|") and line.endswith("|"):
            cells = [cell.strip() for cell in line.strip("|").split("|")]
            table_rows.append(cells)
            continue
        flush_table()
        stripped = line.strip()
        if not stripped or stripped == "---":
            continue
        is_numbered = bool(re.match(r"^\d+\.\s", stripped))
        if not is_numbered:
            active_numbering_id = None
        if stripped.startswith("# "):
            if not skipped_first_title:
                skipped_first_title = True
                continue
            p = doc.add_paragraph(stripped[2:], style="Heading 1")
        elif stripped.startswith("## "):
            title = stripped[3:]
            p = doc.add_paragraph(title, style="Heading 1")
            if title.startswith("3. Arquitectura"):
                add_architecture_visual(doc)
        elif stripped.startswith("### "):
            p = doc.add_paragraph(stripped[4:], style="Heading 2")
        elif re.match(r"^\d+\.\s", stripped):
            if active_numbering_id is None:
                active_numbering_id = create_numbering_instance(doc)
            p = doc.add_paragraph(style="List Number")
            apply_numbering(p, active_numbering_id)
            add_inline(p, re.sub(r"^\d+\.\s+", "", stripped))
        elif stripped.startswith("- "):
            p = doc.add_paragraph(style="List Bullet")
            add_inline(p, stripped[2:])
        else:
            p = doc.add_paragraph()
            add_inline(p, stripped)

    flush_table()

    props = doc.core_properties
    props.title = "AulaGestión - Guía técnica y manual de usuario"
    props.subject = "Aplicativo móvil para inventario, recomendación y reserva de aulas"
    props.author = "Equipo App Inventario Colegio"
    props.keywords = "Flutter, Laravel, MySQL, inventario, aulas, reservas"
    props.comments = "Versión académica 1.0.0"
    doc.save(OUTPUT)
    print(OUTPUT)


if __name__ == "__main__":
    build()
