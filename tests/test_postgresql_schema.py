"""
PostgreSQL Database Schema Validation Tests
Validates database schema, data integrity, and relationships
"""

import unittest
import json
import psycopg2
from psycopg2.extras import RealDictCursor

class PostgreSQLSchemaTest(unittest.TestCase):
    """Test PostgreSQL database schema and integrity"""
    
    @classmethod
    def setUpClass(cls):
        """Set up database connection for all tests"""
        try:
            with open('../config/config.json', 'r') as f:
                config = json.load(f)
            
            cls.db_config = config['database']
            cls.conn = psycopg2.connect(
                host=cls.db_config['host'],
                port=cls.db_config['port'],
                database=cls.db_config['database'],
                user=cls.db_config['user'],
                password=cls.db_config['password']
            )
            cls.conn.autocommit = True
            
        except Exception as e:
            cls.conn = None
            print(f"Warning: Could not connect to database: {e}")
    
    @classmethod
    def tearDownClass(cls):
        """Close database connection"""
        if cls.conn:
            cls.conn.close()
    
    def setUp(self):
        """Skip tests if database not available"""
        if not self.conn:
            self.skipTest("Database connection not available")
    
    def test_database_connection(self):
        """Test that database connection is established"""
        cursor = self.conn.cursor()
        cursor.execute("SELECT version();")
        result = cursor.fetchone()
        self.assertIsNotNone(result)
        self.assertIn("PostgreSQL", result[0])
    
    def test_required_tables_exist(self):
        """Test that all required tables exist"""
        required_tables = [
            'collections',
            'packages',
            'bills',
            'legislators',
            'committees',
            'votes',
            'individual_votes',
            'congressional_record',
            'ingestion_log'
        ]
        
        cursor = self.conn.cursor()
        cursor.execute("""
            SELECT tablename 
            FROM pg_tables 
            WHERE schemaname = 'public';
        """)
        
        existing_tables = [row[0] for row in cursor.fetchall()]
        
        for table in required_tables:
            with self.subTest(table=table):
                self.assertIn(table, existing_tables, f"Table {table} does not exist")
    
    def test_collections_table_structure(self):
        """Test collections table has correct structure"""
        cursor = self.conn.cursor()
        cursor.execute("""
            SELECT column_name, data_type, is_nullable
            FROM information_schema.columns
            WHERE table_name = 'collections'
            ORDER BY column_name;
        """)
        
        columns = {row[0]: (row[1], row[2]) for row in cursor.fetchall()}
        
        # Check required columns
        self.assertIn('id', columns)
        self.assertIn('collection_code', columns)
        self.assertIn('collection_name', columns)
        self.assertIn('created_at', columns)
        self.assertIn('updated_at', columns)
        
        # Check data types
        self.assertEqual(columns['id'][0], 'integer')
        self.assertEqual(columns['collection_code'][0], 'character varying')
        self.assertEqual(columns['collection_name'][0], 'character varying')
    
    def test_packages_table_structure(self):
        """Test packages table has correct structure"""
        cursor = self.conn.cursor()
        cursor.execute("""
            SELECT column_name, data_type
            FROM information_schema.columns
            WHERE table_name = 'packages'
            ORDER BY column_name;
        """)
        
        columns = {row[0]: row[1] for row in cursor.fetchall()}
        
        # Check required columns
        self.assertIn('id', columns)
        self.assertIn('package_id', columns)
        self.assertIn('collection_code', columns)
        self.assertIn('title', columns)
        self.assertIn('metadata', columns)
        self.assertIn('created_at', columns)
        self.assertIn('updated_at', columns)
        
        # Check JSONB fields
        self.assertEqual(columns['metadata'], 'jsonb')
    
    def test_bills_table_structure(self):
        """Test bills table has correct structure"""
        cursor = self.conn.cursor()
        cursor.execute("""
            SELECT column_name, data_type
            FROM information_schema.columns
            WHERE table_name = 'bills'
            ORDER BY column_name;
        """)
        
        columns = {row[0]: row[1] for row in cursor.fetchall()}
        
        # Check required columns
        self.assertIn('bill_id', columns)
        self.assertIn('bill_number', columns)
        self.assertIn('bill_type', columns)
        self.assertIn('congress_number', columns)
        self.assertIn('title', columns)
        self.assertIn('subjects', columns)
        self.assertIn('committees', columns)
        
        # Check JSONB fields
        self.assertEqual(columns['subjects'], 'jsonb')
        self.assertEqual(columns['committees'], 'jsonb')
    
    def test_indexes_exist(self):
        """Test that important indexes exist"""
        cursor = self.conn.cursor()
        cursor.execute("""
            SELECT indexname, tablename
            FROM pg_indexes
            WHERE schemaname = 'public'
            ORDER BY tablename, indexname;
        """)
        
        indexes = [(row[0], row[1]) for row in cursor.fetchall()]
        
        # Check for important indexes
        index_names = [idx[0] for idx in indexes]
        
        # Packages table indexes
        packages_indexes = [idx for idx in indexes if idx[1] == 'packages']
        self.assertGreater(len(packages_indexes), 0, "No indexes found for packages table")
        
        # Bills table indexes
        bills_indexes = [idx for idx in indexes if idx[1] == 'bills']
        self.assertGreater(len(bills_indexes), 0, "No indexes found for bills table")
    
    def test_collections_have_data(self):
        """Test that collections table has data"""
        cursor = self.conn.cursor()
        cursor.execute("SELECT COUNT(*) FROM collections;")
        count = cursor.fetchone()[0]
        
        self.assertGreater(count, 0, "Collections table should have data")
        self.assertGreaterEqual(count, 40, "Should have at least 40 collections")
    
    def test_foreign_key_constraints(self):
        """Test that foreign key constraints exist"""
        cursor = self.conn.cursor()
        cursor.execute("""
            SELECT 
                tc.table_name, 
                kcu.column_name, 
                ccu.table_name AS foreign_table_name
            FROM information_schema.table_constraints tc 
            JOIN information_schema.key_column_usage kcu
                ON tc.constraint_name = kcu.constraint_name
            JOIN information_schema.constraint_column_usage ccu
                ON ccu.constraint_name = tc.constraint_name
            WHERE tc.constraint_type = 'FOREIGN KEY' 
                AND tc.table_schema = 'public';
        """)
        
        foreign_keys = cursor.fetchall()
        
        # Check for packages -> collections foreign key
        packages_fk = [fk for fk in foreign_keys if fk[0] == 'packages' and fk[1] == 'collection_code']
        self.assertGreater(len(packages_fk), 0, "Missing foreign key from packages to collections")
    
    def test_triggers_exist(self):
        """Test that update triggers exist"""
        cursor = self.conn.cursor()
        cursor.execute("""
            SELECT trigger_name, event_object_table
            FROM information_schema.triggers
            WHERE trigger_schema = 'public';
        """)
        
        triggers = cursor.fetchall()
        
        # Check for update triggers
        update_triggers = [t for t in triggers if 'update' in t[0].lower()]
        self.assertGreater(len(update_triggers), 0, "No update triggers found")
    
    def test_database_size(self):
        """Test that database has been created and has some size"""
        cursor = self.conn.cursor()
        cursor.execute(f"SELECT pg_database_size('{self.db_config[\"database\"]}');")
        size = cursor.fetchone()[0]
        
        self.assertGreater(size, 0, "Database should have some size")
    
    def test_ingestion_log_functionality(self):
        """Test that ingestion log can be written to"""
        cursor = self.conn.cursor()
        
        # Try to insert a test record
        cursor.execute("""
            INSERT INTO ingestion_log 
            (collection_code, operation_type, status, records_processed)
            VALUES (%s, %s, %s, %s)
            RETURNING id;
        """, ('TEST', 'test', 'success', 1))
        
        record_id = cursor.fetchone()[0]
        self.assertIsNotNone(record_id, "Should be able to insert into ingestion_log")
        
        # Clean up
        cursor.execute("DELETE FROM ingestion_log WHERE id = %s;", (record_id,))

