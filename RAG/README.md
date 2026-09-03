-------------------
RAG Implementation
-------------------
####
-----------------------------
1. General RAG Implementation
-----------------------------
There are 6 Canonical Steps involved in the implementation of a RAG Pipeline:
- Data Ingestion: This focuses on the way you ingest your data source for RAG implementation- from one drive, google drive, s3, cloud storage etc.
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
- Data Ingestion: You have got a data to ingest (import files) e.g JIRA, Confluence, Google Drive, One Drive and you include your chunking- define a size, overlap, no of similarly stored semantics (top-k) by uploading a pdf or text version of your data source into a data storage e.g s3, cloud storage etc, then you implement your embedding via google embedding, or E5 or BCG etc and then indexing- (create corpus) will be carried- all these steps are defined as parameters in your GCP config
N.B: Can use Vertex AI Vector Search for your vector db- indexing besides weaviate or pinecone
- Retrieval: There is a query to use for your retrieval in GCP (retrieve_contexts)
- Generation: A response is generated and grounded for a return.
####
-------------------------------------
3. RAG Implementation Leveraging AWS
--------------------------------------