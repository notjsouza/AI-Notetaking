from flask import Flask, jsonify, request

import nltk
from nltk.corpus import stopwords
from nltk.tokenize import word_tokenize

from llama_index.core import VectorStoreIndex, Document, Settings, StorageContext, load_index_from_storage

from openai import OpenAI

from dotenv import load_dotenv
import os

from typing import List
from functools import lru_cache
import time
from collections import OrderedDict

from apple_notes_reader import AppleNotesReader

app = Flask(__name__)

index = None
notes_reader = None

# Query cache with TTL and LRU eviction
class LRUCache:
    def __init__(self, max_size=500, ttl=300):
        self.cache = OrderedDict()
        self.max_size = max_size
        self.ttl = ttl
    
    def get(self, key):
        if key not in self.cache:
            return None
        result, timestamp = self.cache[key]
        if time.time() - timestamp >= self.ttl:
            del self.cache[key]
            return None
        # Move to end (most recently used)
        self.cache.move_to_end(key)
        return result
    
    def put(self, key, value):
        if key in self.cache:
            del self.cache[key]
        self.cache[key] = (value, time.time())
        # Evict oldest if over size limit
        if len(self.cache) > self.max_size:
            self.cache.popitem(last=False)
    
    def clear(self):
        self.cache.clear()

query_cache = LRUCache(max_size=500, ttl=300)

# ---------------------------------------------------------------------------------------------------------------------

# Apple Notes Configuration
load_dotenv()

INDEX_STORAGE_PATH = os.getenv('INDEX_STORAGE_PATH', './storage')
NOTES_DB_PATH = os.getenv('NOTES_DB_PATH', None)  # Optional: custom path to Notes database copy

# ---------------------------------------------------------------------------------------------------------------------

client = OpenAI()

# Initialize Apple Notes reader
try:
    notes_reader = AppleNotesReader(db_path=NOTES_DB_PATH)
    print("Apple Notes reader initialized successfully!")
except Exception as e:
    print(f"⚠️  Could not initialize Apple Notes reader: {e}")
    print("The server will start, but /initialize will fail until Notes access is granted.")

# Calling this to initialize an index with LlamaIndex using data from Apple Notes
@app.route('/initialize', methods=['POST'])
def initialize_index():
    global index, notes_reader
    
    if notes_reader is None:
        return jsonify({"error": "Apple Notes reader not initialized. Grant Full Disk Access and restart."}), 500
    
    # Try to load existing index from disk
    if os.path.exists(INDEX_STORAGE_PATH):
        try:
            storage_context = StorageContext.from_defaults(persist_dir=INDEX_STORAGE_PATH)
            index = load_index_from_storage(storage_context)
            return jsonify({"message": "Index loaded from disk successfully"})
        except Exception as e:
            print(f"Failed to load index from disk: {e}")
    
    # Build new index from Apple Notes
    try:
        apple_notes = notes_reader.get_all_notes()
        
        if not apple_notes:
            return jsonify({"message": "No notes found in Apple Notes"}), 404
        
        documents = []
        for note in apple_notes:
            documents.append(
                Document(
                    text=f"Title: {note.title}\nContent: {note.content}",
                    metadata={
                        "id": note.id,
                        "title": note.title,
                        "content": note.content,
                        "folder": note.folder,
                    }
                )
            )
        
        index = VectorStoreIndex(documents)
        # Persist to disk for faster loading next time
        index.storage_context.persist(persist_dir=INDEX_STORAGE_PATH)
        
        return jsonify({
            "message": f"Index initialized successfully with {len(apple_notes)} notes from Apple Notes",
            "note_count": len(apple_notes)
        })
        
    except Exception as e:
        return jsonify({"error": str(e)}), 500

