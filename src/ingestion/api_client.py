"""GovInfo API client with rate limiting and pagination support."""

import time
import requests
import json
from typing import Dict, List, Optional, Any
from datetime import datetime


class GovInfoAPIClient:
    """Client for interacting with the GovInfo API."""
    
    def __init__(self, api_key: str, base_url: str = 'https://api.govinfo.gov'):
        """Initialize API client.
        
        Args:
            api_key: GovInfo API key
            base_url: Base URL for API
        """
        self.api_key = api_key
        self.base_url = base_url
        self.session = requests.Session()
        self.session.headers.update({
            'X-Api-Key': api_key,
            'User-Agent': 'CongressAPI-Project/1.0'
        })
        
        # Rate limiting
        self.last_request_time = 0
        self.min_interval = 0.1  # 100ms between requests (10 req/sec)
        self.max_requests_per_hour = 1000
        self.request_count = 0
        self.hour_start = time.time()
    
    def _check_rate_limit(self):
        """Check and enforce rate limits."""
        now = time.time()
        
        # Check hourly limit
        if now - self.hour_start > 3600:
            self.request_count = 0
            self.hour_start = now
        
        if self.request_count >= self.max_requests_per_hour:
            sleep_time = 3600 - (now - self.hour_start)
            if sleep_time > 0:
                print(f"Rate limit reached, sleeping for {sleep_time:.1f} seconds...")
                time.sleep(sleep_time)
                self.request_count = 0
                self.hour_start = time.time()
        
        # Check minimum interval
        elapsed = now - self.last_request_time
        if elapsed < self.min_interval:
            time.sleep(self.min_interval - elapsed)
        
        self.last_request_time = time.time()
        self.request_count += 1
    
    def get_collections(self) -> Dict[str, Any]:
        """Get all available collections.
        
        Returns:
            Dictionary with collections data
        """
        self._check_rate_limit()
        
        try:
            response = self.session.get(
                f'{self.base_url}/collections',
                timeout=30
            )
            
            if response.status_code == 200:
                return response.json()
            else:
                return {
                    'error': f'HTTP {response.status_code}',
                    'message': response.text[:500]
                }
                
        except Exception as e:
            return {
                'error': str(e),
                'message': 'Exception occurred'
            }
    
    def get_collection_packages(
        self,
        collection_code: str,
        offset: int = 0,
        limit: int = 100,
        start_date: Optional[str] = None,
        end_date: Optional[str] = None
    ) -> Dict[str, Any]:
        """Get packages from a specific collection with pagination.
        
        Args:
            collection_code: Collection code (e.g., 'BILLS', 'CREC')
            offset: Starting offset for pagination
            limit: Number of records to retrieve (max 1000)
            start_date: Start date in ISO format (YYYY-MM-DD)
            end_date: End date in ISO format (YYYY-MM-DD)
            
        Returns:
            Dictionary with packages data
        """
        self._check_rate_limit()
        
        # Build URL with parameters
        url = f'{self.base_url}/collections/{collection_code}'
        params = {
            'offset': offset,
            'pageSize': min(limit, 1000)  # API max is 1000
        }
        
        if start_date:
            params['startDate'] = start_date
        if end_date:
            params['endDate'] = end_date
        
        try:
            response = self.session.get(url, params=params, timeout=30)
            
            if response.status_code == 200:
                data = response.json()
                
                # Add pagination info if not present
                if 'offset' not in data:
                    data['offset'] = offset
                if 'limit' not in data:
                    data['limit'] = limit
                
                return data
                
            else:
                return {
                    'error': f'HTTP {response.status_code}',
                    'message': response.text[:500],
                    'offset': offset,
                    'limit': limit
                }
                
        except Exception as e:
            return {
                'error': str(e),
                'message': 'Exception occurred',
                'offset': offset,
                'limit': limit
            }
    
    def get_package_details(self, package_id: str) -> Dict[str, Any]:
        """Get detailed information about a specific package.
        
        Args:
            package_id: Package identifier
            
        Returns:
            Dictionary with package details
        """
        self._check_rate_limit()
        
        try:
            response = self.session.get(
                f'{self.base_url}/packages/{package_id}',
                timeout=30
            )
            
            if response.status_code == 200:
                return response.json()
            else:
                return {
                    'error': f'HTTP {response.status_code}',
                    'message': response.text[:500]
                }
                
        except Exception as e:
            return {
                'error': str(e),
                'message': 'Exception occurred'
            }
    
    def get_stats(self) -> Dict[str, Any]:
        """Get API usage statistics.
        
        Returns:
            Dictionary with stats
        """
        return {
            'request_count': self.request_count,
            'max_requests_per_hour': self.max_requests_per_hour,
            'elapsed_time': time.time() - self.hour_start
        }


if __name__ == '__main__':
    # Test API client
    import sys
    sys.path.append('/root/congress_api_project/src')
    
    from database.db_manager import DatabaseManager
    
    # Load config
    with open('/root/congress_api_project/config/config.json', 'r') as f:
        config = json.load(f)
    
    # Test collections endpoint
    client = GovInfoAPIClient(config['govinfo_api']['api_key'])
    
    print('Testing GovInfo API client...')
    print('=' * 60)
    
    collections = client.get_collections()
    if 'error' not in collections:
        print(f"✓ Collections retrieved: {len(collections.get('collections', []))} collections")
        
        # Test package retrieval for first collection
        if collections.get('collections'):
            first_collection = collections['collections'][0]
            collection_code = first_collection.get('collectionCode')
            
            print(f"\nTesting packages for collection: {collection_code}")
            packages = client.get_collection_packages(collection_code, offset=0, limit=10)
            
            if 'error' not in packages:
                print(f"✓ Packages retrieved: {len(packages.get('packages', []))} packages")
                if packages.get('packages'):
                    print(f"First package: {packages['packages'][0].get('packageId', 'N/A')}")
            else:
                print(f"✗ Error: {packages['error']}")
    else:
        print(f"✗ Error: {collections['error']}")
    
    print('\n' + '=' * 60)
