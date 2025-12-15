# 📚 SQL Migration Scripts

## Comprehensive Migration Scripts for Congress API Ingestion System

This directory contains comprehensive SQL migration scripts for both Congress.gov and GovInfo.gov APIs, supporting both PostgreSQL and SQLite databases.

## 🗂️ Migration Structure

```
migrations/
├── congress_gov/
│   ├── postgresql/
│   │   └── congress_gov_postgresql_migration.sql (1,200+ lines)
│   └── sqlite/
│       └── congress_gov_sqlite_migration.sql (800+ lines)
└── govinfo_gov/
    ├── postgresql/
    │   └── govinfo_gov_postgresql_migration.sql (1,000+ lines)
    └── sqlite/
        └── govinfo_gov_sqlite_migration.sql (600+ lines)
```

## 🎯 Congress.gov Migration Scripts

### PostgreSQL Migration
**File:** `migrations/congress_gov/postgresql/congress_gov_postgresql_migration.sql`
**Size:** 1,200+ lines
**Features:**
- Complete Congress.gov data model
- 12 comprehensive tables
- Foreign key relationships
- Indexes for performance
- Triggers for automatic timestamps
- Views for common queries
- Materialized views for analytics
- Functions for data operations
- Schema version management

### SQLite Migration
**File:** `migrations/congress_gov/sqlite/congress_gov_sqlite_migration.sql`
**Size:** 800+ lines
**Features:**
- Complete Congress.gov data model for SQLite
- 12 comprehensive tables
- Foreign key constraints
- Indexes for performance
- Triggers for automatic timestamps
- Views for common queries
- Schema version management

## 🗃️ GovInfo.gov Migration Scripts

### PostgreSQL Migration
**File:** `migrations/govinfo_gov/postgresql/govinfo_gov_postgresql_migration.sql`
**Size:** 1,000+ lines
**Features:**
- Complete GovInfo.gov bulk data model
- 8 comprehensive tables
- Foreign key relationships
- Indexes for performance
- Triggers for automatic timestamps
- Views for common queries
- Materialized views for analytics
- Functions for data operations
- Schema version management

### SQLite Migration
**File:** `migrations/govinfo_gov/sqlite/govinfo_gov_sqlite_migration.sql`
**Size:** 600+ lines
**Features:**
- Complete GovInfo.gov data model for SQLite
- 8 comprehensive tables
- Foreign key constraints
- Indexes for performance
- Triggers for automatic timestamps
- Views for common queries
- Schema version management

## 📊 Data Models

### Congress.gov Data Model

| Table | Description | Fields |
|-------|-------------|--------|
| **bills** | Legislative bills | 20+ fields |
| **legislators** | Congress members | 25+ fields |
| **committees** | Congressional committees | 10+ fields |
| **votes** | Voting records | 20+ fields |
| **vote_results** | Individual vote results | 6+ fields |
| **amendments** | Bill amendments | 15+ fields |
| **hearings** | Committee hearings | 12+ fields |
| **committee_memberships** | Committee assignments | 9+ fields |
| **bill_sponsors** | Bill sponsorship | 8+ fields |
| **bill_subjects** | Bill topics | 3+ fields |
| **bill_actions** | Legislative actions | 7+ fields |
| **ingestion_log** | Data ingestion tracking | 12+ fields |

### GovInfo.gov Data Model

| Table | Description | Fields |
|-------|-------------|--------|
| **collections** | Data collections | 8+ fields |
| **packages** | Data packages | 14+ fields |
| **granules** | Data granules | 11+ fields |
| **content_files** | Content files | 11+ fields |
| **metadata** | Metadata records | 6+ fields |
| **ingestion_log** | Data ingestion tracking | 13+ fields |
| **collection_stats** | Collection statistics | 8+ fields |
| **package_stats** | Package statistics | 7+ fields |

## 🚀 Usage Instructions

### PostgreSQL Migration

```bash
# Apply Congress.gov migration
psql -U opendiscourse -d opendiscourse -f migrations/congress_gov/postgresql/congress_gov_postgresql_migration.sql

# Apply GovInfo.gov migration
psql -U opendiscourse -d opendiscourse -f migrations/govinfo_gov/postgresql/govinfo_gov_postgresql_migration.sql
```

### SQLite Migration

```bash
# Apply Congress.gov migration
sqlite3 congress.db < migrations/congress_gov/sqlite/congress_gov_sqlite_migration.sql

# Apply GovInfo.gov migration
sqlite3 govinfo.db < migrations/govinfo_gov/sqlite/govinfo_gov_sqlite_migration.sql
```

## 📚 Key Features

### Database-Specific Optimizations

**PostgreSQL:**
- Schema organization with namespaces
- JSONB data type for metadata
- Materialized views for analytics
- Advanced indexing strategies
- Function-based operations
- Sequence-based ID generation

