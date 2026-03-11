"""
Resume PDF parsing service.
"""
import io
import logging

logger = logging.getLogger(__name__)


def parse_pdf_text(pdf_bytes: bytes) -> str:
    """
    Extracts plain text from a PDF file given as bytes.
    Returns empty string on failure.
    """
    try:
        import PyPDF2

        reader = PyPDF2.PdfReader(io.BytesIO(pdf_bytes))
        pages = []
        for page in reader.pages:
            text = page.extract_text()
            if text:
                pages.append(text.strip())
        return "\n\n".join(pages)
    except Exception as e:
        logger.error(f"PDF parsing failed: {e}")
        return ""
