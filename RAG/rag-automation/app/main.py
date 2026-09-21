"""RAG UI — Gradio chat interface over Vertex AI RAG Engine.
All config via environment variables injected by Cloud Run / Secret Manager.
"""
import os
import gradio as gr
from google import genai
from google.genai import types

PROJECT  = os.environ["GCP_PROJECT"]
CORPUS   = os.environ["RAG_CORPUS"]
MODEL    = os.environ.get("GENERATION_MODEL", "gemini-3.8-flash")
LOCATION = os.environ.get("GCP_LOCATION", "global")
TOP_K    = int(os.environ.get("TOP_K", "5"))

client = genai.Client(vertexai=True, project=PROJECT, location=LOCATION)

RAG_TOOL = types.Tool(
    retrieval=types.Retrieval(
        vertex_rag_store=types.VertexRagStore(
            rag_resources=[types.VertexRagStoreRagResource(rag_corpus=CORPUS)],
            rag_retrieval_config=types.RagRetrievalConfig(
                top_k=TOP_K,
                filter=types.RagRetrievalConfigFilter(
                    vector_distance_threshold=0.5
                ),
            ),
        )
    )
)

SYSTEM = (
    "You are an internal knowledge assistant. Answer questions using only "
    "the retrieved internal documents. If the answer is not in the documents, "
    "say so plainly — do not guess or invent information."
)


def _sources(response) -> str:
    try:
        chunks = response.candidates[0].grounding_metadata.grounding_chunks or []
        titles = {c.retrieved_context.title for c in chunks if c.retrieved_context}
        return "\n\n---\n*Sources: " + ", ".join(sorted(titles)) + "*" if titles else ""
    except (AttributeError, IndexError, TypeError):
        return ""


def respond(message: str, history: list) -> str:
    contents = []
    for turn in history:
        if isinstance(turn, dict):
            role = "user" if turn["role"] == "user" else "model"
            text = str(turn.get("content", ""))
            contents.append(types.Content(role=role, parts=[types.Part(text=text)]))
        else:
            user_msg, assistant_msg = turn
            contents.append(types.Content(role="user",  parts=[types.Part(text=str(user_msg))]))
            if assistant_msg:
                contents.append(types.Content(role="model", parts=[types.Part(text=str(assistant_msg))]))

    contents.append(types.Content(role="user", parts=[types.Part(text=message)]))

    response = client.models.generate_content(
        model=MODEL,
        contents=contents,
        config=types.GenerateContentConfig(
            tools=[RAG_TOOL],
            system_instruction=SYSTEM,
        ),
    )
    return (response.text or "(no answer returned)") + _sources(response)


demo = gr.ChatInterface(
    fn=respond,
    title="Internal Knowledge Assistant",
    description="Ask questions about internal documents. Answers are grounded in the knowledge base.",
    examples=[
        "What topics do these notes cover?",
        "What are the different memory types and their limitations?",
    ],
)

if __name__ == "__main__":
    demo.launch(
        server_name="0.0.0.0",
        server_port=int(os.environ.get("PORT", "8080")),
    )
