#!/bin/bash

source "$HOME/.bashrc"
source /ALL/Downloads/envvars.sh

# provide defaults
export OUR_IMAGE=${OUR_IMAGE:-ghcr.io/t3docs/render-documentation}
export OUR_IMAGE_SHORT=${OUR_IMAGE_SHORT:-t3rd}
export OUR_IMAGE_SLOGAN=${OUR_IMAGE_SLOGAN:-dockrun_t3rd - TYPO3-render-documentation}

export mmLOGFILE=/RESULT/within-container-command-history.log.txt

function install-wheels(){
   find /WHEELS -type f -name "*.whl" | xargs --no-run-if-empty pip --disable-pip-version-check install --force --no-cache-dir
   find /WHEELS/ -name "*.whl" -exec pip freeze \; -quit
}

function utcstamp(){
    printf '%s' $(date -u +"%Y-%m-%dT%H:%M:%S%z")
}

function mm-bashcmd() {
   local cmd
   shift
   cmd="/bin/bash -c"
   if [ -z "$@" ]; then false
   else
      cmd="$cmd"$(printf ' %q' "$@")
   fi
   echo $(utcstamp) "${cmd}" >>"$mmLOGFILE"
   eval "${cmd}"
   local exitstatus="$?"
   tell-about-results "$exitstatus"
}


function mm-minimalhelp(){
   cat <<EOT
$OUR_IMAGE_SLOGAN (${OUR_IMAGE_TAG}, ${OUR_IMAGE_VERSION})
For help:
   docker run --rm $OUR_IMAGE --help

   # or, if you defined the helper function:
   ${DOCKRUN_PREFIX}$OUR_IMAGE_SHORT --help

... did you mean '${DOCKRUN_PREFIX}$OUR_IMAGE_SHORT makehtml'?

See manual: https://t3docs.github.io/DRC-The-Docker-Rendering-Container/

EOT
}


function mm-usage() {
   cat <<EOT
Usage:
    Prepare:
        Define function '${DOCKRUN_PREFIX}$OUR_IMAGE_SHORT' on the command line of your system.
        It will help running Docker with the correct parameters and mappings:
            eval "\$(docker run --rm $OUR_IMAGE show-shell-commands)"
        If you like to, use 'declare' to inspect the function:
            declare -f ${DOCKRUN_PREFIX}${OUR_IMAGE_SHORT}
    Usage:
        ${DOCKRUN_PREFIX}$OUR_IMAGE_SHORT [ARGUMENT]
            ARGUMENT             DESCRIPTION
            --help               Show this menu
            --version            Show buildinfo.txt of this container
            makeall              Create all output formats
            makeall-no-cache     Remove cache first, then create all
            makehtml             Create HTML output
            makehtml-no-cache    Remove cache first, then build HTML
            show-shell-commands  Show useful shell commands and functions
            show-windows-bat     Show file 'dockrun_t3rd.bat' for Windows
            show-howto           Show howto (not totally up to date)
            show-faq             Show questions and answers (not totally up to date)
            bashcmd              Run a bash command in the container
            just1sphinxbuild     Run the container for just one 'sphinx-build' command
            serve4build [port]   Run container as server for 'sphinx-build'
            /bin/bash            Enter the container's Bash shell as superuser
            /usr/bin/bash        Enter the container's Bash shell as normal user
            export-ALL           Copy /ALL to /RESULT/ALL-exported
            tct                  Run TCT, the toolchain runner

            Without argument minimal help is shown.

    Examples:
        ${DOCKRUN_PREFIX}$OUR_IMAGE_SHORT           # show minimal help
        ${DOCKRUN_PREFIX}$OUR_IMAGE_SHORT --help
        ${DOCKRUN_PREFIX}$OUR_IMAGE_SHORT export-ALL
        ${DOCKRUN_PREFIX}$OUR_IMAGE_SHORT makeall-no-cache
        ${DOCKRUN_PREFIX}$OUR_IMAGE_SHORT makehtml
        ${DOCKRUN_PREFIX}$OUR_IMAGE_SHORT bashcmd 'ls -la /ALL'
        ${DOCKRUN_PREFIX}$OUR_IMAGE_SHORT /bin/bash
        ${DOCKRUN_PREFIX}$OUR_IMAGE_SHORT /usr/bin/bash
        ${DOCKRUN_PREFIX}$OUR_IMAGE_SHORT serve4build 9999
        ${DOCKRUN_PREFIX}$OUR_IMAGE_SHORT just1sphinxbuild
        T3DOCS_DEBUG=1 ${DOCKRUN_PREFIX}$OUR_IMAGE_SHORT [...]


End of usage.
EOT
}


function mm-version() {
   cat /ALL/Downloads/buildinfo.txt
}


function mm-show-howto() {
   $(dirname $0)/show-howto.sh
}


function mm-show-faq() {
   $(dirname $0)/show-faq.sh
}


function mm-show-shell-commands() {
   $(dirname $0)/show-shell-commands.sh
}


function mm-show-windows-bat() {
   $(dirname $0)/show-windows-bat.sh
}


function mm-tct() {
   shift
   install-wheels
   tct "$@"
}


function mm-serve4build() {
   shift
   python2 /ALL/Scripts/serve4build.py "$@"
}


function mm-just1sphinxbuild() {
   shift
   python2 /ALL/Scripts/just1sphinxbuild.py "$@"
}


