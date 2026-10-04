from __future__ import annotations

import math
import re
from pathlib import Path

from docx import Document
from docx.enum.section import WD_SECTION
from docx.enum.table import WD_CELL_VERTICAL_ALIGNMENT
from docx.enum.text import WD_ALIGN_PARAGRAPH, WD_BREAK, WD_LINE_SPACING
from docx.oxml import OxmlElement
from docx.oxml.ns import qn
from docx.shared import Inches, Pt, RGBColor


ROOT = Path(__file__).resolve().parents[1]
OUTPUT = ROOT / "docs" / "Informe_Sistema_Diseno_Componentes_WarmiBot.docx"
GOLDENS = ROOT / "test" / "goldens"

BLUE = "2E74B5"
DARK_BLUE = "1F4D78"
GREEN = "0D5C27"
GREEN_LIGHT = "EAF6EE"
INK = "17202A"
MUTED = "5D6D7E"
TABLE_FILL = "E8EEF5"
TABLE_ALT = "F7F9FB"
CODE_FILL = "F6F8FA"
CODE_BORDER = "D0D7DE"
WHITE = "FFFFFF"


def rgb(value: str) -> RGBColor:
    return RGBColor.from_string(value)


def set_cell_shading(cell, fill: str) -> None:
    tc_pr = cell._tc.get_or_add_tcPr()
    shd = tc_pr.find(qn("w:shd"))
    if shd is None:
        shd = OxmlElement("w:shd")
        tc_pr.append(shd)
    shd.set(qn("w:fill"), fill)


def set_cell_margins(cell, top=80, start=120, bottom=80, end=120) -> None:
    tc_pr = cell._tc.get_or_add_tcPr()
    tc_mar = tc_pr.first_child_found_in("w:tcMar")
    if tc_mar is None:
        tc_mar = OxmlElement("w:tcMar")
        tc_pr.append(tc_mar)
    for name, value in (("top", top), ("start", start), ("bottom", bottom), ("end", end)):
        node = tc_mar.find(qn(f"w:{name}"))
        if node is None:
            node = OxmlElement(f"w:{name}")
            tc_mar.append(node)
        node.set(qn("w:w"), str(value))
        node.set(qn("w:type"), "dxa")


def set_table_geometry(table, widths: list[int], indent: int = 120) -> None:
    table.autofit = False
    table.allow_autofit = False
    tbl_pr = table._tbl.tblPr
    tbl_w = tbl_pr.first_child_found_in("w:tblW")
    if tbl_w is None:
        tbl_w = OxmlElement("w:tblW")
        tbl_pr.append(tbl_w)
    tbl_w.set(qn("w:w"), str(sum(widths)))
    tbl_w.set(qn("w:type"), "dxa")
    tbl_ind = tbl_pr.first_child_found_in("w:tblInd")
    if tbl_ind is None:
        tbl_ind = OxmlElement("w:tblInd")
        tbl_pr.append(tbl_ind)
    tbl_ind.set(qn("w:w"), str(indent))
    tbl_ind.set(qn("w:type"), "dxa")
    layout = tbl_pr.first_child_found_in("w:tblLayout")
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
        for idx, cell in enumerate(row.cells):
            cell.width = Inches(widths[idx] / 1440)
            tc_pr = cell._tc.get_or_add_tcPr()
            tc_w = tc_pr.first_child_found_in("w:tcW")
            if tc_w is None:
                tc_w = OxmlElement("w:tcW")
                tc_pr.append(tc_w)
            tc_w.set(qn("w:w"), str(widths[idx]))
            tc_w.set(qn("w:type"), "dxa")
            set_cell_margins(cell)


def mark_repeat_header(row) -> None:
    tr_pr = row._tr.get_or_add_trPr()
    header = OxmlElement("w:tblHeader")
    header.set(qn("w:val"), "true")
    tr_pr.append(header)


def prevent_row_split(row) -> None:
    tr_pr = row._tr.get_or_add_trPr()
    cant_split = OxmlElement("w:cantSplit")
    cant_split.set(qn("w:val"), "true")
    tr_pr.append(cant_split)


