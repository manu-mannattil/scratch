#!/bin/sh
#
# ------------  --------------------------------------------------------
#         file  pdfnl.sh
#  description  Number lines in a PDF
# dependencies  PDFtk
#      created  2016-05-14 05:35 IST
#     modified  2016-05-14 13:25 IST
# ------------  --------------------------------------------------------
#
# pdfnl works by watermarking a "ruler" to all pages of a PDF using
# PDFtk.
#
# Usage: pdfnl [-r <ruler>] [-o <output>] <file>
#
# Watermark rulers:
#
#   * default-both-a4.pdf
#       Line numbers on both sides for an A4 paper.
#
#   * default-both-letter.pdf
#       Line numbers on both sides for a US letter.
#

shname="pdfnl"
shdir=$(dirname "$(readlink -e -f -n -- "$0")")

while getopts ":o:r:" opt; do
  case "$opt" in
    o)  output="$OPTARG" ;;
    r)  ruler="$OPTARG" ;;
    :)  printf >&2 "${shname}: -${OPTARG} requires an argument\n"; exit 1  ;;
    \?) printf >&2 "${shname}: -${OPTARG} is not a valid option\n"; exit 1 ;;
  esac
done
shift $(( OPTIND - 1 ))

if test $# -eq 0
then
  printf >&2 "usage: ${shname} <file>.pdf\n"
  exit 1
fi

input="$1"
test -z "$ruler" && ruler="${shdir}/default-both-letter.pdf"
test -z "$output" && output="${input%.*}-nl.pdf"
exec pdftk "$input" background "$ruler" output "$output"
