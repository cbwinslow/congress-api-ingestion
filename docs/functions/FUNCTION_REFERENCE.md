# 📚 Complete Function Reference

## Congress API Ingestion System - All Functions

This document provides a comprehensive reference of all functions available in the Congress API Ingestion System, organized by module and purpose.

## 🗂️ Module Structure

```
congress_api_ingestion/
├── api_client.py          # API communication functions
├── database.py           # Database operations
├── congress_ingestor.py  # Main ingestion logic
├── config.py             # Configuration management
├── utils.py              # Utility functions
├── error_handler.py      # Error handling
└── models.py             # Data models
```

## 🌐 API Client Functions

### `fetch_api_data(endpoint, params=None, headers=None)`

Fetch data from Congress API endpoints with proper error handling.

**Parameters:**
- `endpoint` (str): API endpoint URL
- `params` (dict, optional): Query parameters
- `headers` (dict, optional): HTTP headers

**Returns:**
- `dict`: Parsed JSON response

**Raises:**
- `APIError`: If API request fails
- `RateLimitError`: If rate limit exceeded

**Example:**
```python
from api_client import fetch_api_data

data = fetch_api_data(
    'https://api.congress.gov/v3/bill',
    params={'limit': 50, 'offset': 0},
    headers={'X-API-KEY': 'your_key'}
)
```

### `handle_rate_limiting(response, max_retries=3)`

Handle API rate limiting with automatic retry logic.

**Parameters:**
- `response` (dict): API response to check
- `max_retries` (int, optional): Maximum retry attempts

**Returns:**
- `bool`: True if request should proceed, False if rate limited

**Example:**
```python
from api_client import handle_rate_limiting

if not handle_rate_limiting(response):
    time.sleep(60)  # Wait before retrying
```

### `get_api_endpoints()`

Get list of available API endpoints.

**Returns:**
- `list`: Available endpoints

**Example:**
```python
from api_client import get_api_endpoints

endpoints = get_api_endpoints()
```

## 🗃️ Database Functions

### `initialize_database(config)`

Initialize database connection with connection pooling.

**Parameters:**
- `config` (dict): Database configuration

**Returns:**
- `DatabaseConnection`: Connection object

**Example:**
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

Create complete database schema with tables and indexes.

**Parameters:**
- `db_connection` (DatabaseConnection): Active connection

**Returns:**
- `bool`: True if successful

**Example:**
```python
from database import create_schema

success = create_schema(db)
```

### `insert_data(db_connection, table, data)`

Insert data into specified table with deduplication.

**Parameters:**
- `db_connection` (DatabaseConnection): Active connection
- `table` (str): Table name
- `data` (dict/list): Data to insert

**Returns:**
- `int`: Number of rows inserted

**Example:**
```python
from database import insert_data

rows_inserted = insert_data(db, 'bills', bill_data)
```

### `get_connection_pool(config, pool_size=5)`

Create connection pool for high-performance operations.

**Parameters:**
- `config` (dict): Database configuration
- `pool_size` (int, optional): Pool size

**Returns:**
- `ConnectionPool`: Connection pool object

**Example:**
```python
from database import get_connection_pool

pool = get_connection_pool(config, pool_size=10)
```

## 📥 Ingestion Functions

### `ingest_data(collection_type, limit=50, offset=0)`

Main data ingestion function.

**Parameters:**
- `collection_type` (str): Data type to ingest
- `limit` (int, optional): Items per request
- `offset` (int, optional): Starting offset

**Returns:**
- `dict`: Ingestion results

**Example:**
```python
from congress_ingestor import ingest_data

result = ingest_data('bills', limit=100)
```

### `parallel_ingest(collection_types, workers=8)`

Parallel data ingestion with multiple workers.

**Parameters:**
- `collection_types` (list): List of collection types
- `workers` (int, optional): Number of workers

**Returns:**
- `dict`: Aggregated results

**Example:**
```python
from congress_ingestor import parallel_ingest

collections = ['bills', 'legislators', 'votes']
result = parallel_ingest(collections, workers=4)
```

### `batch_ingest(collection_type, batch_size=100)`

Batch processing for memory efficiency.

**Parameters:**
- `collection_type` (str): Data type
- `batch_size` (int, optional): Batch size

**Returns:**
- `dict`: Batch results

**Example:**
```python
from congress_ingestor import batch_ingest

result = batch_ingest('bills', batch_size=200)
```

## ⚙️ Configuration Functions

### `load_config(file_path='config.json')`

Load configuration from JSON file.

**Parameters:**
- `file_path` (str, optional): Config file path

**Returns:**
- `dict`: Configuration dictionary

**Example:**
```python
from config import load_config

config = load_config()
```

### `validate_config(config)`

Validate configuration structure and values.

**Parameters:**
- `config` (dict): Configuration to validate

**Returns:**
- `tuple`: (bool, list) - (is_valid, error_messages)

**Example:**
```python
from config import validate_config

is_valid, errors = validate_config(config)
```

### `get_default_config()`

Get default configuration template.

**Returns:**
- `dict`: Default configuration

**Example:**
```python
from config import get_default_config

config = get_default_config()
```

## 🧰 Utility Functions

### `calculate_optimal_workers()`

Calculate optimal workers based on system resources.

