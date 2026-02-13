#!/usr/bin/env python3
"""
Setup script for AI-Notetaking Flask server.
Downloads required NLTK data packages.
"""

import nltk
import os

def setup_nltk():
    """Download required NLTK packages"""
    print("Downloading required NLTK packages...")
    packages = ['punkt_tab', 'stopwords']
    
    all_success = True
    for package in packages:
        try:
            result = nltk.download(package, quiet=False)
            if result:
                print(f"Successfully downloaded {package}")
            else:
                print(f"Failed to download {package}")
                all_success = False
        except Exception as e:
            print(f"Failed to download {package}: {e}")
            all_success = False
    
    if not all_success:
        print("\nSSL CERTIFICATE ERROR DETECTED")
        print("\nThis is a common macOS issue. Try one of these fixes:")
        print("\n1. Install Python SSL certificates (RECOMMENDED):")
        print("Run this command from your Python installation:")
        import sys
        cert_path = f"/Applications/Python {sys.version_info.major}.{sys.version_info.minor}/Install Certificates.command"
        print(f"{cert_path}")
        print("OR run:")
        print(f"open '{cert_path}'")
        print("\n2. Use pip to install certifi:")
        print("pip install --upgrade certifi")
        print("\n3. Manual download:")
        print("python -m nltk.downloader -d ~/nltk_data punkt_tab stopwords")
        print("\nAfter fixing, run this setup script again.")
        return False
    
    print("\nAll NLTK packages downloaded successfully!")
    return True

def create_storage_dir():
    """Create storage directory for index persistence"""
    storage_path = os.getenv('INDEX_STORAGE_PATH', './storage')
    if not os.path.exists(storage_path):
        os.makedirs(storage_path)
        print(f"Created storage directory: {storage_path}")
    else:
        print(f"Storage directory already exists: {storage_path}")

if __name__ == '__main__':
    print("Setting up AI-Notetaking Flask server...\n")
    nltk_success = setup_nltk()
    create_storage_dir()
    
    if not nltk_success:
        print("\nSetup incomplete - please fix NLTK download issues above")
        exit(1)
    else:
        print("\nSetup complete! You can now run: python app.py")
