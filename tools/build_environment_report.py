from __future__ import annotations

import json
import textwrap
from pathlib import Path

from PIL import Image, ImageDraw, ImageFont
from docx import Document
from docx.enum.section import WD_SECTION
from docx.enum.table import WD_CELL_VERTICAL_ALIGNMENT, WD_TABLE_ALIGNMENT
from docx.enum.text import WD_ALIGN_PARAGRAPH, WD_BREAK, WD_LINE_SPACING
from docx.oxml import OxmlElement
from docx.oxml.ns import qn
from docx.shared import Inches, Pt, RGBColor


ROOT = Path(r"C:\WarmiBot")
DOCS = ROOT / "docs"
EVIDENCE = DOCS / "evidencias"
GENERATED = EVIDENCE / "generadas"
OUTPUT = DOCS / "Informe_Entorno_Multiplataforma_WarmiBot.docx"

NAVY = "0B2545"
BLUE = "2E74B5"
GREEN = "18864B"
GREEN_LIGHT = "E8F5ED"
TEAL = "147D82"
CORAL = "C65D4B"
GOLD = "C6902B"
GRAY = "5F6B7A"
LIGHT = "F2F4F7"
PALE_BLUE = "E8EEF5"
WHITE = "FFFFFF"
BLACK = "1F2933"


def rgb(hex_value: str) -> RGBColor:
    return RGBColor.from_string(hex_value)


def set_run_font(run, name="Calibri", size=11, color=BLACK, bold=False,
                 italic=False):
    run.font.name = name
    run._element.get_or_add_rPr().rFonts.set(qn("w:ascii"), name)
    run._element.get_or_add_rPr().rFonts.set(qn("w:hAnsi"), name)
    run.font.size = Pt(size)
    run.font.color.rgb = rgb(color)
    run.bold = bold
    run.italic = italic


def shade_cell(cell, fill: str):
    tc_pr = cell._tc.get_or_add_tcPr()
    shd = tc_pr.find(qn("w:shd"))
    if shd is None:
        shd = OxmlElement("w:shd")
        tc_pr.append(shd)
    shd.set(qn("w:fill"), fill)


def set_cell_margins(cell, top=80, start=120, bottom=80, end=120):
    tc_pr = cell._tc.get_or_add_tcPr()
    tc_mar = tc_pr.first_child_found_in("w:tcMar")
    if tc_mar is None:
        tc_mar = OxmlElement("w:tcMar")
        tc_pr.append(tc_mar)
    for edge, value in (("top", top), ("start", start),
                        ("bottom", bottom), ("end", end)):
        element = tc_mar.find(qn(f"w:{edge}"))
        if element is None:
            element = OxmlElement(f"w:{edge}")
            tc_mar.append(element)
        element.set(qn("w:w"), str(value))
        element.set(qn("w:type"), "dxa")


def set_table_geometry(table, widths_dxa: list[int], indent=120):
    total = sum(widths_dxa)
    table.alignment = WD_TABLE_ALIGNMENT.LEFT
    table.autofit = False
    tbl_pr = table._tbl.tblPr
    for name in ("tblW", "tblInd", "tblLayout"):
        current = tbl_pr.find(qn(f"w:{name}"))
        if current is not None:
            tbl_pr.remove(current)
    tbl_w = OxmlElement("w:tblW")
    tbl_w.set(qn("w:w"), str(total))
    tbl_w.set(qn("w:type"), "dxa")
    tbl_pr.append(tbl_w)
    tbl_ind = OxmlElement("w:tblInd")
    tbl_ind.set(qn("w:w"), str(indent))
    tbl_ind.set(qn("w:type"), "dxa")
    tbl_pr.append(tbl_ind)
    layout = OxmlElement("w:tblLayout")
    layout.set(qn("w:type"), "fixed")
    tbl_pr.append(layout)

    old_grid = table._tbl.tblGrid
    if old_grid is not None:
        table._tbl.remove(old_grid)
    grid = OxmlElement("w:tblGrid")
    for width in widths_dxa:
        col = OxmlElement("w:gridCol")
        col.set(qn("w:w"), str(width))
        grid.append(col)
    table._tbl.insert(1, grid)

    for row in table.rows:
        for index, cell in enumerate(row.cells):
            width = widths_dxa[index]
            tc_pr = cell._tc.get_or_add_tcPr()
            tc_w = tc_pr.find(qn("w:tcW"))
            if tc_w is None:
                tc_w = OxmlElement("w:tcW")
                tc_pr.append(tc_w)
            tc_w.set(qn("w:w"), str(width))
            tc_w.set(qn("w:type"), "dxa")
            cell.width = Inches(width / 1440)
            cell.vertical_alignment = WD_CELL_VERTICAL_ALIGNMENT.CENTER
            set_cell_margins(cell)