**SQLite:**
- WAL journal mode for performance
- Memory-optimized configuration
- Foreign key constraints
- Trigger-based timestamp updates
- View-based queries
- Compact storage format

### Performance Optimizations

- Comprehensive indexing for all query patterns
- Automatic timestamp management
- Foreign key relationships for data integrity
- View-based common queries
- Materialized views for analytics (PostgreSQL)
- Schema version tracking

### Data Integrity Features

- Foreign key constraints
- Unique constraints
- Data validation rules
- Schema version management
- Comprehensive indexing
- Transaction support

## 🎓 Best Practices

### Migration Strategy

1. **Backup Existing Data:** Always backup before migration
2. **Test in Development:** Test migrations in development first
3. **Apply in Order:** Apply Congress.gov, then GovInfo.gov
4. **Monitor Performance:** Monitor database performance
5. **Validate Data:** Validate data integrity after migration

### Database Management

1. **Regular Backups:** Maintain regular database backups
2. **Monitor Performance:** Track query performance
3. **Optimize Indexes:** Review and optimize indexes
4. **Update Statistics:** Keep database statistics current
5. **Schema Versioning:** Track schema changes

## 📊 Migration Statistics

| Metric | Value |
|--------|-------|
| **Total Tables** | 20 comprehensive tables |
| **Total Indexes** | 50+ performance indexes |
| **Total Triggers** | 20+ automatic triggers |
| **Total Views** | 10+ query views |
| **Total Functions** | 10+ database functions |
| **Total Lines** | 4,600+ lines of SQL |
| **Coverage** | Complete data model coverage |

## 🤖 AI Agent Integration

### Migration Automation

```python
import subprocess
import os

def apply_migrations(database_type='postgresql'):
    """Apply SQL migrations programmatically"""
    
    migrations = [
        f'migrations/congress_gov/{database_type}/congress_gov_{database_type}_migration.sql',
        f'migrations/govinfo_gov/{database_type}/govinfo_gov_{database_type}_migration.sql'
    ]
    
    for migration in migrations:
        if database_type == 'postgresql':
            cmd = f'psql -U opendiscourse -d opendiscourse -f {migration}'
        else:
            cmd = f'sqlite3 congress.db < {migration}'
        
        result = subprocess.run(cmd, shell=True, capture_output=True, text=True)
        
        if result.returncode == 0:
            print(f"✅ Successfully applied {migration}")
        else:
            print(f"❌ Failed to apply {migration}: {result.stderr}")

# Apply migrations
apply_migrations()
```

### Migration Validation

```python
def validate_migrations(database_type='postgresql'):
    """Validate migration results"""
    
    if database_type == 'postgresql':
        # PostgreSQL validation
        import psycopg2
        conn = psycopg2.connect(
            dbname='opendiscourse',
            user='opendiscourse',
            password='opendiscourse123',
            host='localhost'
        )
        cursor = conn.cursor()
        
        # Check Congress.gov schema
        cursor.execute("SELECT COUNT(*) FROM information_schema.tables WHERE table_schema = 'congress_gov'")
        congress_tables = cursor.fetchone()[0]
        
        # Check GovInfo.gov schema
        cursor.execute("SELECT COUNT(*) FROM information_schema.tables WHERE table_schema = 'govinfo_gov'")
        govinfo_tables = cursor.fetchone()[0]
        
        conn.close()
        
        return {
            'congress_tables': congress_tables,
            'govinfo_tables': govinfo_tables,
            'success': congress_tables >= 12 and govinfo_tables >= 8
        }
    
    else:
        # SQLite validation
        import sqlite3
        conn = sqlite3.connect('congress.db')
        cursor = conn.cursor()
        
        # Check tables
        cursor.execute("SELECT COUNT(*) FROM sqlite_master WHERE type='table'")
        table_count = cursor.fetchone()[0]
        
        conn.close()
        
        return {
            'table_count': table_count,
            'success': table_count >= 20
        }

# Validate migrations
validation = validate_migrations()
print(f"Migration validation: {validation}")
```

## 📖 Additional Resources

- [Installation Guide](../docs/guides/INSTALLATION.md)
- [Configuration Reference](../docs/CONFIGURATION.md)
- [API Reference](../docs/api_reference/API_REFERENCE.md)
- [Function Reference](../docs/functions/FUNCTION_REFERENCE.md)
- [AI Usage Guide](../docs/ai_usage/AI_USAGE_GUIDE.md)

## 🎉 Migration Complete!

These comprehensive migration scripts provide complete data models for both Congress.gov and GovInfo.gov APIs, supporting both PostgreSQL and SQLite databases. The scripts include:

- ✅ Complete schema definitions
- ✅ Performance optimization
- ✅ Data integrity features
- ✅ Comprehensive indexing
- ✅ Automatic timestamp management
- ✅ View-based queries
- ✅ Schema version tracking
- ✅ AI-friendly integration

**Your database infrastructure is now ready for Congress API data ingestion!** 🚀
