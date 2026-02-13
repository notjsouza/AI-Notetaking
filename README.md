# AI-Notetaking

An intelligent macOS application that helps you rediscover your notes by scanning your screen and suggesting relevant notes based on what you're reading.

## YouTube Demo

[![Demo Video](https://img.youtube.com/vi/qSGGgYjDJxc/0.jpg)](https://www.youtube.com/watch?v=qSGGgYjDJxc)

## Overview

This application uses macOS Accessibility APIs to read text from your active window and uses LlamaIndex with vector similarity search to find relevant notes from Apple Notes. When you hover over highlighted words, it shows suggestions from your note collection.

## Setup

### Prerequisites
- macOS with Accessibility permissions
- Python 3.8+
- Xcode (for Swift app)
- Apple Notes with some notes in it

### Backend Setup

1. **Install Python dependencies**
   ```bash
   cd FlaskServer
   pip install -r requirements.txt
   ```

2. **Run setup script**
   ```bash
   python setup.py
   ```

3. **Grant Full Disk Access** (Required to read Apple Notes)
   - System Settings → Privacy & Security → Full Disk Access
   - Add Terminal to the list
   - Restart Terminal

4. **Configure environment** (optional)
   ```bash
   cp .env.example .env
   # Edit .env if needed (most settings have good defaults)
   ```

5. **Start Flask server**
   ```bash
   python app.py
   ```

### Frontend Setup

1. **Open Xcode project**
   ```bash
   open CurrentWindow.xcodeproj
   ```

2. **Enable Accessibility**
   - System Preferences → Security & Privacy → Privacy → Accessibility
   - Add your app when prompted

3. **Build and Run** (⌘R)