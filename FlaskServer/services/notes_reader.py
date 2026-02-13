"""
Apple Notes Reader
Reads notes from the macOS Apple Notes SQLite database.
"""

import sqlite3
import os
import shutil
import tempfile
from pathlib import Path
from typing import List, Dict, Optional
import logging

logger = logging.getLogger(__name__)

# Apple Notes database location
NOTES_DB_PATH = os.path.expanduser(
    "~/Library/Group Containers/group.com.apple.notes/NoteStore.sqlite"
)


class AppleNote:
    """Represents a single Apple Note"""
    
    def __init__(self, note_id: str, title: str, content: str, folder: str = ""):
        self.id = note_id
        self.title = title
        self.content = content
        self.folder = folder
    
    def __repr__(self):
        return f"AppleNote(id={self.id}, title={self.title[:30]}...)"


class AppleNotesReader:
    """Reader for Apple Notes database"""
    
    def __init__(self, db_path: Optional[str] = None, use_copy: bool = True):
        self.db_path = db_path or NOTES_DB_PATH
        self.use_copy = use_copy
        self.working_db_path = self.db_path
        
        if use_copy:
            self._create_working_copy()
        else:
            self._verify_access()
    
    def _create_working_copy(self):
        """Create a working copy of the database to avoid permission issues"""
        try:
            import shutil
            import tempfile
            
            # Create temp directory for the copy
            temp_dir = Path(tempfile.gettempdir()) / "apple_notes_copy"
            temp_dir.mkdir(exist_ok=True)
            
            self.working_db_path = str(temp_dir / "NoteStore.sqlite")
            
            # Copy the database if source exists and is readable
            if os.path.exists(self.db_path):
                try:
                    shutil.copy2(self.db_path, self.working_db_path)
                    logger.info(f"Created working copy at {self.working_db_path}")
                except (PermissionError, OSError) as e:
                    logger.warning(f"Could not copy database: {e}")
                    # Try to use original path
                    self.working_db_path = self.db_path
                    self._verify_access()
            else:
                raise FileNotFoundError(f"Apple Notes database not found at {self.db_path}")
                
        except Exception as e:
            logger.error(f"Error creating working copy: {e}")
            self.working_db_path = self.db_path
            self._verify_access()
    
    def _verify_access(self):
        """Check if we can access the Notes database"""
        if not os.path.exists(self.working_db_path):
            raise FileNotFoundError(
                f"Apple Notes database not found at {self.working_db_path}. "
                "Make sure Apple Notes is installed and has been used."
            )
        
        # Try to open the database
        try:
            conn = sqlite3.connect(self.working_db_path)
            conn.close()
        except sqlite3.Error as e:
            raise PermissionError(
                f"Cannot access Apple Notes database. Error: {e}\n\n"
                "You need to grant Full Disk Access permission:\n"
                "1. System Settings → Privacy & Security → Full Disk Access\n"
                "2. Add Terminal (or your IDE) to the list\n"
                "3. Restart Terminal/IDE and try again"
            )
    
    def get_all_notes(self) -> List[AppleNote]:
        """
        Retrieve all notes from Apple Notes database.
        
        Returns:
            List of AppleNote objects
        """
        notes = []
        
        try:
            conn = sqlite3.connect(self.working_db_path)
            cursor = conn.cursor()
            
            # Query to get notes with their content
            # Apple Notes stores data in a complex structure with protobuf in ZICNOTEDATA
            # We use ZSNIPPET and ZSTANDARDIZEDCONTENT for text content
            # ZIDENTIFIER contains the UUID needed for the notes:// URL scheme
            query = """
                SELECT 
                    n.ZIDENTIFIER as note_id,
                    n.ZTITLE1 as title,
                    n.ZSNIPPET as snippet,
                    n.ZSTANDARDIZEDCONTENT as standardized_content,
                    f.ZTITLE2 as folder
                FROM ZICCLOUDSYNCINGOBJECT n
                LEFT JOIN ZICCLOUDSYNCINGOBJECT f ON n.ZFOLDER = f.Z_PK
                WHERE n.ZTITLE1 IS NOT NULL
                    AND n.ZMARKEDFORDELETION = 0
                    AND (n.ZSTANDARDIZEDCONTENT IS NOT NULL OR n.ZSNIPPET IS NOT NULL)
                ORDER BY n.ZMODIFICATIONDATE1 DESC
            """
            
            cursor.execute(query)
            rows = cursor.fetchall()
            
            for row in rows:
                note_id, title, snippet, standardized_content, folder = row
                
                # Use standardized_content if available, otherwise use snippet
                content = standardized_content if standardized_content else (snippet if snippet else "")
                
                # Clean up the content
                content = self._clean_content(content)
                title = title or "(Untitled)"
                
                if content and note_id:  # Only include notes with content and valid ID
                    notes.append(AppleNote(
                        note_id=str(note_id) if note_id else "",
                        title=title,
                        content=content,
                        folder=folder or "Notes"
                    ))
            
            conn.close()
            logger.info(f"Successfully loaded {len(notes)} notes from Apple Notes")
            
        except sqlite3.Error as e:
            logger.error(f"Database error: {e}")
            raise
        
        return notes
    
    def _clean_content(self, content: str) -> str:
        """Clean up note content by removing special characters and normalizing"""
        if not content:
            return ""
        
        # Remove null bytes and other problematic characters
        content = content.replace('\x00', '')
        
        # Normalize whitespace
        content = ' '.join(content.split())
        
        return content.strip()
    
    def get_note_by_id(self, note_id: str) -> Optional[AppleNote]:
        """Get a specific note by ID"""
        notes = self.get_all_notes()
        for note in notes:
            if note.id == note_id:
                return note
        return None
    
    def search_notes(self, query: str) -> List[AppleNote]:
        """Simple text search through notes"""
        notes = self.get_all_notes()
        query_lower = query.lower()
        
        return [
            note for note in notes
            if query_lower in note.title.lower() or query_lower in note.content.lower()
        ]


def test_reader():
    """Test the Apple Notes reader"""
    try:
        reader = AppleNotesReader()
        notes = reader.get_all_notes()
        
        print(f"\nSuccessfully loaded {len(notes)} notes from Apple Notes\n")
        
        # Show first few notes
        for i, note in enumerate(notes[:5], 1):
            print(f"{i}. {note.title}")
            print(f"   Folder: {note.folder}")
            print(f"   Content preview: {note.content[:100]}...")
            print()
        
        return True
    except Exception as e:
        print(f"\n✗ Error: {e}\n")
        return False


if __name__ == '__main__':
    # Run test
    logging.basicConfig(level=logging.INFO)
    test_reader()
