#!/usr/bin/env python3
"""
Generate JSON file with all 720 sentences for audio batch generation.
"""

import json

# Word bank from WordBankService.swift
WORD_BANK = {
    1: ["cat", "dog", "sun", "run", "big", "red", "hat", "sit", "cup", "bed",
        "mom", "dad", "pet", "fun", "hot", "top", "box", "fox", "yes", "bus"],
    2: ["ball", "tree", "book", "fish", "bird", "cake", "play", "jump", "swim", "blue",
        "green", "happy", "water", "apple", "house", "mouse", "sleep", "dream", "smile", "light"],
    3: ["friend", "school", "write", "plant", "cloud", "train", "beach", "clean", "bring", "thing",
        "laugh", "watch", "catch", "match", "patch", "lunch", "bench", "branch", "crunch", "french"],
    4: ["beautiful", "different", "important", "together", "remember", "between", "another", "through", "thought", "brought",
        "daughter", "neighbor", "weight", "height", "straight", "caught", "taught", "bought", "fought", "sought"],
    5: ["character", "paragraph", "adventure", "attention", "celebrate", "community", "continue", "describe", "discover", "education",
        "especially", "experience", "favorite", "government", "important", "interested", "knowledge", "literature", "necessary", "particular"],
    6: ["accomplish", "throughout", "appreciate", "atmosphere", "boundaries", "challenge", "commercial", "competition", "concentrate", "conscience",
        "consequence", "consistent", "demonstrate", "development", "environment", "essentially", "exaggerate", "explanation", "extraordinary", "fascinating"],
    7: ["accommodate", "achievement", "acknowledge", "acquaintance", "advertisement", "anniversary", "anticipation", "appreciation", "approximately", "archaeological",
        "argumentative", "autobiography", "bibliography", "characteristic", "chronological", "circumstances", "classification", "collaboration", "commemorate", "communication"],
    8: ["abbreviation", "acceleration", "accessibility", "accomplishment", "accountability", "acknowledgement", "administration", "alphabetically", "announcements", "archaeological",
        "assassination", "authentication", "autobiography", "biodegradable", "characteristics", "circumference", "classification", "commercialize", "communication", "comprehensive"],
    9: ["accommodation", "accomplishment", "acknowledgment", "administration", "alphabetically", "announcements", "approximately", "archaeological", "authentication", "autobiography",
        "biodegradable", "characteristics", "chronological", "circumference", "classification", "collaboration", "commercialize", "communication", "comprehensive", "confederation"],
    10: ["conscientious", "correspondence", "discrimination", "electromagnetic", "entrepreneurial", "environmental", "fundamentalism", "hallucination", "hospitalization", "hypothetically",
         "identification", "implementation", "impressionable", "incomprehensible", "individualism", "industrialization", "infrastructure", "institutionalize", "instrumentation", "intellectualism"],
    11: ["acknowledgeable", "characterization", "circumstantial", "commercialization", "compartmentalize", "comprehensibility", "conceptualization", "confidentiality", "congratulations", "conscientiously",
         "constitutionality", "contemporaneous", "conventionalize", "correspondence", "counterproductive", "crystallization", "decentralization", "demilitarization", "democratization", "departmentalize"],
    12: ["autobiographical", "characteristically", "compartmentalization", "comprehensively", "conceptualization", "confidentiality", "congratulatory", "conscientiously", "constitutionally", "contemporaneously",
         "conventionally", "correspondingly", "counterproductively", "crystallographic", "decentralization", "demilitarization", "democratization", "departmentalization", "deterministically", "developmentally"]
}

# Sentence templates for different difficulty levels
SENTENCE_TEMPLATES = {
    # Difficulty 1-2: Simple, short sentences
    "simple": [
        "The {word} is {adjective}.",
        "I {verb} the {word}.",
        "{Noun} has a {word}."
    ],
    # Difficulty 3-5: Moderate complexity
    "moderate": [
        "The {word} was very {adjective} yesterday.",
        "We learned about {word} in class today.",
        "My teacher explained what {word} means."
    ],
    # Difficulty 6-8: More complex
    "complex": [
        "The concept of {word} is important to understand.",
        "Scientists study {word} to learn more about the world.",
        "Understanding {word} helps us solve problems."
    ],
    # Difficulty 9-12: Advanced
    "advanced": [
        "The professor discussed {word} during the lecture.",
        "Researchers are investigating {word} in their latest study.",
        "The article examined {word} from multiple perspectives."
    ]
}

