# 🎯 User Guide: Congress Data Parallel Ingestion System

Welcome! This guide will help you set up and run the Congress data ingestion system on your own computer.

## 📋 What You'll Get

- **Complete PostgreSQL database** with Congress data
- **High-performance parallel ingestion** system
- **All data types**: Bills, Legislators, Votes, Committees
- **Ready-to-use queries** and analysis tools

## 🚀 Quick Start (5 Minutes)

### 1. Download the Repository

```bash
# Clone the repository
git clone https://github.com/cbwinslow/congress-api-ingestion.git
cd congress-api-ingestion

# Or download as ZIP
wget https://github.com/cbwinslow/congress-api-ingestion/archive/refs/heads/main.zip
unzip main.zip
cd congress-api-ingestion-main
```

### 2. Run the Setup Script

```bash
# Make the script executable
chmod +x scripts/parallel_ingestion/setup_postgres.sh

# Run as root (required for PostgreSQL setup)
sudo ./scripts/parallel_ingestion/setup_postgres.sh
```

**This script will:**
- ✅ Install PostgreSQL (if not installed)
- ✅ Create database and user
- ✅ Apply Congress data schema
- ✅ Install Python requirements
- ✅ Create configuration files

### 3. Start Data Ingestion

```bash
# Run the parallel ingestor
python scripts/parallel_ingestion/parallel_ingestor.py
```

**That's it!** The system will start ingesting Congress data automatically.

## 📦 What's Included

### Files You Need:

```
congress-api-ingestion/
├── scripts/parallel_ingestion/
│   ├── setup_postgres.sh          # Main setup script
│   ├── parallel_ingestor.py      # Parallel ingestion system
│   ├── create_postgres_schema.sql # Database schema
│   ├── config.json               # Configuration file
│   ├── README.md                 # Technical documentation
│   └── USER_GUIDE.md             # This guide
├── requirements.txt              # Python dependencies
└── data/                         # Data storage (created automatically)
```

### Database Schema:

The system creates a comprehensive PostgreSQL schema with:

- **12 tables** for all Congress data types
- **15 indexes** for fast queries
- **Automatic timestamps** for all records
- **JSONB fields** for flexible metadata
- **Foreign key relationships** for data integrity

## 🛠️ Requirements

### System Requirements:

- **Operating System**: Linux (Ubuntu/Debian recommended)
- **Memory**: 4GB+ RAM
- **Storage**: 10GB+ free space
- **Python**: 3.8+
- **PostgreSQL**: 12+ (installed automatically)

### Python Dependencies:

```
psycopg2-binary==2.9.9
requests==2.31.0
```

## 🎯 Ingestion Options

### Option 1: Full Ingestion (Recommended)

```bash
python scripts/parallel_ingestion/parallel_ingestor.py
```

**What it does:**
- Ingests 50 recent House bills
- Ingests current legislators
- Ingests recent votes
- Takes ~5-10 minutes

### Option 2: Custom Ingestion

```bash
# Ingest specific bills
python scripts/parallel_ingestion/parallel_ingestor.py --bills 118 hr 100

# Ingest legislators
python scripts/parallel_ingestion/parallel_ingestor.py --legislators current

# Ingest votes
python scripts/parallel_ingestion/parallel_ingestor.py --votes 118 2024
```

### Option 3: Large-Scale Ingestion

```bash
# Ingest all bills from 118th Congress (takes longer)
python scripts/parallel_ingestion/parallel_ingestor.py --bills 118 hr 1000
python scripts/parallel_ingestion/parallel_ingestor.py --bills 118 s 500

# Ingest all current legislators
python scripts/parallel_ingestion/parallel_ingestor.py --legislators all
```

## 📊 Data Types Explained

### Bills
- **Full text** of legislation
- **Sponsors and cosponsors**
- **Actions and status**
- **Subjects and policy areas**
- **Committee referrals**

### Legislators
- **Biographical information**
- **Contact information**
- **Committee assignments**
- **Social media links**
- **Term information**

### Votes
- **Roll call votes**
- **Individual positions**
- **Party breakdowns**
- **Bill associations**
- **Vote statistics**

### Committees
- **Membership lists**
- **Jurisdiction info**
- **Subcommittees**
- **Leadership roles**
- **Contact information**

