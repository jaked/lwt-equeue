-include ../Makefile.conf

DIRS=relay

ifeq ($(HAS_COHTTPSERVER),1)
DIRS += cohttpserver
endif

ifeq ($(HAS_DELIMCC),1)
DIRS += fiber
endif

all:
	for dir in $(DIRS); do \
		$(MAKE) -C $$dir all || exit; \
	done

clean:
	for dir in $(DIRS); do \
		$(MAKE) -C $$dir clean || exit; \
	done
