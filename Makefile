build:
	./node_modules/.bin/coffee -b -c -o lib src

watch:
	./node_modules/.bin/coffee -w -b -c -o lib src

test: build mocha

mocha:
	@NODE_ENV=test ./node_modules/.bin/mocha \
	--reporter nyan \
	--compilers coffee:coffee-script \
	--check-leaks \
	--slow 20 \
	tests

.PHONY: build watch test mocha
