#!/bin/bash

# Build Jekyll site first to ensure fonts are available
bundle exec jekyll build

# Generate OG images
cd scripts/og-image
npm install
npm run generate
cd ../..

# Build Jekyll site again to include the generated OG images
bundle exec jekyll build 