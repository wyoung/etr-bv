VERSION := 0.2.0
DISTFILES := etr-bv.R LICENSE GNUmakefile
DISTDIR := etr-bv-$(VERSION)

dist:
	mkdir -p $(DISTDIR) tarballs
	cp $(DISTFILES) $(DISTDIR)
	tar cvjf tarballs/$(DISTDIR).tar.bz2 $(DISTDIR)
	rm -rf $(DISTDIR)