def add_table(doc, headers: list[str], rows: list[list[str]], widths: list[int]):
    table = doc.add_table(rows=1, cols=len(headers))
    table.style = "Table Grid"
    set_table_geometry(table, widths)
    header = table.rows[0]
    mark_repeat_header(header)
    prevent_row_split(header)
    for idx, text in enumerate(headers):
        cell = header.cells[idx]
        set_cell_shading(cell, TABLE_FILL)
        cell.vertical_alignment = WD_CELL_VERTICAL_ALIGNMENT.CENTER
        p = cell.paragraphs[0]
        p.paragraph_format.space_after = Pt(0)
        r = p.add_run(text)
        r.bold = True
        r.font.size = Pt(8.5)
        r.font.color.rgb = rgb(DARK_BLUE)
    for row_index, values in enumerate(rows):
        row = table.add_row()
        prevent_row_split(row)
        cells = row.cells
        for idx, text in enumerate(values):
            cell = cells[idx]
            if row_index % 2:
                set_cell_shading(cell, TABLE_ALT)
            cell.vertical_alignment = WD_CELL_VERTICAL_ALIGNMENT.CENTER
            p = cell.paragraphs[0]
            p.paragraph_format.space_after = Pt(0)
            run = p.add_run(text)
            run.font.size = Pt(8.2)
            run.font.color.rgb = rgb(INK)
    doc.add_paragraph().paragraph_format.space_after = Pt(1)
    return table


def add_page_number(paragraph) -> None:
    run = paragraph.add_run("Página ")
    run.font.size = Pt(8.5)
    run.font.color.rgb = rgb(MUTED)
    begin = OxmlElement("w:fldChar")
    begin.set(qn("w:fldCharType"), "begin")
    instr = OxmlElement("w:instrText")
    instr.set(qn("xml:space"), "preserve")
    instr.text = " PAGE "
    separate = OxmlElement("w:fldChar")
    separate.set(qn("w:fldCharType"), "separate")
    value = OxmlElement("w:t")
    value.text = "1"
    end = OxmlElement("w:fldChar")
    end.set(qn("w:fldCharType"), "end")
    run._r.extend([begin, instr, separate, value, end])


def configure_document(doc: Document) -> None:
    section = doc.sections[0]
    section.page_width = Inches(8.5)
    section.page_height = Inches(11)
    section.top_margin = Inches(0.72)
    section.bottom_margin = Inches(0.85)
    section.left_margin = Inches(0.75)
    section.right_margin = Inches(0.75)
    section.header_distance = Inches(0.35)
    section.footer_distance = Inches(0.25)
    doc.settings.odd_and_even_pages_header_footer = False

    styles = doc.styles
    normal = styles["Normal"]
    normal.font.name = "Calibri"
    normal._element.rPr.rFonts.set(qn("w:ascii"), "Calibri")
    normal._element.rPr.rFonts.set(qn("w:hAnsi"), "Calibri")
    normal.font.size = Pt(10.2)
    normal.font.color.rgb = rgb(INK)
    normal.paragraph_format.space_before = Pt(0)
    normal.paragraph_format.space_after = Pt(5)
    normal.paragraph_format.line_spacing = 1.16

    heading_tokens = {
        "Heading 1": (16, BLUE, 14, 7),
        "Heading 2": (13, BLUE, 10, 5),
        "Heading 3": (11.5, DARK_BLUE, 8, 4),
    }
    for name, (size, color, before, after) in heading_tokens.items():
        style = styles[name]
        style.font.name = "Calibri"
        style._element.rPr.rFonts.set(qn("w:ascii"), "Calibri")
        style._element.rPr.rFonts.set(qn("w:hAnsi"), "Calibri")
        style.font.size = Pt(size)
        style.font.bold = True
        style.font.color.rgb = rgb(color)
        style.paragraph_format.space_before = Pt(before)
        style.paragraph_format.space_after = Pt(after)
        style.paragraph_format.keep_with_next = True

    header = section.header.paragraphs[0]
    header.text = "WARMIBOT  |  Sistema de diseño y componentes reutilizables"
    header.alignment = WD_ALIGN_PARAGRAPH.LEFT
    header.paragraph_format.space_after = Pt(0)
    for run in header.runs:
        run.font.name = "Calibri"
        run.font.size = Pt(8.5)
        run.font.bold = True
        run.font.color.rgb = rgb(MUTED)

    footer = section.footer.paragraphs[0]
    footer.alignment = WD_ALIGN_PARAGRAPH.RIGHT
    add_page_number(footer)


