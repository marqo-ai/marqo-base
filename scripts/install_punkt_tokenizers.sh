#!/bin/bash
# This script is meant to be run at buildtime.

mkdir -p /root/nltk_data/tokenizers
curl https://raw.githubusercontent.com/nltk/nltk_data/gh-pages/packages/tokenizers/punkt.zip -o /root/nltk_data/tokenizers/punkt.zip
unzip /root/nltk_data/tokenizers/punkt.zip -d /root/nltk_data/tokenizers/
rm /root/nltk_data/tokenizers/punkt.zip