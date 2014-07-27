all: concatSubs wkmeans fastsubs scode perl python dists

### Reprository Check-out Commands
## If the latest version is required then do not set the corresponding
## tag variable.

## DISTS
WKMEANS_GIT_REPO=git://github.com/ai-ku/wkmeans.git
## DISTS
DIST_GIT_REPO=git://github.com/ai-ku/dist.git
## SCODE
SCODE_GIT_REPO=git://github.com/ai-ku/scode.git
## FASTSUBS
FASTSUBS_GIT_REPO=https://github.com/ai-ku/fastsubs.git
###

wkmeans: check
	test -e ../src/wkmeans || (cd ../src/ ; git clone ${WKMEANS_GIT_REPO}) 
	cd ../src/wkmeans; make
	test -e $@ || ln -s ../src/wkmeans/wkmeans .

dists: check
	test -e ../src/dist || (cd ../src/ ; git clone ${DIST_GIT_REPO}) 
	cd ../src/dist; make
	test -e $@ || ln -s ../src/dist/dists .
fastsubs: check

	test -e ../src/fastsubs || (cd ../src/ ; git clone ${FASTSUBS_GIT_REPO}) 
	cd ../src/fastsubs; make
	test -e $@ || ln -s ../src/fastsubs/fastsubs .
	test -e wordsub || ln -s ../src/fastsubs/wordsub .
	test -e wordsub-n || ln -s ../src/fastsubs/wordsub-n .
	test -e fastsubs-omp || ln -s ../src/fastsubs/fastsubs-omp .

scode: check
	test -e ../src/scode || (cd ../src/ ; git clone ${SCODE_GIT_REPO})
	cd ../src/scode; make
	test -e $@ || ln -s ../src/scode/scode ../src/scode/scode-online .

concatSubs: check
	test -e ../src/concatSubs || g++ -O3 -o ../src/concatSubs ../src/concatSubs.cpp -lm
	ln -s ../src/concatSubs .
perl: check
	test -e `ls *.pl`  || ls *.pl | xargs -I '{}' unlink '{}'
	ln -s ../src/*.pl .

python: check
	test -e `ls *.py` || ls *.py | xargs -I '{}' unlink '{}'
	ln -s ../src/*.py .
check:
	true

clean:
	find . -type l | xargs -I '{}' rm -f '{}'
	rm -rf ../src/scode ../src/fastsubs ../src/dist ../src/wkmeans ../src/concatSubs
