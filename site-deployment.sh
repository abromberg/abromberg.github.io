#!/bin/bash

set -e

handle_error() {
    echo "Error: $1"
    exit 1
}

cd "$(git rev-parse --show-toplevel)"
mkdir -p ../andybrombergcom_build
bundle exec jekyll build -d ../andybrombergcom_build || handle_error "Jekyll build failed"
if ! git checkout gh-pages 2>/dev/null; then
    handle_error "Unable to switch to gh-pages branch. Please resolve any conflicts and try again."
fi
git rm -rf .
cp -r ../andybrombergcom_build/* .
git add .
git commit -m "Deploy site $(date)"
git push origin gh-pages
rm -rf _site
git checkout master
echo "Deployment complete"
