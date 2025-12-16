from fastapi import FastAPI
from transformers import AutoTokenizer, AutoModelForSeq2SeqLM

app = FastAPI()

tokenizer = AutoTokenizer.from_pretrained("google/flan-t5-small")
model = AutoModelForSeq2SeqLM.from_pretrained("google/flan-t5-small")

def generate_label(text: str, list_of_labels: list):
    input_text = f"Generate a 1-3 word label for the following text. Text: {text}. Preferably choose from these labels: {', '.join(list_of_labels)}."
    inputs = tokenizer(input_text, return_tensors="pt")
    outputs = model.generate(**inputs, do_sample=True, temperature=0.7, max_new_tokens=10, top_p=0.9)
    label = tokenizer.decode(outputs[0], skip_special_tokens=True)
    return label

# Example: 
# {
#   "text": "I love swimming in pool.", 
#   "list_of_labels": ["Sports", "Technology", "Cooking"]
# }
@app.post("/generate-label/")
def generate_label_endpoint(request: dict):
    text = request.get("text", "")
    list_of_labels = request.get("list_of_labels", [])
    label = generate_label(text, list_of_labels)
    return {"label": label}