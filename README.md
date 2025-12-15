# Congress API Data Ingestion System

A comprehensive data ingestion system for retrieving and storing congressional data from the GovInfo API. This system provides robust pagination, rate limiting, duplicate prevention, and supports both PostgreSQL and SQLite databases.

## Features

- **Dual Database Support**: PostgreSQL (production) and SQLite (development/fallback)
- **Robust API Client**: Rate limiting, pagination, and error handling
- **Duplicate Prevention**: Automatic detection and skipping of existing records
- **Pagination Tracking**: Resumes from last successful offset
- **Comprehensive Logging**: Detailed ingestion logs for monitoring and debugging
- **Flexible Configuration**: JSON-based configuration with secure API key storage
- **Comprehensive Testing**: Unit tests for all major components

## Project Structure

```
congress_api_project/
├── config/
│   └── config.json              # Configuration and API keys
├── data/
│   └── congress_data.db         # SQLite database (fallback)
├── src/
│   ├── database/
│   │   └── db_manager.py        # Database abstraction layer
│   ├── ingestion/
│   │   ├── api_client.py        # GovInfo API client
│   │   └── ingestion_engine.py  # Main ingestion orchestration
│   └── utils/
│       └── helpers.py           # Utility functions
├── tests/
│   └── test_db_manager.py       # Unit tests
├── main.py                      # Main entry point
├── requirements.txt             # Python dependencies
└── README.md                    # This file
```

## Prerequisites