def add_title_block(doc: Document) -> None:
    kicker = doc.add_paragraph()
    kicker.paragraph_format.space_after = Pt(3)
    run = kicker.add_run("INFORME TÉCNICO")
    run.font.name = "Calibri"
    run.font.size = Pt(9.5)
    run.font.bold = True
    run.font.color.rgb = rgb(GREEN)
    run.font.all_caps = True

    title = doc.add_paragraph()
    title.paragraph_format.space_after = Pt(4)
    run = title.add_run("Sistema de diseño y catálogo de componentes de WarmiBot")
    run.font.name = "Calibri"
    run.font.size = Pt(23)
    run.font.bold = True
    run.font.color.rgb = rgb(GREEN)

    subtitle = doc.add_paragraph()
    subtitle.paragraph_format.space_after = Pt(12)
    run = subtitle.add_run(
        "Tokens primitivos y semánticos, reutilización, pantalla ensamblada y verificación de accesibilidad"
    )
    run.font.size = Pt(11.5)
    run.font.color.rgb = rgb(MUTED)


def add_callout(doc: Document, label: str, text: str) -> None:
    p = doc.add_paragraph()
    p.paragraph_format.left_indent = Inches(0.08)
    p.paragraph_format.right_indent = Inches(0.08)
    p.paragraph_format.space_before = Pt(6)
    p.paragraph_format.space_after = Pt(8)
    p.paragraph_format.keep_together = True
    p_pr = p._p.get_or_add_pPr()
    shd = OxmlElement("w:shd")
    shd.set(qn("w:fill"), GREEN_LIGHT)
    p_pr.append(shd)
    borders = OxmlElement("w:pBdr")
    left = OxmlElement("w:left")
    left.set(qn("w:val"), "single")
    left.set(qn("w:sz"), "18")
    left.set(qn("w:space"), "6")
    left.set(qn("w:color"), GREEN)
    borders.append(left)
    p_pr.append(borders)
    run = p.add_run(f"{label}: ")
    run.bold = True
    run.font.color.rgb = rgb(GREEN)
    run = p.add_run(text)
    run.font.color.rgb = rgb(INK)


def luminance(hex_color: str) -> float:
    values = [int(hex_color[i:i + 2], 16) / 255 for i in (0, 2, 4)]
    linear = [v / 12.92 if v <= 0.04045 else ((v + 0.055) / 1.055) ** 2.4 for v in values]
    return 0.2126 * linear[0] + 0.7152 * linear[1] + 0.0722 * linear[2]


def contrast(a: str, b: str) -> float:
    la, lb = luminance(a), luminance(b)
    return (max(la, lb) + 0.05) / (min(la, lb) + 0.05)


DART_KEYWORDS = {
    "abstract", "as", "break", "case", "class", "const", "continue", "covariant",
    "default", "do", "else", "enum", "extends", "final", "for", "if", "import",
    "in", "is", "late", "new", "null", "override", "required", "return", "static",
    "super", "switch", "this", "throw", "true", "false", "try", "typedef", "var",
    "void", "while", "with",
}


TOKEN_RE = re.compile(r"(//.*$|'(?:\\.|[^'\\])*'|\"(?:\\.|[^\"\\])*\"|\b\d+(?:\.\d+)?\b|\b[A-Za-z_]\w*\b|\s+|.)")


def code_color(token: str) -> str:
    if token.startswith("//"):
        return "6A737D"
    if token.startswith(("'", '"')):
        return "A31515"
    if token in DART_KEYWORDS:
        return "0000A0"
    if re.fullmatch(r"\d+(?:\.\d+)?", token):
        return "098658"
    if token and token[0].isupper():
        return "267F99"
    return "24292F"


def add_code(doc: Document, source: str) -> None:
    lines = source.rstrip().splitlines()
    digits = len(str(len(lines)))
    for number, line in enumerate(lines, 1):
        p = doc.add_paragraph()
        p.paragraph_format.space_before = Pt(0)
        p.paragraph_format.space_after = Pt(0)
        p.paragraph_format.line_spacing_rule = WD_LINE_SPACING.SINGLE
        p.paragraph_format.keep_together = True
        p_pr = p._p.get_or_add_pPr()
        shd = OxmlElement("w:shd")
        shd.set(qn("w:fill"), CODE_FILL)
        p_pr.append(shd)
        run = p.add_run(f"{number:>{digits}}  ")
        run.font.name = "Consolas"
        run._element.rPr.rFonts.set(qn("w:ascii"), "Consolas")
        run._element.rPr.rFonts.set(qn("w:hAnsi"), "Consolas")
        run.font.size = Pt(6.4)
        run.font.color.rgb = rgb("7A8694")
        for token in TOKEN_RE.findall(line):
            run = p.add_run(token)
            run.font.name = "Consolas"
            run._element.rPr.rFonts.set(qn("w:ascii"), "Consolas")
            run._element.rPr.rFonts.set(qn("w:hAnsi"), "Consolas")
            run.font.size = Pt(6.4)
            run.font.color.rgb = rgb(code_color(token))
    doc.add_paragraph().paragraph_format.space_after = Pt(1)