class DataIntegrityTest(unittest.TestCase):
    """Test data integrity and validation"""
    
    @classmethod
    def setUpClass(cls):
        """Set up database connection"""
        try:
            with open('../config/config.json', 'r') as f:
                config = json.load(f)
            
            cls.db_config = config['database']
            cls.conn = psycopg2.connect(
                host=cls.db_config['host'],
                port=cls.db_config['port'],
                database=cls.db_config['database'],
                user=cls.db_config['user'],
                password=cls.db_config['password']
            )
            cls.conn.autocommit = True
            
        except Exception as e:
            cls.conn = None
            print(f"Warning: Could not connect to database: {e}")
    
    def setUp(self):
        """Skip tests if database not available"""
        if not self.conn:
            self.skipTest("Database connection not available")
    
    def test_no_duplicate_collections(self):
        """Test that collection codes are unique"""
        cursor = self.conn.cursor()
        cursor.execute("""
            SELECT collection_code, COUNT(*)
            FROM collections
            GROUP BY collection_code
            HAVING COUNT(*) > 1;
        """)
        
        duplicates = cursor.fetchall()
        self.assertEqual(len(duplicates), 0, f"Found duplicate collections: {duplicates}")
    
    def test_no_duplicate_packages(self):
        """Test that package IDs are unique"""
        cursor = self.conn.cursor()
        cursor.execute("""
            SELECT package_id, COUNT(*)
            FROM packages
            GROUP BY package_id
            HAVING COUNT(*) > 1;
        """)
        
        duplicates = cursor.fetchall()
        self.assertEqual(len(duplicates), 0, f"Found duplicate packages: {duplicates}")
    
    def test_collection_codes_not_null(self):
        """Test that collection codes are not null"""
        cursor = self.conn.cursor()
        cursor.execute("""
            SELECT COUNT(*)
            FROM collections
            WHERE collection_code IS NULL;
        """)
        
        null_count = cursor.fetchone()[0]
        self.assertEqual(null_count, 0, "Found null collection codes")
    
    def test_package_ids_not_null(self):
        """Test that package IDs are not null"""
        cursor = self.conn.cursor()
        cursor.execute("""
            SELECT COUNT(*)
            FROM packages
            WHERE package_id IS NULL;
        """)
        
        null_count = cursor.fetchone()[0]
        self.assertEqual(null_count, 0, "Found null package IDs")

if __name__ == '__main__':
    unittest.main()
