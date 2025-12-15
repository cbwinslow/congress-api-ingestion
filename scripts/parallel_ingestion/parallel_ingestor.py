#!/usr/bin/env python3
"""
Parallel Congress Data Ingestion System
Uses multiprocessing and threading for high-performance data ingestion
"""

import os
import sys
import json
import time
import requests
import psycopg2
import multiprocessing
import threading
import queue
from concurrent.futures import ThreadPoolExecutor, ProcessPoolExecutor
from datetime import datetime
from typing import List, Dict, Any, Optional

# Add project root to path
sys.path.append(os.path.dirname(os.path.dirname(os.path.abspath(__file__))))

class CongressAPIClient:
    """API client for Congress.gov with rate limiting"""
    
    def __init__(self, api_key: str, base_url: str = "https://api.congress.gov/v3", rate_limit: int = 1000):
        self.api_key = api_key
        self.base_url = base_url
        self.rate_limit = rate_limit
        self.last_request_time = 0
        self.request_count = 0
        self.session = requests.Session()
        self.session.headers.update({
            'X-API-KEY': self.api_key,
            'Accept': 'application/json'
        })
    
    def _rate_limit_wait(self):
        """Enforce rate limiting"""
        current_time = time.time()
        if current_time - self.last_request_time < 3600:
            if self.request_count >= self.rate_limit:
                wait_time = 3600 - (current_time - self.last_request_time)
                time.sleep(wait_time)
                self.request_count = 0
                self.last_request_time = time.time()
        else:
            self.request_count = 0
            self.last_request_time = current_time
        
        self.request_count += 1
    
    def get(self, endpoint: str, params: Optional[Dict] = None, max_retries: int = 3) -> Optional[Dict]:
        """Make API request with rate limiting and retries"""
        url = f"{self.base_url}/{endpoint}"
        
        for attempt in range(max_retries):
            try:
                self._rate_limit_wait()
                response = self.session.get(url, params=params, timeout=30)
                response.raise_for_status()
                return response.json()
            except requests.exceptions.RequestException as e:
                if attempt == max_retries - 1:
                    print(f"Failed to fetch {url}: {str(e)}")
                    return None
                time.sleep(2 ** attempt)
        
        return None

class DatabaseManager:
    """Database manager for PostgreSQL"""
    
    def __init__(self, db_config: Dict):
        self.db_config = db_config
        self.connection = None
        self.lock = threading.Lock()
    
    def connect(self):
        """Establish database connection"""
        try:
            self.connection = psycopg2.connect(**self.db_config)
            return True
        except Exception as e:
            print(f"Database connection failed: {str(e)}")
            return False
    
    def execute(self, query: str, params: Optional[tuple] = None, fetch: bool = False):
        """Execute SQL query with thread-safe connection handling"""
        with self.lock:
            if not self.connection or self.connection.closed:
                if not self.connect():
                    return None
            
            try:
                with self.connection.cursor() as cursor:
                    cursor.execute(query, params)
                    if fetch:
                        return cursor.fetchall()
                    self.connection.commit()
                    return True
            except Exception as e:
                self.connection.rollback()
                print(f"Query failed: {str(e)}")
                return None
    
    def close(self):
        """Close database connection"""
        if self.connection and not self.connection.closed:
            self.connection.close()

