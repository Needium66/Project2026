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

###
Locally Deploying RAG Pipeline
###
-------------------------------------------------------
#Create a cloud storage bucket for rag implementation:
--------------------------------------------------------
gcloud storage buckets create gs://YOUR_BUCKET_NAME `
  --project=YOUR_PROJECT_ID `
  --location=us- `
  --uniform-bucket-level-access

------------------------------------
#Verify the existence of the bucket:
------------------------------------
gcloud storage buckets describe gs://YOUR_BUCKET_NAME --format="value(name,location)"

------------------------------------------------------------------------------------------------------------------------------------
#Grant the RAG service agent read access: i.e create a service agent with read access for the RAG Engine set up to enable files to be imported from the cloud storage into the corpus eventually:
------------------------------------------------------------------------------------------------------------------------------------
$PROJECT_NUMBER = gcloud projects describe YOUR_PROJECT_ID --format="value(projectNumber)"
gcloud storage buckets add-iam-policy-binding gs://YOUR_BUCKET_NAME `
  --member="serviceAccount:service-$PROJECT_NUMBER@gcp-sa-vertex-rag.iam.gserviceaccount.com" `
  --role="roles/storage.objectViewer"

---------------------------------------
#Upload the data into the bucket:
---------------------------------------
gcloud storage cp .\your-notes.md gs://YOUR_BUCKET_NAME/

----------------------------------------------------------------------------
#Check to see if you have all the necessary services needed enabled already:
----------------------------------------------------------------------------
gcloud services list --enabled --project=$PROJECT_ID --filter="aiplatform"

----------------------------------------
#Create the RAG corpus with this script:
----------------------------------------

-------------------------------------------------------------------------------------------------------------------------------------
#Import the files from the bucket into corpus just created- with this step, the chunking strategy and embedding will be done in one execution:
-------------

-----------------------------------
#Retrieving the data: fixed- top 5
-----------------------------------

------------------------------------------------------------------
#Generate an output from it: ask a question and check the response
-------------------------------------------------------------------

-----------------------
Commands for Execution:
-----------------------
#Check the existence of the read access on the bucket: gcloud storage buckets get-iam-policy gs://test_rag --format=json | Select-String "vertex-rag"
#check size of the file: (Get-Item .\test-notes.md).Length
#check content of the files: Get-Content .\test-notes.md -TotalCount 30
#copy files into the bucket: gcloud storage cp .\test-notes.pdf gs://test_rag/notes/test-notes.pdf
#remove unused file: gcloud storage rm gs://test_rag/import_results/result.ndjson 
#import files: python ninc_import_files.py
#retrieve:  python ninc_retrieve_data.py 
#install new version: python -m pip install google-genai
#generate: python test_generate.py "Explain what installsify is and what it does."
#####
----------------------------------------
Integrate A Minimalistic UI Using Gradio
----------------------------------------
Create a directory
Add files for:
- app.py- expand the generate script, with respond function that has no hallucination, historical chat building- chats follow up and grounding to the chat interface
- requirements for dependencies and 
- an env variable file for the corpus, project id and others
pip install the dependencies- be careful with the version of gradio
run your python script- python app.py
copy the local host and paste it in the browser
check the responses to validate: what does installsify do?
- can you elaborate on the second point?- to check if it is tracking historical chats- keeps up
- what is the weather in Lagos? to see if it hallucinates- should decline
- check for grounding- refers to the source
to enable internal users- enable username and password. provides details with the ip it is running on for access
-----------------------------------------------------------------------------------------------------------------
For enterprise, expand it to run a cloud run- dockerfile package implementation
---------------------------------------------------------------------------------
Start your local docker machine
Enable the required service if not yet enabled- gcloud services enable run.googleapis.com artifactregistry.googleapis.com
------------------------------------------------------------
Create artifactory registry repo to be used for the project:
------------------------------------------------------------
gcloud artifacts repositories create rag-test-ui `
  --repository-format=docker `
  --location=us-central1 `
  --description="RAG UI container images"
