"""Render every PDF page to a PNG for visual QA."""

from pathlib import Path
import sys

import pypdfium2 as pdfium


def main() -> None:
    if len(sys.argv) != 3:
        raise SystemExit("Usage: render_pdf_pages.py INPUT.pdf OUTPUT_DIR")

    input_pdf = Path(sys.argv[1]).resolve()
    output_dir = Path(sys.argv[2]).resolve()
    output_dir.mkdir(parents=True, exist_ok=True)

    document = pdfium.PdfDocument(input_pdf)
    for index, page in enumerate(document, start=1):
        bitmap = page.render(scale=2.0)
        bitmap.to_pil().save(output_dir / f"page-{index:02d}.png")

    print(f"Rendered {len(document)} pages into {output_dir}")


if __name__ == "__main__":
    main()
