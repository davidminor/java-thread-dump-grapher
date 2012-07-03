#!/bin/sh
# Usage example: ./dump2pdf log_file output_file.pdf

ruby thread_dump.rb $1 /tmp/intermediate_file
ruby thread_graph.rb /tmp/intermediate_file /tmp/output_file.dot
dot -Tpdf /tmp/output_file.dot -o $2