- Python 3.8+
- PostgreSQL 12+ (optional, SQLite used by default)
- GovInfo API key (get one at https://api.data.gov/signup/)

## Installation

1. **Clone or create the project directory**:
   ```bash
   mkdir -p /root/congress_api_project
   cd /root/congress_api_project
   ```

2. **Create virtual environment and install dependencies**:
   ```bash
   python3 -m venv venv
   source venv/bin/activate
   pip install -r requirements.txt
   ```

3. **Configure API keys**:
   Edit `config/config.json` and add your GovInfo API key:
   ```json
   {
     "govinfo_api": {
       "api_key": "YOUR_GOVINFO_API_KEY_HERE",
       "base_url": "https://api.govinfo.gov"
     },
     "database": {
       "type": "sqlite",
       "path": "/root/congress_api_project/data/congress_data.db"
     }
   }
   ```

4. **Initialize the database**:
   The system will automatically create tables on first run.

## Usage

### Testing API Connection

Test your API connection and list available collections:

```bash
python main.py --test-api
```

### Ingesting Collections

Ingest all available collections from the GovInfo API:

```bash
python main.py --ingest-collections
```

### Ingesting Packages

Ingest packages from a specific collection:

```bash
# Ingest first 100 packages from BILLS collection
python main.py --ingest-packages BILLS --max-packages 100

# Ingest packages from CREC collection with date range
python main.py --ingest-packages CREC --start-date 2024-01-01 --end-date 2024-12-31

# Ingest all packages from BILLS collection (use with caution!)
python main.py --ingest-packages BILLS
```

### Viewing Statistics

View ingestion statistics and recent activity:

```bash
python main.py --stats
```

### Command Line Options

```
python main.py [OPTIONS]

Options:
  --ingest-collections           Ingest all collections from API
  --ingest-packages COLLECTION   Ingest packages from specified collection
  --max-packages N               Maximum packages to ingest (default: all)
  --batch-size N                 Packages per API call (default: 100, max: 1000)
  --start-date DATE              Start date filter (YYYY-MM-DD)
  --end-date DATE                End date filter (YYYY-MM-DD)
  --stats                        Show ingestion statistics
  --test-api                     Test API connection
  --config PATH                  Path to config file
```

## Available Collections

The GovInfo API provides access to the following key collections:

- **BILLS**: Congressional bills and resolutions
- **BILLSTATUS**: Bill status information
- **CREC**: Congressional Record
- **CFR**: Code of Federal Regulations
- **FR**: Federal Register
- **PLAW**: Public Laws
- **STATUTE**: United States Statutes at Large
- **USCODE**: United States Code
- **CHRG**: Congressional Hearings
- **HOUSE**: House documents and reports
- **SENATE**: Senate documents and reports

## Database Schema

### Collections Table

```sql
CREATE TABLE collections (
    id SERIAL PRIMARY KEY,
    collection_code VARCHAR(50) UNIQUE NOT NULL,
    collection_name VARCHAR(255),
    description TEXT,
    last_modified TIMESTAMP,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);
```

### Packages Table

```sql
CREATE TABLE packages (
    id SERIAL PRIMARY KEY,
    package_id VARCHAR(255) UNIQUE NOT NULL,
    collection_code VARCHAR(50) NOT NULL,
    title TEXT,
    summary TEXT,
    download_url TEXT,
    details_url TEXT,
    publish_date DATE,
    last_modified TIMESTAMP,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (collection_code) REFERENCES collections(collection_code)
);
```

### Ingestion Log Table

```sql
CREATE TABLE ingestion_log (
    id SERIAL PRIMARY KEY,
    collection_code VARCHAR(50) NOT NULL,
    offset_value INTEGER NOT NULL,
    limit_value INTEGER NOT NULL,
    records_ingested INTEGER DEFAULT 0,
    status VARCHAR(20) NOT NULL,
    error_message TEXT,
    completed_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);
```

## Rate Limiting

The system implements automatic rate limiting:

- **Default**: 1,000 requests per hour
- **Minimum interval**: 100ms between requests (10 req/sec)
- **Automatic throttling**: System sleeps when limits are reached

## Pagination

The system handles pagination automatically:

- **Offset tracking**: Resumes from last successful offset
- **Batch processing**: Configurable batch sizes (default: 100, max: 1000)
- **Progress tracking**: Detailed logging of ingestion progress

## Duplicate Prevention

- **Package ID checking**: Automatically skips existing packages
- **Upsert logic**: Updates existing records if modified
- **Collection tracking**: Maintains referential integrity

## Testing

Run the test suite:

```bash
# Run all tests
python -m pytest tests/ -v

# Run specific test file
python -m pytest tests/test_db_manager.py -v

# Run with coverage
python -m pytest tests/ --cov=src --cov-report=html
```

## Configuration

### Database Configuration

**SQLite (Default)**:
```json
{
  "database": {
    "type": "sqlite",
    "path": "/root/congress_api_project/data/congress_data.db"
  }
}
```

**PostgreSQL**:
```json
{
  "database": {
    "type": "postgresql",
    "host": "localhost",
    "port": 5432,
    "database": "opendiscourse",
    "user": "opendiscourse",
    "password": "opendiscourse123"
  }
}
```

### API Configuration

```json
{
  "govinfo_api": {
    "api_key": "YOUR_API_KEY_HERE",
    "base_url": "https://api.govinfo.gov"
  }
}
```

## Troubleshooting

### API Connection Issues

- **403 Forbidden**: Check your API key in `config/config.json`
- **Rate limit exceeded**: Wait for the hourly limit to reset
- **Network errors**: Verify internet connectivity and firewall settings

### Database Issues

- **PostgreSQL connection refused**: Ensure PostgreSQL is running and accessible
- **SQLite fallback**: System automatically falls back to SQLite if PostgreSQL unavailable
- **Permission errors**: Check database user permissions and file system access

### Ingestion Issues

- **Empty results**: Verify collection code and date ranges
- **Duplicate errors**: Normal behavior, system skips existing records
- **API errors**: Check API status at https://api.govinfo.gov/

## API Endpoints Used

- `GET /collections` - List all available collections
- `GET /collections/{collectionCode}` - Retrieve packages from a collection
- `GET /packages/{packageId}` - Get detailed package information

## Performance Considerations

- **Batch size**: Larger batches (up to 1000) reduce API calls but increase memory usage
- **Date filtering**: Use date ranges to limit data volume
- **Incremental ingestion**: System tracks progress and resumes automatically
- **Database optimization**: PostgreSQL recommended for large-scale ingestion

## Security

- **API key storage**: Stored in configuration file, not in code
- **Database credentials**: Encrypted in production environments
- **Input validation**: All API parameters validated before use
- **SQL injection prevention**: Parameterized queries throughout

## Monitoring

Monitor ingestion progress:

1. **Real-time logging**: All operations logged to console
2. **Database logs**: Check `ingestion_log` table for detailed history
3. **API usage**: Monitor rate limit usage in statistics
4. **Error tracking**: Errors logged with detailed messages

## Contributing

1. Fork the repository
2. Create a feature branch
3. Write tests for new functionality
4. Ensure all tests pass
5. Submit a pull request

## License

This project is provided as-is for educational and research purposes.

## Support

For issues or questions:

1. Check the troubleshooting section above
2. Review the test suite for usage examples
3. Check API documentation at https://api.govinfo.gov/docs/

## Changelog

### Version 1.0.0 (2024-12-14)
- Initial release
- Dual database support (PostgreSQL + SQLite)
- Comprehensive pagination and rate limiting
- Duplicate prevention and progress tracking
- Full test coverage
- Command-line interface