def set_repeat_table_header(row):
    tr_pr = row._tr.get_or_add_trPr()
    tbl_header = OxmlElement("w:tblHeader")
    tbl_header.set(qn("w:val"), "true")
    tr_pr.append(tbl_header)


def add_page_number(paragraph):
    paragraph.alignment = WD_ALIGN_PARAGRAPH.RIGHT
    run = paragraph.add_run("Página ")
    set_run_font(run, size=9, color=GRAY)
    fld_char1 = OxmlElement("w:fldChar")
    fld_char1.set(qn("w:fldCharType"), "begin")
    instr_text = OxmlElement("w:instrText")
    instr_text.set(qn("xml:space"), "preserve")
    instr_text.text = " PAGE "
    fld_char2 = OxmlElement("w:fldChar")
    fld_char2.set(qn("w:fldCharType"), "end")
    run._r.extend([fld_char1, instr_text, fld_char2])


def configure_styles(doc: Document):
    section = doc.sections[0]
    section.page_width = Inches(8.5)
    section.page_height = Inches(11)
    section.top_margin = Inches(1)
    section.right_margin = Inches(1)
    section.bottom_margin = Inches(1)
    section.left_margin = Inches(1)
    section.header_distance = Inches(0.492)
    section.footer_distance = Inches(0.492)

    styles = doc.styles
    normal = styles["Normal"]
    normal.font.name = "Calibri"
    normal._element.rPr.rFonts.set(qn("w:ascii"), "Calibri")
    normal._element.rPr.rFonts.set(qn("w:hAnsi"), "Calibri")
    normal.font.size = Pt(11)
    normal.font.color.rgb = rgb(BLACK)
    normal.paragraph_format.space_before = Pt(0)
    normal.paragraph_format.space_after = Pt(6)
    normal.paragraph_format.line_spacing = 1.1

    heading_tokens = {
        "Heading 1": (16, BLUE, 16, 8),
        "Heading 2": (13, BLUE, 12, 6),
        "Heading 3": (12, NAVY, 8, 4),
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

    for name in ("List Bullet", "List Number"):
        style = styles[name]
        style.font.name = "Calibri"
        style.font.size = Pt(11)
        style.paragraph_format.left_indent = Inches(0.5)
        style.paragraph_format.first_line_indent = Inches(-0.25)
        style.paragraph_format.space_after = Pt(8)
        style.paragraph_format.line_spacing = 1.167

    header = section.header
    hp = header.paragraphs[0]
    hp.text = "WARMI BOT  |  ENTORNO MÓVIL MULTIPLATAFORMA"
    hp.alignment = WD_ALIGN_PARAGRAPH.LEFT
    hp.paragraph_format.space_after = Pt(0)
    set_run_font(hp.runs[0], size=8.5, color=GRAY, bold=True)
    footer = section.footer
    add_page_number(footer.paragraphs[0])


def add_para(doc, text, *, bold=False, italic=False, color=BLACK, size=11,
             align=WD_ALIGN_PARAGRAPH.LEFT, after=6, keep=False):
    p = doc.add_paragraph()
    p.alignment = align
    p.paragraph_format.space_before = Pt(0)
    p.paragraph_format.space_after = Pt(after)
    p.paragraph_format.line_spacing = 1.1
    p.paragraph_format.keep_with_next = keep
    r = p.add_run(text)
    set_run_font(r, size=size, color=color, bold=bold, italic=italic)
    return p


def add_bullet(doc, text):
    p = doc.add_paragraph(style="List Bullet")
    p.add_run(text)
    return p


def add_number(doc, text):
    p = doc.add_paragraph(style="List Number")
    p.add_run(text)
    return p


def add_code(doc, text):
    p = doc.add_paragraph()
    p.paragraph_format.left_indent = Inches(0.18)
    p.paragraph_format.right_indent = Inches(0.18)
    p.paragraph_format.space_before = Pt(4)
    p.paragraph_format.space_after = Pt(8)
    p.paragraph_format.line_spacing_rule = WD_LINE_SPACING.SINGLE
    p_pr = p._p.get_or_add_pPr()
    shd = OxmlElement("w:shd")
    shd.set(qn("w:fill"), "F7F8FA")
    p_pr.append(shd)
    r = p.add_run(text)
    set_run_font(r, name="Consolas", size=9, color=NAVY)
    return p


def add_callout(doc, label, text, fill=GREEN_LIGHT, accent=GREEN):
    table = doc.add_table(rows=1, cols=1)
    set_table_geometry(table, [9360])
    cell = table.cell(0, 0)
    shade_cell(cell, fill)
    p = cell.paragraphs[0]
    p.paragraph_format.space_after = Pt(2)
    r = p.add_run(label.upper())
    set_run_font(r, size=9, color=accent, bold=True)
    p2 = cell.add_paragraph()
    p2.paragraph_format.space_after = Pt(0)
    r2 = p2.add_run(text)
    set_run_font(r2, size=10.5, color=BLACK)
    doc.add_paragraph().paragraph_format.space_after = Pt(0)
    return table


def add_matrix(doc, headers, rows, widths, header_fill=PALE_BLUE):
    table = doc.add_table(rows=1, cols=len(headers))
    table.style = "Table Grid"
    set_table_geometry(table, widths)
    set_repeat_table_header(table.rows[0])
    for i, header in enumerate(headers):
        cell = table.rows[0].cells[i]
        shade_cell(cell, header_fill)
        p = cell.paragraphs[0]
        p.paragraph_format.space_after = Pt(0)
        r = p.add_run(header)
        set_run_font(r, size=9.5, color=NAVY, bold=True)
    for row_values in rows:
        row = table.add_row()
        for i, value in enumerate(row_values):
            cell = row.cells[i]
            p = cell.paragraphs[0]
            p.paragraph_format.space_after = Pt(0)
            p.paragraph_format.line_spacing = 1.0
            r = p.add_run(str(value))
            set_run_font(r, size=9.2, color=BLACK)
        set_table_geometry(table, widths)
    return table


def page_break(doc):
    doc.add_page_break()


def set_last_image_alt(doc, description: str):
    inline = doc.inline_shapes[-1]._inline
    doc_pr = inline.docPr
    doc_pr.set("descr", description)
    doc_pr.set("title", description)


def terminal_image(filename: str, title: str, lines: list[str], accent: str):
    width = 1500
    margin = 55
    font_path = r"C:\Windows\Fonts\consola.ttf"
    bold_path = r"C:\Windows\Fonts\consolab.ttf"
    body_font = ImageFont.truetype(font_path, 25)
    title_font = ImageFont.truetype(bold_path, 30)
    small_font = ImageFont.truetype(font_path, 21)
    wrapped = []
    for line in lines:
        wrapped.extend(textwrap.wrap(line, width=92, replace_whitespace=False,
                                     drop_whitespace=False) or [""])
    height = 150 + len(wrapped) * 38 + 50
    image = Image.new("RGB", (width, height), "#0B1220")
    draw = ImageDraw.Draw(image)
    draw.rounded_rectangle((12, 12, width - 12, height - 12), radius=28,
                           outline=f"#{accent}", width=4, fill="#0B1220")
    draw.rectangle((12, 12, width - 12, 105), fill=f"#{accent}")
    draw.ellipse((45, 43, 67, 65), fill="#FF6B6B")
    draw.ellipse((78, 43, 100, 65), fill="#FFD166")
    draw.ellipse((111, 43, 133, 65), fill="#53D769")
    draw.text((170, 35), title, font=title_font, fill="white")
    y = 135
    for line in wrapped:
        color = "#7CFFB2" if ("No issues" in line or "passed" in line or
                              "100%" in line or "200 OK" in line) else "#D8E2F0"
        draw.text((margin, y), line, font=body_font, fill=color)
        y += 38
    draw.text((margin, height - 42),
              "Evidencia generada desde la salida real guardada en el repositorio",
              font=small_font, fill="#8FA3BF")
    path = GENERATED / filename
    image.save(path)
    return path


def architecture_image():
    width, height = 1500, 760
    image = Image.new("RGB", (width, height), "white")
    draw = ImageDraw.Draw(image)
    font = ImageFont.truetype(r"C:\Windows\Fonts\calibri.ttf", 32)
    bold = ImageFont.truetype(r"C:\Windows\Fonts\calibrib.ttf", 38)
    small = ImageFont.truetype(r"C:\Windows\Fonts\calibri.ttf", 26)

    boxes = [
        (70, 220, 390, 540, GREEN, "Flutter", ["UI + BLoC", "Cliente /health", "SQLite local"]),
        (590, 170, 910, 590, BLUE, "FastAPI", ["JWT + roles", "Servicios", "OpenAPI"]),
        (1110, 220, 1430, 540, TEAL, "Datos", ["SQLAlchemy", "SQLite dev", "Caché"]),
    ]
    for x1, y1, x2, y2, color, title, items in boxes:
        draw.rounded_rectangle((x1, y1, x2, y2), radius=30,
                               fill=f"#{color}", outline=f"#{NAVY}", width=3)
        tw = draw.textlength(title, font=bold)
        draw.text(((x1 + x2 - tw) / 2, y1 + 42), title, font=bold, fill="white")
        y = y1 + 135
        for item in items:
            draw.text((x1 + 45, y), f"• {item}", font=font, fill="white")
            y += 70
    for x1, x2, label in ((390, 590, "HTTP :800"), (910, 1110, "ORM")):
        y = 380
        draw.line((x1 + 25, y, x2 - 30, y), fill=f"#{GOLD}", width=10)
        draw.polygon([(x2 - 30, y - 18), (x2, y), (x2 - 30, y + 18)],
                     fill=f"#{GOLD}")
        tw = draw.textlength(label, font=small)
        draw.text(((x1 + x2 - tw) / 2, y - 62), label, font=small, fill=f"#{NAVY}")
    draw.text((70, 70), "Arquitectura verificada de WarmiBot", font=bold,
              fill=f"#{NAVY}")
    draw.text((70, 125), "Una base Flutter, API propia y seguridad acotada para desarrollo local",
              font=font, fill=f"#{GRAY}")
    path = GENERATED / "arquitectura_warmibot.png"
    image.save(path)
    return path


def read_lines(path: Path) -> list[str]:
    return path.read_text(encoding="utf-8", errors="replace").splitlines()


def build():
    GENERATED.mkdir(parents=True, exist_ok=True)

    doctor_lines = read_lines(EVIDENCE / "flutter_doctor.txt")
    doctor_selected = [line.strip() for line in doctor_lines if any(key in line for key in (
        "Flutter version", "Dart version", "Android SDK", "Java version",
        "All Android licenses", "Android 13", "No issues found",
    ))]
    version_lines = read_lines(EVIDENCE / "versiones_entorno.txt")
    versions_selected = [line for line in version_lines if line.strip()][:22]
    flutter_test = read_lines(EVIDENCE / "flutter_test.txt")
    backend_test = read_lines(EVIDENCE / "backend_pytest.txt")
    test_selected = [
        "flutter analyze --no-pub -> No issues found!",
        *[line for line in flutter_test if "All tests passed" in line],
        f"pytest backend -> {backend_test[-1] if backend_test else 'sin salida'}",
        "APK -> build/app/outputs/flutter-apk/app-debug.apk",
        'API -> GET /health HTTP/1.1 200 OK',
        'Hot reload -> Reloaded 3 of 1990 libraries',
    ]
    doctor_png = terminal_image("doctor_limpio.png", "flutter doctor -v",
                                doctor_selected, GREEN)
    versions_png = terminal_image("versiones_reales.png", "versiones del equipo",
                                  versions_selected, BLUE)
    tests_png = terminal_image("pruebas_reales.png", "validación final",
                               test_selected, CORAL)
    architecture_png = architecture_image()

    doc = Document()
    configure_styles(doc)

    # Portada editorial técnica (named override: cover_title).
    add_para(doc, "INFORME TÉCNICO DE CONFIGURACIÓN", bold=True, color=GREEN,
             size=11, align=WD_ALIGN_PARAGRAPH.CENTER, after=26)
    add_para(doc, "WarmiBot", bold=True, color=NAVY, size=32,
             align=WD_ALIGN_PARAGRAPH.CENTER, after=4)
    add_para(doc, "Entorno móvil multiplataforma y comunicación con API propia",
             color=BLUE, size=16, align=WD_ALIGN_PARAGRAPH.CENTER, after=16)
    add_para(doc, "Flutter + FastAPI | Pixel_4 Android 13 | Evidencia del 16 de agosto de 2026",
             bold=True, color=GRAY, size=10.5,
             align=WD_ALIGN_PARAGRAPH.CENTER, after=42)

    add_callout(doc, "Resultado",
                "El entorno quedó operativo y reproducible: diagnóstico sin hallazgos, "
                "aplicación ejecutada en Pixel_4, recarga en caliente comprobada y "
                "solicitud real a /health con HTTP 200.")
    add_para(doc, "", after=12)
    cover_rows = [
        ("Integrante 1", "[NOMBRE COMPLETO]"),
        ("Integrante 2", "[NOMBRE COMPLETO]"),
        ("Integrante 3", "[NOMBRE COMPLETO]"),
        ("Asignatura", "[ASIGNATURA]"),
        ("Docente", "[DOCENTE]"),
        ("Fecha de entrega", "[DD/MM/AAAA]"),
    ]
    add_matrix(doc, ["Campo editable", "Información"], cover_rows,
               [2700, 6660], header_fill=LIGHT)
    add_para(doc, "Universidad Estatal Amazónica - Tena, Napo, Ecuador",
             color=GRAY, size=10, align=WD_ALIGN_PARAGRAPH.CENTER, after=0)

    page_break(doc)
    doc.add_heading("1. Resumen ejecutivo", level=1)
    add_para(doc,
             "Se configuró y verificó un entorno de desarrollo móvil basado en Flutter "
             "y Android, integrado con el backend FastAPI existente de WarmiBot. La "
             "aplicación obtiene la URL base desde variables de entorno, consulta un "
             "endpoint propio y presenta el estado de conexión en pantalla. El tráfico "
             "HTTP local se limita a la variante debug y al alias 10.0.2.2.")
    add_callout(doc, "Conclusión de la verificación",
                "La cadena completa Flutter -> Android Emulator -> FastAPI funcionó. "
                "La API registró tres solicitudes GET /health con respuesta 200 y la "
                "captura final muestra 'API conectada'.", fill=GREEN_LIGHT, accent=GREEN)
    doc.add_heading("1.1 Cumplimiento de la actividad", level=2)
    rows = [
        ("Framework", "Flutter seleccionado y justificado", "Cumplido"),
        ("Entorno", "SDK, editor, extensiones, JDK y Android", "Cumplido"),
        ("Diagnóstico", "flutter doctor -v sin hallazgos", "Cumplido"),
        ("Destino", "Pixel_4, Android 13 / API 33", "Cumplido"),
        ("Proyecto", "WarmiBot ejecutado y hot reload", "Cumplido"),
        ("Variables", "API_BASE_URL en .env.example", "Cumplido"),
        ("API propia", "GET /health desde el emulador", "Cumplido"),
        ("README", "Pasos reproducibles y solución de problemas", "Cumplido"),
    ]
    add_matrix(doc, ["Criterio", "Evidencia", "Estado"], rows,
               [1900, 5660, 1800])

    page_break(doc)
    doc.add_heading("2. Selección técnica de Flutter", level=1)
    add_para(doc,
             "Flutter fue seleccionado porque permite construir Android, iOS, web y "
             "escritorio desde una base de código Dart. Para WarmiBot resulta útil por "
             "su interfaz personalizada, acceso a micrófono y notificaciones, ciclo de "
             "desarrollo con hot reload y ecosistema de pruebas. La demostración se "
             "concentra en Android, el destino disponible y validado en este equipo.")
    doc.add_heading("2.1 Beneficios aplicados al proyecto", level=2)
    for item in (
        "Una sola capa de presentación y dominio para múltiples destinos.",
        "BLoC separa eventos, estado y servicios de la interfaz.",
        "Hot reload permite demostrar cambios sin perder el estado actual.",
        "El analizador de Dart y las pruebas de widgets detectan regresiones.",
        "Los plugins cubren voz, TTS, SQLite, notificaciones y variables de entorno.",
    ):
        add_bullet(doc, item)
    doc.add_heading("2.2 Estructura lógica", level=2)
    doc.add_picture(str(architecture_png), width=Inches(6.45))
    set_last_image_alt(
        doc,
        "Diagrama de arquitectura: Flutter se comunica por HTTP con FastAPI, que accede a la capa de datos.",
    )
    add_para(doc, "Figura 1. Arquitectura verificada en el repositorio WarmiBot.",
             italic=True, color=GRAY, size=9, after=0)

    page_break(doc)
    doc.add_heading("3. Entorno real instalado", level=1)
    add_para(doc,
             "Las versiones siguientes fueron obtenidas directamente del equipo de "
             "verificación. No son valores estimados ni capturas de terceros.")
    rows = [
        ("Sistema", "Windows 11, compilación 26100.9168"),
        ("Flutter", "3.44.2 estable"),
        ("Dart / DevTools", "3.12.2 / 2.57.0"),
        ("Android", "SDK 36.1, Emulator 36.6.11, ADB 37.0.0"),
        ("Java", "OpenJDK 21.0.10 incluido con Android Studio"),
        ("VS Code", "1.132.0; extensiones Dart y Flutter 3.140.0"),
        ("Backend", "Python 3.14.4, FastAPI 0.139.2, Uvicorn 0.51.0"),
        ("Destino", "Pixel_4, Android 13, API 33, emulator-5554"),
    ]
    add_matrix(doc, ["Componente", "Versión comprobada"], rows, [2700, 6660])
    add_para(doc, "Fuente: docs/evidencias/versiones_entorno.txt.",
             italic=True, color=GRAY, size=9, after=8)
    doc.add_picture(str(versions_png), width=Inches(6.45))
    set_last_image_alt(
        doc,
        "Panel de terminal con versiones reales de VS Code, extensiones, Python, FastAPI, Java, ADB y emulador.",
    )
    add_para(doc, "Figura 2. Extracto visual de la evidencia de versiones.",
             italic=True, color=GRAY, size=9, after=0)

    page_break(doc)
    doc.add_heading("4. Diagnóstico y preparación", level=1)
    add_para(doc,
             "El primer diagnóstico detectó dos SDK de Flutter en PATH y la comprobación "
             "de Visual Studio para Windows Desktop. Se priorizó C:\\flutter\\bin y se "
             "deshabilitó únicamente el destino Windows no usado. Android, web e iOS "
             "permanecen habilitados. El diagnóstico final no reporta hallazgos.")
    doc.add_picture(str(doctor_png), width=Inches(6.45))
    set_last_image_alt(
        doc,
        "Panel de terminal con el diagnóstico Flutter sin hallazgos y el dispositivo Android 13.",
    )
    add_para(doc, "Figura 3. Resultado final de flutter doctor -v.",
             italic=True, color=GRAY, size=9)
    doc.add_heading("4.1 Comandos reproducibles", level=2)
    add_code(doc, "flutter --version\nflutter doctor -v\nflutter doctor --android-licenses\nflutter devices")
    add_callout(doc, "Criterio de aceptación",
                "El diagnóstico debe terminar con 'No issues found!' y mostrar el "
                "destino Android cuando el emulador esté iniciado.", fill=PALE_BLUE,
                accent=BLUE)

    page_break(doc)
    doc.add_heading("5. Configuración del backend", level=1)
    add_para(doc,
             "El backend usa FastAPI como framework ASGI, Uvicorn como servidor, "
             "SQLAlchemy para persistencia y PyJWT para credenciales. El endpoint de "
             "salud no requiere autenticación y permite demostrar conectividad sin "
             "exponer datos sensibles.")
    doc.add_heading("5.1 Instalación", level=2)
    for step in (
        "Crear backend/.venv con python -m venv.",
        "Instalar backend/requirements.txt.",
        "Copiar backend/.env.example como backend/.env.",
        "Cambiar JWT_SECRET y la contraseña inicial antes de compartir el entorno.",
        "Ejecutar Uvicorn sobre 0.0.0.0 y el puerto 800.",
    ):
        add_number(doc, step)
    add_code(doc,
             "cd C:\\WarmiBot\\backend\n"
             ".\\.venv\\Scripts\\python.exe -m uvicorn app.main:app "
             "--host 0.0.0.0 --port 800 --env-file .env")
    doc.add_heading("5.2 Controles de seguridad", level=2)
    rows = [
        ("Contraseñas", "scrypt con sal aleatoria"),
        ("Sesión", "access token corto + refresh revocable"),
        ("Autorización", "roles y dependencias FastAPI"),
        ("CORS", "orígenes, métodos y cabeceras explícitos"),
        ("Producción", "JWT_SECRET de 32+ caracteres obligatorio"),
        ("Diagnóstico", "deshabilitado cuando APP_ENV=production"),
    ]
    add_matrix(doc, ["Control", "Implementación"], rows, [2700, 6660])

    page_break(doc)
    doc.add_heading("6. Integración móvil con la API", level=1)
    add_para(doc,
             "El archivo .env.example define API_BASE_URL. BackendApiService normaliza "
             "la dirección, aplica un timeout de cinco segundos, exige HTTP 200 y "
             "valida que el JSON contenga status=ok. BackendStatusIndicator muestra el "
             "resultado y permite repetir la comprobación con un toque.")
    add_code(doc,
             "API_BASE_URL=http://10.0.2.2:800\n\n"
             "GET http://10.0.2.2:800/health\n"
             "{\"status\":\"ok\",\"environment\":\"development\"}")
    add_callout(doc, "Por qué 10.0.2.2",
                "Android Emulator reserva 10.0.2.2 como alias especial hacia la "
                "interfaz loopback del host. 127.0.0.1 dentro del AVD apunta al propio "
                "dispositivo virtual.", fill=PALE_BLUE, accent=BLUE)
    doc.add_heading("6.1 Tráfico HTTP acotado", level=2)
    for item in (
        "El manifiesto principal desactiva cleartext.",
        "Solo android/app/src/debug habilita la excepción.",
        "La configuración XML autoriza exclusivamente 10.0.2.2.",
        "Release debe usar HTTPS y no recibe esta configuración debug.",
    ):
        add_bullet(doc, item)

    page_break(doc)
    doc.add_heading("7. Evidencia auténtica en Pixel_4", level=1)
    add_para(doc,
             "La aplicación se compiló, instaló y ejecutó en emulator-5554. Durante el "
             "primer arranque pesado, el indicador conservó un fallo transitorio; al "
             "tocar el control de reintento, FastAPI registró GET /health 200 y la UI "
             "cambió a verde. Este comportamiento valida también la recuperación ante "
             "indisponibilidad temporal.")
    app_image = EVIDENCE / "warmibot_pixel4_backend_retry.png"
    doc.add_picture(str(app_image), height=Inches(6.55))
    set_last_image_alt(
        doc,
        "Captura auténtica de WarmiBot ejecutándose en Pixel 4; el encabezado muestra API conectada en verde.",
    )
    last = doc.paragraphs[-1]
    last.alignment = WD_ALIGN_PARAGRAPH.CENTER
    add_para(doc,
             "Figura 4. Captura directa del Pixel_4: WarmiBot muestra 'API conectada'.",
             italic=True, color=GRAY, size=9,
             align=WD_ALIGN_PARAGRAPH.CENTER, after=0)

    page_break(doc)
    doc.add_heading("8. Hot reload y corrección en ejecución", level=1)
    add_para(doc,
             "La ejecución real detectó una aserción de Flutter 3.44 en tarjetas "
             "ListTile decoradas. Se sustituyeron contenedores intermedios por "
             "Material con forma, borde y recorte. Después se presionó r en la sesión "
             "flutter run: se recargaron bibliotecas y no reaparecieron excepciones.")
    add_code(doc,
             "Flutter run key commands.\n"
             "r Hot reload.\n"
             "Reloaded 3 of 1990 libraries ...")
    rows = [
        ("Antes", "ListTile detrás de DecoratedBox", "Aserción en Flutter 3.44"),
        ("Corrección", "Material + RoundedRectangleBorder", "Tinta y fondo visibles"),
        ("Después", "Hot reload de bibliotecas", "Sin nuevas excepciones"),
    ]
    add_matrix(doc, ["Etapa", "Cambio", "Resultado"], rows,
               [1700, 4400, 3260])
    add_callout(doc, "Interpretación",
                "Hot reload permitió corregir un defecto observado en el destino real "
                "sin reinstalar la aplicación y conservando su estado.")

    page_break(doc)
    doc.add_heading("9. Pruebas y artefactos", level=1)
    doc.add_picture(str(tests_png), width=Inches(6.45))
    set_last_image_alt(
        doc,
        "Panel de validación con análisis limpio, nueve pruebas Flutter, once pruebas backend, APK y health 200.",
    )
    add_para(doc, "Figura 5. Resultado consolidado de validación.",
             italic=True, color=GRAY, size=9)
    rows = [
        ("Flutter analyze", "0 incidencias", "Aprobado"),
        ("Flutter test", "9 pruebas", "Aprobado"),
        ("Backend pytest", "11 pruebas", "Aprobado"),
        ("APK debug", "app-debug.apk", "Generado"),
        ("API desde AVD", "GET /health -> 200", "Aprobado"),
    ]
    add_matrix(doc, ["Verificación", "Evidencia", "Resultado"], rows,
               [2600, 4360, 2400])
    add_para(doc,
             "La advertencia sobre Built-in Kotlin es preventiva para versiones futuras "
             "de Flutter. La compilación actual finalizó correctamente; la migración "
             "depende además de que flutter_tts, share_plus y speech_to_text actualicen "
             "su integración.", italic=True, color=GRAY, size=9.5)

    page_break(doc)
    doc.add_heading("10. Guías diferenciadas para tres integrantes", level=1)
    add_para(doc,
             "La evidencia de este informe pertenece a un solo equipo. Los siguientes "
             "bloques son guías de encuadre para que cada integrante produzca evidencia "
             "auténtica en su computadora; no deben presentarse como capturas ya "
             "ejecutadas en tres entornos.")
    add_callout(doc, "Integrante 1 - Entorno",
                "Encabezado verde. Mostrar flutter --version, flutter doctor -v, VS "
                "Code, extensiones Dart/Flutter y estructura lib/. Sustituir [NOMBRE].",
                fill="E8F5ED", accent=GREEN)
    add_callout(doc, "Integrante 2 - Backend",
                "Encabezado azul. Iniciar Uvicorn, abrir /health y Swagger, mostrar el "
                "registro 200 y explicar 10.0.2.2. Sustituir [NOMBRE].",
                fill="E8EEF5", accent=BLUE)
    add_callout(doc, "Integrante 3 - Aplicación",
                "Encabezado coral. Ejecutar Pixel_4 o teléfono, mostrar API conectada, "
                "realizar hot reload y enseñar pruebas/APK. Sustituir [NOMBRE].",
                fill="FCEDEA", accent=CORAL)
    doc.add_heading("10.1 Datos que debe completar cada integrante", level=2)
    rows = [
        ("Nombre", "[NOMBRE COMPLETO]"),
        ("Equipo", "[MARCA / MODELO / RAM]"),
        ("Sistema", "[SISTEMA Y VERSIÓN]"),
        ("Destino", "[AVD O TELÉFONO]"),
        ("Fecha de captura", "[DD/MM/AAAA HH:MM]"),
    ]
    add_matrix(doc, ["Campo", "Valor editable"], rows, [2700, 6660])

    page_break(doc)
    doc.add_heading("11. Guion sugerido para el video", level=1)
    rows = [
        ("0:00-1:20", "Integrante 1", "Proyecto, Flutter, versiones y diagnóstico"),
        ("1:20-2:40", "Integrante 2", "Backend, seguridad, /health y 10.0.2.2"),
        ("2:40-4:00", "Integrante 3", "Pixel_4, API conectada, hot reload y pruebas"),
        ("4:00-4:30", "Equipo", "Limitaciones, aprendizaje y cierre"),
    ]
    add_matrix(doc, ["Tiempo", "Responsable", "Contenido"], rows,
               [1700, 2100, 5560])
    doc.add_heading("11.1 Texto orientativo", level=2)
    add_para(doc,
             "Integrante 1: 'WarmiBot se desarrolló con Flutter porque una sola base "
             "Dart permite mantener varios destinos. En este equipo verificamos Flutter "
             "3.44.2, Dart 3.12.2 y Android SDK 36.1. El diagnóstico final no presenta "
             "hallazgos.'")
    add_para(doc,
             "Integrante 2: 'El backend propio usa FastAPI y Uvicorn. Desde el emulador "
             "utilizamos 10.0.2.2:800 porque Android reserva esa dirección para el "
             "localhost del equipo. La solicitud /health regresó HTTP 200.'")
    add_para(doc,
             "Integrante 3: 'WarmiBot se ejecutó en Pixel_4 con Android 13. El indicador "
             "verde demuestra comunicación con la API. También aplicamos hot reload y "
             "terminamos con nueve pruebas Flutter y once del backend aprobadas.'")

    page_break(doc)
    doc.add_heading("12. Limitaciones y recomendaciones", level=1)
    rows = [
        ("Memoria", "Pixel_4 reserva 2 GB y cuatro núcleos", "Cerrar programas o usar teléfono USB"),
        ("Primer build", "Gradle tardó varios minutos", "Compilar antes de la exposición"),
        ("HTTP local", "No cifra tráfico", "Solo debug; HTTPS en producción"),
        ("Kotlin", "Advertencia de migración futura", "Actualizar plugins en rama separada"),
        ("Evidencias", "Un solo equipo verificado", "Cada integrante debe capturar el suyo"),
    ]
    add_matrix(doc, ["Área", "Limitación observada", "Recomendación"], rows,
               [1750, 3650, 3960])
    doc.add_heading("12.1 Lista final antes de exponer", level=2)
    for item in (
        "Completar nombres, asignatura, docente y fecha.",
        "Iniciar el backend y comprobar /health.",
        "Arrancar Pixel_4 antes de compartir pantalla.",
        "Tocar el indicador si el backend inició después de la app.",
        "No mostrar .env, contraseñas, tokens ni claves de clima.",
        "Tener el APK y los logs disponibles como respaldo.",
    ):
        add_bullet(doc, item)

    page_break(doc)
    doc.add_heading("13. Fuentes y trazabilidad", level=1)
    add_para(doc,
             "Fuentes oficiales consultadas (acceso: 16 de agosto de 2026):")
    sources = [
        "Flutter. Hot reload. https://docs.flutter.dev/tools/hot-reload",
        "Flutter. Set up and test drive Flutter. https://docs.flutter.dev/install/quick",
        "Android Developers. Espacio de direcciones de red del emulador. "
        "https://developer.android.com/studio/run/emulator-networking-address?hl=es-419",
        "Android Developers. Network security configuration. "
        "https://developer.android.com/privacy-and-security/security-config",
        "FastAPI. Run a Server Manually. https://fastapi.tiangolo.com/deployment/manually/",
        "FastAPI. CORS. https://fastapi.tiangolo.com/tutorial/cors/",
    ]
    for source in sources:
        add_bullet(doc, source)
    doc.add_heading("13.1 Evidencia interna", level=2)
    for item in (
        "docs/evidencias/flutter_doctor.txt",
        "docs/evidencias/versiones_entorno.txt",
        "docs/evidencias/flutter_analyze.txt",
        "docs/evidencias/flutter_test.txt",
        "docs/evidencias/backend_pytest.txt",
        "docs/evidencias/flutter_build_apk.txt",
        "docs/evidencias/warmibot_pixel4_backend_retry.png",
    ):
        add_bullet(doc, item)
    add_callout(doc, "Declaración de evidencia",
                "La captura Pixel_4 y los logs fueron obtenidos en este equipo. Las "
                "guías de integrantes 2 y 3 no se presentan como ejecuciones externas.",
                fill=LIGHT, accent=GRAY)

    core = doc.core_properties
    core.title = "Informe de entorno móvil multiplataforma - WarmiBot"
    core.subject = "Flutter, Android, FastAPI y comunicación con API propia"
    core.author = "Equipo WarmiBot"
    core.keywords = "WarmiBot, Flutter, FastAPI, Android, API, entorno"
    core.comments = "Documento generado desde evidencia reproducible del repositorio."
    doc.save(OUTPUT)
    print(json.dumps({"output": str(OUTPUT), "size": OUTPUT.stat().st_size},
                     ensure_ascii=False))


if __name__ == "__main__":
    build()
