# Copilot Instructions

## Worktree Overview
This worktree contains developer runtime tooling for a toolbox container.
The container is designed to be built via GitHub Actions.
The resulting container image is pushed to GitHub Container Registry.

## Code Style and Standards
- Follow existing patterns in the codebase
- Use clear, descriptive variable names
- Add comments for complex logic
- Maintain consistency with existing file structure

## Development Workflow
- Make minimal, focused changes
- Use the provided Makefile for build processes
- The build results in container images pushed to GitHub Container Registry
- The build is not intended to run locally but via GitHub Actions

## Key Files and Directories
- `Makefile` - Build and deployment scripts
- `.github/workflows/` - CI/CD pipeline configurations
- Container runtime configurations and toolbox setup files

## Testing and Validation
- Verify container builds successfully using GitHub Actions
- Check runtime binaries are present in the container with simple `--version` commands
- Ensure no build errors in GitHub Actions logs
- Validate that the container image is available in GitHub Container Registry
- Ensure the README.md file is updated with new binaries and versions

## Deployment
- Container images are published to GitHub Container Registry

## Documentation
- The README.md file is generated as part of the build process
- All runtime tooling binaries added to the container should be in the README.md file
- Detail of each binary will include table fields:
  - Binary name
  - Version
  - Description
 <!-- Link to official documentation -->
- Update documentation when adding new features or changing workflows

## Notes
This file can be customized to include project-specific requirements and development guidelines.
