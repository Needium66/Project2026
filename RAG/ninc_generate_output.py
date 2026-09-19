import sys
from google import genai
from google.genai import types

PROJECT = "YOUR_PROJECT_ID"
CORPUS = "projects/YOUR_PROJECT_ID/locations/us-/ragCorpora/YOUR_ID"  # unchanged

client = genai.Client(vertexai=True, project=PROJECT, location="global")

question = " ".join(sys.argv[1:]) or "What topics do these notes cover?"

response = client.models.generate_content(
    model="gemini-3.8-flash",
    contents=question,
    config=types.GenerateContentConfig(
        tools=[types.Tool(
            retrieval=types.Retrieval(
                vertex_rag_store=types.VertexRagStore(
                    rag_resources=[types.VertexRagStoreRagResource(rag_corpus=CORPUS)],
                    similarity_top_k=5,
                )
            )
        )]
    ),
)

print(response.text)