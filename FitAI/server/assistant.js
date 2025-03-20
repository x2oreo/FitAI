const { PineconeClient } = require('@pinecone-database/pinecone');
const { OpenAI } = require('openai');
const { GoogleGenerativeAI } = require('@google/generative-ai');
require('dotenv').config();

// Initialize clients
const openai = new OpenAI({
  apiKey: process.env.OPENAI_API_KEY,
});
const genAI = new GoogleGenerativeAI(process.env.GEMINI_API_KEY);
const pinecone = new Pinecone({apiKey: process.env.PINECONE_API_KEY});
const index = pinecone.index(process.env.PINECONE_INDEX);

// Generate embeddings using OpenAI's text-embedding-ada-002
async function generateEmbedding(text) {
    if (!query || typeof query !== "string") {
        throw new Error("Invalid query parameter");
      }
      try {
        const denseResponse = await openai.embeddings.create({
          input: query,
          model: denseModel,
        });
        return {vector: denseResponse.data[0].embedding};
      } catch (error) {
        console.error("Error embedding query:", error);
        return null;
      }
}

// Query Pinecone to get top 10 relevant chunks
async function queryPinecone(embeddings, topK = 10) {
    if (!queryEmbeddings || !queryEmbeddings.vector) {
        throw new Error("Invalid embedding format");
        }
    const queryResponse = await index.query({
        vector: embeddings.vector,
        topK,
        includeMetadata: true,
    });
    
    return queryResponse.results;
}

// Call Gemini API with the retrieved context
async function queryGemini(query, nameUser, userInfo, contextChunks) {
  const model = genAI.getGenerativeModel({ model: "gemini-2.0-flash" });
  
  // Format context chunks into a single string
  const formattedContext = contextChunks
      .map((chunk) => `${chunk.metadata.text}`)
      .join("\n\n");
  
  const prompt = `
    You are a highly knowledgeable and empathetic personal health assistant specializing in the unique health needs of a programmer named ${nameUser}.
    Your goal is to provide clear, actionable, and science-backed advice tailored to the ${nameUser}'s concerns.

    ${nameUser}'s Question:
    "${query}"

    What You Know About the User:
    ${userInfo}

    Additional Knowledge:
    You have access to the following knowledge base, which you should treat as your own expertise:
    ${formattedContext}

    Guidelines:
    - Provide answers in a clear, concise, and engaging manner.
    - Focus on practical, real-world solutions that fit into a programmer’s lifestyle.
    - Address health concerns related to prolonged sitting, screen time, stress, diet, sleep, and productivity.
    - If the question is beyond your expertise, encourage the user to seek medical advice rather than speculating.
    - Use an encouraging and supportive tone, but don’t sugarcoat important health risks.
    `;

  const result = await model.generateContent(prompt);
  return result.response.text();
}

// Main function to process a query
async function processQuery(query) {
  try {
    // Generate embedding for the query
    const embedding = await generateEmbedding(query);
    
    // Retrieve top 10 relevant chunks from Pinecone
    const relevantChunks = await queryPinecone(embedding);
    
    // If no relevant chunks found
    if (relevantChunks.length === 0) {
      return "I couldn't find any relevant information to answer your question.";
    }
    
    // Generate answer using Gemini with retrieved chunks as context
    const answer = await queryGemini(query, relevantChunks);
    
    return answer;
  } catch (error) {
    console.error("Error processing query:", error);
    return "An error occurred while processing your query.";
  }
}

module.exports = { processQuery };