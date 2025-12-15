"""Main ingestion engine for GovInfo API data."""

import json
import time
from typing import Dict, List, Optional, Any
from datetime import datetime

from database.db_manager import DatabaseManager
from ingestion.api_client import GovInfoAPIClient


class IngestionEngine:
    """Orchestrates data ingestion from GovInfo API to database."""
    
    def __init__(self, config_path: str = '/root/congress_api_project/config/config.json'):
        """Initialize ingestion engine.
        
        Args:
            config_path: Path to configuration file
        """
        self.config_path = config_path
        with open(config_path, 'r') as f:
            self.config = json.load(f)
        
        # Initialize components
        self.db = DatabaseManager(config_path)
        self.api_client = GovInfoAPIClient(
            self.config['govinfo_api']['api_key'],
            self.config['govinfo_api']['base_url']
        )
        
        self.db.connect()
    
    def ingest_collections(self) -> Dict[str, Any]:
        """Ingest all collections from API.
        
        Returns:
            Dictionary with ingestion results
        """
        print('\nIngesting collections...')
        print('=' * 60)
        
        result = {
            'total_collections': 0,
            'inserted': 0,
            'updated': 0,
            'errors': []
        }
        
        # Get collections from API
        api_result = self.api_client.get_collections()
        
        if 'error' in api_result:
            result['errors'].append(api_result['error'])
            return result
        
        collections = api_result.get('collections', [])
        result['total_collections'] = len(collections)
        
        for collection in collections:
            try:
                collection_data = {
                    'collection_code': collection.get('collectionCode'),
                    'collection_name': collection.get('collectionName'),
                    'description': collection.get('description'),
                    'last_modified': collection.get('lastModified')
                }
                
                # Check if collection exists
                exists = self._collection_exists(collection_data['collection_code'])
                
                self.db.insert_collection(collection_data)
                
                if exists:
                    result['updated'] += 1
                else:
                    result['inserted'] += 1
                
                print(f"  ✓ {collection_data['collection_code']}: {collection_data['collection_name']}")
                
            except Exception as e:
                result['errors'].append(f"Collection {collection.get('collectionCode', 'UNKNOWN')}: {str(e)}")
        
        print(f"\nCollections ingested: {result['inserted']} inserted, {result['updated']} updated")
        return result
    
    def _collection_exists(self, collection_code: str) -> bool:
        """Check if collection exists in database."""
        query = "SELECT 1 FROM collections WHERE collection_code = %s LIMIT 1"
        result = self.db.execute(query, (collection_code,))
        return len(result) > 0
    
    def ingest_collection_packages(
        self,
        collection_code: str,
        batch_size: int = 100,
        max_packages: Optional[int] = None,
        start_date: Optional[str] = None,
        end_date: Optional[str] = None
    ) -> Dict[str, Any]:
        """Ingest packages from a collection with pagination.
        
        Args:
            collection_code: Collection code to ingest
            batch_size: Number of packages per API call (max 1000)
            max_packages: Maximum packages to ingest (None for all)
            start_date: Start date filter (YYYY-MM-DD)
            end_date: End date filter (YYYY-MM-DD)
            
        Returns:
            Dictionary with ingestion results
        """
        print(f'\nIngesting packages for collection: {collection_code}')
        print('=' * 60)
        
        result = {
            'collection_code': collection_code,
            'total_ingested': 0,
            'inserted': 0,
            'updated': 0,
            'duplicates_skipped': 0,
            'errors': [],
            'batches_completed': 0,
            'last_offset': 0
        }
        
        # Get last successful offset
        last_offset = self.db.get_last_offset(collection_code)
        current_offset = last_offset
        
        print(f"Starting from offset: {current_offset}")
        
        batch_size = min(batch_size, 1000)  # API max
        
        while True:
            # Check max packages limit
            if max_packages and result['total_ingested'] >= max_packages:
                print(f"\nReached maximum packages limit: {max_packages}")
                break
            
            print(f"\nFetching batch at offset {current_offset}, limit {batch_size}...")
            
            # Log ingestion start
            log_id = self._log_ingestion_start(collection_code, current_offset, batch_size)
            
            # Get packages from API
            api_result = self.api_client.get_collection_packages(
                collection_code,
                offset=current_offset,
                limit=batch_size,
                start_date=start_date,
                end_date=end_date
            )
            
            if 'error' in api_result:
                error_msg = f"Offset {current_offset}: {api_result['error']} - {api_result.get('message', '')}"
                result['errors'].append(error_msg)
                print(f"  ✗ {error_msg}")
                
                # Log error
                self._log_ingestion_complete(log_id, 'error', 0, error_msg)
                break
            
            packages = api_result.get('packages', [])
            
            if not packages:
                print(f"  No more packages found at offset {current_offset}")
                self._log_ingestion_complete(log_id, 'success', 0)
                break
            
            # Process packages
            batch_inserted = 0
            batch_updated = 0
            batch_duplicates = 0
            
            for package in packages:
                try:
                    package_data = self._transform_package(package, collection_code)
                    
                    # Check for duplicates
                    if self.db.package_exists(package_data['package_id']):
                        batch_duplicates += 1
                        result['duplicates_skipped'] += 1
                        continue
                    
                    # Insert package
                    self.db.insert_package(package_data)
                    
                    if package.get('lastModified'):
                        batch_updated += 1
                        result['updated'] += 1
                    else:
                        batch_inserted += 1
                        result['inserted'] += 1
                    
                    result['total_ingested'] += 1
                    
                except Exception as e:
                    error_msg = f"Package {package.get('packageId', 'UNKNOWN')}: {str(e)}"
                    result['errors'].append(error_msg)
                    print(f"    ✗ {error_msg}")
            
            print(f"  ✓ Batch processed: {len(packages)} packages ({batch_inserted} new, {batch_updated} updated, {batch_duplicates} duplicates)")
            
            # Log success
            self._log_ingestion_complete(
                log_id,
                'success',
                len(packages)
            )
            
            result['batches_completed'] += 1
            result['last_offset'] = current_offset
            
            # Move to next batch
            current_offset += len(packages)
            
            # Check if we've reached the end
            if len(packages) < batch_size:
                print(f"\nReached end of collection at offset {current_offset}")
                break
            
            # Small delay between batches
            time.sleep(0.5)
        
        print(f"\nIngestion complete for {collection_code}")
        print(f"  Total packages: {result['total_ingested']}")
        print(f"  Inserted: {result['inserted']}")
        print(f"  Updated: {result['updated']}")
        print(f"  Duplicates skipped: {result['duplicates_skipped']}")
        print(f"  Errors: {len(result['errors'])}")
        print(f"  Batches: {result['batches_completed']}")
        
        return result
    
    def _transform_package(self, package: Dict[str, Any], collection_code: str) -> Dict[str, Any]:
        """Transform API package data to database format."""
        return {
            'package_id': package.get('packageId', ''),
            'collection_code': collection_code,
            'title': package.get('title'),
            'summary': package.get('summary'),
            'download_url': package.get('downloadUrl'),
            'details_url': package.get('detailsUrl'),
            'publish_date': package.get('publishDate'),
            'last_modified': package.get('lastModified')
        }
    
    def _log_ingestion_start(self, collection_code: str, offset: int, limit: int) -> int:
        """Log the start of an ingestion batch."""
        log_data = {
            'collection_code': collection_code,
            'offset_value': offset,
            'limit_value': limit,
            'records_ingested': 0,
            'status': 'started',
            'error_message': None,
            'completed_at': None
        }
        return self.db.log_ingestion(log_data)
    
    def _log_ingestion_complete(self, log_id: int, status: str, records: int = 0, error_msg: str = None):
        """Update ingestion log with completion status."""
        # Note: Since we can't easily update by ID in this simple implementation,
        # we'll just log new entries. In production, implement update functionality.
        pass
    
    def get_ingestion_stats(self) -> Dict[str, Any]:
        """Get overall ingestion statistics."""
        stats = {
            'database_type': self.db.db_type,
            'total_collections': 0,
            'total_packages': 0,
            'api_stats': self.api_client.get_stats()
        }
        
        # Get collection count
        result = self.db.execute('SELECT COUNT(*) as count FROM collections')
        if result:
            stats['total_collections'] = result[0]['count']
        
        # Get package count
        result = self.db.execute('SELECT COUNT(*) as count FROM packages')
        if result:
            stats['total_packages'] = result[0]['count']
        
        return stats
    
    def close(self):
        """Close database connection."""
        if self.db:
            self.db.disconnect()


if __name__ == '__main__':
    # Test ingestion engine
    print('Testing Ingestion Engine')
    print('=' * 60)
    
    engine = IngestionEngine()
    
    # Test collections ingestion
    print('\n1. Testing collections ingestion...')
    collections_result = engine.ingest_collections()
    
    if not collections_result['errors']:
        print('\n2. Testing package ingestion for BILLS collection...')
        packages_result = engine.ingest_collection_packages(
            'BILLS',
            batch_size=10,
            max_packages=20
        )
    
    # Get stats
    print('\n3. Getting ingestion statistics...')
    stats = engine.get_ingestion_stats()
    print(json.dumps(stats, indent=2))
    
    engine.close()
    print('\n' + '=' * 60)
