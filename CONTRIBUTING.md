# Contributing to Eksilik

Thank you for your interest in contributing!

## Getting Started

1. Fork the repository
2. Create a feature branch: `git checkout -b feature/my-feature`
3. Make your changes
4. Run tests: `Cmd+U` in Xcode
5. Commit your changes with a descriptive message
6. Push and open a Pull Request

## Guidelines

- Follow existing code style and MVVM architecture
- Add unit tests for new parsers and services
- Keep views small and focused
- Use English for all code, comments, and documentation
- Do not add analytics, tracking, or advertising SDKs
- Do not commit secrets or API keys

## Reporting Issues

Open an issue on GitHub with:
- Steps to reproduce
- Expected behavior
- Actual behavior
- iOS version and device

## Architecture Notes

- **Parsers** extract data from HTML using CSS selectors (Kanna). If eksisozluk.com changes their markup, parsers need updating.
- **Services** handle network requests and call parsers.
- **ViewModels** are `@MainActor` and use `async/await`.
- **Views** use `@EnvironmentObject` for shared state (theme, session, preferences).
