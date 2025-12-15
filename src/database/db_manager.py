"""Database manager with support for PostgreSQL and SQLite fallback."""

import json
import os
import sqlite3
from typing import Any, Dict, List, Optional
from datetime import datetime

try:
    import psycopg2
    from psycopg2.extras import RealDictCursor
    POSTGRES_AVAILABLE = True
except ImportError:
    POSTGRES_AVAILABLE = False


class DatabaseManager:
    """Manages database connections and operations."""
    
    def __init__(self, config_path: str = '/root/congress_api_project/config/config.json'):
        """Initialize database manager with config.
        
        Args:
            config_path: Path to configuration file
        """
        self.config_path = config_path
        self.db_type = None
        self.conn = None
        self._load_config()
    
    def _load_config(self):
        """Load database configuration."""
        with open(self.config_path, 'r') as f:
            config = json.load(f)
        self.db_config = config.get('database', {})
    
    def connect(self) -> bool:
        """Connect to database (PostgreSQL or SQLite fallback).
        
        Returns:
            True if connection successful, False otherwise
        """
        # Try PostgreSQL first
        if POSTGRES_AVAILABLE:
            try:
                self.conn = psycopg2.connect(
                    host=self.db_config.get('host', 'localhost'),
                    port=self.db_config.get('port', 5432),
                    database=self.db_config.get('database', 'opendiscourse'),
                    user=self.db_config.get('user', 'opendiscourse'),
                    password=self.db_config.get('password', '')
                )
                self.db_type = 'postgresql'
                print(f"✓ Connected to PostgreSQL: {self.db_config['database']}")
                return True
            except Exception as e:
                print(f"PostgreSQL connection failed: {e}")
        
        # Fallback to SQLite
        try:
            db_path = '/root/congress_api_project/data/congress_data.db'
            os.makedirs(os.path.dirname(db_path), exist_ok=True)
            self.conn = sqlite3.connect(db_path)
            self.db_type = 'sqlite'
            print(f"✓ Connected to SQLite: {db_path}")
            return True
        except Exception as e:
            print(f"SQLite connection failed: {e}")
            return False
    
    def disconnect(self):
        """Close database connection."""
        if self.conn:
            self.conn.close()
            self.conn = None
    
    def execute(self, query: str, params: tuple = ()) -> List[Dict[str, Any]]:
        """Execute a query and return results.
        
        Args:
            query: SQL query string
            params: Query parameters
            
        Returns:
            List of dictionaries representing rows
        """
        if not self.conn:
            raise ConnectionError("Not connected to database")
        
        try:
            cur = self.conn.cursor()
            
            # Handle parameter style differences
            if self.db_type == 'sqlite':
                # SQLite uses ? placeholders
                query = query.replace('%s', '?')
            
            cur.execute(query, params)
            
            if cur.description:
                columns = [desc[0] for desc in cur.description]
                rows = [dict(zip(columns, row)) for row in cur.fetchall()]
            else:
                rows = []
            
            self.conn.commit()
            cur.close()
            return rows
            
        except Exception as e:
            self.conn.rollback()
            raise e
    
    def insert_collection(self, collection_data: Dict[str, Any]) -> bool:
        """Insert or update a collection.
        
        Args:
            collection_data: Dictionary with collection_code, collection_name, etc.
            
        Returns:
            True if successful
        """
        query = """
            INSERT INTO collections (collection_code, collection_name, description, last_modified)
            VALUES (%s, %s, %s, %s)
            ON CONFLICT (collection_code) 
            DO UPDATE SET 
                collection_name = EXCLUDED.collection_name,
                description = EXCLUDED.description,
                last_modified = EXCLUDED.last_modified,
                updated_at = CURRENT_TIMESTAMP
        """
        
        params = (
            collection_data.get('collection_code'),
            collection_data.get('collection_name'),
            collection_data.get('description'),
            collection_data.get('last_modified')
        )
        
        self.execute(query, params)
        return True
    
    def insert_package(self, package_data: Dict[str, Any]) -> bool:
        """Insert or update a package.
        
        Args:
            package_data: Dictionary with package_id, collection_code, etc.
            
        Returns:
            True if successful
        """
        query = """
            INSERT INTO packages (
                package_id, collection_code, title, summary,
                download_url, details_url, publish_date, last_modified
            )
            VALUES (%s, %s, %s, %s, %s, %s, %s, %s)
            ON CONFLICT (package_id)
            DO UPDATE SET
                collection_code = EXCLUDED.collection_code,
                title = EXCLUDED.title,
                summary = EXCLUDED.summary,
                download_url = EXCLUDED.download_url,
                details_url = EXCLUDED.details_url,
                publish_date = EXCLUDED.publish_date,
                last_modified = EXCLUDED.last_modified,
                updated_at = CURRENT_TIMESTAMP
        """
        
        params = (
            package_data.get('package_id'),
            package_data.get('collection_code'),
            package_data.get('title'),
            package_data.get('summary'),
            package_data.get('download_url'),
            package_data.get('details_url'),
            package_data.get('publish_date'),
            package_data.get('last_modified')
        )
        
        self.execute(query, params)
        return True
    
    def log_ingestion(self, log_data: Dict[str, Any]) -> int:
        """Log an ingestion attempt.
        
        Args:
            log_data: Dictionary with collection_code, offset_value, etc.
            
        Returns:
            Log ID
        """
        query = """
            INSERT INTO ingestion_log (
                collection_code, offset_value, limit_value,
                records_ingested, status, error_message, completed_at
            )
            VALUES (%s, %s, %s, %s, %s, %s, %s)
            RETURNING id
        """
        
        params = (
            log_data.get('collection_code'),
            log_data.get('offset_value'),
            log_data.get('limit_value'),
            log_data.get('records_ingested'),
            log_data.get('status'),
            log_data.get('error_message'),
            log_data.get('completed_at')
        )
        
        result = self.execute(query, params)
        return result[0]['id'] if result else None
    
    def get_last_offset(self, collection_code: str) -> int:
        """Get the last successful offset for a collection.
        
        Args:
            collection_code: Collection code
            
        Returns:
            Last offset value or 0 if not found
        """
        query = """
            SELECT offset_value + limit_value as last_offset
            FROM ingestion_log
            WHERE collection_code = %s AND status = 'success'
            ORDER BY id DESC
            LIMIT 1
        """
        
        result = self.execute(query, (collection_code,))
        return result[0]['last_offset'] if result else 0
    
    def package_exists(self, package_id: str) -> bool:
        """Check if a package already exists.
        
        Args:
            package_id: Package ID
            
        Returns:
            True if package exists
        """
        query = "SELECT 1 FROM packages WHERE package_id = %s LIMIT 1"
        result = self.execute(query, (package_id,))
        return len(result) > 0


if __name__ == '__main__':
    # Test database manager
    db = DatabaseManager()
    if db.connect():
        print(f"Database type: {db.db_type}")
        
        # Test collection insertion
        test_collection = {
            'collection_code': 'TEST',
            'collection_name': 'Test Collection',
            'description': 'Test description',
            'last_modified': '2024-01-01T00:00:00Z'
        }
        db.insert_collection(test_collection)
        print("✓ Collection insertion test passed")
        
        db.disconnect()
