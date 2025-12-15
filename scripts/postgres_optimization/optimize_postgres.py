#!/usr/bin/env python3
"""
Comprehensive PostgreSQL Optimization System
Calculates optimal workers, implements connection pooling, and enhances database features
"""

import os
import sys
import json
import multiprocessing
import psycopg2
import psycopg2.pool
import psycopg2.extras
import subprocess
import platform
import socket
import time
from typing import Dict, Any, Optional, Tuple

# Add project root to path
sys.path.append(os.path.dirname(os.path.dirname(os.path.abspath(__file__))))

class SystemAnalyzer:
    """Analyze system resources to determine optimal configuration"""
    
    @staticmethod
    def get_cpu_info() -> Dict[str, Any]:
        """Get CPU information"""
        cpu_info = {
            'physical_cores': multiprocessing.cpu_count(),
            'logical_cores': multiprocessing.cpu_count(),
            'cpu_model': platform.processor(),
            'cpu_usage': 0.0
        }
        
        try:
            # Get CPU usage
            if platform.system() == 'Linux':
                with open('/proc/loadavg', 'r') as f:
                    load_avg = f.read().split()
                    cpu_info['load_avg_1min'] = float(load_avg[0])
                    cpu_info['load_avg_5min'] = float(load_avg[1])
                    cpu_info['load_avg_15min'] = float(load_avg[2])
        except Exception as e:
            print(f"CPU info error: {str(e)}")
        
        return cpu_info
    
    @staticmethod
    def get_memory_info() -> Dict[str, Any]:
        """Get memory information"""
        mem_info = {'total': 0, 'available': 0, 'used': 0, 'free': 0}
        
        try:
            if platform.system() == 'Linux':
                with open('/proc/meminfo', 'r') as f:
                    for line in f:
                        if line.startswith('MemTotal:'):
                            mem_info['total'] = int(line.split()[1]) // 1024  # Convert to MB
                        elif line.startswith('MemAvailable:'):
                            mem_info['available'] = int(line.split()[1]) // 1024
                        elif line.startswith('MemFree:'):
                            mem_info['free'] = int(line.split()[1]) // 1024
        except Exception as e:
            print(f"Memory info error: {str(e)}")
        
        mem_info['used'] = mem_info['total'] - mem_info['free']
        return mem_info
    
    @staticmethod
    def get_network_info() -> Dict[str, Any]:
        """Get network information"""
        net_info = {
            'hostname': socket.gethostname(),
            'ip_address': socket.gethostbyname(socket.gethostname()),
            'interfaces': []
        }
        
        try:
            if platform.system() == 'Linux':
                # Get network interfaces
                with open('/proc/net/dev', 'r') as f:
                    lines = f.readlines()
                    for line in lines[2:]:  # Skip header lines
                        parts = line.split()
                        if len(parts) >= 17:
                            interface = {
                                'name': parts[0].strip(':'),
                                'rx_bytes': int(parts[1]),
                                'tx_bytes': int(parts[9])
                            }
                            net_info['interfaces'].append(interface)
        except Exception as e:
            print(f"Network info error: {str(e)}")
        
        return net_info
    
    @staticmethod
    def get_disk_info() -> Dict[str, Any]:
        """Get disk information"""
        disk_info = {'total': 0, 'used': 0, 'free': 0, 'partitions': []}
        
        try:
            if platform.system() == 'Linux':
                # Get disk usage
                result = subprocess.run(['df', '-h'], capture_output=True, text=True)
                lines = result.stdout.split('\n')
                for line in lines[1:]:  # Skip header
                    if line.strip():
                        parts = line.split()
                        if len(parts) >= 6:
                            partition = {
                                'filesystem': parts[0],
                                'size': parts[1],
                                'used': parts[2],
                                'available': parts[3],
                                'use_percent': parts[4],
                                'mounted_on': parts[5]
                            }
                            disk_info['partitions'].append(partition)
        except Exception as e:
            print(f"Disk info error: {str(e)}")
        
        return disk_info
    
    @staticmethod
    def calculate_optimal_workers() -> int:
        """Calculate optimal number of workers based on system resources"""
        cpu_info = SystemAnalyzer.get_cpu_info()
        mem_info = SystemAnalyzer.get_memory_info()
        
        # Base calculation: CPU cores
        optimal_workers = cpu_info['logical_cores']
        
        # Adjust based on memory
        # For data ingestion, we need at least 500MB per worker
        memory_per_worker = 500  # MB
        max_workers_by_memory = mem_info['available'] // memory_per_worker
        
        if max_workers_by_memory < optimal_workers:
            optimal_workers = max_workers_by_memory
        
        # Minimum of 2 workers, maximum of 20 for data ingestion
        optimal_workers = max(2, min(optimal_workers, 20))
        
        # Adjust based on CPU load
        if 'load_avg_1min' in cpu_info:
            load_factor = cpu_info['load_avg_1min'] / cpu_info['logical_cores']
            if load_factor > 0.8:  # High load
                optimal_workers = max(2, optimal_workers // 2)
        
        return optimal_workers

class PostgreSQLOptimizer:
    """Optimize PostgreSQL configuration and extensions"""
    
    def __init__(self, db_config: Dict[str, Any]):
        self.db_config = db_config
        self.connection = None
        self.pool = None
    
    def connect(self) -> bool:
        """Establish database connection"""
        try:
            self.connection = psycopg2.connect(**self.db_config)
            return True
        except Exception as e:
            print(f"Database connection failed: {str(e)}")
            return False
    
    def create_connection_pool(self, min_connections: int = 5, max_connections: int = 20) -> bool:
        """Create connection pool"""
        try:
            self.pool = psycopg2.pool.ThreadedConnectionPool(
                min_connections,
                max_connections,
                **self.db_config
            )
            return True
        except Exception as e:
            print(f"Connection pool creation failed: {str(e)}")
            return False
    
    def install_extensions(self) -> Dict[str, bool]:
        """Install useful PostgreSQL extensions"""
        extensions = [
            'pg_stat_statements',  # Query performance monitoring
            'pg_repack',           # Online table reorganization
            'pg_partman',          # Partition management
            'pg_cron',             # Job scheduling
            'pg_audit',            # Audit logging
            'pg_prewarm',          # Preload data into cache
            'pg_buffercache',      # Buffer cache inspection
            'pg_qualstats',        # Query qualification statistics
            'pg_stat_kcache',      # Kernel cache statistics
            'pg_wait_sampling',    # Wait event sampling
            'pg_visibility',       # Visibility map inspection
            'pg_freespacemap',     # Free space map inspection
            'pgrowlocks',          # Row locking information
            'pg_trigger',          # Trigger information
            'pg_amcheck',          # Data corruption detection
            'pg_walinspect',       # WAL inspection
            'pg_squeeze',          # Table bloat reduction
            'pg_ivm',              # Incremental view maintenance
            'pg_logical',          # Logical decoding
            'pg_output',           # Logical decoding output plugin
            'pg_rewind',           # Database cluster rewinding
            'pg_standby',          # Warm standby tools
            'pg_upgrade',          # Database upgrade tools
            'pg_verifybackup',     # Backup verification
            'pg_wal',              # WAL utilities
            'pg_waldump',          # WAL dump utility
            'pg_xlogdump',         # Transaction log dump utility
            'pg_archivecleanup',   # WAL archive cleanup
            'pg_basebackup',       # Base backup utility
            'pg_receivewal',       # WAL receiver
            'pg_recvlogical',      # Logical decoding receiver
            'pg_test_fsync',       # File sync performance test
            'pg_test_timing',      # Timing performance test
            'pg_bench',            # Benchmarking tool
            'pg_config',           # Configuration utility
            'pg_controldata',      # Control file inspection
            'pg_ctl',              # Database control utility
            'pg_dump',             # Database backup
            'pg_dumpall',          # All databases backup
            'pg_isready',          # Connection status check
            'pg_resetwal',         # WAL reset utility
            'pg_restore',          # Database restore
            'pg_verifybackup',     # Backup verification
            'vacuumlo',            # Large object cleanup
            'cluster_db',          # Database clustering
            'createdb',            # Database creation
            'createuser',          # User creation
            'dropdb',              # Database removal
            'dropuser',            # User removal
            'ecpg',                # Embedded SQL preprocessor
            'pg_amcheck',          # Data corruption detection
            'pg_archivecleanup',   # WAL archive cleanup
            'pg_basebackup',       # Base backup utility
            'pg_bench',            # Benchmarking tool
            'pg_checksums',        # Data checksum verification
            'pg_config',           # Configuration utility
            'pg_controldata',      # Control file inspection
            'pg_ctl',              # Database control utility
            'pg_dump',             # Database backup
            'pg_dumpall',          # All databases backup
            'pg_isready',          # Connection status check
            'pg_receivewal',       # WAL receiver
            'pg_recvlogical',      # Logical decoding receiver
            'pg_resetwal',         # WAL reset utility
            'pg_restore',          # Database restore
            'pg_rewind',           # Database cluster rewinding
            'pg_test_fsync',       # File sync performance test
            'pg_test_timing',      # Timing performance test
            'pg_upgrade',          # Database upgrade tools
            'pg_verifybackup',     # Backup verification
            'pg_wal',              # WAL utilities
            'pg_waldump',          # WAL dump utility
            'pg_xlogdump',         # Transaction log dump utility
        ]
        
        results = {}
        
        for extension in extensions:
            try:
                with self.connection.cursor() as cursor:
                    cursor.execute(f"CREATE EXTENSION IF NOT EXISTS {extension}")
                    self.connection.commit()
                    results[extension] = True
                    print(f"✅ Installed extension: {extension}")
            except Exception as e:
                print(f"⚠️  Extension {extension} failed: {str(e)}")
                results[extension] = False
        
        return results
    
    def optimize_postgresql_config(self) -> Dict[str, bool]:
        """Optimize PostgreSQL configuration for high throughput"""
        optimizations = {
            'shared_buffers': '4GB',
            'effective_cache_size': '12GB',
            'maintenance_work_mem': '1GB',
            'work_mem': '64MB',
            'wal_buffers': '16MB',
            'default_statistics_target': '100',
            'random_page_cost': '1.1',
            'effective_io_concurrency': '200',
            'max_worker_processes': '8',
            'max_parallel_workers_per_gather': '4',
            'max_parallel_workers': '8',
            'max_parallel_maintenance_workers': '4',
            'max_connections': '200',
            'superuser_reserved_connections': '10',
            'autovacuum': 'on',
            'autovacuum_max_workers': '4',
            'autovacuum_naptime': '1min',
            'autovacuum_vacuum_threshold': '50',
            'autovacuum_analyze_threshold': '50',
            'autovacuum_vacuum_scale_factor': '0.2',
            'autovacuum_analyze_scale_factor': '0.1',
            'autovacuum_vacuum_cost_delay': '20',
            'autovacuum_vacuum_cost_limit': '2000',
            'checkpoint_timeout': '15min',
            'checkpoint_completion_target': '0.9',
            'checkpoint_flush_after': '256kB',
            'max_wal_size': '4GB',
            'min_wal_size': '1GB',
            'wal_compression': 'on',
            'wal_level': 'logical',
            'synchronous_commit': 'off',
            'full_page_writes': 'off',
            'hot_standby': 'on',
            'max_standby_archive_delay': '30s',
            'max_standby_streaming_delay': '30s',
            'wal_keep_size': '1GB',
            'wal_keep_segments': '64',
            'archive_mode': 'on',
            'archive_command': 'cd .',
            'archive_timeout': '60s',
            'logging_collector': 'on',
            'log_destination': 'csvlog',
            'log_directory': 'log',
            'log_filename': 'postgresql-%Y-%m-%d_%H%M%S.log',
            'log_truncate_on_rotation': 'on',
            'log_rotation_age': '1d',
            'log_rotation_size': '100MB',
            'log_min_duration_statement': '1000',
            'log_checkpoints': 'on',
            'log_connections': 'on',
            'log_disconnections': 'on',
            'log_lock_waits': 'on',
            'log_temp_files': '0',
            'log_autovacuum_min_duration': '0',
            'log_error_verbosity': 'verbose',
            'log_line_prefix': '%m [%p] %q%u@%d ',
            'log_statement': 'all',
            'track_activities': 'on',
            'track_counts': 'on',
            'track_io_timing': 'on',
            'track_functions': 'all',
            'track_activity_query_size': '2048',
            'idle_in_transaction_session_timeout': '10min',
            'statement_timeout': '60s',
            'lock_timeout': '5s',
            'deadlock_timeout': '1s',
            'tcp_keepalives_idle': '60',
            'tcp_keepalives_interval': '10',
            'tcp_keepalives_count': '10',
            'shared_preload_libraries': 'pg_stat_statements,pg_cron,pg_repack,pg_partman,pg_audit,pg_prewarm,pg_buffercache,pg_qualstats,pg_stat_kcache,pg_wait_sampling,pg_visibility,pg_freespacemap,pgrowlocks,pg_trigger,pg_amcheck,pg_walinspect,pg_squeeze,pg_ivm,pg_logical,pg_output,pg_rewind,pg_standby,pg_upgrade,pg_verifybackup,pg_wal,pg_waldump,pg_xlogdump,pg_archivecleanup,pg_basebackup,pg_receivewal,pg_recvlogical,pg_test_fsync,pg_test_timing,pg_bench,pg_config,pg_controldata,pg_ctl,pg_dump,pg_dumpall,pg_isready,pg_resetwal,pg_restore,pg_verifybackup,vacuumlo,cluster_db,createdb,createuser,dropdb,dropuser,ecpg,pg_amcheck,pg_archivecleanup,pg_basebackup,pg_bench,pg_checksums,pg_config,pg_controldata,pg_ctl,pg_dump,pg_dumpall,pg_isready,pg_receivewal,pg_recvlogical,pg_resetwal,pg_restore,pg_rewind,pg_test_fsync,pg_test_timing,pg_upgrade,pg_verifybackup,pg_wal,pg_waldump,pg_xlogdump'
        }
        
        results = {}
        
        # Write to postgresql.conf
        try:
            conf_path = '/etc/postgresql/18/main/postgresql.conf'
            with open(conf_path, 'a') as f:
                for param, value in optimizations.items():
                    f.write(f"\n{param} = {value}")
                    results[param] = True
            
            print("✅ PostgreSQL configuration optimized")
            
            # Reload configuration
            subprocess.run(['sudo', '-u', 'postgres', '/usr/lib/postgresql/18/bin/pg_ctl', 
                          'reload', '-D', '/var/lib/postgresql/18/main'])
            
        except Exception as e:
            print(f"⚠️  Configuration optimization failed: {str(e)}")
            for param in optimizations:
                results[param] = False
        
        return results
    
    def create_optimization_table(self) -> bool:
        """Create table to store optimization settings"""
        try:
            with self.connection.cursor() as cursor:
                cursor.execute('''
                CREATE TABLE IF NOT EXISTS congress.optimization_settings (
                    id SERIAL PRIMARY KEY,
                    setting_name VARCHAR(100) UNIQUE NOT NULL,
                    setting_value TEXT,
                    data_type VARCHAR(20),
                    description TEXT,
                    last_updated TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
                    updated_by VARCHAR(50)
                )
                ''')
                
                cursor.execute('''
                CREATE TABLE IF NOT EXISTS congress.system_metrics (
                    id SERIAL PRIMARY KEY,
                    metric_name VARCHAR(100) NOT NULL,
                    metric_value TEXT,
                    data_type VARCHAR(20),
                    collected_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
                    notes TEXT
                )
                ''')
                
                cursor.execute('''
                CREATE TABLE IF NOT EXISTS congress.ingestion_performance (
                    id SERIAL PRIMARY KEY,
                    ingestion_type VARCHAR(50) NOT NULL,
                    records_processed INT,
                    start_time TIMESTAMP,
                    end_time TIMESTAMP,
                    duration_seconds FLOAT,
                    workers_used INT,
                    success_count INT,
                    failure_count INT,
                    notes TEXT
                )
                ''')
                
                self.connection.commit()
                return True
        except Exception as e:
            print(f"Optimization table creation failed: {str(e)}")
            return False
    
    def store_optimization_settings(self, settings: Dict[str, Any]) -> bool:
        """Store optimization settings in database"""
        try:
            with self.connection.cursor() as cursor:
                for name, value in settings.items():
                    # Check if setting exists
                    cursor.execute("SELECT 1 FROM congress.optimization_settings WHERE setting_name = %s", (name,))
                    exists = cursor.fetchone()
                    
                    if exists:
                        cursor.execute('''
                        UPDATE congress.optimization_settings
                        SET setting_value = %s, data_type = %s, description = %s, last_updated = CURRENT_TIMESTAMP
                        WHERE setting_name = %s
                        ''', (str(value), type(value).__name__, f"Auto-calculated {name}", name))
                    else:
                        cursor.execute('''
                        INSERT INTO congress.optimization_settings 
                        (setting_name, setting_value, data_type, description)
                        VALUES (%s, %s, %s, %s)
                        ''', (name, str(value), type(value).__name__, f"Auto-calculated {name}"))
            
            self.connection.commit()
            return True
        except Exception as e:
            print(f"Settings storage failed: {str(e)}")
            return False
    
    def store_system_metrics(self, metrics: Dict[str, Any]) -> bool:
        """Store system metrics in database"""
        try:
            with self.connection.cursor() as cursor:
                for name, value in metrics.items():
                    cursor.execute('''
                    INSERT INTO congress.system_metrics 
                    (metric_name, metric_value, data_type, notes)
                    VALUES (%s, %s, %s, %s)
                    ''', (name, str(value), type(value).__name__, "System analysis"))
            
            self.connection.commit()
            return True
        except Exception as e:
            print(f"Metrics storage failed: {str(e)}")
            return False
    
    def get_optimal_settings(self) -> Dict[str, Any]:
        """Get optimal settings from database"""
        try:
            with self.connection.cursor() as cursor:
                cursor.execute("SELECT setting_name, setting_value, data_type FROM congress.optimization_settings")
                results = cursor.fetchall()
                
                settings = {}
                for name, value, data_type in results:
                    # Convert value to appropriate type
                    if data_type == 'int':
                        settings[name] = int(value)
                    elif data_type == 'float':
                        settings[name] = float(value)
                    elif data_type == 'bool':
                        settings[name] = value.lower() == 'true'
                    else:
                        settings[name] = value
                
                return settings
        except Exception as e:
            print(f"Settings retrieval failed: {str(e)}")
            return {}

class AdvancedIngestionSystem:
    """Advanced ingestion system with connection pooling and optimization"""
    
    def __init__(self, db_config: Dict[str, Any]):
        self.db_config = db_config
        self.optimizer = PostgreSQLOptimizer(db_config)
        self.connection_pool = None
        self.worker_count = 4
    
    def initialize(self) -> bool:
        """Initialize the advanced ingestion system"""
        # Connect to database
        if not self.optimizer.connect():
            return False
        
        # Create optimization tables
        if not self.optimizer.create_optimization_table():
            return False
        
        # Analyze system
        system_analysis = self._analyze_system()
        
        # Store system metrics
        self.optimizer.store_system_metrics(system_analysis)
        
        # Calculate optimal workers
        optimal_workers = SystemAnalyzer.calculate_optimal_workers()
        self.worker_count = optimal_workers
        
        # Store optimization settings
        settings = {
            'optimal_workers': optimal_workers,
            'max_connections': 200,
            'connection_pool_size': min(optimal_workers * 2, 50),
            'batch_size': 50,
            'rate_limit': 1000,
            'timeout': 30,
            'max_retries': 3
        }
        
        self.optimizer.store_optimization_settings(settings)
        
        # Create connection pool
        pool_size = settings['connection_pool_size']
        if not self.optimizer.create_connection_pool(min_connections=5, max_connections=pool_size):
            return False
        
        self.connection_pool = self.optimizer.pool
        
        return True
    
    def _analyze_system(self) -> Dict[str, Any]:
        """Perform comprehensive system analysis"""
        analysis = {
            'system_info': {
                'os': platform.system(),
                'os_version': platform.version(),
                'architecture': platform.architecture(),
                'hostname': socket.gethostname()
            },
            'cpu_info': SystemAnalyzer.get_cpu_info(),
            'memory_info': SystemAnalyzer.get_memory_info(),
            'network_info': SystemAnalyzer.get_network_info(),
            'disk_info': SystemAnalyzer.get_disk_info(),
            'postgresql_version': self._get_postgresql_version()
        }
        
        return analysis
    
    def _get_postgresql_version(self) -> str:
        """Get PostgreSQL version"""
        try:
            with self.optimizer.connection.cursor() as cursor:
                cursor.execute("SELECT version()")
                return cursor.fetchone()[0]
        except Exception as e:
            return f"Unknown: {str(e)}"
    
    def get_connection(self):
        """Get connection from pool"""
        if self.connection_pool:
            return self.connection_pool.getconn()
        return None
    
    def release_connection(self, conn):
        """Release connection back to pool"""
        if self.connection_pool and conn:
            self.connection_pool.putconn(conn)
    
    def get_optimized_settings(self) -> Dict[str, Any]:
        """Get optimized settings for ingestion"""
        # Get from database first
        db_settings = self.optimizer.get_optimal_settings()
        
        # Default settings
        default_settings = {
            'workers': 4,
            'batch_size': 50,
            'max_connections': 20,
            'connection_pool_size': 10,
            'rate_limit': 1000,
            'timeout': 30,
            'max_retries': 3
        }
        
        # Merge settings (database settings take precedence)
        settings = {**default_settings, **db_settings}
        
        return settings

def main():
    """Main optimization function"""
    
    # Database configuration
    db_config = {
        'dbname': 'opendiscourse',
        'user': 'opendiscourse',
        'password': 'opendiscourse123',
        'host': 'localhost',
        'port': 5432
    }
    
    print("🚀 PostgreSQL Optimization System")
    print("=" * 50)
    
    # Initialize advanced system
    print("Initializing advanced ingestion system...")
    advanced_system = AdvancedIngestionSystem(db_config)
    
    if not advanced_system.initialize():
        print("❌ Initialization failed")
        return
    
    print("✅ Advanced system initialized")
    
    # Get optimized settings
    settings = advanced_system.get_optimized_settings()
    print(f"\n📊 Optimal Configuration:")
    print(f"   Workers: {settings.get('optimal_workers', 'N/A')}")
    print(f"   Max Connections: {settings.get('max_connections', 'N/A')}")
    print(f"   Connection Pool: {settings.get('connection_pool_size', 'N/A')}")
    print(f"   Batch Size: {settings.get('batch_size', 'N/A')}")
    print(f"   Rate Limit: {settings.get('rate_limit', 'N/A')}")
    
    # System analysis
    print(f"\n💻 System Analysis:")
    cpu_info = SystemAnalyzer.get_cpu_info()
    mem_info = SystemAnalyzer.get_memory_info()
    
    print(f"   CPU Cores: {cpu_info.get('logical_cores', 'N/A')}")
    print(f"   Memory Available: {mem_info.get('available', 'N/A')} MB")
    print(f"   Load Average: {cpu_info.get('load_avg_1min', 'N/A')}")
    
    # Optimize PostgreSQL
    print("\n🔧 Optimizing PostgreSQL...")
    optimizer = PostgreSQLOptimizer(db_config)
    
    if optimizer.connect():
        # Install extensions
        print("Installing PostgreSQL extensions...")
        extension_results = optimizer.install_extensions()
        installed_count = sum(1 for result in extension_results.values() if result)
        print(f"✅ Installed {installed_count} extensions")
        
        # Optimize configuration
        print("Optimizing PostgreSQL configuration...")
        config_results = optimizer.optimize_postgresql_config()
        optimized_count = sum(1 for result in config_results.values() if result)
        print(f"✅ Optimized {optimized_count} configuration parameters")
    
    print("\n✅ PostgreSQL optimization complete!")
    print("\n🎯 Next Steps:")
    print("   1. Use optimized settings in your ingestion scripts")
    print("   2. Monitor performance with pg_stat_statements")
    print("   3. Adjust settings based on actual workload")
    print("   4. Set up regular maintenance with pg_cron")

if __name__ == "__main__":
    main()
