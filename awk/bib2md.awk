#!/usr/bin/awk -f
#
# bib2md.awk -- convert BiBTeX entries for *articles* into Markdown.
#
# I wrote this while documenting NoLiTSA.  Contains loads and loads of
# bugs.  Always check the output and see if everything's alright.
#
# -m, 2015-08-24 23:46 IST
#

BEGIN {
  field_authors     = "MISSING_AUTHORS!"
  field_year        = "MISSING_YEAR!"
  field_title       = "MISSING_TITLE!"
  field_journal     = "MISSING_JOURNAL!"
  field_volume      = "MISSING_VOLUME!"
  field_volume      = "MISSING_VOLUME!"
  field_url         = "MISSING_URL!"
}

function clean(string) {
  gsub("[{}]", "", string)
  gsub(",$", "", string)
  return string
}

function authors(string) {
  new_string = ""
  split(string, array, "[[:space:]]+and[[:space:]]+")
  for (i = 1; i <= length(array); i++) {
    split(array[i], name, "[[:space:]]")
    if (i == length(array) && length(array) != 1)
      new_string = new_string " & " name[length(name)] ", "
    else
      new_string = new_string name[length(name)] ", "

    for (j = 1; j < length(name); j++)
      new_string = new_string toupper(substr(name[j], 1, 1)) "."

    if (i < length(array) - 1)
      new_string = new_string ", "
  }

  return new_string
}

function print_all() {
  printf("%s (%s). %s. [_%s_ __%s__, %s](%s).\n\n", \
        field_authors,                              \
        field_year,                                 \
        field_title,                                \
        field_journal,                              \
        field_volume,                               \
        field_pages,                                \
        field_url                                   \
  )

  field_authors     = "MISSING_AUTHORS!"
  field_year        = "MISSING_YEAR!"
  field_title       = "MISSING_TITLE!"
  field_journal     = "MISSING_JOURNAL!"
  field_volume      = "MISSING_VOLUME!"
  field_pages       = "MISSING_PAGES!"
  field_url         = "MISSING_URL!"
}

/author/ {
  split($0, array, "[[:space:]]*=[[:space:]]*")
  field_authors = authors(clean(array[2]))
}

/year/ {
  split($0, array, "[[:space:]]*=[[:space:]]*")
  field_year = clean(array[2])
}

/title/ {
  split($0, array, "[[:space:]]*=[[:space:]]*")
  field_title = clean(array[2])
}

/journal/ {
  split($0, array, "[[:space:]]*=[[:space:]]*")
  field_journal = clean(array[2])
}

/volume/ {
  split($0, array, "[[:space:]]*=[[:space:]]*")
  field_volume = clean(array[2])
}

/volume/ {
  split($0, array, "([[:space:]]*=[[:space:]]*|--)")
  field_volume = clean(array[2])
}

/pages/ {
  split($0, array, "([[:space:]]*=[[:space:]]*|--)")
  field_pages = clean(array[2])
}

/url/ {
  split($0, array, "([[:space:]]*=[[:space:]]*|--)")
  field_url = clean(array[2])
}

/^@/ {
  if (NR != 1)
    print_all()
}

END {
  print_all()
}
