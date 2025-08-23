#!/bin/bash

# BuddyPress Test Runner

COMMAND=$1
COMPONENT=$2

case "$COMMAND" in
    all)
        echo "Running all BuddyPress tests..."
        vendor/bin/phpunit
        ;;
    unit)
        echo "Running unit tests..."
        vendor/bin/phpunit --testsuite "BuddyPress Unit Tests"
        ;;
    integration)
        echo "Running integration tests..."
        vendor/bin/phpunit --testsuite "BuddyPress Integration Tests"
        ;;
    security)
        echo "Running security tests..."
        vendor/bin/phpunit --testsuite "BuddyPress Security Tests"
        ;;
    component)
        if [ -z "$COMPONENT" ]; then
            echo "Please specify a component name"
            exit 1
        fi
        echo "Running tests for component: $COMPONENT"
        vendor/bin/phpunit unit/Components/$COMPONENT
        vendor/bin/phpunit integration/Components/$COMPONENT
        ;;
    *)
        echo "Usage: $0 {all|unit|integration|security|component <name>}"
        exit 1
        ;;
esac