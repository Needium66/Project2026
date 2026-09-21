"""Import/sync PDFs from GCS into the RAG corpus.
Called by GitHub Actions after every push that changes files in docs/.
Idempotent: unchanged files are skipped automatically by the API.

Usage:
  python scripts/import_files.py \
    --project YOUR_PROJECT_ID \
    --corpus  projects/.../ragCorpora/... \
    --bucket  gs://needium66_rag/notes/
"""
import argparse
import sys
from datetime import datetime, timezone

import vertexai
from vertexai import rag


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("--project",  required=True)
    ap.add_argument("--corpus",   required=True)
    ap.add_argument("--bucket",   required=True, help="gs://bucket/prefix/")
    ap.add_argument("--region",   default="us-central1")
    ap.add_argument("--chunk-size",    type=int, default=512)
    ap.add_argument("--chunk-overlap", type=int, default=100)
    args = ap.parse_args()

    vertexai.init(project=args.project, location=args.region)

    stamp = datetime.now(timezone.utc).strftime("%Y%m%d-%H%M%S")
    sink  = f"{args.bucket.rstrip('/')}/import_results/{stamp}.ndjson"

    print(f"Importing from {args.bucket} into corpus ...")
    response = rag.import_files(
        args.corpus,
        [args.bucket],
        transformation_config=rag.TransformationConfig(
            chunking_config=rag.ChunkingConfig(
                chunk_size=args.chunk_size,
                chunk_overlap=args.chunk_overlap,
            )
        ),
        max_embedding_requests_per_min=900,
        import_result_sink=sink,
    )

    imported = response.imported_rag_files_count
    failed   = getattr(response, "failed_rag_files_count", 0)
    skipped  = getattr(response, "skipped_rag_files_count", 0)

    print(f"Imported: {imported}  Failed: {failed}  Skipped: {skipped}")
    print(f"Results : {sink}")

    if failed:
        print("ERROR: one or more files failed to import.", file=sys.stderr)
        sys.exit(1)


if __name__ == "__main__":
    main()