def set_image_alt(inline_shape, description: str) -> None:
    inline = inline_shape._inline
    doc_pr = inline.docPr
    doc_pr.set("descr", description)
    doc_pr.set("title", description)


def add_figure(doc: Document, images: list[tuple[Path, float, str]], caption: str) -> None:
    p = doc.add_paragraph()
    p.alignment = WD_ALIGN_PARAGRAPH.CENTER
    p.paragraph_format.keep_with_next = True
    for index, (path, width, alt) in enumerate(images):
        shape = p.add_run().add_picture(str(path), width=Inches(width))
        set_image_alt(shape, alt)
        if index < len(images) - 1:
            p.add_run("   ")
    cap = doc.add_paragraph()
    cap.alignment = WD_ALIGN_PARAGRAPH.CENTER
    cap.paragraph_format.space_before = Pt(3)
    cap.paragraph_format.space_after = Pt(8)
    cap.paragraph_format.keep_with_next = False
    run = cap.add_run(caption)
    run.italic = True
    run.font.size = Pt(8.2)
    run.font.color.rgb = rgb(MUTED)


def add_component_section(
    doc: Document,
    number: int,
    name: str,
    purpose: str,
    rationale: str,
    interface_rows: list[list[str]],
    states: str,
    source_path: Path,
) -> None:
    doc.add_heading(f"3.{number} {name}", level=2)
    doc.add_paragraph(purpose)
    add_callout(doc, "Por qué es reutilizable", rationale)
    add_table(
        doc,
        ["Elemento público", "Tipo", "Responsabilidad"],
        interface_rows,
        [2200, 2500, 5380],
    )
    doc.add_paragraph(f"Estados resueltos: {states}")
    doc.add_paragraph("Código fuente completo, seleccionable y numerado:").runs[0].bold = True
    add_code(doc, source_path.read_text(encoding="utf-8"))


