#!/usr/bin/env python3
"""
Congress API Data Ingestion System

Main entry point for ingesting data from GovInfo API into PostgreSQL/SQLite database.
"""

import argparse
import json
import sys
import time
from datetime import datetime

# Add src to path
sys.path.insert(0, '/root/congress_api_project/src')

from database.db_manager import DatabaseManager
from ingestion.api_client import GovInfoAPIClient
from ingestion.ingestion_engine import IngestionEngine


def main():
    """Main entry point."""
    parser = argparse.ArgumentParser(
        description='Congress API Data Ingestion System',
        formatter_class=argparse.RawDescriptionHelpFormatter,
        epilog="""
Examples:
  # Ingest all collections
  python main.py --ingest-collections
  
  # Ingest packages from BILLS collection (first 100)
  python main.py --ingest-packages BILLS --max-packages 100
  
  # Ingest packages from CREC collection with date range
  python main.py --ingest-packages CREC --start-date 2024-01-01 --end-date 2024-12-31
  
  # Show statistics
  python main.py --stats
  
  # Test API connection
  python main.py --test-api
        """
    )
    
    parser.add_argument(
        '--ingest-collections',
        action='store_true',
        help='Ingest all collections from API'
    )
    
    parser.add_argument(
        '--ingest-packages',
        metavar='COLLECTION_CODE',
        help='Ingest packages from specified collection'
    )
    
    parser.add_argument(
        '--max-packages',
        type=int,
        default=None,
        help='Maximum number of packages to ingest (default: all)'
    )
    
    parser.add_argument(
        '--batch-size',
        type=int,
        default=100,
        help='Number of packages per API call (default: 100, max: 1000)'
    )
    
    parser.add_argument(
        '--start-date',
        help='Start date for package filtering (YYYY-MM-DD)'
    )
    
    parser.add_argument(
        '--end-date',
        help='End date for package filtering (YYYY-MM-DD)'
    )
    
    parser.add_argument(
        '--stats',
        action='store_true',
        help='Show ingestion statistics'
    )
    
    parser.add_argument(
        '--test-api',
        action='store_true',
        help='Test API connection and list available collections'
    )
    
    parser.add_argument(
        '--config',
        default='/root/congress_api_project/config/config.json',
        help='Path to configuration file'
    )
    
    args = parser.parse_args()
    
    # Validate arguments
    if not any(vars(args).values()):
        parser.print_help()
        return 0
    
    try:
        # Initialize engine
        engine = IngestionEngine(args.config)
        
        if args.test_api:
            test_api_connection(engine)
        
        elif args.ingest_collections:
            result = engine.ingest_collections()
            if result['errors']:
                print(f"\nErrors encountered: {len(result['errors'])}")
                for error in result['errors'][:5]:  # Show first 5 errors
                    print(f"  - {error}")
        
        elif args.ingest_packages:
            result = engine.ingest_collection_packages(
                collection_code=args.ingest_packages,
                batch_size=args.batch_size,
                max_packages=args.max_packages,
                start_date=args.start_date,
                end_date=args.end_date
            )
            
            if result['errors']:
                print(f"\nErrors encountered: {len(result['errors'])}")
                for error in result['errors'][:5]:
                    print(f"  - {error}")
        
        elif args.stats:
            show_statistics(engine)
        
        engine.close()
        return 0
        
    except Exception as e:
        print(f"\nError: {e}")
        import traceback
        traceback.print_exc()
        return 1


def test_api_connection(engine):
    """Test API connection and list available collections."""
    print('Testing GovInfo API Connection')
    print('=' * 60)
    
    # Test collections endpoint
    print('\nFetching collections...')
    collections = engine.api_client.get_collections()
    
    if 'error' in collections:
        print(f"✗ API Error: {collections['error']}")
        print(f"  {collections.get('message', '')}")
        return
    
    collections_list = collections.get('collections', [])
    print(f"✓ Connected successfully!")
    print(f"\nAvailable collections: {len(collections_list)}")
    print('-' * 60)
    
    # Show first 10 collections
    for i, collection in enumerate(collections_list[:10], 1):
        print(f"{i}. {collection.get('collectionCode', 'N/A')}: {collection.get('collectionName', 'N/A')}")
    
    if len(collections_list) > 10:
        print(f"... and {len(collections_list) - 10} more")
    
    # Show API stats
    stats = engine.api_client.get_stats()
    print(f"\nAPI Usage:")
    print(f"  Requests this hour: {stats['request_count']}/{stats['max_requests_per_hour']}")
    print(f"  Elapsed time: {stats['elapsed_time']:.1f} seconds")
    
    print('\n' + '=' * 60)


def show_statistics(engine):
    """Show ingestion statistics."""
    print('Ingestion Statistics')
    print('=' * 60)
    
    stats = engine.get_ingestion_stats()
    
    print(f"\nDatabase:")
    print(f"  Type: {stats['database_type']}")
    print(f"  Collections: {stats['total_collections']}")
    print(f"  Packages: {stats['total_packages']}")
    
    print(f"\nAPI Usage:")
    api_stats = stats['api_stats']
    print(f"  Requests this hour: {api_stats['request_count']}/{api_stats['max_requests_per_hour']}")
    print(f"  Elapsed time: {api_stats['elapsed_time']:.1f} seconds")
    
    # Get recent ingestion logs
    print(f"\nRecent Ingestion Activity:")
    logs = engine.db.execute(
        "SELECT * FROM ingestion_log ORDER BY id DESC LIMIT 5"
    )
    
    if logs:
        for log in logs:
            print(f"  {log['collection_code']}: offset {log['offset_value']}, "
                  f"{log['records_ingested']} records, {log['status']}")
    else:
        print("  No recent activity")
    
    print('\n' + '=' * 60)


if __name__ == '__main__':
    sys.exit(main())
