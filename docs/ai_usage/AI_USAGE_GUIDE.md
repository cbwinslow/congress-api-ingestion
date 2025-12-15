# 🤖 AI Agent Usage Guide

## Complete Guide for AI Agents Using Congress API Ingestion System

This guide provides comprehensive instructions for AI agents to effectively use the Congress API Ingestion System.

## 🎯 Quick Start for AI Agents

### Basic Setup
```python
# Import required modules
from congress_ingestor import ingest_data, parallel_ingest
from config import load_config
from database import initialize_database

# Load configuration
config = load_config()

# Initialize database
db = initialize_database(config['database'])

# Ready for ingestion operations
```

### Simple Ingestion
```python
# Ingest specific data type
result = ingest_data('bills', limit=100)

# Check results
if result['success_count'] > 0:
    # Continue with data processing
    pass
```

## 📚 Core Functionality

### Data Ingestion

#### Single Collection Ingestion
```python
from congress_ingestor import ingest_data

# Ingest bills with pagination
result = ingest_data(
    collection_type='bills',
    limit=50,
    offset=0
)

# Process results
print(f"Success: {result['success_count']}")
print(f"Errors: {result['error_count']}")
```

#### Multiple Collection Ingestion
```python
from congress_ingestor import ingest_data

collections = ['bills', 'legislators', 'votes']

for collection in collections:
    result = ingest_data(collection, limit=100)
    # Process each collection
```

### Parallel Processing

#### Basic Parallel Ingestion
```python
from congress_ingestor import parallel_ingest

collections = ['bills', 'legislators', 'votes', 'committees']
result = parallel_ingest(collections, workers=4)
```

#### Advanced Parallel Processing
```python
from congress_ingestor import parallel_ingest
from utils import calculate_optimal_workers

# Calculate optimal workers based on system resources
workers = calculate_optimal_workers()

# Parallel ingestion with optimal workers
collections = ['bills', 'legislators', 'votes']
result = parallel_ingest(collections, workers=workers)

# Process aggregated results
print(f"Total success: {result['total_success']}")
print(f"Total errors: {result['total_errors']}")
```

### Batch Processing

#### Memory-Efficient Batch Processing
```python
from congress_ingestor import batch_ingest

# Process bills in batches of 200
result = batch_ingest('bills', batch_size=200)

# Process batch results
for batch_result in result['batches']:
    # Process each batch
    pass
```

## 🗃️ Database Operations

### Database Initialization
```python
from database import initialize_database, create_schema

# Initialize database connection
db = initialize_database({
    'host': 'localhost',
    'port': 5432,
    'database': 'opendiscourse',
    'user': 'opendiscourse',
    'password': 'opendiscourse123'
})

# Create schema
create_schema(db)
```

### Data Insertion
```python
from database import insert_data

# Insert bill data
data = {
    'bill_id': 'hr123',
    'title': 'Sample Bill',
    'status': 'introduced',
    'metadata': {'sponsor': 'Rep. Smith'}
}

rows_inserted = insert_data(db, 'bills', data)
```

### Connection Pooling
```python
from database import get_connection_pool

# Get connection pool
pool = get_connection_pool(config['database'], pool_size=10)

# Use connection from pool
with pool.get_connection() as conn:
    # Perform database operations
    pass
```

## 🌐 API Operations

### API Data Fetching
```python
from api_client import fetch_api_data

# Fetch data from Congress API
data = fetch_api_data(
    'https://api.congress.gov/v3/bill',
    params={'limit': 50, 'offset': 0},
    headers={'X-API-KEY': config['api_key']}
)
```

### Rate Limiting Handling
```python
from api_client import fetch_api_data, handle_rate_limiting

try:
    data = fetch_api_data(endpoint, params)
    
    # Check rate limiting
    if not handle_rate_limiting(data):
        # Rate limit exceeded, wait before continuing
        import time
        time.sleep(60)
        
except Exception as e:
    # Handle API errors
    pass
```

## ⚙️ Configuration Management

### Configuration Loading
```python
from config import load_config, validate_config

# Load configuration
config = load_config()

# Validate configuration
is_valid, errors = validate_config(config)

if not is_valid:
    # Handle configuration errors
    for error in errors:
        print(f"Config error: {error}")
```

### Default Configuration
```python
from config import get_default_config

# Get default configuration template
default_config = get_default_config()

# Customize as needed
default_config['database']['host'] = 'your_host'
```

## 🧰 Utility Functions

