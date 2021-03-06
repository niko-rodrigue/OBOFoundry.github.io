# All ontology .md files
ONTS := $(wildcard ontology/*md)

# All principles .md file
PRINCIPLES := $(wildcard principles/*md)

all: _config.yml registry/ontologies.yml

test: validate all

integration-test: test valid-purl-report.txt

t:
	echo $(ONTS)


# Create the site-wide config file by combining all metadata on ontologies + principles
#  and combining with site-wide metadata.
#
# Note that anything in _config.yml is accessible to any liquid template via the
# `sites` object - think of it like the global database
#
# (this is somewhat hacky, but concatenating these yamls is safe)
_config.yml: _config_header.yml registry/ontologies.yml principles/all.yml
	cat $^ > $@.tmp && mv $@.tmp $@

# Extract metadata from each ontology .md file and combine into single yaml
registry/ontologies.yml: $(ONTS)
	./util/extract-metadata.py concat -o $@.tmp $^  && mv $@.tmp $@

# Extract the metadata from each principle in the principles/ directory, and concatenate
# into a single yaml file in that directory
principles/all.yml: $(PRINCIPLES)
	./util/extract-metadata.py concat-principles -o $@.tmp $^  && mv $@.tmp $@

# TODO: add @context
registry/ontologies.jsonld: registry/ontologies.yml
	./util/yaml2json.py $< > $@.tmp && mv $@.tmp $@

# TODO
registry/ontologies.ttl: registry/ontologies.jsonld
	riot registry/context.jsonld $< > $@.tmp && mv $@.tmp $@


validate: $(ONTS)
	./util/extract-metadata.py validate $^

# Note this should *not* be run as part of general travis jobs, it is expensive
# and may be prone to false positives as it is inherently network-based
#
# TODO: Other non-travis CI job. Nightly?
# TODO: Integrate this with some kind of OCLC query check
#
# See: https://github.com/OBOFoundry/OBOFoundry.github.io/issues/18
valid-purl-report.txt: registry/ontologies.yml
	./util/processor.py -i $< check-urls > $@.tmp && mv $@.tmp $@
