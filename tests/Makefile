.PHONY: all clean

all:
	ml-build main.cm Tests.main
	sml @SMLload main.`sml @SMLsuffix`

clean:
	rm -r .cm/ main.`sml @SMLsuffix`
