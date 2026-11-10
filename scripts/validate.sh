#!/bin/bash

# Simple Terraform Module Validation Script
# This script validates the Terraform module structure and runs tests

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Track if any errors occur
ERRORS=0

print_success() {
    echo -e "${GREEN}✓${NC} $1"
}

print_error() {
    echo -e "${RED}✗${NC} $1"
    ERRORS=$((ERRORS + 1))
}

print_info() {
    echo -e "${YELLOW}ℹ${NC} $1"
}

# Check if Terraform is installed
if ! command -v terraform &> /dev/null; then
    print_error "Terraform is not installed"
    exit 1
fi
TERRAFORM_VERSION=$(terraform version -json 2>/dev/null | grep -o '"terraform_version":"[^"]*' | cut -d'"' -f4 || terraform version | head -1)
print_success "Terraform found: $TERRAFORM_VERSION"

echo ""
print_info "Checking required files..."

# Check required files in root
REQUIRED_FILES=("versions.tf" "variables.tf" "output.tf" "README.md" "LICENSE")
for file in "${REQUIRED_FILES[@]}"; do
    if [ -f "$file" ]; then
        print_success "Found: $file"
    else
        print_error "Missing: $file"
    fi
done

echo ""
print_info "Validating root module..."

# Format check
if terraform fmt -check -recursive . &> /dev/null; then
    print_success "Formatting is correct"
else
    print_error "Formatting issues found (run 'terraform fmt -recursive .' to fix)"
fi

# The module requires an aliased provider (aws.us_east_1), so it is validated
# through the example that wires the providers
for example in examples/*/; do
    EXAMPLE_NAME=$(basename "$example")
    if (cd "$example" && terraform init -backend=false -input=false &> /dev/null && terraform validate &> /dev/null); then
        print_success "Validation passed (examples/$EXAMPLE_NAME)"
    else
        print_error "Validation failed (examples/$EXAMPLE_NAME)"
        (cd "$example" && terraform init -backend=false -input=false && terraform validate)
    fi
done

echo ""
print_info "Validating submodules..."

# Check each submodule under modules/
if [ -d "modules" ]; then
    for submodule in modules/*/; do
        if [ -d "$submodule" ]; then
            MODULE_NAME=$(basename "$submodule")
            print_info "  Checking $MODULE_NAME..."
            
            if terraform fmt -check -recursive "$submodule" &> /dev/null; then
                print_success "    Formatting is correct"
            else
                print_error "    Formatting issues found"
            fi
            
            if (cd "$submodule" && terraform init -backend=false -input=false &> /dev/null && terraform validate &> /dev/null); then
                print_success "    Validation passed"
            else
                print_error "    Validation failed"
                (cd "$submodule" && terraform init -backend=false -input=false && terraform validate)
            fi
        fi
    done
else
    print_info "  No modules directory found"
fi

echo ""
print_info "Running tests..."

# Run Terraform tests if test files exist
if [ -d "tests" ] && [ -n "$(find tests -name '*.tftest.hcl' 2>/dev/null)" ]; then
    if terraform test &> /dev/null; then
        print_success "All tests passed"
    else
        print_error "Some tests failed"
        terraform test
    fi
else
    print_info "No test files found in tests/ directory"
fi

echo ""
echo "=========================================="
if [ $ERRORS -eq 0 ]; then
    echo -e "${GREEN}All checks passed!${NC}"
    echo "=========================================="
    exit 0
else
    echo -e "${RED}Found $ERRORS error(s)${NC}"
    echo "=========================================="
    exit 1
fi
