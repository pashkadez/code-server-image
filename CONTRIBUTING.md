# Contributing to Code-Server Image

Thank you for your interest in contributing to this project! This document provides guidelines for contributing.

## How to Contribute

### Reporting Issues

If you find a bug or have a suggestion:

1. Check if the issue already exists in [GitHub Issues](https://github.com/pashkadez/code-server-image/issues)
2. If not, create a new issue with:
   - Clear description of the problem or suggestion
   - Steps to reproduce (for bugs)
   - Your environment details (OS, Docker version, deployment method)
   - Relevant logs or error messages

### Submitting Changes

1. Fork the repository
2. Create a feature branch: `git checkout -b feature/your-feature-name`
3. Make your changes
4. Test your changes thoroughly:
   - Build the Docker image locally
   - Test with Docker, Docker Compose, and/or Kubernetes
   - Verify VSC marketplace functionality
5. Commit your changes with clear commit messages
6. Push to your fork: `git push origin feature/your-feature-name`
7. Create a Pull Request

### Testing Your Changes

Before submitting a PR, please test:

1. **Docker Build**: Ensure the image builds successfully
   ```bash
   docker build -t code-server-test .
   ```

2. **Docker Run**: Test the container runs properly
   ```bash
   docker run -d -p 8080:8080 -e PASSWORD=test code-server-test
   ```

3. **VSC Marketplace**: Verify you can install extensions
   - Access http://localhost:8080
   - Try installing an extension from the VSC marketplace
   - Verify GitHub Copilot can be installed (if you have access)

4. **Docker Compose**: Test with docker-compose
   ```bash
   docker compose -f docker-compose.local.yml up -d
   ```

5. **Documentation**: Update README.md if you add new features

### Code Style

- Use clear, descriptive variable names
- Add comments for complex configurations
- Follow existing code formatting
- Keep Dockerfile instructions organized and well-commented

### Pull Request Guidelines

- Provide a clear description of the changes
- Reference any related issues
- Include test results if applicable
- Update documentation as needed
- Keep changes focused and minimal

## Development Setup

1. Clone the repository:
   ```bash
   git clone https://github.com/pashkadez/code-server-image.git
   cd code-server-image
   ```

2. Build and test locally:
   ```bash
   docker build -t code-server-dev .
   docker run -d -p 8080:8080 -e PASSWORD=dev code-server-dev
   ```

3. Make changes and rebuild:
   ```bash
   docker build --no-cache -t code-server-dev .
   ```

## Questions?

If you have questions about contributing, feel free to:
- Open a GitHub issue
- Start a discussion in GitHub Discussions

Thank you for contributing! 🎉
