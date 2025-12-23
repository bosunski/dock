# Contributing to Dock

Thank you for considering contributing to this project!

## Adding a New Service

1. Create a new directory under `services/` with your service name
2. Include either a `docker-compose.yml` or `Dockerfile`
3. Add a README.md explaining your service
4. Include example configuration files (`.env.example`)
5. Test the service locally before submitting

## Improving Infrastructure

1. Make changes to Ansible roles in `infra/roles/`
2. Test changes on a staging environment first
3. Document any new variables or requirements
4. Update the main README if adding new features

## Workflow Improvements

1. Propose changes to GitHub Actions workflows
2. Explain the benefit and use case
3. Ensure backward compatibility when possible

## Pull Request Process

1. Fork the repository
2. Create a feature branch
3. Make your changes with clear commit messages
4. Test your changes
5. Submit a pull request with a clear description

## Code Style

- Use consistent formatting
- Add comments for complex logic
- Follow best practices for Docker and Ansible
- Keep security in mind

## Questions?

Open an issue for discussion before making major changes.
