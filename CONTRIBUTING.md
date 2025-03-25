# Contributing to IconInk

Thank you for your interest in contributing to IconInk! This document provides guidelines and instructions for contributing to this project.

## Table of Contents

- [Code of Conduct](#code-of-conduct)
- [Getting Started](#getting-started)
- [Development Environment](#development-environment)
- [Pull Request Process](#pull-request-process)
- [Coding Standards](#coding-standards)
- [Testing Guidelines](#testing-guidelines)
- [Documentation](#documentation)
- [Issue Reporting](#issue-reporting)

## Code of Conduct

This project adheres to our Code of Conduct. By participating, you are expected to uphold this code. Please report unacceptable behavior to the project maintainers.

## Getting Started

1. Fork the repository
2. Clone your fork locally:
   ```
   git clone https://github.com/your-username/iconink.git
   cd iconink
   ```
3. Add the upstream repository as a remote:
   ```
   git remote add upstream https://github.com/fleXRPL/iconink.git
   ```
4. Create a branch for your work:
   ```
   git checkout -b feature/your-feature-name
   ```

## Development Environment

### Requirements

- Xcode 16.2 or later
- iOS 17.0 SDK or later
- Swift 5.9+

### Setup

1. Open the project in Xcode:

   ```
   open iconink/iconink.xcodeproj
   ```

2. Build and run the application on your device or simulator

## Pull Request Process

1. Update your fork with the latest upstream changes:

   ```
   git fetch upstream
   git rebase upstream/main
   ```

2. Ensure your code follows the project's coding standards and passes all tests

3. Update documentation if necessary, including inline code comments and README updates

4. Submit a pull request with a clear title and description:

   - Include the purpose of the PR
   - Reference any related issues (e.g., "Fixes #123")
   - Provide steps to test your changes

5. Respond to any code review feedback

## Coding Standards

- Follow Swift API Design Guidelines
- Adhere to the SwiftLint rules set up in the project
- Write self-documenting code with clear variable and function names
- Include documentation comments for public APIs
- Follow MVVM architecture pattern

### Specific Guidelines

- Avoid force unwrapping (`!`) unless absolutely necessary
- Use property wrappers appropriately for SwiftUI integration
- Use dependency injection for better testability
- Keep view files under 300 lines of code when possible
- Separate business logic from view code

## Testing Guidelines

- Write unit tests for all business logic
- Ensure UI tests for critical user flows
- Test edge cases and error conditions
- All tests must pass before submitting a PR
- Aim for good test coverage of new code

## Documentation

- Use documentation comments (`///`) for all public APIs
- Keep code comments current with code changes
- Update the README if your changes affect setup or usage
- Document architectural decisions in the Wiki

## Issue Reporting

When reporting issues, please include:

1. A clear and descriptive title
2. Steps to reproduce the issue
3. Expected behavior and actual behavior
4. Screenshots if applicable
5. Device/simulator information and OS version
6. Any relevant logs or error messages

---

Thank you for contributing to IconInk! Your efforts help make this project better for everyone.