class DataProcessor:
    """Data processing and transformation"""
    
    @staticmethod
    def process_bill_data(bill_data: Dict) -> Dict:
        """Process bill data for database insertion"""
        processed = {
            'bill_id': bill_data.get('billId', ''),
            'congress': bill_data.get('congress', 0),
            'bill_type': bill_data.get('type', ''),
            'bill_number': bill_data.get('number', ''),
            'title': bill_data.get('title', '')[:500],
            'official_title': bill_data.get('officialTitle', '')[:1000] if bill_data.get('officialTitle') else None,
            'summary': bill_data.get('summary', '')[:2000] if bill_data.get('summary') else None,
            'sponsor_id': bill_data.get('sponsor', {}).get('bioguideId', '') if bill_data.get('sponsor') else None,
            'sponsor_name': bill_data.get('sponsor', {}).get('name', '') if bill_data.get('sponsor') else None,
            'sponsor_state': bill_data.get('sponsor', {}).get('state', '') if bill_data.get('sponsor') else None,
            'sponsor_party': bill_data.get('sponsor', {}).get('party', '') if bill_data.get('sponsor') else None,
            'introduced_date': bill_data.get('introducedDate', ''),
            'last_action_date': bill_data.get('lastAction', {}).get('actionDate', '') if bill_data.get('lastAction') else None,
            'last_action': bill_data.get('lastAction', {}).get('text', '')[:1000] if bill_data.get('lastAction') else None,
            'status': bill_data.get('latestAction', {}).get('text', '')[:100] if bill_data.get('latestAction') else None,
            'url': bill_data.get('url', '')[:255] if bill_data.get('url') else None,
            'pdf_url': bill_data.get('pdf', '')[:255] if bill_data.get('pdf') else None,
            'text_content': bill_data.get('text', '')[:5000] if bill_data.get('text') else None,
            'metadata': json.dumps(bill_data)
        }
        return processed
    
    @staticmethod
    def process_legislator_data(legislator_data: Dict) -> Dict:
        """Process legislator data for database insertion"""
        processed = {
            'legislator_id': legislator_data.get('id', {}).get('bioguide', '') or legislator_data.get('bioguideId', ''),
            'bioguide_id': legislator_data.get('id', {}).get('bioguide', '') or legislator_data.get('bioguideId', ''),
            'name': legislator_data.get('name', {}).get('officialFull', '')[:100] if legislator_data.get('name') else '',
            'first_name': legislator_data.get('name', {}).get('first', '')[:50] if legislator_data.get('name') else None,
            'last_name': legislator_data.get('name', {}).get('last', '')[:50] if legislator_data.get('name') else None,
            'middle_name': legislator_data.get('name', {}).get('middle', '')[:50] if legislator_data.get('name') else None,
            'suffix': legislator_data.get('name', {}).get('suffix', '')[:10] if legislator_data.get('name') else None,
            'gender': legislator_data.get('gender', '')[:20] if legislator_data.get('gender') else None,
            'birth_date': legislator_data.get('dateOfBirth', '') if legislator_data.get('dateOfBirth') else None,
            'party': legislator_data.get('party', '')[:10] if legislator_data.get('party') else None,
            'state': legislator_data.get('state', '')[:2] if legislator_data.get('state') else None,
            'district': legislator_data.get('district', '')[:10] if legislator_data.get('district') else None,
            'chamber': legislator_data.get('chamber', '')[:10] if legislator_data.get('chamber') else None,
            'title': legislator_data.get('title', '')[:20] if legislator_data.get('title') else None,
            'phone': legislator_data.get('phone', '')[:20] if legislator_data.get('phone') else None,
            'office': legislator_data.get('office', '')[:50] if legislator_data.get('office') else None,
            'website': legislator_data.get('url', '')[:255] if legislator_data.get('url') else None,
            'twitter': legislator_data.get('twitter', '')[:50] if legislator_data.get('twitter') else None,
            'facebook': legislator_data.get('facebook', '')[:100] if legislator_data.get('facebook') else None,
            'youtube': legislator_data.get('youtube', '')[:100] if legislator_data.get('youtube') else None,
            'instagram': legislator_data.get('instagram', '')[:100] if legislator_data.get('instagram') else None,
            'term_start': legislator_data.get('termStart', '') if legislator_data.get('termStart') else None,
            'term_end': legislator_data.get('termEnd', '') if legislator_data.get('termEnd') else None,
            'in_office': legislator_data.get('inOffice', True),
            'metadata': json.dumps(legislator_data)
        }
        return processed

