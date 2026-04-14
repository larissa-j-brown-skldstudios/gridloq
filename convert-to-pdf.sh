#!/bin/bash

echo "Resume PDF Conversion Script"
echo "============================"
echo ""

# Check if wkhtmltopdf is installed
if command -v wkhtmltopdf &> /dev/null; then
    echo "Converting resume.html to PDF using wkhtmltopdf..."
    wkhtmltopdf --page-size A4 --margin-top 0.5in --margin-bottom 0.5in --margin-left 0.5in --margin-right 0.5in resume.html Larissa_Brown_Resume.pdf
    echo "✅ PDF created: Larissa_Brown_Resume.pdf"
elif command -v weasyprint &> /dev/null; then
    echo "Converting resume.html to PDF using weasyprint..."
    weasyprint resume.html Larissa_Brown_Resume.pdf
    echo "✅ PDF created: Larissa_Brown_Resume.pdf"
elif command -v pandoc &> /dev/null; then
    echo "Converting resume.md to PDF using pandoc..."
    pandoc resume.md -o Larissa_Brown_Resume.pdf --pdf-engine=wkhtmltopdf
    echo "✅ PDF created: Larissa_Brown_Resume.pdf"
else
    echo "❌ No PDF conversion tools found."
    echo ""
    echo "To convert to PDF, you can:"
    echo "1. Install wkhtmltopdf: brew install wkhtmltopdf (macOS) or apt-get install wkhtmltopdf (Ubuntu)"
    echo "2. Install weasyprint: pip install weasyprint"
    echo "3. Install pandoc: brew install pandoc (macOS) or apt-get install pandoc (Ubuntu)"
    echo ""
    echo "Alternatively, you can:"
    echo "1. Open resume.html in a web browser"
    echo "2. Use Ctrl+P (or Cmd+P on Mac) to print"
    echo "3. Select 'Save as PDF' as the destination"
    echo "4. Save the file as 'Larissa_Brown_Resume.pdf'"
fi

echo ""
echo "Files created:"
echo "- resume.md (Markdown version)"
echo "- resume.html (HTML version with styling)"
echo "- resume-styles.css (CSS styling)"
echo "- convert-to-pdf.sh (this script)" 