## 🔧 Configuration

Edit `config.json` to customize:

```json
{
  "congress_api": {
    "base_url": "https://api.congress.gov/v3",
    "api_key": "YOUR_API_KEY_HERE"
  },
  "database": {
    "postgresql": {
      "database": "opendiscourse",
      "user": "opendiscourse",
      "password": "opendiscourse123",
      "host": "localhost",
      "port": 5432
    }
  },
  "ingestion_settings": {
    "workers": 4,           // Number of parallel workers
    "rate_limit": 1000,     // API requests per hour
    "batch_size": 50,       // Items per batch
    "max_retries": 3,       // Retry failed requests
    "timeout": 30           // Request timeout (seconds)
  }
}
```

## 📈 Performance Tips

### Optimize Workers

Adjust based on your CPU:
- **4-8 cores**: Use 4 workers
- **8-16 cores**: Use 8 workers
- **16+ cores**: Use 12-16 workers

### Batch Size

Optimal batch sizes:
- **Bills**: 50-100 per batch
- **Legislators**: 100-200 per batch
- **Votes**: 20-50 per batch

### Memory Usage

Monitor memory during large ingestions:
```bash
htop
free -h
```

## 🔍 Query Examples

### Recent Bills
```sql
SELECT bill_id, title, sponsor_name, introduced_date
FROM congress.bills
ORDER BY introduced_date DESC
LIMIT 20;
```

### Legislators by State
```sql
SELECT name, party, state, chamber
FROM congress.legislators
WHERE state = 'CA' AND in_office = TRUE;
```

### Recent Votes
```sql
SELECT vote_id, question, result, vote_date
FROM congress.votes
ORDER BY vote_date DESC
LIMIT 10;
```

### Bills by Sponsor
```sql
SELECT b.bill_id, b.title, b.introduced_date
FROM congress.bills b
JOIN congress.legislators l ON b.sponsor_id = l.legislator_id
WHERE l.name = 'Nancy Pelosi';
```

## 🎓 Advanced Usage

### Custom API Endpoints

Add custom endpoints to the ingestor:
```python
# In parallel_ingestor.py
custom_endpoints = {
    'recent_bills': '/bill?congress=118&limit=100',
    'house_members': '/member/house?congress=118'
}
```

### Error Handling

Configure retry logic:
```json
"error_handling": {
  "max_retries": 5,
  "timeout": 60,
  "retry_delay": 5,
  "skip_errors": true
}
```

### Monitoring

Track ingestion progress:
```bash
# View logs
tail -f ingestion.log

# Check database stats
psql -d opendiscourse -c "SELECT COUNT(*) FROM congress.bills;"
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
python scripts/parallel_ingestion/parallel_ingestor.py --workers 2

# Increase batch size
python scripts/parallel_ingestion/parallel_ingestor.py --batch-size 20
```

## 🎯 Next Steps

### 1. Start Small
```bash
python scripts/parallel_ingestion/parallel_ingestor.py --bills 118 hr 10
```

### 2. Monitor Performance
```bash
htop
psql -d opendiscourse -c "SELECT COUNT(*) FROM congress.bills;"
```

### 3. Scale Up
```bash
python scripts/parallel_ingestion/parallel_ingestor.py --bills 118 hr 500
python scripts/parallel_ingestion/parallel_ingestor.py --legislators all
```

### 4. Set Up Regular Updates
```bash
# Add to crontab for daily updates
0 3 * * * /path/to/congress-api-ingestion/scripts/parallel_ingestion/parallel_ingestor.py --bills 118 hr 50
```

## 📚 Resources

- **Congress.gov API**: https://api.congress.gov/
- **PostgreSQL Docs**: https://www.postgresql.org/docs/
- **Python Multiprocessing**: https://docs.python.org/3/library/multiprocessing.html

## 🎉 Success!

You now have a complete Congress data system with:
- ✅ High-performance parallel ingestion
- ✅ Comprehensive PostgreSQL database
- ✅ All major data types
- ✅ Ready-to-use queries
- ✅ Scalable architecture

**🚀 Start ingesting data now!**

```bash
python scripts/parallel_ingestion/parallel_ingestor.py
```
