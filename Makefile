PYTHON_VERSION = 2.7.3
PYWIN32_VERSION = 218
PYGAME_VERSION = 1.9.1
PYINSTALLER_VERSION = 2.0

PYINSTALLER=tools/pyinstaller-${PYINSTALLER_VERSION}/pyinstaller.py
PYTHON_EXE=~/.wine/drive_c/Python27/python.exe
PYWIN32=pywin32-${PYWIN32_VERSION}.win32-py2.7.exe
PYGAME_MSI=pygame-${PYGAME_VERSION}.win32-py2.7.msi

WINE_PATH = ~/.wine/drive_c

ifeq "Darwin" "$(shell uname)"
PYTHON=arch -i386 python
PYTHON=python2.7-32
else
PYTHON=python
endif

OK=\033[32m[OK]\033[39m
FAIL=\033[31m[FAIL]\033[39m
CHECK=@if [ $$? -eq 0 ]; then echo "${OK}"; else echo "${FAIL}"; cat ${DEBUG} ; fi

WGET = wget 

PYTHON_SOURCES = ${shell find gameproto -type f -iname '*.py'}
PYTHON_COMPILED = $(patsubst %.py,%.pyc, ${PYTHON_SOURCES})

VIRTUALENV_DIR=venv

VIRTUALENV=. ${VIRTUALENV_DIR}/bin/activate;

default: run

${VIRTUALENV_DIR}/bin/activate:
	test -d venv || virtualenv venv --system-site-packages && touch $@

venv: ${VIRTUALENV_DIR}/bin/activate

.requirements.txt.check: ${VIRTUALENV_DIR}/bin/activate requirements.txt
	@${VIRTUALENV} pip install -r requirements.txt && \
		touch $@

%.pyc: %.py
	${VIRTUALENV} ${PYTHON} -m py_compile $<

external:
	@echo "Creating external dir: \c"
	@mkdir -p external
	${CHECK}

deps/.done:
	@echo "Creating dependencies dir: \c"
	@mkdir -p deps
	@touch $@
	${CHECK}

tools/.done:
	@echo "Creating tools dir: \c"
	@mkdir -p tools
	@touch $@
	${CHECK}

deps/pyinstaller-${PYINSTALLER_VERSION}.zip: deps/.done
	@cd deps && \
		${WGET} http://sourceforge.net/projects/pyinstaller/files/${PYINSTALLER_VERSION}/pyinstaller-${PYINSTALLER_VERSION}.zip
	@touch $@


deps/python-${PYTHON_VERSION}.msi: deps/.done
	@cd deps && \
		${WGET} http://www.python.org/ftp/python/${PYTHON_VERSION}/python-${PYTHON_VERSION}.msi
	@touch $@

${PYTHON_EXE}: deps/python-${PYTHON_VERSION}.msi
	@cd deps && \
		msiexec /i python-${PYTHON_VERSION}.msi /qb
	@touch $@

${WINE_PATH}/Python27/msvcp90.dll: ${WINE_PATH}/windows/system32/msvcp90.dll
	@cp $< $@

deps/${PYWIN32}: deps/.done
	echo http://downloads.sourceforge.net/project/pywin32/pywin32/Build\%20${PYWIN32_VERSION}/${PYWIN32}
	@cd deps && \
		${WGET} http://downloads.sourceforge.net/project/pywin32/pywin32/Build\%20${PYWIN32_VERSION}/${PYWIN32}
	@touch $@

deps/pywin32.installed: ${PYTHON_EXE} ${WINE_PATH}/Python27/msvcp90.dll deps/${PYWIN32}
	@cd deps && \
		wine ${PYWIN32}
	@touch $@

deps/${PYGAME_MSI}: deps/.done
	@cd deps && \
		${WGET} http://pygame.org/ftp/${PYGAME_MSI}
	@touch $@

deps/pygame.installed: ${PYTHON_EXE} deps/${PYGAME_MSI}
	@cd deps && \
		msiexec /i ${PYGAME_MSI} /qb
	@touch $@

${PYINSTALLER}: tools/.done deps/pyinstaller-2.0.zip
	@echo "Unzipping PyInstaller ${PYINSTALLER_VERSION}: \c"
	@cd tools && \
		unzip ../deps/pyinstaller-2.0.zip
	@touch $@

build_tools: tools/pyinstaller-${PYINSTALLER_VERSION}/pyinstaller.py

dependencies: .requirements.txt.check

build: dependencies ${PYTHON_COMPILED}

test: build
	#@nosetests

run: test
	${VIRTUALENV} ${PYTHON} gameproto/test.py

dist/darwin/gameproto: ${PYINSTALLER}
	${PYTHON} -O ${PYINSTALLER} --onedir  gameproto.darwin.spec

dist/linux/gameproto: ${PYINSTALLER}
	${PYTHON} -O ${PYINSTALLER} --onedir  gameproto.linux.spec

dist/windows/gameproto: ${PYINSTALLER} deps/pywin32.installed deps/pygame.installed
	wine ${PYTHON_EXE} ${PYINSTALLER} --onefile gameproto.windows.spec

dist/test: ${PYINSTALLER}
	${PYTHON} -O ${PYINSTALLER} --onefile test.spec

dist/test.exe: ${PYINSTALLER} deps/pywin32.installed deps/pygame.installed
	wine ${PYTHON_EXE} ${PYINSTALLER} --onefile test.spec

dist: dist/windows/gameproto

clean:
	@rm -rf tools
	@rm -rf reports

purge: clean
	@rm -rf deps
	@rm -rf ${VIRTUALENV_DIR}

.PHONY: clean run dist report