### System Monitoring
```python
from utils import monitor_system_resources

# Monitor system resources
resources = monitor_system_resources()

print(f"CPU: {resources['cpu_usage']}%")
print(f"Memory: {resources['memory_usage']}%")
```

### Progress Reporting
```python
from utils import generate_progress_report

# Generate progress report
progress = {
    'completed': 100,
    'total': 500,
    'success_rate': 98.5
}

report = generate_progress_report(progress)
print(report)
```

### Worker Calculation
```python
from utils import calculate_optimal_workers

# Calculate optimal workers
workers = calculate_optimal_workers()

# Use in parallel processing
result = parallel_ingest(collections, workers=workers)
```

## ❌ Error Handling

### API Error Handling
```python
from api_client import fetch_api_data
from error_handler import handle_api_error

try:
    data = fetch_api_data(endpoint, params)
except Exception as e:
    error_info = handle_api_error(e)
    
    # Implement recovery based on error type
    if error_info['type'] == 'rate_limit':
        # Wait and retry
        time.sleep(60)
    elif error_info['type'] == 'connection':
        # Check network connection
        pass
```

### Database Error Handling
```python
from database import insert_data
from error_handler import handle_database_error

try:
    rows_inserted = insert_data(db, 'bills', data)
except Exception as e:
    error_info = handle_database_error(e)
    
    # Implement recovery based on error type
    if error_info['type'] == 'connection':
        # Reconnect to database
        db = initialize_database(config['database'])
    elif error_info['type'] == 'constraint':
        # Handle constraint violation
        pass
```

### Comprehensive Error Handling
```python
from congress_ingestor import ingest_data
from error_handler import handle_api_error, handle_database_error, log_error

try:
    result = ingest_data('bills', limit=100)
    
    # Check for errors in results
    if result['error_count'] > 0:
        for error in result['errors']:
            log_error(error)
            
except Exception as e:
    # Handle different types of errors
    error_info = handle_api_error(e)
    
    if error_info['type'] == 'rate_limit':
        # Implement rate limit recovery
        pass
    elif error_info['type'] == 'authentication':
        # Handle authentication errors
        pass
    else:
        # Log unexpected errors
        log_error(error_info)
```

## 📊 Advanced Usage Patterns

### Complete Ingestion Workflow
```python
from congress_ingestor import parallel_ingest
from config import load_config
from database import initialize_database, create_schema
from utils import calculate_optimal_workers, log_ingestion_stats

# 1. Load and validate configuration
config = load_config()
is_valid, errors = validate_config(config)

if not is_valid:
    # Handle configuration errors
    raise Exception(f"Configuration errors: {errors}")

# 2. Initialize database
db = initialize_database(config['database'])
create_schema(db)

# 3. Calculate optimal workers
workers = calculate_optimal_workers()

# 4. Define collections to ingest
collections = ['bills', 'legislators', 'votes', 'committees']

# 5. Perform parallel ingestion
result = parallel_ingest(collections, workers=workers)

# 6. Log statistics
log_ingestion_stats({
    'success_count': result['total_success'],
    'error_count': result['total_errors'],
    'duration_seconds': result['duration'],
    'collections_processed': len(collections)
})

# 7. Close database connection
db.close()
```

### Scheduled Ingestion Pattern
```python
import time
from congress_ingestor import ingest_data
from utils import log_ingestion_stats

def scheduled_ingestion():
    """Run scheduled ingestion with proper error handling"""
    
    collections = ['bills', 'legislators', 'votes']
    
    for collection in collections:
        try:
            # Ingest data with pagination
            offset = 0
            limit = 100
            
            while True:
                result = ingest_data(collection, limit=limit, offset=offset)
                
                # Log statistics
                log_ingestion_stats({
                    'collection': collection,
                    'success_count': result['success_count'],
                    'error_count': result['error_count'],
                    'offset': offset
                })
                
                # Update offset for next batch
                offset += limit
                
                # Check if more data available
                if result['success_count'] < limit:
                    break
                    
                # Respect rate limits
                time.sleep(1)
                
        except Exception as e:
            # Handle errors and continue with next collection
            log_error(handle_api_error(e))
            continue

# Run scheduled ingestion
scheduled_ingestion()
```

