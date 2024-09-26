from crypt import methods
from importlib.metadata import metadata

from flask import Flask, jsonify, request

import nltk
nltk.download('punkt_tab')
from nltk.corpus import stopwords
from nltk.tokenize import word_tokenize

from llama_index.core import VectorStoreIndex, Document, Settings

from pymongo import MongoClient
from pymongo.server_api import ServerApi

from openai import OpenAI

from dotenv import load_dotenv

from typing import List

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

try:
    clientDB.admin.command('ping')
    print("Pinged your deployment. You successfully connected to MongoDB!")
except Exception as e:
    print(e)

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
                        "content": content,
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

    similarity_threshold = 0.75

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

@app.route('/filter_text', methods=['POST'])
def filter_text():
    data = request.json
    if not data or 'text' not in data:
        return jsonify({"error": "No text provided"}), 400

    text = data['text']
    stop_words = set(stopwords.words('english'))
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
    app.run(debug=True)
    initialize_index()
