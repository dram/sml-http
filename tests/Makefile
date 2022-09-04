.PHONY: all clean

all:
	sml -m main.cm
	sml @SMLload main.`sml @SMLsuffix`

clean:
	rm -r .cm/ main.`sml @SMLsuffix`
