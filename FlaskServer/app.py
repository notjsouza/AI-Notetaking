from crypt import methods
from importlib.metadata import metadata

from flask import Flask, jsonify, request

from llama_index.core import VectorStoreIndex, Document, Settings

from pymongo import MongoClient
from pymongo.server_api import ServerApi

from openai import OpenAI

from dotenv import load_dotenv

from typing import List

import os

app = Flask(__name__)

index = None

uri = "mongodb+srv://notjsouza:YwtaMupVNB9PC6jd@overlay.l1yzd.mongodb.net/?retryWrites=true&w=majority&appName=Overlay"
DATABASE_NAME = 'test_notes'
COLLECTION_NAME = 'test_notes'

load_dotenv()
client = OpenAI()

clientDB = MongoClient(uri, server_api=ServerApi('1'))
db = clientDB[DATABASE_NAME]
collection = db[COLLECTION_NAME]

@app.route('/initialize', methods=['POST'])
def initialize_index():
    global index

    notes = []
    for note in collection.find():

        title = note.get('title', '')
        content = note.get('content', '')

        if content:
            notes.append(
                Document(
                    text="Title: " + title + "\nContent: " + content,
                    metadata={
                        "title": title,
                        "content": content
                    }
                )
            )

    if notes:
        index = VectorStoreIndex(notes)
        return jsonify({"message": "Index initialized successfully"})
    else:
        return jsonify({"message": "No documents found to initialize index"})

@app.route('/search', methods=['POST'])
def search():
    global index

    if index is None:
        return jsonify({"error": "Index not initialized"}), 400

    query = request.json.get('query')
    if not query:
        return jsonify({"error": "No query provided"}), 400

    retriever = index.as_retriever(similarity_top_k=10)
    related_nodes: List[Document] = retriever.retrieve(query)

    similarity_threshold = 0.7

    related_notes = []
    for node in related_nodes:
        if node.score >= similarity_threshold:
            related_notes.append({
                "title": node.metadata.get("title", ""),
                "content": node.get_content(),
            })

    return jsonify({
        "query": query,
        "related_notes": related_notes
    })

# ---------------------------------------------------------------------------

# Function to extract keywords from text contents through a GPT call
def extract_keywords(text):
    try:
        response = client.chat.completions.create(model="gpt-3.5-turbo",
        messages=[
            {"role": "system", "content": "You are a helpful assistant that extracts keywords from text."},
            {"role": "user", "content": f"Extract the main keywords from the following text: {text}"}
        ],
        max_tokens=100)

        keywords = response.choices[0].message.content.strip()
        return keywords
    except Exception as e:
        print(f"An error occurred: {e}")
        return []

# Returns all notes from the MongoDB database
@app.route('/api/notes', methods=['GET'])
def get_all_notes():
    cursor = collection.find()

    # Convert MongoDB ObjectId to string and prepare the notes for JSON response
    notes = []
    for note in cursor:
        note['_id'] = str(note['_id'])  # Convert ObjectId to string
        notes.append({
            'id': note['_id'],  # Use '_id' as the UUID string in Swift
            'title': note['title'],
            'content': note['content'],
            'keywords': note['keywords']
        })

    return jsonify(notes)

@app.route('/get_notes', methods=['GET'])
def get_notes():
    notes = list(collection.find())
    return jsonify(notes)

if __name__ == '__main__':
    app.run(debug=True)
    initialize_index()
