"""
Flask Server - Smart Notes Overlay Backend
Main application entry point using modular services
"""

from flask import Flask
from dotenv import load_dotenv
import os

from services.cache_manager import LRUCache
from services.search_service import SearchService
from services.notes_reader import AppleNotesReader
from api.routes import register_routes

# Load environment variables
load_dotenv()

# Configuration
INDEX_STORAGE_PATH = os.getenv('INDEX_STORAGE_PATH', './storage')
NOTES_DB_PATH = os.getenv('NOTES_DB_PATH', None)  # Optional: custom path to Notes database copy

# Initialize Flask app
app = Flask(__name__)

# Initialize services
query_cache = LRUCache(max_size=500, ttl=300)
search_service = SearchService(index_storage_path=INDEX_STORAGE_PATH)

# Initialize Apple Notes reader
notes_reader = None
try:
    notes_reader = AppleNotesReader(db_path=NOTES_DB_PATH)
    print("Apple Notes reader initialized successfully!")
except Exception as e:
    print(f"Could not initialize Apple Notes reader: {e}")
    print("The server will start, but /initialize will fail until Notes access is granted.")

# Register all API routes
register_routes(app, search_service, notes_reader, query_cache)

if __name__ == '__main__':
    print("\n" + "="*60)
    print("Overlay Server Starting")
    print("="*60)
    print(f"Index storage path: {INDEX_STORAGE_PATH}")
    if notes_reader:
        print(f"Apple Notes reader: Ready")
    else:
        print(f"Apple Notes reader: Not initialized")
    print("="*60 + "\n")
    
    app.run(debug=True, port=5000)
