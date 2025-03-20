import re
import os
import logging
from openai import OpenAI
from pinecone import Pinecone, ServerlessSpec

# Configure logging
logging.basicConfig(level=logging.INFO)
logger = logging.getLogger(__name__)

gpt_api = "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"
pine_api = "pcsk_3JitMn_PWGRiWubNzgq9dN1frPaqkBJAvDvCsaLxZ9QTLy53jaf3FSLQDFWYhQqgwKg2j6"

# Initialize clients
client = OpenAI(api_key=gpt_api)
pinecone_client = Pinecone(api_key=pine_api)


# Create an index if not created
index_name = "gavri"
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
    start_chunk_id = None

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
input_folder = "/Users/kaloyan/Documents/Gavri/Embedding model/01-startups"
# process_and_upsert_embeddings(input_folder)
videos_process_and_upsert(input_folder)


# TESTING
# embedding = get_embedding(text="Title How to Get Strangers To Want To Buy Your Stuff Author Alex Hormozi Section I Start Here Its har d to be poor with leads bangin down your door Hormozi family jingle You have to sell stuf f to make money . It seems simple enough, but everyone tries to skip to the make money part. It doesn t work. I tried. Y ou need all the pieces. Y ou need the stuf f to sell an of fer. You need people to sell it to leads. Then you gotta get those people to buy it sales. Once you put all those in place, then you can make money . My first book, 100M Offers, covers the first step and gives you the stuff. It answers the age old question What should I sell?. Answer an of fer so good people feel stupid saying no. But strangers can only buy your stuf f if they know you exist. This takes leads. Leads mean a lot of dif ferent things to a lot of dif ferent people. But most agree that theyre the first step to getting more customers. In simpler terms, it means theyve got the problem to solve and the money to spend.If youre reading this book, you already know leads don t magically appear . You need to go get them. More precisely , you need to help them find you so they can buy your stuf f! And the best part is, you don t have to waityou can force them to find you. Y ou do that through advertising. Advertising , the pr ocess of making known , lets strangers know about the stuf f you sell. If more people know about the stuf f you sell, then you sell more stuf f. If you")
# index.upsert(
#     vectors=[{
#         "id": "69",
#         "values": embedding["vector"],  # Dense vector
#         "sparse_values": embedding["sparse_vector"],  # Sparse vector
#         "metadata": embedding["metadata"]  # Original text
#     }])