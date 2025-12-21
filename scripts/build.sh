#!/bin/bash

# Build Jekyll site first to ensure fonts are available
bundle exec jekyll build

# Generate OG images
cd scripts/og-image
npm install
npm run generate
cd ../..

# Generate academic PDFs for posts with academic_pdf: true
# Requires: pandoc, xelatex (from texlive or mactex)
if command -v pandoc &> /dev/null && command -v xelatex &> /dev/null; then
  echo "📚 Generating academic PDFs..."
  ./scripts/pdf/generate-pdfs.sh
else
  echo "⚠️  Skipping PDF generation (pandoc and/or xelatex not found)"
  echo "   Install with: brew install pandoc && brew install --cask mactex"
fi

# Build Jekyll site again to include the generated OG images and PDFs
bundle exec jekyll build 