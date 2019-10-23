include Makefile.cfg

PROFILE?=reldebug
ROS_DISTRO?=`ls /opt/ros/`
EMAIL?=XXX_email_unset_XXX
AUTHOR?=XXX_author_unset_XXX


PKG?=XXX_package_name_unset_XXX
ROSCONSOLE_FORMAT=[$${severity}] [$${time}] [$${node}]: $${message}
PRELOAD_SCRIPT=source /opt/ros/${ROS_DISTRO}/setup.bash
LOCAL_PRELOAD_SCRIPT=source ./devel/${PROFILE}/setup.bash
ARGS?=
#ARGS=--bump minor

CMAKE_COMMON_FLAGS=-DCMAKE_CXX_COMPILER_LAUNCHER=ccache -DCMAKE_CXX_FLAGS=-fdiagnostics-color

##
## Default target (build)
##

default: build
.DEFAULT:
	${MAKE} PKG=$@


##
## Workspace targets
##

# Add catkin profile
wsaddprofile:
	catkin profile add ${PROFILE}
	catkin config --profile ${PROFILE} --log-space logs/${PROFILE} \
                                       --build-space build/${PROFILE} \
                                       --devel-space devel/${PROFILE} \
                                       --install-space install/${PROFILE} \
                                       --cmake-args ${CMAKE_ARGS}

# Reset & initialize workspace
wsinit: wspurge
	mkdir -p src
	catkin init
	cd src; wstool init
	${MAKE} wsaddprofile PROFILE=debug CMAKE_ARGS="-DCMAKE_BUILD_TYPE=Debug ${CMAKE_COMMON_FLAGS}"
	${MAKE} wsaddprofile PROFILE=reldebug CMAKE_ARGS="-DCMAKE_BUILD_TYPE=RelWithDebInfo ${CMAKE_COMMON_FLAGS}"

# Status packages in the workspace
wsstatus:
	git status
	cd src; wstool info


# Add new packages to the workspace
wsscrape:
	cd src; wstool scrape

# Update workspace & all packages
wsupdate:
	git pull
	${MAKE} wsupdate_pkgs

# Update workspace & all packages
wsupdate_pkgs:
	cd src; wstool update -j4 --continue-on-error


# Clean workspace
wsclean:
	rm -Rf build*
	rm -Rf devel*
	rm -Rf install*
	rm -Rf logs*
	rm -Rf src/.rosinstall.bak
	rm -Rf .catkin_tools/profiles/*/packages/


# Purge workspace (delete catkin configuration)
wspurge: wsclean
	rm -Rf .catkin_tools
	rm -Rf src


##
## Package targets
##


build:
	bash -c "${PRELOAD_SCRIPT}; catkin build \
		--verbose \
		--summary \
		--profile ${PROFILE} \
		-i \
		${ARGS} \
		${PKG}"
	echo 'export ROSCONSOLE_FORMAT='\''${ROSCONSOLE_FORMAT}'\''' >> devel/${PROFILE}/setup.bash

test: #-j 1
	bash -c "${LOCAL_PRELOAD_SCRIPT}; roscd ${PKG}; \
		catkin build \
			--profile ${PROFILE} \
			--verbose \
			--no-deps \
			--this \
			-i \
			${ARGS} \
			--make-args run_tests"
	${MAKE} showtestresults

showtestresults:
	bash -c "${LOCAL_PRELOAD_SCRIPT}; catkin_test_results ./build/${PROFILE}/${PKG}"


install:
	bash -c "${LOCAL_PRELOAD_SCRIPT}; roscd ${PKG}; \
		catkin build \
			--profile ${PROFILE} \
			--verbose \
			--no-deps \
			--this \
			-i \
			${ARGS} \
			--make-args install"


changelognew:
	${MAKE} changelog ARGS=--all

changelog: assert_committed assert_release_valid_branch # ARGS=--all
	bash -c '${LOCAL_PRELOAD_SCRIPT}; roscd ${PKG}; cd `git rev-parse --show-toplevel`; \
		catkin_generate_changelog ${ARGS}; \
		git add `find ./ -name "CHANGELOG.rst" -printf "%h/%f "`; \
		git commit -a -m "Updated changelog"'

preprelease:
	bash -c '${LOCAL_PRELOAD_SCRIPT}; roscd ${PKG}; cd `git rev-parse --show-toplevel`; \
		catkin_prepare_release ${ARGS}'

release:
	${MAKE} changelog
	${MAKE} preprelease

releasenew:
	${MAKE} changelognew
	${MAKE} preprelease


doxall:
	catkin document \
		--profile ${PROFILE} \
		--no-deps

dox:
	catkin document \
		--profile ${PROFILE} \
		--no-deps \
		${PKG}

assert_committed:
	@echo "Checking for uncommitted modifications..."
	@bash -c '${LOCAL_PRELOAD_SCRIPT}; roscd ${PKG}; pwd; test -z `git status --porcelain`'

assert_release_valid_branch:
	@echo "Checking for proper branch..."
	@bash -c '${LOCAL_PRELOAD_SCRIPT}; roscd ${PKG}; pwd; test -z `git rev-parse --abbrev-ref HEAD | grep -v -e "master" -e "\-devel"`'


depends:
	bash -c "${LOCAL_PRELOAD_SCRIPT}; roscd ${PKG};  catkin list --rdeps --profile ${PROFILE} --this"
#	cd src/${PKG}/; catkin list --rdeps --profile ${PROFILE} --this


rosdep:
	#cd rosdep; wstool update -j4
	#cd rosdep; ./release_scripts/configure_rosdep.sh
	bash -c "${PRELOAD_SCRIPT}; rosdep install --from-paths src --ignore-src --rosdistro=ROS_DISTRO -y"


new:
	mkdir -p src/${PKG}/include/${PKG}
	bash -c "${PRELOAD_SCRIPT}; \
		catkin create pkg 	-p src/ \
							-v 0.0.0 \
							-l 'proprietary' \
                         	-m '${AUTHOR}' '${EMAIL}' \
							${PKG}"
	cd src/${PKG}; git init


clean:
	bash -c "${PRELOAD_SCRIPT}; rosclean purge"
	catkin clean \
		--profile ${PROFILE} \
		${PKG}


##
## Other targets
##

help:
	@grep -v "^	" Makefile | grep -v "^ " | grep -v "^$$" | grep -v "^\."

.PHONY: build clean test rosdep install
