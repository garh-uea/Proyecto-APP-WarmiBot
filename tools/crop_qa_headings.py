"""Create enlarged heading crops for the Word-render QA pass."""

from pathlib import Path
from PIL import Image


ROOT = Path(r"C:\WarmiBot\docs\qa_informe\pages")
for page_number in (12, 14):
    source = Image.open(ROOT / f"page-{page_number:02d}.png")
    crop = source.crop((100, 100, 1150, 300))
    crop.resize((2100, 400)).save(ROOT / f"heading-{page_number:02d}.png")

EXPO_ROOT = Path(r"C:\WarmiBot\docs\qa_exposicion\pages_final")
for page_number in (5, 7):
    source = Image.open(EXPO_ROOT / f"page-{page_number:02d}.png")
    crop = source.crop((90, 35, 1170, 255))
    crop.resize((2160, 440)).save(EXPO_ROOT / f"heading-{page_number:02d}.png")
