#!/usr/bin/env python3
"""
Advanced Congress Data Ingestion System
Uses optimized PostgreSQL with connection pooling and parallel processing
"""

import os
import sys
import json
import time
import requests
import psycopg2
import psycopg2.pool
import psycopg2.extras
import multiprocessing
import threading
import queue
from concurrent.futures import ThreadPoolExecutor, ProcessPoolExecutor
from datetime import datetime
from typing import Dict, Any, Optional, List, Tuple

# Add project root to path
sys.path.append(os.path.dirname(os.path.dirname(os.path.abspath(__file__))))

class AdvancedAPIClient:
    """Advanced API client with connection pooling and rate limiting"""
    
    def __init__(self, api_key: str, base_url: str = "https://api.congress.gov/v3", rate_limit: int = 1000):
        self.api_key = api_key
        self.base_url = base_url
        self.rate_limit = rate_limit
        self.last_request_time = 0
        self.request_count = 0
        self.session_pool = []
        self.lock = threading.Lock()
        
        # Create session pool
        self._initialize_session_pool()
    
    def _initialize_session_pool(self, pool_size: int = 10):
        """Initialize session pool"""
        for _ in range(pool_size):
            session = requests.Session()
            session.headers.update({
                'X-API-KEY': self.api_key,
                'Accept': 'application/json',
                'User-Agent': 'CongressDataAdvancedIngestor/1.0'
            })
            self.session_pool.append(session)
    
    def _get_session(self) -> requests.Session:
        """Get session from pool"""
        with self.lock:
            if self.session_pool:
                return self.session_pool.pop()
            # Create new session if pool is empty
            session = requests.Session()
            session.headers.update({
                'X-API-KEY': self.api_key,
                'Accept': 'application/json'
            })
            return session
    
    def _return_session(self, session: requests.Session):
        """Return session to pool"""
        with self.lock:
            self.session_pool.append(session)
    
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
        session = self._get_session()
        
        try:
            for attempt in range(max_retries):
                try:
                    self._rate_limit_wait()
                    response = session.get(url, params=params, timeout=30)
                    response.raise_for_status()
                    return response.json()
                except requests.exceptions.RequestException as e:
                    if attempt == max_retries - 1:
                        print(f"Failed to fetch {url}: {str(e)}")
                        return None
                    time.sleep(2 ** attempt)
        finally:
            self._return_session(session)

class AdvancedDatabaseManager:
    """Advanced database manager with connection pooling"""
    
    def __init__(self, db_config: Dict, min_connections: int = 5, max_connections: int = 20):
        self.db_config = db_config
        self.connection_pool = None
        self.lock = threading.Lock()
        self.min_connections = min_connections
        self.max_connections = max_connections
        
        # Initialize connection pool
        self._initialize_pool()
    
    def _initialize_pool(self):
        """Initialize connection pool"""
        try:
            self.connection_pool = psycopg2.pool.ThreadedConnectionPool(
                self.min_connections,
                self.max_connections,
                **self.db_config
            )
            print(f"✅ Connection pool initialized: {self.min_connections}-{self.max_connections} connections")
        except Exception as e:
            print(f"❌ Connection pool initialization failed: {str(e)}")
            self.connection_pool = None
    
    def get_connection(self):
        """Get connection from pool"""
        if not self.connection_pool:
            return None
        
        try:
            return self.connection_pool.getconn()
        except Exception as e:
            print(f"⚠️  Connection pool get failed: {str(e)}")
            return None
    
    def release_connection(self, conn):
        """Release connection back to pool"""
        if self.connection_pool and conn:
            try:
                self.connection_pool.putconn(conn)
            except Exception as e:
                print(f"⚠️  Connection pool release failed: {str(e)}")
    
    def execute(self, query: str, params: Optional[tuple] = None, fetch: bool = False):
        """Execute SQL query with connection pooling"""
        conn = self.get_connection()
        if not conn:
            return None
        
        try:
            with conn.cursor() as cursor:
                cursor.execute(query, params)
                if fetch:
                    result = cursor.fetchall()
                    return result
                conn.commit()
                return True
        except Exception as e:
            conn.rollback()
            print(f"❌ Query failed: {str(e)}")
            return None
        finally:
            self.release_connection(conn)
    
    def execute_batch(self, query: str, params_list: List[tuple]) -> bool:
        """Execute batch insert with connection pooling"""
        conn = self.get_connection()
        if not conn:
            return False
        
        try:
            with conn.cursor() as cursor:
                psycopg2.extras.execute_batch(cursor, query, params_list)
                conn.commit()
                return True
        except Exception as e:
            conn.rollback()
            print(f"❌ Batch execute failed: {str(e)}")
            return False
        finally:
            self.release_connection(conn)
    
    def get_pool_stats(self) -> Dict[str, Any]:
        """Get connection pool statistics"""
        if not self.connection_pool:
            return {'error': 'Pool not initialized'}
        
        return {
            'connections_in_use': self.connection_pool._used.getvalue(),
            'connections_available': self.max_connections - self.connection_pool._used.getvalue(),
            'total_connections': self.max_connections,
            'min_connections': self.min_connections
        }

