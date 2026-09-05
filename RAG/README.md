-------------------
RAG Implementation
-------------------
####
-----------------------------
1. General RAG Implementation
-----------------------------
There are 6 Canonical Steps involved in the implementation of a RAG Pipeline:
- Data Ingestion: This focuses on the way you ingest your data source for RAG implementation i.e the way file/data is imported- from one drive, google drive, s3, cloud storage etc.
- Data Transformation: This involves transitioning your data(text/tokens) to chunks e.g 512, 1024, 2048 etc
- Embedding: This aspect deals with the conversion of chunks to vectors (numerical representations) for semantic meaning
- Data Indexing: This is where you structure your data/chunks into index- you organize your data to be easily retrieved.
- Retrieval:: You initiate a query that will be used to retrieve documents/text/topics that are similar in semantics/keyword etc to the query.
- Generation: From what has been retrieved, a response will be generated and grounded for a return.
####
------------------------------------
2. RAG Implementation Leveraging GCP
------------------------------------
GCP is a managed service and therefore some steps are abstracted in its implementation. A parameter/query/call/config is used to 
automatically process some of the steps and therefore instead of following the canonical step part by having exact 6 steps, it instead
just utilizes 3 steps, wherein the first 3 canonical steps are combined into 1 and then retrieval and generation:
- Data Ingestion: You have got data/files to be ingested (import files) e.g JIRA, Confluence, Google Drive, One Drive and you include your chunking- define a size, overlap, no of similarly stored semantics (top-k) by uploading a pdf or text version of your data source into a data storage e.g s3, cloud storage etc as chunks, then you implement your embedding via google embedding, or E5 or BCG etc and then indexing- (corpus gets created automatically) will be carried- all these steps are defined as parameters in your GCP config
N.B: Can use Vertex AI Vector Search for your vector db- indexing besides weaviate or pinecone- select your choice. The ingestion, chunking, and embedding are passed as parameters and get executed in the RAG Engine- use Import script.
- Retrieval: There is a query to use for your retrieval in GCP (retrieve_contexts)
- Generation: A response is generated and grounded for a return.
####
-------------------------------------
3. RAG Implementation Leveraging AWS
--------------------------------------
AWS is a managed service as well and some steps in the workflow are abstracted in its implementation. However, there are 2 options available for implementation in AWS. The first option involves the 3 steps workflow like GCP, while the second option uses exact 6 steps worklow utilizing AWS services at each of the steps.
####
First Option:
- AWS Bedrock + Knowledege Bases: Ingest data/files into S3 from your knowledge bases e.g JIRA, Confluence, Salesforce, Google Drive etc. Use OpenSearch Serverless as the vector db as an enterprise or use Aurora PostgreSQL + pgvector or S3 vector as a startup or SME or select a 3rd party vector db.
N.B: The ingestion, chunking and embedding will all take place in the Bedrock while you choose a preferred vector db for indexing. Some of the embedding model of choice in AWS are Titan and Cohere.
- Retrieval: There is Retrieve API that will produce relevant response once queried.
- Generation: There is a generation of response that combines with the retrieval in a single call.
####
Second Option:
- S3 Event- To store your files/data for ingestion
- Lambda or Step Function with Chucking: For extraction and chunking of the files- size, strategy, overlap etc
- AWS Bedrock Embedding API- Cohere etc for embedding
- OpenSearch Serverless or pgvector- For indexing of the chunks
- Lambda- To serve retrieval purpose
- LLM Call- To generate the response.
####
-----------------------------------------
Out of the box flow manual implementation
-----------------------------------------
- pypdf
- recursive chunker
- ebedding API
- pgvector
- cosine top-k
- prompt template. 
####
----------------------------------------------------------------------
Uploading files directly from local machine to cloud storage: One off
----------------------------------------------------------------------
- "gcloud storage cp C:\Users\You\Notes\*.txt gs://rag-corpus/"

---------------------------------------------
Uploading files from GitHub to cloud storage: Off
---------------------------------------------
git clone https://github.com/your-org/your-repo.git
gcloud storage rsync --recursive \
  --exclude '\.git/.*' \
  ./your-repo gs://rag-corpus/github/your-repo/
####
N:B: The rsync is to upload changes in the future.