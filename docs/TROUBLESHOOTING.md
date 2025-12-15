# 🔧 Troubleshooting Guide

## Complete Troubleshooting Guide for Congress API Ingestion System

## 🚨 Common Issues and Solutions

### Database Connection Issues

**Symptom:** Database connection failed

**Possible Causes:**
- Database server not running
- Incorrect credentials
- Network connectivity issues
- Firewall blocking connection
- Database not created

**Solutions:**

1. **Check Database Server:**
```bash
sudo systemctl status postgresql
```

2. **Verify Credentials:**
```bash
psql -h localhost -U opendiscourse -d opendiscourse
```

3. **Test Network Connectivity:**
```bash
ping your_database_host
telnet your_database_host 5432
```

4. **Check Firewall:**
```bash
sudo ufw status
sudo iptables -L
```

5. **Verify Database Exists:**
```bash
sudo -u postgres psql -l
```

### API Connection Issues

**Symptom:** API connection failed or rate limited

**Possible Causes:**
- Invalid API key
- Rate limit exceeded
- Network connectivity issues
- API endpoint unavailable
- Authentication failed

**Solutions:**

1. **Verify API Key:**
```python
from api_client import test_api_key
result = test_api_key('your_api_key')
```

2. **Check Rate Limits:**
```python
from api_client import check_rate_limit
limit_info = check_rate_limit()
```

3. **Test Network Connectivity:**
```bash
ping api.congress.gov
curl -v https://api.congress.gov/v3
```

4. **Check API Status:**
```bash
curl -I https://api.congress.gov/v3/status
```

### Dependency Installation Issues

**Symptom:** pip install fails

**Possible Causes:**
- Python version incompatible
- Missing system dependencies
- Network connectivity issues
- pip version outdated
- Permission issues

**Solutions:**

1. **Check Python Version:**
```bash
python --version
```

2. **Update pip:**
```bash
pip install --upgrade pip
```

3. **Install System Dependencies:**
```bash
sudo apt install python3-dev libpq-dev build-essential
```

4. **Use Virtual Environment:**
```bash
python -m venv venv
source venv/bin/activate
pip install -r requirements.txt
```

5. **Install Dependencies Individually:**
```bash
pip install requests
pip install psycopg2-binary
```

### Performance Issues

**Symptom:** Slow ingestion or high resource usage

**Possible Causes:**
- Too many workers
- Large batch sizes
- Network latency
- Database bottlenecks
- System resource constraints

**Solutions:**

1. **Optimize Workers:**
```python
from utils import calculate_optimal_workers
workers = calculate_optimal_workers()
```

2. **Reduce Batch Size:**
```python
result = ingest_data('bills', batch_size=50)
```

3. **Monitor System Resources:**
```python
from utils import monitor_system_resources
resources = monitor_system_resources()
```

4. **Optimize Database:**
```bash
./scripts/postgres_optimization/optimize_postgres.py
```

5. **Check Network Performance:**
```bash
ping -c 10 api.congress.gov
```

### Data Quality Issues

**Symptom:** Missing or incorrect data

**Possible Causes:**
- API changes
- Data format issues
- Parsing errors
- Network errors during transfer
- Rate limiting interruptions

**Solutions:**

1. **Validate API Response:**
```python
from api_client import validate_api_response
is_valid = validate_api_response(response)
```

2. **Check Data Integrity:**
```python
from utils import validate_data_integrity
is_valid = validate_data_integrity(data)
```

3. **Implement Retry Logic:**
```python
from api_client import fetch_api_data

for attempt in range(3):
    try:
        data = fetch_api_data(endpoint)
        break
    except Exception as e:
        if attempt == 2:
            raise
        time.sleep(5)
```

4. **Verify Data Schema:**
```python
from utils import validate_schema
is_valid = validate_schema(data, expected_schema)
```

## 🔍 Diagnostic Tools

### System Diagnostic
```bash
./scripts/system_diagnostic.sh
```

### Database Diagnostic
```bash
./scripts/database_diagnostic.sh
```

### API Diagnostic
```bash
./scripts/api_diagnostic.sh
```

### Network Diagnostic
```bash
./scripts/network_diagnostic.sh
```

## 📊 Error Codes and Messages

### Database Error Codes

| Code | Message | Solution |
|------|---------|----------|
| DB-001 | Connection failed | Check database credentials and network |
| DB-002 | Authentication failed | Verify username and password |
| DB-003 | Database not found | Create database or check name |
| DB-004 | Table not found | Run schema creation |
| DB-005 | Connection timeout | Check database server status |

### API Error Codes

