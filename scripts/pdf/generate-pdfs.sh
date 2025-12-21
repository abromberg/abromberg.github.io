#!/bin/bash

# generate-pdfs.sh
# Generates academic-style PDFs for posts with `academic_pdf: true` in frontmatter

set -e

# Add MacTeX to PATH if installed (common macOS location)
if [ -d "/Library/TeX/texbin" ]; then
  export PATH="/Library/TeX/texbin:$PATH"
fi

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT_DIR="$(cd "$SCRIPT_DIR/../.." && pwd)"
TEMPLATE="$SCRIPT_DIR/academic-template.tex"
OUTPUT_DIR="$ROOT_DIR/assets/pdf/posts"
PREPROCESSOR="$SCRIPT_DIR/preprocess-markdown.sh"

# Create output directory
mkdir -p "$OUTPUT_DIR"

echo "🔍 Scanning for posts with academic_pdf: true..."

# Function to check if a file has academic_pdf: true
has_academic_pdf() {
  local file="$1"
  # Check frontmatter for academic_pdf: true
  awk '/^---$/{if(++c==2)exit} c==1' "$file" | grep -q "^academic_pdf:\s*true"
}

# Function to extract frontmatter value
get_frontmatter() {
  local file="$1"
  local key="$2"
  awk '/^---$/{if(++c==2)exit} c==1' "$file" | grep "^${key}:" | sed "s/^${key}:\s*//" | sed 's/^"//' | sed 's/"$//' | sed "s/^'//" | sed "s/'$//"
}

# Function to generate PDF from markdown
generate_pdf() {
  local input_file="$1"
  local filename=$(basename "$input_file" .md)
  filename=$(basename "$filename" .markdown)
  
  # Remove date prefix if present (e.g., 2024-11-23-)
  local clean_name=$(echo "$filename" | sed 's/^[0-9]\{4\}-[0-9]\{2\}-[0-9]\{2\}-//')
  local output_file="$OUTPUT_DIR/${clean_name}.pdf"
  
  echo "📄 Processing: $input_file"
  echo "   → Output: $output_file"
  
  # Extract metadata from frontmatter
  local title=$(get_frontmatter "$input_file" "title" | sed 's/^[[:space:]]*//' | sed 's/^["'\'']//' | sed 's/["'\'']$//')
  local date=$(get_frontmatter "$input_file" "date" | cut -d' ' -f1)
  local description=$(get_frontmatter "$input_file" "description")
  
  # Get permalink for the footer
  local permalink=$(get_frontmatter "$input_file" "permalink" | sed 's/^[[:space:]]*//')
  local post_url="https://andybromberg.com${permalink}"
  
  echo "   Title: $title"
  echo "   URL: $post_url"
  
  # Create a temp file with preprocessed content
  local temp_file=$(mktemp)
  
  # Preprocess: 
  # 1. Remove Jekyll-specific liquid tags
  # 2. Fix image paths
  # 3. Remove TK notes (draft markers)
  # 4. Convert markdown tables to simple description lists (avoids longtable issues)
  cat "$input_file" | \
    # FIRST: Convert Jekyll picture tags to markdown images (before removing other liquid tags)
    # Format: {% picture preset path/to/image.png %} -> ![](full/path/to/image.png)
    sed "s|{%[[:space:]]*picture[[:space:]][[:space:]]*[a-z]*[[:space:]][[:space:]]*\([^[:space:]%}]*\)[[:space:]]*%}|![](${ROOT_DIR}/assets/images/\1)|g" | \
    # Convert sidenotes to footnotes
    # Pattern: <label for="sn-X"...><input...><span class="sidenote">CONTENT</span>
    # Becomes: [^sn-X] and later [^sn-X]: CONTENT
    perl -0777 -pe '
      # Extract all sidenotes and build footnote definitions
      my @footnotes;
      while (/<label[^>]*for="([^"]+)"[^>]*class="[^"]*sidenote-number[^"]*"[^>]*><\/label><input[^>]*><span[^>]*class="[^"]*sidenote[^"]*"[^>]*>(.*?)<\/span>/gs) {
        push @footnotes, "[^$1]: $2\n";
      }
      # Replace sidenote HTML with footnote references
      s/<label[^>]*for="([^"]+)"[^>]*class="[^"]*sidenote-number[^"]*"[^>]*><\/label><input[^>]*><span[^>]*class="[^"]*sidenote[^"]*"[^>]*>.*?<\/span>/[^$1]/gs;
      # Append footnote definitions at the end
      $_ .= "\n\n" . join("", @footnotes) if @footnotes;
    ' | \
    # Remove remaining liquid tags on their own line
    sed '/^{%.*%}$/d' | \
    # Remove remaining inline liquid tags
    sed 's/{%[^%]*%}//g' | \
    # Remove TK notes in brackets
    sed 's/\[TK[^\]]*\]//g' | \
    # Fix relative image paths to absolute
    sed "s|](/assets/|](${ROOT_DIR}/assets/|g" | \
    sed "s|](assets/|](${ROOT_DIR}/assets/|g" | \
    # Remove table separator rows (|--|--|)
    sed '/^|[-: |]*$/d' | \
    # Convert table rows to bullet points: | A | B | -> - **A**: B
    sed 's/^| *\([^|]*[^ |]\) *| *\([^|]*[^ |]\) *| *$/- **\1**: \2/' \
    > "$temp_file"
  
  # Run pandoc
  pandoc "$temp_file" \
    --from=markdown+yaml_metadata_block-pipe_tables-simple_tables-multiline_tables-grid_tables \
    --to=latex \
    --output="$output_file" \
    --template="$TEMPLATE" \
    --pdf-engine=xelatex \
    --variable=title:"$title" \
    --variable=date:"$date" \
    --variable=posturl:"$post_url" \
    --shift-heading-level-by=-1 \
    --number-sections \
    --standalone \
    2>&1 || {
      echo "   ⚠️  Warning: PDF generation had issues, continuing..."
    }
  
  # Cleanup
  rm -f "$temp_file"
  
  if [ -f "$output_file" ]; then
    echo "   ✅ Generated: $output_file"
  else
    echo "   ❌ Failed to generate PDF"
  fi
}

# Count of processed files
count=0

# Process _posts
for file in "$ROOT_DIR"/_posts/*.md "$ROOT_DIR"/_posts/*.markdown; do
  [ -f "$file" ] || continue
  if has_academic_pdf "$file"; then
    generate_pdf "$file"
    ((count++))
  fi
done

# Process _drafts (for testing)
for file in "$ROOT_DIR"/_drafts/*.md "$ROOT_DIR"/_drafts/*.markdown; do
  [ -f "$file" ] || continue
  if has_academic_pdf "$file"; then
    generate_pdf "$file"
    ((count++))
  fi
done

echo ""
echo "✨ Done! Generated $count PDF(s)"