class ParallelIngestor:
    """Parallel data ingestion system"""
    
    def __init__(self, api_client: CongressAPIClient, db_manager: DatabaseManager, workers: int = 4):
        self.api_client = api_client
        self.db_manager = db_manager
        self.workers = workers
        self.task_queue = queue.Queue()
        self.result_queue = queue.Queue()
        self.stop_event = threading.Event()
    
    def _worker_thread(self):
        """Worker thread for processing tasks"""
        while not self.stop_event.is_set():
            try:
                task = self.task_queue.get(timeout=1)
                if task is None:
                    break
                
                data_type, data_id = task
                result = self._process_task(data_type, data_id)
                self.result_queue.put(result)
                
            except queue.Empty:
                continue
            except Exception as e:
                print(f"Worker error: {str(e)}")
    
    def _process_task(self, data_type: str, data_id: str) -> Dict:
        """Process individual task"""
        result = {
            'data_type': data_type,
            'data_id': data_id,
            'status': 'error',
            'records': 0,
            'error': None
        }
        
        try:
            if data_type == 'bill':
                records = self._ingest_bill(data_id)
            elif data_type == 'legislator':
                records = self._ingest_legislator(data_id)
            elif data_type == 'vote':
                records = self._ingest_vote(data_id)
            else:
                result['error'] = f"Unknown data type: {data_type}"
                return result
            
            result['status'] = 'success'
            result['records'] = records
            
        except Exception as e:
            result['error'] = str(e)
        
        return result
    
    def _ingest_bill(self, bill_id: str) -> int:
        """Ingest single bill"""
        data = self.api_client.get(f"bill/{bill_id}")
        if not data or 'bill' not in data:
            return 0
        
        bill_data = data['bill']
        processed = DataProcessor.process_bill_data(bill_data)
        
        # Insert into database
        query = '''
        INSERT INTO congress.bills 
        (bill_id, congress, bill_type, bill_number, title, official_title, summary, 
         sponsor_id, sponsor_name, sponsor_state, sponsor_party, introduced_date, 
         last_action_date, last_action, status, url, pdf_url, text_content, metadata)
        VALUES (%s, %s, %s, %s, %s, %s, %s, %s, %s, %s, %s, %s, %s, %s, %s, %s, %s, %s, %s)
        ON CONFLICT (bill_id) DO NOTHING
        '''
        
        params = (
            processed['bill_id'], processed['congress'], processed['bill_type'], 
            processed['bill_number'], processed['title'], processed['official_title'], 
            processed['summary'], processed['sponsor_id'], processed['sponsor_name'], 
            processed['sponsor_state'], processed['sponsor_party'], processed['introduced_date'],
            processed['last_action_date'], processed['last_action'], processed['status'],
            processed['url'], processed['pdf_url'], processed['text_content'], 
            processed['metadata']
        )
        
        if self.db_manager.execute(query, params):
            return 1
        
        return 0
    
    def _ingest_legislator(self, legislator_id: str) -> int:
        """Ingest single legislator"""
        data = self.api_client.get(f"member/{legislator_id}")
        if not data or 'member' not in data:
            return 0
        
        legislator_data = data['member']
        processed = DataProcessor.process_legislator_data(legislator_data)
        
        # Insert into database
        query = '''
        INSERT INTO congress.legislators 
        (legislator_id, bioguide_id, name, first_name, last_name, middle_name, suffix, 
         gender, birth_date, party, state, district, chamber, title, phone, office, 
         website, twitter, facebook, youtube, instagram, term_start, term_end, 
         in_office, metadata)
        VALUES (%s, %s, %s, %s, %s, %s, %s, %s, %s, %s, %s, %s, %s, %s, %s, %s, %s, %s, %s, %s, %s, %s, %s, %s, %s)
        ON CONFLICT (legislator_id) DO NOTHING
        '''
        
        params = (
            processed['legislator_id'], processed['bioguide_id'], processed['name'], 
            processed['first_name'], processed['last_name'], processed['middle_name'], 
            processed['suffix'], processed['gender'], processed['birth_date'], 
            processed['party'], processed['state'], processed['district'], 
            processed['chamber'], processed['title'], processed['phone'], 
            processed['office'], processed['website'], processed['twitter'], 
            processed['facebook'], processed['youtube'], processed['instagram'], 
            processed['term_start'], processed['term_end'], processed['in_office'], 
            processed['metadata']
        )
        
        if self.db_manager.execute(query, params):
            return 1
        
        return 0
    
    def start_workers(self):
        """Start worker threads"""
        self.workers = []
        for i in range(self.workers):
            worker = threading.Thread(target=self._worker_thread, daemon=True)
            worker.start()
            self.workers.append(worker)
    
    def stop_workers(self):
        """Stop worker threads"""
        self.stop_event.set()
        for _ in range(len(self.workers)):
            self.task_queue.put(None)
        
        for worker in self.workers:
            worker.join()
    
    def ingest_data_parallel(self, data_type: str, data_ids: List[str]) -> Dict:
        """Ingest data in parallel"""
        results = {
            'total': len(data_ids),
            'success': 0,
            'failed': 0,
            'errors': []
        }
        
        # Add tasks to queue
        for data_id in data_ids:
            self.task_queue.put((data_type, data_id))
        
        # Process results
        processed = 0
        while processed < len(data_ids):
            try:
                result = self.result_queue.get(timeout=5)
                if result['status'] == 'success':
                    results['success'] += 1
                else:
                    results['failed'] += 1
                    if result['error']:
                        results['errors'].append(f"{result['data_type']} {result['data_id']}: {result['error']}")
                processed += 1
            except queue.Empty:
                continue
        
        return results

