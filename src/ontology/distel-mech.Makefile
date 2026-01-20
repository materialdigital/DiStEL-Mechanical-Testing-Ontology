## Customize Makefile settings for distel
## 
## If you need to customize your Makefile, make
## changes here rather than in the main Makefile
## Customize Makefile settings for distel


PMDCO_DISJOINTNESS_REMOVAL_TERMS = $(IMPORTDIR)/pmdco_remove_disjoint.txt
IAO_TO_REMOVE = $(IMPORTDIR)/iao_to_remove.txt
PMDCO_CLASSES_TO_REMOVE = $(IMPORTDIR)/pmdco_classes_to_remove.txt


# Import TTO classes preserving subclass hierarchy to PMDco
$(IMPORTDIR)/tto_import.owl: $(MIRRORDIR)/tto.owl $(IMPORTDIR)/tto_terms.txt $(IMPORTSEED) | all_robot_plugins

	$(ROBOT) annotate --input $< --remove-annotations \
			odk:normalize --add-source true \
			extract --term-file $(IMPORTDIR)/tto_terms.txt \
						--force true \
						--copy-ontology-annotations true \
						--individuals exclude \
						--intermediates all \
						--method BOT \
			remove --term-file $(IAO_TO_REMOVE) \
				   --select "individuals classes"\
			remove --select individuals \
			\
			remove --term http://purl.obolibrary.org/obo/IAO_0000412 \
					--select annotation \
			odk:normalize --base-iri https://w3id.org/pmd/distel \
							--subset-decls true --synonym-decls true \
			annotate --ontology-iri $(ONTBASE)/$@ $(ANNOTATE_ONTOLOGY_VERSION) \
			convert -f owl --output $@.tmp.owl && mv $@.tmp.owl $@


$(IMPORTDIR)/pmdco_import.owl: $(MIRRORDIR)/pmdco.owl $(IMPORTDIR)/pmdco_terms.txt
	@echo "Generating Application Module from pmdco..."
	if [ $(IMP) = true ]; then $(ROBOT) \
	  query -i $< --update ../sparql/preprocess-module.ru \
	  extract --term-file $(IMPORTDIR)/pmdco_terms.txt \
	          --force true \
	          --copy-ontology-annotations true \
	          --intermediates all \
	          --method BOT \
	  \
	  query --update ../sparql/inject-subset-declaration.ru \
	        --update ../sparql/inject-synonymtype-declaration.ru \
	        --update ../sparql/postprocess-module.ru \
	  \
	  remove --term http://purl.obolibrary.org/obo/IAO_0000412 \
             --select annotation \
	  \
	  remove --term-file $(PMDCO_DISJOINTNESS_REMOVAL_TERMS) \
			 --axioms DisjointClasses \
	  remove --term-file $(PMDCO_CLASSES_TO_REMOVE) \
			 --select "classes"\
	  remove --term-file $(IAO_TO_REMOVE) \
			 --select "individuals classes"\
	  $(ANNOTATE_CONVERT_FILE); \
	fi


$(IMPORTDIR)/uo_import.owl: $(MIRRORDIR)/uo.owl $(IMPORTDIR)/uo_terms.txt
	$(ROBOT) filter --input $(MIRRORDIR)/uo.owl \
		--term-file $(IMPORTDIR)/uo_terms.txt \
		--allow-punning true \
		--select "annotations self parents" \
		$(ANNOTATE_CONVERT_FILE)

$(IMPORTDIR)/obi_import.owl: $(MIRRORDIR)/obi.owl $(IMPORTDIR)/obi_terms.txt \
			   $(IMPORTSEED) | all_robot_plugins
	$(ROBOT) annotate --input $< --remove-annotations \
		 odk:normalize --add-source true \
		 extract --term-file $(IMPORTDIR)/obi_terms.txt $(T_IMPORTSEED) \
		         --force true --copy-ontology-annotations true \
		         --individuals exclude \
		         --method SUBSET \
		 remove --term IAO:0000416 \
		 remove $(foreach p, $(ANNOTATION_PROPERTIES), --term $(p)) \
		        --term-file $(IMPORTDIR)/obi_terms.txt $(T_IMPORTSEED) \
		        --select complement --select annotation-properties \
		 odk:normalize --base-iri https://w3id.org/pmd \
		               --subset-decls true --synonym-decls true \
		 repair --merge-axiom-annotations true \
		 $(ANNOTATE_CONVERT_FILE)


#.PHONY: autoshapes
#autoshapes: 
#	echo "please run manually: sh utils/generate-auto-shapes.sh"



$(ONT)-base.owl: $(EDIT_PREPROCESSED) $(OTHER_SRC) $(IMPORT_FILES)
	$(ROBOT_RELEASE_IMPORT_MODE) \
	reason --reasoner ELK --equivalent-classes-allowed asserted-only --exclude-tautologies structural --annotate-inferred-axioms False \
	relax \
	reduce -r ELK \
	remove --base-iri $(URIBASE)/ --axioms external --preserve-structure false --trim false \
	$(SHARED_ROBOT_COMMANDS) \
	annotate --link-annotation http://purl.org/dc/elements/1.1/type http://purl.obolibrary.org/obo/IAO_8000001 \
		--ontology-iri $(ONTBASE)/$@ $(ANNOTATE_ONTOLOGY_VERSION) \
		--output $@.tmp.owl && mv $@.tmp.owl $@


CITATION=distel-mech: DiStEL Mechanical Testing Ontology. Version $(VERSION), https://w3id.org/pmd/distel/

ALL_ANNOTATIONS=--ontology-iri https://w3id.org/pmd/distel/ -V https://w3id.org/pmd/distel/$(VERSION) \
	--annotation http://purl.org/dc/terms/created "$(TODAY)" \
	--annotation owl:versionInfo "$(VERSION)" \
	--annotation http://purl.org/dc/terms/bibliographicCitation "$(CITATION)" \
	--link-annotation owl:priorVersion https://w3id.org/pmd/distel/$(PRIOR_VERSION)

update-ontology-annotations: 
	$(ROBOT) annotate --input distel-mech.owl $(ALL_ANNOTATIONS) --output ../../distel-mech.owl
	$(ROBOT) annotate --input distel-mech.ttl $(ALL_ANNOTATIONS) --output ../../distel-mech.ttl
	$(ROBOT) annotate --input distel-mech-full.owl $(ALL_ANNOTATIONS) --output ../../distel-mech-full.owl
	$(ROBOT) annotate --input distel-mech-full.ttl $(ALL_ANNOTATIONS) --output ../../distel-mech-full.ttl
	$(ROBOT) annotate --input distel-mech-base.owl $(ALL_ANNOTATIONS) --output ../../distel-mech-base.owl
	$(ROBOT) annotate --input distel-mech-base.ttl $(ALL_ANNOTATIONS) --output ../../distel-mech-base.ttl
	@if [ -f distel-mech-simple.owl ]; then $(ROBOT) annotate --input distel-mech-simple.owl $(ALL_ANNOTATIONS) --output ../../distel-mech-simple.owl; fi

all_assets: update-ontology-annotations