# Searches the index for related database entries to the keyword passed through
@app.route('/search', methods=['POST'])
def search():
    global index, query_cache

    if index is None:
        return jsonify({"error": "Index not initialized"}), 400

    query = request.json.get('query')
    if not query:
        return jsonify({"error": "No query provided"}), 400
    
    # Check cache first
    cache_key = query.lower()
    cached_result = query_cache.get(cache_key)
    
    if cached_result is not None:
        return jsonify(cached_result)

    # Reduced from 10 to 3 for faster performance
    retriever = index.as_retriever(similarity_top_k=3)
    related_nodes: List[Document] = retriever.retrieve(query)

    # Lowered threshold for more matches and faster queries
    similarity_threshold = 0.70

    related_notes = []
    for node in related_nodes:
        if node.score >= similarity_threshold:
            related_notes.append({
                "id": node.metadata.get("id", ""),
                "title": node.metadata.get("title", ""),
                "content": node.get_content(),
            })
    
    result = {
        "query": query,
        "related_notes": related_notes
    }
    
    # Cache the result
    query_cache.put(cache_key, result)
    
    return jsonify(result)

# New batch search endpoint for better performance
@app.route('/search_batch', methods=['POST'])
def search_batch():
    global index, query_cache

    if index is None:
        return jsonify({"error": "Index not initialized"}), 400

    queries = request.json.get('queries', [])
    
    print(f"Batch search request - received {len(queries) if queries else 0} queries")
    
    if not queries:
        print("Error: No queries provided in request")
        return jsonify({"error": "No queries provided"}), 400
    
    results = {}
    queries_to_fetch = []
    
    # Check cache for all queries first
    for query in queries:
        cache_key = query.lower()
        cached_result = query_cache.get(cache_key)
        
        if cached_result is not None:
            results[query] = cached_result['related_notes']
        else:
            queries_to_fetch.append(query)
    
    # Batch query uncached items
    if queries_to_fetch:
        print(f"Cache miss for {len(queries_to_fetch)} queries - fetching from index")
        retriever = index.as_retriever(similarity_top_k=3)
        
        for query in queries_to_fetch:
            related_nodes = retriever.retrieve(query)
            
            related_notes = []
            for node in related_nodes:
                # Lowered threshold for more matches
                if node.score >= 0.70:
                    related_notes.append({
                        "id": node.metadata.get("id", ""),
                        "title": node.metadata.get("title", ""),
                        "content": node.get_content(),
                    })
            
            results[query] = related_notes
            # Cache each result
            query_cache.put(query.lower(), {"query": query, "related_notes": related_notes})
    
    print(f"Batch search returning results for {len(results)} queries ({len(queries) - len(queries_to_fetch)} from cache)")
    return jsonify(results)

# ---------------------------------------------------------------------------

# Filters the text input to remove all stopwords and duplicates
# Cache stopwords set for reuse
_stop_words = None

def get_stop_words():
    global _stop_words
    if _stop_words is None:
        _stop_words = set(stopwords.words('english'))
    return _stop_words

@app.route('/filter_text', methods=['POST'])
def filter_text():
    data = request.json
    if not data or 'text' not in data:
        return jsonify({"error": "No text provided"}), 400

    text = data['text']
    stop_words = get_stop_words()
    word_tokens = word_tokenize(text)

    filtered_words = []
    seen = set()

    for word in word_tokens:
        word_lower = word.lower()
        if (word_lower not in stop_words and
            word.isalnum() and
            not word.isdigit() and
            word_lower not in seen):
            filtered_words.append(word)
            seen.add(word_lower)

    return jsonify(filtered_words)

if __name__ == '__main__':
    print("\n" + "="*60)
    print("🚀 AI-Notetaking Flask Server")
    print("="*60)
    print("Apple Notes integration active")
    print("Server starting on http://127.0.0.1:5000")
    print("\nNext steps:")
    print("  1. Send POST to /initialize to build the index")
    print("  2. Start the Swift macOS app")
    print("="*60 + "\n")
    app.run(debug=True)
