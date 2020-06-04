#!/bin/bash

current_path=`pwd`
current_dir=`basename "$current_path"`


if [ ! -d liblbfgs-1.10 ]; then
    echo Installing libLBFGS library to support MaxEnt LMs
    bash ./install_liblbfgs.sh || exit 1
fi


! which gawk 2>/dev/null && \
   echo "GNU awk is not installed so SRILM will probably not work correctly: refusing to install" && exit 1;

# set the SRILM variable in the top-level Makefile to this directory.
cp Makefile tmpf

cat tmpf | awk -v pwd=`pwd` '/SRILM =/{printf("SRILM = %s\n", pwd); next;} {print;}' \
  > Makefile || exit 1;

mtype=`sbin/machine-type`

echo HAVE_LIBLBFGS=1 >> common/Makefile.machine.$mtype
grep ADDITIONAL_INCLUDES common/Makefile.machine.$mtype | \
    sed 's|$| -I$(SRILM)/../liblbfgs-1.10/include|' \
    >> common/Makefile.machine.$mtype

grep ADDITIONAL_LDFLAGS common/Makefile.machine.$mtype | \
    sed 's|$| -L$(SRILM)/../liblbfgs-1.10/lib/ -Wl,-rpath -Wl,$(SRILM)/../liblbfgs-1.10/lib/|' \
    >> common/Makefile.machine.$mtype



make || exit 1

cd ..
(
  [ ! -z "${SRILM}" ] && \
    echo >&2 "SRILM variable is aleady defined. Undefining..." && \
    unset SRILM

  [ -f ./env.sh ] && . ./env.sh

  [ ! -z "${SRILM}" ] && \
    echo >&2 "SRILM config is already in env.sh" && exit

  wd=`pwd`
  wd=`readlink -f $wd || pwd`

  echo "export SRILM=$wd/srilm"
  dirs="\${PATH}"
  for directory in $(cd srilm && find bin -type d ) ; do
    dirs="$dirs:\${SRILM}/$directory"
  done
  echo "export PATH=$dirs"
) >> env.sh

echo >&2 "Installation of SRILM finished successfully"
echo >&2 "Please source the tools/env.sh in your path.sh to enable it"

