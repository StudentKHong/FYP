# import re

# from fastapi import FastAPI
# from pydantic import BaseModel
# from typing import List
# from transformers import AutoTokenizer, AutoModelForSeq2SeqLM

# app = FastAPI()

# tokenizer = AutoTokenizer.from_pretrained("google/flan-t5-base")
# model = AutoModelForSeq2SeqLM.from_pretrained("google/flan-t5-base")

# class GenerateLabelRequest(BaseModel):
#     text: str = ""
#     list_of_labels: List[str] = []

# def generate_label(text: str, list_of_labels: list):
#     # if not list_of_labels: 
#     #     return []
    # input_text = (
    #     "Generate about 5 labels for the TEXT.\n"
    #     "Each label should be 1 to 2 words.\n"
    #     "Do NOT repeat words from the TEXT.\n"
    #     "Return ONLY comma-separated list of labels.\n\n"
    #     f"TEXT: {text}."
    # )
#     if list_of_labels:
#         input_text += f" If the text is ONLY highly relevant to one of: {', '.join(list_of_labels)}, then please use one of these."
#     inputs = tokenizer(input_text, return_tensors="pt")
#     outputs = model.generate(**inputs, do_sample=True, temperature=0.1, max_new_tokens=10, top_p=0.9, num_beams=4)
#     raw_output = tokenizer.decode(outputs[0], skip_special_tokens=True)
#     labels = [
#         label.strip().title() 
#         for label in raw_output.split(",") 
#         if re.search(r"[A-Za-z0-9]", label.strip())
#     ]
#     labels = list(dict.fromkeys(labels))
#     return labels[:5]

# # Example: 
# # {
# #   "text": "I love swimming in pool.", 
# #   "list_of_labels": ["Sports", "Technology", "Cooking"]
# # }
# @app.post("/generate-label")
# def generate_label_endpoint(request: GenerateLabelRequest):
#     label = generate_label(request.text, request.list_of_labels)
#     return {"label": label}