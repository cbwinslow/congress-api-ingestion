# Congress API Ingestion System

[![Python Version](https://img.shields.io/badge/python-3.11%2B-blue)](https://www.python.org/downloads/)
[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)
[![GitHub Issues](https://img.shields.io/github/issues/cbwinslow/congress-api-ingestion)](https://github.com/cbwinslow/congress-api-ingestion/issues)
[![GitHub Stars](https://img.shields.io/github/stars/cbwinslow/congress-api-ingestion)](https://github.com/cbwinslow/congress-api-ingestion/stargazers)
[![GitHub Forks](https://img.shields.io/github/forks/cbwinslow/congress-api-ingestion)](https://github.com/cbwinslow/congress-api-ingestion/network/members)
[![Contributions Welcome](https://img.shields.io/badge/contributions-welcome-brightgreen.svg)](CONTRIBUTING.md)
[![Documentation](https://img.shields.io/badge/docs-complete-brightgreen)](README.md)
[![Test Coverage](https://img.shields.io/badge/tests-15%2B%20passing-brightgreen)](tests/)
[![PostgreSQL](https://img.shields.io/badge/database-PostgreSQL-blue)](https://www.postgresql.org/)
[![SQLite](https://img.shields.io/badge/database-SQLite-green)](https://www.sqlite.org/)

A comprehensive data ingestion system for Congress.gov and GovInfo.gov APIs with PostgreSQL backend.

## 🚀 Features

- **Dual Database Support**: PostgreSQL (production) + SQLite (fallback)
- **Comprehensive Schema**: 10+ tables for all Congress data types
- **Rate Limiting**: Respects API rate limits (1,000+ req/hour)
- **Pagination Support**: Handles offsets and pagination automatically
- **Monitoring**: Health checks and performance monitoring
- **Backup System**: Automated compressed backups
- **Validation Tests**: Comprehensive test suite (15+ tests)
- **Security**: Protected API keys and sensitive data
- **40+ Collections**: Support for bills, legislators, votes, committees, and more

## 📊 Quick Stats

- **Total Files**: 30+ files
- **Lines of Code**: ~2,500+ lines
- **Test Coverage**: 15+ test cases
- **Database Tables**: 10 tables
- **API Endpoints**: 40+ collections
- **Documentation**: Complete inline documentation

## 🛠️ Installation

### Prerequisites

- Python 3.11 or higher
- PostgreSQL 13+ (for production)
- Git

### Quick Start

```bash
# Clone the repository
git clone https://github.com/cbwinslow/congress-api-ingestion.git
cd congress-api-ingestion

# Create virtual environment
python -m venv venv
source venv/bin/activate  # On Windows: venv\Scripts\activate

# Install dependencies
pip install -r requirements.txt

# Configure
cp config/config.example.json config/config.json
# Edit config.json with your API keys
```

## ⚙️ Configuration

### API Keys

1. Get Congress API key from https://api.data.gov/signup/
2. Get GovInfo API key from https://api.data.gov/signup/
3. Add keys to `config/config.json`:

```json
{
  "api": {
    "congress": {
      "base_url": "https://api.congress.gov/v3",
      "api_key": "YOUR_CONGRESS_API_KEY"
    },
    "govinfo": {
      "base_url": "https://api.govinfo.gov",
      "api_key": "YOUR_GOVINFO_API_KEY"
    }
  },
  "database": {
    "postgresql": {
      "host": "localhost",
      "port": 5432,
      "database": "opendiscourse",
      "user": "opendiscourse",
      "password": "opendiscourse123"
    },
    "sqlite": {
      "path": "data/congress.db"
    }
  }
}
```

## 🗄️ Database Setup

### Option 1: SQLite (Development)

```bash
python main.py --setup-db
```

### Option 2: PostgreSQL (Production)

```bash
# Configure firewall
./scripts/setup_firewall.sh

# Setup PostgreSQL database
./scripts/database_setup.sh

# Monitor database health
python scripts/database_monitor.py --health
```

## 🚀 Usage

### Test API Connection

```bash
python main.py --test-api
```

### Ingest Collections

```bash
# Ingest all collections
python main.py --ingest collections

# Ingest specific collection
python main.py --ingest packages --collection BILLS
```

### View Statistics

```bash
python main.py --stats
```

### Run Tests

```bash
# Run all tests
python -m pytest tests/ -v

# Run specific test
python -m pytest tests/test_api_client.py -v

# Run with coverage
python -m pytest tests/ --cov=src --cov-report=html
```

## 📊 Database Schema

### Tables

| Table | Description |
|-------|-------------|
| `collections` | GovInfo collection metadata |
| `packages` | Individual data packages |
| `bills` | Legislative bills |
| `legislators` | Congress members |
| `committees` | Congressional committees |
| `votes` | Roll call votes |
| `individual_votes` | Individual member votes |
| `congressional_record` | Congressional record entries |
| `ingestion_log` | Data ingestion tracking |

### Schema Features

- **Foreign Keys**: Maintains data integrity
- **Indexes**: Optimized for fast queries
- **JSONB Fields**: Flexible metadata storage
- **Timestamps**: Automatic creation and updates
- **Constraints**: Data validation

## 📈 Monitoring

### Health Checks

```bash
python scripts/database_monitor.py --health
```

### Performance Monitoring

```bash
python scripts/database_monitor.py --performance
```

### Backup

```bash
# Create backup
python scripts/database_backup.py --backup

# Restore from backup
python scripts/database_backup.py --restore backup_file.sql.gz
```

## 🧪 Testing

### Test Suite

- **API Client Tests**: Connection and rate limiting
- **Database Tests**: Schema validation and operations
- **Ingestion Tests**: Data collection and processing
- **Validation Tests**: Data integrity and constraints

### Run Tests

```bash
# All tests
python -m pytest tests/ -v

# Specific test file
python -m pytest tests/test_api_client.py -v

# With coverage report
python -m pytest tests/ --cov=src --cov-report=html
```n

## 📖 Documentation

- [CONTRIBUTING.md](CONTRIBUTING.md) - Contribution guidelines
- [CHANGELOG.md](CHANGELOG.md) - Version history
- [RELEASE_v1.0.0.md](RELEASE_v1.0.0.md) - Release notes
- [API Documentation](docs/api.md) - API usage guide
- [Schema Documentation](docs/schema.md) - Database structure

## 🤝 Contributing

We welcome contributions! Please read [CONTRIBUTING.md](CONTRIBUTING.md) for guidelines.

1. Fork the repository
2. Create a feature branch: `git checkout -b feature/amazing-feature`
3. Make your changes
4. Add tests for new functionality
5. Ensure tests pass: `python -m pytest tests/ -v`
6. Commit your changes: `git commit -m 'Add amazing feature'`
7. Push to the branch: `git push origin feature/amazing-feature`
8. Open a Pull Request

## 📄 License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## 🙏 Acknowledgments

- **Library of Congress**: For the Congress.gov API
- **GovInfo**: For comprehensive bulk data access
- **Contributors**: All who helped shape this project

## 📞 Support

- **GitHub Issues**: https://github.com/cbwinslow/congress-api-ingestion/issues
- **Documentation**: See project README and inline docs
- **Community**: Check GitHub Discussions

## 🎯 Roadmap

### Version 1.1.0 (Planned)
- Real-time data streaming
- Advanced analytics dashboard
- Performance optimizations
- Additional API endpoints

### Version 1.2.0 (Planned)
- Web-based monitoring interface
- Cloud deployment automation
- Advanced error recovery
- Data validation enhancements

---

**Thank you for using Congress API Ingestion System!** 🚀

For updates, ⭐ star the repository on GitHub!
