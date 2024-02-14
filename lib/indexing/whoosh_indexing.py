import glob
from whoosh import index, fields 
from whoosh.qparser import QueryParser
import os
import stat



# Define schema with title and content fields
schema = fields.Schema(title=fields.TEXT, content=fields.TEXT)

# Path to your text files directory
text_files_dir = "..\\..\\אוצריא"

# Create an index writer
# create folder if not exist
if not os.path.exists("index_dir"):
    os.mkdir("index_dir")
ix = index.create_in("index_dir", schema)
writer = ix.writer()

for path in glob.iglob(f"{text_files_dir}\\**\\*", recursive=True):  # use iglob instead of glob:
        if not stat.S_ISDIR(os.stat(path).st_mode) and not path.endswith("pdf"):
                filepath = str(path)
                with open(filepath, "r", encoding="utf-8") as f:
                    title = path
                    content = f.read()
                writer.add_document(title=title, content=content)

# Commit the changes
writer.commit()

# Define your search term
search_term = "ירא שמים"
query = QueryParser("content", schema=schema).parse(search_term)

# Open the index reader
searcher = ix.searcher()


# Perform the search and retrieve results
results = searcher.search(query)

# Iterate and print results
for hit in results:
    print(f"Found in: {hit['title']}")
    print(f"Snippet: {hit.highlights('content', snippet_chars=100)}")
    print("=" * 20)

# Close the index
ix.close()