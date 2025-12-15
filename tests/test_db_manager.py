"""Unit tests for DatabaseManager."""

import unittest
import os
import tempfile
from datetime import datetime

import sys
sys.path.insert(0, '/root/congress_api_project/src')

from database.db_manager import DatabaseManager


class TestDatabaseManager(unittest.TestCase):
    """Test cases for DatabaseManager class."""
    
    def setUp(self):
        """Set up test fixtures."""
        # Use a temporary config for testing
        self.config_path = '/root/congress_api_project/config/config.json'
        self.db = DatabaseManager(self.config_path)
        
    def test_connection(self):
        """Test database connection."""
        result = self.db.connect()
        self.assertTrue(result, "Database connection should succeed")
        self.assertIsNotNone(self.db.db_type, "Database type should be set")
        self.db.disconnect()
    
    def test_collection_operations(self):
        """Test collection insert and retrieval."""
        self.db.connect()
        
        # Test collection insertion
        test_collection = {
            'collection_code': 'TEST_COLLECTION',
            'collection_name': 'Test Collection',
            'description': 'Test description',
            'last_modified': '2024-01-01T00:00:00Z'
        }
        
        result = self.db.insert_collection(test_collection)
        self.assertTrue(result, "Collection insertion should succeed")
        
        # Test collection exists by querying directly
        query = "SELECT 1 FROM collections WHERE collection_code = %s LIMIT 1"
        result = self.db.execute(query, ('TEST_COLLECTION',))
        self.assertTrue(len(result) > 0, "Collection should exist after insertion")
        
        self.db.disconnect()
    
    def test_package_operations(self):
        """Test package insert and retrieval."""
        self.db.connect()
        
        # First insert a collection
        collection_data = {
            'collection_code': 'TEST_PKG_COLLECTION',
            'collection_name': 'Test Package Collection',
            'description': 'Test',
            'last_modified': '2024-01-01T00:00:00Z'
        }
        self.db.insert_collection(collection_data)
        
        # Test package insertion
        test_package = {
            'package_id': 'TEST-PKG-001',
            'collection_code': 'TEST_PKG_COLLECTION',
            'title': 'Test Package',
            'summary': 'Test summary',
            'download_url': 'http://example.com/download',
            'details_url': 'http://example.com/details',
            'publish_date': '2024-01-01',
            'last_modified': '2024-01-01T00:00:00Z'
        }
        
        result = self.db.insert_package(test_package)
        self.assertTrue(result, "Package insertion should succeed")
        
        # Test package exists
        exists = self.db.package_exists('TEST-PKG-001')
        self.assertTrue(exists, "Package should exist after insertion")
        
        # Test duplicate prevention
        result = self.db.insert_package(test_package)
        self.assertTrue(result, "Duplicate insertion should succeed (upsert)")
        
        self.db.disconnect()
    
    def test_ingestion_log(self):
        """Test ingestion logging."""
        self.db.connect()
        
        log_data = {
            'collection_code': 'TEST_LOG_COLLECTION',
            'offset_value': 0,
            'limit_value': 100,
            'records_ingested': 50,
            'status': 'success',
            'error_message': None,
            'completed_at': '2024-01-01T00:00:00Z'
        }
        
        log_id = self.db.log_ingestion(log_data)
        self.assertIsNotNone(log_id, "Log ID should be returned")
        
        self.db.disconnect()
    
    def test_offset_tracking(self):
        """Test offset tracking functionality."""
        self.db.connect()
        
        # Insert test log entries
        log_data1 = {
            'collection_code': 'TEST_OFFSET',
            'offset_value': 0,
            'limit_value': 100,
            'records_ingested': 100,
            'status': 'success',
            'error_message': None,
            'completed_at': '2024-01-01T00:00:00Z'
        }
        
        log_data2 = {
            'collection_code': 'TEST_OFFSET',
            'offset_value': 100,
            'limit_value': 100,
            'records_ingested': 100,
            'status': 'success',
            'error_message': None,
            'completed_at': '2024-01-01T00:00:00Z'
        }
        
        self.db.log_ingestion(log_data1)
        self.db.log_ingestion(log_data2)
        
        # Test last offset retrieval
        last_offset = self.db.get_last_offset('TEST_OFFSET')
        self.assertEqual(last_offset, 200, "Last offset should be 200 (100 + 100)")
        
        # Test non-existent collection
        last_offset = self.db.get_last_offset('NON_EXISTENT')
        self.assertEqual(last_offset, 0, "Non-existent collection should return 0")
        
        self.db.disconnect()
    
    def tearDown(self):
        """Clean up after tests."""
        if hasattr(self, 'db') and self.db.conn:
            self.db.disconnect()


if __name__ == '__main__':
    unittest.main()
