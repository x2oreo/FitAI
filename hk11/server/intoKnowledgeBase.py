import re
import os
import logging
from openai import OpenAI
from pinecone import Pinecone, ServerlessSpec
from dotenv import load_dotenv

# Configure logging
logging.basicConfig(level=logging.INFO)
logger = logging.getLogger(__name__)

# Load environment variables
load_dotenv()

# Get API keys from environment variables
gpt_api = os.getenv('OPENAI_API_KEY')
pine_api = os.getenv('PINECONE_API_KEY')
index_name = os.getenv('PINECONE_INDEX')

# Initialize clients
client = OpenAI(api_key=gpt_api)
pinecone_client = Pinecone(api_key=pine_api)

# Create an index if not created
if index_name not in pinecone_client.list_indexes().names():
    pinecone_client.create_index(
        name=index_name,
        dimension=3072,
        metric="dotproduct",
        spec=ServerlessSpec(cloud="aws", region="us-east-1")
    )
# Connect to Pinecone
index = pinecone_client.Index(index_name)


# Function to read text from a file
def text_from_file(input_file):
    try:
        with open(input_file, 'r', encoding='utf-8') as file:
            return file.read()
    except Exception as e:
        logger.error(f"Error reading file {input_file}: {e}")
        return None


# Function to split text into chunks
def split_text_into_chunks(text, min_chunk_size=200, max_chunk_size=300, overlap_size=20):
    if not text:
        return []

    paragraphs = [p.strip() for p in re.split(r'\n\s*\n', text) if p.strip()]
    chunks = []
    current_chunk = []

    for paragraph in paragraphs:
        words = paragraph.split()
        current_chunk.extend(words)

        while len(current_chunk) >= max_chunk_size:
            chunk = ' '.join(current_chunk[:max_chunk_size])
            chunks.append(chunk)
            current_chunk = current_chunk[max_chunk_size - overlap_size:]

    if len(current_chunk) >= min_chunk_size:
        chunks.append(' '.join(current_chunk))

    return chunks


# Function to generate embeddings
def get_embedding(text, model="text-embedding-3-large", sparse_model="pinecone-sparse-english-v0"):
    try:
        dense_embedding = client.embeddings.create(
        input=text,
        model=model
        )
        sparse_embedding = pinecone_client.inference.embed(
            model=sparse_model,
            inputs=[text],
            parameters={
                "input_type": "passage",
                "return_tokens": False
            }
        )
    
        sparse_values = {
            "indices": sparse_embedding[0]["sparse_indices"],
            "values": sparse_embedding[0]["sparse_values"]
        }

        return {
            "vector": dense_embedding.data[0].embedding,
            "sparse_vector": sparse_values,
            "metadata": {"text": text}
        }
    except Exception as e:
        logger.error(f"Error generating embedding: {e}")
        return None


# Function to process and upsert chunks to Pinecone
def process_and_upsert_embeddings(input_folder):
    book_counter = 1
    media_type = 1
    start_chunk_id = "id-1/6/1185"

    for file_name in os.listdir(input_folder):
        if file_name.endswith('.txt'):
            input_file = os.path.join(input_folder, file_name)
            logger.info(f"Processing {file_name}")

            text = text_from_file(input_file)
            if not text:
                continue

            chunks = split_text_into_chunks(text)
            book_counter += 1

            for chunk_counter, chunk in enumerate(chunks, start=1):
                chunk_id = f"id-{media_type}/{book_counter}/{chunk_counter}"

                # Skip chunks until the start_chunk_id is reached
                if start_chunk_id and chunk_id != start_chunk_id:
                    continue
                else:
                    start_chunk_id = None

                # Generate and upsert embeddings
                embedding = get_embedding(chunk)
                if embedding:
                    try:
                        index.upsert(vectors=[{
                            "id": chunk_id,
                            "values": embedding["vector"],
                            "sparse_values": embedding["sparse_vector"],
                            "metadata": embedding["metadata"]
                        }])
                        logger.info(f"Upserted {chunk_id}")
                    except Exception as e:
                        logger.error(f"Error upserting {chunk_id}: {e}")

# Function to process and upsert video content to Pinecone with a specific namespace
def videos_process_and_upsert(input_folder):
    video_counter = 1
    media_type = 2
    
    for file_name in os.listdir(input_folder):
        if file_name.endswith('.txt'):
            input_file = os.path.join(input_folder, file_name)
            logger.info(f"Processing video content from {file_name}")

            text = text_from_file(input_file)
            if not text:
                continue

            # No chunking - use the entire text
            chunk_id = f"id-{media_type}/{video_counter}/1"
            video_counter += 1

            # Generate and upsert embeddings for the entire text
            embedding = get_embedding(text)
            if embedding:
                try:
                    index.upsert(
                        vectors=[{
                            "id": chunk_id,
                            "values": embedding["vector"],
                            "sparse_values": embedding["sparse_vector"],
                            "metadata": {"text": text, "filename": file_name}
                        }],
                        namespace="startupSpecific"
                    )
                    logger.info(f"Upserted {chunk_id} to startupSpecific namespace")
                except Exception as e:
                    logger.error(f"Error upserting {chunk_id}: {e}")

# Example usage
input_folder = "/Users/kaloyan/Documents/Flutter/FitAI/FitAI/server/processedBooks"
process_and_upsert_embeddings(input_folder)
# videos_process_and_upsert(input_folder)