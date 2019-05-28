# gexsys - Guile Expert Sysytem.

[![DOI](https://zenodo.org/badge/DOI/10.5281/zenodo.2596628.svg)](https://doi.org/10.5281/zenodo.2596628)


## Overview:

A relational knowledge base framework for GNU Guile using simple tools for
constructing rule based systems using relational databases.


## Dependencies:

* GNU Guile - ver 2.0. or newer ( https://www.gnu.org/software/guile/ )

* guile-dbi - ( https://github.com/eestrada/guile-dbi )

* guile-dbd-sqlite3 - ( https://github.com/eestrada/guile-dbi )

* Sqlite3 - ( https://www.sqlite.org/index.html )

* grsp - https://github.com/PESchoenberg/grsp.git


## Installation:

* Assuming that you already have the requisite software running on your system,
get gexsys, unpack it into a folder of your choice and cd into it.

* gexsys installs as a GNU Guile library. See GNU Guile's manual instructions
for details concerning your OS and distribution, but as an example, on Ubuntu
you would issue:

    sudo mkdir /usr/share/guile/site/2.0/gexsys

    sudo cp *.scm -rv /usr/share/guile/site/2.0/gexsys

    or

    sudo cp *.scm -rv /usr/local/share/guile/site/2.2/gexsys

and that will do the trick.


## Uninstall:

* You just need to remove /usr/share/guile/site/2.0/gexsys and its subfolders.

* If you would like to uninstall guile-dbi, you should read the specific
docs for that package.


## Usage:

* Should be used as any other GNU Guile library.

* See the examples contained in the /examples folder. These are self-explaining
and filled with comments.


## Credits and Sources:

* GNU Guile - https://www.gnu.org/software/guile/ (LGPL-3.0 or later).

* guile-dbi - https://github.com/eestrada/guile-dbi (no license provided at present).

* Sqlite.org - https://www.sqlite.org/index.html (public domain).

* URL of this project - https://github.com/PESchoenberg/gexsys.git

Please let me know if I forgot to add any credits or sources.


## License:

* LGPL-3.0-or-later.