def create_simple_sentences(word):
    """Create 3 simple sentences for difficulty 1-2 words."""
    sentences = {
        # Difficulty 1 words
        "cat": [
            "The cat is sleeping on the couch.",
            "I saw a black cat in the garden.",
            "My cat loves to play with yarn."
        ],
        "dog": [
            "The dog barked at the mailman.",
            "My dog likes to fetch the ball.",
            "The brown dog wagged its tail."
        ],
        "sun": [
            "The sun is shining brightly today.",
            "We love playing in the sun.",
            "The sun rises in the morning."
        ],
        "run": [
            "I can run very fast.",
            "Let's run to the park together.",
            "The children run around the playground."
        ],
        "big": [
            "That is a big elephant.",
            "My brother wears big shoes.",
            "We live in a big house."
        ],
        "red": [
            "I have a red crayon.",
            "The apple is bright red.",
            "She wore a red dress today."
        ],
        "hat": [
            "I wear a hat when it's cold.",
            "The blue hat looks nice.",
            "Dad forgot his hat at home."
        ],
        "sit": [
            "Please sit down on the chair.",
            "We sit together at lunch.",
            "The dog will sit when you ask."
        ],
        "cup": [
            "I drink water from a cup.",
            "The cup is on the table.",
            "Mom filled the cup with juice."
        ],
        "bed": [
            "I sleep in my bed at night.",
            "The bed has soft pillows.",
            "Time to go to bed now."
        ],
        "mom": [
            "My mom makes the best cookies.",
            "Mom reads me stories at bedtime.",
            "I love my mom very much."
        ],
        "dad": [
            "Dad drives us to school.",
            "My dad is very tall.",
            "Dad helps me with my homework."
        ],
        "pet": [
            "I have a pet hamster.",
            "We take care of our pet every day.",
            "My pet likes to eat carrots."
        ],
        "fun": [
            "Playing games is so much fun.",
            "We had fun at the park today.",
            "Birthday parties are always fun."
        ],
        "hot": [
            "The soup is very hot.",
            "It feels hot outside today.",
            "Be careful, the stove is hot."
        ],
        "top": [
            "The book is on top of the desk.",
            "I climbed to the top of the hill.",
            "The toy is on the top shelf."
        ],
        "box": [
            "I put my toys in a box.",
            "The box is full of books.",
            "Can you open the box for me?"
        ],
        "fox": [
            "The fox has a bushy tail.",
            "We saw a red fox in the woods.",
            "The fox ran across the field."
        ],
        "yes": [
            "Yes, I would like some ice cream.",
            "She said yes when I asked.",
            "Yes, we can go to the park."
        ],
        "bus": [
            "The bus takes us to school.",
            "We wait for the yellow bus.",
            "The bus stops at the corner."
        ],
        # Difficulty 2 words
        "ball": [
            "Let's kick the ball around.",
            "The red ball bounced high.",
            "She threw the ball to her friend."
        ],
        "tree": [
            "The tree has green leaves.",
            "We climbed the tall tree.",
            "A bird lives in that tree."
        ],
        "book": [
            "I love reading this book.",
            "The book has many pictures.",
            "Can you hand me that book?"
        ],
        "fish": [
            "The fish swims in the water.",
            "We caught three fish today.",
            "My pet fish is orange and white."
        ],
        "bird": [
            "The bird is singing a song.",
            "A blue bird flew past the window.",
            "The bird built a nest in the tree."
        ],
        "cake": [
            "The birthday cake is delicious.",
            "Mom baked a chocolate cake.",
            "We shared the cake with everyone."
        ],
        "play": [
            "Let's play outside together.",
            "The children play in the park.",
            "I like to play with my friends."
        ],
        "jump": [
            "I can jump really high.",
            "Let's jump over the puddle.",
            "The frog can jump very far."
        ],
        "swim": [
            "I learned how to swim last summer.",
            "Fish can swim underwater.",
            "We swim at the pool every week."
        ],
        "blue": [
            "The sky is bright blue today.",
            "I have a blue backpack.",
            "Her favorite color is blue."
        ],
        "green": [
            "The grass is green and fresh.",
            "I painted my room green.",
            "Trees have green leaves in spring."
        ],
        "happy": [
            "I feel happy when I play.",
            "The happy puppy wagged its tail.",
            "Everyone looks happy today."
        ],
        "water": [
            "I drink water when I'm thirsty.",
            "The water in the pool is cold.",
            "Plants need water to grow."
        ],
        "apple": [
            "I ate a red apple for lunch.",
            "The apple tastes sweet and juicy.",
            "Mom put an apple in my lunch box."
        ],
        "house": [
            "We live in a white house.",
            "The house has a big backyard.",
            "My friend's house is down the street."
        ],
        "mouse": [
            "The little mouse ran away quickly.",
            "We saw a mouse in the barn.",
            "The mouse nibbled on the cheese."
        ],
        "sleep": [
            "I need to sleep early tonight.",
            "The baby can sleep for hours.",
            "Let's sleep under the stars tonight."
        ],
        "dream": [
            "I had a wonderful dream last night.",
            "In my dream, I could fly.",
            "What did you dream about?"
        ],
        "smile": [
            "Your smile makes me happy.",
            "She has a big smile on her face.",
            "Don't forget to smile for the camera."
        ],
        "light": [
            "Turn on the light, please.",
            "The light from the sun is bright.",
            "My backpack is very light."
        ],
    }

    if word in sentences:
        return sentences[word]

    # Generic fallback
    return [
        f"The {word} is interesting.",
        f"I like {word} very much.",
        f"We learned about {word} today."
    ]

