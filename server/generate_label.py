from fastapi import FastAPI
from pydantic import BaseModel
from typing import List
from transformers import AutoTokenizer, AutoModelForSeq2SeqLM

app = FastAPI()

tokenizer = AutoTokenizer.from_pretrained("google/flan-t5-base")
model = AutoModelForSeq2SeqLM.from_pretrained("google/flan-t5-base")

class GenerateLabelRequest(BaseModel):
    text: str = ""
    list_of_labels: List[str] = []

def generate_label(text: str, list_of_labels: list):
    input_text = (
        "Generate a 1 to 2 word label for the TEXT.\n"
        "Return ONLY comma-separated single words.\n\n"
        f"TEXT: {text}."
    )
    if list_of_labels:
        input_text += f" If the text is highly relevant to one of: {', '.join(list_of_labels)}, then please use one of these."
    inputs = tokenizer(input_text, return_tensors="pt")
    outputs = model.generate(**inputs, do_sample=True, temperature=0.1, max_new_tokens=10, top_p=0.9, num_beams=4)
    label = tokenizer.decode(outputs[0], skip_special_tokens=True)
    return label

# Example: 
# {
#   "text": "I love swimming in pool.", 
#   "list_of_labels": ["Sports", "Technology", "Cooking"]
# }
@app.post("/generate-label")
def generate_label_endpoint(request: GenerateLabelRequest):
    label = generate_label(request.text, request.list_of_labels)
    return {"label": label}