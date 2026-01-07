# ==================================================
# Program Name   : text_generation.py
# Purpose        : Text generation API for label generation
# Developer      : Mr. Ng Kuok Hong 
# Student ID     : TP069007
# Course         : Bachelor of Software Engineering (Hons) 
# Created Date   : 19 December 2025
# Last Modified  : 24 December 2025
# ==================================================

import os
import json
from google import genai

from fastapi import FastAPI
from pydantic import BaseModel
from typing import List

app = FastAPI()

PROJECT_ID = os.environ.get('GOOGLE_CLOUD_PROJECT')
MODEL_ID = os.environ.get('MODEL_ID')
key_json = os.environ.get("GOOGLE_APPLICATION_CREDENTIALS_JSON")
if key_json:
    os.environ["GOOGLE_APPLICATION_CREDENTIALS"] = "/tmp/vertex-ai-key.json"
    with open("/tmp/vertex-ai-key.json", "w") as f:
        f.write(key_json)

client = genai.Client(
    vertexai=True,
    project=PROJECT_ID,
    location="global",
)

@app.get("/ping")
async def ping():
    return {"status": "ok", "message": "Server is awake"}

class GenerateLabelRequest(BaseModel):
    text: str = ""
    list_of_labels: List[str] = []

@app.post("/generate-labels")
def generate_labels(request: GenerateLabelRequest):
    try:
        text = request.text
        list_of_labels = request.list_of_labels

        input_text = (
            "Generate about 5 labels for the TEXT.\n"
            "Each label should be 1 to 2 words.\n"
            "Do NOT repeat words from the TEXT.\n"
            "Return ONLY comma-separated list of labels.\n\n"
            f"TEXT: {text}."
        )
        if list_of_labels:
            input_text += f" If the text is ONLY highly relevant to one of: {', '.join(list_of_labels)}, then please use one of these."

        response = client.models.generate_content(
            model=MODEL_ID,
            contents=[input_text]
        )

        raw_output = response.text or ""

        labels = [
            label.strip().title() 
            for label in raw_output.split(",") 
            if label.strip()
        ]
        labels = list(dict.fromkeys(labels))

        return { "labels": labels[:5] }
    except Exception as ex:
        import traceback
        traceback.print_exc()
        return {"error": str(ex)}