**Returns:**
- `int`: Optimal worker count

**Example:**
```python
from utils import calculate_optimal_workers

workers = calculate_optimal_workers()
```

### `log_ingestion_stats(stats)`

Log ingestion statistics and performance metrics.

**Parameters:**
- `stats` (dict): Statistics dictionary

**Example:**
```python
from utils import log_ingestion_stats

stats = {
    'success_count': 100,
    'error_count': 2,
    'duration_seconds': 120
}
log_ingestion_stats(stats)
```

### `monitor_system_resources()`

Monitor system resources (CPU, memory, network).

**Returns:**
- `dict`: Resource usage statistics

**Example:**
```python
from utils import monitor_system_resources

resources = monitor_system_resources()
```

### `generate_progress_report(progress)`

Generate progress report for ingestion operations.

**Parameters:**
- `progress` (dict): Progress data

**Returns:**
- `str`: Formatted progress report

**Example:**
```python
from utils import generate_progress_report

report = generate_progress_report(progress)
```

## ❌ Error Handling Functions

### `handle_api_error(error)`

Handle API errors gracefully.

**Parameters:**
- `error` (Exception): Error to handle

**Returns:**
- `dict`: Error information and recovery suggestions

**Example:**
```python
from error_handler import handle_api_error

try:
    data = fetch_api_data(endpoint)
except Exception as e:
    error_info = handle_api_error(e)
```

### `handle_database_error(error)`

Handle database errors gracefully.

**Parameters:**
- `error` (Exception): Database error

**Returns:**
- `dict`: Error information and recovery suggestions

**Example:**
```python
from error_handler import handle_database_error

try:
    db.execute(query)
except Exception as e:
    error_info = handle_database_error(e)
```

### `log_error(error_info)`

Log error information for debugging.

**Parameters:**
- `error_info` (dict): Error information

**Example:**
```python
from error_handler import log_error

log_error(error_info)
```

## 📊 Data Model Functions

### `Bill(data)`

Bill data model.

**Parameters:**
- `data` (dict): Bill data

**Example:**
```python
from models import Bill

bill = Bill(bill_data)
```

### `Legislator(data)`

Legislator data model.

**Parameters:**
- `data` (dict): Legislator data

**Example:**
```python
from models import Legislator

legislator = Legislator(legislator_data)
```

### `Vote(data)`

Vote data model.

**Parameters:**
- `data` (dict): Vote data

**Example:**
```python
from models import Vote

vote = Vote(vote_data)
```

## 🎯 Usage Patterns

### Basic Ingestion Pattern
```python
from congress_ingestor import ingest_data
from config import load_config

# Load configuration
config = load_config()

# Ingest data
result = ingest_data('bills', limit=100)

# Process results
print(f"Ingested {result['success_count']} items")
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

### Complete Workflow Pattern
```python
from api_client import fetch_api_data
from database import initialize_database, insert_data
from config import load_config

# Load configuration
config = load_config()

# Initialize database
db = initialize_database(config['database'])

# Fetch data from API
data = fetch_api_data('https://api.congress.gov/v3/bill')

# Insert into database
rows_inserted = insert_data(db, 'bills', data)

# Close connection
db.close()
```

## 📚 Function Index

| Category | Function | Description |
|----------|----------|-------------|
| **API** | `fetch_api_data()` | Fetch API data |
| **API** | `handle_rate_limiting()` | Handle rate limiting |
| **API** | `get_api_endpoints()` | Get available endpoints |
| **DB** | `initialize_database()` | Initialize database |
| **DB** | `create_schema()` | Create schema |
| **DB** | `insert_data()` | Insert data |
| **DB** | `get_connection_pool()` | Get connection pool |
| **Ingestion** | `ingest_data()` | Main ingestion |
| **Ingestion** | `parallel_ingest()` | Parallel ingestion |
| **Ingestion** | `batch_ingest()` | Batch processing |
| **Config** | `load_config()` | Load config |
| **Config** | `validate_config()` | Validate config |
| **Config** | `get_default_config()` | Default config |
| **Utils** | `calculate_optimal_workers()` | Calculate workers |
| **Utils** | `log_ingestion_stats()` | Log stats |
| **Utils** | `monitor_system_resources()` | Monitor resources |
| **Utils** | `generate_progress_report()` | Generate report |
| **Errors** | `handle_api_error()` | Handle API errors |
| **Errors** | `handle_database_error()` | Handle DB errors |
| **Errors** | `log_error()` | Log errors |
| **Models** | `Bill()` | Bill model |
| **Models** | `Legislator()` | Legislator model |
| **Models** | `Vote()` | Vote model |

## 🤖 AI Agent Best Practices

1. **Always validate configuration** before operations
2. **Use connection pooling** for database operations
3. **Implement proper error handling** for robustness
4. **Monitor rate limits** to avoid API restrictions
5. **Use parallel processing** for large datasets
6. **Log all operations** for debugging and analysis
7. **Validate data integrity** after ingestion
8. **Monitor system resources** during operations

## 📖 Additional Documentation

- [API Reference](API_REFERENCE.md)
- [User Guide](USER_GUIDE.md)
- [Installation Guide](INSTALLATION.md)
- [Configuration Reference](CONFIGURATION.md)
