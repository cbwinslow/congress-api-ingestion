#!/usr/bin/env python3
"""
PostgreSQL Database Health Monitoring Script
Monitors database health, performance, and ingestion status
"""

import sys
import json
import psycopg2
from datetime import datetime
from psycopg2.extras import RealDictCursor

def load_config():
    """Load database configuration"""
    with open('../config/config.json', 'r') as f:
        config = json.load(f)
    return config['database']

def test_connection(db_config):
    """Test database connection"""
    try:
        conn = psycopg2.connect(
            host=db_config['host'],
            port=db_config['port'],
            database=db_config['database'],
            user=db_config['user'],
            password=db_config['password']
        )
        conn.close()
        return True, "✅ Connected successfully"
    except Exception as e:
        return False, f"❌ Connection failed: {str(e)}"

def get_table_counts(db_config):
    """Get record counts for all tables"""
    try:
        conn = psycopg2.connect(
            host=db_config['host'],
            port=db_config['port'],
            database=db_config['database'],
            user=db_config['user'],
            password=db_config['password'],
            cursor_factory=RealDictCursor
        )
        cursor = conn.cursor()
        
        query = """
        SELECT 'collections' as table_name, COUNT(*) as record_count FROM collections
        UNION ALL
        SELECT 'packages', COUNT(*) FROM packages
        UNION ALL
        SELECT 'bills', COUNT(*) FROM bills
        UNION ALL
        SELECT 'legislators', COUNT(*) FROM legislators
        UNION ALL
        SELECT 'votes', COUNT(*) FROM votes
        UNION ALL
        SELECT 'ingestion_log', COUNT(*) FROM ingestion_log
        ORDER BY table_name;
        """
        
        cursor.execute(query)
        results = cursor.fetchall()
        
        conn.close()
        return results
    except Exception as e:
        return None

def get_ingestion_status(db_config):
    """Get recent ingestion activity"""
    try:
        conn = psycopg2.connect(
            host=db_config['host'],
            port=db_config['port'],
            database=db_config['database'],
            user=db_config['user'],
            password=db_config['password'],
            cursor_factory=RealDictCursor
        )
        cursor = conn.cursor()
        
        query = """
        SELECT 
            collection_code,
            operation_type,
            status,
            COUNT(*) as operation_count,
            MAX(started_at) as last_operation
        FROM ingestion_log 
        WHERE started_at >= NOW() - INTERVAL '24 hours'
        GROUP BY collection_code, operation_type, status
        ORDER BY last_operation DESC;
        """
        
        cursor.execute(query)
        results = cursor.fetchall()
        
        conn.close()
        return results
    except Exception as e:
        return None

def get_database_size(db_config):
    """Get database and table sizes"""
    try:
        conn = psycopg2.connect(
            host=db_config['host'],
            port=db_config['port'],
            database=db_config['database'],
            user=db_config['user'],
            password=db_config['password'],
            cursor_factory=RealDictCursor
        )
        cursor = conn.cursor()
        
        query = f"""
        SELECT 
            pg_size_pretty(pg_database_size('{db_config["database"]}')) as database_size,
            pg_size_pretty(pg_total_relation_size('packages')) as packages_size,
            pg_size_pretty(pg_total_relation_size('bills')) as bills_size;
        """
        
        cursor.execute(query)
        results = cursor.fetchone()
        
        conn.close()
        return results
    except Exception as e:
        return None

def get_recent_errors(db_config):
    """Get recent errors from ingestion log"""
    try:
        conn = psycopg2.connect(
            host=db_config['host'],
            port=db_config['port'],
            database=db_config['database'],
            user=db_config['user'],
            password=db_config['password'],
            cursor_factory=RealDictCursor
        )
        cursor = conn.cursor()
        
        query = """
        SELECT 
            collection_code,
            operation_type,
            error_message,
            started_at
        FROM ingestion_log 
        WHERE status = 'error' 
            AND started_at >= NOW() - INTERVAL '24 hours'
        ORDER BY started_at DESC
        LIMIT 10;
        """
        
        cursor.execute(query)
        results = cursor.fetchall()
        
        conn.close()
        return results
    except Exception as e:
        return None

def main():
    """Main monitoring function"""
    print("=== PostgreSQL Database Health Monitor ===")
    print()
    
    # Load configuration
    db_config = load_config()
    
    # Test connection
    print("1. Database Connection:")
    success, message = test_connection(db_config)
    print(f"   {message}")
    
    if not success:
        print("\n❌ Cannot connect to database. Please check connection settings.")
        sys.exit(1)
    
    # Get table counts
    print("\n2. Table Record Counts:")
    counts = get_table_counts(db_config)
    if counts:
        for row in counts:
            print(f"   {row['table_name']}: {row['record_count']} records")
    else:
        print("   Failed to get table counts")
    
    # Get ingestion status
    print("\n3. Recent Ingestion Activity:")
    ingestion = get_ingestion_status(db_config)
    if ingestion:
        for row in ingestion:
            print(f"   {row['collection_code']} - {row['operation_type']} - {row['status']}: {row['operation_count']} operations (last: {row['last_operation']})")
    else:
        print("   No recent ingestion activity")
    
    # Get database size
    print("\n4. Database Size:")
    sizes = get_database_size(db_config)
    if sizes:
        print(f"   Database: {sizes['database_size']}")
        print(f"   Packages table: {sizes['packages_size']}")
        print(f"   Bills table: {sizes['bills_size']}")
    else:
        print("   Failed to get database size")
    
    # Get recent errors
    print("\n5. Recent Errors:")
    errors = get_recent_errors(db_config)
    if errors and len(errors) > 0:
        for row in errors:
            print(f"   {row['started_at']} - {row['collection_code']} - {row['error_message']}")
    else:
        print("   No recent errors")
    
    print("\n✅ Monitor Complete")

if __name__ == "__main__":
    main()
