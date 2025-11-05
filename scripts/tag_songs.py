#!/usr/bin/env python3
"""
Batch song tagging script for offline processing
Tags songs with AI-generated metadata and outputs JSON for Firestore upload
"""

import json
import os
import sys
from typing import List, Dict, Any
from openai import OpenAI

# Initialize OpenAI client
client = OpenAI(api_key=os.getenv("OPENAI_API_KEY"))

def generate_embedding(text: str) -> List[float]:
    """Generate embedding for text using OpenAI"""
    try:
        response = client.embeddings.create(
            model="text-embedding-3-small",
            input=text
        )
        return response.data[0].embedding
    except Exception as e:
        print(f"Error generating embedding: {e}")
        return []

def analyze_lyrics(song_title: str, artist: str, lyrics: str) -> Dict[str, Any]:
    """Analyze lyrics for CEFR level, themes, grammar points"""
    prompt = f"""
    Analyze this song for language learning purposes:
    
    Song: "{song_title}" by {artist}
    Lyrics:
    {lyrics}
    
    Return JSON with:
    - cefr_level: CEFR level (A1, A2, B1, B2, C1, C2)
    - vocab_cefr: Dictionary mapping words to CEFR levels (top 20 words)
    - grammar_points: Array of grammar points found (e.g. ["presente continuo", "imperativo"])
    - themes: Array of themes (e.g. ["love", "nostalgia"])
    - difficulty_score: Double from 0.0 to 1.0
    
    Return only valid JSON, no markdown formatting.
    """
    
    try:
        response = client.chat.completions.create(
            model="gpt-4o-mini",
            messages=[
                {"role": "system", "content": "You are a language learning expert. Return only valid JSON."},
                {"role": "user", "content": prompt}
            ],
            response_format={"type": "json_object"}
        )
        
        result = json.loads(response.choices[0].message.content)
        return result
    except Exception as e:
        print(f"Error analyzing lyrics: {e}")
        return {
            "cefr_level": "B1",
            "vocab_cefr": {},
            "grammar_points": [],
            "themes": [],
            "difficulty_score": 0.5
        }

def tag_song(song: Dict[str, Any]) -> Dict[str, Any]:
    """Tag a single song"""
    song_id = song.get("id", "")
    title = song.get("title", "")
    artist = song.get("artist", "")
    lyrics = song.get("lyrics", "")
    
    if not lyrics:
        print(f"Warning: No lyrics for {title} by {artist}")
        return None
    
    print(f"Tagging: {title} by {artist}...")
    
    # Generate embedding
    embedding = generate_embedding(lyrics)
    
    # Analyze lyrics
    analysis = analyze_lyrics(title, artist, lyrics)
    
    # Create tag
    tag = {
        "id": song_id,
        "cefr": analysis.get("cefr_level", "B1"),
        "vocab_cefr": analysis.get("vocab_cefr", {}),
        "grammar_points": analysis.get("grammar_points", []),
        "themes": analysis.get("themes", []),
        "embeddings": embedding,
        "difficulty_score": analysis.get("difficulty_score", 0.5)
    }
    
    return tag

def main():
    """Main function"""
    if len(sys.argv) < 2:
        print("Usage: python tag_songs.py <input_json_file> [output_json_file]")
        sys.exit(1)
    
    input_file = sys.argv[1]
    output_file = sys.argv[2] if len(sys.argv) > 2 else "tagged_songs.json"
    
    # Load songs from input file
    with open(input_file, 'r', encoding='utf-8') as f:
        songs = json.load(f)
    
    if not isinstance(songs, list):
        print("Error: Input file must contain a JSON array of songs")
        sys.exit(1)
    
    # Tag all songs
    tagged_songs = []
    for song in songs:
        tag = tag_song(song)
        if tag:
            tagged_songs.append(tag)
    
    # Save tagged songs
    with open(output_file, 'w', encoding='utf-8') as f:
        json.dump(tagged_songs, f, indent=2, ensure_ascii=False)
    
    print(f"\nTagged {len(tagged_songs)} songs. Output saved to {output_file}")

if __name__ == "__main__":
    main()

