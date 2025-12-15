# ⚙️ Configuration Reference

## Complete Configuration Guide for Congress API Ingestion System

## 📚 Table of Contents

- [Configuration Structure](#-configuration-structure)
- [Database Configuration](#-database-configuration)
- [API Configuration](#-api-configuration)
- [Ingestion Configuration](#-ingestion-configuration)
- [Logging Configuration](#-logging-configuration)
- [Advanced Configuration](#-advanced-configuration)
- [Environment Variables](#-environment-variables)
- [Configuration Examples](#-configuration-examples)

## 🗂️ Configuration Structure

```json
{
  "database": {
    "type": "postgresql",
    "host": "localhost",
    "port": 5432,
    "database": "opendiscourse",
    "user": "opendiscourse",
    "password": "opendiscourse123",
    "ssl": false,
    "pool_size": 10,
    "timeout": 30
  },
  "api": {
    "congress_gov": {
      "base_url": "https://api.congress.gov/v3",
      "api_key": "your_api_key_here",
      "rate_limit": 1000,
      "timeout": 30,
      "retry_limit": 3
    },
    "govinfo": {
      "base_url": "https://api.govinfo.gov",
      "api_key": "your_api_key_here",
      "rate_limit": 1000,
      "timeout": 30,
      "retry_limit": 3
    }
  },
  "ingestion": {
    "workers": 8,
    "batch_size": 100,
    "timeout": 30,
    "retry_limit": 3,
    "max_errors": 10,
    "log_interval": 60
  },
  "logging": {
    "level": "INFO",
    "file": "ingestion.log",
    "max_size": "10MB",
    "backup_count": 5,
    "console": true,
    "format": "%(asctime)s - %(name)s - %(levelname)s - %(message)s"
  },
  "advanced": {
    "connection_pooling": true,
    "parallel_processing": true,
    "data_validation": true,
    "deduplication": true,
    "compression": false,
    "encryption": false
  }
}
```

## 🗃️ Database Configuration

### Database Type
- `type`: Database type (`postgresql` or `sqlite`)
- Default: `postgresql`

### PostgreSQL Configuration
- `host`: Database server host
- `port`: Database server port (default: 5432)
- `database`: Database name
- `user`: Database username
- `password`: Database password
- `ssl`: Use SSL connection (boolean)
- `pool_size`: Connection pool size (default: 10)
- `timeout`: Connection timeout in seconds (default: 30)

### SQLite Configuration
- `database`: Path to SQLite database file
- `timeout`: Connection timeout in seconds (default: 30)

### Example PostgreSQL Configuration
```json
"database": {
  "type": "postgresql",
  "host": "localhost",
  "port": 5432,
  "database": "opendiscourse",
  "user": "opendiscourse",
  "password": "opendiscourse123",
  "ssl": false,
  "pool_size": 10,
  "timeout": 30
}
```

### Example SQLite Configuration
```json
"database": {
  "type": "sqlite",
  "database": "data/congress.db",
  "timeout": 30
}
```

## 🌐 API Configuration

### Congress.gov API Configuration
- `base_url`: API base URL
- `api_key`: API authentication key
- `rate_limit`: Requests per hour limit
- `timeout`: Request timeout in seconds
- `retry_limit`: Maximum retry attempts

### GovInfo API Configuration
- `base_url`: API base URL
- `api_key`: API authentication key
- `rate_limit`: Requests per hour limit
- `timeout`: Request timeout in seconds
- `retry_limit`: Maximum retry attempts

### Example API Configuration
```json
"api": {
  "congress_gov": {
    "base_url": "https://api.congress.gov/v3",
    "api_key": "your_api_key_here",
    "rate_limit": 1000,
    "timeout": 30,
    "retry_limit": 3
  },
  "govinfo": {
    "base_url": "https://api.govinfo.gov",
    "api_key": "your_api_key_here",
    "rate_limit": 1000,
    "timeout": 30,
    "retry_limit": 3
  }
}
```

## 📥 Ingestion Configuration

### Ingestion Parameters
- `workers`: Number of parallel workers (default: 8)
- `batch_size`: Items per batch (default: 100)
- `timeout`: Operation timeout in seconds (default: 30)
- `retry_limit`: Maximum retry attempts (default: 3)
- `max_errors`: Maximum errors before stopping (default: 10)
- `log_interval`: Logging interval in seconds (default: 60)

### Example Ingestion Configuration
```json
"ingestion": {
  "workers": 8,
  "batch_size": 100,
  "timeout": 30,
  "retry_limit": 3,
  "max_errors": 10,
  "log_interval": 60
}
```

## 📝 Logging Configuration

### Logging Parameters
- `level`: Logging level (DEBUG, INFO, WARNING, ERROR, CRITICAL)
- `file`: Log file path
- `max_size`: Maximum log file size
- `backup_count`: Number of backup files
- `console`: Log to console (boolean)
- `format`: Log message format

### Example Logging Configuration
```json
"logging": {
  "level": "INFO",
  "file": "ingestion.log",
  "max_size": "10MB",
  "backup_count": 5,
  "console": true,
  "format": "%(asctime)s - %(name)s - %(levelname)s - %(message)s"
}
```

## ⚙️ Advanced Configuration

### Advanced Features
- `connection_pooling`: Enable connection pooling (boolean)
- `parallel_processing`: Enable parallel processing (boolean)
- `data_validation`: Enable data validation (boolean)
- `deduplication`: Enable data deduplication (boolean)
- `compression`: Enable data compression (boolean)
- `encryption`: Enable data encryption (boolean)

### Example Advanced Configuration
```json
"advanced": {
  "connection_pooling": true,
  "parallel_processing": true,
  "data_validation": true,
  "deduplication": true,
  "compression": false,
  "encryption": false
}
```

## 🌍 Environment Variables

The system supports environment variables for configuration:

```bash
export CONGRESS_DB_TYPE=postgresql
export CONGRESS_DB_HOST=localhost
export CONGRESS_DB_PORT=5432
export CONGRESS_DB_NAME=opendiscourse
export CONGRESS_DB_USER=opendiscourse
export CONGRESS_DB_PASSWORD=opendiscourse123
export CONGRESS_API_KEY=your_api_key_here
```

Environment variables override configuration file settings.

## 📋 Configuration Examples

### Production Configuration
```json
{
  "database": {
    "type": "postgresql",
    "host": "db.production.example.com",
    "port": 5432,
    "database": "opendiscourse_prod",
    "user": "opendiscourse",
    "password": "secure_password_here",
    "ssl": true,
    "pool_size": 20,
    "timeout": 60
  },
  "api": {
    "congress_gov": {
      "base_url": "https://api.congress.gov/v3",
      "api_key": "prod_api_key_here",
      "rate_limit": 1000,
      "timeout": 60,
      "retry_limit": 5
    },
    "govinfo": {
      "base_url": "https://api.govinfo.gov",
      "api_key": "prod_api_key_here",
      "rate_limit": 1000,
      "timeout": 60,
      "retry_limit": 5
    }
  },
  "ingestion": {
    "workers": 16,
    "batch_size": 200,
    "timeout": 60,
    "retry_limit": 5,
    "max_errors": 20,
    "log_interval": 30
  },
  "logging": {
    "level": "INFO",
    "file": "/var/log/congress_ingestion.log",
    "max_size": "50MB",
    "backup_count": 10,
    "console": false,
    "format": "%(asctime)s - %(name)s - %(levelname)s - %(message)s"
  },
  "advanced": {
    "connection_pooling": true,
    "parallel_processing": true,
    "data_validation": true,
    "deduplication": true,
    "compression": false,
    "encryption": false
  }
}
```

### Development Configuration
```json
{
  "database": {
    "type": "sqlite",
    "database": "data/congress_dev.db",
    "timeout": 30
  },
  "api": {
    "congress_gov": {
      "base_url": "https://api.congress.gov/v3",
      "api_key": "dev_api_key_here",
      "rate_limit": 100,
      "timeout": 30,
      "retry_limit": 3
    },
    "govinfo": {
      "base_url": "https://api.govinfo.gov",
      "api_key": "dev_api_key_here",
      "rate_limit": 100,
      "timeout": 30,
      "retry_limit": 3
    }
  },
  "ingestion": {
    "workers": 4,
    "batch_size": 50,
    "timeout": 30,
    "retry_limit": 3,
    "max_errors": 5,
    "log_interval": 60
  },
  "logging": {
    "level": "DEBUG",
    "file": "ingestion_dev.log",
    "max_size": "5MB",
    "backup_count": 3,
    "console": true,
    "format": "%(asctime)s - %(name)s - %(levelname)s - %(message)s"
  },
  "advanced": {
    "connection_pooling": true,
    "parallel_processing": true,
    "data_validation": true,
    "deduplication": true,
    "compression": false,
    "encryption": false
  }
}
```

### Testing Configuration
```json
{
  "database": {
    "type": "sqlite",
    "database": ":memory:",
    "timeout": 10
  },
  "api": {
    "congress_gov": {
      "base_url": "https://api.congress.gov/v3",
      "api_key": "test_api_key_here",
      "rate_limit": 10,
      "timeout": 10,
      "retry_limit": 1
    },
    "govinfo": {
      "base_url": "https://api.govinfo.gov",
      "api_key": "test_api_key_here",
      "rate_limit": 10,
      "timeout": 10,
      "retry_limit": 1
    }
  },
  "ingestion": {
    "workers": 2,
    "batch_size": 10,
    "timeout": 10,
    "retry_limit": 1,
    "max_errors": 2,
    "log_interval": 10
  },
  "logging": {
    "level": "DEBUG",
    "file": "test_ingestion.log",
    "max_size": "1MB",
    "backup_count": 1,
    "console": true,
    "format": "%(asctime)s - %(name)s - %(levelname)s - %(message)s"
  },
  "advanced": {
    "connection_pooling": false,
    "parallel_processing": false,
    "data_validation": true,
    "deduplication": true,
    "compression": false,
    "encryption": false
  }
}
```

## 🤖 AI Agent Configuration Tips

### Programmatic Configuration
```python
from config import get_default_config, save_config

# Get default configuration
config = get_default_config()

# Customize for your environment
config['database']['host'] = 'your_host'
config['database']['password'] = 'your_password'
config['api']['congress_gov']['api_key'] = 'your_api_key'

# Save configuration
save_config(config, 'config.json')
```

### Configuration Validation
```python
from config import load_config, validate_config

# Load configuration
config = load_config()

# Validate configuration
is_valid, errors = validate_config(config)

if not is_valid:
    # Handle validation errors
    for error in errors:
        print(f"Configuration error: {error}")
```

### Environment-Based Configuration
```python
import os
from config import get_default_config

# Get default configuration
config = get_default_config()

# Override with environment variables
if 'DB_HOST' in os.environ:
    config['database']['host'] = os.environ['DB_HOST']

if 'API_KEY' in os.environ:
    config['api']['congress_gov']['api_key'] = os.environ['API_KEY']
```

## 📚 Configuration Best Practices

1. **Use Environment Variables** for sensitive information
2. **Validate Configuration** before starting operations
3. **Use Different Configurations** for different environments
4. **Document Configuration Changes** in CHANGELOG.md
5. **Test Configuration** before production deployment
6. **Use Version Control** for configuration files
7. **Implement Configuration Backup** for critical systems
8. **Monitor Configuration Changes** for security

## 🔧 Configuration Management Tools

The system includes tools for configuration management:

```bash
# Validate configuration
python scripts/validate_config.py

# Test configuration
python scripts/test_config.py

# Generate default configuration
python scripts/generate_config.py
```

This configuration reference provides everything needed to configure the Congress API Ingestion System for various environments and use cases.
