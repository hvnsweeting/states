all:
	lint doc

doc:
	./doc/build.py

lint:
	./test/lint.py
