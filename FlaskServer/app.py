
from flask import Flask, jsonify, request
import random
"""
from nltk.corpus import stopwords
from rake_nltk import Rake
"""

app = Flask(__name__)

notes = {
    "Chocolate Chip Cookies": {
        "title": "Chocolate Chip Cookies",
        "content": "Ingredients: Flour, sugar, butter, chocolate chips, eggs, vanilla extract, baking soda, salt.\nSteps: Cream butter and sugar, add eggs and vanilla, mix in dry ingredients, fold in chocolate chips. Bake at 350°F for 10-12 minutes."
    },
    "Banana Bread": {
        "title": "Banana Bread",
        "content": "Ingredients: Ripe bananas, flour, sugar, butter, eggs, baking soda, salt, vanilla extract.\nSteps: Mash bananas, mix in wet ingredients, combine with dry ingredients. Bake at 350°F for 60-70 minutes."
    },
    "Vanilla Cupcakes": {
        "title": "Vanilla Cupcakes",
        "content": "Ingredients: Flour, sugar, butter, eggs, vanilla extract, baking powder, milk.\nSteps: Cream butter and sugar, add eggs and vanilla, alternate adding dry ingredients and milk. Bake at 350°F for 18-20 minutes."
    },
    "Apple Pie": {
        "title": "Apple Pie",
        "content": "Ingredients: Apples, flour, sugar, butter, cinnamon, nutmeg, lemon juice, pie crust.\nSteps: Prepare crust, mix apple slices with sugar and spices, fill crust, add top crust, bake at 375°F for 50-60 minutes."
    },
    "Brownies": {
        "title": "Brownies",
        "content": "Ingredients: Flour, sugar, cocoa powder, butter, eggs, vanilla extract, baking powder, salt.\nSteps: Melt butter and mix with sugar and cocoa, add eggs and vanilla, fold in dry ingredients. Bake at 350°F for 25-30 minutes."
    },
    "German Shepherd": {
        "title": "German Shepherd",
        "content": "Origin: Germany\nHistory: Developed in the late 19th century, German Shepherds were initially bred for herding sheep. Their versatility and intelligence soon made them ideal working dogs for military and police work. The breed is known for its loyalty and protective nature."
    },
    "Beagle": {
        "title": "Beagle",
        "content": "Origin: England\nHistory: Beagles have a long history dating back to ancient Greece, but they were refined in England as hunting dogs for small game like rabbits. Their keen sense of smell and friendly demeanor have made them popular as both hunters and family pets."
    },
    "Golden Retriever": {
        "title": "Golden Retriever",
        "content": "Origin: Scotland\nHistory: Bred in the 19th century for retrieving game during hunting, Golden Retrievers are known for their friendly and tolerant attitude. Their intelligence and versatility have made them popular as guide dogs, therapy dogs, and search and rescue dogs."
    },
    "Siberian Husky": {
        "title": "Siberian Husky",
        "content": "Origin: Siberia, Russia\nHistory: Bred by the Chukchi people for sled pulling and companionship, Siberian Huskies are known for their endurance, friendly demeanor, and striking appearance. They were brought to Alaska during the gold rush and gained fame in sled dog racing."
    },
    "Shih Tzu": {
        "title": "Shih Tzu",
        "content": "Origin: China\nHistory: The Shih Tzu was bred as a companion dog for Chinese royalty, particularly during the Ming and Qing dynasties. Known for their luxurious coats and affectionate nature, Shih Tzus have been cherished as lap dogs for centuries."
    },
    "Mathematics": {
        "title": "Mathematics",
        "content": "Key Areas: Algebra, Geometry, Calculus, Statistics\nOverview: Mathematics involves the study of numbers, shapes, and patterns. It is a fundamental subject that develops critical thinking and problem-solving skills."
    },
    "English": {
        "title": "English",
        "content": "Key Areas: Poetry, Prose, Drama\nOverview: English Literature explores various literary works from different periods, focusing on themes, character development, and linguistic style. It encourages analysis and interpretation."
    },
    "Biology": {
        "title": "Biology",
        "content": "Key Areas: Cell Biology, Genetics, Ecology, Human Anatomy\nOverview: Biology is the study of living organisms, their structure, function, growth, and evolution. It includes understanding the complex interactions within ecosystems."
    },
    "History": {
        "title": "History",
        "content": "Key Areas: Ancient Civilizations, World Wars, Modern History\nOverview: History involves the study of past events, societies, and cultures. It helps us understand the development of the world and learn from past experiences."
    },
    "Physics": {
        "title": "Physics",
        "content": "Key Areas: Mechanics, Electromagnetism, Thermodynamics, Quantum Physics\nOverview: Physics is the study of matter, energy, and the fundamental forces of nature. It explains natural phenomena through laws and theories."
    },
    "Chemistry": {
        "title": "Chemistry",
        "content": "Key Areas: Organic Chemistry, Inorganic Chemistry, Biochemistry, Physical Chemistry\nOverview: Chemistry involves the study of substances, their properties, reactions, and the changes they undergo. It bridges physical sciences with biology and medicine."
    }
}

"""
# Initialize Rake with stopwords
r = Rake(stopwords=stopwords.words('english'))

def extract_keywords(text):
    r.extract_keywords_from_text(text)
    return r.get_ranked_phrases()

# Example usage
content = notes["Chocolate Chip Cookies"]["content"]
keywords = extract_keywords(content)
print(keywords)  # ['add eggs', 'baking soda', 'chocolate chips', ...]
"""

@app.route('/check_word', methods=['POST'])
def check_word():
    data = request.json
    word = data.get('word', '').lower()

    relevant_words = ["flask", "button", "text", "database", "chatgpt", "logic", "swift", "python", "backend"]

    is_relevant = word in relevant_words

    return jsonify({"is_relevant": is_relevant})

@app.route('/get_note', methods=['POST'])
def get_note():

    data = request.json
    word = data.get('word')

    # #keyWords = ["flask", "button", "text", "database", "chatgpt", "logic", "swift", "similar", "python", "backend"]

    note = random.choice(list(notes.values()))
    res = {
        "title": note['title'],
        "content": note['content']
    }

    return jsonify(res)

if __name__ == '__main__':
    app.run(debug=True)
