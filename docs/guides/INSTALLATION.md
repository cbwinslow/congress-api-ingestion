# 🛠️ Installation Guide

## Complete Installation Instructions for Congress API Ingestion System

## 📋 System Requirements

### Minimum Requirements
- Python 3.11+
- PostgreSQL 12+ or SQLite 3.35+
- 4GB RAM
- 10GB Disk Space
- Internet Connection

### Recommended Requirements
- Python 3.11+
- PostgreSQL 15+
- 8GB+ RAM
- 50GB+ Disk Space
- High-speed Internet Connection

## 🐍 Python Installation

### Install Python 3.11+

**Ubuntu/Debian:**
```bash
sudo apt update
sudo apt install python3.11 python3.11-dev python3.11-venv
```

**MacOS (Homebrew):**
```bash
brew install python@3.11
```

**Windows:**
Download from [Python.org](https://www.python.org/downloads/)

## 🗃️ Database Installation

### PostgreSQL Installation

**Ubuntu/Debian:**
```bash
sudo apt update
sudo apt install postgresql postgresql-contrib libpq-dev
```

**MacOS (Homebrew):**
```bash
brew install postgresql
brew services start postgresql
```

**Windows:**
Download from [PostgreSQL.org](https://www.postgresql.org/download/)

### SQLite Installation

SQLite is included with Python, no additional installation needed.

## 📦 Project Setup

### Clone Repository
```bash
cd /path/to/your/projects
git clone git@github.com:cbwinslow/congress-api-ingestion.git
cd congress-api-ingestion
```

### Create Virtual Environment
```bash
python -m venv venv
source venv/bin/activate  # Linux/Mac
# venv\Scripts\activate  # Windows
```

### Install Dependencies
```bash
pip install -r requirements.txt
```

## 🗃️ Database Configuration

### PostgreSQL Configuration

1. **Create Database and User:**
```bash
sudo -u postgres psql
```

2. **Execute SQL Commands:**
```sql
CREATE DATABASE opendiscourse;
CREATE USER opendiscourse WITH PASSWORD 'opendiscourse123';
GRANT ALL PRIVILEGES ON DATABASE opendiscourse TO opendiscourse;
ALTER DATABASE opendiscourse OWNER TO opendiscourse;
```

3. **Configure PostgreSQL for Remote Access (Optional):**
```bash
sudo nano /etc/postgresql/15/main/postgresql.conf
```

Uncomment and modify:
```
listen_addresses = '*'
```

4. **Configure Client Authentication:**
```bash
sudo nano /etc/postgresql/15/main/pg_hba.conf
```

Add line:
```
host    opendiscourse    opendiscourse    0.0.0.0/0    md5
```

5. **Restart PostgreSQL:**
```bash
sudo systemctl restart postgresql
```

### SQLite Configuration

No additional configuration needed. SQLite database will be created automatically.

## 📝 System Configuration

### Copy Configuration Template
```bash
cp config.example.json config.json
```

### Edit Configuration
```bash
nano config.json
```

### Configuration Options
```json
{
  "database": {
    "type": "postgresql",  // or "sqlite"
    "host": "localhost",
    "port": 5432,
    "database": "opendiscourse",
    "user": "opendiscourse",
    "password": "opendiscourse123"
  },
  "api": {
    "congress_gov": {
      "base_url": "https://api.congress.gov/v3",
      "api_key": "your_api_key_here",
      "rate_limit": 1000
    },
    "govinfo": {
      "base_url": "https://api.govinfo.gov",
      "api_key": "your_api_key_here",
      "rate_limit": 1000
    }
  },
  "ingestion": {
    "workers": 8,
    "batch_size": 100,
    "timeout": 30,
    "retry_limit": 3
  },
  "logging": {
    "level": "INFO",
    "file": "ingestion.log",
    "max_size": "10MB",
    "backup_count": 5
  }
}
```

## 🚀 System Verification

### Test Database Connection
```bash
python scripts/test_database_connection.py
```

### Test API Connection
```bash
python scripts/test_api_connection.py
```

### Run System Tests
```bash
python -m pytest tests/
```

## 📚 Additional Configuration

### PostgreSQL Extensions
```bash
./scripts/postgres_optimization/install_postgres_extensions.sh
```

### PostgreSQL Optimization
```bash
python scripts/postgres_optimization/optimize_postgres.py
```

## 🎯 Troubleshooting

### Common Issues

**Database Connection Failed:**
- Verify PostgreSQL is running
- Check credentials in config.json
- Verify network connectivity
- Check firewall settings

**API Connection Failed:**
- Verify API keys are correct
- Check internet connectivity
- Verify API endpoints are accessible
- Check rate limits

**Dependency Installation Failed:**
- Verify Python version
- Check pip version
- Try installing dependencies individually
- Check for system library dependencies

## 📖 Next Steps

After successful installation:

1. **Review Configuration:**
```bash
nano config.json
```

2. **Test System:**
```bash
python scripts/test_system.py
```

3. **Start Ingestion:**
```bash
python scripts/start_ingestion.py
```

4. **Monitor Operations:**
```bash
python scripts/monitor_system.py
```

## 🤖 AI Agent Installation Notes

For AI agents installing this system:

1. **Automate Configuration:**
```python
from config import get_default_config, save_config

config = get_default_config()
config['database']['host'] = 'your_host'
# Customize other settings

save_config(config, 'config.json')
```

2. **Automate Database Setup:**
```python
from database import initialize_database, create_schema

db = initialize_database(config['database'])
create_schema(db)
db.close()
```

3. **Automate Dependency Installation:**
```python
import subprocess

subprocess.run(['pip', 'install', '-r', 'requirements.txt'], check=True)
```

This installation guide provides everything needed to set up the Congress API Ingestion System on various platforms with comprehensive configuration options and troubleshooting guidance.
