#!/usr/bin/env python3
"""
PostgreSQL Database Backup Script
Creates automated backups with compression and timestamping
"""

import sys
import os
import json
import subprocess
import gzip
import shutil
from datetime import datetime
from pathlib import Path

def load_config():
    """Load database configuration"""
    with open('../config/config.json', 'r') as f:
        config = json.load(f)
    return config['database']

def create_backup_directory():
    """Create backup directory if it doesn't exist"""
    backup_dir = Path('../backups')
    backup_dir.mkdir(exist_ok=True)
    return backup_dir

def create_backup(db_config, backup_dir):
    """Create database backup using pg_dump"""
    timestamp = datetime.now().strftime('%Y%m%d_%H%M%S')
    backup_file = backup_dir / f'congress_backup_{timestamp}.sql'
    compressed_file = backup_dir / f'congress_backup_{timestamp}.sql.gz'
    
    print(f"Creating backup: {backup_file}")
    
    try:
        # Create pg_dump command
        env = os.environ.copy()
        env['PGPASSWORD'] = db_config['password']
        
        cmd = [
            'pg_dump',
            '-h', db_config['host'],
            '-p', str(db_config['port']),
            '-U', db_config['user'],
            '-d', db_config['database'],
            '--no-password',
            '--verbose',
            '--clean',
            '--if-exists',
            '--create',
            '--encoding', 'utf8',
            '--file', str(backup_file)
        ]
        
        # Execute pg_dump
        result = subprocess.run(cmd, env=env, capture_output=True, text=True)
        
        if result.returncode != 0:
            print(f"❌ Backup failed: {result.stderr}")
            return False
        
        # Compress the backup
        print(f"Compressing backup...")
        with open(backup_file, 'rb') as f_in:
            with gzip.open(compressed_file, 'wb') as f_out:
                shutil.copyfileobj(f_in, f_out)
        
        # Remove uncompressed file
        backup_file.unlink()
        
        # Get file size
        file_size = compressed_file.stat().st_size
        size_mb = file_size / (1024 * 1024)
        
        print(f"✅ Backup created successfully: {compressed_file}")
        print(f"   Size: {size_mb:.2f} MB")
        
        # Clean up old backups (keep last 7 days)
        cleanup_old_backups(backup_dir)
        
        return True
        
    except Exception as e:
        print(f"❌ Backup failed: {str(e)}")
        return False

def cleanup_old_backups(backup_dir, days=7):
    """Remove backups older than specified days"""
    import time
    
    current_time = time.time()
    cutoff_time = current_time - (days * 24 * 60 * 60)
    
    deleted_count = 0
    for backup_file in backup_dir.glob('congress_backup_*.sql.gz'):
        if backup_file.stat().st_mtime < cutoff_time:
            backup_file.unlink()
            deleted_count += 1
    
    if deleted_count > 0:
        print(f"🗑️  Cleaned up {deleted_count} old backup(s)")

def list_backups(backup_dir):
    """List all available backups"""
    backups = sorted(backup_dir.glob('congress_backup_*.sql.gz'))
    
    if not backups:
        print("No backups found")
        return
    
    print("Available backups:")
    for backup in backups:
        size_mb = backup.stat().st_size / (1024 * 1024)
        modified = datetime.fromtimestamp(backup.stat().st_mtime)
        print(f"  {backup.name} - {size_mb:.2f} MB - {modified}")

def restore_backup(db_config, backup_file):
    """Restore database from backup"""
    if not backup_file.exists():
        print(f"❌ Backup file not found: {backup_file}")
        return False
    
    print(f"Restoring from backup: {backup_file}")
    print("⚠️  This will overwrite the current database!")
    
    try:
        # Decompress backup
        temp_file = backup_file.parent / 'temp_restore.sql'
        
        with gzip.open(backup_file, 'rb') as f_in:
            with open(temp_file, 'wb') as f_out:
                shutil.copyfileobj(f_in, f_out)
        
        # Restore using psql
        env = os.environ.copy()
        env['PGPASSWORD'] = db_config['password']
        
        cmd = [
            'psql',
            '-h', db_config['host'],
            '-p', str(db_config['port']),
            '-U', db_config['user'],
            '-d', db_config['database'],
            '--no-password',
            '--file', str(temp_file)
        ]
        
        result = subprocess.run(cmd, env=env, capture_output=True, text=True)
        
        # Clean up temp file
        temp_file.unlink()
        
        if result.returncode != 0:
            print(f"❌ Restore failed: {result.stderr}")
            return False
        
        print("✅ Restore completed successfully")
        return True
        
    except Exception as e:
        print(f"❌ Restore failed: {str(e)}")
        return False

def main():
    """Main backup function"""
    import argparse
    
    parser = argparse.ArgumentParser(description='PostgreSQL Database Backup Tool')
    parser.add_argument('--backup', action='store_true', help='Create new backup')
    parser.add_argument('--list', action='store_true', help='List available backups')
    parser.add_argument('--restore', type=str, help='Restore from specific backup file')
    
    args = parser.parse_args()
    
    # Load configuration
    db_config = load_config()
    backup_dir = create_backup_directory()
    
    if args.backup:
        success = create_backup(db_config, backup_dir)
        sys.exit(0 if success else 1)
    
    elif args.list:
        list_backups(backup_dir)
        sys.exit(0)
    
    elif args.restore:
        backup_file = backup_dir / args.restore
        success = restore_backup(db_config, backup_file)
        sys.exit(0 if success else 1)
    
    else:
        # Default: create backup
        success = create_backup(db_config, backup_dir)
        sys.exit(0 if success else 1)

if __name__ == "__main__":
    main()