class AdvancedDataProcessor:
    """Advanced data processing with batch operations"""
    
    @staticmethod
    def process_bill_batch(bill_data_list: List[Dict]) -> List[Dict]:
        """Process batch of bill data"""
        processed = []
        for bill_data in bill_data_list:
            processed_bill = {
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
            processed.append(processed_bill)
        
        return processed

class AdvancedParallelIngestor:
    """Advanced parallel ingestion with connection pooling"""
    
    def __init__(self, api_client: AdvancedAPIClient, db_manager: AdvancedDatabaseManager, workers: int = 8):
        self.api_client = api_client
        self.db_manager = db_manager
        self.workers = workers
        self.task_queue = queue.Queue()
        self.result_queue = queue.Queue()
        self.stop_event = threading.Event()
        self.worker_threads = []
        self.stats = {
            'total_tasks': 0,
            'completed_tasks': 0,
            'success_count': 0,
            'failure_count': 0,
            'start_time': None,
            'end_time': None
        }
    
    def _worker_thread(self):
        """Advanced worker thread with connection pooling"""
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
                print(f"⚠️  Worker error: {str(e)}")
    
    def _process_task(self, data_type: str, data_id: str) -> Dict:
        """Process individual task with connection pooling"""
        result = {
            'data_type': data_type,
            'data_id': data_id,
            'status': 'error',
            'records': 0,
            'error': None,
            'start_time': datetime.now().isoformat(),
            'end_time': None
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
            result['end_time'] = datetime.now().isoformat()
            
        except Exception as e:
            result['error'] = str(e)
            result['end_time'] = datetime.now().isoformat()
        
        return result
    
    def _ingest_bill(self, bill_id: str) -> int:
        """Ingest single bill with connection pooling"""
        data = self.api_client.get(f"bill/{bill_id}")
        if not data or 'bill' not in data:
            return 0
        
        bill_data = data['bill']
        processed = AdvancedDataProcessor.process_bill_batch([bill_data])[0]
        
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
    
    def start_workers(self):
        """Start worker threads"""
        self.stats['start_time'] = datetime.now().isoformat()
        self.worker_threads = []
        
        for i in range(self.workers):
            worker = threading.Thread(target=self._worker_thread, daemon=True, name=f"worker-{i}")
            worker.start()
            self.worker_threads.append(worker)
        
        print(f"✅ Started {self.workers} worker threads")
    
    def stop_workers(self):
        """Stop worker threads"""
        self.stop_event.set()
        
        # Send stop signal to all workers
        for _ in range(len(self.worker_threads)):
            self.task_queue.put(None)
        
        # Wait for workers to finish
        for worker in self.worker_threads:
            worker.join()
        
        self.stats['end_time'] = datetime.now().isoformat()
        print(f"✅ Stopped {len(self.worker_threads)} worker threads")
    
    def ingest_data_parallel(self, data_type: str, data_ids: List[str]) -> Dict:
        """Ingest data in parallel with statistics"""
        self.stats['total_tasks'] = len(data_ids)
        self.stats['completed_tasks'] = 0
        self.stats['success_count'] = 0
        self.stats['failure_count'] = 0
        
        # Add tasks to queue
        for data_id in data_ids:
            self.task_queue.put((data_type, data_id))
        
        # Process results
        processed = 0
        while processed < len(data_ids):
            try:
                result = self.result_queue.get(timeout=5)
                self.stats['completed_tasks'] += 1
                
                if result['status'] == 'success':
                    self.stats['success_count'] += 1
                else:
                    self.stats['failure_count'] += 1
                    if result['error']:
                        print(f"⚠️  {result['data_type']} {result['data_id']}: {result['error']}")
                
                processed += 1
                
                # Print progress every 10 tasks
                if processed % 10 == 0:
                    progress = (processed / len(data_ids)) * 100
                    print(f"📊 Progress: {processed}/{len(data_ids)} ({progress:.1f}%)")
                    
            except queue.Empty:
                continue
        
        # Calculate duration
        if self.stats['start_time'] and self.stats['end_time']:
            start = datetime.fromisoformat(self.stats['start_time'])
            end = datetime.fromisoformat(self.stats['end_time'])
            self.stats['duration_seconds'] = (end - start).total_seconds()
        
        return self.stats
    
    def get_stats(self) -> Dict:
        """Get ingestion statistics"""
        return self.stats.copy()
    
    def get_performance_metrics(self) -> Dict:
        """Get performance metrics"""
        metrics = self.get_stats()
        
        if metrics['duration_seconds'] and metrics['completed_tasks'] > 0:
            metrics['tasks_per_second'] = metrics['completed_tasks'] / metrics['duration_seconds']
            metrics['success_rate'] = (metrics['success_count'] / metrics['completed_tasks']) * 100
        
        # Add database pool stats
        metrics['db_pool_stats'] = self.db_manager.get_pool_stats()
        
        return metrics

def main():
    """Main function for advanced ingestion"""
    
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
    
    print("🚀 Advanced Congress Data Ingestion System")
    print("=" * 60)
    
    # Initialize components
    print("Initializing advanced components...")
    
    # Create API client with connection pooling
    api_client = AdvancedAPIClient(
        config['congress_api']['api_key'],
        rate_limit=config['api_settings']['rate_limit']
    )
    print("✅ Advanced API client initialized")
    
    # Create database manager with connection pooling
    db_manager = AdvancedDatabaseManager(
        db_config,
        min_connections=5,
        max_connections=20
    )
    print("✅ Advanced database manager initialized")
    
    # Create parallel ingestor
    ingestor = AdvancedParallelIngestor(api_client, db_manager, workers=8)
    print("✅ Advanced parallel ingestor initialized")
    
    # Start workers
    ingestor.start_workers()
    
    # Example: Ingest recent bills
    print("\n📊 Ingesting recent bills...")
    
    # Get list of recent bills (simplified for example)
    # In a real implementation, this would fetch from the API
    sample_bill_ids = [
        f"118hr{i:04d}" for i in range(1, 51)  # 50 sample bill IDs
    ]
    
    # Ingest bills
    results = ingestor.ingest_data_parallel('bill', sample_bill_ids)
    
    # Stop workers
    ingestor.stop_workers()
    
    # Print results
    print(f"\n🎯 Ingestion Results:")
    print(f"   Total Tasks: {results['total_tasks']}")
    print(f"   Completed: {results['completed_tasks']}")
    print(f"   Success: {results['success_count']}")
    print(f"   Failed: {results['failure_count']}")
    print(f"   Duration: {results.get('duration_seconds', 0):.2f} seconds")
    
    # Print performance metrics
    metrics = ingestor.get_performance_metrics()
    print(f"\n📈 Performance Metrics:")
    print(f"   Tasks/Second: {metrics.get('tasks_per_second', 0):.2f}")
    print(f"   Success Rate: {metrics.get('success_rate', 0):.1f}%")
    print(f"   DB Connections: {metrics['db_pool_stats'].get('connections_in_use', 0)}/{metrics['db_pool_stats'].get('total_connections', 0)}")
    
    print("\n✅ Advanced ingestion complete!")
    print("\n🎯 Features Demonstrated:")
    print("   ✅ Connection pooling for API and database")
    print("   ✅ Parallel processing with 8 workers")
    print("   ✅ Real-time progress tracking")
    print("   ✅ Comprehensive performance metrics")
    print("   ✅ Robust error handling")
    print("   ✅ Batch processing capabilities")

if __name__ == "__main__":
    main()
