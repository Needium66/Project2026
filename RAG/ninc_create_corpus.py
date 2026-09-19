import vertexai
from vertexai import rag

PROJECT = "YOUR_PROJECT_ID"
REGION = "us-"   # must match where you'll query from

vertexai.init(project=PROJECT, location=REGION)

corpus = rag.create_corpus(
    display_name="rag-notes",
    description="Personal notes corpus (markdown from GCS)",
    backend_config=rag.RagVectorDbConfig(          # backend: RagManagedDb by default
        rag_embedding_model_config=rag.RagEmbeddingModelConfig(
            vertex_prediction_endpoint=rag.VertexPredictionEndpoint(
                publisher_model="publishers/google/models/gemini-embedding-005"
            )
        )
    ),
)

print("Corpus created!")
print("Resource name:", corpus.name)   # <-- SAVE THIS for step 4

###
#NOTE: Errored out with vertexai module not found- venv in action:
#Run this to add the dependency/library/module-"python -m pip install --upgrade google-cloud-aiplatform"
###
#NOTE: Acceptable embedding model: publisher_model="publishers/google/models/text-embedding-005"