| Code | Message | Solution |
|------|---------|----------|
| API-001 | Invalid API key | Check and update API key |
| API-002 | Rate limit exceeded | Wait and retry with delay |
| API-003 | Endpoint not found | Verify API endpoint URL |
| API-004 | Connection timeout | Check network connectivity |
| API-005 | Authentication failed | Verify API credentials |

### Ingestion Error Codes

| Code | Message | Solution |
|------|---------|----------|
| ING-001 | Data validation failed | Check data format and schema |
| ING-002 | Batch processing failed | Reduce batch size |
| ING-003 | Worker initialization failed | Check system resources |
| ING-004 | Rate limit exceeded | Implement delay and retry |
| ING-005 | Data integrity check failed | Verify data source |

## 🧰 Debugging Techniques

### Logging and Monitoring

1. **Enable Debug Logging:**
```json
"logging": {
  "level": "DEBUG",
  "console": true
}
```

2. **Monitor Ingestion Process:**
```bash
tail -f ingestion.log
```

3. **Check System Resources:**
```bash
top
htop
free -m
df -h
```

### Step-by-Step Debugging

1. **Isolate the Issue:**
   - Identify specific component causing problems
   - Test individual functions

2. **Check Logs:**
   - Review error messages
   - Look for patterns in failures

3. **Test Components Individually:**
   - Test database connection
   - Test API connection
   - Test configuration loading

4. **Implement Additional Logging:**
```python
import logging
logging.basicConfig(level=logging.DEBUG)
```

5. **Use Debugging Tools:**
```python
import pdb
pdb.set_trace()
```

## 🤖 AI Agent Troubleshooting Tips

### Automated Error Handling
```python
from error_handler import handle_api_error, handle_database_error

try:
    # Perform operation
except Exception as e:
    error_info = handle_api_error(e)
    
    # Implement automated recovery
    if error_info['recoverable']:
        # Implement recovery logic
        pass
    else:
        # Log and alert
        log_error(error_info)
        alert_admin(error_info)
```

### Automated System Monitoring
```python
from utils import monitor_system_resources

resources = monitor_system_resources()

# Check resource thresholds
if resources['cpu_usage'] > 90:
    # Implement CPU usage mitigation
    pass

if resources['memory_usage'] > 85:
    # Implement memory management
    pass
```

### Automated Configuration Validation
```python
from config import validate_config

config = load_config()
is_valid, errors = validate_config(config)

if not is_valid:
    # Implement automated configuration repair
    for error in errors:
        if 'database' in error:
            # Fix database configuration
            pass
        elif 'api' in error:
            # Fix API configuration
            pass
```

## 📚 Common Solutions

### Reset Database Connection
```python
from database import initialize_database

try:
    db.close()
except:
    pass

db = initialize_database(config['database'])
```

### Clear Rate Limit Cache
```python
from api_client import clear_rate_limit_cache

clear_rate_limit_cache()
```

### Restart Ingestion Process
```python
from congress_ingestor import restart_ingestion

restart_ingestion()
```

### Validate System Configuration
```python
from config import validate_system_configuration

is_valid = validate_system_configuration()
```

## 🎯 Prevention and Maintenance

### Regular Maintenance Tasks

1. **Database Maintenance:**
```bash
./scripts/database_maintenance.sh
```

2. **System Updates:**
```bash
./scripts/system_update.sh
```

3. **Configuration Backup:**
```bash
./scripts/backup_config.sh
```

### Best Practices for Prevention

1. **Regular Backups:**
   - Database backups
   - Configuration backups
   - Code backups

2. **Monitoring:**
   - System resource monitoring
   - Error rate monitoring
   - Performance monitoring

3. **Testing:**
   - Regular system testing
   - Configuration validation
   - API endpoint testing

4. **Documentation:**
   - Maintain up-to-date documentation
   - Document configuration changes
   - Document troubleshooting steps

## 📖 Additional Resources

- [Installation Guide](INSTALLATION.md)
- [Configuration Reference](CONFIGURATION.md)
- [API Reference](API_REFERENCE.md)
- [Function Reference](FUNCTION_REFERENCE.md)
- [User Guide](USER_GUIDE.md)

## 🤝 Support and Community

### Getting Help

1. **Check Documentation:**
   - Review all documentation files
   - Check examples and guides

2. **Review Logs:**
   - Check ingestion.log
   - Review system logs

3. **Community Support:**
   - GitHub Issues
   - Discussion Forums
   - Community Chat

4. **Professional Support:**
   - Contact support team
   - Request professional services
   - Schedule consultation

This troubleshooting guide provides comprehensive solutions for common issues with the Congress API Ingestion System, including diagnostic tools, error codes, and prevention strategies.
