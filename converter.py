import fitz  # PyMuPDF
import os

# Function to convert PDF to PNG
def pdf_to_png(directory):
    for file_name in os.listdir(directory):
        if file_name.lower().endswith(".pdf"):
            pdf_path = os.path.join(directory, file_name)
            doc = fitz.open(pdf_path)
            
            # Extract base file name without extension
            base_name = os.path.splitext(file_name)[0]

            # Convert each page to PNG and save
            for page_num in range(len(doc)):
                page = doc[page_num]
                pix = page.get_pixmap()  # Render page to an image
                
                # Save the first page as PNG (overwrite behavior for single-page PDFs)
                if page_num == 0:
                    output_path = os.path.join(directory, f"{base_name}.png")
                else:
                    output_path = os.path.join(directory, f"{base_name}_page_{page_num + 1}.png")

                pix.save(output_path)

            # Close the PDF document
            doc.close()

            # Remove the original PDF file after conversion
            os.remove(pdf_path)

if __name__ == "__main__":
    directory = "output"  # Replace with your folder path

    # Convert all PDFs to PNGs in the directory
    pdf_to_png(directory)
    print("All PDFs have been converted to PNGs and replaced.")
