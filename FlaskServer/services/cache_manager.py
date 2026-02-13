"""
Cache Manager - LRU cache with TTL for query caching
"""

import time
from collections import OrderedDict
from typing import Any, Optional


class LRUCache:
    """LRU Cache with Time-To-Live (TTL) and automatic eviction"""
    
    def __init__(self, max_size: int = 500, ttl: int = 300):
        """
        Initialize LRU cache
        
        Args:
            max_size: Maximum number of items to cache
            ttl: Time to live in seconds
        """
        self.cache = OrderedDict()
        self.max_size = max_size
        self.ttl = ttl
    
    def get(self, key: str) -> Optional[Any]:
        """Get value from cache if it exists and hasn't expired"""
        if key not in self.cache:
            return None
        
        result, timestamp = self.cache[key]
        
        # Check if expired
        if time.time() - timestamp >= self.ttl:
            del self.cache[key]
            return None
        
        # Move to end (most recently used)
        self.cache.move_to_end(key)
        return result
    
    def put(self, key: str, value: Any):
        """Put value in cache, evicting oldest if necessary"""
        if key in self.cache:
            del self.cache[key]
        
        self.cache[key] = (value, time.time())
        
        # Evict oldest if over size limit
        if len(self.cache) > self.max_size:
            self.cache.popitem(last=False)
    
    def clear(self):
        """Clear all cached items"""
        self.cache.clear()
    
    def size(self) -> int:
        """Get current cache size"""
        return len(self.cache)
