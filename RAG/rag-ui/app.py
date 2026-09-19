"""Minimal internal chat UI over the Vertex RAG corpus.

Run:  python app.py   ->  http://localhost:7860
Everything configurable lives in environment variables (see .env.example).
"""
import os

import gradio as gr
from google import genai
from google.genai import types

PROJECT = os.environ["GCP_PROJECT"]
CORPUS = os.environ["RAG_CORPUS"]          # full resource name from step 3
MODEL = os.environ.get("GENERATION_MODEL", "gemini-3.8-flash")
LOCATION = os.environ.get("GCP_LOCATION", "global")
TOP_K = int(os.environ.get("TOP_K", "5"))

client = genai.Client(vertexai=True, project=PROJECT, location=LOCATION)

RAG_TOOL = types.Tool(
    retrieval=types.Retrieval(
        vertex_rag_store=types.VertexRagStore(
            rag_resources=[types.VertexRagStoreRagResource(rag_corpus=CORPUS)],
            rag_retrieval_config=types.RagRetrievalConfig(
                top_k=TOP_K,
                filter=types.RagRetrievalConfigFilter(vector_distance_threshold=0.5),
            ),
        )
    )
)

SYSTEM = (
    "You answer questions using the retrieved internal notes. "
    "If the notes don't cover the question, say so plainly instead of guessing."
)


def _sources(response) -> str:
    """Pull cited files out of grounding metadata, if present."""
    try:
        chunks = response.candidates[0].grounding_metadata.grounding_chunks or []
        titles = {c.retrieved_context.title for c in chunks if c.retrieved_context}
        return "\n\n---\n*Sources: " + ", ".join(sorted(titles)) + "*" if titles else ""
    except (AttributeError, IndexError, TypeError):
        return ""


def respond(message: str, history: list[dict]) -> str:
    # Rebuild the conversation so follow-up questions stay in context.
    contents = []
    for turn in history:
        role = "user" if turn["role"] == "user" else "model"
        text = turn["content"] if isinstance(turn["content"], str) else str(turn["content"])
        contents.append(types.Content(role=role, parts=[types.Part(text=text)]))
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
    type="messages",
    title="Internal Notes Assistant",
    description="Ask questions about the internal knowledge base. Answers are grounded in the RAG corpus.",
    examples=["What are the different memory types and their limitations?",
              "What topics do these notes cover?"],
)

if __name__ == "__main__":
    demo.launch(
        server_name="0.0.0.0",                       # reachable by teammates on your network
        server_port=int(os.environ.get("PORT", "7860")),
        auth=(                                        # optional minimal gate: set both vars to enable
            (os.environ["UI_USER"], os.environ["UI_PASS"])
            if os.environ.get("UI_USER") and os.environ.get("UI_PASS") else None
        ),
    )