function tell-about-results() {
local exitstatus=$1
if [ $exitstatus -eq 0 ]
then
   cat <<EOT

Final exit status: 0 (completed)

EOT
else
   cat <<EOT

Final exit status: $exitstatus (aborted)

EOT
fi
if [ -d "/RESULT/Result" ]; then
   echo -n >/RESULT/warning-files.txt
   echo Find the results:
   find /RESULT/Result -type f -regextype posix-egrep -iregex '.*/0\.0\.0/Index\.html$' -printf "  ./Documentation-GENERATED-temp/Result/%P\\n"
   find /RESULT/Result -type f -regextype posix-egrep -iregex '.*/0\.0\.0/singlehtml/Index\.html$'  -printf "  ./Documentation-GENERATED-temp/Result/%P\\n"
   find /RESULT/Result -type d -regextype posix-egrep -regex  '.*/0\.0\.0/_buildinfo$'  -printf "  ./Documentation-GENERATED-temp/Result/%P\\n"
   find /RESULT/Result -type f -regextype posix-egrep -regex  '.*/_buildinfo/warnings\.txt$' \! -empty -printf "  ./Documentation-GENERATED-temp/Result/%P\\n"
   find /RESULT/Result -type f -regextype posix-egrep -regex  '.*/_buildinfo/warnings\.txt$' \! -empty -printf "  ./Documentation-GENERATED-temp/Result/%P\\n" >>/RESULT/warning-files.txt
   find /RESULT/Result -type f -regextype posix-egrep -iregex '.*/latex.*/run-make\.sh$' -printf "  ./Documentation-GENERATED-temp/Result/%P\\n"
   find /RESULT/Result -type f -regextype posix-egrep -iregex '.*/package/package.*\.zip$' -printf "  ./Documentation-GENERATED-temp/Result/%P\\n"

   if [ -f /RESULT/warning-files.txt ];then
      echo
      if [ -s /RESULT/warning-files.txt ];then
         echo "ATTENTION:"
         echo "   There are Sphinx warnings!"
      else
         echo "Congratulations:"
         echo "    There are no Sphinx warnings!"
         rm -f /RESULT/warning-files.txt
      fi
      echo
   fi
fi
}


function mm-makeall() {
   local cmd
   shift
   install-wheels

# make sure nothing is left over from previous run
if [[ -f /tmp/RenderDocumentation/Todo/ALL.source-me.sh ]]
then
   rm -f /tmp/RenderDocumentation/Todo/ALL.source-me.sh
fi
cmd="tct --cfg-file=/ALL/venv/tctconfig.cfg --verbose"
cmd="$cmd run RenderDocumentation -c makedir /ALL/Makedir"
cmd="$cmd -c make_latex 1 -c make_package 1 -c make_pdf 1 -c make_singlehtml 1"
if [ -z "$@" ]; then false
else
   cmd="$cmd"$(printf ' %q' "$@")
fi

echo $(utcstamp) cmd: "${cmd}" >>"$mmLOGFILE"
eval "$cmd"

local exitstatus=$?

# do localizations
if [[ -f /tmp/RenderDocumentation/Todo/ALL.source-me.sh ]]
then
   source /tmp/RenderDocumentation/Todo/ALL.source-me.sh
fi


tell-about-results $exitstatus
}


function mm-makeall-no-cache() {
   if [ -d "/RESULT/Cache" ]; then
      rm -rf /RESULT/Cache
   fi
   mm-makeall "$@"
}


function mm-makehtml() {
   local cmd
   shift
   install-wheels

# make sure nothing is left over from previous run
if [[ -f /tmp/RenderDocumentation/Todo/ALL.source-me.sh ]]
then
   rm -f /tmp/RenderDocumentation/Todo/ALL.source-me.sh
fi
cmd="tct --cfg-file=/ALL/venv/tctconfig.cfg --verbose"
cmd="$cmd run RenderDocumentation -c makedir /ALL/Makedir"
if [[ -z "$@" ]]
then
   true "do nothing"
else
   cmd="$cmd"$(printf ' %q' "$@")
fi

echo $(utcstamp) cmd: "${cmd}" >>"$mmLOGFILE"
eval $cmd

local exitstatus=$?

# do localizations
if [[ -f /tmp/RenderDocumentation/Todo/ALL.source-me.sh ]]
then
   source /tmp/RenderDocumentation/Todo/ALL.source-me.sh
fi

tell-about-results $exitstatus
}


function mm-makehtml-no-cache() {
   if [ -d "/RESULT/Cache" ]; then
      rm -rf /RESULT/Cache
   fi
   mm-makehtml "$@"
}


case "$1" in
--help)              mm-usage "$@" ;;
--version)           mm-version "$@" ;;
bashcmd)             mm-bashcmd "$@" ;;
makeall)             mm-makeall "$@" ;;
makeall-no-cache)    mm-makeall-no-cache "$@" ;;
makehtml)            mm-makehtml "$@" ;;
makehtml-no-cache)   mm-makehtml-no-cache "$@" ;;
show-shell-commands) mm-show-shell-commands "$@" ;;
show-windows-bat)    mm-show-windows-bat "$@" ;;
show-faq)            mm-show-faq "$@" ;;
show-howto)          mm-show-howto "$@" ;;
tct)                 mm-tct "$@" ;;
serve4build)         mm-serve4build "$@" ;;
just1sphinxbuild)    mm-just1sphinxbuild "$@" ;;
*)                   mm-minimalhelp "$@" ;;
esac
