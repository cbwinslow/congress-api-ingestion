# 🚀 Congress Data Parallel Ingestion System

This system provides high-performance parallel processing for ingesting Congress.gov data into PostgreSQL.

## 📦 Features

- **Multiprocessing**: Uses Python's ProcessPoolExecutor for CPU-bound tasks
- **Threading**: Uses threading for I/O-bound operations
- **Rate Limiting**: Respects Congress.gov API rate limits (1,000 requests/hour)
- **Error Handling**: Robust error handling and retry logic
- **Batch Processing**: Efficient batch processing of data
- **Deduplication**: Prevents duplicate data ingestion

## 🏗️ System Architecture

```
┌─────────────────────────────────────────────────────────────┐
│                     Congress.gov API                        │
└─────────────────────────────────────────────────────────────┘
                                    ↓
┌─────────────────────────────────────────────────────────────┐
│                 Parallel Ingestion System                   │
│                                                             │
│  ┌─────────────┐    ┌─────────────┐    ┌─────────────┐    │
│  │  Worker 1    │    │  Worker 2    │    │  Worker N    │    │
│  └─────────────┘    └─────────────┘    └─────────────┘    │
│                                                             │
│  ┌───────────────────────────────────────────────────────┐  │
│  │                   Task Queue                        │  │
│  └───────────────────────────────────────────────────────┘  │
│                                                             │
│  ┌───────────────────────────────────────────────────────┐  │
│  │                 Database Manager                   │  │
│  └───────────────────────────────────────────────────────┘  │
│                                                             │
└─────────────────────────────────────────────────────────────┘
                                    ↓
┌─────────────────────────────────────────────────────────────┐
│                     PostgreSQL Database                     │
└─────────────────────────────────────────────────────────────┘
```

## 📁 Files

- `parallel_ingestor.py`: Main parallel ingestion script
- `config.json`: Configuration file
- `create_postgres_schema.sql`: PostgreSQL database schema
- `README.md`: This documentation

## 🛠️ Requirements

- Python 3.8+
- PostgreSQL 12+
- Required Python packages:
  ```
  psycopg2-binary
  requests
  ```

## 🚀 Usage

### 1. Install Requirements

```bash
pip install psycopg2-binary requests
```

### 2. Set Up PostgreSQL

```bash
# Create database and user
sudo -u postgres psql -c "CREATE DATABASE opendiscourse;"
sudo -u postgres psql -c "CREATE USER opendiscourse WITH PASSWORD 'opendiscourse123';"
sudo -u postgres psql -c "GRANT ALL PRIVILEGES ON DATABASE opendiscourse TO opendiscourse;"

# Apply schema
psql -d opendiscourse -f create_postgres_schema.sql
```

### 3. Configure

Edit `config.json` with your API key and database credentials.

### 4. Run Ingestion

```bash
# Run the parallel ingestor
python parallel_ingestor.py

# Or run specific ingestion tasks
python parallel_ingestor.py --bills 118 hr 100  # Ingest 100 House bills from 118th Congress
python parallel_ingestor.py --legislators current  # Ingest current legislators
python parallel_ingestor.py --votes 118 2024  # Ingest 2024 votes from 118th Congress
```

## 🎯 Performance Optimization

### Worker Configuration

Adjust the number of workers based on your system:

- **CPU-bound tasks**: Use `workers = CPU cores`
- **I/O-bound tasks**: Use `workers = 2 * CPU cores`

### Batch Size

Optimal batch sizes:
- **Bills**: 50-100 per batch
- **Legislators**: 100-200 per batch
- **Votes**: 20-50 per batch

### Rate Limiting

The system automatically respects Congress.gov API limits:
- **1,000 requests/hour**
- **30 second timeout**
- **3 retry attempts**

## 📊 Data Types Supported

### Bills
- Full text content
- Sponsors and cosponsors
- Actions and status
- Subjects and policy areas

### Legislators
- Biographical information
- Contact information
- Committee assignments
- Social media links

### Votes
- Roll call votes
- Individual vote positions
- Vote statistics by party
- Bill associations

### Committees
- Committee membership
- Jurisdiction information
- Subcommittees
- Leadership roles

## 🔧 Advanced Configuration

### Custom API Endpoints

Add custom endpoints to the configuration:

```json
"custom_endpoints": {
  "recent_bills": "/bill?congress=118&limit=100",
  "house_members": "/member/house?congress=118",
  "senate_votes": "/vote/senate?congress=118&year=2024"
}
```

### Error Handling

Configure retry logic and timeouts:

```json
"error_handling": {
  "max_retries": 5,
  "timeout": 60,
  "retry_delay": 5,
  "skip_errors": true
}
```

## 📈 Monitoring

### Log Ingestion Progress

```bash
# View ingestion log
tail -f ingestion.log

# Check database statistics
psql -d opendiscourse -c "SELECT COUNT(*) FROM congress.bills;"
psql -d opendiscourse -c "SELECT COUNT(*) FROM congress.legislators;"
```

### Performance Metrics

```bash
# Monitor system resources
top
htop

# Check PostgreSQL performance
psql -d opendiscourse -c "SELECT * FROM pg_stat_activity;"
```

## 🎓 Best Practices

### 1. Start Small

Begin with small batches to test connectivity and performance:

```bash
python parallel_ingestor.py --bills 118 hr 10  # Just 10 bills
```

### 2. Monitor Resources

Watch CPU, memory, and network usage during ingestion.

### 3. Backup Regularly

```bash
pg_dump -U opendiscourse -d opendiscourse > backup.sql
```

### 4. Optimize Database

```bash
VACUUM ANALYZE;
CREATE INDEX IF NOT EXISTS idx_bills_congress ON congress.bills(congress);
```

## 🚨 Troubleshooting

### Connection Issues

```bash
# Test API connection
curl -H "X-API-KEY: YOUR_KEY" "https://api.congress.gov/v3/bill/118/hr/1"

# Test database connection
psql -h localhost -U opendiscourse -d opendiscourse -c "SELECT 1;"
```

### Rate Limiting

```bash
# Check API rate limits
# Congress.gov allows 1,000 requests/hour
# The system automatically handles rate limiting
```

### Performance Issues

```bash
# Reduce worker count
python parallel_ingestor.py --workers 2

# Increase batch size
python parallel_ingestor.py --batch-size 20
```

## 🎯 Next Steps

1. **Test with small batches**
2. **Monitor performance**
3. **Scale up gradually**
4. **Set up regular ingestion schedule**

## 📚 Resources

- [Congress.gov API Documentation](https://api.congress.gov/)
- [PostgreSQL Documentation](https://www.postgresql.org/docs/)
- [Python Multiprocessing Guide](https://docs.python.org/3/library/multiprocessing.html)

---

**🚀 Ready to ingest massive amounts of Congress data with parallel processing!**
