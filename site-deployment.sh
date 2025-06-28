#!/bin/bash

set -e

handle_error() {
    echo "Error: $1"
    exit 1
}

GIT_ROOT="$(git rev-parse --show-toplevel)"
cd "$GIT_ROOT"
sleep 20
mkdir -p ../andybrombergcom_build
./scripts/build.sh
JEKYLL_ENV=production bundle exec jekyll build -d ../andybrombergcom_build || handle_error "Jekyll build failed"
cd ../andybrombergcom_build
git add .
git commit -m "Deploy site $(date)"
git push origin gh-pages || handle_error "Git push failed"
cd "$GIT_ROOT"
echo "Deployment complete"