def build() -> None:
    OUTPUT.parent.mkdir(parents=True, exist_ok=True)
    doc = Document()
    configure_document(doc)
    add_title_block(doc)

    doc.add_heading("Resumen del trabajo", level=1)
    doc.add_paragraph(
        "En esta actividad definimos un sistema de diseño para WarmiBot, convertimos valores visuales aislados en tokens de tema y construimos un catálogo de componentes que recibe datos y callbacks sin depender del backend ni de rutas de navegación. Después reconstruimos la pantalla Conversaciones con esos componentes y verificamos contraste, semántica, área táctil, dos anchos y ampliación tipográfica."
    )
    add_callout(
        doc,
        "Resultado",
        "La pantalla funciona a 360 y 600 dp, admite fuente al 150 %, mantiene objetivos táctiles de 48 dp y las 18 pruebas automatizadas terminan correctamente.",
    )

    doc.add_heading("1. Proyecto e inventario derivado de la API", level=1)
    doc.add_paragraph(
        "WarmiBot es una aplicación Flutter con identidad amazónica que integra chat, voz, clima, noticias, traducción, recordatorios y alarmas. Su backend propio está desarrollado con FastAPI y expone salud del sistema, autenticación, conversaciones, tareas asíncronas y diagnósticos. Para evitar diseñar pantallas aisladas, derivamos el inventario a partir de todos los endpoints y distinguimos lo implementado actualmente de la evolución prevista."
    )
    inventory = [
        ["Inicio / estado", "GET /health", "Confirmar disponibilidad y ambiente de la API.", "Actual"],
        ["Registro", "POST /api/v1/auth/register", "Crear una cuenta de usuario.", "Futura"],
        ["Inicio de sesión", "POST /auth/login; /refresh; /logout", "Abrir, renovar y cerrar la sesión.", "Futura"],
        ["Perfil", "GET /api/v1/auth/me", "Mostrar identidad y rol autenticado.", "Futura"],
        ["Conversaciones", "GET y POST /api/v1/conversations", "Listar y crear conversaciones.", "Vista actual; API futura"],
        ["Detalle", "GET y DELETE /conversations/{id}", "Consultar mensajes o eliminar la conversación.", "Futura"],
        ["Chat", "POST /conversations/{id}/messages", "Agregar mensajes del usuario o asistente.", "Futura"],
        ["Resumen", "POST /jobs/conversation-summary/{id}; GET /jobs/{id}", "Solicitar y consultar un resumen asíncrono.", "Futura"],
        ["Diagnóstico administrador", "POST /diagnostics/seed; GET /n-plus-one; GET /cache", "Preparar datos y revisar optimización/caché.", "Interna"],
    ]
    add_table(doc, ["Pantalla", "Endpoint asociado", "Necesidad de interfaz", "Estado"], inventory, [1900, 3150, 3900, 1130])
    doc.add_paragraph(
        "Los endpoints de renovación de token y algunas tareas de diagnóstico no necesitan una pantalla independiente: actúan en segundo plano o dentro de un área administrativa. La pantalla elegida para el ensamblaje es Conversaciones porque ya pertenece a la aplicación y permite evidenciar contenido, vacío, carga y error sin ampliar el alcance hacia una autenticación completa."
    )

    doc.add_heading("2. Sistema de tokens", level=1)
    doc.add_paragraph(
        "Separamos dos niveles. Los tokens primitivos expresan valores base sin intención de uso; los semánticos indican para qué sirve cada valor en la interfaz. Los componentes solo consultan las extensiones WarmiColorTokens, WarmiSpacingTokens, WarmiRadiusTokens y WarmiSizeTokens mediante el contexto del tema."
    )
    primitive_colors = [
        ["jungle800", "#0D5C27", "Verde oscuro base"],
        ["jungle600", "#1B8A3C", "Verde amazónico"],
        ["jungle400", "#52D681", "Verde claro"],
        ["night950", "#050E1C", "Azul noche extremo"],
        ["night900", "#0A1628", "Azul noche"],
        ["night800", "#112040", "Azul tarjeta"],
        ["night700", "#1A2F4A", "Azul elevado"],
        ["blue200", "#B0C4DE", "Azul texto secundario"],
        ["blue300", "#91ADD0", "Azul texto atenuado"],
        ["amber300", "#FFD166", "Ámbar"],
        ["coral300", "#FF9B9B", "Coral"],
        ["teal300", "#5DE2E7", "Turquesa"],
    ]
    add_table(doc, ["Token primitivo", "Valor", "Descripción"], primitive_colors, [2600, 1800, 5680])
    semantic_rows = [
        ["background", "night900", "Fondo general"],
        ["surface / surfaceElevated", "night800 / night700", "Tarjetas y niveles elevados"],
        ["textPrimary", "white", "Texto principal"],
        ["textSecondary / textMuted", "blue200 / blue300", "Texto de apoyo"],
        ["interactive / onInteractive", "jungle800 / white", "Acción y texto sobre acción"],
        ["success / warning / error", "jungle400 / amber300 / coral300", "Estados acompañados de texto o icono"],
        ["outline", "#557797", "Bordes perceptibles"],
        ["focus", "teal300", "Indicador de foco"],
    ]
    add_table(doc, ["Token semántico", "Primitivo o valor", "Uso"], semantic_rows, [2900, 3000, 4180])

    doc.add_heading("2.1 Tipografía, espaciado y radio", level=2)
    other_tokens = [
        ["Tipografía primitiva", "28, 22, 18, 16, 14 y 12 sp", "Escala base"],
        ["Tipografía semántica", "headlineLarge, headlineMedium, titleLarge, bodyLarge, bodyMedium, label", "Roles consumidos con TextTheme"],
        ["Espaciado", "4, 8, 12, 16, 24, 32 y 48 dp", "xxs a xxl; base modular de 4"],
        ["Radio", "8, 12, 16 y 999 dp", "small, medium, large y pill"],
        ["Objetivo táctil", "48 dp", "minimumSize para acciones"],
    ]
    add_table(doc, ["Familia", "Valores", "Aplicación semántica"], other_tokens, [2500, 3400, 4180])

    doc.add_heading("2.2 Medición de contraste", level=2)
    pairs = [
        ("textPrimary / background", "FFFFFF", "0A1628", "Texto normal"),
        ("textPrimary / surface", "FFFFFF", "112040", "Texto normal"),
        ("textSecondary / background", "B0C4DE", "0A1628", "Texto normal"),
        ("textSecondary / surface", "B0C4DE", "112040", "Texto normal"),
        ("textMuted / surface", "91ADD0", "112040", "Texto normal"),
        ("onInteractive / interactive", "FFFFFF", "0D5C27", "Texto de botón"),
        ("success / background", "52D681", "0A1628", "Estado"),
        ("warning / background", "FFD166", "0A1628", "Estado"),
        ("error / background", "FF9B9B", "0A1628", "Estado"),
        ("focus / background", "5DE2E7", "0A1628", "Foco"),
        ("outline / surface", "557797", "112040", "Borde gráfico"),
    ]
    contrast_rows = []
    for label, fg, bg, use in pairs:
        value = contrast(fg, bg)
        threshold = 3.0 if use in {"Estado", "Foco", "Borde gráfico"} else 4.5
        contrast_rows.append([label, f"#{fg} / #{bg}", f"{value:.2f}:1", f"≥ {threshold:.1f}:1", "Cumple" if value >= threshold else "No cumple"])
    add_table(doc, ["Par", "Colores", "Resultado", "Umbral", "Evaluación"], contrast_rows, [2700, 2500, 1400, 1200, 2280])
    add_callout(
        doc,
        "Corrección aplicada",
        "El borde #3E5E79 producía 2,36:1 sobre surface. Lo sustituimos por #557797, con 3,43:1. Además, cada estado utiliza icono y texto; el color nunca es el único medio de comunicación.",
    )

    doc.add_heading("3. Catálogo de componentes", level=1)
    catalog = [
        ["WarmiPageScaffold", "Estructura título-descripción-contenido", "Todas las pantallas principales", "Contenido"],
        ["WarmiAsyncContent", "Alternar carga, vacío, error y contenido", "Cualquier consulta o colección", "Carga, vacío, error, contenido"],
        ["WarmiMessageCard", "Presentar mensajes por remitente", "Inicio, historial y detalle futuro", "Usuario / WarmiBot; interacción opcional"],
        ["WarmiActionCard", "Acción compacta con etiqueta", "Ocho acciones rápidas y futuros accesos", "Normal / seleccionado"],
    ]
    add_table(doc, ["Componente", "Propósito", "Apariciones previstas", "Variantes/estados"], catalog, [2500, 3000, 3000, 1580])
    doc.add_paragraph(
        "La regla de las tres apariciones se aplicó de forma práctica: WarmiActionCard sustituye ocho botones repetidos; WarmiPageScaffold representa el patrón común de las pantallas; WarmiMessageCard ya se consume en Inicio e Historial y será reutilizable en el detalle; WarmiAsyncContent centraliza cuatro estados que de otro modo se repetirían en cada flujo de API. Ninguno importa servicios HTTP ni recibe rutas."
    )

    add_component_section(
        doc, 1, "WarmiPageScaffold",
        "Uniforma el encabezado, márgenes y área de contenido de una pantalla.",
        "La interfaz delega el cuerpo y las acciones como Widget; el componente solo organiza presentación y lee tokens semánticos del tema.",
        [["title", "String", "Título semántico de la pantalla"], ["description", "String", "Explica la función de la vista"], ["child", "Widget", "Contenido delegado"], ["actions", "List<Widget>", "Acciones delegadas opcionales"]],
        "contenido normal y presencia o ausencia de acciones.",
        ROOT / "lib/presentation/components/warmi_page_scaffold.dart",
    )
    add_component_section(
        doc, 2, "WarmiAsyncContent",
        "Evita que cada pantalla vuelva a programar sus estados de datos.",
        "El enum desacopla el estado visual; todos los textos son configurables, contentBuilder delega el contenido correcto y onRetry comunica la intención sin conocer la API.",
        [["state", "WarmiContentState", "Selecciona carga, vacío, error o contenido"], ["contentBuilder", "WidgetBuilder", "Construye contenido delegado"], ["loading/empty/error...", "String", "Mensajes configurables"], ["onRetry", "VoidCallback?", "Notifica el reintento al contenedor"]],
        "loading, empty, error y content; liveRegion anuncia cambios.",
        ROOT / "lib/presentation/components/warmi_async_content.dart",
    )
    add_component_section(
        doc, 3, "WarmiMessageCard",
        "Representa un mensaje y adapta alineación visual al remitente.",
        "Recibe el modelo completo, deriva su variante sin consultar datos externos, ofrece interacción opcional y expone una frase semántica que incluye remitente, hora y contenido.",
        [["message", "ChatMessage", "Datos que se representan"], ["onLongPress", "VoidCallback?", "Contenido interactivo opcional"]],
        "mensaje del usuario, mensaje de WarmiBot y acción prolongada opcional.",
        ROOT / "lib/presentation/components/warmi_message_card.dart",
    )
    add_component_section(
        doc, 4, "WarmiActionCard",
        "Reemplaza los ocho botones repetidos de acciones rápidas.",
        "Se configura con icono, etiqueta, semántica, callback y selección. Mantiene 48 dp mínimos y no conoce qué comando, servicio o ruta ejecutará el contenedor.",
        [["icon / label", "String", "Contenido visual"], ["semanticLabel", "String?", "Descripción para asistencia"], ["onPressed", "VoidCallback", "Acción delegada"], ["selected", "bool", "Configuración visual"]],
        "normal y seleccionado.",
        ROOT / "lib/presentation/components/warmi_action_card.dart",
    )

    doc.add_heading("4. Ensamblaje de la pantalla Conversaciones", level=1)
    doc.add_paragraph(
        "Separamos ConversationsPage, que adapta el estado del BLoC, de ConversationsView, que es una vista pura. La vista ensambla WarmiPageScaffold, WarmiAsyncContent y WarmiMessageCard. Así puede probarse con datos controlados, pero en ejecución real recibe el historial del estado de la aplicación."
    )
    page_source = (ROOT / "lib/presentation/pages/conversations_page.dart").read_text(encoding="utf-8")
    start = page_source.index("class ConversationsView")
    end = page_source.index("// ============================================================\n// WarmiBot — ProfilePage")
    add_code(doc, page_source[start:end].rstrip())

    doc.add_page_break()
    doc.add_heading("5. Capturas y comportamiento responsivo", level=1)
    doc.add_paragraph(
        "Las capturas se produjeron ejecutando la vista real mediante Flutter Test con tamaño y escala tipográfica controlados. No son maquetas: representan los widgets compilados, el tema y los componentes implementados."
    )
    add_figure(
        doc,
        [
            (GOLDENS / "conversaciones_360.png", 2.45, "Pantalla Conversaciones a 360 dp con dos mensajes"),
            (GOLDENS / "conversaciones_600.png", 3.06, "Pantalla Conversaciones a 600 dp con dos mensajes"),
        ],
        "Figura 1. La misma pantalla a 360 dp y 600 dp: el contenido se redistribuye sin desbordamientos.",
    )
    doc.add_page_break()
    add_figure(
        doc,
        [(GOLDENS / "conversaciones_fuente_150.png", 2.65, "Conversaciones a 360 dp con fuente del sistema al 150 por ciento")],
        "Figura 2. Fuente al 150 %: textos refluídos y tarjetas con altura flexible.",
    )
    add_figure(
        doc,
        [
            (GOLDENS / "estado_cargando.png", 1.65, "Estado cargando conversaciones"),
            (GOLDENS / "estado_vacio.png", 1.65, "Estado vacío sin conversaciones"),
            (GOLDENS / "estado_error.png", 1.65, "Estado de error con botón de reintento"),
        ],
        "Figura 3. Estados cargando, vacío y error resueltos por WarmiAsyncContent.",
    )

    doc.add_heading("6. Verificación de accesibilidad", level=1)
    accessibility_rows = [
        ["Contraste de texto", "Mínimo observado 6,97:1 en texto atenuado sobre surface", "Cumple AA"],
        ["Contraste no textual", "Outline corregido de 2,36:1 a 3,43:1", "Cumple 3:1"],
        ["Área táctil", "Botón Reintentar ≥ 48 × 48 dp; token minTouchTarget = 48", "Cumple guía Flutter"],
        ["Etiquetas semánticas", "Encabezado, estados, mensajes y acciones tienen label/rol", "Comprobado por pruebas"],
        ["Color como señal", "Error, vacío y carga combinan icono, texto y color", "Cumple"],
        ["Ancho compacto", "360 × 800 dp, sin excepción de overflow", "Cumple"],
        ["Ancho ampliado", "600 × 960 dp, sin excepción de overflow", "Cumple"],
        ["Fuente ampliada", "TextScaler 1,5 en 360 dp, sin desbordamiento", "Cumple"],
    ]
    add_table(doc, ["Criterio", "Valor o evidencia", "Resultado"], accessibility_rows, [2600, 5400, 2080])
    doc.add_paragraph(
        "La corrección más importante fue eliminar TextScaler.noScaling de MaterialApp. Ese código impedía respetar la preferencia del sistema. También cambiamos GestureDetector por controles con semántica y superficie Material, y trasladamos el mínimo táctil al tema para que no dependa de cada widget."
    )
    add_callout(
        doc,
        "Verificación automática",
        "dart analyze informó 0 incidencias y flutter test ejecutó 18 pruebas aprobadas. design_system_test.dart valida semántica, 48 dp, fuente al 150 % y genera las seis capturas reproducibles.",
    )
    doc.add_paragraph(
        "Criterios consultados: WCAG 2.2 exige 4,5:1 para texto normal y 3:1 para información gráfica; la guía oficial de Flutter recomienda objetivos táctiles de al menos 48 × 48 y comprobar la interfaz con fuentes grandes."
    )

    doc.add_heading("7. Registro del apoyo de inteligencia artificial", level=1)
    ai_rows = [
        ["Estructuración", "Apoyo para ordenar el inventario de endpoints y la matriz del informe.", "El equipo revisó el alcance y aprobó la pantalla."],
        ["Accesibilidad", "Apoyo para calcular contraste y proponer casos de prueba.", "Los integrantes conservaron los valores verificados y la corrección final."],
        ["Código y pruebas", "Apoyo puntual para revisar desacoplamiento, semántica y escenarios.", "La implementación, ejecución y validación se integraron y revisaron dentro del proyecto del grupo."],
        ["Redacción", "Apoyo para claridad, síntesis y consistencia del informe.", "La versión final se expresa desde el trabajo y las decisiones del equipo."],
    ]
    add_table(doc, ["Parte", "Uso de IA", "Responsabilidad del equipo"], ai_rows, [2100, 4300, 3680])
    doc.add_paragraph(
        "La inteligencia artificial se utilizó como herramienta de apoyo en partes específicas. No reemplazó la comprensión del proyecto ni la revisión del código: las decisiones de diseño, la integración en WarmiBot y la validación final corresponden a los integrantes del grupo."
    )

    doc.add_heading("Conclusiones", level=1)
    doc.add_paragraph(
        "Con este trabajo dejamos de tratar cada pantalla como una pieza aislada. Los tokens establecen una única fuente de verdad, los componentes expresan contratos públicos y la vista Conversaciones demuestra que presentación, estado y datos pueden mantenerse separados. La accesibilidad también pasó de ser una revisión visual a una condición comprobable mediante contraste medido, semántica, 48 dp, dos anchos y fuente ampliada."
    )

    doc.add_heading("Fuentes de verificación", level=2)
    sources = [
        "W3C. Web Content Accessibility Guidelines (WCAG) 2.2. https://www.w3.org/TR/WCAG22/",
        "W3C. Técnica G207: contraste 3:1 para iconos y objetos gráficos. https://www.w3.org/WAI/WCAG22/Techniques/general/G207",
        "Flutter. Accessibility: diseño, objetivos táctiles y escalado. https://docs.flutter.dev/ui/accessibility",
        "Código fuente local de WarmiBot: tema, componentes, pantalla, backend y pruebas revisados el 22 de agosto de 2026.",
    ]
    for source in sources:
        p = doc.add_paragraph(source)
        p.paragraph_format.left_indent = Inches(0.2)
        p.paragraph_format.first_line_indent = Inches(-0.2)
        p.paragraph_format.space_after = Pt(3)
        for run in p.runs:
            run.font.size = Pt(8.5)

    props = doc.core_properties
    props.title = "Sistema de diseño y catálogo de componentes de WarmiBot"
    props.subject = "Informe técnico de tokens, componentes y accesibilidad"
    props.author = "Equipo WarmiBot"
    props.keywords = "WarmiBot, Flutter, sistema de diseño, componentes, accesibilidad"

    doc.save(OUTPUT)
    print(OUTPUT)


if __name__ == "__main__":
    build()