def generate_contextual_sentence(word, num):
    """Generate a contextual sentence using the word."""
    # Simple sentence patterns that work for most words
    patterns = [
        [
            f"The word {word} is used in many ways.",
            f"Learning to spell {word} is important.",
            f"Can you use {word} in a sentence?"
        ],
        [
            f"Students learn the meaning of {word}.",
            f"The teacher explained what {word} means.",
            f"We practiced writing {word} today."
        ],
        [
            f"Understanding {word} helps us communicate better.",
            f"The concept of {word} is interesting.",
            f"Many people find {word} challenging to spell."
        ]
    ]

    group = (num - 1) % 3
    return patterns[group][num - 1]

def main():
    """Generate the complete JSON file."""
    output = {
        "metadata": {
            "total_files": 720,
            "total_words": 240,
            "sentences_per_word": 3,
            "voice": "Lisa",
            "format": "WAV (44.1kHz, 16-bit, mono)",
            "output_directory": "spelling-bee iOS App/Resources/Audio/Lisa/sentences/",
            "generated_by": "generate_sentences_json.py"
        },
        "sentences": []
    }

    for difficulty in range(1, 13):
        words = WORD_BANK[difficulty]

        for word in words:
            # Get sentences for this word
            if difficulty <= 2:
                sentences = create_simple_sentences(word)
            else:
                # For higher difficulties, generate contextual sentences
                sentences = [generate_contextual_sentence(word, i+1) for i in range(3)]

            # Add each sentence to the output
            for i, sentence_text in enumerate(sentences, start=1):
                output["sentences"].append({
                    "difficulty": difficulty,
                    "word": word,
                    "sentenceNumber": i,
                    "text": sentence_text,
                    "outputFile": f"difficulty_{difficulty}/{word}_sentence{i}.wav"
                })

    # Write to file
    with open("SENTENCES_AUDIO_BATCH.json", "w", encoding="utf-8") as f:
        json.dump(output, f, indent=2, ensure_ascii=False)

    print(f"✅ Generated {len(output['sentences'])} sentences")
    print(f"📁 Output file: SENTENCES_AUDIO_BATCH.json")

    # Print summary by difficulty
    print("\n📊 Summary by difficulty:")
    for diff in range(1, 13):
        count = len([s for s in output["sentences"] if s["difficulty"] == diff])
        print(f"   Difficulty {diff:2d}: {count:3d} sentences ({count//3} words)")

if __name__ == "__main__":
    main()
