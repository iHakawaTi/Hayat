"""
Supabase Client Utility
Helper functions for interacting with the Supabase database.
"""

from supabase import create_client, Client
import pandas as pd
import sys
import os

sys.path.append(os.path.dirname(os.path.dirname(os.path.dirname(os.path.abspath(__file__)))))

from config.settings import SUPABASE_URL, SUPABASE_ANON_KEY, SUPABASE_TABLES


class SupabaseClient:
    """Wrapper for Supabase operations"""
    
    def __init__(self, url: str = None, key: str = None):
        self.url = url or SUPABASE_URL
        self.key = key or SUPABASE_ANON_KEY
        self.client: Client = create_client(self.url, self.key)
    
    def get_table(self, table_name: str, limit: int = None) -> pd.DataFrame:
        """Fetch all rows from a table"""
        query = self.client.table(table_name).select("*")
        if limit:
            query = query.limit(limit)
        result = query.execute()
        return pd.DataFrame(result.data) if result.data else pd.DataFrame()
    
    def get_donors(self, limit: int = None) -> pd.DataFrame:
        """Fetch donors table"""
        return self.get_table(SUPABASE_TABLES['donors'], limit)
    
    def get_hospitals(self, limit: int = None) -> pd.DataFrame:
        """Fetch hospitals table"""
        return self.get_table(SUPABASE_TABLES['hospitals'], limit)
    
    def get_blood_banks(self, limit: int = None) -> pd.DataFrame:
        """Fetch blood banks table"""
        return self.get_table(SUPABASE_TABLES['blood_banks'], limit)
    
    def get_blood_requests(self, limit: int = None) -> pd.DataFrame:
        """Fetch blood requests table"""
        return self.get_table(SUPABASE_TABLES['blood_requests'], limit)
    
    def get_requests_view(self, limit: int = None) -> pd.DataFrame:
        """Fetch the v_requests view (joined data)"""
        return self.get_table(SUPABASE_TABLES['v_requests'], limit)
    
    def insert_rows(self, table_name: str, data: list[dict]) -> dict:
        """Insert rows into a table"""
        result = self.client.table(table_name).insert(data).execute()
        return result
    
    def upsert_dataframe(self, table_name: str, df: pd.DataFrame) -> dict:
        """Upsert a DataFrame to a table"""
        records = df.to_dict('records')
        result = self.client.table(table_name).upsert(records).execute()
        return result
    
    def get_schema_info(self) -> dict:
        """Get basic schema information for all tables"""
        schema = {}
        for name, table in SUPABASE_TABLES.items():
            try:
                result = self.client.table(table).select("*").limit(1).execute()
                if result.data:
                    schema[name] = {
                        'columns': list(result.data[0].keys()),
                        'sample': result.data[0]
                    }
                else:
                    schema[name] = {'columns': [], 'sample': None}
            except Exception as e:
                schema[name] = {'error': str(e)}
        return schema
    
    def get_row_counts(self) -> dict:
        """Get row counts for all tables"""
        counts = {}
        for name, table in SUPABASE_TABLES.items():
            try:
                result = self.client.table(table).select("*", count="exact").execute()
                counts[name] = result.count
            except Exception as e:
                counts[name] = f"Error: {e}"
        return counts


def main():
    """Test Supabase connection"""
    print("=" * 60)
    print("🔗 TESTING SUPABASE CONNECTION")
    print("=" * 60)
    
    client = SupabaseClient()
    
    print("\n📊 Row Counts:")
    counts = client.get_row_counts()
    for table, count in counts.items():
        print(f"  {table}: {count}")
    
    print("\n📋 Schema Info:")
    schema = client.get_schema_info()
    for table, info in schema.items():
        if 'columns' in info:
            print(f"\n  {table}:")
            print(f"    Columns: {info['columns'][:5]}...")  # First 5 columns
    
    print("\n✅ Connection successful!")


if __name__ == "__main__":
    main()