### Monitoring and Reporting Pattern
```python
from congress_ingestor import parallel_ingest
from utils import monitor_system_resources, generate_progress_report
import time

def monitored_ingestion():
    """Run ingestion with system monitoring and reporting"""
    
    # Start monitoring
    start_time = time.time()
    start_resources = monitor_system_resources()
    
    # Run ingestion
    collections = ['bills', 'legislators', 'votes']
    result = parallel_ingest(collections, workers=4)
    
    # End monitoring
    end_time = time.time()
    end_resources = monitor_system_resources()
    
    # Generate comprehensive report
    report = generate_progress_report({
        'total_processed': result['total_success'],
        'total_errors': result['total_errors'],
        'duration_seconds': end_time - start_time,
        'cpu_usage_start': start_resources['cpu_usage'],
        'cpu_usage_end': end_resources['cpu_usage'],
        'memory_usage_start': start_resources['memory_usage'],
        'memory_usage_end': end_resources['memory_usage']
    })
    
    print("Ingestion Report:")
    print(report)
    
    return result

# Run monitored ingestion
result = monitored_ingestion()
```

## 🎓 Best Practices for AI Agents

### Configuration Management
1. **Always validate configuration** before starting operations
2. **Use default configuration** as template for customization
3. **Handle configuration errors** gracefully
4. **Store configuration securely** with proper permissions

### Database Operations
1. **Use connection pooling** for high-performance operations
2. **Implement proper error handling** for database operations
3. **Monitor database performance** during operations
4. **Close connections properly** to avoid resource leaks

### API Operations
1. **Respect rate limits** to avoid API restrictions
2. **Implement retry logic** for transient failures
3. **Monitor API response times** for performance optimization
4. **Handle authentication properly** with secure key management

### Ingestion Operations
1. **Use parallel processing** for large datasets
2. **Implement batch processing** for memory efficiency
3. **Monitor system resources** during operations
4. **Log all operations** for debugging and analysis
5. **Validate data integrity** after ingestion

### Error Handling
1. **Implement comprehensive error handling** for all operations
2. **Log all errors** for debugging and analysis
3. **Implement recovery logic** for common error types
4. **Monitor error rates** for system health
5. **Alert on critical errors** for immediate attention

## 📚 Complete Function Reference

For complete function reference, see:
- [API Reference](API_REFERENCE.md)
- [Function Reference](FUNCTION_REFERENCE.md)

## 🤖 AI Agent Specific Tips

### Memory Management
```python
# Use batch processing for large datasets
from congress_ingestor import batch_ingest

result = batch_ingest('bills', batch_size=200)
```

### Performance Optimization
```python
# Calculate optimal workers based on system resources
from utils import calculate_optimal_workers

workers = calculate_optimal_workers()
result = parallel_ingest(collections, workers=workers)
```

### Error Recovery
```python
# Implement comprehensive error recovery
from error_handler import handle_api_error, handle_database_error

try:
    # Perform operations
except Exception as e:
    error_info = handle_api_error(e)
    
    # Implement recovery based on error type
    if error_info['recoverable']:
        # Implement recovery logic
        pass
    else:
        # Log critical error
        log_error(error_info)
```

### Monitoring and Logging
```python
# Monitor system resources during operations
from utils import monitor_system_resources

resources = monitor_system_resources()

# Log important events
from utils import log_ingestion_stats

log_ingestion_stats({
    'operation': 'data_ingestion',
    'status': 'completed',
    'records_processed': 1000
})
```

## 📖 Additional Resources

- [Complete API Reference](API_REFERENCE.md)
- [Function Reference](FUNCTION_REFERENCE.md)
- [Installation Guide](INSTALLATION.md)
- [Configuration Reference](CONFIGURATION.md)
- [Troubleshooting Guide](TROUBLESHOOTING.md)

## 🎯 Quick Reference

### Common Operations

**Ingest Data:**
```python
from congress_ingestor import ingest_data
result = ingest_data('bills', limit=100)
```

**Parallel Ingestion:**
```python
from congress_ingestor import parallel_ingest
result = parallel_ingest(['bills', 'legislators'], workers=4)
```

**Database Operations:**
```python
from database import initialize_database, insert_data
db = initialize_database(config['database'])
insert_data(db, 'bills', data)
```

**API Operations:**
```python
from api_client import fetch_api_data
data = fetch_api_data(endpoint, params)
```

**Error Handling:**
```python
from error_handler import handle_api_error
try:
    # Operation
except Exception as e:
    error_info = handle_api_error(e)
```

## 🤖 AI Agent Checklist

- [ ] Load and validate configuration
- [ ] Initialize database connection
- [ ] Calculate optimal workers
- [ ] Implement proper error handling
- [ ] Monitor system resources
- [ ] Log all operations
- [ ] Validate data integrity
- [ ] Respect rate limits
- [ ] Use connection pooling
- [ ] Implement recovery logic

This guide provides everything AI agents need to effectively use the Congress API Ingestion System with comprehensive examples and best practices.
