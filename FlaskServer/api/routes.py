"""
API Routes - Flask route handlers
"""

from flask import request, jsonify
import nltk
from nltk.corpus import stopwords
from nltk.tokenize import word_tokenize

# Singleton for stopwords
_stop_words = None

def get_stop_words():
    """Get cached stopwords set"""
    global _stop_words
    if _stop_words is None:
        nltk.download('stopwords', quiet=True)
        nltk.download('punkt', quiet=True)
        _stop_words = set(stopwords.words('english'))
    return _stop_words


def register_routes(app, search_service, notes_reader, query_cache):
    """Register all Flask routes"""
    
    @app.route('/initialize', methods=['POST'])
    def initialize_index():
        """Initialize the LlamaIndex vector index with notes"""
        if notes_reader is None:
            return jsonify({"error": "Apple Notes reader not initialized. Grant Full Disk Access and restart."}), 500
        
        try:
            apple_notes = notes_reader.get_all_notes()
            
            if not apple_notes:
                return jsonify({"message": "No notes found in Apple Notes"}), 404
            
            message = search_service.initialize_index(apple_notes)
            
            return jsonify({
                "message": message,
                "note_count": len(apple_notes)
            })
            
        except Exception as e:
            return jsonify({"error": str(e)}), 500
    
    @app.route('/search', methods=['POST'])
    def search():
        """Search for notes related to a query"""
        query = request.json.get('query')
        if not query:
            return jsonify({"error": "No query provided"}), 400
        
        # Check cache first
        cache_key = query.lower()
        cached_result = query_cache.get(cache_key)
        
        if cached_result is not None:
            return jsonify(cached_result)
        
        try:
            related_notes = search_service.search_single(query)
            
            result = {
                "query": query,
                "related_notes": related_notes
            }
            
            # Cache the result
            query_cache.put(cache_key, result)
            
            return jsonify(result)
            
        except Exception as e:
            return jsonify({"error": str(e)}), 500
    
    @app.route('/search_batch', methods=['POST'])
    def search_batch():
        """Search for notes related to multiple queries (batch)"""
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
        
        # Fetch uncached items
        if queries_to_fetch:
            print(f"Cache miss for {len(queries_to_fetch)} queries - fetching from index")
            
            try:
                batch_results = search_service.search_batch(queries_to_fetch)
                
                for query, related_notes in batch_results.items():
                    results[query] = related_notes
                    # Cache each result
                    query_cache.put(query.lower(), {"query": query, "related_notes": related_notes})
                    
            except Exception as e:
                return jsonify({"error": str(e)}), 500
        
        print(f"Batch search returning results for {len(results)} queries ({len(queries) - len(queries_to_fetch)} from cache)")
        return jsonify(results)
    
    @app.route('/filter_text', methods=['POST'])
    def filter_text():
        """Filter text to remove stopwords and duplicates"""
        text = request.json.get('text')
        if not text:
            return jsonify({"error": "No text provided"}), 400
        
        try:
            stop_words = get_stop_words()
            
            # Tokenize and filter
            words = word_tokenize(text.lower())
            filtered = [word for word in words if word.isalnum() and word not in stop_words and len(word) > 2]
            
            # Remove duplicates while preserving order
            seen = set()
            unique_filtered = []
            for word in filtered:
                if word not in seen:
                    seen.add(word)
                    unique_filtered.append(word)
            
            return jsonify({"filtered_words": unique_filtered})
            
        except Exception as e:
            return jsonify({"error": str(e)}), 500
    
    @app.route('/health', methods=['GET'])
    def health():
        """Health check endpoint"""
        return jsonify({
            "status": "healthy",
            "index_initialized": search_service.index is not None,
            "cache_size": query_cache.size()
        })