----------------------------------------------------------------------------------------------------------------------
Create service account for the cloud run and grant it the permission for cloud run to access vertex ai and rag corpus
----------------------------------------------------------------------------------------------------------------------
gcloud iam service-accounts create rag-ui-runtime `
  --display-name="RAG UI Runtime"
-----------------------------------------------
Enable the project id to be used subsequently:
-----------------------------------------------
$PROJECT_ID = gcloud config get-value project

--------------------------------------------------------------
Grant it permission to have access to vertex ai and rag corpus
--------------------------------------------------------------
gcloud projects add-iam-policy-binding $PROJECT_ID `
  --member="serviceAccount:rag-ui-runtime@$PROJECT_ID.iam.gserviceaccount.com" `
  --role="roles/aiplatform.user"

----------------------------------
Build and Push the container image
----------------------------------
- Configure docker to push to artifact registry:
gcloud auth configure-docker us-central1-docker.pkg.dev
- Build and push (run from the rag-ui folder where your Dockerfile lives)
gcloud builds submit `
  --tag us-central1-docker.pkg.dev/$PROJECT_ID/rag-ui/app:latest

-----------------------------------------------------
Store the rag corpus in a secret for cloud run to use
-----------------------------------------------------
echo "projects/YOUR_PROJECT_ID/locations/us-central1/ragCorpora/YOUR_CORPUS_ID" | `
  gcloud secrets create rag-corpus-name `
  --data-file=- `
  --replication-policy=automatic

----------------------------------------------
Grant the service account runtime to read it:
----------------------------------------------
gcloud secrets add-iam-policy-binding rag-corpus-name `
  --member="serviceAccount:rag-ui-runtime@$PROJECT_ID.iam.gserviceaccount.com" `
  --role="roles/secretmanager.secretAccessor"

--------------------
Deploy to Cloud Run:
--------------------
gcloud run deploy rag-ui `
  --image us-central1-docker.pkg.dev/$PROJECT_ID/rag-ui/app:latest `
  --region us-central1 `
  --service-account rag-ui-runtime@$PROJECT_ID.iam.gserviceaccount.com `
  --no-allow-unauthenticated `
  --set-env-vars GCP_PROJECT=$PROJECT_ID `
  --set-env-vars GCP_LOCATION=global `
  --set-env-vars GENERATION_MODEL=gemini-3.8-flash `
  --set-env-vars TOP_K=5 `
  --set-secrets RAG_CORPUS=rag-corpus-name:latest `
  --memory 512Mi `
  --min-instances 0 `
  --max-instances 3 `
  --port 8080

-------------------------------
Grant the internal team access:
-------------------------------
- For Individual:
gcloud run services add-iam-policy-binding rag-ui `
  --region us-central1 `
  --member="user:colleague@yourcompany.com" `
  --role="roles/run.invoker"
- For Group:
gcloud run services add-iam-policy-binding rag-ui `
  --region us-central1 `
  --member="group:internal-team@yourcompany.com" `
  --role="roles/run.invoker"
- For Everyone In the Workspace:
gcloud run services add-iam-policy-binding rag-ui `
  --region us-central1 `
  --member="group:internal-team@yourcompany.com" `
  --role="roles/run.invoker"
To get the URL of the cloud run deployed:
gcloud run services describe rag-ui `
  --region us-central1 `
  --format="value(status.url)"

--------------------------------------------------------------------------------------------------------------------
Because you deploy with no access for unauthenticated, you might want to enable access through Identity-Aware Proxy:
---------------------------------------------------------------------------------------------------------------------
- You will need an OAuth Screen Configuration for this- If you do not have an existing OAuth Screen, follow the below steps
Enable the service:
gcloud services enable iap.googleapis.com
Create the OAuth Consent Screen
# APIs & Services → OAuth consent screen → Branding -> App name -> App Logo -> App Domain-> Save (Or Skip this entirely)
# Audience- > User Type -> Internal
# Clients -> Create Client -> Name -> Application Type: Web Application -> Add Redirect UI: Incorporate Client ID from the setting into it -> Note: Copy the Client ID and Secret produced in a safe place -> Save
Note: https://iap.googleapis.com/v1/oauth/clientIds/YOUR_CLIENT_ID:handleRedirect
Enable IAP on your Cloud Run service (Cloud Console is easier for this):
# Security → Identity-Aware Proxy → find rag-ui → Toggle ON for IAP -> Select the 3 dots -> Settings-> Select Client Managed Key-> Paste Client ID and Secrets - >
# Paste the OAuth client ID and secret when prompted
 Can save the credentials in secret manager:
gcloud secrets create iap-oauth-client-id --data-file=- <<< "YOUR_CLIENT_ID"
gcloud secrets create iap-oauth-client-secret --data-file=- <<< "YOUR_CLIENT_SECRET"