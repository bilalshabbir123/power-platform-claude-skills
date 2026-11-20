source convert-markdown.sh
clean_name=$(sanitize_filename "My Document (Draft).md")
echo "$clean_name"  # my_document_draft.md