class BatchIngestor:
    """Batch ingestion using multiprocessing"""
    
    def __init__(self, api_client: CongressAPIClient, db_manager: DatabaseManager, workers: int = 4):
        self.api_client = api_client
        self.db_manager = db_manager
        self.workers = workers
    
    def ingest_bills_batch(self, congress: int, bill_type: str, limit: int = 100) -> Dict:
        """Ingest bills in parallel using multiprocessing"""
        # Get list of bills
        bills_data = self.api_client.get(f"bill/{congress}/{bill_type}", {'limit': limit})
        if not bills_data or 'bills' not in bills_data:
            return {'total': 0, 'success': 0, 'failed': 0, 'errors': ['No bills found']}
        
        bill_ids = [bill['billId'] for bill in bills_data['bills']]
        
        # Use multiprocessing for parallel ingestion
        with ProcessPoolExecutor(max_workers=self.workers) as executor:
            # Create a partial function with fixed parameters
            def ingest_single(bill_id):
                try:
                    ingestor = ParallelIngestor(self.api_client, self.db_manager, 1)
                    result = ingestor._ingest_bill(bill_id)
                    return {'bill_id': bill_id, 'success': result > 0}
                except Exception as e:
                    return {'bill_id': bill_id, 'success': False, 'error': str(e)}
            
            results = list(executor.map(ingest_single, bill_ids))
        
        # Process results
        final_results = {'total': len(bill_ids), 'success': 0, 'failed': 0, 'errors': []}
        for result in results:
            if result['success']:
                final_results['success'] += 1
            else:
                final_results['failed'] += 1
                if 'error' in result:
                    final_results['errors'].append(f"{result['bill_id']}: {result['error']}")
        
        return final_results

def main():
    """Main function for parallel ingestion"""
    
    # Load configuration
    config_path = os.path.join(os.path.dirname(__file__), '..', '..', 'config', 'config.json')
    with open(config_path, 'r') as f:
        config = json.load(f)
    
    # Database configuration
    db_config = {
        'dbname': config['database']['postgresql']['database'],
        'user': config['database']['postgresql']['user'],
        'password': config['database']['postgresql']['password'],
        'host': config['database']['postgresql']['host'],
        'port': config['database']['postgresql']['port']
    }
    
    # Initialize components
    api_client = CongressAPIClient(config['congress_api']['api_key'])
    db_manager = DatabaseManager(db_config)
    
    if not db_manager.connect():
        print("Failed to connect to database")
        return
    
    # Create parallel ingestor
    ingestor = ParallelIngestor(api_client, db_manager, workers=4)
    batch_ingestor = BatchIngestor(api_client, db_manager, workers=4)
    
    print("🚀 Congress Data Parallel Ingestion System")
    print("=" * 50)
    
    # Example: Ingest recent bills
    print("Ingesting recent bills...")
    result = batch_ingestor.ingest_bills_batch(118, 'hr', limit=50)
    print(f"Bills: {result['success']}/{result['total']} ingested")
    
    # Example: Ingest current legislators
    print("Ingesting current legislators...")
    # This would be implemented similarly to bills
    
    # Close connections
    db_manager.close()
    print("✅ Ingestion complete!")

if __name__ == "__main__":
    main()
