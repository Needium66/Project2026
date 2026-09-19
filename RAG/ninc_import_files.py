import vertexai
from vertexai import rag

PROJECT = "YOUR_PROJECT_ID"
REGION = "us-"
CORPUS = "projects/YOUR_PROJECT_ID/locations/us-/ragCorpora/1234567890"  # from step 3's output
BUCKET_PATH = "gs://YOUR_BUCKET_NAME/"   # whole bucket; or a prefix like gs://bucket/notes/

vertexai.init(project=PROJECT, location=REGION)

response = rag.import_files(
    CORPUS,
    [BUCKET_PATH],
    transformation_config=rag.TransformationConfig(
        chunking_config=rag.ChunkingConfig(
            chunk_size=512,      # tokens per chunk
            chunk_overlap=100,   # ~20% overlap
        )
    ),
    max_embedding_requests_per_min=900,  # throttle below the embedding quota
)

print("Imported:", response.imported_rag_files_count)
print("Failed:  ", getattr(response, "failed_rag_files_count", 0))
print("Skipped: ", getattr(response, "skipped_rag_files_count", 0))