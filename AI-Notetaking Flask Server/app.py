
from flask import Flask, request, jsonify
import random

app = Flask(__name__)

notes = {
    "Chocolate Chip Cookies": """
    **Chocolate Chip Cookies**
    **Chocolate Chip Cookies**
    **Ingredients:** Flour, sugar, butter, chocolate chips, eggs, vanilla extract, baking soda, salt.
    **Steps:** Cream butter and sugar, add eggs and vanilla, mix in dry ingredients, fold in chocolate chips. Bake at 350°F for 10-12 minutes.
    """,
    "Banana Bread":"""
    **Banana Bread**
    **Ingredients:** Ripe bananas, flour, sugar, butter, eggs, baking soda, salt, vanilla extract.
    **Steps:** Mash bananas, mix in wet ingredients, combine with dry ingredients. Bake at 350°F for 60-70 minutes.
    """,
    "Vanilla Cupcakes": """
    **Vanilla Cupcakes**
    **Ingredients:** Flour, sugar, butter, eggs, vanilla extract, baking powder, milk.
    **Steps:** Cream butter and sugar, add eggs and vanilla, alternate adding dry ingredients and milk. Bake at 350°F for 18-20 minutes.
    """,
    "Apple Pie": """
    **Apple Pie**
    **Ingredients:** Apples, flour, sugar, butter, cinnamon, nutmeg, lemon juice, pie crust.
    **Steps:** Prepare crust, mix apple slices with sugar and spices, fill crust, add top crust, bake at 375°F for 50-60 minutes.
    """,
    "Brownies": """
    **Brownies**
    **Ingredients:** Flour, sugar, cocoa powder, butter, eggs, vanilla extract, baking powder, salt.
    **Steps:** Melt butter and mix with sugar and cocoa, add eggs and vanilla, fold in dry ingredients. Bake at 350°F for 25-30 minutes.
    """,
    "German Shepherd": """
    **German Shepherd**
    **Origin:** Germany
    **History:** Developed in the late 19th century, German Shepherds were initially bred for herding sheep. Their versatility and intelligence soon made them ideal working dogs for military and police work. The breed is known for its loyalty and protective nature.
    """,
    "Beagle": """
    **Beagle**
    **Origin:** England
    **History:** Beagles have a long history dating back to ancient Greece, but they were refined in England as hunting dogs for small game like rabbits. Their keen sense of smell and friendly demeanor have made them popular as both hunters and family pets.
    """,
    "Golden Retriever": """
    **Golden Retriever**
    **Origin:** Scotland
    **History:** Bred in the 19th century for retrieving game during hunting, Golden Retrievers are known for their friendly and tolerant attitude. Their intelligence and versatility have made them popular as guide dogs, therapy dogs, and search and rescue dogs.
    """,
    "Siberian Husky": """
    **Siberian Husky**
    **Origin:** Siberia, Russia
    **History:** Bred by the Chukchi people for sled pulling and companionship, Siberian Huskies are known for their endurance, friendly demeanor, and striking appearance. They were brought to Alaska during the gold rush and gained fame in sled dog racing.
    """,
    "Shih Tzu": """
    **Shih Tzu**
    **Origin:** China
    **History:** The Shih Tzu was bred as a companion dog for Chinese royalty, particularly during the Ming and Qing dynasties. Known for their luxurious coats and affectionate nature, Shih Tzus have been cherished as lap dogs for centuries."
    """,
    "Mathematics": """
    **Mathematics**
    **Key Areas:** Algebra, Geometry, Calculus, Statistics
    **Overview:** Mathematics involves the study of numbers, shapes, and patterns. It is a fundamental subject that develops critical thinking and problem-solving skills.
    """,
    "English": """
    **English**
    **Key Areas:** Poetry, Prose, Drama
    **Overview:** English Literature explores various literary works from different periods, focusing on themes, character development, and linguistic style. It encourages analysis and interpretation.
    """,
    "Biology": """
    **Biology**
    **Key Areas:** Cell Biology, Genetics, Ecology, Human Anatomy
    **Overview:** Biology is the study of living organisms, their structure, function, growth, and evolution. It includes understanding the complex interactions within ecosystems.
    """,
    "History": """
    **History**
    **Key Areas:** Ancient Civilizations, World Wars, Modern History
    **Overview:** History involves the study of past events, societies, and cultures. It helps us understand the development of the world and learn from past experiences.
    """,
    "Physics": """
    **Physics**
    **Key Areas:** Mechanics, Electromagnetism, Thermodynamics, Quantum Physics
    **Overview:** Physics is the study of matter, energy, and the fundamental forces of nature. It explains natural phenomena through laws and theories.
    """,
    "Chemistry": """
    **Chemistry**
    **Key Areas:** Organic Chemistry, Inorganic Chemistry, Biochemistry, Physical Chemistry
    **Overview:** Chemistry involves the study of substances, their properties, reactions, and the changes they undergo. It bridges physical sciences with biology and medicine.
    """
}

@app.route('/get_note', methods=['POST'])
def get_note():
    data = request.json
    hoveredWord = data.get('word', ' ')

    randomNote = random.choice(list(notes.values()))

    return jsonify({"note": randomNote})

if __name__ == '__main__':
    app.run(debug=True)
