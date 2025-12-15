# Contributing to Congress API Ingestion System

Thank you for your interest in contributing to the Congress API Ingestion System! This document provides guidelines and instructions for contributing.

## Code of Conduct

- Be respectful and inclusive
- Provide constructive feedback
- Focus on what's best for the community
- Accept responsibility and apologize for mistakes

## How to Contribute

### Reporting Bugs

1. Check if the bug has already been reported in Issues
2. Create a new issue with:
   - Clear, descriptive title
   - Steps to reproduce
   - Expected vs actual behavior
   - Environment details (OS, Python version, etc.)
   - Error messages or logs

### Suggesting Features

1. Check if the feature has already been requested
2. Create a new issue with:
   - Clear description of the feature
   - Use case and benefits
   - Proposed implementation (if you have ideas)

### Submitting Pull Requests

1. **Fork the repository**
2. **Create a feature branch**: `git checkout -b feature/amazing-feature`
3. **Make your changes** following the coding standards below
4. **Add tests** for new functionality
5. **Ensure tests pass**: `python -m pytest tests/ -v`
6. **Update documentation** if needed
7. **Commit your changes**: `git commit -m 'Add amazing feature'`
8. **Push to the branch**: `git push origin feature/amazing-feature`
9. **Open a Pull Request**

## Development Setup

### Prerequisites

- Python 3.11 or higher
- PostgreSQL 13+ (for production)
- Git

### Installation

```bash
git clone https://github.com/cbwinslow/congress-api-ingestion.git
cd congress-api-ingestion
python -m venv venv
source venv/bin/activate  # On Windows: venv\Scripts\activate
pip install -r requirements.txt
```

### Configuration

```bash
cp config/config.example.json config/config.json
# Edit config.json with your API keys and database settings
```

### Database Setup

```bash
# For development (SQLite)
python main.py --setup-db

# For production (PostgreSQL)
./scripts/database_setup.sh
```

## Coding Standards

### Python Code Style

- Follow PEP 8 guidelines
- Use type hints for function parameters and return values
- Write docstrings for all public functions and classes
- Keep line length under 100 characters
- Use meaningful variable and function names

### Example

```python
def fetch_collection_data(collection_code: str, offset: int = 0) -> dict:
    """
    Fetch data for a specific collection from the API.
    
    Args:
        collection_code: The collection code to fetch
        offset: Starting offset for pagination
    
    Returns:
        Dictionary containing collection data
    """
    # Implementation here
```

### Database Standards

- Use parameterized queries to prevent SQL injection
- Always close database connections
- Use transactions for multiple related operations
- Add indexes for frequently queried columns

### Testing Standards

- Write unit tests for all new functions
- Use descriptive test method names
- Test both success and error cases
- Mock external dependencies (APIs, databases)

### Documentation Standards

- Update README.md for major changes
- Add docstrings to new functions and classes
- Update inline comments for complex logic
- Keep CHANGELOG.md updated

## Project Structure

```
congress-api-ingestion/
├── config/          # Configuration files
├── src/             # Source code
│   ├── database/    # Database operations
│   ├── ingestion/   # API ingestion logic
│   └── utils/       # Utility functions
├── tests/           # Test files
├── scripts/         # Helper scripts
├── migrations/      # Database migrations
└── docs/            # Documentation
```

## Testing

### Run All Tests
```bash
python -m pytest tests/ -v
```

### Run Specific Test File
```bash
python -m pytest tests/test_api_client.py -v
```

### Run with Coverage
```bash
python -m pytest tests/ --cov=src --cov-report=html
```

## Database Migrations

When modifying the database schema:

1. Create a new migration file in `migrations/`
2. Name it with incrementing number: `002_new_feature.sql`
3. Include both UP and DOWN migrations
4. Test the migration on a copy of the database
5. Document the changes in the migration file

## Code Review Process

1. All pull requests require at least one review
2. Reviewers will check:
   - Code quality and style
   - Test coverage
   - Documentation updates
   - Security considerations
   - Performance impact
3. Address reviewer feedback before merging
4. Maintainer merges after approval

## Release Process

1. Update version number in relevant files
2. Update CHANGELOG.md with release notes
3. Create release branch: `release/v1.2.0`
4. Test thoroughly on staging environment
5. Create GitHub release with tag
6. Merge to master
7. Update documentation

## Questions?

If you have questions about contributing:
- Open an issue
- Check existing documentation
- Review closed issues and PRs for similar questions

Thank you for contributing! 🚀
