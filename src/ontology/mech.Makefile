## Customize Makefile settings for mech
## 
## If you need to customize your Makefile, make
## changes here rather than in the main Makefile
## Customize Makefile settings for mech


PMDCO_DISJOINTNESS_REMOVAL_TERMS = $(IMPORTDIR)/pmdco_remove_disjoint.txt
IAO_TO_REMOVE = $(IMPORTDIR)/iao_to_remove.txt
PMDCO_CLASSES_TO_REMOVE = $(IMPORTDIR)/pmdco_classes_to_remove.txt


# Import TTO classes preserving subclass hierarchy to PMDco
#$(IMPORTDIR)/tto_import.owl: $(MIRRORDIR)/tto.owl $(IMPORTDIR)/tto_terms.txt $(IMPORTSEED) | all_robot_plugins
#
#	$(ROBOT) annotate --input $< --remove-annotations \
#			odk:normalize --add-source true \
#			extract --term-file $(IMPORTDIR)/tto_terms.txt \
#						--force true \
#						--copy-ontology-annotations true \
#						--individuals exclude \
#						--intermediates all \
#						--method BOT \
#			remove --term-file $(IMPORTDIR)/tto_remove_parent.txt \
#					--select "ancestors" \
#					--trim false \
#			remove --select "complement" --select "named" --trim true \
#			remove --term-file $(IAO_TO_REMOVE) \
#				   --select "individuals classes"\
#			remove --term-file $(IMPORTDIR)/tto_to_remove.txt \
#				   --select "classes"\
#			remove --select individuals \
#			odk:normalize --base-iri https://w3id.org/pmd/mech \
#							--subset-decls true --synonym-decls true \
#			remove --term http://purl.obolibrary.org/obo/IAO_0000412 \
#					--select annotation \
#			annotate --ontology-iri $(ONTBASE)/$@ $(ANNOTATE_ONTOLOGY_VERSION) \
#			convert -f owl --output $@.tmp.owl && mv $@.tmp.owl $@

$(IMPORTDIR)/tto_import.owl: $(MIRRORDIR)/tto.owl $(IMPORTDIR)/tto_terms.txt $(IMPORTSEED) | all_robot_plugins
	@echo "Generating import module from private TTO mirror..."
	$(ROBOT) annotate --input $< --remove-annotations \
			odk:normalize --add-source true \
			extract --term-file $(IMPORTDIR)/tto_terms.txt \
						--force true \
						--copy-ontology-annotations true \
						--individuals exclude \
						--intermediates all \
						--method BOT \
			remove --term "https://w3id.org/pmd/co/relatesTo" \
				   --select "self" \
				   --trim true \
			odk:normalize --base-iri https://w3id.org/pmd/mech \
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


$(IMPORTDIR)/qudt_import.owl: $(MIRRORDIR)/qudt.owl $(IMPORTDIR)/qudt_terms.txt
	$(ROBOT) filter --input $(MIRRORDIR)/qudt.owl \
		--term-file $(IMPORTDIR)/qudt_terms.txt \
		--allow-punning true \
		--select "annotations self" \
		$(ANNOTATE_CONVERT_FILE)

$(IMPORTDIR)/vto_import.owl: $(MIRRORDIR)/vto.owl $(IMPORTDIR)/vto_terms.txt $(IMPORTSEED) | all_robot_plugins
	@echo "Generating import module from VTO mirror..."
	$(ROBOT) annotate --input $< --remove-annotations \
			odk:normalize --add-source true \
			extract --term-file $(IMPORTDIR)/vto_terms.txt \
						--force true \
						--copy-ontology-annotations true \
						--intermediates all \
						--method TOP \
						--individuals exclude \
			remove --term "https://w3id.org/pmd/co/relatesTo" \
				   --select "self" \
				   --trim true \
			odk:normalize --base-iri https://w3id.org/pmd/mech \
							--subset-decls true --synonym-decls true \
			annotate --ontology-iri $(ONTBASE)/$@ $(ANNOTATE_ONTOLOGY_VERSION) \
			convert -f owl --output $@.tmp.owl && mv $@.tmp.owl $@

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

$(IMPORTDIR)/iao_import.owl: $(MIRRORDIR)/iao.owl $(IMPORTDIR)/iao_terms.txt
	if [ $(IMP) = true ]; then $(ROBOT) query -i $< --update ../sparql/preprocess-module.ru \
		remove --select "IAO:*" --select complement --select "classes object-properties data-properties"  --axioms annotation \
		extract --term-file $(IMPORTDIR)/iao_terms.txt  --force true --copy-ontology-annotations true --individuals exclude --intermediates none --method BOT \
		query --update ../sparql/inject-subset-declaration.ru --update ../sparql/inject-synonymtype-declaration.ru --update ../sparql/postprocess-module.ru \
 		remove --term IAO:0000032 --axioms subclass \
 		remove $(foreach p, $(ANNOTATION_PROPERTIES), --term $(p)) \
		      --select complement --select annotation-properties \
		$(ANNOTATE_CONVERT_FILE); fi


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


CITATION=mech: Mechanical Testing Ontology. Version $(VERSION), https://w3id.org/pmd/mech/

ALL_ANNOTATIONS=--ontology-iri https://w3id.org/pmd/mech/ -V https://w3id.org/pmd/mech/$(VERSION) \
	--annotation http://purl.org/dc/terms/created "$(TODAY)" \
	--annotation owl:versionInfo "$(VERSION)" \
	--annotation http://purl.org/dc/terms/bibliographicCitation "$(CITATION)" \
	--link-annotation owl:priorVersion https://w3id.org/pmd/mech/$(PRIOR_VERSION)

update-ontology-annotations: 
	$(ROBOT) annotate --input mech.owl $(ALL_ANNOTATIONS) --output ../../mech.owl
	$(ROBOT) annotate --input mech.ttl $(ALL_ANNOTATIONS) --output ../../mech.ttl
	$(ROBOT) annotate --input mech-full.owl $(ALL_ANNOTATIONS) --output ../../mech-full.owl
	$(ROBOT) annotate --input mech-full.ttl $(ALL_ANNOTATIONS) --output ../../mech-full.ttl
	$(ROBOT) annotate --input mech-base.owl $(ALL_ANNOTATIONS) --output ../../mech-base.owl
	$(ROBOT) annotate --input mech-base.ttl $(ALL_ANNOTATIONS) --output ../../mech-base.ttl
	@if [ -f mech-simple.owl ]; then $(ROBOT) annotate --input mech-simple.owl $(ALL_ANNOTATIONS) --output ../../mech-simple.owl; fi

all_assets: update-ontology-annotations
