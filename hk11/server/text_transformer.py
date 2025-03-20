import os
from PyPDF2 import PdfReader
import os
import ebooklib
from ebooklib import epub
from bs4 import BeautifulSoup
import re

def convert_pdf_to_txt(pdf_path, output_path=None):

    # Validate input file
    if not pdf_path.lower().endswith('.pdf'):
        raise ValueError("Input file must be a PDF")
    
    if not os.path.exists(pdf_path):
        raise FileNotFoundError(f"PDF file not found: {pdf_path}")
    
    # Determine output path
    if output_path is None:
        output_path = os.path.dirname(pdf_path)
    
    # Create output directory if it doesn't exist
    os.makedirs(output_path, exist_ok=True)
    
    # Generate output filename
    base_filename = os.path.splitext(os.path.basename(pdf_path))[0]
    txt_path = os.path.join(output_path, f"{base_filename}.txt")
    
    # Extract text from PDF
    with open(pdf_path, 'rb') as file:
        reader = PdfReader(file)
        
        # Open text file to write
        with open(txt_path, 'w', encoding='utf-8') as txt_file:
            # Extract text from each page
            for page in reader.pages:
                txt_file.write(page.extract_text())
    
    print(f"Converted {pdf_path} to {txt_path}")
    return txt_path

def batch_convert_pdfs(pdf_path, output_directory=None):

    # Validate input directory
    if not os.path.isdir(pdf_path):
        raise ValueError(f"Not a valid directory: {pdf_path}")
    
    # List to store converted file paths
    converted_files = []
    
    # Iterate through PDF files in the directory
    for filename in os.listdir(pdf_path):
        if filename.lower().endswith('.pdf'):
            pdf_path = os.path.join(pdf_path, filename)
            try:
                txt_path = convert_pdf_to_txt(pdf_path, output_directory)
                converted_files.append(txt_path)
            except Exception as e:
                print(f"Error converting {filename}: {e}")
    
    return converted_files

def convert_epub_to_txt(epub_path, output_path=None):
    # Validate input file
    if not epub_path.lower().endswith('.epub'):
        raise ValueError("Input file must be an EPUB")
    
    if not os.path.exists(epub_path):
        raise FileNotFoundError(f"EPUB file not found: {epub_path}")
    
    # Determine output path
    if output_path is None:
        output_path = os.path.dirname(epub_path)
    
    # Create output directory if it doesn't exist
    os.makedirs(output_path, exist_ok=True)
    
    # Generate output filename
    base_filename = os.path.splitext(os.path.basename(epub_path))[0]
    txt_path = os.path.join(output_path, f"{base_filename}.txt")
    
    # Open the EPUB book
    book = epub.read_epub(epub_path)
    
    # Open text file to write
    with open(txt_path, 'w', encoding='utf-8') as txt_file:
        # Write book title
        if book.get_metadata('DC', 'title'):
            txt_file.write(f"Title: {book.get_metadata('DC', 'title')[0][0]}\n\n")
        
        # Write book author
        if book.get_metadata('DC', 'creator'):
            txt_file.write(f"Author: {book.get_metadata('DC', 'creator')[0][0]}\n\n")
        
        # Extract text from each HTML item in the book
        for item in book.get_items_of_type(ebooklib.ITEM_DOCUMENT):
            # Parse the HTML content
            soup = BeautifulSoup(item.get_content(), 'html.parser')
            
            # Extract text and clean it up
            page_text = soup.get_text(separator='\n', strip=True)
            
            # Write the text to the file
            txt_file.write(page_text)
            txt_file.write("\n\n")
    
    print(f"Converted {epub_path} to {txt_path}")
    return txt_path

def batch_convert_epubs(epub_directory, output_directory=None):
    # Validate input directory
    if not os.path.isdir(epub_directory):
        raise ValueError(f"Not a valid directory: {epub_directory}")
    
    # List to store converted file paths
    converted_files = []
    
    # Iterate through EPUB files in the directory
    for filename in os.listdir(epub_directory):
        if filename.lower().endswith('.epub'):
            epub_path = os.path.join(epub_directory, filename)
            try:
                txt_path = convert_epub_to_txt(epub_path, output_directory)
                converted_files.append(txt_path)
            except Exception as e:
                print(f"\n\nError converting {filename}: {e}\n")
    
    return converted_files

def batch_converts(path, output_path = None):
    batch_convert_epubs(path, output_path)
    batch_convert_pdfs(path, output_path)



def remove_special_characters(input_path, output_path=None):
    with open(input_path, 'r', encoding='utf-8', errors='ignore') as file:
        text = file.read()
    
    cleaned_text = re.sub(r"[^a-zA-Z0-9\s.,!?'\"]", "", text)
    
    cleaned_text = re.sub(r"\s{2,}", " ", cleaned_text)
    
    cleaned_text = cleaned_text.strip()
    
    with open(output_path, 'w', encoding='utf-8') as file:
        file.write(cleaned_text)
    
    print(f"File cleaned and saved to: {output_path}")

def batch_remove_special_characters(input_folder, output_folder):
    os.makedirs(output_folder, exist_ok=True)
    
    for file_name in os.listdir(input_folder):
        if file_name.endswith('.txt'):
            input_file = os.path.join(input_folder, file_name)
            output_file = os.path.join(output_folder, file_name)
            
            with open(input_file, 'r', encoding='utf-8', errors='ignore') as file:
                text = file.read()
            
            cleaned_text = re.sub(r"[^a-zA-Z0-9\s.,!?'\"]", "", text)
            cleaned_text = re.sub(r"\s{2,}", " ", cleaned_text)
            cleaned_text = cleaned_text.strip()
            
            with open(output_file, 'w', encoding='utf-8') as file:
                file.write(cleaned_text)
            
            print(f"Processed: {file_name} -> Saved to: {output_file}")



# EPUB
# convert_epub_to_txt("/Users/kaloyan/Documents/Flutter/FitAI/FitAI/server/booksToProcess/WhyWeSleep.epub")
# batch_convert_epubs("")

# PDF
convert_pdf_to_txt("/Users/kaloyan/Documents/Flutter/FitAI/FitAI/server/booksToProcess/InDefenceOfFood.pdf", "/Users/kaloyan/Documents/Flutter/FitAI/FitAI/server/processedBooks")
# batch_convert_pdfs("")

# batch_converts("/Users/kaloyan/Documents/Flutter/FitAI/FitAI/server/booksToProcess", output_path="/Users/kaloyan/Documents/Flutter/FitAI/FitAI/server/processedBooks")

# batch_remove_special_characters("")