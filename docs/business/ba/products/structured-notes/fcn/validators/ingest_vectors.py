#!/usr/bin/env python3
"""
FCN Test Vector Ingestion Script

Ingests test vector markdown files into database test_vector table.
Part of the FCN v1.0 governance framework.

Usage:
    python ingest_vectors.py <test_vectors_dir> <db_connection_string>
"""

import sys
import yaml
import re
import json
from pathlib import Path
from typing import Dict


class VectorIngester:
    """Ingests test vectors into database."""
    
    def __init__(self, db_connection_string: str = None):
        self.db_connection = db_connection_string
        self.vectors = []
    
    def extract_vector_data(self, file_path: Path) -> Dict:
        """Extract complete vector data from markdown file."""
        try:
            with open(file_path, 'r', encoding='utf-8') as f:
                content = f.read()
            
            # Extract YAML front matter
            pattern = r'^---\s*\n(.*?)\n---\s*\n'
            match = re.match(pattern, content, re.DOTALL)
            
            if not match:
                return None
            
            data = yaml.safe_load(match.group(1))
            
            vector_data = {
                'vector_code': data.get('vector_id'),
                'product_code': data.get('product_code'),
                'spec_version': data.get('spec_version'),
                'description': data.get('description'),
                'normative': data.get('normative', False),
                'taxonomy': data.get('taxonomy', {}),
                'parameters': data.get('parameters', {}),
                'market_scenario': data.get('market_scenario', {}),
                'expected_outputs': data.get('expected_outputs', {}),
                'tags': data.get('tags', [])
            }
            
            return vector_data
        except Exception as e:
            print(f"Error extracting data from {file_path.name}: {e}")
            return None
    
    def ingest_directory(self, test_vectors_dir: Path) -> int:
        """Ingest all test vectors from directory."""
        count = 0
        
        for vector_file in test_vectors_dir.glob('*.md'):
            vector_data = self.extract_vector_data(vector_file)
            
            if vector_data:
                self.vectors.append(vector_data)
                count += 1
                print(f"✅ Extracted: {vector_data['vector_code']}")
            else:
                print(f"❌ Failed: {vector_file.name}")
        
        return count
    
    def save_to_database(self) -> bool:
        """Save vectors to database."""
        if not self.db_connection:
            print("⚠️  No database connection provided. Vectors extracted but not saved.")
            return False
        
        # Database insertion logic would go here
        # For now, this is a placeholder
        print(f"\n📊 Would insert {len(self.vectors)} vectors into database")
        print(f"   Connection: {self.db_connection}")
        
        return True
    
    def export_to_json(self, output_path: Path) -> bool:
        """Export vectors to JSON file."""
        try:
            with open(output_path, 'w', encoding='utf-8') as f:
                json.dump(self.vectors, f, indent=2, ensure_ascii=False)
            
            print(f"\n✅ Exported {len(self.vectors)} vectors to {output_path}")
            return True
        except Exception as e:
            print(f"❌ Failed to export: {e}")
            return False
    
    def print_summary(self):
        """Print ingestion summary."""
        print(f"\n{'='*70}")
        print(f"Test Vector Ingestion Summary")
        print(f"{'='*70}")
        print(f"Total vectors extracted: {len(self.vectors)}")
        
        normative_count = sum(1 for v in self.vectors if v.get('normative'))
        print(f"Normative vectors: {normative_count}")
        
        product_codes = set(v['product_code'] for v in self.vectors if v.get('product_code'))
        print(f"Product codes: {', '.join(product_codes)}")
        
        print(f"{'='*70}\n")


def main():
    if len(sys.argv) < 2:
        print("Usage: python ingest_vectors.py <test_vectors_dir> [db_connection_string]")
        print("\nIf db_connection_string is omitted, vectors will be extracted and exported to JSON only.")
        sys.exit(1)
    
    test_vectors_dir = Path(sys.argv[1])
    db_connection = sys.argv[2] if len(sys.argv) > 2 else None
    
    if not test_vectors_dir.is_dir():
        print(f"Error: Test vectors directory not found: {test_vectors_dir}")
        sys.exit(1)
    
    ingester = VectorIngester(db_connection)
    
    print(f"Ingesting test vectors from: {test_vectors_dir}\n")
    count = ingester.ingest_directory(test_vectors_dir)
    
    if count == 0:
        print("\n⚠️  No test vectors found")
        sys.exit(1)
    
    ingester.print_summary()
    
    # Export to JSON
    output_json = test_vectors_dir.parent / 'test-vectors-export.json'
    ingester.export_to_json(output_json)
    
    # Save to database if connection provided
    if db_connection:
        ingester.save_to_database()
    
    sys.exit(0)


if __name__ == '__main__':
    main()
