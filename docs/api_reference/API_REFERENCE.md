# 🤖 AI Agent API Reference

## Congress API Ingestion System - Complete Function Reference

This document provides comprehensive API reference specifically designed for AI agents to understand and utilize all functions in the Congress API Ingestion System.

## 📚 Table of Contents

- [Core Functions](#-core-functions)
- [Database Functions](#-database-functions)
- [API Functions](#-api-functions)
- [Configuration Functions](#-configuration-functions)
- [Utility Functions](#-utility-functions)
- [Error Handling](#-error-handling)

## 🎯 Core Functions

### `ingest_data(collection_type, limit=50, offset=0)`

**Purpose:** Main data ingestion function for Congress data

**Parameters:**
- `collection_type` (str): Type of data to ingest (e.g., 'bills', 'legislators', 'votes')
- `limit` (int, optional): Number of items per request (default: 50)
- `offset` (int, optional): Starting offset for pagination (default: 0)

**Returns:**
- `dict`: Ingestion results with success count, errors, and metadata

**Example Usage:**
```python
from congress_ingestor import ingest_data

result = ingest_data('bills', limit=100, offset=0)
print(f"Ingested {result['success_count']} bills")
```

### `parallel_ingest(collection_types, workers=8)`

**Purpose:** Parallel data ingestion using multiple workers

**Parameters:**
- `collection_types` (list): List of collection types to ingest
- `workers` (int, optional): Number of parallel workers (default: 8)

**Returns:**
- `dict`: Aggregated results from all workers

**Example Usage:**
```python
from congress_ingestor import parallel_ingest

collections = ['bills', 'legislators', 'votes', 'committees']
result = parallel_ingest(collections, workers=4)
```

## 🗃️ Database Functions

### `initialize_database(config)`

**Purpose:** Initialize database connection and schema

**Parameters:**
- `config` (dict): Database configuration dictionary

**Returns:**
- `DatabaseConnection`: Active database connection object

**Example Usage:**
```python
from database import initialize_database

config = {
    'host': 'localhost',
    'port': 5432,
    'database': 'opendiscourse',
    'user': 'opendiscourse',
    'password': 'opendiscourse123'
}

db = initialize_database(config)
```

### `create_schema(db_connection)`

**Purpose:** Create all required database tables and indexes

**Parameters:**
- `db_connection` (DatabaseConnection): Active database connection

**Returns:**
- `bool`: True if schema creation successful

**Example Usage:**
```python
from database import create_schema

success = create_schema(db)
```

## 🌐 API Functions

### `fetch_api_data(endpoint, params=None)`

**Purpose:** Fetch data from Congress API endpoints

**Parameters:**
- `endpoint` (str): API endpoint URL
- `params` (dict, optional): Query parameters

**Returns:**
- `dict`: API response data

**Example Usage:**
```python
from api_client import fetch_api_data

data = fetch_api_data('https://api.congress.gov/v3/bill', {'limit': 50})
```

### `handle_rate_limiting(response)`

**Purpose:** Handle API rate limiting and retry logic

**Parameters:**
- `response` (dict): API response to check

**Returns:**
- `bool`: True if rate limit is acceptable, False if exceeded

**Example Usage:**
```python
from api_client import handle_rate_limiting

if not handle_rate_limiting(response):
    time.sleep(60)  # Wait before retrying
```

## ⚙️ Configuration Functions

### `load_config(file_path='config.json')`

**Purpose:** Load configuration from JSON file

**Parameters:**
- `file_path` (str, optional): Path to config file

**Returns:**
- `dict`: Configuration dictionary

**Example Usage:**
```python
from config import load_config

config = load_config()
```

### `validate_config(config)`

**Purpose:** Validate configuration structure and values

**Parameters:**
- `config` (dict): Configuration to validate

**Returns:**
- `tuple`: (bool, list) - (is_valid, error_messages)

**Example Usage:**
```python
from config import validate_config

is_valid, errors = validate_config(config)
```

## 🧰 Utility Functions

### `calculate_optimal_workers()`

**Purpose:** Calculate optimal number of workers based on system resources

**Returns:**
- `int`: Optimal worker count

**Example Usage:**
```python
from utils import calculate_optimal_workers

workers = calculate_optimal_workers()
```

### `log_ingestion_stats(stats)`

**Purpose:** Log ingestion statistics and performance metrics

**Parameters:**
- `stats` (dict): Statistics dictionary

**Example Usage:**
```python
from utils import log_ingestion_stats

stats = {
    'success_count': 100,
    'error_count': 2,
    'duration_seconds': 120
}
log_ingestion_stats(stats)
```

## ❌ Error Handling

### `handle_api_error(error)`

**Purpose:** Handle API errors gracefully

**Parameters:**
- `error` (Exception): Error to handle

**Returns:**
- `dict`: Error information and recovery suggestions

**Example Usage:**
```python
from error_handler import handle_api_error

try:
    data = fetch_api_data(endpoint)
except Exception as e:
    error_info = handle_api_error(e)
    # Implement recovery logic based on error_info
```

### `handle_database_error(error)`

**Purpose:** Handle database errors gracefully

**Parameters:**
- `error` (Exception): Database error to handle

**Returns:**
- `dict`: Error information and recovery suggestions

**Example Usage:**
```python
from error_handler import handle_database_error

try:
    db.execute(query)
except Exception as e:
    error_info = handle_database_error(e)
```

## 📚 Complete Function Index

| Function | Module | Description |
|----------|--------|-------------|
| `ingest_data()` | `congress_ingestor` | Main data ingestion function |
| `parallel_ingest()` | `congress_ingestor` | Parallel data ingestion |
| `initialize_database()` | `database` | Initialize database connection |
| `create_schema()` | `database` | Create database schema |
| `fetch_api_data()` | `api_client` | Fetch API data |
| `handle_rate_limiting()` | `api_client` | Handle rate limiting |
| `load_config()` | `config` | Load configuration |
| `validate_config()` | `config` | Validate configuration |
| `calculate_optimal_workers()` | `utils` | Calculate optimal workers |
| `log_ingestion_stats()` | `utils` | Log statistics |
| `handle_api_error()` | `error_handler` | Handle API errors |
| `handle_database_error()` | `error_handler` | Handle database errors |

## 🤖 AI Agent Usage Patterns

### Basic Ingestion Pattern
```python
from congress_ingestor import ingest_data
from config import load_config

# Load configuration
config = load_config()

# Ingest specific data type
result = ingest_data('bills', limit=100)

# Process results
if result['success_count'] > 0:
    # Continue with data processing
    pass
```

### Parallel Processing Pattern
```python
from congress_ingestor import parallel_ingest
from utils import calculate_optimal_workers

# Calculate optimal workers
workers = calculate_optimal_workers()

# Parallel ingestion
collections = ['bills', 'legislators', 'votes']
result = parallel_ingest(collections, workers=workers)
```

### Error Handling Pattern
```python
from congress_ingestor import ingest_data
from error_handler import handle_api_error

try:
    result = ingest_data('bills')
except Exception as e:
    error_info = handle_api_error(e)
    # Implement recovery based on error type
    if error_info['type'] == 'rate_limit':
        # Wait and retry
        pass
```

## 🎓 Best Practices for AI Agents

1. **Always validate configuration** before starting ingestion
2. **Use parallel processing** for large datasets
3. **Implement proper error handling** for robust operations
4. **Monitor rate limits** to avoid API restrictions
5. **Log all operations** for debugging and analysis
6. **Use batch processing** for memory efficiency
7. **Validate data integrity** after ingestion

## 📖 Additional Resources

- [Complete User Guide](USER_GUIDE.md)
- [Installation Instructions](INSTALLATION.md)
- [Configuration Reference](CONFIGURATION.md)
- [Troubleshooting Guide](TROUBLESHOOTING.md)
