"""
Search Service - Handles LlamaIndex operations and note searching
"""

import os
from typing import List, Dict
from llama_index.core import VectorStoreIndex, Document, StorageContext, load_index_from_storage


class SearchService:
    """Service for searching notes using LlamaIndex vector embeddings"""
    
    def __init__(self, index_storage_path: str = './storage'):
        self.index_storage_path = index_storage_path
        self.index = None
    
    def initialize_index(self, notes: List) -> str:
        """Initialize or load the LlamaIndex vector index"""
        
        # Try to load existing index from disk
        if os.path.exists(self.index_storage_path):
            try:
                storage_context = StorageContext.from_defaults(persist_dir=self.index_storage_path)
                self.index = load_index_from_storage(storage_context)
                return "Index loaded from disk successfully"
            except Exception as e:
                print(f"Failed to load index from disk: {e}")
        
        # Build new index from notes
        if not notes:
            raise ValueError("No notes provided to build index")
        
        documents = []
        for note in notes:
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
        
        self.index = VectorStoreIndex(documents)
        # Persist to disk for faster loading next time
        self.index.storage_context.persist(persist_dir=self.index_storage_path)
        
        return f"Index initialized successfully with {len(notes)} notes"
    
    def search_single(self, query: str, similarity_top_k: int = 3, threshold: float = 0.70) -> List[Dict]:
        """Search for notes related to a single query"""
        
        if not self.index:
            raise RuntimeError("Index not initialized")
        
        retriever = self.index.as_retriever(similarity_top_k=similarity_top_k)
        related_nodes = retriever.retrieve(query)
        
        related_notes = []
        for node in related_nodes:
            if node.score >= threshold:
                related_notes.append({
                    "id": node.metadata.get("id", ""),
                    "title": node.metadata.get("title", ""),
                    "content": node.get_content(),
                })
        
        return related_notes
    
    def search_batch(self, queries: List[str], similarity_top_k: int = 3, threshold: float = 0.70) -> Dict[str, List[Dict]]:
        """Search for notes related to multiple queries (batch operation)"""
        
        if not self.index:
            raise RuntimeError("Index not initialized")
        
        retriever = self.index.as_retriever(similarity_top_k=similarity_top_k)
        
        results = {}
        for query in queries:
            related_nodes = retriever.retrieve(query)
            
            related_notes = []
            for node in related_nodes:
                if node.score >= threshold:
                    related_notes.append({
                        "id": node.metadata.get("id", ""),
                        "title": node.metadata.get("title", ""),
                        "content": node.get_content(),
                    })
            
            results[query] = related_notes
        
        return results
