import sys
import vertexai
from vertexai import rag

PROJECT = "YOUR_PROJECT_ID"
REGION = "us-"
CORPUS = "projects/.../ragCorpora/..."   # same one

vertexai.init(project=PROJECT, location=REGION)

question = " ".join(sys.argv[1:]) or "What topics do these notes cover?"

response = rag.retrieval_query(
    rag_resources=[rag.RagResource(rag_corpus=CORPUS)],
    text=question,
    rag_retrieval_config=rag.RagRetrievalConfig(
        top_k=5,
        filter=rag.Filter(vector_distance_threshold=0.5),  # drop weak matches
    ),
)

for ctx in response.contexts.contexts:
    print("─" * 70)
    print(f"score: {ctx.score:.3f}  source: {ctx.source_display_name}")
    print(ctx.text[:400])