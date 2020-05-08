DOCS := site/autosecret/REFERENCE.md site/ud/REFERENCE.md

all : docs

docs : $(DOCS)

$(DOCS) : %/REFERENCE.md :
	cd $* && puppet strings generate --format markdown --out $(notdir $@)

.PHONY : $(DOCS)
